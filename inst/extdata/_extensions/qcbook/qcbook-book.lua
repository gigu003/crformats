-- qcbook-book.lua
-- Preserve Quarto book structural metadata for Typst output.
--
-- Quarto's final Typst output lowers book `part` entries to ordinary
-- unnumbered level-1 headings. Running this filter at `post-quarto` lets us
-- read `file.bookItemType` before that distinction is lost and replace part
-- headings with an explicit Typst function call handled by typst-template.typ.

local function is_typst_book()
  local file_state = quarto.doc.file_metadata()
  return quarto.doc.is_format("typst") and
         file_state ~= nil and
         file_state.file ~= nil
end

local header_filter = {
  Header = function(el)
    if not is_typst_book() then
      return nil
    end

    local file_state = quarto.doc.file_metadata()
    if file_state == nil or file_state.file == nil then
      return nil
    end

    local file = file_state.file
    local bookItemType = file.bookItemType

    if el.level ~= 1 or bookItemType == nil then
      return nil
    end

    if bookItemType == "part" then
      return pandoc.RawBlock('typst', '#qcbook-part[' .. pandoc.utils.stringify(el.content) .. ']')
    end

    -- Handle appendices. Quarto marks concrete appendix chapters with
    -- bookItemType == "appendix". Insert an explicit Typst marker before the
    -- first appendix so typst-template.typ can render the appendix divider and
    -- TOC entry from structured book metadata instead of relying only on the
    -- literal "Appendices" heading text.
    if bookItemType == "appendix" then
      if file.bookItemNumber == 1 or file.bookItemNumber == nil then
        local appendixStart = pandoc.RawBlock('typst', '#qcbook-appendices')

        -- If Quarto emits a synthetic unnumbered Appendices divider heading,
        -- replace it with our explicit marker to avoid duplicate appendix
        -- divider output. Otherwise keep the actual appendix chapter heading.
        if el.classes:includes("unnumbered") then
          return appendixStart
        end

        return { appendixStart, el }
      end
    end

    return nil
  end
}

return quarto.utils.combineFilters({
  quarto.utils.file_metadata_filter(),
  header_filter
})