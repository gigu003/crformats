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
local utils = require 'pandoc.utils'
local stringify = utils.stringify

-- [import]
local from_scholarly = require "from_scholarly_metadata"
local resolve_institutes = from_scholarly.resolve_institutes
-- [/import]

local M = {}

-- [i18n]
--- Check if the document language is Chinese (zh).
-- @param lang  Pandoc MetaValue (MetaInlines/MetaString) or nil
-- @return boolean
function M.is_chinese_lang(lang)
  if lang == nil then
    return true  -- default to Chinese
  end
  local lang_str = utils.stringify(lang)
  return lang_str:sub(1, 2) == "zh"
end

--- Locale strings for UI labels.
M.locale = {
  zh = {
    equal_contributor = "作者对本研究贡献相同",
    correspondence     = "通讯作者：",
  },
  en = {
    equal_contributor = "These authors contributed equally to this work.",
    correspondence     = "Correspondence:",
  },
}
-- [/i18n]

-- from @kapsner
local function normalize_affiliations(affiliations)
  local affiliations_by_id = {}
  local affiliation_ids = List:new{}
  local affiliation_aliases = {}
  for _, affil in ipairs(affiliations or {}) do
    if type(affil) == "table" and affil.id ~= nil and affil.name ~= nil then
      local affil_id = stringify(affil.id)
      local affil_name = stringify(affil.name)
      if affil_name ~= "" and not affil_id:match("^aff%-%d+$") then
        local existing = affiliations_by_id[affil_id]
        local should_replace = existing == nil
          or stringify(existing.name) == affil_id
          or #affil_name > #stringify(existing.name)

        if existing == nil then
          affiliation_ids:insert(affil_id)
        end
        if should_replace then
          affil.id = pandoc.MetaString(affil_id)
          affiliations_by_id[affil_id] = affil
        end
      elseif affil_name ~= "" and affil_id:match("^aff%-%d+$") then
        affiliation_aliases[affil_id] = affil_name
      end
    end
  end

  local affiliations_norm = List:new{}
  for _, affil_id in ipairs(affiliation_ids) do
    local affil = affiliations_by_id[affil_id]
    if affil ~= nil then
      affil.index = pandoc.MetaInlines(pandoc.Str(tostring(#affiliations_norm + 1)))
      affiliations_norm:insert(affil)
    end
  end

  for alias_id, target_id in pairs(affiliation_aliases) do
    local target = affiliations_by_id[target_id]
    if target ~= nil then
      local alias = {
        id = alias_id,
        name = target.name,
        index = target.index,
        hidden = true,
      }
      affiliations_norm:insert(alias)
    end
  end
  return affiliations_norm
end
M.normalize_affiliations = normalize_affiliations

-- from https://stackoverflow.com/a/2282547
local function has_key(set, key)
  return set[key] ~= nil
end
M.has_key = has_key

-- from @kapsner
local function normalize_authors(affiliations)
  return function(auth)
    auth.id = pandoc.MetaString(stringify(auth.name))
    auth.affiliations = resolve_institutes(
      auth.affiliations,
      affiliations
    )
    return auth
  end
end
M.normalize_authors = normalize_authors

return M
