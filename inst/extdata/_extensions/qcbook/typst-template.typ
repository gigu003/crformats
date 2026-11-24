// qcbook Typst template for Quarto.
//
// The main entry point is report(), called from typst-show.typ.  It focuses on
// Chinese book/report-style PDF output: cover page, table of contents, chapter
// headings, running headers/footers, figure/table lists, footnotes, quotes and
// custom rule boxes.

#let rule(
  title: "",
  source: "",
  body: "",
  color: rgb("1e3a8a"),
  fill: rgb("f8f9fb"),
) = {
  block(
    width: 100%,
    fill: fill,
    stroke: (
      top: 0.9pt + color,
      bottom: 0.9pt + color
    ),
    radius: 3pt,
    inset: (top: 0.5em, right: 1em, bottom: 0.5em, left: 1em),

    stack(
      spacing: 1em,
      // header tag
      move(
        dx: -1em,
        dy: -0.5em,
        box(
          fill: color,
          inset: (x: 0.5em, y: 0.5em),
          radius: 2pt,
          text(
            size: 0.9em,
            weight: "bold",
            fill: white,
            tracking: 1pt,
            [📐 #title]
          )
        )
      ),

      // body
      block(width: 100%)[
        #set text(size: 0.85em, fill: luma(20))
        #body
      ],

      // source
      if source != "" [
        #align(
          right,
          text(size: 0.7em, fill: color, style: "italic")[#source]
        )
      ]
    )
  )
}

// Safely normalize user-provided color values.
//
// Quarto YAML options are often passed as strings. Previously, every non-black
// string was sent to rgb(), so values such as `primary` or `green` caused Typst
// to fail with "color string contains non-hexadecimal letters". Keep real Typst
// colors unchanged, support common named colors, parse likely hex strings, and
// fall back instead of calling rgb() on arbitrary text.
#let qcbook-color(value, fallback: black) = {
  if type(value) != str {
    value
  } else {
    let v = value.replace("\\#", "#").trim()
    if v == "black" {
      black
    } else if v == "white" {
      white
    } else if v == "red" {
      red
    } else if v == "green" {
      green
    } else if v == "blue" {
      blue
    } else if v == "gray" or v == "grey" {
      gray
    } else if v == "yellow" {
      yellow
    } else if v == "orange" {
      orange
    } else if v == "purple" {
      purple
    } else if v == "none" {
      fallback
    } else if v.starts-with("#") or v.len() == 3 or v.len() == 6 or v.len() == 8 {
      rgb(v)
    } else {
      fallback
    }
  }
}

#let qcbook-part-state = state("qcbook-part-state", none)
#let qcbook-part-location = state("qcbook-part-location", none)
#let qcbook-part-change = state("qcbook-part-change", false)
#let qcbook-part-counter = counter("qcbook-part-counter")
#let qcbook-appendices-location = state("qcbook-appendices-location", none)
#let qcbook-appendices-change = state("qcbook-appendices-change", false)
#let qcbook-appendices-started = state("qcbook-appendices-started", false)

#let qcbook-cn-number(n) = {
  let nums = ("一", "二", "三", "四", "五", "六", "七", "八", "九", "十")
  if n >= 1 and n <= nums.len() {
    nums.at(n - 1)
  } else {
    str(n)
  }
}

#let qcbook-part(title) = {
  pagebreak(weak: true)
  qcbook-part-change.update(true)
  qcbook-part-state.update(title)
  qcbook-part-counter.step()
  context {
    qcbook-part-location.update(here())
    let part-number = qcbook-part-counter.get().first()
    metadata("qcbook-chapter-start")
    v(5em)
    set par(first-line-indent: 0em, justify: false)
    align(center)[
      #text(size: 18pt, weight: "bold", fill: luma(80))[第#qcbook-cn-number(part-number)部分]
      #v(1em)
      #text(size: 32pt, weight: "bold")[#title]
    ]
    v(5em)
  }
}

#let qcbook-appendices = {
  qcbook-appendices-change.update(true)
  qcbook-appendices-started.update(true)
  context {
    qcbook-appendices-location.update(here())
  }
  heading(level: 1, numbering: none)[Appendices]
}

#let report(
  title: none,
  subtitle: none,
  cover-note: none,
  authors: none,
  date: none,
  logo: "_assets/logos/logo.png",
  cover-image: none,
  cover-bg-color: "#f0f8ff",
  cover-bg-color-end: "#dff1fb",
  toc-bg-color: "#f0f8ff",
  toc-bg-color-end: none,
  body-bg-color: "#ffffff",
  body-bg-color-end: none,
  abstract: none,
  header: " ",
  footer: " ",
  cols: 1,
  margin: (x: 1.0in, y: 1.0in),
  paper: "a4",
  font: "STSong",
  coverfont: "STSong",
  fontsize: 12pt,
  title-size: 1.5em,
  title-line-height: auto,
  subtitle-size: 1.25em,
  body-leading: 1em,
  body-spacing: 1.5em,
  list-indent: 2em,
  list-leading: 1em,
  list-spacing: 1.5em,
  code-block-leading: 0.45em,
  code-block-size: 0.85em,
  codefont: "Menlo",
  heading-family: "STHeiti",
  heading-weight: "bold",
  heading-style: "normal",
  heading-color: "black",
  heading-line-height: 0.55em,
  sectionnumbering: "1.1.1",
  figure-numbering: "1.1",
  table-numbering: "1.1",
  footnote-numbering: "1",
  appendix-title: "附录",
  appendix-delim: "：",
  bib-style: "gb-7714-2005-numeric",
  bib-title: none,
  toc: false,
  toc-title: none,
  list-of-figure-title: none,
  list-of-table-title: none,
  toc-depth: 3,
  toc-indent: 1.5em,
  doc,
) = {
  let heading-color-value = qcbook-color(heading-color, fallback: black)

  // `brand.typography.headings.line-height` can be converted by Quarto into a
  // Typst paragraph leading value such as `-0.2em`. That is acceptable for some
  // heading contexts, but it makes large multi-line cover titles overlap. Use a
  // cover-specific safe leading unless the user explicitly sets
  // `title-line-height`.
  let cover-title-leading = if title-line-height != auto and title-line-height != none {
    title-line-height
  } else if heading-line-height <= 0pt {
    0.35em
  } else {
    heading-line-height
  }

  let qcbook-bg-fill(start, end: none) = {
    let start-color = qcbook-color(start, fallback: white)
    if end == none {
      start-color
    } else {
      let end-color = qcbook-color(end, fallback: start-color)
      gradient.linear(start-color, end-color, angle: 135deg)
    }
  }

  // 页面设置
  set page(
    paper: paper,
    margin: margin,
    fill: qcbook-bg-fill(body-bg-color, end: body-bg-color-end)
    )

  // 段落格式设置 
  set par(
    leading: body-leading,
    spacing: body-spacing,
    justify: true,
    linebreaks: auto,
    first-line-indent:(amount: 2em, all: true)
    )
  
  // 文字格式设置  
  set text(font: font, size: fontsize, tracking: 0.3pt)
  set footnote(numbering: footnote-numbering)

  // 代码块格式设置：使用更紧凑的行间距，并取消首行缩进
  show raw.where(block: true): it => {
    set par(leading: code-block-leading, first-line-indent: 0em)
    set text(font: codefont, size: code-block-size)
    it
  }

  // Quarto 的语法高亮代码块由 Skylighting() 生成，最终包在
  // fill: rgb("#f1f3f5") 的 block 中；单独设置 raw 不会影响这类代码块。
  show block.where(fill: rgb("#f1f3f5")): it => {
    set par(leading: code-block-leading, first-line-indent: 0em)
    set text(font: codefont, size: code-block-size)
    it
  }

  // 覆盖 Quarto 内置的 Skylighting()：Quarto 默认用 raw("\n") 拼接代码行，
  // par(leading) 对这种结构不够稳定；改用 stack(spacing: ...) 逐行排版。
  let Skylighting(fill: none, number: false, start: 1, sourcelines) = {
    let rows = ()
    let lnum = start - 1
    for ln in sourcelines {
      let row = if number {
        lnum = lnum + 1
        box(width: if start + sourcelines.len() > 999 { 30pt } else { 24pt }, text(fill: rgb("#aaaaaa"), [ #lnum ])) + ln
      } else {
        ln
      }
      rows = rows + (row,)
    }

    block(fill: rgb("#f1f3f5"), width: 100%, inset: 8pt, radius: 2pt)[
      #set text(font: codefont, size: code-block-size)
      #set par(first-line-indent: 0em)
      #stack(dir: ttb, spacing: code-block-leading, ..rows)
    ]
  }

  //  标题序号
  set heading(numbering: sectionnumbering)
  // 图片编号：Quarto 生成的图片 float 使用 kind: "quarto-float-fig"。
  // Typst 的 figure 计数器默认只有图片自身序号一层，因此单纯设置
  // numbering: "1.1" 不会自动继承章节号。这里显式拼接“当前章节号 + 图序号”，
  // 让 YAML 中的 figure-numbering: "1.1" 生效为“图1.1”。
  set figure(numbering: figure-numbering, gap: 0.65em)
  let qcbook-figure-numbering = n => context {
    let chapter-number = counter(heading).get().at(0)
    numbering(figure-numbering, chapter-number, n)
  }
  let qcbook-in-appendix = state("qcbook-in-appendix", false)
  let qcbook-appendix-counter = counter("qcbook-appendix")
  let qcbook-render-appendices-divider = {
    colbreak(weak: true)
    metadata("qcbook-chapter-start")
    v(4em)
    set text(fill: heading-color-value, font: heading-family)
    set par(first-line-indent: 0em, leading: 0.6em, justify: false)
    align(center)[
      #text(size: 32pt, tracking: 0.2em, weight: heading-weight)[#appendix-title]
    ]
    v(4em)
  }
  show figure.where(kind: "quarto-float-fig"): set figure(numbering: qcbook-figure-numbering)
  // 普通 Markdown 图片在 Quarto 生成的 Typst 中通常是 kind: image，
  // 也需要显式拼接“当前章节号 + 图序号”，否则 figure-numbering: "1.1"
  // 只会作为 Typst 原生单参数编号格式使用，无法得到“图1.1”。
  show figure.where(kind: image): set figure(numbering: qcbook-figure-numbering)
  // 表格编号：Quarto 生成的表格 float 使用 kind: "quarto-float-tbl"。
  // 与图片相同，显式拼接“当前章节号 + 表序号”，让 table-numbering: "1.1"
  // 生效为“表1.1”。
  show figure.where(kind: "quarto-float-tbl"): set figure(
    numbering: n => context {
      let chapter-number = counter(heading).get().at(0)
      numbering(table-numbering, chapter-number, n)
    }
  )
  show heading.where(level: 1): it => {
    let is-unnumbered = it.numbering == none
    let ch-number = counter(heading).get().at(0)   // 获取当前章节号
    let is-appendix-marker = is-unnumbered and it.body == [Appendices]
    let in-appendix = qcbook-in-appendix.get() or qcbook-appendices-started.get()
    if is-appendix-marker {
      qcbook-in-appendix.update(true)
      qcbook-appendices-started.update(true)
      qcbook-appendices-change.update(true)
      context {
        qcbook-appendices-location.update(here())
      }
      qcbook-appendix-counter.update(0)
    }
    if not is-unnumbered and ch-number > 0 {
      counter(figure.where(kind: "quarto-float-fig")).update(0)
      counter(figure.where(kind: "quarto-float-tbl")).update(0)
    }
    if is-appendix-marker {
      // Quarto 为 book appendices 自动生成英文中间标题 “Appendices”。
      // 这里将其本地化为一个大的“附录”分部标题。
    } else {
      colbreak(weak: true)
      // 标记章节标题实际排版后的页面，供运行页眉判断“章节首页”使用。
      // 不能只依赖 heading.location()：一级标题 show rule 内部先执行 colbreak，
      // 在部分情况下 heading 的原始 location 仍可能落在换页前，导致章节首页页眉未被隐藏。
      metadata("qcbook-chapter-start")
    }
    if is-appendix-marker {
      qcbook-render-appendices-divider
    } else if in-appendix {
      let appendix-number = qcbook-appendix-counter.get().first() + 1
      qcbook-appendix-counter.update(appendix-number)
      v(2em)
      set text(fill: heading-color-value, font: heading-family)
      set par(first-line-indent: 0em, leading: 0.5em)
      block(
        width: 100%,
        inset: (left: 1em, right: 0.5em, top: 0.6em, bottom: 0.6em),
        stroke: (left: 0.5em + heading-color-value),
      )[
        #text(size: 24pt, fill: heading-color-value)[#appendix-title #numbering("A", appendix-number)#appendix-delim #it.body]
      ]
      v(3em)
    } else if is-unnumbered {
      v(2em)
      set text(fill: heading-color-value, font: heading-family)
      set par(first-line-indent: 0em, leading: 0.5em)
      text(size: 24pt)[#it.body]
      v(3em)
    } else if ch-number == 0 {
      v(2em)
      text(fill: heading-color-value, size: 24pt, tracking: 0.5em, font: heading-family)[#it.body]
      v(3em)
    } else {
      v(2em)
      set text(fill: heading-color-value, font: heading-family)
      set par(first-line-indent: 0em, leading: 0.5em)
      grid(columns: (auto, auto),
          block(inset: (left: 1em, right: 0.1em, top: 0.5em, bottom: 0.5em),
                outset: -0.3em,
                stroke: (left: 0.5em + heading-color-value),
                text(size: 15pt, fill: luma(100))[第 #ch-number 章#linebreak()]
              )
          )
      v(0.3em)
      text(size: 24pt)[#it.body] 
      v(3em)
    }
    if not is-appendix-marker and it.level == 1 {
      qcbook-part-change.update(false)
    }
  }

  show heading.where(level: 2): it => {
    v(1.3em)
    set text(font: heading-family, size: 18pt, weight: heading-weight, style: heading-style, fill: heading-color-value)
    it
    v(0.5em)
  }

  show heading.where(level: 3): it => {
    set text(font: heading-family, size: 16pt, weight: heading-weight, style: heading-style, fill: heading-color-value)
    it
    v(0.5em)
  }

  show heading.where(level: 4): it => {
    set text(font: heading-family, size: 1.1em, weight: heading-weight, style: heading-style, fill: heading-color-value)
    it
    v(0.5em)
  }


// 这里添加列表缩进设置
set list(
  indent: list-indent,
  body-indent: 0.8em,
  spacing: list-spacing,
)
set enum(
  indent: list-indent,
  body-indent: 0.8em,
  spacing: list-spacing,
)
show list.item: set par(leading: list-leading)
show enum.item: set par(leading: list-leading)

// 设置表格格式
show table: set table(inset: (top: 0.9em, bottom: 0.9em))
show table.cell: set par(leading: 0.7em)
show table: it => {
  v(1em)
  it
  v(1em)
}


// 设置图格式
show figure: set block(breakable: true, spacing: 2em)
show figure.caption: set text(fill: luma(100), font: heading-family)


// 设置封面格式
let cover-background = if cover-image == none or cover-image == "" {
  rect(
    width: 100%,
    height: 100%,
    fill: gradient.linear(
      qcbook-color(cover-bg-color, fallback: white),
      qcbook-color(cover-bg-color-end, fallback: qcbook-color(cover-bg-color, fallback: white)),
      angle: 135deg,
    ),
  )
} else {
  image(cover-image.replace("\\_", "_"), width: 100%, height: 100%, fit: "cover")
}

set page(
  numbering: none,
  background: cover-background
  )

if logo != none and logo != "" {
  align(left)[#image(logo.replace("\\_", "_"), height: 4%)]
}

v(8%)
// 设置标题和副标题格式
if title != none {
    align(left)[#block(below:0cm, height: 20%, width:100%)[
      #set par(leading: cover-title-leading, first-line-indent: 0em,
               spacing: cover-title-leading, linebreaks: "optimized", justify: false)
      #if (heading-family != none or heading-weight != "bold" or heading-style != "normal"
           or heading-color-value != black) {
        set text(font: heading-family, weight: heading-weight, style: heading-style, fill: heading-color-value)
        text(size: title-size, tracking: 1pt)[#title]
        v(0.8em)
        line(
          length: 82%,
          stroke: gradient.linear(
            rgb("#01579b"),     // 深蓝
            rgb("#0288d1"),     // 中蓝
            rgb("#4fc3f7"),     // 浅蓝
            rgb("#81d4fa")      // 更浅的蓝
            ) + 2pt
         )
        v(0.8em)
        if subtitle != none {
          parbreak()
          text(size: subtitle-size, tracking: 1pt)[#subtitle]
        }
      } else {
        text(weight: "bold", size: title-size, tracking: 1pt)[#title]
        if subtitle != none {
          parbreak()
          text(weight: "bold", size: subtitle-size, tracking: 1pt)[#subtitle]
        }
      }
    ]]
  }
    
v(3em)

block(height: 25%, above: 0cm, width: 100%)[
  #if authors != none {
    let count = authors.len()
    place(top + left)[
      #text(
        font: heading-family, 
        size: subtitle-size, 
        fill: luma(60)
      )[
        #authors.map(author => author.name).join(" ") 
        #if count > 0 { "© 编著" }
      ]
    ]
  }
]


place(bottom + center)[
  #stack(dir: ttb, spacing: 1.5em,
  if date != none {text(size: 1.1em, font: coverfont, fill: luma(200))[#date] },
  if cover-note != none {
  set par(leading: 0.8em, justify: false)
    block(width: 60%)[#text(font: font, size: 1em, style: "italic", weight: 100, fill:luma(50))[#cover-note]]
  }
  )
]
pagebreak()

// 设置目录页面格式
set page(
  numbering: "- 1 -",
  background: none,
  fill: qcbook-bg-fill(toc-bg-color, end: toc-bg-color-end)
  )
// 从1开始页数计数
counter(page).update(1)

// TOC 中 heading.location() 读取的页码在第二页起可能比视觉页脚页码少 1。
// 该函数只修正目录、图目录和表目录中的显示页码，不改变正文 page counter，
// 因而不会影响章节起始页隐藏 header 的 metadata 判断逻辑。
let qcbook-toc-page-number(n) = if n > 1 { n + 1 } else { n }

if toc {
    let toc-title-value = if toc-title == none {
      auto
    } else {
      toc-title
    }
    block(above: 2em, below: 2em)[
       #set par(leading: 1.5em)
    #align(center)[   
    #if toc-title-value != auto and toc-title-value != none {
      heading(level: 1, numbering: none, outlined: false)[#toc-title-value]
      v(1em)
    }
    #context {
      let in-appendix-toc = false
      let appendix-toc-number = 0
      let appendices-toc-emitted = false
      for hd in query(selector(heading)) {
        let loc = hd.location()
        let level = hd.level
        if level <= toc-depth and hd.outlined {
          let part-change = qcbook-part-change.at(loc)
          if level == 1 and part-change {
            let part-title = qcbook-part-state.at(loc)
            let part-loc = qcbook-part-location.at(loc)
            let part-counter-value = qcbook-part-counter.at(loc).first()
            block(width: 100%, inset: (top: 1.2em, bottom: 0.8em))[
              #align(center)[
                #link(part-loc)[#text(weight: "bold")[第#qcbook-cn-number(part-counter-value)部分#h(0.8em)#part-title]]
              ]
            ]
          }
          let appendices-change = qcbook-appendices-change.at(loc)
          let is-appendix-marker = hd.numbering == none and hd.body == [Appendices]
          let page-number = counter(page).at(loc).first()
          let indent = if level == 1 { 0em } else { toc-indent * (level - 1) }
          let title-body = hd.body
          let title-prefix = none

          if appendices-change and not appendices-toc-emitted {
            let appendices-loc = qcbook-appendices-location.at(loc)
            in-appendix-toc = true
            appendix-toc-number = 0
            appendices-toc-emitted = true
            block(width: 100%, inset: (top: 1.2em, bottom: 0.8em))[
              #align(center)[
                #link(appendices-loc)[#text(weight: "bold")[#appendix-title]]
              ]
            ]
          }

          if is-appendix-marker {
            in-appendix-toc = true
            appendix-toc-number = 0
            title-body = appendix-title
            if not appendices-toc-emitted {
              appendices-toc-emitted = true
              block(width: 100%, inset: (top: 1.2em, bottom: 0.8em))[
                #align(center)[
                  #link(loc)[#text(weight: "bold")[#appendix-title]]
                ]
              ]
            }
          } else if in-appendix-toc and level == 1 {
            appendix-toc-number = appendix-toc-number + 1
            title-prefix = [#appendix-title #numbering("A", appendix-toc-number)#appendix-delim ]
          } else if hd.numbering != none {
            let nums = counter(heading).at(loc)
            if level == 1 {
              title-prefix = [第#nums.at(0)章#h(0.8em)]
            } else if level == 2 {
              title-prefix = [#numbering("1.1", nums.at(0), nums.at(1))#h(0.8em)]
            } else if level == 3 {
              title-prefix = [#numbering("1.1.1", nums.at(0), nums.at(1), nums.at(2))#h(0.8em)]
            }
          }

          if not is-appendix-marker {
            block(width: 100%, inset: (left: indent))[#link(loc)[
              #if title-prefix != none { title-prefix }
              #title-body
            ]#box(width: 1fr, repeat[.])#link(loc)[#numbering("- 1 -", qcbook-toc-page-number(page-number))]]
          }
        }
      }
    }
    ]
  ]
  pagebreak()
}



if list-of-table-title != none {
  block(above: 2em, below: 2em)[
    #set text(size: 1em, font: font)
    #set par(leading: 1.6em)  // 行高更舒适

    #align(center)[
      #heading(level: 1, numbering: none, outlined: false)[#list-of-table-title]
      #v(1em)
      #context {
        for tbl in query(selector(figure.where(kind: "quarto-float-tbl"))) {
          let loc = tbl.location()
          let chapter-number = counter(heading).at(loc).at(0)
          let tbl-number = counter(figure.where(kind: "quarto-float-tbl")).at(loc).at(0)
          let page-number = counter(page).at(loc).first()
          let caption-body = if tbl.caption != none { tbl.caption.body } else { [] }
          block(width: 100%)[
            #link(loc)[表#numbering(table-numbering, chapter-number, tbl-number)#h(0.8em)#caption-body]
            #box(width: 1fr, repeat[.])
            #link(loc)[#numbering("- 1 -", qcbook-toc-page-number(page-number))]
          ]
        }
      }
    ]
  ]
  pagebreak()
}


if list-of-figure-title != none {
  block(above: 2em, below: 2em)[
    #set text(size: 1em, font: font)
    #set par(leading: 1.6em)  // 行高更舒适

    #align(center)[
      #heading(level: 1, numbering: none, outlined: false)[#list-of-figure-title]
      #v(1em)
      #context {
        for fig in query(selector(figure.where(kind: "quarto-float-fig"))) {
          let loc = fig.location()
          let chapter-number = counter(heading).at(loc).at(0)
          let fig-number = counter(figure.where(kind: "quarto-float-fig")).at(loc).at(0)
          let page-number = counter(page).at(loc).first()
          let caption-body = if fig.caption != none { fig.caption.body } else { [] }
          block(width: 100%)[
            #link(loc)[图#numbering(figure-numbering, chapter-number, fig-number)#h(0.8em)#caption-body]
            #box(width: 1fr, repeat[.])
            #link(loc)[#numbering("- 1 -", qcbook-toc-page-number(page-number))]
          ]
        }
      }
    ]
  ]
  pagebreak()
}

counter(page).update(1)
set page(
    header-ascent: 50%,
    header: context {
      let page-num = counter(page).get().first()
      let current-page = here().page()
      let is-chapter-start-page = false
      for chapter-start in query(selector(metadata.where(value: "qcbook-chapter-start"))) {
        if chapter-start.location().page() == current-page {
          is-chapter-start-page = true
        }
      }

      if not is-chapter-start-page {
        let sheader = if header != none and header != " " and header != "" {
          header
        } else {
          let h1 = query(selector(heading.where(level: 1)).before(here())).last()
          if h1 != none and h1.numbering != none {
            [第#counter(heading.where(level: 1)).display(h1.numbering)章#h(1em)#h1.body]
          } else {
            none
          }
        }
        if sheader != none {
          let alignment = if calc.odd(page-num) { right } else { left }
          align(alignment, text(font: font, fill: luma(60), size: 0.8em)[#sheader])
        }
      }
      


    },
    footer: context {
      let page = counter(page).get().first()
      let body = if calc.odd(page) [#footer#h(1em)\- #page \-] else [\- #page \-#h(1em)#footer]
      let alignment = if calc.odd(page) { right } else { left }
      align(alignment, text(font: font, fill: luma(60), size: 0.8em)[#body])
      },
    fill: qcbook-bg-fill(body-bg-color, end: body-bg-color-end)
)

show super: set text(font: font)
// Keep Typst's native footnote.entry renderer so the marker produced by
// `set footnote(numbering: footnote-numbering)` is preserved. Rebuilding the
// entry manually can drop or misplace the number in Typst 0.15.
set footnote.entry(
  gap: 0.5em,
  indent: 1.5em,
)
show footnote.entry: set text(
  font: font,
  fill: luma(80),
  size: 0.8em,
)
show footnote.entry: set par(
  first-line-indent: 0em,
  leading: 0.6em,
)


show quote: it => {
  block(
    fill: rgb("f8f9fb"),
    stroke: (
      top: 1pt + rgb("1e3a8a"),
      bottom: 1pt + rgb("1e3a8a")
    ),
    radius: 3pt,
    inset: (top: 1.2em, right: 1em, bottom: 1.2em, left: 1em),
    stack(
      spacing: 0.6em,
      text(size: 0.95em, fill: rgb("333333"))[#it.body]
    )
  )
}


set bibliography(style: bib-style, title: bib-title)

set text(font: font)
  if abstract != none {
    block(inset: 2em, fill: luma(250), radius:1em)[
    #text(weight: "bold")[【摘要】] 
    #text(size: 0.95em)[#abstract]
    ]
  }

 set text(size: 1em)
  if cols == 1 {
    doc
  } else {
    columns(cols, doc)
  }
}

