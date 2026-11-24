// Metadata bridge for the qcbook Quarto Typst format.
//
// Quarto/Pandoc metadata values are forwarded to report(), which is defined in
// typst-template.typ.

#show: doc => report(
$if(title)$
  title: [$title$],
$endif$
$if(subtitle)$
  subtitle: [$subtitle$],
$endif$
$if(cover-note)$
  cover-note: "$cover-note$",
$endif$
$if(logo)$ 
  logo: "$logo$",
$endif$
$if(cover-image)$
  cover-image: "$cover-image$",
$endif$
$if(cover-bg-color)$
  cover-bg-color: "$cover-bg-color$",
$elseif(brand.color.primary)$
  cover-bg-color: $brand.color.primary$,
$endif$
$if(cover-bg-color-end)$
  cover-bg-color-end: "$cover-bg-color-end$",
$elseif(brand.color.secondary)$
  cover-bg-color-end: $brand.color.secondary$,
$endif$
$if(toc-bg-color)$
  toc-bg-color: "$toc-bg-color$",
$elseif(brand.color.background)$
  toc-bg-color: $brand.color.background$,
$endif$
$if(toc-bg-color-end)$
  toc-bg-color-end: "$toc-bg-color-end$",
$endif$
$if(body-bg-color)$
  body-bg-color: "$body-bg-color$",
$elseif(brand.color.background)$
  body-bg-color: $brand.color.background$,
$endif$
$if(body-bg-color-end)$
  body-bg-color-end: "$body-bg-color-end$",
$endif$

$if(header)$
  header: [$header$],
$endif$
$if(footer)$ 
  footer: [$footer$], 
$endif$
$if(by-author)$
  authors: (
$for(by-author)$
$if(it.name.literal)$
    ( name: [$it.name.literal$],
      affiliation: [$for(it.affiliations)$$it.name$$sep$, $endfor$],
      email: [$it.email$] ),
$endif$
$endfor$
    ),
$endif$
$if(date)$
  date: [$date$],
$endif$
$if(abstract)$
  abstract: [$abstract$],
$endif$
$if(margin)$
  margin: ($for(margin/pairs)$$margin.key$: $margin.value$,$endfor$),
$endif$
$if(papersize)$
  paper: "$papersize$",
$endif$
$if(mainfont)$
  font: ("$mainfont$",),
$elseif(brand.typography.base.family)$
  font: $brand.typography.base.family$,
$endif$
$if(coverfont)$
  coverfont: ("$coverfont$",),
$elseif(brand.typography.headings.family)$
  coverfont: $brand.typography.headings.family$,
$elseif(brand.typography.base.family)$
  coverfont: $brand.typography.base.family$,
$endif$
$if(fontsize)$
  fontsize: $fontsize$,
$elseif(brand.typography.base.size)$
  fontsize: $brand.typography.base.size$,
$endif$
$if(codefont)$
  codefont: ("$codefont$",),
$elseif(code-font)$
  codefont: ("$code-font$",),
$elseif(brand.typography.monospace.family)$
  codefont: $brand.typography.monospace.family$,
$endif$

$if(title-size)$
  title-size: $title-size$,
$endif$
$if(title-line-height)$
  title-line-height: $title-line-height$,
$endif$
$if(subtitle-size)$
  subtitle-size: $subtitle-size$,
$endif$
$if(body-leading)$
  body-leading: $body-leading$,
$endif$
$if(body-spacing)$
  body-spacing: $body-spacing$,
$endif$
$if(list-indent)$
  list-indent: $list-indent$,
$endif$
$if(list-leading)$
  list-leading: $list-leading$,
$endif$
$if(list-spacing)$
  list-spacing: $list-spacing$,
$endif$
$if(code-block-leading)$
  code-block-leading: $code-block-leading$,
$endif$
$if(code-block-size)$
  code-block-size: $code-block-size$,
$endif$

$if(heading-color)$
  heading-color: "$heading-color$",
$elseif(brand.typography.headings.color)$
  heading-color: $brand.typography.headings.color$,
$elseif(brand.color.primary)$
  heading-color: $brand.color.primary$,
$endif$

$if(title)$
$if(headingfont)$
  heading-family: ("$headingfont$",),
$elseif(heading-family)$
  heading-family: ("$heading-family$",),
$elseif(brand.typography.headings.family)$
  heading-family: $brand.typography.headings.family$,
$endif$
$if(brand.typography.headings.weight)$
  heading-weight: $brand.typography.headings.weight$,
$endif$
$if(brand.typography.headings.style)$
  heading-style: "$brand.typography.headings.style$",
$endif$
$if(brand.typography.headings.line-height)$
  heading-line-height: $brand.typography.headings.line-height$,
$endif$
$endif$

$if(section-numbering)$
  sectionnumbering: "$section-numbering$",
$endif$
$if(figure-numbering)$
  figure-numbering: "$figure-numbering$",
$elseif(fig-numbering)$
  figure-numbering: "$fig-numbering$",
$endif$
$if(table-numbering)$
  table-numbering: "$table-numbering$",
$endif$
$if(footnote-numbering)$
  footnote-numbering: "$footnote-numbering$",
$endif$
$if(crossref.appendix-title)$
  appendix-title: "$crossref.appendix-title$",
$endif$
$if(crossref.appendix-delim)$
  appendix-delim: "$crossref.appendix-delim$",
$endif$
$if(bib-style)$
  bib-style: "$bib-style$",
$endif$
$if(bib-title)$
  bib-title: [$bib-title$],
$endif$
$if(toc)$
  toc: $toc$,
$endif$

$if(lof)$
  list-of-figure-title: "$if(crossref.lof-title)$$crossref.lof-title$$else$$crossref-lof-title$$endif$",
$endif$
$if(lot)$
  list-of-table-title: "$if(crossref.lot-title)$$crossref.lot-title$$else$$crossref-lot-title$$endif$",
$endif$
$if(toc)$
  toc-title: [$toc-title$],
$endif$
$if(toc-depth)$
  toc-depth: $toc-depth$,
$endif$
$if(toc-indent)$
  toc-indent: $toc-indent$,
$endif$
  cols: $if(columns)$$columns$$else$1$endif$,
  doc,
)
