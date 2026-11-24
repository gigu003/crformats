-- https://github.com/pandoc/lua-filters/commit/ca72210b453cc0d045360e0ae36448d019d7dfbf
--[[
affiliation-blocks – generate title components

Copyright © 2017–2021 Albert Krewinkel

Permission to use, copy, modify, and/or distribute this software for any purpose
with or without fee is hereby granted, provided that the above copyright notice
and this permission notice appear in all copies.

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH
REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND
FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT,
INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS
OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER
TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF
THIS SOFTWARE.
]]

-- from @kapsner
-- [import]
local from_utils = require "utils"
local has_key = from_utils.has_key
local is_chinese_lang = from_utils.is_chinese_lang
local i18n = from_utils.locale
-- [/import]
local M = {}

-- taken from https://github.com/pandoc/lua-filters/blob/1660794b991c3553968beb993f5aabb99b317584/author-info-blocks/author-info-blocks.lua
local List = require 'pandoc.List'
local utils = require 'pandoc.utils'
local stringify = utils.stringify

local function meta_value(value)
  return value ~= nil and stringify(value) or ""
end

local function get_localized_value(item, field_name, fallback_field_name)
  if type(item) ~= "table" then
    return nil
  end
  if field_name ~= nil and item[field_name] ~= nil and meta_value(item[field_name]) ~= "" then
    return item[field_name]
  end
  -- Quarto stores non-standard author/affiliation keys such as `name-en`
  -- under the nested `metadata` map. Look there before falling back.
  if field_name ~= nil
      and type(item.metadata) == "table"
      and item.metadata[field_name] ~= nil
      and meta_value(item.metadata[field_name]) ~= "" then
    return item.metadata[field_name]
  end
  if fallback_field_name ~= nil and item[fallback_field_name] ~= nil and meta_value(item[fallback_field_name]) ~= "" then
    return item[fallback_field_name]
  end
  if fallback_field_name ~= nil
      and type(item.metadata) == "table"
      and item.metadata[fallback_field_name] ~= nil
      and meta_value(item.metadata[fallback_field_name]) ~= "" then
    return item.metadata[fallback_field_name]
  end
  return nil
end

local function value_to_inlines(value)
  if value == nil then
    return List:new{}
  end
  if type(value) == "table" and value.literal ~= nil then
    return List.clone(value.literal)
  end
  if type(value) == "table" and value[1] ~= nil then
    return List.clone(value)
  end
  local value_str = stringify(value)
  if value_str == "" then
    return List:new{}
  end
  return List:new{pandoc.Str(value_str)}
end

local function with_custom_style(blocks, style_name, class_name)
  if blocks == nil then
    return nil
  end
  local style = style_name ~= nil and stringify(style_name) or ""
  if style == "" then
    return blocks
  end
  return List:new{
    pandoc.Div(
      blocks,
      pandoc.Attr("", class_name ~= nil and {class_name} or {}, { ["custom-style"] = style })
    )
  }
end


-- taken from https://github.com/pandoc/lua-filters/blob/1660794b991c3553968beb993f5aabb99b317584/author-info-blocks/author-info-blocks.lua
local default_marks = {
  corresponding_author = FORMAT == 'latex'
    and {pandoc.RawInline('latex', '*')}
    or {pandoc.Str '†'},
  equal_contributor = FORMAT == 'latex'
    and {pandoc.RawInline('latex', '$\\dagger{}$')}
    or {pandoc.Str '*'},
}
M.default_marks = default_marks

-- modified by @kapsner
-- taken from https://github.com/pandoc/lua-filters/blob/1660794b991c3553968beb993f5aabb99b317584/author-info-blocks/author-info-blocks.lua
local function is_equal_contributor(author)
  if has_key(author, "attributes") then
    return author.attributes["equal-contributor"]
  end
  return nil
end

-- taken from https://github.com/pandoc/lua-filters/blob/1660794b991c3553968beb993f5aabb99b317584/author-info-blocks/author-info-blocks.lua
--- Create equal contributors note.
--- 生成共同作者标记
local function create_equal_contributors_block(authors, mark, lang, style_name)
  local lang_key = is_chinese_lang(lang) and "zh" or "en"
  local notes = i18n[lang_key].equal_contributor

  local has_equal_contribs = List:new(authors):find_if(is_equal_contributor)
  if not has_equal_contribs then
    return nil
  end
  
  local contributors = {
    pandoc.Superscript(mark'equal_contributor'),
    pandoc.Space(),
    pandoc.Str(notes)
  }
  return with_custom_style(
    List:new{pandoc.Para(contributors)},
    style_name,
    "qauthor-equal-contributor"
  )
end
M.create_equal_contributors_block = create_equal_contributors_block


-- taken from https://github.com/pandoc/lua-filters/blob/1660794b991c3553968beb993f5aabb99b317584/author-info-blocks/author-info-blocks.lua
local function intercalate(lists, elem)
  local result = List:new{}
  for i = 1, (#lists - 1) do
    result:extend(lists[i])
    result:extend(elem)
  end
  if #lists > 0 then
    result:extend(lists[#lists])
  end
  return result
end

-- taken from https://github.com/pandoc/lua-filters/blob/1660794b991c3553968beb993f5aabb99b317584/author-info-blocks/author-info-blocks.lua
--- Check whether the given author is a corresponding author
local function is_corresponding_author(author)
  if has_key(author, "attributes") then
    if author.attributes["corresponding"] then
      return author.email
    end
  end
  return nil
end
M.is_corresponding_author = is_corresponding_author

-- taken from https://github.com/pandoc/lua-filters/blob/1660794b991c3553968beb993f5aabb99b317584/author-info-blocks/author-info-blocks.lua
--- Generate a block element containing the correspondence information
local function create_correspondence_blocks(authors, mark, lang, name_field, style_name)
  local lang_key = is_chinese_lang(lang) and "zh" or "en"
  local corresponding_authors = List:new{}
  for _, author in ipairs(authors) do
    if is_corresponding_author(author) then
      local mailto = 'mailto:' .. utils.stringify(author.email)
      local author_name = value_to_inlines(get_localized_value(author, name_field or "name", "name"))
      local author_with_mail = List:new{}
      author_with_mail:extend(author_name)
      author_with_mail:extend(List:new{pandoc.Str ",", pandoc.Space(), pandoc.Str 'Email: '})
      author_with_mail:extend(value_to_inlines(author.email))
      local link = pandoc.Link(author_with_mail, mailto)
      table.insert(corresponding_authors, {link})
    end
  end
  if #corresponding_authors == 0 then
    return nil
  end
  
  local label = i18n[lang_key].correspondence
  
  local correspondence = List:new{
    pandoc.Superscript(mark'corresponding_author'),
    pandoc.Str(label),
    pandoc.Space()
  }
  local sep = List:new{pandoc.Str(";"), pandoc.Space()}
  local correspondence_final = List:new{}
  correspondence_final:extend(correspondence)
  correspondence_final:extend(intercalate(corresponding_authors, sep))
  return with_custom_style(
    List:new{pandoc.Para(correspondence_final)},
    style_name,
    "qauthor-correspondence"
  )
end
M.create_correspondence_blocks = create_correspondence_blocks

-- taken from https://github.com/pandoc/lua-filters/blob/1660794b991c3553968beb993f5aabb99b317584/author-info-blocks/author-info-blocks.lua
--- Create inlines for a single author (includes all author notes)
local function author_inline_generator (get_mark, name_field)
  return function (author)
    local author_marks = List:new{}

    local idx_str
    for _, idx in ipairs(author.affiliations) do
      if type(idx) ~= 'table' then
        idx_str = tostring(idx)
      else
        idx_str = stringify(idx)
      end
      author_marks[#author_marks + 1] = {pandoc.Str(idx_str)}
    end
    
    -- modified by @kapsner
    if has_key(author, "attributes") then
      if author.attributes["equal-contributor"] then
        author_marks[#author_marks + 1] = get_mark 'equal_contributor'
      end
    end
    
    if is_corresponding_author(author) then
      ---author_marks[#author_marks + 1] = get_mark 'corresponding_author'
      table.insert(author_marks, get_mark 'corresponding_author')
    end
    -- modified by @kapsner
    if FORMAT:match 'latex' then
      ---author.name.literal[#author.name.literal + 1] = pandoc.Superscript(intercalate(author_marks, {pandoc.Str ','}))
      author.name.literal[#author.name.literal + 1] = pandoc.Superscript(intercalate(author_marks, {}))
      return author
    else
      local res = value_to_inlines(get_localized_value(author, name_field or "name", "name"))
      res[#res + 1] = pandoc.Superscript(intercalate(author_marks, {pandoc.Str ','}))
      return res
    end
  end
end
M.author_inline_generator = author_inline_generator

-- taken from https://github.com/pandoc/lua-filters/blob/1660794b991c3553968beb993f5aabb99b317584/author-info-blocks/author-info-blocks.lua
--- Parse a separator string into a Pandoc List of inlines.
--- Spaces must be represented as pandoc.Space(), not pandoc.Str(" "),
--- otherwise they can be dropped by Pandoc writers.
local function parse_separator(sep_str)
  if sep_str == nil then
    return nil
  end
  local nbsp = " "
  local result = List:new{}
  local text = ""

  local chars = List:new{}
  for char in sep_str:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
    chars:insert(char)
  end
  local only_spaces = #chars > 0
  for _, char in ipairs(chars) do
    if char ~= " " then
      only_spaces = false
      break
    end
  end

  if only_spaces then
    result:insert(pandoc.Space())
    for _ = 2, #chars do
      result:insert(pandoc.Str(nbsp))
    end
    return result
  end

  local flush_text = function()
    if text ~= "" then
      result:insert(pandoc.Str(text))
      text = ""
    end
  end

  -- Iterate UTF-8 characters so non-ASCII punctuation remains intact.
  for _, char in ipairs(chars) do
    if char == " " then
      flush_text()
      result:insert(pandoc.Str(nbsp))
    else
      text = text .. char
    end
  end
  flush_text()

  -- Quarto/Pandoc may strip trailing spaces from YAML metadata values like
  -- `author-separator: ",  "` before this filter sees them. If the visible
  -- separator ends with common punctuation, add a stable non-breaking space so
  -- punctuation-separated author lists still render with spacing in DOCX.
  local last_char = chars[#chars]
  if last_char == "," or last_char == "，" or last_char == ";" or last_char == "；" then
    result:insert(pandoc.Str(nbsp))
  end

  return result
end

--- Convert a separator MetaValue into a Pandoc List of inlines.
--- This preserves MetaInlines such as a single Space, which would be lost
--- if converted through pandoc.utils.stringify().
local function parse_separator_meta(sep_meta)
  if sep_meta == nil then
    return nil
  end
  if type(sep_meta) == "table" and sep_meta[1] ~= nil then
    return parse_separator(pandoc.utils.stringify(sep_meta))
  end
  local sep_str = pandoc.utils.stringify(sep_meta)
  if type(sep_meta) == "table" and sep_str == "" then
    return List:new{pandoc.Space()}
  end
  return parse_separator(sep_str)
end

--- Generate a list of inlines containing all authors.
-- @param authors   list of author objects
-- @param mark      function to retrieve default marks
-- @param lang      language meta field
-- @param sep_meta  optional author-separator meta value (string or {between, last})
local function create_authors_inlines(authors, mark, lang, sep_meta, name_field)
  local lang_key = is_chinese_lang(lang) and "zh" or "en"

  -- Resolve separators: user config > language defaults
  local between_sep, last_sep
  if sep_meta ~= nil then
    if type(sep_meta) == "table" and sep_meta.t == "MetaMap" then
      -- Object form: {between: ", ", last: ", and "}
      if sep_meta.between then
        between_sep = parse_separator_meta(sep_meta.between)
      end
      if sep_meta.last then
        last_sep = parse_separator_meta(sep_meta.last)
      end
    else
      -- String form: ", "
      between_sep = parse_separator_meta(sep_meta)
      last_sep = parse_separator_meta(sep_meta)
    end
  end

  -- Fallback to language-dependent defaults
  if between_sep == nil then
    between_sep = List:new{pandoc.Space(), pandoc.Space(), pandoc.Space()}
  end
  if last_sep == nil then
    if lang_key == "zh" then
      last_sep = List:new{pandoc.Space(), pandoc.Space(), pandoc.Space()}
    else
      last_sep = List:new{pandoc.Space(), pandoc.Str("and"), pandoc.Space()}
    end
  end

  local inlines_generator = author_inline_generator(mark, name_field)
  local inlines = List:new(authors):map(inlines_generator)

  local last_author = inlines[#inlines]
  inlines[#inlines] = nil

  local result = intercalate(inlines, between_sep)
  if #authors > 1 then
    if #authors == 2 then
      result:extend(last_sep)
    else
      result:extend(List:new{pandoc.Str("")} .. last_sep)
    end
  end
  result:extend(last_author)
  return result
end
M.create_authors_inlines = create_authors_inlines

-- taken from https://github.com/pandoc/lua-filters/blob/1660794b991c3553968beb993f5aabb99b317584/author-info-blocks/author-info-blocks.lua
--- Generate a block list all affiliations, marked with arabic numbers.
local function create_affiliations_blocks(affiliations, name_field, style_name)
  local affil_lines = List:new{}
  for _, affil in ipairs(affiliations or {}) do
    if type(affil) == "table" and affil.name ~= nil and not affil.hidden then
      local affil_name = stringify(get_localized_value(affil, name_field or "name", "name"))
      if affil_name ~= "" then
        local affil_number = affil.index and stringify(affil.index) or tostring(#affil_lines + 1)
        local num_inlines = List:new{
          pandoc.Superscript{pandoc.Str(affil_number)},
          pandoc.Space()
        }
        num_inlines:insert(pandoc.Str(affil_name))
        affil_lines:insert(num_inlines)
      end
    end
  end
  return with_custom_style(
    List:new{pandoc.Para(intercalate(affil_lines, {pandoc.LineBreak()}))},
    style_name,
    "qauthor-affiliations"
  )
end
M.create_affiliations_blocks = create_affiliations_blocks

local function create_title_block(title_meta, class_name, custom_style)
  local title = stringify(title_meta)
  if title == "" then
    return nil
  end
  local para = pandoc.Para(value_to_inlines(title_meta))
  local style = custom_style ~= nil and stringify(custom_style) or ""
  if style ~= "" then
    return pandoc.Div(
      {para},
      pandoc.Attr("", class_name ~= nil and {class_name} or {}, { ["custom-style"] = style })
    )
  end
  return para
end
M.create_title_block = create_title_block

local function create_author_info_section(authors, affiliations, mark, options)
  options = options or {}
  local blocks = List:new{}
  if options.show_title and options.title ~= nil then
    local title_block = create_title_block(options.title, options.title_class, options.title_style)
    if title_block ~= nil then
      blocks:insert(title_block)
    end
  end
  local author_inlines = create_authors_inlines(
    authors,
    mark,
    options.lang,
    options.author_separator,
    options.name_field
  )
  local author_para = pandoc.Para(author_inlines)
  local author_list_style = options.author_list_style ~= nil and stringify(options.author_list_style) or ""
  if author_list_style ~= "" then
    blocks:insert(pandoc.Div(
      {author_para},
      pandoc.Attr("", {options.author_list_class or "qauthor-author-list"}, { ["custom-style"] = author_list_style })
    ))
  else
    blocks:insert(author_para)
  end
  blocks:extend(create_affiliations_blocks(
    affiliations,
    options.affiliation_name_field,
    options.affiliation_style
  ) or {})
  blocks:extend(create_correspondence_blocks(
    authors,
    mark,
    options.lang,
    options.name_field,
    options.correspondence_style
  ) or {})
  blocks:extend(create_equal_contributors_block(
    authors,
    mark,
    options.lang,
    options.equal_contributor_style
  ) or {})
  return blocks
end
M.create_author_info_section = create_author_info_section

return M
