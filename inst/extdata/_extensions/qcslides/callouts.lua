local callout_kinds = {
  ["callout-note"] = "note",
  ["callout-tip"] = "tip",
  ["callout-warning"] = "warning",
  ["callout-important"] = "important",
  ["callout-caution"] = "caution"
}

local function has_class(classes, class)
  for _, value in ipairs(classes) do
    if value == class then
      return true
    end
  end
  return false
end

local function typst_escape_text(text)
  text = text:gsub("\\", "\\\\")
  text = text:gsub("%]", "\\]")
  text = text:gsub("%[", "\\[")
  return text
end

local function typst_escape_string(text)
  text = text:gsub("\\", "\\\\")
  text = text:gsub('"', '\\"')
  text = text:gsub("\n", "\\n")
  text = text:gsub("\r", "\\r")
  return text
end

-- Lua's `%s` character class is locale-sensitive. Under some UTF-8 locales,
-- individual bytes inside Chinese characters can be classified as whitespace,
-- which corrupts the text when trimming it. Markdown whitespace is ASCII here,
-- so keep all trimming and token splitting byte-safe.
local function trim_ascii_whitespace(text)
  return (text:gsub("^[ \t\r\n]+", ""):gsub("[ \t\r\n]+$", ""))
end

function Code(code)
  if not quarto.doc.is_format("typst") then
    return nil
  end

  return pandoc.RawInline(
    "typst",
    '#qinline-code(raw("' .. typst_escape_string(code.text) .. '"))'
  )
end

-- Quarto uses code-summary as the label of a collapsible code block in HTML.
-- Typst/PDF has no interactive folding, so qcslides reuses that value as a
-- visible code-card title. `filename` keeps its native file-label semantics
-- and takes precedence when both attributes are present.
function CodeBlock(code)
  if not quarto.doc.is_format("typst") then
    return nil
  end

  local title = code.attributes["filename"] or code.attributes["code-summary"]
  if title == nil or title == "" then
    return nil
  end

  -- Prevent Pandoc from trying to interpret these display-only attributes
  -- after qcslides has converted them to the Typst wrapper.
  code.attributes["filename"] = nil
  code.attributes["code-summary"] = nil

  -- Keep the CodeBlock node between raw opening/closing blocks. This lets
  -- Pandoc's normal syntax-highlighting pass still produce Skylighting(...).
  return {
    pandoc.RawBlock("typst", "#qcode-title([" .. typst_escape_text(title) .. "],["),
    code,
    pandoc.RawBlock("typst", "])"),
  }
end

local function parse_timeline_item(blocks)
  local text = pandoc.utils.stringify(blocks)
  local icon = nil

  local first, rest_text = text:match("^%s*(%S+)%s+(.+)$")
  if first ~= nil and not first:match("[:：]") and not first:match("^%d") then
    icon = first
    text = rest_text
  end

  local marker, rest = text:match("^%s*([^:：]+)%s*[:：]%s*(.-)%s*$")
  if marker == nil then
    marker = tostring(#text > 0 and text or "")
    return icon, marker, marker, ""
  end

  local sep_start, sep_end = rest:find("｜", 1, true)
  if sep_start == nil then
    sep_start, sep_end = rest:find("|", 1, true)
  end

  local title, body
  if sep_start ~= nil then
    title = rest:sub(1, sep_start - 1):match("^%s*(.-)%s*$")
    body = rest:sub(sep_end + 1):match("^%s*(.-)%s*$")
  else
    title = rest
    body = ""
  end

  return icon, marker, title, body
end

local function parse_card_item(blocks)
  local text = pandoc.utils.stringify(blocks)
  local icon = nil

  local first, rest_text = text:match("^[ \t\r\n]*([^ \t\r\n]+)[ \t\r\n]+(.+)$")
  if first ~= nil and not first:match("[:：]") and not first:match("^%d") then
    icon = first
    text = rest_text
  end

  local sep_start, sep_end = text:find("｜", 1, true)
  if sep_start == nil then
    sep_start, sep_end = text:find("|", 1, true)
  end

  local title, body
  if sep_start ~= nil then
    title = trim_ascii_whitespace(text:sub(1, sep_start - 1))
    body = trim_ascii_whitespace(text:sub(sep_end + 1))
  else
    title = trim_ascii_whitespace(text)
    body = ""
  end

  return icon, title, body
end

local function parse_image_item(blocks)
  -- Only the path is plain text. Preserve caption inlines (including Span
  -- styles already converted to RawInline by the bottom-up filter).
  local path_parts = {}
  local caption = pandoc.Inlines({})
  local found_separator = false
  for _, block in ipairs(blocks) do
    if block.t == "Plain" or block.t == "Para" then
      for _, inline in ipairs(block.content) do
        if found_separator then
          caption:insert(inline)
        elseif inline.t == "Str" then
          local first, last = inline.text:find("｜", 1, true)
          if first == nil then
            first, last = inline.text:find("|", 1, true)
          end
          if first ~= nil then
            table.insert(path_parts, inline.text:sub(1, first - 1))
            found_separator = true
            local rest = inline.text:sub(last + 1)
            if rest ~= "" then
              caption:insert(pandoc.Str(rest))
            end
          else
            table.insert(path_parts, inline.text)
          end
        else
          table.insert(path_parts, pandoc.utils.stringify(inline))
        end
      end
    end
  end
  while #caption > 0 and (caption[1].t == "Space" or caption[1].t == "SoftBreak") do
    caption:remove(1)
  end
  while #caption > 0 and (caption[#caption].t == "Space" or caption[#caption].t == "SoftBreak") do
    caption:remove(#caption)
  end
  return trim_ascii_whitespace(table.concat(path_parts)), caption
end

local function parse_metric_item(blocks)
  local text = pandoc.utils.stringify(blocks)
  local parts = {}
  local current = ""

  for _, codepoint in utf8.codes(text) do
    local char = utf8.char(codepoint)
    if (char == "｜" or char == "|") and #parts < 2 then
      table.insert(parts, current:match("^%s*(.-)%s*$"))
      current = ""
    else
      current = current .. char
    end
  end
  table.insert(parts, current:match("^%s*(.-)%s*$"))

  return parts[1] or "", parts[2] or "", parts[3] or ""
end

local function split_pipe_parts(text, max_parts)
  local parts = {}
  local current = ""

  for _, codepoint in utf8.codes(text) do
    local char = utf8.char(codepoint)
    if (char == "｜" or char == "|") and #parts < max_parts - 1 then
      table.insert(parts, current:match("^%s*(.-)%s*$"))
      current = ""
    else
      current = current .. char
    end
  end
  table.insert(parts, current:match("^%s*(.-)%s*$"))

  return parts
end

local function parse_gantt_item(blocks)
  local text = pandoc.utils.stringify(blocks)
  local parts = split_pipe_parts(text, 5)
  return parts[1] or "", parts[2] or "", parts[3] or "", parts[4] or "", parts[5] or ""
end

local function parse_gantt_footer_note(blocks)
  local text = pandoc.utils.stringify(blocks):match("^%s*(.-)%s*$")

  local function content_after_prefix(prefix, case_insensitive)
    local candidate = case_insensitive and text:lower() or text
    local expected = case_insensitive and prefix:lower() or prefix
    if candidate:sub(1, #expected) ~= expected then
      return nil, false
    end

    local rest = text:sub(#prefix + 1)
    if rest == "" then
      return "", true
    elseif rest:sub(1, 1) == ":" then
      return rest:sub(2):match("^%s*(.-)%s*$"), true
    elseif rest:sub(1, #"：") == "：" then
      return rest:sub(#"：" + 1):match("^%s*(.-)%s*$"), true
    elseif rest:match("^%s") then
      return rest:match("^%s*(.-)%s*$"), true
    end
    return nil, false
  end

  local content, matched = content_after_prefix("note", true)
  if matched then
    return content, true
  end
  -- 优先匹配较长的中文前缀，避免“备注”被较短前缀误判。
  for _, prefix in ipairs({ "备注", "注" }) do
    content, matched = content_after_prefix(prefix, false)
    if matched then
      return content, true
    end
  end
  return nil, false
end

local gantt_warning

local function parse_gantt_progress(value, task)
  local normalized = tostring(value or ""):match("^%s*(.-)%s*$")
  if normalized == "" then
    return nil
  end

  local has_percent = normalized:sub(-1) == "%"
  local numeric_text = has_percent and normalized:sub(1, -2) or normalized
  local number = tonumber(numeric_text:match("^%s*(.-)%s*$"))
  if number == nil then
    gantt_warning("任务“" .. task .. "”的进度“" .. normalized .. "”无效，已忽略；可使用 80%、80 或 0.8。")
    return nil
  end

  local percent
  if has_percent then
    percent = number
  elseif number >= 0 and number <= 1 then
    percent = number * 100
  else
    percent = number
  end
  if percent < 0 or percent > 100 then
    gantt_warning("任务“" .. task .. "”的进度超出 0%–100%，已自动截断。")
    percent = math.max(0, math.min(100, percent))
  end
  return percent
end

local function split_gantt_notes(text)
  local notes = {}
  local current = ""
  for _, codepoint in utf8.codes(text or "") do
    local char = utf8.char(codepoint)
    if char == "；" or char == ";" then
      local note = current:match("^%s*(.-)%s*$")
      if note ~= "" then
        table.insert(notes, note)
      end
      current = ""
    else
      current = current .. char
    end
  end
  local note = current:match("^%s*(.-)%s*$")
  if note ~= "" then
    table.insert(notes, note)
  end
  return notes
end

local function text_width_em(text)
  local width = 0
  for _, codepoint in utf8.codes(text or "") do
    if codepoint < 128 then
      width = width + 0.55
    else
      width = width + 1.0
    end
  end
  return width
end

local function positive_em(value, fallback)
  if value == nil or value == "" then
    return fallback
  end
  local number = tonumber(tostring(value):match("^%s*([%d%.]+)%s*em%s*$"))
  if number == nil or number <= 0 then
    return fallback
  end
  return number
end

local function absolute_length_arg(value, fallback, name)
  if value == nil or value == "" then
    return fallback
  end

  local normalized = tostring(value):match("^%s*(.-)%s*$")
  local number, unit = normalized:match("^(%d*%.?%d+)%s*([%a]+)$")
  local allowed_units = { pt = true, mm = true, cm = true, ["in"] = true }
  if normalized == "0" or (number ~= nil and allowed_units[unit] == true) then
    return normalized
  end

  gantt_warning(name .. " 必须使用非负绝对长度（pt、mm、cm 或 in）；收到“" .. normalized .. "”，已回退到 " .. fallback .. "。")
  return fallback
end

local function gantt_task_kind(task)
  local normalized = tostring(task or ""):match("^%s*(.-)%s*$")
  if normalized:sub(1, 1) == "!" then
    return "milestone", normalized:sub(2):match("^%s*(.-)%s*$")
  end
  -- Lua pattern 的字符类按字节匹配，不能安全地写成 [◆◇]，否则会截断 UTF-8。
  for _, marker in ipairs({ "◆", "◇" }) do
    if normalized:sub(1, #marker) == marker then
      return "milestone", normalized:sub(#marker + 1):match("^%s*(.-)%s*$")
    end
  end
  return "task", normalized
end

local function parse_year_month(value)
  if value == nil then
    return nil
  end
  local year, month = tostring(value):match("^(%d%d%d%d)[%-/%.](%d%d?)$")
  if year == nil then
    return nil
  end
  year = tonumber(year)
  month = tonumber(month)
  if month == nil or month < 1 or month > 12 then
    return nil
  end
  return year, month
end

local function month_serial(value)
  local year, month = parse_year_month(value)
  if year == nil then
    return nil
  end
  return year * 12 + month - 1
end

local function month_label(serial, style)
  local year = math.floor(serial / 12)
  local month = serial % 12 + 1
  if style == "year-month" or style == "ym" then
    return string.format("%04d-%02d", year, month)
  end
  return string.format("%02d", month)
end

local function gantt_scale(value)
  local normalized = string.lower(tostring(value or "month")):gsub("_", "-")
  local scales = {
    month = { name = "month", step = 1 },
    ["1m"] = { name = "month", step = 1 },
    bimonth = { name = "bimonth", step = 2 },
    ["bi-month"] = { name = "bimonth", step = 2 },
    ["2m"] = { name = "bimonth", step = 2 },
    quarter = { name = "quarter", step = 3 },
    quarterly = { name = "quarter", step = 3 },
    ["3m"] = { name = "quarter", step = 3 },
    ["half-year"] = { name = "half-year", step = 6 },
    halfyear = { name = "half-year", step = 6 },
    semiannual = { name = "half-year", step = 6 },
    ["6m"] = { name = "half-year", step = 6 },
  }
  return scales[normalized]
end

local function period_label(start_serial, end_serial, scale_name, label_style)
  local start_year = math.floor(start_serial / 12)
  local start_month = start_serial % 12 + 1
  local end_year = math.floor(end_serial / 12)
  local end_month = end_serial % 12 + 1
  local full_span = end_serial - start_serial + 1

  if scale_name == "month" then
    return month_label(start_serial, label_style)
  end
  if scale_name == "quarter" and full_span == 3 and start_year == end_year and (start_month - 1) % 3 == 0 then
    return "Q" .. tostring(math.floor((start_month - 1) / 3) + 1)
  end
  if scale_name == "half-year" and full_span == 6 and start_year == end_year and (start_month == 1 or start_month == 7) then
    return start_month == 1 and "H1" or "H2"
  end
  if start_year == end_year then
    return string.format("%02d–%02d", start_month, end_month)
  end
  return string.format("%04d-%02d–%04d-%02d", start_year, start_month, end_year, end_month)
end

gantt_warning = function(message)
  local formatted = "qcslides gantt: " .. message
  if quarto ~= nil and quarto.log ~= nil and quarto.log.warning ~= nil then
    quarto.log.warning(formatted)
  else
    io.stderr:write("WARNING: " .. formatted .. "\n")
  end
end

local function timeline_orientation(classes)
  if has_class(classes, "vertical") then
    return "vertical"
  end
  return "horizontal"
end

local function timeline_columns(attributes)
  local value = attributes["columns"] or attributes["vertical-columns"]
  if value == nil or value == "" then
    return "auto"
  end

  local number = tonumber(value)
  if number == nil or number < 1 then
    return "auto"
  end

  return tostring(math.floor(number))
end

local function timeline_column_threshold(attributes)
  local value = attributes["threshold"] or attributes["vertical-column-threshold"]
  if value == nil or value == "" then
    return "4"
  end

  local number = tonumber(value)
  if number == nil or number < 1 then
    return "4"
  end

  return tostring(math.floor(number))
end

local function cards_columns(attributes)
  local value = attributes["columns"]
  if value == nil or value == "" then
    return "auto"
  end

  local number = tonumber(value)
  if number == nil or number < 1 then
    return "auto"
  end

  return tostring(math.floor(number))
end

local function metric_columns(attributes)
  local value = attributes["columns"] or attributes["column"]
  if value == nil or value == "" then
    return "auto"
  end

  local number = tonumber(value)
  if number == nil or number < 1 then
    return "auto"
  end

  return tostring(math.floor(number))
end

local function typst_bool_arg(value, default)
  if value == nil or value == "" then
    return default
  end

  value = tostring(value):lower()
  if value == "false" or value == "no" or value == "0" then
    return "false"
  end
  return "true"
end

local function keypoints_style(attributes)
  local value = attributes["style"]
  if value == "bullet" then
    return "bullet"
  end
  return "numbered"
end

local function quote_align(attributes)
  local value = attributes["align"]
  if value == "left" or value == "center" or value == "right" or value == "justify" then
    return value
  end
  return "center"
end

local function quote_size_arg(attributes)
  local value = attributes["size"]
  if value == "normal" or value == "large" then
    return "\"" .. value .. "\""
  end

  if value ~= nil then
    local number, unit = value:match("^%s*(%d*%.?%d+)%s*(%a+)%s*$")
    if number ~= nil and (unit == "em" or unit == "pt") and tonumber(number) > 0 then
      return number .. unit
    end
  end

  return "\"large\""
end

local function quote_style(attributes)
  local value = attributes["style"]
  if value == "compact" or value == "card" then
    return value
  end
  return "classic"
end

local function typst_content_arg(value)
  if value ~= nil and value ~= "" then
    return "[" .. typst_escape_text(value) .. "]"
  end
  return "none"
end

local function typst_string_arg(value, default)
  if value ~= nil and value ~= "" then
    return "\"" .. typst_escape_text(value) .. "\""
  end
  return default
end

local function typst_color_arg(value, default)
  if value == nil or value == "" then
    return default
  end

  local normalized = tostring(value):match("^%s*(.-)%s*$")
  local css_colors = {
    lightblue = "#ADD8E6",
  }
  if css_colors[normalized:lower()] ~= nil then
    return "rgb(\"" .. css_colors[normalized:lower()] .. "\")"
  end
  if normalized:match("^#%x%x%x%x%x%x$") then
    return "rgb(\"" .. normalized .. "\")"
  end
  return normalized
end

local function list_length_arg(value, default)
  if value == nil or value == "" then
    return default
  end

  local normalized = trim_ascii_whitespace(tostring(value))
  if normalized == "0" then
    return "0em"
  end
  local number, unit = normalized:match("^(%d*%.?%d+)%s*([%a]+)$")
  local allowed_units = { pt = true, mm = true, cm = true, ["in"] = true, em = true, ex = true }
  if number ~= nil and tonumber(number) >= 0 and allowed_units[unit] == true then
    return number .. unit
  end
  return default
end

local function list_opacity_arg(value, default)
  if value == nil or value == "" then
    return default
  end

  local normalized = trim_ascii_whitespace(tostring(value))
  local number = normalized:match("^(%d*%.?%d+)%%$")
  if number ~= nil and tonumber(number) >= 0 and tonumber(number) <= 100 then
    return number .. "%"
  end
  return default
end

function Span(span)
  if not quarto.doc.is_format("typst") then
    return nil
  end

  local color = span.attributes["color"] or span.attributes["font-color"] or span.attributes["text-color"]
  local font_size = span.attributes["font-size"] or span.attributes["text-size"]
  local background = span.attributes["bg"] or span.attributes["background"] or
    span.attributes["background-color"]
  local background_opacity = span.attributes["bg-opacity"] or span.attributes["background-opacity"]
  local padding = span.attributes["padding"] or span.attributes["inset"] or
    span.attributes["text-padding"]
  if color == nil and font_size == nil and background == nil and background_opacity == nil and
      padding == nil then
    return nil
  end

  local inlines = {
    pandoc.RawInline(
      "typst",
      "#qstyled-text(color: " .. typst_color_arg(color, "none") ..
        ", font-size: " .. list_length_arg(font_size, "none") ..
        ", bg: " .. typst_color_arg(background, "none") ..
        ", bg-opacity: " .. list_opacity_arg(background_opacity, "100%") ..
        ", padding: " .. list_length_arg(padding, "none") .. ")["
    ),
  }
  for _, inline in ipairs(span.content) do
    table.insert(inlines, inline)
  end
  table.insert(inlines, pandoc.RawInline("typst", "]"))
  return inlines
end

local function logo_offset_arg(value)
  if value == nil or value == "" then
    return "0pt"
  end

  local normalized = tostring(value):match("^%s*(.-)%s*$")
  if normalized == "0" then
    return "0pt"
  end

  local number, unit = normalized:match("^([+-]?%d*%.?%d+)%s*([%a]+)$")
  local allowed_units = {
    pt = true,
    mm = true,
    cm = true,
    ["in"] = true,
    em = true,
    ex = true,
  }
  if number ~= nil and allowed_units[unit] == true then
    return number .. unit
  end

  return "0pt"
end

local function logo_layout_arg(value, has_image, has_text)
  if value == "text" or value == "image" or value == "image-text" then
    return value
  end
  if has_image and has_text then
    return "image-text"
  elseif has_image then
    return "image"
  end
  return "text"
end

-- Typst only reads files inside its project root. Normalize local absolute
-- image paths so both `logo-image` and page-local `.logo` can reference an
-- image stored outside the Quarto project directory.
local function normalize_logo_path(path)
  -- Pandoc represents an escaped underscore in metadata as a non-breaking
  -- space after stringify(); restore both forms before opening the file.
  return path:gsub("\\_", "_"):gsub("\194\160", "_")
end

local function logo_resource_path(path)
  path = normalize_logo_path(path)
  if path:sub(1, 1) ~= "/" then
    return path
  end

  local file = io.open(path, "rb")
  if file == nil then
    return path
  end

  local contents = file:read("*all")
  file:close()

  local extension = path:match("%.([%w]+)$")
  extension = extension ~= nil and extension:lower() or "bin"
  local mime_types = {
    png = "image/png",
    jpg = "image/jpeg",
    jpeg = "image/jpeg",
    gif = "image/gif",
    webp = "image/webp",
    svg = "image/svg+xml",
  }
  local key = "_qcslides-logo-" .. path:gsub("[^%w%._%-]", "_")
  pandoc.mediabag.insert(key, mime_types[extension] or "application/octet-stream", contents)
  return key
end

local function meta_string(value)
  if value == nil then
    return nil
  end
  if type(value) == "string" then
    return value
  end
  if value.t == "MetaString" then
    return value.text
  end
  if value.t == "MetaInlines" or pandoc.utils.type(value) == "Inlines" then
    return pandoc.utils.stringify(value)
  end
  return nil
end

local function stage_absolute_image(path, prefix)
  path = normalize_logo_path(path)
  if path:sub(1, 1) ~= "/" then
    return path
  end
  local file = io.open(path, "rb")
  if file == nil then
    return path
  end

  local contents = file:read("*all")
  file:close()

  local key = prefix .. path:gsub("[^%w%._%-]", "_")
  local input_file = quarto.doc.input_file or PANDOC_STATE.input_files[1]
  if input_file == nil or input_file == "" then
    return path
  end

  local project_dir = pandoc.path.directory(input_file)
  local relative_path = pandoc.path.join({ ".quarto", "qcslides-media", key })
  local target = pandoc.path.join({ project_dir, relative_path })
  pandoc.system.make_directory(pandoc.path.directory(target), true)

  local output = io.open(target, "wb")
  if output ~= nil then
    output:write(contents)
    output:close()
    return relative_path
  end
  return path
end

function Meta(meta)
  local logo_image = meta_string(meta["logo-image"])
  if logo_image ~= nil and logo_image ~= "" and logo_image:match("^/") then
    stage_absolute_image(logo_image, "_qcslides-logo-")
  end
  return meta
end

local function figure_insight_position(attributes)
  local value = attributes["insight-position"] or attributes["position"]
  if value == "left" or value == "right" or value == "top" or value == "bottom" then
    return value
  end
  return "right"
end

local function quote_slide_from_div(div)
  local body = pandoc.write(pandoc.Pandoc(div.content), "typst", { wrap_text = "none" })
  local author = div.attributes["author"]
  local author_arg = "none"
  if author ~= nil and author ~= "" then
    author_arg = "[" .. typst_escape_text(author) .. "]"
  end

  return pandoc.RawBlock(
    "typst",
    "#qquote-slide(author: " .. author_arg ..
      ", quote-align: \"" .. quote_align(div.attributes) .. "\"" ..
      ", quote-size: " .. quote_size_arg(div.attributes) ..
      ", quote-style: \"" .. quote_style(div.attributes) .. "\"" ..
      ")[\n" .. body .. "\n]"
  )
end

local function keypoints_from_div(div)
  local list = nil
  for _, block in ipairs(div.content) do
    if block.t == "BulletList" then
      list = block.content
      break
    end
  end

  if list == nil then
    return nil
  end

  local items = {}
  for _, item_blocks in ipairs(list) do
    local _, title, body = parse_card_item(item_blocks)
    table.insert(
      items,
      "(title: [" .. typst_escape_text(title) .. "], body: [" .. typst_escape_text(body) .. "])"
    )
  end

  -- Typst 的单元素数组必须保留尾逗号；否则 `(item)` 会被解析成字典。
  local items_value = table.concat(items, ", ")
  if #items == 1 then
    items_value = items_value .. ","
  end

  return pandoc.RawBlock(
    "typst",
    "#qkeypoints((" .. items_value ..
      "), style: \"" .. keypoints_style(div.attributes) .. "\"" ..
      ", height: " .. (div.attributes["height"] or "auto") ..
      ")"
  )
end

local function metrics_from_div(div)
  local list = nil
  for _, block in ipairs(div.content) do
    if block.t == "BulletList" then
      list = block.content
      break
    end
  end

  if list == nil then
    return nil
  end

  local items = {}
  for _, item_blocks in ipairs(list) do
    local value, label, note = parse_metric_item(item_blocks)
    if value ~= nil and value ~= "" then
      local label_value = "none"
      local note_value = "none"
      if label ~= nil and label ~= "" then
        label_value = "[" .. typst_escape_text(label) .. "]"
      end
      if note ~= nil and note ~= "" then
        note_value = "[" .. typst_escape_text(note) .. "]"
      end
      table.insert(
        items,
        "(value: [" .. typst_escape_text(value) .. "], label: " .. label_value .. ", note: " .. note_value .. ")"
      )
    end
  end

  return pandoc.RawBlock(
    "typst",
    "#keyvalues((" .. table.concat(items, ", ") .. ")" ..
      ", columns: " .. metric_columns(div.attributes) ..
      ", height: " .. (div.attributes["height"] or "auto") ..
      ", gutter: " .. (div.attributes["gap"] or div.attributes["gutter"] or "1em") ..
      ", value-size: " .. (div.attributes["value-size"] or "auto") ..
      ", label-size: " .. (div.attributes["label-size"] or "auto") ..
      ", note-size: " .. (div.attributes["note-size"] or "auto") ..
      ", inset: " .. (div.attributes["inset"] or "auto") ..
      ")"
  )
end

local function cards_from_div(div)
  local list = nil
  for _, block in ipairs(div.content) do
    if block.t == "BulletList" then
      list = block.content
      break
    end
  end

  if list == nil then
    return nil
  end

  local items = {}
  for _, item_blocks in ipairs(list) do
    local icon, title, body = parse_card_item(item_blocks)
    local icon_value = "none"
    if icon ~= nil and icon ~= "" then
      icon_value = "[" .. typst_escape_text(icon) .. "]"
    end
    table.insert(
      items,
      "(icon: " .. icon_value .. ", title: [" .. typst_escape_text(title) .. "], body: [" .. typst_escape_text(body) .. "])"
    )
  end

  return pandoc.RawBlock(
    "typst",
    "#qcards((" .. table.concat(items, ", ") .. "), columns: " .. cards_columns(div.attributes) .. ")"
  )
end

local function flow_from_div(div)
  local list = nil
  for _, block in ipairs(div.content) do
    if block.t == "BulletList" then
      list = block.content
      break
    end
  end

  if list == nil then
    return nil
  end

  local items = {}
  for _, item_blocks in ipairs(list) do
    local label = trim_ascii_whitespace(pandoc.utils.stringify(item_blocks))
    if label ~= "" then
      table.insert(items, "[" .. typst_escape_text(label) .. "]")
    end
  end

  if #items == 0 then
    return nil
  end

  -- Typst 的单元素集合必须保留尾逗号，否则 items.len() 会作用于内容节点。
  local items_value = table.concat(items, ", ")
  if #items == 1 then
    items_value = items_value .. ","
  end

  return pandoc.RawBlock(
    "typst",
    "#qflow((" .. items_value .. ")" ..
      ", height: " .. (div.attributes["height"] or "16mm") ..
      ", gap: " .. (div.attributes["gap"] or "1.25em") ..
      ", text-size: " .. (div.attributes["text-size"] or "0.76em") ..
      ")"
  )
end

local function card2_body_typst(blocks, accent_color, list_size)
  local parts = {}

  for _, block in ipairs(blocks) do
    if block.t == "BulletList" then
      local items = {}
      for _, item_blocks in ipairs(block.content) do
        local item_body = pandoc.write(
          pandoc.Pandoc(item_blocks),
          "typst",
          { wrap_text = "none" }
        )
        table.insert(items, "[" .. item_body .. "]")
      end

      local item_args = table.concat(items, ", ")
      if #items == 1 then
        item_args = item_args .. ","
      end

      table.insert(
        parts,
        "#qcard2-list((" .. item_args ..
          "), accent-color: " .. typst_color_arg(accent_color, "none") ..
          ", list-size: " .. (list_size or "0.86em") .. ")"
      )
    else
      table.insert(
        parts,
        pandoc.write(
          pandoc.Pandoc({ block }),
          "typst",
          { wrap_text = "none" }
        )
      )
    end
  end

  return table.concat(parts, "\n")
end

local function card2_from_div(div)
  local title = div.attributes["title"]
  local body_blocks = {}
  local header_removed = false

  for _, block in ipairs(div.content) do
    if block.t == "Header" and not header_removed then
      if title == nil or title == "" then
        title = pandoc.utils.stringify(block.content)
      end
      header_removed = true
    else
      table.insert(body_blocks, block)
    end
  end

  local body = card2_body_typst(
    body_blocks,
    div.attributes["accent-color"],
    div.attributes["list-size"]
  )

  return pandoc.RawBlock(
    "typst",
    "#qcard2(" ..
      "title: " .. typst_content_arg(title) ..
      ", subtitle: " .. typst_content_arg(div.attributes["subtitle"]) ..
      ", accent-color: " .. typst_color_arg(div.attributes["accent-color"], "none") ..
      ", height: " .. (div.attributes["height"] or "auto") ..
      ", radius: " .. (div.attributes["radius"] or "0.8em") ..
      ")[\n" .. body .. "\n]"
  )
end

local function timeline_from_div(div)
  local list = nil
  for _, block in ipairs(div.content) do
    if block.t == "BulletList" then
      list = block.content
      break
    end
  end

  if list == nil then
    return nil
  end

  local items = {}
  for _, item_blocks in ipairs(list) do
    local icon, marker, title, body = parse_timeline_item(item_blocks)
    local icon_value = "none"
    if icon ~= nil and icon ~= "" then
      icon_value = "[" .. typst_escape_text(icon) .. "]"
    end
    table.insert(
      items,
      "(icon: " .. icon_value .. ", marker: [" .. typst_escape_text(marker) .. "], title: [" .. typst_escape_text(title) .. "], body: [" .. typst_escape_text(body) .. "])"
    )
  end

  return pandoc.RawBlock(
    "typst",
    "#qtimeline((" .. table.concat(items, ", ") .. "), orientation: \"" .. timeline_orientation(div.classes) .. "\", vertical-columns: " .. timeline_columns(div.attributes) .. ", vertical-column-threshold: " .. timeline_column_threshold(div.attributes) .. ")"
  )
end

local function figure_insight_from_div(div)
  local image = div.attributes["image"]
  if image == nil or image == "" then
    return nil
  end

  local list = nil
  for _, block in ipairs(div.content) do
    if block.t == "BulletList" then
      list = block.content
      break
    end
  end

  if list == nil then
    return nil
  end

  local items = {}
  for _, item_blocks in ipairs(list) do
    local _, title, body = parse_card_item(item_blocks)
    table.insert(
      items,
      "(title: [" .. typst_escape_text(title) .. "], body: [" .. typst_escape_text(body) .. "])"
    )
  end

  return pandoc.RawBlock(
    "typst",
    "#qfigure-insight(" .. typst_string_arg(image) ..
      ", (" .. table.concat(items, ", ") .. ")" ..
      ", caption: " .. typst_content_arg(div.attributes["caption"]) ..
      ", image-width: " .. (div.attributes["image-width"] or "92%") ..
      ", image-height: " .. (div.attributes["image-height"] or "auto") ..
      ", image-fit: " .. typst_string_arg(div.attributes["image-fit"], "\"contain\"") ..
      ", frame-width: " .. (div.attributes["frame-width"] or "auto") ..
      ", insight-position: \"" .. figure_insight_position(div.attributes) .. "\"" ..
      ", image-area-width: " .. (div.attributes["image-area-width"] or "1.35fr") ..
      ", insight-area-width: " .. (div.attributes["insight-area-width"] or "1fr") ..
      ", gutter: " .. (div.attributes["gutter"] or "1.4em") ..
      ")"
  )
end

local function image_list_from_div(div)
  local list = nil
  for _, block in ipairs(div.content) do
    if block.t == "BulletList" then
      list = block.content
      break
    end
  end

  if list == nil then
    return nil
  end

  local items = {}
  for _, item_blocks in ipairs(list) do
    local path, caption = parse_image_item(item_blocks)
    if path ~= nil and path ~= "" then
      path = stage_absolute_image(path, "_qcslides-image-list-")
      local caption_value = "none"
      if #caption > 0 then
        caption_value = "[" .. pandoc.write(
          pandoc.Pandoc({ pandoc.Plain(caption) }), "typst", { wrap_text = "none" }
        ) .. "]"
      end
      table.insert(
        items,
        "(path: " .. typst_string_arg(path, "\"\"") .. ", caption: " .. caption_value .. ")"
      )
    end
  end

  -- Typst 的单元素数组必须保留尾逗号；否则 `(item)` 会被解析成
  -- 普通括号表达式，导致 qimage-list 中的 items.len() 等数组操作报错。
  local items_value = table.concat(items, ", ")
  if #items == 1 then
    items_value = items_value .. ","
  end

  return pandoc.RawBlock(
    "typst",
    "#qimage-list((" .. items_value .. ")" ..
      ", columns: " .. cards_columns(div.attributes) ..
      ", image-height: " .. (div.attributes["image-height"] or "38mm") ..
      ", image-fit: " .. typst_string_arg(div.attributes["fit"] or div.attributes["image-fit"], "\"contain\"") ..
      ", gutter: " .. (div.attributes["gap"] or div.attributes["gutter"] or "1em") ..
      ", caption: " .. typst_content_arg(div.attributes["caption"]) ..
      ", cap-location: " .. typst_string_arg(div.attributes["cap-location"], "\"bottom\"") ..
      ", caption-size: " .. (div.attributes["caption-size"] or "0.62em") ..
      ", group-caption-size: " .. (div.attributes["group-caption-size"] or "0.68em") ..
      ", frame: " .. typst_bool_arg(div.attributes["frame"], "true") ..
      ")"
  )
end

local function logo_from_div(div)
  local path = nil

  for _, block in ipairs(div.content) do
    if block.t == "Para" or block.t == "Plain" then
      for _, inline in ipairs(block.content) do
        if inline.t == "Image" then
          path = inline.src
          if path == nil and inline.target ~= nil then
            path = inline.target[2]
          end
          break
        end
      end
    end
    if path ~= nil and path ~= "" then
      break
    end
  end

  local header_image = div.attributes["logo-image"]
  local header_text = div.attributes["logo-text"]
  local header_height = div.attributes["logo-height"]
  local header_layout = div.attributes["logo-layout"]
  local has_header_options = header_image ~= nil or header_text ~= nil or
    header_height ~= nil or header_layout ~= nil
  local x = logo_offset_arg(div.attributes["x"] or div.attributes["dx"])
  local y_value = div.attributes["y"] or div.attributes["dy"]
  local y = "none"
  if y_value ~= nil and y_value ~= "" then
    y = logo_offset_arg(y_value)
  end
  local replace_header = typst_bool_arg(
    div.attributes["replace-header"] or div.attributes["replace-header-logo"],
    "false"
  )
  replace_header = replace_header == "true" or has_header_options

  if header_image ~= nil and header_image ~= "" then
    if normalize_logo_path(header_image):lower() == "none" then
      path = nil
    else
      path = header_image
    end
  end

  if path == nil or path == "" then
    if not replace_header then
      return nil
    end
  end

  local height = header_height or div.attributes["height"] or "12mm"
  local logo_image = nil
  if path ~= nil and path ~= "" then
    path = logo_resource_path(path)
    logo_image = pandoc.Image(
      {},
      path,
      "",
      pandoc.Attr("", {}, { height = height })
    )
  end

  if replace_header then
    local has_image = logo_image ~= nil
    local has_text = header_text ~= nil and header_text ~= ""
    local layout = logo_layout_arg(header_layout, has_image, has_text)
    local header_body = pandoc.RawBlock("typst", "")
    if logo_image ~= nil then
      header_body = pandoc.Para({ logo_image })
    end
    return {
      pandoc.RawBlock(
        "typst",
        "#context { let current-page = counter(page).get().at(0); qcslides-header-override-pages.update(pages => pages + (current-page,)) }"
      ),
      pandoc.RawBlock(
        "typst",
        "#qslide-header-logo(logo-height: " .. height ..
          ", logo-layout: " .. typst_string_arg(layout, "\"image\"") ..
          ", logo-text: " .. typst_content_arg(header_text) .. ")["
      ),
      header_body,
      pandoc.RawBlock("typst", "]"),
    }
  end

  return {
    pandoc.RawBlock(
      "typst",
      "#qslide-logo(logo-height: " .. height .. ", x: " .. x .. ", y: " .. y .. ")["
    ),
    pandoc.Para({ logo_image }),
    pandoc.RawBlock("typst", "]"),
  }
end

local function logo_from_header(header)
  local proxy = pandoc.Div({}, pandoc.Attr("", { "logo" }, header.attributes))
  return logo_from_div(proxy)
end

local function list_from_div(div)
  local marker = div.attributes["marker"] or div.attributes["bullet"] or div.attributes["item-symbol"]
  local line_spacing = div.attributes["line-spacing"] or div.attributes["leading"]
  local paragraph_spacing = div.attributes["paragraph-spacing"] or div.attributes["spacing"] or
    div.attributes["item-spacing"]
  local color = div.attributes["color"] or div.attributes["font-color"] or div.attributes["text-color"]
  local font_size = div.attributes["font-size"] or div.attributes["text-size"]
  local background = div.attributes["bg-color"] or div.attributes["block-bg"] or
    div.attributes["background-color"]
  local background_opacity = div.attributes["bg-opacity"] or div.attributes["background-opacity"]
  local indent = div.attributes["indent"] or div.attributes["list-indent"]
  local padding = div.attributes["padding"] or div.attributes["inset"] or
    div.attributes["block-padding"]
  local radius = div.attributes["radius"] or div.attributes["corner-radius"] or
    div.attributes["block-radius"]

  local blocks = {
    pandoc.RawBlock(
      "typst",
      "#qstyled-list(marker: " .. typst_content_arg(marker) ..
        ", line-spacing: " .. list_length_arg(line_spacing, "0.82em") ..
        ", paragraph-spacing: " .. list_length_arg(paragraph_spacing, "0.45em") ..
        ", color: " .. typst_color_arg(color, "none") ..
        ", font-size: " .. list_length_arg(font_size, "none") ..
        ", bg-color: " .. typst_color_arg(background, "none") ..
        ", bg-opacity: " .. list_opacity_arg(background_opacity, "100%") ..
        ", indent: " .. list_length_arg(indent, "none") ..
        ", padding: " .. list_length_arg(padding, "none") ..
        ", radius: " .. list_length_arg(radius, "none") .. ")["
    ),
  }
  for _, block in ipairs(div.content) do
    table.insert(blocks, block)
  end
  table.insert(blocks, pandoc.RawBlock("typst", "]"))
  -- Keep the wrapper as one layout cell. Returning sibling blocks lets
  -- Quarto split the opening call, list, and closing bracket across columns.
  div.content = blocks
  div.classes = div.classes:filter(function(class) return class ~= "list" end)
  return div
end

local function gantt_from_div(div)
  local list = nil
  for _, block in ipairs(div.content) do
    if block.t == "BulletList" then
      list = block.content
      break
    end
  end

  if list == nil then
    gantt_warning("组件中未找到项目列表。")
    return nil
  end

  local range_start = div.attributes["start"] or "2026-01"
  local range_end = div.attributes["end"] or "2026-12"
  local start_serial = month_serial(range_start)
  local end_serial = month_serial(range_end)

  if start_serial == nil or end_serial == nil or end_serial < start_serial then
    gantt_warning("起止月份无效，请使用 YYYY-MM，且 end 不得早于 start。")
    return nil
  end

  local month_count = end_serial - start_serial + 1
  local scale_value = div.attributes["scale"] or "month"
  local scale = gantt_scale(scale_value)
  if scale == nil then
    gantt_warning("未知时间尺度“" .. tostring(scale_value) .. "”，已回退到 month；可用 month、bimonth、quarter、half-year。")
    scale = gantt_scale("month")
  end
  local period_count = math.ceil(month_count / scale.step)
  local label_style = div.attributes["label-style"] or div.attributes["month-label"] or "month"
  local months = {}
  local year_groups = {}
  local previous_start_year = nil
  local current_year_label = nil
  local current_year_span = 0
  for index = 0, period_count - 1 do
    local period_start = start_serial + index * scale.step
    local period_end = math.min(period_start + scale.step - 1, end_serial)
    local period_span = period_end - period_start + 1
    local start_year = math.floor(period_start / 12)
    local end_year = math.floor(period_end / 12)
    local year_label = start_year == end_year and tostring(start_year) or string.format("%04d–%04d", start_year, end_year)
    local is_year_start = index == 0 or start_year ~= previous_start_year
    table.insert(
      months,
      "(label: [" .. typst_escape_text(period_label(period_start, period_end, scale.name, label_style)) ..
        "], year-label: [" .. typst_escape_text(year_label) ..
        "], year-start: " .. tostring(is_year_start) ..
        ", span: " .. tostring(period_span) .. ")"
    )
    if year_label == current_year_label then
      current_year_span = current_year_span + period_span
    else
      if current_year_label ~= nil then
        table.insert(year_groups, "(label: [" .. typst_escape_text(current_year_label) .. "], span: " .. tostring(current_year_span) .. ")")
      end
      current_year_label = year_label
      current_year_span = period_span
    end
    previous_start_year = start_year
  end
  if current_year_label ~= nil then
    table.insert(year_groups, "(label: [" .. typst_escape_text(current_year_label) .. "], span: " .. tostring(current_year_span) .. ")")
  end

  local task_header = div.attributes["task-header"]
  if task_header == nil or task_header:match("^%s*$") then
    task_header = "任务"
  end
  local items = {}
  local max_task_width = text_width_em(task_header)
  local max_label_width_em = positive_em(div.attributes["max-label-width"], 12)
  local task_number_enabled = typst_bool_arg(div.attributes["task-number"], "false") == "true"
  -- 编号徽标直径与任务字号一致，再计入其后的中等间距。
  local task_number_width_em = task_number_enabled and 0.86 or 0
  local task_number = 0
  local task_records = {}
  local footer_notes = {}
  for _, item_blocks in ipairs(list) do
    local footer_note, is_footer_note = parse_gantt_footer_note(item_blocks)
    if is_footer_note then
      if footer_note == nil or footer_note == "" then
        gantt_warning("忽略了内容为空的图底部备注。")
      else
        table.insert(footer_notes, "[" .. typst_escape_text(footer_note) .. "]")
      end
    else
      local task, item_start, item_end, note, progress_value = parse_gantt_item(item_blocks)
      local task_kind, display_task = gantt_task_kind(task)
      task = display_task
      local progress = parse_gantt_progress(progress_value, task)
      local item_start_serial = month_serial(item_start)
      local item_end_serial = month_serial(item_end)
      if task == nil or task == "" then
        gantt_warning("忽略了任务名称为空的列表项。")
      elseif item_start_serial == nil or item_end_serial == nil then
        gantt_warning("任务“" .. task .. "”的日期无效，请使用 YYYY-MM。")
      elseif item_end_serial < item_start_serial then
        gantt_warning("任务“" .. task .. "”的结束月份早于开始月份，已忽略。")
      else
        local task_width = text_width_em(task)
        max_task_width = math.max(max_task_width, task_width)
        local clipped_start = math.max(item_start_serial, start_serial)
        local clipped_end = math.min(item_end_serial, end_serial)
        if clipped_start <= clipped_end then
          task_number = task_number + 1
          local display_number = task_number
          local offset = clipped_start - start_serial
          local duration = clipped_end - clipped_start + 1
          local point_offset = clipped_start - start_serial + 0.5
          local bar_offset = offset
          local bar_duration = duration
          local note_values = {}
          local note_widths = {}
          if note ~= nil and note ~= "" then
            for _, note_item in ipairs(split_gantt_notes(note)) do
              table.insert(note_values, "[" .. typst_escape_text(note_item) .. "]")
              table.insert(note_widths, text_width_em(note_item))
            end
          end
          local notes_tuple = "()"
          if #note_values > 0 then
            -- Typst 的单元素数组必须保留尾随逗号，否则会被解析成普通 content。
            notes_tuple = "(" .. table.concat(note_values, ", ") .. ",)"
          end
          table.insert(task_records, {
            task = task,
            task_width = task_width,
            kind = task_kind,
            number = display_number,
            offset = offset,
            point_offset = point_offset,
            duration = duration,
            bar_offset = bar_offset,
            bar_duration = bar_duration,
            notes_tuple = notes_tuple,
            note_widths = note_widths,
            progress = progress,
          })
        else
          gantt_warning("任务“" .. task .. "”不在甘特图显示范围内，已忽略。")
        end
      end
    end
  end

  local label_width = div.attributes["label-width"]
  local effective_label_content_em = max_label_width_em - 0.9 - task_number_width_em
  if label_width == nil or label_width == "" or label_width == "auto" then
    local auto_width = math.min(max_task_width + 1.2 + task_number_width_em, max_label_width_em)
    label_width = string.format("%.2fem", auto_width)
    effective_label_content_em = math.max(2, auto_width - 0.9 - task_number_width_em)
  else
    effective_label_content_em = math.max(2, positive_em(label_width, max_label_width_em) - 0.9 - task_number_width_em)
  end

  for _, record in ipairs(task_records) do
    local task_lines = math.max(1, math.ceil(record.task_width / effective_label_content_em))
    local note_capacity = math.max(4, (record.duration / month_count) * 44 - 1.6)
    local note_lines = 0
    for _, note_width in ipairs(record.note_widths) do
      note_lines = note_lines + math.max(1, math.ceil(note_width / note_capacity))
    end
    table.insert(
      items,
      "(task: [" .. typst_escape_text(record.task) ..
        "], kind: \"" .. record.kind ..
        "\", number: " .. (record.number == nil and "none" or tostring(record.number)) ..
        ", offset: " .. tostring(record.offset) ..
        ", point-offset: " .. string.format("%.4f", record.point_offset) ..
        ", duration: " .. tostring(record.duration) ..
        ", bar-offset: " .. string.format("%.4f", record.bar_offset) ..
        ", bar-duration: " .. string.format("%.4f", record.bar_duration) ..
        ", task-lines: " .. tostring(task_lines) ..
        ", note-lines: " .. tostring(note_lines) ..
        ", progress: " .. (record.progress == nil and "none" or string.format("%.4f", record.progress / 100)) ..
        ", notes: " .. record.notes_tuple .. ")"
    )
  end

  local today_offset = "none"
  local today_label = div.attributes["today-label"] or "今天"
  local today_serial = month_serial(div.attributes["today"])
  if div.attributes["today"] ~= nil and today_serial == nil then
    gantt_warning("today 无效，请使用 YYYY-MM。")
  elseif today_serial ~= nil and today_serial >= start_serial and today_serial <= end_serial then
    today_offset = tostring(today_serial - start_serial + 0.5)
  end

  local note_list_inset = absolute_length_arg(div.attributes["note-list-inset"], "0.8mm", "note-list-inset")

  return pandoc.RawBlock(
    "typst",
    "#qgantt((" .. table.concat(items, ", ") .. ",)" ..
      ", (" .. table.concat(months, ", ") .. ",)" ..
      ", year-groups: (" .. table.concat(year_groups, ", ") .. ",)" ..
      ", footer-notes: (" .. table.concat(footer_notes, ", ") .. (#footer_notes > 0 and "," or "") .. ")" ..
      ", title: " .. typst_content_arg(div.attributes["title"]) ..
      ", task-header: " .. typst_content_arg(task_header) ..
      ", label-width: " .. label_width ..
      ", today-offset: " .. today_offset ..
      ", today-label: [" .. typst_escape_text(today_label) .. "]" ..
      ", row-height: " .. (div.attributes["row-height"] or "auto") ..
      ", row-gap: " .. (div.attributes["row-gap"] or "0pt") ..
      ", note-inside-threshold: 3" ..
      ", note-gap: " .. (div.attributes["note-gap"] or "auto") ..
      ", note-list-inset: " .. note_list_inset ..
      ", note-bullet-gap: " .. (div.attributes["note-bullet-gap"] or "0.10em") ..
      ", bar-height: " .. (div.attributes["bar-height"] or "82%") ..
      ", bar-radius: " .. (div.attributes["bar-radius"] or "2pt") ..
      ", show-year: " .. typst_bool_arg(div.attributes["show-year"], "true") ..
      ", show-notes: " .. typst_bool_arg(div.attributes["show-notes"], "true") ..
      ", show-footer-notes: " .. typst_bool_arg(div.attributes["show-footer-notes"], "true") ..
      ", footer-note-gap: " .. (div.attributes["footer-note-gap"] or "0.12em") ..
      ", show-progress: " .. typst_bool_arg(div.attributes["show-progress"], "true") ..
      ", progress-label: " .. typst_bool_arg(div.attributes["progress-label"], "true") ..
      ", task-number: " .. typst_bool_arg(div.attributes["task-number"], "false") ..
      ", accent-color: " .. (div.attributes["accent-color"] or "none") ..
      ", milestone-color: " .. (div.attributes["milestone-color"] or "orange") ..
      ", milestone-darken: " .. (div.attributes["milestone-darken"] or "20%") ..
      ")"
  )
end

function Div(div)
  if has_class(div.classes, "list") then
    return list_from_div(div)
  end

  if has_class(div.classes, "logo") then
    return logo_from_div(div)
  end

  if has_class(div.classes, "quote-slide") then
    return quote_slide_from_div(div)
  end

  if has_class(div.classes, "keyvalue") then
    return metrics_from_div(div)
  end

  if has_class(div.classes, "keypoints") then
    return keypoints_from_div(div)
  end

  if has_class(div.classes, "cards") then
    return cards_from_div(div)
  end

  if has_class(div.classes, "flow") then
    return flow_from_div(div)
  end

  if has_class(div.classes, "card2") then
    return card2_from_div(div)
  end

  if has_class(div.classes, "timeline") then
    return timeline_from_div(div)
  end

  if has_class(div.classes, "figure-insight") then
    return figure_insight_from_div(div)
  end

  if has_class(div.classes, "image-list") then
    return image_list_from_div(div)
  end

  if has_class(div.classes, "gantt") then
    return gantt_from_div(div)
  end

  local kind = nil
  for class, value in pairs(callout_kinds) do
    if has_class(div.classes, class) then
      kind = value
      break
    end
  end

  if kind == nil then
    return nil
  end

  local title = nil
  local body_blocks = {}

  for i, block in ipairs(div.content) do
    if i == 1 and block.t == "Header" then
      title = pandoc.utils.stringify(block.content)
    else
      table.insert(body_blocks, block)
    end
  end

  local body = pandoc.write(pandoc.Pandoc(body_blocks), "typst", { wrap_text = "none" })
  local title_arg = "none"
  if title ~= nil and title ~= "" then
    title_arg = "[" .. typst_escape_text(title) .. "]"
  end

  return pandoc.RawBlock(
    "typst",
    "#qcallout(kind: \"" .. kind .. "\", title: " .. title_arg .. ")[\n" .. body .. "\n]"
  )
end

function Header(header)
  if not has_class(header.classes, "logo") then
    return nil
  end

  local logo_blocks = logo_from_header(header)
  if logo_blocks == nil then
    return nil
  end

  local classes = {}
  for _, class in ipairs(header.classes) do
    if class ~= "logo" then
      table.insert(classes, class)
    end
  end
  header.classes = classes

  local blocks = { header }
  for _, block in ipairs(logo_blocks) do
    table.insert(blocks, block)
  end
  return blocks
end
