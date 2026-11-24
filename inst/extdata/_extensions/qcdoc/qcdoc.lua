--[[
qcdoc – minimal Quarto extension for Chinese reports
Copyright (c) 2024 Qiong Chen

This filter provides:
1. Chinese et-al processing for bilingual bibliographies
2. Heading numbering for Chinese reports (一、1) 1. a.)
]]

local chinese_et_al = require "chinese_et_al"

local function stringify(value)
  if value == nil then return "" end
  if type(value) == "string" then return value end
  return pandoc.utils.stringify(value)
end

local function truthy(value)
  if value == nil then return false end
  if type(value) == "boolean" then return value end
  if type(value) == "table" and value.t == "MetaBool" then return value.c end
  local value_str = stringify(value):lower()
  return value_str == "true" or value_str == "yes" or value_str == "1"
end

----------------------------------------------------------------------
-- Heading numbering
----------------------------------------------------------------------

local CHINESE_NUMBERS = {
  "一", "二", "三", "四", "五", "六", "七", "八", "九", "十",
  "十一", "十二", "十三", "十四", "十五", "十六", "十七", "十八", "十九", "二十",
  "二十一", "二十二", "二十三", "二十四", "二十五", "二十六", "二十七", "二十八", "二十九", "三十"
}

local LATIN_LETTERS = {
  "a", "b", "c", "d", "e", "f", "g", "h", "i", "j",
  "k", "l", "m", "n", "o", "p", "q", "r", "s", "t",
  "u", "v", "w", "x", "y", "z"
}

-- Numbering formats keyed by RELATIVE level (1 = top-most, 2 = second, ...)
local NUMBERING_FORMATS = {
  [1] = function(n) return (CHINESE_NUMBERS[n] or tostring(n)) .. "　" end,
  [2] = function(n) return tostring(n) .. ") " end,
  [3] = function(n) return tostring(n) .. ". " end,
  [4] = function(n) return (LATIN_LETTERS[n] or tostring(n)) .. ". " end,
}

local DEFAULT_MAX_RELATIVE_LEVEL = 4

local function is_unnumbered(header)
  return header.classes:includes("unnumbered")
end

-- Find the shallowest (smallest) heading level used among non-unnumbered headers
local function find_base_level(doc)
  local min_level = 7  -- Pandoc max is 6
  for _, block in ipairs(doc.blocks) do
    if block.t == "Header" and not is_unnumbered(block) then
      if block.level < min_level then
        min_level = block.level
      end
    end
  end
  return min_level
end

local function apply_heading_numbering(doc, max_relative_level)
  local base_level = find_base_level(doc)
  local max_absolute_level = math.min(base_level + max_relative_level - 1, 6)

  local counters = {}
  for i = 1, max_absolute_level do
    counters[i] = 1
  end

  local function reset_counters(from_level)
    for i = from_level, max_absolute_level do
      counters[i] = 1
    end
  end

  local new_blocks = {}
  for _, block in ipairs(doc.blocks) do
    if block.t == "Header" and not is_unnumbered(block) and block.level <= max_absolute_level then
      local abs_level = block.level
      local rel_level = abs_level - base_level + 1  -- 1-based relative level
      -- Reset all lower-level counters
      reset_counters(abs_level + 1)
      -- Build numbering prefix
      local prefix_func = NUMBERING_FORMATS[rel_level]
      if prefix_func == nil then
        -- Fallback: use digit format for levels beyond defined formats
        prefix_func = function(n) return tostring(n) .. ". " end
      end
      local prefix = prefix_func(counters[abs_level])
      -- Increment this level's counter
      counters[abs_level] = counters[abs_level] + 1
      -- Prepend numbering to header content
      local new_content = {pandoc.Str(prefix)}
      for _, inline in ipairs(block.content) do
        table.insert(new_content, inline)
      end
      block.content = new_content
    end
    table.insert(new_blocks, block)
  end
  return pandoc.Pandoc(new_blocks, doc.meta)
end

----------------------------------------------------------------------
-- Main Pandoc filter
----------------------------------------------------------------------

function Pandoc(doc)
  if doc == nil or doc.meta == nil then
    return doc
  end

  local config = doc.meta["qcdoc"] or {}

  -- 1. Chinese et-al processing
  doc = chinese_et_al.process(doc, config)

  -- 2. Heading numbering (enabled by default, can be disabled with numbering: false)
  local numbering = config["numbering"]
  local numbering_enabled = true
  local max_relative_level = DEFAULT_MAX_RELATIVE_LEVEL
  if type(numbering) == "table" then
    if numbering["enabled"] ~= nil then
      numbering_enabled = truthy(numbering["enabled"])
    end
    if numbering["depth"] ~= nil then
      max_relative_level = tonumber(stringify(numbering["depth"])) or DEFAULT_MAX_RELATIVE_LEVEL
    end
  elseif numbering ~= nil then
    numbering_enabled = truthy(numbering)
  end
  if numbering_enabled then
    doc = apply_heading_numbering(doc, max_relative_level)
  end

  return doc
end