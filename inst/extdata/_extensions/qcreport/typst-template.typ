// qcreport: a Quarto Typst format for cancer registry reports.
// This partial defines the Typst `report()` function. Metadata values are
// forwarded by `typst-show.typ`.

#let qc-blue = rgb("#1f5f99")
#let qc-blue-light = rgb("#eaf3fb")
#let qc-cover-title = rgb("#0b3d78")
#let qc-cover-subtitle = rgb("#5a7489")
#let qc-cover-author = rgb("#2e617e")
#let qc-cover-registry = rgb("#314c65")
#let qc-cover-date = rgb("#718294")
#let qc-heading-blue = rgb("#0b3d78")
#let qc-gray = luma(92)
#let qc-gray-light = luma(248)
#let qc-table-rule = luma(45)
#let qc-table-stripe = luma(250)
#let qc-table-head = rgb("#eef5fb")

#let is-empty(value) = {
  value == none or value == [] or value == ""
}

#let clean-image-path(path) = path.replace("\\_", "_")

// Keep the heading hierarchy in one place so spacing and size changes do not
// have to be synchronized across several branches below.
#let qc-heading-style(level) = {
  if level == 1 {
    (before: 1.2em, after: 1.5em, size: 1.12em)
  } else if level == 2 {
    (before: 1.35em, after: 1.4em, size: 1.08em)
  } else {
    (before: 1.2em, after: 1.4em, size: 1.04em)
  }
}

#let qc-background-image(path, opacity-value) = block(
  width: 100%,
  height: 100%,
)[
  #image(path, width: 100%, height: 100%, fit: "cover")
  #place(top + left)[
    #rect(
      width: 100%,
      height: 100%,
      fill: white.transparentize(opacity-value),
    )
  ]
]

#let heading-content(it, level) = {
  if it.numbering == none {
    it.body
  } else if level == 1 {
    [#counter(heading).display() #h(0.45em) #text(fill: qc-blue)[│] #h(0.45em) #it.body]
  } else if level == 2 {
    [#counter(heading).display()#text(fill: qc-blue)[.] #h(0.35em) #it.body]
  } else {
    [#counter(heading).display() #h(0.35em) #it.body]
  }
}

#let qc-note(title: "提示", body) = block(
  width: 100%,
  inset: 0.9em,
  radius: 0.45em,
  fill: qc-blue-light,
  stroke: (left: 4pt + qc-blue),
)[
  #set par(first-line-indent: 0em)
  #text(weight: "bold", fill: qc-blue)[#title]
  #v(0.35em)
  #body
]

#let report(
  // Document metadata and cover content.
  title: none,
  subtitle: none,
  version: none,
  contact: none,
  cover-note: none,
  authors: none,
  date: none,
  logo: "_assets/logos/logo.png",
  // `logo` is retained for compatibility; the two explicit logo parameters
  // are the preferred interface for new documents.
  logo_image: none,
  logo_height: 7%,
  cover-bg: "_assets/bg/cover-bg.png",
  body-bg: "_assets/bg/body-bg.png",
  cover-bg-opacity: 60%,
  body-bg-opacity: 40%,
  registry: none,
  author: none,
  abstract-title: "报告摘要",
  abstract: none,
  header: " ",
  footer: " ",

  // Page and typography settings.
  cols: 1,
  margin: (x: 1.0in, y: 1.0in),
  paper: "a4",
  mainfont: "STsong",
  // Tables use STSong by default, while superscripts and subscripts use an
  // independent font with reliable glyph coverage.
  tablefont: ("STSong", "Songti SC"),
  tablescriptfont: ("PingFang SC", "Arial Unicode MS"),
  // `none` makes table notes inherit the current table font.
  tablenotesfont: none,
  mathfont: "STIX Two Math",
  coverfont: ("Source Han Serif", "Songti SC", "STSong"),
  fontsize: 12pt,
  par-leading: 1.3em,
  par-spacing: 1.6em,
  first-line-indent: 2em,
  table-leading: 0.7em,
  sectionnumbering: "1.1.1",
  toc-depth: 2,
  toc: false,
  toc-table: false,
  toc-figure: false,
  doc,
) = {
  // Resolve assets before configuring pages so cover and body setup use the
  // same normalized paths.
  let cover-background = if is-empty(cover-bg) {
    none
  } else {
    qc-background-image(clean-image-path(cover-bg), cover-bg-opacity)
  }
  let body-background = if is-empty(body-bg) {
    none
  } else {
    qc-background-image(clean-image-path(body-bg), body-bg-opacity)
  }
  let logo-source = if is-empty(logo_image) {
    logo
  } else {
    logo_image
  }
  let table_notes_font = if is-empty(tablenotesfont) {
    tablefont
  } else {
    tablenotesfont
  }

  // Global document defaults.
  set page(paper: paper, margin: margin, fill: luma(255), background: cover-background)
  set par(
    leading: par-leading,
    spacing: par-spacing,
    justify: true,
    linebreaks: auto,
    first-line-indent: (amount: first-line-indent, all: true),
  )
  set text(font: mainfont, size: fontsize)
  // Use a dedicated OpenType math font for symbols and operators. Formula
  // labels can select a different text font without changing math layout.
  show math.equation: set text(font: mathfont, weight: "regular")
  show text.where(lang: "zh-CN"): set text(font: mainfont, weight: "regular")
  // A page-footnote reference is rendered as a superscript. Keep its number
  // out of STSong so the marker remains visible; the footnote body is not
  // affected by this inline marker rule.
  show footnote: it => text(font: tablescriptfont, fill: luma(45))[#it]
  // Footnote entries need their own rule because they are rendered on the
  // page bottom, outside the call site's text scope. Keep the note compact
  // and emit its sequential number explicitly in a font that contains it.
  show footnote.entry: it => {
    set text(font: mainfont, size: 0.78em)
    let loc = it.note.location()
    text(font: tablescriptfont, fill: luma(45))[
      #numbering("1.", ..counter(footnote).at(loc))
    ]
    h(0.25em)
    it.note.body
  }
  set heading(numbering: sectionnumbering)

  // Figures and tables.
  set figure(placement: top)
  // Quarto wraps captioned tables in figures. Keep those figures in flow and
  // breakable so long tables can continue across pages.
  show figure.where(kind: "quarto-float-tbl"): set figure(placement: none)
  show figure.where(kind: "quarto-float-tbl"): set block(breakable: true)
  // Table captions inherit the display font while table contents retain
  // `tablefont` through the scoped table rule below.
  show figure.where(kind: "quarto-float-tbl"): it => {
    set text(font: coverfont)
    it
  }
  set table(
    stroke: none,
    inset: (x: 0.55em, y: 0.42em),
    fill: (x, y) => {
      if y == 0 {
        qc-table-head
      } else if calc.even(y) {
        qc-table-stripe
      } else {
        none
      }
    },
  )

  show figure.caption: it => {
    set par(first-line-indent: 0em, justify: false)
    show super: set text(font: tablescriptfont)
    show sub: set text(font: tablescriptfont)
    text(size: 0.9em, fill: luma(35))[#it]
  }

  show table: it => {
    set par(first-line-indent: 0em, leading: table-leading, spacing: 0pt)
    set text(font: tablefont, size: 0.92em)
    show super: set text(font: tablescriptfont)
    show sub: set text(font: tablescriptfont)
    // tinytable emits notes in `table.footer`. Define this inside the table
    // wrapper so it overrides the body table text settings above.
    show table.footer: footer => {
      set text(font: table_notes_font)
      footer
    }
    block()[
      #v(0.12em)
      #it
      #v(0.12em)
    ]
  }

  show table.cell.where(y: 0): it => {
    set text(weight: "bold")
    set table.cell(stroke: (bottom: 0.65pt + qc-table-rule))
    it
  }

  // Body heading hierarchy.
  show heading: it => {
    set par(first-line-indent: 0em)
    let level = it.level
    let style = qc-heading-style(level)
    v(style.before)
    block(width: 100%, below: style.after)[
      #text(font: coverfont, size: style.size, weight: "bold", fill: qc-heading-blue)[
        #heading-content(it, level)
      ]
    ]
  }

  // Cover page
  set page(paper: paper, margin: margin, fill: luma(255), background: cover-background, numbering: none, header: none, footer: none)
  block(width: 100%, height: 100%)[
    #set par(first-line-indent: 0em, justify: false)
    // Nudge the mark toward the physical top-left corner without changing the
    // vertical rhythm of the cover title below.
    #align(left)[#move(dx: -10mm, dy: -10mm)[#image(clean-image-path(logo-source), height: logo_height)]]
    #v(18%)
    #align(center)[
      #if not is-empty(title) {
        block(width: 100%)[
          #set align(center)
          #set par(leading: 0.8em, first-line-indent: 0em, justify: false)
          #text(font: coverfont, weight: 700, fill: qc-cover-title, size: 32pt, tracking: 0.02em)[#title]
        ]
      }
      #if not is-empty(subtitle) {
        v(0.8em)
        text(
          font: coverfont,
          fill: qc-cover-subtitle,
          size: 13pt,
          weight: 400,
          tracking: 0.055em,
        )[#subtitle]
        parbreak()
      }
      #if not is-empty(registry) {
        v(2.0em)
        text(
          font: coverfont,
          fill: qc-cover-author,
          size: 13.2pt,
          weight: 500,
          tracking: 0.06em,
        )[#registry]
        parbreak()
      }
    ]

    #place(bottom + center, dy: 0.45em)[
      #stack(dir: ttb, spacing: 0.3em,
        if not is-empty(author) {
          text(
            font: coverfont,
            size: 11.2pt,
            weight: 500,
            fill: qc-cover-registry,
            tracking: 0.045em,
          )[#author]
        } else if authors != none {
          let count = authors.len()
          let ncols = calc.min(count, 3)
          grid(
            columns: (1fr,) * ncols,
            column-gutter: 1.5em,
            align: center,
            ..authors.map(author =>
              text(font: coverfont, size: 11.2pt, weight: 500, fill: qc-cover-registry)[
                #author.name \
                #author.affiliation \
                #author.email
              ]
            )
          )
        },
        if not is-empty(contact) { text(font: coverfont, size: 0.9em, fill: qc-cover-registry)[#contact] },
        if not is-empty(date) {
          text(
            size: 9.5pt,
            font: coverfont,
            weight: 400,
            fill: qc-cover-date,
            tracking: 0.1em,
          )[#date]
        },
        if not is-empty(cover-note) {
          block(width: 70%)[#text(font: mainfont, size: 0.86em, style: "italic", fill: luma(50))[#cover-note]]
        },
      )
    ]
  ]

  // Table of contents and figure/table outlines.
  pagebreak()

  // Outlines
  set page(numbering: "- 1 -")
  counter(page).update(1)
  if toc {
    block(above: 2em, below: 2em)[
      #set par(leading: 1.5em, first-line-indent: 0em)
      #align(center)[#text(font: coverfont, size: 1.25em, weight: "bold", fill: qc-blue)[目录]]
      #v(1em)
      #set text(size: 1em, font: mainfont)
      #outline(title: none, depth: toc-depth, indent: auto)
    ]
    pagebreak()
  }

  if toc-figure {
    block(above: 2em, below: 2em)[
      #set par(leading: 1.5em, first-line-indent: 0em)
      #align(center)[#text(font: coverfont, size: 1.25em, weight: "bold", fill: qc-blue)[图目录]]
      #v(1em)
      #set text(size: 1em, font: mainfont)
      #outline(title: none, depth: toc-depth, indent: auto, target: figure.where(kind: image))
    ]
    pagebreak()
  }

  if toc-table {
    block(above: 2em, below: 2em)[
      #set par(leading: 1.5em, first-line-indent: 0em)
      #align(center)[#text(font: coverfont, size: 1.25em, weight: "bold", fill: qc-blue)[表目录]]
      #v(1em)
      #set text(size: 1em, font: mainfont)
      #outline(title: none, depth: toc-depth, indent: auto, target: figure.where(kind: table))
    ]
    pagebreak()
  }

  // Body page style
  counter(page).update(1)
  set page(
    fill: luma(255),
    background: body-background,
    header: context {
      let page = counter(page).get().first()
      let alignment = if calc.odd(page) { right } else { left }
      if not is-empty(header) {
        align(alignment, text(fill: luma(50), size: 0.86em)[#header])
      }
    },
    footer: context {
      let page = counter(page).get().first()
      let page-text = [\- #page \-]
      let body = if is-empty(footer) {
        page-text
      } else if calc.odd(page) {
        [#footer#h(1em)#page-text]
      } else {
        [#page-text#h(1em)#footer]
      }
      let alignment = if calc.odd(page) { right } else { left }
      align(alignment, text(fill: luma(50), size: 0.86em)[#body])
    },
  )

  set text(font: mainfont)
  if abstract != none {
    block(inset: 1.2em, fill: qc-gray-light, radius: 0.6em, stroke: 0.3pt + qc-gray)[
      #set par(first-line-indent: 0em)
      #text(weight: "bold", fill: qc-blue)[#abstract-title]
      #v(0.45em)
      #set par(first-line-indent: (amount: first-line-indent, all: true))
      #text(size: 0.95em)[#abstract]
    ]
    v(1em)
  }

  set text(size: 1em)
  if cols == 1 {
    doc
  } else {
    columns(cols, doc)
  }
}
