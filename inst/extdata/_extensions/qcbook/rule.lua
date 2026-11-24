local function typst_string_escape(s)
  s = tostring(s or "")
  s = s:gsub("\\", "\\\\")
  s = s:gsub('"', '\\"')
  s = s:gsub("\n", "\\n")
  return s
end

local function typst_content_escape(s)
  s = tostring(s or "")
  s = s:gsub("\\", "\\\\")
  s = s:gsub("%]", "\\]")
  return s
end

local function trim(s)
  return tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function typst_color_expr(value, fallback_expr)
  local raw = trim(value)

  if raw == "" then
    return fallback_expr
  end

  local hex = raw:gsub("^#", "")
  if hex:match("^%x%x%x$") or hex:match("^%x%x%x%x%x%x$") or hex:match("^%x%x%x%x%x%x%x%x$") then
    return string.format('rgb("%s")', hex)
  end

  -- Typst named colors, e.g. green, red, blue, black.
  -- Restrict to a simple identifier to avoid injecting arbitrary Typst code.
  if raw:match("^[%a_][%w_%-]*$") then
    return raw
  end

  return fallback_expr
end

function Div(el)
  if not FORMAT:match("typst") then
    return nil
  end

  if el.classes:includes("rule") then
    local title = typst_string_escape(el.attributes["title"] or "")
    local source = typst_string_escape(el.attributes["source"] or "")
    local color = typst_color_expr(el.attributes["color"], 'rgb("1e3a8a")')
    local fill = typst_color_expr(el.attributes["fill"], 'rgb("f8f9fb")')
    local body = typst_content_escape(pandoc.utils.stringify(el.content))

    return pandoc.RawBlock(
      "typst",
      string.format(
        '#rule(title: "%s", source: "%s", color: %s, fill: %s, body: [%s])',
        title,
        source,
        color,
        fill,
        body
      )
    )
  end
end