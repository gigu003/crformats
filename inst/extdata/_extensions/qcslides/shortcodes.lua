function appendix()
    -- QCSlides is a static PDF format and has no incremental appendix state.
    -- Keep the legacy shortcode as a safe section boundary for old documents.
    return pandoc.RawBlock('typst', '#pagebreak(weak: true)')
end

function pause()
    -- Incremental reveal is not available in a static Typst PDF.
    return pandoc.Null()
end

function meanwhile()
    -- Legacy incremental marker; intentionally a no-op for static PDFs.
    return pandoc.Null()
end

function v(args)
    return pandoc.RawInline('typst', '#v(' .. args[1] .. ')')
end