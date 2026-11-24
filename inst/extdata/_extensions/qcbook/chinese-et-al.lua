-- Normalize et-al terms for mixed Chinese/English bibliographies.
--
-- Quarto/Pandoc applies CSL locale globally. With `lang: en`, Chinese
-- references may be rendered with `et al.`; with `lang: zh` / `zh-CN`,
-- English references may be rendered with `等`. This file supports two modes:
--
-- 1. Pandoc Lua filter mode: best-effort AST cleanup.
-- 2. Standalone script mode via `quarto run`: post-process generated Typst
--    and recompile the PDF.

local List = pandoc and pandoc.List or nil

local function has_chinese(s)
  -- Detect common CJK codepoints. Prefer Lua's UTF-8 iterator because
  -- Lua patterns are byte-oriented and fragile for multibyte text.
  local text = tostring(s or "")
  local ok, found = pcall(function()
    for _, codepoint in utf8.codes(text) do
      if (codepoint >= 0x3400 and codepoint <= 0x4DBF)
        or (codepoint >= 0x4E00 and codepoint <= 0x9FFF)
        or (codepoint >= 0xF900 and codepoint <= 0xFAFF) then
        return true
      end
    end
    return false
  end)

  if ok then
    return found
  end

  -- Fallback for escaped/generated Typst text that may contain byte sequences
  -- Lua's utf8 iterator rejects. This checks the common UTF-8 byte ranges for
  -- CJK Unified Ideographs.
  return text:match("[\228-\233][\128-\191][\128-\191]") ~= nil
end

local function strip_reference_number(s)
  s = tostring(s or "")
  s = s:gsub("^%s*\\%[%d+\\%]%s*", "")
  s = s:gsub("^%s*%[%d+%]%s*", "")
  return s
end

local function first_author_segment(s)
  local text = strip_reference_number(s)
  text = text:gsub("[Ee][Tt]%s+[Aa][Ll]", "")
  text = text:gsub("等", "")
  local stop = text:find("[%.。．]")
  if stop then
    return text:sub(1, stop - 1)
  end
  return text
end

local function fix_str_text(text)
  if not has_chinese(text) then
    return text
  end

  -- Handles cases where citeproc keeps the whole phrase in one Str.
  -- Examples:
  --   "李少芳 et al."  -> "李少芳等"
  --   "李少芳 et al.," -> "李少芳等,"
  text = text:gsub("%s+et%s+al(%.)", "等")
  text = text:gsub("%s+et%s+al", "等")
  return text
end

local function starts_with_latin_author(s)
  s = strip_reference_number(s)
  return s:match("^%s*[A-Z][A-Za-z%-%']*") ~= nil
end

local function normalize_et_al_line(line)
  local text = tostring(line or "")
  if not (text:match("[Ee][Tt]%s+[Aa][Ll]") or text:match("等")) then
    return text
  end

  local author_segment = first_author_segment(text)

  if has_chinese(author_segment) then
    -- Chinese entry: always use 等.
    text = text:gsub("([,，])%s*[Ee][Tt]%s+[Aa][Ll]%.", "%1 等.")
    text = text:gsub("([,，])%s*[Ee][Tt]%s+[Aa][Ll]", "%1 等")
    return text
  end

  if starts_with_latin_author(text) then
    -- English entry: always use et al.
    text = text:gsub("([,，])%s*等%.", "%1 et al.")
    text = text:gsub("([,，])%s*等", "%1 et al.")
    return text
  end

  return text
end

local function fix_english_bib_et_al(text)
  -- GB/T Chinese CSL styles usually render the et-al term as "等" for
  -- every entry, including English references.  For English entries,
  -- convert only the author-list terminator back to "et al.".
  --
  -- Examples in generated Typst/text:
  --   Lee J，Yoon W，Kim S，等. BioBERT...
  --   \[3\] Lee J，Yoon W，Kim S，等. BioBERT...
  -- become:
  --   Lee J，Yoon W，Kim S, et al. BioBERT...
  if not starts_with_latin_author(text) then
    return text
  end

  text = text:gsub("，等%.", ", et al.", 1)
  text = text:gsub(",%s*等%.", ", et al.", 1)
  return text
end

local function normalize_typst_file(typ_path)
  local input = io.open(typ_path, "r")
  if not input then
    return false, "Typst file not found: " .. tostring(typ_path)
  end
  local content = input:read("*a")
  input:close()

  local changed = false
  local lines = {}
  local has_trailing_newline = content:sub(-1) == "\n"

  for line in (content .. "\n"):gmatch("(.-)\n") do
    local fixed = normalize_et_al_line(line)
    if fixed ~= line then
      changed = true
    end
    table.insert(lines, fixed)
  end

  if not has_trailing_newline then
    table.remove(lines)
  end

  if changed then
    local output = io.open(typ_path, "w")
    if not output then
      return false, "Unable to write Typst file: " .. tostring(typ_path)
    end
    output:write(table.concat(lines, "\n"))
    if has_trailing_newline then
      output:write("\n")
    end
    output:close()
  end

  return true, changed
end

local function run_standalone()
  local qmd_path = arg and arg[1] or "template.qmd"
  local typ_path = arg and arg[2] or qmd_path:gsub("%.qmd$", ".typ")
  local pdf_path = arg and arg[3] or qmd_path:gsub("%.qmd$", ".pdf")

  local ok, result = normalize_typst_file(typ_path)
  if not ok then
    io.stderr:write(result .. "\n")
    return 1
  end

  local cmd = string.format("typst compile %q %q", typ_path, pdf_path)
  local status = os.execute(cmd)
  if status ~= true and status ~= 0 then
    io.stderr:write("Failed to compile Typst file: " .. cmd .. "\n")
    return 1
  end

  io.stdout:write("Normalized et-al terms in " .. typ_path .. " and rebuilt " .. pdf_path .. "\n")
  return 0
end

local function is_str(el, value)
  return el and el.t == "Str" and el.text == value
end

local function is_space(el)
  return el and (el.t == "Space" or el.t == "SoftBreak" or el.t == "LineBreak")
end

local function fix_inlines(inlines)
  local out = List:new()
  local i = 1
  local english_reference_entry = starts_with_latin_author(pandoc.utils.stringify(inlines))
  local english_et_al_fixed = false

  while i <= #inlines do
    local cur = inlines[i]

    -- Handles citeproc's common split form:
    --   Str("李少芳") Space Str("et") Space Str("al.")
    if cur and cur.t == "Str" and has_chinese(cur.text)
      and is_space(inlines[i + 1])
      and is_str(inlines[i + 2], "et")
      and is_space(inlines[i + 3])
      and inlines[i + 4] and inlines[i + 4].t == "Str"
      and inlines[i + 4].text:match("^al%.?[,]?$") then

      local suffix = inlines[i + 4].text:match("(,)$") or ""
      out:insert(pandoc.Str(fix_str_text(cur.text) .. "等" .. suffix))
      i = i + 5
    else
      if cur and cur.t == "Str" then
        cur.text = fix_str_text(cur.text)
        if english_reference_entry and not english_et_al_fixed then
          local fixed = fix_english_bib_et_al(cur.text)
          if fixed ~= cur.text then
            english_et_al_fixed = true
            cur.text = fixed
          end
        else
          cur.text = fix_english_bib_et_al(cur.text)
        end
      end
      out:insert(cur)
      i = i + 1
    end
  end

  return out
end

local function postprocess_doc(doc, replace_cite_nodes)
  return doc:walk({
    Cite = function(el)
      if not replace_cite_nodes then
        return nil
      end

      -- After pandoc.utils.citeproc(), formatted citation text is often
      -- stored in Cite.content while the Cite wrapper is still present.
      -- Process it explicitly and replace the Cite inline with plain
      -- formatted inlines. This matters for Typst output: if the Cite
      -- wrapper remains while top-level citeproc is disabled, Pandoc's
      -- Typst writer may serialize it back to native @key citations.
      return fix_inlines(el.content)
    end,
    Span = function(el)
      el.content = fix_inlines(el.content)
      return el
    end,
    Para = function(el)
      el.content = fix_inlines(el.content)
      return el
    end,
    Plain = function(el)
      el.content = fix_inlines(el.content)
      return el
    end,
    Header = function(el)
      el.content = fix_inlines(el.content)
      return el
    end,
  })
end

local function meta_bool(meta, key)
  local value = meta[key]
  if value == nil then
    return false
  end
  if type(value) == "boolean" then
    return value
  end
  if value.t == "MetaBool" then
    return value.c
  end
  return pandoc.utils.stringify(value) == "true"
end

-- `quarto pandoc lua chinese-et-al.lua template.qmd template.typ template.pdf`
-- runs in Pandoc's embedded Lua interpreter, where the `pandoc` table still
-- exists.  Therefore script mode is detected from positional arguments rather
-- than from `pandoc == nil` alone.
if arg and arg[1] and arg[2] then
  os.exit(run_standalone())
end

function Pandoc(doc)
  -- Pandoc runs ordinary Lua filters before its built-in citeproc pass.
  -- To make this a real citeproc *post*-processor, opt in with:
  --
  --   citeproc: false
  --   chinese-et-al-citeproc: true
  --
  -- The filter then invokes citeproc itself, receives formatted citation
  -- text, and finally replaces Chinese "et al." occurrences with "等".
  local internal_citeproc = meta_bool(doc.meta, "chinese-et-al-citeproc")

  if internal_citeproc then
    if pandoc.utils.citeproc == nil then
      io.stderr:write("WARNING: pandoc.utils.citeproc is unavailable; chinese-et-al.lua cannot run citeproc internally.\n")
    else
      doc = pandoc.utils.citeproc(doc)
    end
  end

  return postprocess_doc(doc, internal_citeproc)
end