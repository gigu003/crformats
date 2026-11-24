--[[
authors-block – affiliations block extension for quarto

Copyright (c) 2023 Lorenz A. Kapsner

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

local List = require 'pandoc.List'
local stringify = pandoc.utils.stringify

-- [import]
local from_utils = require "utils"
local normalize_affiliations = from_utils.normalize_affiliations
local normalize_authors = from_utils.normalize_authors

local from_authors = require "from_author_info_blocks"
local default_marks = from_authors.default_marks
local create_equal_contributors_block = from_authors.create_equal_contributors_block
local create_affiliations_blocks = from_authors.create_affiliations_blocks
local create_correspondence_blocks = from_authors.create_correspondence_blocks
local is_corresponding_author = from_authors.is_corresponding_author
local author_inline_generator = from_authors.author_inline_generator
local create_authors_inlines = from_authors.create_authors_inlines
local create_author_info_section = from_authors.create_author_info_section
local chinese_et_al = require "chinese_et_al"
-- [/import]

local function meta_truthy(value)
  if value == nil then
    return false
  end
  if type(value) == "boolean" then
    return value
  end
  local value_str = stringify(value):lower()
  return value_str == "true" or value_str == "yes" or value_str == "1"
end

local function meta_falsey(value)
  if value == nil then
    return false
  end
  if type(value) == "boolean" then
    return not value
  end
  local value_str = stringify(value):lower()
  return value_str == "false" or value_str == "no" or value_str == "0"
end

local function get_qauthor_config(meta)
  return meta["qcjournal"] or meta["qauthor-block"] or {}
end

local function get_author_separator(meta, qauthor_config, lang_key)
  local q_sep = qauthor_config["author-separator"]
  if type(q_sep) == "table" then
    return q_sep[lang_key] or q_sep.between or q_sep
  end
  if q_sep ~= nil then
    return q_sep
  end
  if lang_key == "zh" then
    return meta["author-separator"]
  end
  return nil
end

local function should_show_title(qauthor_config, lang_key, default_value)
  local show_title = qauthor_config["show-title"]
  if type(show_title) == "table" then
    local lang_value = show_title[lang_key]
    if lang_value ~= nil then
      return not meta_falsey(lang_value)
    end
    return default_value
  end
  if show_title ~= nil then
    return not meta_falsey(show_title)
  end
  return default_value
end

local function get_title_style(qauthor_config, lang_key)
  local title_style = qauthor_config["title-style"]
  if type(title_style) == "table" then
    return title_style[lang_key] or title_style.default
  end
  return title_style
end

local function get_config_value(config, key, lang_key, default_value)
  local value = config[key]
  if type(value) == "table" then
    return value[lang_key] or value.default or default_value
  end
  if value ~= nil then
    return value
  end
  return default_value
end

local function get_author_list_style(qauthor_config, lang_key)
  return get_config_value(qauthor_config, "author-list-style", lang_key, "Authors")
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

local function is_header(block, level, text, case_insensitive)
  if block == nil or block.t ~= "Header" or block.level ~= level then
    return false
  end
  local block_text = stringify(block.content)
  local target_text = stringify(text)
  if case_insensitive then
    return block_text:lower() == target_text:lower()
  end
  return block_text == target_text
end

local function section_kind(block, qauthor_config)
  if is_header(block, 2, get_config_value(qauthor_config, "abstract-headings", "zh", "摘要"), false) then
    return "zh_abstract"
  end
  if is_header(block, 2, get_config_value(qauthor_config, "keyword-headings", "zh", "关键词"), false) then
    return "zh_keywords"
  end
  if is_header(block, 2, get_config_value(qauthor_config, "abstract-headings", "en", "Abstract"), true) then
    return "en_abstract"
  end
  if is_header(block, 2, get_config_value(qauthor_config, "keyword-headings", "en", "Keywords"), true) then
    return "en_keywords"
  end
  return nil
end

local function extract_bilingual_frontmatter_sections(blocks, qauthor_config)
  local sections = {
    zh_abstract = nil,
    zh_keywords = nil,
    en_abstract = nil,
    en_keywords = nil,
    remaining = List:new{}
  }
  local current_kind = nil

  for _, block in ipairs(blocks or {}) do
    local kind = section_kind(block, qauthor_config)
    if kind ~= nil and sections[kind] == nil then
      current_kind = kind
      sections[current_kind] = List:new{block}
    elseif block.t == "Header" and block.level <= 2 then
      current_kind = nil
      sections.remaining:insert(block)
    elseif current_kind ~= nil then
      sections[current_kind]:insert(block)
    else
      sections.remaining:insert(block)
    end
  end

  return sections
end

local function append_space_if_needed(inlines)
  if #inlines > 0 then
    inlines:insert(pandoc.Space())
  end
end

local function block_to_inlines(block)
  if block == nil then
    return List:new{}
  end
  if block.t == "Para" or block.t == "Plain" then
    return List.clone(block.content)
  end
  local text = stringify(block)
  if text == "" then
    return List:new{}
  end
  return List:new{pandoc.Str(text)}
end

local function append_blocks_as_inlines(target, blocks)
  local first = true
  for _, block in ipairs(blocks or {}) do
    local inlines = block_to_inlines(block)
    if #inlines > 0 then
      if not first then
        target:insert(pandoc.Space())
      end
      target:extend(inlines)
      first = false
    end
  end
end

local function create_inline_structured_abstract(section_blocks, lang_key, qauthor_config)
  if section_blocks == nil then
    return nil
  end
  local prefix = stringify(get_config_value(
    qauthor_config,
    "abstract-prefix",
    lang_key,
    lang_key == "zh" and "【摘要】" or "Abstract"
  ))
  local result = List:new{pandoc.Strong{pandoc.Str(prefix)}}
  local first_section = true
  local current_heading = nil
  local current_blocks = List:new{}

  local function flush_section()
    if current_heading == nil then
      return
    end
    if not first_section or lang_key == "en" then
      result:insert(pandoc.Space())
    end
    result:insert(pandoc.Strong{pandoc.Str(current_heading)})
    result:insert(pandoc.Space())
    append_blocks_as_inlines(result, current_blocks)
    first_section = false
    current_heading = nil
    current_blocks = List:new{}
  end

  local unstructured_blocks = List:new{}
  for i, block in ipairs(section_blocks) do
    if i ~= 1 then -- skip the level-2 abstract heading itself
      if block.t == "Header" and block.level == 3 then
        flush_section()
        current_heading = stringify(block.content)
        current_blocks = List:new{}
      elseif current_heading ~= nil then
        current_blocks:insert(block)
      else
        unstructured_blocks:insert(block)
      end
    end
  end
  flush_section()

  if #unstructured_blocks > 0 and first_section then
    result:insert(pandoc.Space())
    append_blocks_as_inlines(result, unstructured_blocks)
  end

  return with_custom_style(
    List:new{pandoc.Para(result)},
    get_config_value(qauthor_config, "abstract-style", lang_key, "Abstract"),
    "qauthor-abstract-" .. lang_key
  )
end

local function create_inline_keywords(section_blocks, lang_key, qauthor_config)
  if section_blocks == nil then
    return nil
  end
  local prefix = stringify(get_config_value(
    qauthor_config,
    "keyword-prefix",
    lang_key,
    lang_key == "zh" and "【关键词】" or "Keywords:"
  ))
  local result = List:new{pandoc.Strong{pandoc.Str(prefix)}}
  if lang_key == "en" then
    result:insert(pandoc.Space())
  end
  local content_blocks = List:new{}
  for i, block in ipairs(section_blocks) do
    if i ~= 1 then -- skip the level-2 keywords heading itself
      content_blocks:insert(block)
    end
  end
  append_blocks_as_inlines(result, content_blocks)
  return with_custom_style(
    List:new{pandoc.Para(result)},
    get_config_value(qauthor_config, "keyword-style", lang_key, "Keywords"),
    "qauthor-keywords-" .. lang_key
  )
end

local function should_move_abstracts(qauthor_config)
  if qauthor_config["move-abstracts"] == nil then
    return true
  end
  return not meta_falsey(qauthor_config["move-abstracts"])
end

-- This is the main-part
function Pandoc(doc)
  if doc == nil or doc.meta == nil then
    return doc
  end
  local meta = doc.meta
  local body = List:new{}
  local qauthor_config = get_qauthor_config(meta)
  local bilingual = meta_truthy(qauthor_config.bilingual)
  
  local mark = function (mark_name) return default_marks[mark_name] end


  meta.affiliations = normalize_affiliations(meta.affiliations)
  meta.author = meta.authors:map(normalize_authors(meta.affiliations))

  if bilingual then
    local frontmatter_sections = should_move_abstracts(qauthor_config)
      and extract_bilingual_frontmatter_sections(doc.blocks, qauthor_config)
      or {remaining = doc.blocks}

    body:extend(create_author_info_section(meta.author, meta.affiliations, mark, {
      lang = pandoc.MetaString("zh"),
      title = meta.title,
      title_class = "qauthor-title-zh",
      show_title = should_show_title(qauthor_config, "zh", false),
      author_separator = get_author_separator(meta, qauthor_config, "zh"),
      name_field = "name",
      affiliation_name_field = "name",
      author_list_style = get_author_list_style(qauthor_config, "zh"),
      author_list_class = "qauthor-author-list-zh",
      affiliation_style = get_config_value(qauthor_config, "affiliation-style", "zh", "Affiliations"),
      correspondence_style = get_config_value(qauthor_config, "correspondence-style", "zh", "Author Notes"),
      equal_contributor_style = get_config_value(qauthor_config, "equal-contributor-style", "zh", "Author Notes"),
    }) or {})
    body:extend(create_inline_structured_abstract(frontmatter_sections.zh_abstract, "zh", qauthor_config) or {})
    body:extend(create_inline_keywords(frontmatter_sections.zh_keywords, "zh", qauthor_config) or {})

    body:insert(pandoc.Para{})

    body:extend(create_author_info_section(meta.author, meta.affiliations, mark, {
      lang = pandoc.MetaString("en"),
      title = meta["title-en"],
      title_class = "qauthor-title-en",
      title_style = get_title_style(qauthor_config, "en") or pandoc.MetaString("Subtitle"),
      show_title = should_show_title(qauthor_config, "en", true),
      author_separator = get_author_separator(meta, qauthor_config, "en"),
      name_field = "name-en",
      affiliation_name_field = "name-en",
      author_list_style = get_author_list_style(qauthor_config, "en"),
      author_list_class = "qauthor-author-list-en",
      affiliation_style = get_config_value(qauthor_config, "affiliation-style", "en", "Affiliations"),
      correspondence_style = get_config_value(qauthor_config, "correspondence-style", "en", "Author Notes"),
      equal_contributor_style = get_config_value(qauthor_config, "equal-contributor-style", "en", "Author Notes"),
    }) or {})
    body:extend(create_inline_structured_abstract(frontmatter_sections.en_abstract, "en", qauthor_config) or {})
    body:extend(create_inline_keywords(frontmatter_sections.en_keywords, "en", qauthor_config) or {})

    body:extend(frontmatter_sections.remaining)

    -- In bilingual mode Quarto still owns the native title so DOCX can keep
    -- the reference.docx Title style. The extension owns author/affiliation
    -- blocks and the optional English title.
    meta.author = nil
    meta.affiliations = nil
  else
    body:extend(create_affiliations_blocks(meta.affiliations) or {})
    body:extend(create_correspondence_blocks(meta.author, mark, meta.lang) or {})
    body:extend(create_equal_contributors_block(meta.author, mark, meta.lang) or {})
    body:extend(doc.blocks)
    
    -- Overwrite authors with formatted values. We use a single, formatted
    -- string for most formats. LaTeX output, however, looks nicer if we
    -- provide a authors as a list.
    meta.author = pandoc.MetaInlines(create_authors_inlines(meta.author, mark, meta.lang, meta["author-separator"]))
    -- Institute info is now baked into the affiliations block.
    meta.affiliations = nil
  end
  
  local result = pandoc.Pandoc(body, meta)
  return chinese_et_al.process(result, qauthor_config)
end
