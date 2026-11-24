// qcreport metadata bridge: Pandoc/Quarto YAML keys are mapped here to the
// named arguments accepted by report() in typst-template.typ.

#show: doc => report(
// Document metadata and cover content.
$if(title)$ title: [$title$], $endif$
$if(subtitle)$ subtitle: [$subtitle$], $endif$
$if(version)$ version: [$version$], $endif$
$if(contact)$ contact: [$contact$], $endif$
$if(cover-note)$ cover-note: "$cover-note$", $endif$
$if(logo)$ logo: "$logo$", $endif$
$if(logo-image)$ logo_image: "$logo-image$", $endif$
$if(logo-height)$ logo_height: $logo-height$, $endif$
$if(cover-bg)$ cover-bg: "$cover-bg$", $endif$
$if(body-bg)$ body-bg: "$body-bg$", $endif$
$if(cover-bg-opacity)$ cover-bg-opacity: $cover-bg-opacity$, $endif$
$if(body-bg-opacity)$ body-bg-opacity: $body-bg-opacity$, $endif$
$if(author)$
  registry: [$author$],
$if(registry)$
  author: [$registry$],
$endif$
$elseif(registry)$
  registry: [$registry$],
$endif$
$if(header)$ header: [$header$], $endif$
$if(footer)$ footer: [$footer$], $endif$
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

// Optional abstract and page settings.
$if(abstract)$
  abstract: [$abstract$],
$endif$
$if(abstract-title)$
  abstract-title: [$abstract-title$],
$endif$
$if(margin)$
  margin: ($for(margin/pairs)$$margin.key$: $margin.value$,$endfor$),
$endif$
$if(papersize)$
  paper: "$papersize$",
$endif$
$if(mainfont)$
  mainfont: ("$mainfont$",),
$endif$
$if(tablefont)$
  tablefont: ("$tablefont$",),
$endif$
$if(tablescriptfont)$
  tablescriptfont: ("$tablescriptfont$",),
$endif$
$if(tablenotesfont)$
  tablenotesfont: ("$tablenotesfont$",),
$endif$
$if(mathfont)$
  mathfont: "$mathfont$",
$endif$
$if(coverfont)$
  coverfont: ("$coverfont$",),
$endif$
$if(fontsize)$
  fontsize: $fontsize$,
$endif$
$if(par-leading)$
  par-leading: $par-leading$,
$endif$
$if(par-spacing)$
  par-spacing: $par-spacing$,
$endif$
$if(first-line-indent)$
  first-line-indent: $first-line-indent$,
$endif$
$if(table-leading)$
  table-leading: $table-leading$,
$endif$
$if(section-numbering)$
  sectionnumbering: "$section-numbering$",
$endif$
$if(toc)$
  toc: $toc$,
$endif$
$if(toc-depth)$
  toc-depth: $toc-depth$,
$endif$
$if(toc-figure)$
  toc-figure: $toc-figure$,
$endif$
$if(toc-table)$
  toc-table: $toc-table$,
$endif$
  cols: $if(columns)$$columns$$else$1$endif$,
  doc,
)
