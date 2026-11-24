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
  return text
end

function Div(div)
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