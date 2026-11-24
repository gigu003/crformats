-- Normalize et-al terms for mixed Chinese/English bibliographies in qcjournal.
-- This module is required by qcjournal.lua; it is not an independent filter.

local List = require 'pandoc.List'
local stringify = pandoc.utils.stringify

local M = {}

local function has_chinese(s)
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
  if ok then return found end
  return text:match("[\228-\233][\128-\191][\128-\191]") ~= nil
end

local function strip_reference_number(s)
  s = tostring(s or "")
  s = s:gsub("^%s*\\%[%d+\\%]%s*", "")
  s = s:gsub("^%s*%[%d+%]%s*", "")
  return s
end

local function starts_with_latin_author(s)
  s = strip_reference_number(s)
  return s:match("^%s*[A-Z][A-Za-z%-%']*") ~= nil
end

local function fix_str_text(text)
  if not has_chinese(text) then return text end
  text = text:gsub("%s+et%s+al(%.)", "等")
  text = text:gsub("%s+et%s+al", "等")
  return text
end

local function fix_english_bib_et_al(text)
  if not starts_with_latin_author(text) then return text end
  text = text:gsub("，等%.", ", et al.", 1)
  text = text:gsub(",%s*等%.", ", et al.", 1)
  return text
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
  local english_reference_entry = starts_with_latin_author(stringify(inlines))
  local english_et_al_fixed = false

  while i <= #inlines do
    local cur = inlines[i]
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
          if fixed == cur.text and cur.text:match("^等%.?$") then
            fixed = "et al."
          end
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
      if not replace_cite_nodes then return nil end
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

local function truthy(value)
  if value == nil then return false end
  if type(value) == "boolean" then return value end
  if type(value) == "table" and value.t == "MetaBool" then return value.c end
  local value_str = stringify(value):lower()
  return value_str == "true" or value_str == "yes" or value_str == "1"
end

local function falsey(value)
  if value == nil then return false end
  if type(value) == "boolean" then return not value end
  if type(value) == "table" and value.t == "MetaBool" then return not value.c end
  local value_str = stringify(value):lower()
  return value_str == "false" or value_str == "no" or value_str == "0"
end

function M.process(doc, config)
  config = config or {}
  -- Default on for qcjournal; disable with qcjournal.chinese-et-al: false.
  if falsey(config["chinese-et-al"]) then return doc end

  local internal_citeproc = truthy(config["chinese-et-al-citeproc"])
    or truthy(doc.meta["chinese-et-al-citeproc"])

  if internal_citeproc then
    if pandoc.utils.citeproc == nil then
      io.stderr:write("WARNING: pandoc.utils.citeproc is unavailable; qcjournal chinese-et-al cannot run citeproc internally.\n")
    else
      doc = pandoc.utils.citeproc(doc)
    end
  end

  return postprocess_doc(doc, internal_citeproc)
end

return M
