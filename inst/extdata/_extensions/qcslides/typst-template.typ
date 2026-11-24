
// This is an example typst template (based on the default template that ships
// with Quarto). It defines a typst function named 'article' which provides
// various customization options. This function is called from the 
// 'typst-show.typ' file (which maps Pandoc metadata function arguments)
//
// If you are creating or packaging a custom typst template you will likely
// want to replace this file and 'typst-show.typ' entirely. You can find 
// documentation on creating typst templates and some examples here: 
//   - https://typst.app/docs/tutorial/making-a-template/
//   - https://github.com/typst/templates

// 定义状态：当前主题色，供正文中的组件读取
// Lua filter 生成的原始 Typst 片段无法直接访问 article() 的 theme-color 参数，
// 因此由 article() 更新该状态，正文组件默认读取它。
#let qcslides-theme-color = state("qcslides-theme-color", red)
#let qcslides-inline-code-font = state("qcslides-inline-code-font", "Menlo")
#let qcslides-code-size = state("qcslides-code-size", 0.72em)
#let qcslides-code-leading = state("qcslides-code-leading", 0.82em)
#let qcslides-inline-code-fill = state("qcslides-inline-code-fill", luma(248))
#let qcslides-inline-code-border = state("qcslides-inline-code-border", luma(220))
#let qcslides-inline-code-radius = state("qcslides-inline-code-radius", 0.35em)
#let qcslides-code-inset = state("qcslides-code-inset", 0.65em)
#let qcslides-code-fill = state("qcslides-code-fill", luma(248))
#let qcslides-code-border = state("qcslides-code-border", luma(220))
#let qcslides-code-radius = state("qcslides-code-radius", 0.35em)
#let qcslides-code-title-active = state("qcslides-code-title-active", false)
#let qcslides-margin-top = state("qcslides-margin-top", 20mm)
#let qcslides-header-override-pages = state("qcslides-header-override-pages", ())

// 主题色语义色阶：统一控制标题、强调、边框和浅色背景。
// 这些函数必须先于 qcode-title 等顶层组件定义。
#let qtheme-title-color(base, override: none) = if override == none { base.darken(70%) } else { override }
#let qtheme-heading-color(base) = base.darken(55%)
#let qtheme-bar-color(base) = base.darken(35%)
#let qtheme-border-color(base) = base.lighten(62%)
#let qtheme-soft-border-color(base) = base.lighten(75%)
#let qtheme-muted-border-color(base) = base.lighten(78%)
#let qtheme-chip-fill(base) = base.lighten(92%)
#let qtheme-soft-fill(base) = base.lighten(94%)
#let qtheme-subtle-fill(base) = base.lighten(96%)
#let qtheme-quote-mark-color(base) = base.lighten(72%)
#let qtheme-line-color(base) = base.lighten(70%)
#let qtheme-overlay-fill(base) = base.transparentize(30%)

// 覆写 Quarto/Pandoc 生成的 Skylighting 容器。高亮代码块不是 block raw，
// 因此必须在这里为实际承载各代码行的 block 设置行距和内边距。
#let qcslides-skylighting(
  sourcelines,
  fill: none,
  number: false,
  start: 1,
  leading: 0.82em,
  inset: 0.65em,
  background: luma(248),
  border: luma(220),
  radius: 0.35em,
  outset: (y: 0.22em),
  code-fonts: ("Menlo", "DejaVu Sans Mono"),
  code-size: 0.72em,
) = {
  let blocks = []
  let lnum = start - 1
  for ln in sourcelines {
    if number {
      lnum += 1
      blocks += box(
        width: if start + sourcelines.len() > 999 { 30pt } else { 24pt },
        text(fill: rgb("#aaaaaa"), [#lnum]),
      )
    }
    blocks += ln + raw("\n")
  }
  block(
    width: 100%,
    inset: inset,
    outset: outset,
    fill: background,
    stroke: if border == none { none } else { 0.8pt + border },
    radius: radius,
  )[
    #set par(first-line-indent: 0em, leading: leading, spacing: 0em)
    #set text(
      font: code-fonts,
      size: code-size,
      tracking: 0pt,
    )
    #blocks
  ]
}

#let Skylighting(fill: none, number: false, start: 1, sourcelines) = context {
  let in-titled-card = qcslides-code-title-active.get()
  qcslides-skylighting(
    sourcelines,
    fill: fill,
    number: number,
    start: start,
    leading: qcslides-code-leading.get(),
    inset: qcslides-code-inset.get(),
    background: if in-titled-card { none } else { qcslides-code-fill.get() },
    border: if in-titled-card { none } else { qcslides-code-border.get() },
    radius: if in-titled-card { 0pt } else { qcslides-code-radius.get() },
    outset: if in-titled-card { 0pt } else { (y: 0.22em) },
    code-fonts: (qcslides-inline-code-font.get(), "DejaVu Sans Mono"),
    code-size: qcslides-code-size.get(),
  )
}

// 带标题的代码卡片。Lua filter 将 filename 或 code-summary 包装到这里，
// 正文仍由 Pandoc 的 Skylighting 生成，因此保留语法高亮和行号能力。
#let qcode-title(title, body) = context {
  let base = qcslides-theme-color.get()
  let border = qcslides-code-border.get()
  let radius = qcslides-code-radius.get()
  let inset = qcslides-code-inset.get()

  block(
    width: 100%,
    outset: (y: 0.22em),
    fill: qcslides-code-fill.get(),
    stroke: 0.8pt + border,
    radius: radius,
    clip: true,
  )[
    #set par(first-line-indent: 0em, spacing: 0em)
    #block(
      width: 100%,
      inset: (left: inset, right: inset, top: 0.34em, bottom: 0.34em),
      fill: qtheme-chip-fill(base),
      stroke: (bottom: 0.8pt + border),
    )[
      #set text(size: qcslides-code-size.get() * 0.92, fill: qtheme-heading-color(base), weight: 700)
      #title
    ]
    #qcslides-code-title-active.update(true)
    #body
    #qcslides-code-title-active.update(false)
  ]
}

// Lua filter 只对真正的 Markdown Code 节点调用此函数；语法高亮 token 不会命中。
#let qinline-code(body) = context {
  let base = qcslides-theme-color.get()
  box(
    inset: (x: 0.22em, y: 0.06em),
    fill: qcslides-inline-code-fill.get(),
    stroke: 0.6pt + qcslides-inline-code-border.get(),
    radius: qcslides-inline-code-radius.get() * 0.65,
  )[
    #set text(
      font: (qcslides-inline-code-font.get(), "DejaVu Sans Mono"),
      fill: base.darken(55%),
      tracking: 0pt,
    )
    #body
  ]
}

// 可配置的普通列表。Lua filter 保留 Pandoc 生成的 list 内容，只在局部覆盖
// 项目符号、正文行距、列表项间距和字体颜色。
#let qstyled-list(
  marker: none,
  line-spacing: 0.82em,
  paragraph-spacing: 0.45em,
  color: none,
  font-size: none,
  bg-color: none,
  bg-opacity: 100%,
  indent: none,
  padding: none,
  radius: none,
  body,
) = {
  set par(leading: line-spacing, spacing: paragraph-spacing)
  set list(spacing: paragraph-spacing)
  set text(fill: color) if color != none
  set text(size: font-size) if font-size != none
  set list(marker: marker) if marker != none
  set list(indent: indent) if indent != none
  if bg-color != none or padding != none or radius != none {
    let block-fill = if bg-color == none {
      none
    } else {
      bg-color.transparentize(100% - bg-opacity)
    }
    block(
      width: 100%,
      fill: block-fill,
      inset: if padding == none { 0pt } else { padding },
      radius: if radius == none { 0pt } else { radius },
    )[#body]
  } else {
    body
  }
}

// 局部文字样式使用显式 text/highlight 包装，其优先级高于外层列表等块级 set 规则。
#let qstyled-text(color: none, font-size: none, bg: none, bg-opacity: 100%, padding: none, body) = {
  let styled = if color != none and font-size != none {
    text(body, fill: color, size: font-size)
  } else if color != none {
    text(body, fill: color)
  } else if font-size != none {
    text(body, size: font-size)
  } else {
    body
  }

  if padding != none {
    let text-fill = if bg == none {
      none
    } else {
      bg.transparentize(100% - bg-opacity)
    }
    box(inset: padding, fill: text-fill)[#styled]
  } else if bg != none {
    highlight(styled, fill: bg.transparentize(100% - bg-opacity))
  } else {
    styled
  }
}

// 定义函数：Quarto 原生 callout 的 qcslides 样式
#let qcallout(kind: "note", title: none, accent-color: red, body) = {
  let calloutColor = if kind == "tip" {
    green
  } else if kind == "warning" {
    orange
  } else if kind == "important" {
    red
  } else if kind == "caution" {
    yellow.darken(30%)
  } else {
    accent-color
  }

  let calloutLabel = if kind == "tip" {
    "提示"
  } else if kind == "warning" {
    "注意"
  } else if kind == "important" {
    "重要"
  } else if kind == "caution" {
    "小心"
  } else {
    "说明"
  }

  block(
    width: 100%,
    inset: (left: 1em, right: 1em, top: 0.8em, bottom: 0.8em),
    outset: (y: 0.4em),
    stroke: (left: 0.35em + calloutColor),
    fill: qtheme-chip-fill(calloutColor),
    radius: 0.3em,
  )[
    #set par(first-line-indent: 0em, spacing: 0.6em)
    #text(size: 0.9em, fill: calloutColor, weight: 800)[
      #if title == none { calloutLabel } else { title }
    ]
    #v(0.3em)
    #text(fill: luma(45), weight: 300)[#body]
  ]
}

// 定义函数：左右分栏布局，适合图文页
#let qsplit(
  left: none,
  right: none,
  left-width: 1fr,
  right-width: 1fr,
  gutter: 1.5em,
  align: top,
) = {
  grid(
    columns: (left-width, right-width),
    gutter: gutter,
    align: align,
    block(width: 100%)[#left],
    block(width: 100%)[#right],
  )
}

// 定义函数：大数字/关键指标展示
#let keyvalue(
  value: none,
  label: none,
  note: none,
  fill: none,
  strokeColor: none,
  width: 82%,
  height: auto,
  value-size: auto,
  label-size: auto,
  note-size: auto,
  inset: auto,
) = context {
  let metric-color = if strokeColor == none { qcslides-theme-color.get() } else { strokeColor }
  let metric-fill = if fill == none { qtheme-soft-fill(metric-color) } else { fill }
  let is-compact = height != auto
  let base-size = if value-size == auto { if is-compact { 1.9em } else { 3.2em } } else { value-size }
  let effective-value-size = base-size
  let effective-label-size = if label-size == auto { base-size * 0.40 } else { label-size }
  let effective-note-size = if note-size == auto { base-size * 0.30 } else { note-size }
  let effective-inset = if inset == auto { (x: base-size * 0.34, y: base-size * 0.20) } else { inset }
  let label-gap = base-size * 0.55
  let note-gap = base-size * 0.32
  let content-leading = base-size * 0.38

  align(center + horizon)[
    #block(
      width: width,
      height: height,
      inset: effective-inset,
      stroke: 1.2pt + metric-color,
      fill: metric-fill,
      radius: 0.5em,
    )[
      #set par(first-line-indent: 0em, leading: content-leading, spacing: 0em)
      #align(center + horizon)[
        #text(size: effective-value-size, fill: metric-color, weight: 900, tracking: 1pt)[#value]
        #if label != none {
          v(label-gap)
          text(size: effective-label-size, fill: luma(45), weight: 500)[#label]
        }
        #if note != none {
          v(note-gap)
          text(size: effective-note-size, fill: luma(90), weight: 300)[#note]
        }
      ]
    ]
  ]
}

// 定义函数：多指标展示，由 ::: {.keyvalue} 列表语法转换而来
#let keyvalues(
  items,
  columns: auto,
  height: auto,
  gutter: 1em,
  accent-color: none,
  value-size: auto,
  label-size: auto,
  note-size: auto,
  inset: auto,
) = context {
  let metric-color = if accent-color == none { qcslides-theme-color.get() } else { accent-color }
  let n = items.len()
  let col-count = if columns == auto { calc.min(n, 3) } else { columns }

  if n == 0 {
    none
  } else {
    block(width: 100%, inset: (x: 0.25em, y: 0.35em))[
      #grid(
        columns: (1fr,) * col-count,
        gutter: gutter,
        align: horizon,
        ..items.map(item => {
          keyvalue(
            value: item.value,
            label: item.label,
            note: item.note,
            strokeColor: metric-color,
            width: 100%,
            height: height,
            value-size: value-size,
            label-size: label-size,
            note-size: note-size,
            inset: inset,
          )
        }),
      )
    ]
  }
}

// 定义函数：图片展示页
#let qimage-slide(
  image-path,
  caption: none,
  image-width: 90%,
  image-height: 68%,
) = {
  align(center)[
    #image(image-path, width: image-width, height: image-height, fit: "contain")
    #if caption != none {
      v(0.6em)
      text(size: 0.85em, fill: luma(90), weight: 300)[#caption]
    }
  ]
}

// 定义函数：图片列表 / 图片墙组件
// 由 Lua filter 将 ::: {.image-list} 中的列表转换为 qimage-list(items)
#let qimage-list(
  items,
  columns: auto,
  image-height: 38mm,
  image-fit: "contain",
  gutter: 1em,
  caption: none,
  cap-location: "bottom",
  caption-size: 0.62em,
  group-caption-size: 0.68em,
  frame: true,
  accent-color: none,
) = context {
  let list-color = if accent-color == none { qcslides-theme-color.get() } else { accent-color }
  let n = items.len()
  let col-count = if columns == auto { calc.min(n, 3) } else { columns }
  let cap-pos = if cap-location == "top" { "top-center" } else if cap-location == "inside-bottom" { "bottom-center" } else { cap-location }
  let is-inside-cap = cap-pos != "bottom"

  let caption-label(body, inside: false) = {
    if inside {
      box(
        inset: (x: 0.32em, y: 0.12em),
        fill: qtheme-overlay-fill(list-color),
        radius: 0.18em,
      )[
        #text(size: caption-size * 0.82, fill: white, weight: 500)[#body]
      ]
    } else {
      text(size: caption-size, fill: luma(80), weight: 300)[#body]
    }
  }

  let caption-align(pos) = if pos == "top-left" or pos == "bottom-left" {
    left
  } else if pos == "top-right" or pos == "bottom-right" {
    right
  } else {
    center
  }

  let caption-dx(pos) = if pos == "top-left" or pos == "bottom-left" {
    0.38em
  } else if pos == "top-right" or pos == "bottom-right" {
    -0.38em
  } else {
    0pt
  }

  let caption-dy(pos) = if pos == "top-left" or pos == "top-center" or pos == "top-right" {
    0.38em
  } else if pos == "bottom-left" or pos == "bottom-center" or pos == "bottom-right" {
    -0.38em
  } else {
    0pt
  }

  let caption-placement(pos) = if pos == "top-left" or pos == "top-center" or pos == "top-right" {
    top + caption-align(pos)
  } else if pos == "bottom-left" or pos == "bottom-center" or pos == "bottom-right" {
    bottom + caption-align(pos)
  } else {
    center
  }

  let image-card(item) = {
    let rendered-image = image(
      item.path,
      width: 100%,
      height: image-height,
      fit: image-fit,
    )

    let base = if frame {
      box(
        width: 100%,
        inset: (x: 0.38em, y: 0.38em),
        fill: white,
        stroke: 0.65pt + qtheme-quote-mark-color(list-color),
        radius: 0.42em,
      )[
        #rendered-image
      ]
    } else {
      rendered-image
    }

    block(width: 100%)[
      #if is-inside-cap and item.caption != none and item.caption != [] {
        box(width: 100%)[
          #base
          #place(
            caption-placement(cap-pos),
            dx: caption-dx(cap-pos),
            dy: caption-dy(cap-pos),
          )[#caption-label(item.caption, inside: true)]
        ]
      } else {
        base
      }
      #if not is-inside-cap and item.caption != none and item.caption != [] {
        v(0.35em)
        align(center)[
          #caption-label(item.caption)
        ]
      }
    ]
  }

  if n == 0 {
    none
  } else {
    block(width: 100%, inset: (x: 0.25em, y: 0.35em))[
      #grid(
        columns: (1fr,) * col-count,
        gutter: gutter,
        align: top,
        ..items.map(item => {
          image-card(item)
        }),
      )
      #if caption != none and caption != [] {
        v(0.65em)
        align(center)[
          #text(size: group-caption-size, fill: luma(75), weight: 300)[#caption]
        ]
      }
    ]
  }
}

// 定义函数：图表 + 洞察解读页
// 由 Lua filter 将 ::: {.figure-insight image="..."} 中的列表转换为 qfigure-insight(image-path, items)
#let qfigure-insight(
  image-path,
  items,
  caption: none,
  image-width: 92%,
  image-height: auto,
  image-fit: "contain",
  frame-width: auto,
  insight-position: "right",
  image-area-width: 1.35fr,
  insight-area-width: 1fr,
  gutter: 1.4em,
  accent-color: none,
) = context {
  let insight-color = if accent-color == none { qcslides-theme-color.get() } else { accent-color }
  let n = items.len()
  let caption-gap = 0.18em

  let rendered-image = if image-height == auto {
    image(image-path, width: image-width, fit: image-fit)
  } else {
    image(image-path, width: image-width, height: image-height, fit: image-fit)
  }

  let image-frame = if frame-width == auto {
    box(
      inset: (x: 0.55em, y: 0.55em),
      fill: white,
      stroke: 0.7pt + qtheme-soft-border-color(insight-color),
      radius: 0.55em,
    )[
      #rendered-image
    ]
  } else {
    box(
      width: frame-width,
      inset: (x: 0.55em, y: 0.55em),
      fill: white,
      stroke: 0.7pt + qtheme-soft-border-color(insight-color),
      radius: 0.55em,
    )[
      #align(center)[#rendered-image]
    ]
  }

  let image-part = block(width: 100%)[
      #set par(first-line-indent: 0em, spacing: 0em)
      #align(center)[
        #image-frame
        #if caption != none and caption != [] {
          v(caption-gap)
          text(size: 0.64em, fill: luma(100), weight: 300)[#caption]
        }
      ]
    ]

  let image-core-part = block(width: 100%)[
      #align(center)[#image-frame]
    ]

  let caption-part = block(width: 100%)[
      #if caption != none and caption != [] {
        align(center)[
          #text(size: 0.64em, fill: luma(100), weight: 300)[#caption]
        ]
      }
    ]

  let insight-card(item, target-height: auto, match-height: false) = block(
    width: 100%,
    height: target-height,
    inset: if match-height {
      (x: 0.8em, y: 0em)
    } else {
      (left: 0.8em, right: 0.8em, top: 0.58em, bottom: 0.62em)
    },
    fill: qtheme-subtle-fill(insight-color),
    radius: 0.35em,
  )[
    #let card-content = [
      #text(size: 0.72em, fill: luma(35), weight: 800)[#item.title]
      #if item.body != none and item.body != [] {
        v(0.18em)
        text(size: 0.56em, fill: luma(90), weight: 300)[#item.body]
      }
    ]
    #if match-height {
      align(horizon, card-content)
    } else {
      card-content
    }
  ]

  let insight-separator = line(
    length: 100%,
    stroke: (
      paint: qtheme-line-color(insight-color),
      thickness: 0.55pt,
      dash: "dashed",
    ),
  )

  let insight-part(target-height: auto, distribute: false) = block(
    width: 100%,
    height: target-height,
    inset: (x: 0.15em, y: 0.25em),
  )[
    #if n == 0 {
      none
    } else {
      set par(first-line-indent: 0em, leading: 0.82em, spacing: 0.2em)
      if distribute and n > 1 {
        let insight-rows = ()
        let insight-elements = ()
        for (idx, item) in items.enumerate() {
          insight-rows.push(1fr)
          insight-elements.push(insight-card(item, target-height: 100%, match-height: true))
          if idx < n - 1 {
            insight-rows.push(auto)
            insight-elements.push(insight-separator)
          }
        }
        grid(
          columns: (1fr,),
          rows: insight-rows,
          ..insight-elements,
        )
      } else {
        for (idx, item) in items.enumerate() {
          insight-card(item)
          if idx < n - 1 {
            v(0.32em)
            insight-separator
            v(0.32em)
          }
        }
      }
    }
  ]

  // 左右布局的两列宽度均由 fr 控制。先按与 grid 相同的规则算出图片区
  // 的实际宽度，再测量图片高度，使洞察区可以精确拉伸到同一高度。
  let side-layout(insight-first: false) = layout(size => {
    let available-width = size.width - gutter
    let image-fraction = image-area-width / 1fr
    let insight-fraction = insight-area-width / 1fr
    let image-column-width = available-width * image-fraction / (image-fraction + insight-fraction)
    let image-core-height = measure(image-core-part, width: image-column-width).height
    let matched-insights = insight-part(target-height: image-core-height, distribute: true)

    block(width: 100%)[
      #set par(first-line-indent: 0em, spacing: 0em)
      #if insight-first {
        grid(
          columns: (insight-area-width, image-area-width),
          rows: (image-core-height,),
          gutter: gutter,
          align: horizon,
          matched-insights,
          image-core-part,
        )
      } else {
        grid(
          columns: (image-area-width, insight-area-width),
          rows: (image-core-height,),
          gutter: gutter,
          align: horizon,
          image-core-part,
          matched-insights,
        )
      }
      #if caption != none and caption != [] {
        v(caption-gap)
        if insight-first {
          grid(
            columns: (insight-area-width, image-area-width),
            gutter: gutter,
            none,
            caption-part,
          )
        } else {
          grid(
            columns: (image-area-width, insight-area-width),
            gutter: gutter,
            caption-part,
            none,
          )
        }
      }
    ]
  })

  if insight-position == "left" {
    side-layout(insight-first: true)
  } else if insight-position == "top" {
    grid(
      rows: (auto, auto),
      gutter: gutter,
      insight-part(),
      image-part,
    )
  } else if insight-position == "bottom" {
    grid(
      rows: (auto, auto),
      gutter: gutter,
      image-part,
      insight-part(),
    )
  } else {
    side-layout()
  }
}

// 定义函数：多卡片要点组件
// 由 Lua filter 将 ::: {.cards} 中的列表转换为 qcards(items)
#let qcards(
  items,
  columns: auto,
  accent-color: none,
) = context {
  let card-color = if accent-color == none { qcslides-theme-color.get() } else { accent-color }
  let n = items.len()
  let col-count = if columns == auto { calc.min(n, 4) } else { columns }
  let card-gutter = 1em

  let card(item, width: 100%, height: auto) = block(
    width: width,
    height: height,
    inset: (left: 1em, right: 1em, top: 0.85em, bottom: 0.9em),
    fill: qtheme-soft-fill(card-color),
    stroke: 0.7pt + qtheme-border-color(card-color),
    radius: 0.55em,
  )[
    #set par(first-line-indent: 0em, leading: 0.82em, spacing: 0.25em)
    #if item.icon != none {
      text(size: 1.35em, fill: card-color)[#item.icon]
      v(0.45em)
    }
    #text(size: 0.9em, fill: card-color, weight: 800)[#item.title]
    #if item.body != none and item.body != [] {
      v(0.45em)
      text(size: 0.66em, fill: luma(80), weight: 300)[#item.body]
    }
  ]

  if n == 0 {
    none
  } else {
    block(width: 100%, inset: (x: 0.3em, y: 0.4em))[
      #layout(size => {
        let card-width = (size.width - card-gutter * (col-count - 1)) / col-count
        let natural-heights = items.map(item => measure(card(item, width: card-width)).height)
        let row-count = calc.ceil(n / col-count)
        let row-heights = range(row-count).map(row => {
          let start = row * col-count
          let end = calc.min(start + col-count, n)
          calc.max(..natural-heights.slice(start, end))
        })

        grid(
          columns: (1fr,) * col-count,
          rows: row-heights,
          gutter: card-gutter,
          align: top,
          ..items.enumerate().map(((idx, item)) => {
            let row = calc.floor(idx / col-count)
            card(item, height: row-heights.at(row))
          }),
        )
      })
    ]
  }
}

// 横向步骤流程。由 Lua filter 将 ::: {.flow} 中的普通列表转换为
// qflow(items)，自动编号并使用循环色板连接各步骤。
#let qflow(
  items,
  height: 16mm,
  gap: 1.25em,
  text-size: 0.76em,
) = context {
  let palette = (
    rgb("#1376df"),
    rgb("#20a85b"),
    rgb("#f39a0a"),
    rgb("#7b3fe4"),
    rgb("#ed3441"),
  )
  let n = items.len()

  if n == 0 {
    none
  } else {
    let columns = ()
    let cells = ()

    for (idx, item) in items.enumerate() {
      let color = palette.at(calc.rem(idx, palette.len()))
      columns += (1fr,)
      cells += (block(
        width: 100%,
        height: height,
        inset: (left: 0.62em, right: 0.72em, top: 0.42em, bottom: 0.42em),
        fill: color.lighten(88%),
        stroke: 1pt + color,
        radius: 0.52em,
      )[
        #grid(
          columns: (1.65em, 1fr),
          gutter: 0.48em,
          align: horizon,
          circle(
            radius: 0.78em,
            fill: color,
          )[
            #align(center + horizon)[
              #text(size: 0.72em, fill: white, weight: 800)[#(idx + 1)]
            ]
          ],
          align(center + horizon)[
            #set par(first-line-indent: 0em, leading: 0.82em, spacing: 0em)
            #text(size: text-size, fill: color.darken(58%), weight: 750)[#item]
          ],
        )
      ],)

      if idx < n - 1 {
        columns += (gap,)
        cells += (align(center + horizon)[
          #text(size: 1.18em, fill: color, weight: 800)[→]
        ],)
      }
    }

    block(width: 100%, inset: (top: 0.35em, bottom: 0.35em))[
      #grid(
        columns: columns,
        gutter: 0pt,
        align: horizon,
        ..cells,
      )
    ]
  }
}

// 单张蓝色标题卡片。由 Lua filter 将 ::: {.card2} 转换为 qcard2(body)。
// 第一条标题可使用 Div 内的一级/二级标题，也可以通过 title 属性指定；
// subtitle 属性用于标题区的第二行说明。
#let qcard2-list(items, accent-color: none, list-size: 0.86em) = {
  let marker-color = if accent-color == none {
    rgb("#0879e5")
  } else {
    accent-color
  }

  stack(
    spacing: 0.8em,
    ..items.map(item => {
      grid(
        columns: (1em, 1fr),
        gutter: 0.2em,
        align: top,
        box(height: 0.9em)[
          #align(horizon)[
            #circle(radius: 0.16em, fill: marker-color)
          ]
        ],
        block(width: 100%)[
          #set text(size: list-size)
          #set par(first-line-indent: 0em, leading: 0.9em, spacing: 0em)
          #item
        ],
      )
    }),
  )
}

#let qcard2(
  title: none,
  subtitle: none,
  accent-color: none,
  height: auto,
  radius: 0.8em,
  body,
) = context {
  let card-color = if accent-color == none {
    rgb("#0879e5")
  } else {
    accent-color
  }

  block(
    width: 100%,
    height: height,
    fill: white,
    stroke: 0.8pt + card-color.lighten(35%),
    radius: radius,
    clip: true,
  )[
    #if title != none or subtitle != none {
      block(
        width: 100%,
        fill: card-color,
        inset: (left: 1.2em, right: 1.2em, top: 0.8em, bottom: 0.85em),
      )[
        #set par(first-line-indent: 0em, leading: 1em, spacing: 0em)
        #if title != none {
          text(size: 1.25em, fill: white, weight: 800)[#title]
        }
        #if title != none and subtitle != none {
          v(0.4em)
        }
        #if subtitle != none {
          text(size: 0.78em, fill: white, weight: 500)[#subtitle]
        }
      ]
    }
    #block(
      width: 100%,
      inset: (left: 1.2em, right: 1.2em, top: 0.1em, bottom: 1.05em),
    )[
      #set par(first-line-indent: 0em, leading: 1.05em, spacing: 0.45em)
      #set list(
        indent: 1.45em,
        body-indent: 0.45em,
        spacing: 0.55em,
        marker: [#align(horizon)[#circle(radius: 0.16em, fill: card-color)]],
      )
      #set text(size: 0.86em, fill: luma(35))
      #body
    ]
  ]
}

// 定义函数：重点结论列表组件
// 由 Lua filter 将 ::: {.keypoints} 中的列表转换为 qkeypoints(items)
#let qkeypoints(
  items,
  style: "numbered",
  height: auto,
  accent-color: none,
) = context {
  let point-color = if accent-color == none { qcslides-theme-color.get() } else { accent-color }
  let n = items.len()
  let marker(idx) = if style == "bullet" {
    circle(radius: 0.38em, fill: point-color)
  } else {
    let no = idx + 1
    circle(radius: 1.05em, fill: qtheme-quote-mark-color(point-color))[
      #align(center + horizon)[
        #text(size: 0.72em, fill: point-color, weight: 800)[#if no < 10 { [0#no] } else { [#no] }]
      ]
    ]
  }

  if n == 0 {
    none
  } else {
    block(width: 100%, inset: (x: 0.5em, y: 0.35em))[
      #set par(first-line-indent: 0em, spacing: 0.55em)
      #for (idx, item) in items.enumerate() {
        block(
          width: 100%,
          height: height,
          inset: (left: 0.9em, right: 1em, top: 0.65em, bottom: 0.7em),
          fill: qtheme-subtle-fill(point-color),
          radius: 0.45em,
          outset: (y: 0.18em),
        )[
          #align(horizon)[
            #grid(
              columns: (2.5em, 1fr),
              gutter: 0.75em,
              align: horizon,
              align(center + horizon)[#marker(idx)],
              block(width: 100%)[
                #set par(first-line-indent: 0em, leading: 0.85em, spacing: 0.2em)
                #text(size: 0.86em, fill: luma(35), weight: 800)[#item.title]
                #if item.body != none and item.body != [] {
                  v(0.28em)
                  text(size: 0.64em, fill: luma(85), weight: 300)[#item.body]
                }
              ],
            )
          ]
        ]
      }
    ]
  }
}

// 定义函数：金句 / 引用页组件
// 由 Lua filter 将 ::: {.quote-slide} 转换为 qquote-slide()[...]
#let qquote-slide(
  author: none,
  quote-align: "center",
  quote-size: "large",
  quote-style: "classic",
  accent-color: none,
  body,
) = context {
  let quote-color = if accent-color == none { qcslides-theme-color.get() } else { accent-color }
  let text-align = if quote-align == "right" { right } else if quote-align == "center" { center } else { left }
  let justify-body = quote-align == "justify"
  let main-size = if quote-size == "normal" {
    1.18em
  } else if quote-size == "large" {
    1.55em
  } else {
    quote-size
  }
  let is-compact = quote-style == "compact"
  let is-card = quote-style == "card"
  let quote-top-height = if is-compact { 1.15em } else { 1.35em }
  let quote-body-gap = if is-compact { -0.35em } else { -0.25em }
  let quote-bottom-gap = if is-compact { -0.05em } else { -0.15em }
  let quote-bottom-height = if is-compact { 1.05em } else { 1.25em }
  let author-gap = if is-compact { 0.45em } else { 0.55em }

  block(width: 100%, inset: (x: 1.2em, y: 1.0em))[
    #align(center)[
      #block(
        width: 78%,
        inset: if is-card { (left: 1.3em, right: 1.3em, top: 0.85em, bottom: 1em) } else { (x: 0em, y: 0em) },
        fill: if is-card { qtheme-soft-fill(quote-color) } else { none },
        stroke: if is-card { 0.7pt + qtheme-border-color(quote-color) } else { none },
        radius: if is-card { 0.65em } else { 0em },
      )[
        #set par(first-line-indent: 0em, leading: 1.05em, spacing: 0.55em, justify: justify-body)
        #block(width: 100%, height: quote-top-height)[
          #place(left + top)[
            #text(size: 3.2em, fill: qtheme-quote-mark-color(quote-color), weight: 900)[“]
          ]
        ]
        #v(quote-body-gap)
        #align(text-align)[
          #text(size: main-size, fill: luma(35), weight: 600, style: "italic")[#body]
        ]
        #v(quote-bottom-gap)
        #block(width: 100%, height: quote-bottom-height)[
          #place(right + top)[
            #text(size: 3.2em, fill: qtheme-quote-mark-color(quote-color), weight: 900)[”]
          ]
        ]
        #if author != none and author != [] {
          v(author-gap)
          align(right)[
            #text(size: 0.68em, fill: quote-color, weight: 500)[— #author]
          ]
        }
      ]
    ]
  ]
}

// 定义函数：甘特图组件
// 由 Lua filter 将 ::: {.gantt} 中的列表转换为 qgantt(items, months)
#let qgantt(
  items,
  months,
  year-groups: (),
  footer-notes: (),
  title: none,
  task-header: [任务],
  label-width: 8em,
  today-offset: none,
  today-label: [今天],
  row-height: auto,
  row-gap: 0pt,
  note-inside-threshold: 3,
  note-gap: auto,
  note-list-inset: 0.8mm,
  note-bullet-gap: 0.10em,
  bar-height: 82%,
  bar-radius: 2pt,
  show-year: true,
  show-notes: true,
  show-footer-notes: true,
  footer-note-gap: 0.12em,
  show-progress: true,
  progress-label: true,
  task-number: false,
  accent-color: none,
  milestone-color: orange,
  milestone-darken: 20%,
) = context {
  let gantt-color = if accent-color == none { qcslides-theme-color.get() } else { accent-color }
  let effective-milestone-color = milestone-color.darken(milestone-darken)
  let n = items.len()
  let period-count = months.len()
  let month-count = months.fold(0, (total, month) => total + month.span)
  let max-note-count = if n == 0 { 0 } else { calc.max(..items.map(item => item.notes.len())) }
  let is-dense = n > 6 or month-count > 12 or max-note-count > 3
  let base-row-height = if row-height == auto { if is-dense { 7.2mm } else { 8.8mm } } else { row-height }
  let task-size = if is-dense { 0.56em } else { 0.64em }
  let note-size = if is-dense { 0.42em } else { 0.48em }
  let month-size = if period-count > 12 { 0.42em } else { 0.50em }
  let note-line-height = if is-dense { 3.2mm } else { 3.8mm }
  let note-item-gap = if note-gap == auto { if is-dense { 0.45mm } else { 0.7mm } } else { note-gap }
  let contrast-text-color(color) = {
    let components = color.components()
    let luminance = if components.len() >= 3 {
      0.2126 * components.at(0) + 0.7152 * components.at(1) + 0.0722 * components.at(2)
    } else {
      components.at(0)
    }
    if luminance > 62% { luma(35) } else { white }
  }
  let item-row-height(item) = {
    let note-count = item.notes.len()
    let note-lines = calc.max(item.note-lines, note-count)
    let note-height = if note-count <= 1 { base-row-height } else { note-lines * note-line-height + (note-count - 1) * note-item-gap + 2 * note-list-inset + 3.0mm }
    let task-height = if item.task-lines <= 1 { base-row-height } else { item.task-lines * (if is-dense { 3.2mm } else { 3.8mm }) + 3.2mm }
    calc.max(base-row-height, note-height, task-height)
  }
  let year-header-height = base-row-height * 0.62
  let header-height = base-row-height + if show-year { year-header-height } else { 0pt }
  let grid-line = gantt-color.lighten(86%)
  let year-line = gantt-color.lighten(67%)
  let active-fill = gantt-color.transparentize(58%)
  let progress-fill = gantt-color.transparentize(12%)
  let milestone-plan-fill = effective-milestone-color.lighten(82%)
  let milestone-progress-fill = effective-milestone-color.transparentize(10%)
  let row-fill-light = white
  let row-fill-dark = gantt-color.lighten(95%)
  let task-number-label(number) = if number < 10 { [0#number] } else { [#number] }
  let progress-badge(label, color) = box(
    inset: (x: 0.25em, y: 0.04em),
    fill: color.lighten(90%),
    stroke: 0.3pt + color.lighten(66%),
    radius: 999pt,
  )[
    #text(size: note-size * 0.76, fill: color.darken(16%), weight: 750)[#label]
  ]

  let year-header() = grid(
    columns: (1fr,) * month-count,
    gutter: 0pt,
    ..year-groups.map(group => grid.cell(
      colspan: group.span,
      block(
        width: 100%,
        height: year-header-height,
        fill: gantt-color.lighten(93%),
        stroke: (left: 0.65pt + year-line, right: 0.65pt + year-line, top: 0.4pt + grid-line, bottom: 0.4pt + grid-line),
      )[
        #align(center + horizon)[
          #text(size: month-size * 0.98, fill: gantt-color.darken(38%), weight: 700)[#group.label]
        ]
      ],
    )),
  )

  let month-header() = grid(
    columns: (1fr,) * month-count,
    gutter: 0pt,
    ..months.map(month => grid.cell(
      colspan: month.span,
      block(
        width: 100%,
        height: base-row-height,
        inset: (x: 0.12em, y: 0.25em),
        fill: gantt-color.lighten(97%),
        stroke: (
          left: (if month.year-start { 0.95pt + year-line } else { 0.25pt + grid-line }),
          right: 0.25pt + grid-line,
          top: 0.25pt + grid-line,
          bottom: 0.4pt + grid-line,
        ),
      )[
        #align(center + horizon)[
          #text(size: month-size, fill: luma(92), weight: 500)[#month.label]
        ]
      ],
    )),
  )

  let month-cell(month, cell-height, row-fill: white) = block(
    width: 100%,
    height: cell-height,
    fill: row-fill,
    stroke: (
      left: (if month.year-start { 0.95pt + year-line } else { 0.22pt + grid-line }),
      right: 0.22pt + grid-line,
      top: 0.2pt + grid-line,
      bottom: 0.2pt + grid-line,
    ),
  )

  let timeline-row(item, row-fill) = {
    let current-row-height = item-row-height(item)
    let has-progress = show-progress and item.progress != none
    let progress-text = if has-progress { str(calc.round(item.progress * 100)) + "%" } else { "" }
    let item-color = if item.kind == "milestone" { effective-milestone-color } else { gantt-color }
    let item-plan-fill = if item.kind == "milestone" { milestone-plan-fill } else { active-fill }
    let item-progress-fill = if item.kind == "milestone" { milestone-progress-fill } else { progress-fill }
    let item-bar-text-color = contrast-text-color(item-color)
    let item-bar-dot-color = item-bar-text-color.transparentize(22%)
    let item-end = item.bar-offset + item.bar-duration
    let note-outside = show-notes and item.notes.len() > 0 and item.bar-duration < note-inside-threshold
    let note-at-left = item-end >= month-count - 1
    let outside-annotation() = {
      let note-content = block[
        #set par(first-line-indent: 0em, leading: note-line-height * 0.72, spacing: 0em)
        #for (idx, note) in item.notes.enumerate() {
          text(size: note-size, fill: item-color.darken(18%), weight: 650)[#note]
          if idx < item.notes.len() - 1 { linebreak() }
        }
      ]
      grid(
        columns: if has-progress and progress-label { (auto, auto) } else { (auto,) },
        gutter: 0.36em,
        align: horizon,
        ..(if has-progress and progress-label {
          if note-at-left { (note-content, progress-badge(progress-text, item-color)) } else { (progress-badge(progress-text, item-color), note-content) }
        } else {
          (note-content,)
        }),
      )
    }
    block(width: 100%, height: current-row-height)[
    #grid(
      columns: (1fr,) * month-count,
      gutter: 0pt,
      ..months.map(month => grid.cell(
        colspan: month.span,
        month-cell(month, current-row-height, row-fill: row-fill),
      )),
    )
    #place(left + horizon, dx: item.bar-offset * 100% / month-count)[
        #box(width: item.bar-duration * 100% / month-count)[
          #rect(
            width: 100%,
            height: current-row-height * bar-height,
            fill: item-plan-fill,
            stroke: 0.5pt + item-color,
            radius: bar-radius,
          )
        ]
      ]
    #if has-progress and item.progress > 0 {
        place(left + horizon, dx: item.bar-offset * 100% / month-count)[
          #box(width: item.bar-duration * item.progress * 100% / month-count)[
            #rect(
              width: 100%,
              height: current-row-height * bar-height,
              fill: item-progress-fill,
              stroke: none,
              radius: bar-radius,
            )
          ]
        ]
    }
    #if today-offset != none {
      place(left + top, dx: today-offset * 100% / month-count)[
        #line(length: current-row-height, angle: 90deg, stroke: (paint: red.lighten(18%).transparentize(30%), thickness: 0.58pt, dash: (array: (2.2pt, 2.8pt))))
      ]
    }
    #if note-outside {
      if note-at-left {
        place(right + horizon, dx: -(month-count - item.bar-offset) * 100% / month-count - 0.28em)[
          #align(right)[#outside-annotation()]
        ]
      } else {
        place(left + horizon, dx: item-end * 100% / month-count + 0.28em)[#outside-annotation()]
      }
    } else if show-notes and item.notes.len() > 0 {
        place(left + horizon, dx: item.bar-offset * 100% / month-count)[
          #box(width: item.bar-duration * 100% / month-count, inset: (x: 0.5em, y: 0.18em))[
            #align(left + horizon)[
              #if item.notes.len() == 1 {
                text(size: note-size, fill: item-bar-text-color, weight: 500)[#item.notes.first()]
              } else {
                block(inset: (top: note-list-inset, bottom: note-list-inset))[
                  #set par(first-line-indent: 0em, leading: note-line-height * 0.72, spacing: 0em)
                  #for (idx, note) in item.notes.enumerate() {
                    grid(
                      columns: (0.40em, 1fr),
                      gutter: note-bullet-gap,
                      align: top,
                      box(width: 0.40em, height: note-line-height)[
                        #place(center + horizon)[
                          #circle(radius: 1.05pt, fill: item-bar-dot-color)
                        ]
                      ],
                      block(width: 100%)[
                        #text(size: note-size, fill: item-bar-text-color, weight: 500)[#note]
                      ],
                    )
                    if idx < item.notes.len() - 1 { v(note-item-gap) }
                  }
                ]
              }
            ]
          ]
        ]
    }
    #if has-progress and progress-label and not note-outside {
      let label-at-left = item-end >= month-count - 0.55
      place(
        if label-at-left { right + horizon } else { left + horizon },
        dx: if label-at-left { -(month-count - item-end) * 100% / month-count - 0.34em } else { item-end * 100% / month-count + 0.34em },
      )[
        #progress-badge(progress-text, item-color)
      ]
    }
    ]
  }

  let timeline-header() = if show-year {
    block(width: 100%, height: header-height)[
      #grid(
        columns: (1fr,),
        rows: (year-header-height, base-row-height),
        row-gutter: 0pt,
        year-header(),
        month-header(),
      )
      #if today-offset != none {
        place(left + top, dx: today-offset * 100% / month-count)[
          #place(top + center, dy: 0.75mm)[
            #box(inset: (x: 0.26em, y: 0.07em), fill: red.lighten(8%), radius: 999pt)[
              #text(size: month-size * 0.66, fill: white, weight: 700)[#today-label]
            ]
          ]
          #place(top + center, dy: 4.1mm)[
            #line(length: header-height - 4.1mm, angle: 90deg, stroke: (paint: red.lighten(18%).transparentize(30%), thickness: 0.58pt, dash: (array: (2.2pt, 2.8pt))))
          ]
        ]
      }
    ]
  } else {
    block(width: 100%, height: header-height)[
      #month-header()
      #if today-offset != none {
        place(left + top, dx: today-offset * 100% / month-count)[
          #place(top + center, dy: 0.75mm)[
            #box(inset: (x: 0.26em, y: 0.07em), fill: red.lighten(8%), radius: 999pt)[
              #text(size: month-size * 0.66, fill: white, weight: 700)[#today-label]
            ]
          ]
          #place(top + center, dy: 4.1mm)[
            #line(length: header-height - 4.1mm, angle: 90deg, stroke: (paint: red.lighten(18%).transparentize(30%), thickness: 0.58pt, dash: (array: (2.2pt, 2.8pt))))
          ]
        ]
      }
    ]
  }

  if n == 0 or month-count == 0 {
    none
  } else {
    block(width: 100%, inset: (x: 0.25em, y: 0.35em))[
      #if title != none and title != [] {
        align(center)[
          #text(size: 0.86em, fill: qtheme-title-color(gantt-color), weight: 800)[#title]
        ]
        v(0.22em)
      }
      #grid(
        columns: (label-width, 1fr),
        rows: (header-height,) + items.map(item => item-row-height(item)),
        column-gutter: 0pt,
        row-gutter: row-gap,
        align: top,
        block(
          width: 100%,
          height: header-height,
          inset: (left: 0.45em, right: 0.45em, top: 0.25em, bottom: 0.25em),
          fill: gantt-color.darken(8%),
          stroke: (right: 0.75pt + gantt-color.lighten(55%)),
          radius: (top-left: 2pt, bottom-left: 2pt),
        )[
          #align(left + horizon)[
            #text(size: task-size, fill: white, weight: 800)[#task-header]
          ]
        ],
        timeline-header(),
        ..items.enumerate().map(((idx, item)) => {
          let row-fill = if calc.rem(idx, 2) == 0 { row-fill-light } else { row-fill-dark }
          let current-row-height = item-row-height(item)
          (
            block(
              width: 100%,
              height: current-row-height,
              inset: (left: 0.45em, right: 0.45em, top: 0.22em, bottom: 0.22em),
              fill: if calc.rem(idx, 2) == 0 { gantt-color.lighten(98%) } else { gantt-color.lighten(95%) },
              stroke: (right: 0.65pt + year-line, top: 0.2pt + grid-line, bottom: 0.2pt + grid-line),
              radius: 0em,
            )[
              #set par(first-line-indent: 0em, leading: 0.62em, spacing: 0em)
              #align(left + horizon)[
                #grid(
                  columns: if task-number and item.number != none { (auto, 1fr) } else { (1fr,) },
                  gutter: if task-number and item.number != none { 0.22em } else { 0.12em },
                  align: horizon,
                  ..(if task-number and item.number != none {
                    (
                      circle(radius: task-size / 2, fill: gantt-color.lighten(88%), stroke: 0.35pt + gantt-color.lighten(56%))[
                        #align(center + horizon)[
                          #text(size: task-size * 0.48, fill: gantt-color.darken(16%), weight: 800, tracking: 0pt)[#task-number-label(item.number)]
                        ]
                      ],
                      text(size: task-size, fill: luma(75), weight: 600)[#item.task],
                    )
                  } else {
                    (text(size: task-size, fill: luma(75), weight: 600)[#item.task],)
                  }),
                )
              ]
            ],
            timeline-row(item, row-fill),
          )
        }).flatten(),
      )
      #if show-footer-notes and footer-notes.len() > 0 {
        v(footer-note-gap)
        block(width: 100%, inset: (x: 0.08em, y: 0em))[
          #set par(first-line-indent: 0em, leading: 0.72em, spacing: 0em)
          #grid(
            columns: (auto, 1fr),
            gutter: 0.12em,
            align: top,
            text(size: note-size * 0.94, fill: gantt-color.darken(35%), weight: 700)[注：],
            block(width: 100%)[
              #for (idx, note) in footer-notes.enumerate() {
                grid(
                  columns: (1.5em, 1fr),
                  gutter: 0.12em,
                  align: top,
                  align(right)[
                    #text(size: note-size * 0.94, fill: gantt-color.darken(22%), weight: 600)[#(idx + 1). #sym.zwj]
                  ],
                  text(size: note-size * 0.94, fill: luma(92), weight: 350)[#note],
                )
                if idx < footer-notes.len() - 1 { v(0.12em) }
              }
            ],
          )
        ]
      }
    ]
  }
}

// 定义函数：时间线组件
// 由 Lua filter 将 ::: {.timeline} 中的列表转换为 qtimeline(items)
#let qtimeline(
  items,
  orientation: "horizontal",
  accent-color: none,
  dense-threshold: 4,
  axis-width: 0.95pt,
  icon-dx: -0.8em,
  arrow-dy: 1.2pt,
  vertical-columns: auto,
  // 纵向时间线超过该数量时自动分列展示。
  vertical-column-threshold: 4,
) = context {
  let timeline-color = if accent-color == none { qcslides-theme-color.get() } else { accent-color }
  let n = items.len()
  let is-dense = n > dense-threshold
  let event-width = if is-dense { 64% } else { 70% }
  let last-event-width = if is-dense { 82% } else { 82% }
  let top-row-height = if is-dense { 44mm } else { 38mm }
  let bottom-row-height = if is-dense { 36mm } else { 30mm }
  let top-safe-gap = if is-dense { 12mm } else { 7mm }
  let bottom-safe-gap = if is-dense { 8mm } else { 4mm }
  let marker-size = if is-dense { 0.9em } else { 1.0em }
  let title-size = if is-dense { 0.7em } else { 0.78em }
  let body-size = if is-dense { 0.54em } else { 0.63em }
  let body-gap = if is-dense { 0.32em } else { 0.55em }
  let marker-title-gap = if is-dense { 0.28em } else { 0.45em }
  let event-leading = if is-dense { 0.68em } else { 0.8em }
  let axis-stroke = axis-width + timeline-color.lighten(38%)
  let timeline-icon(icon: none) = circle(radius: 0.68em, fill: white, stroke: 1pt + timeline-color)[
    #align(center + horizon)[
      #if icon != none {
        text(size: 0.58em, fill: timeline-color)[#icon]
      } else {
        circle(radius: 0.34em, fill: timeline-color)
      }
    ]
  ]
  let event-card(item, width: event-width) = block(width: width)[
    #set par(first-line-indent: 0em, leading: event-leading, spacing: 0.12em)
    #text(size: marker-size, fill: timeline-color, weight: 500, tracking: 0pt)[#item.marker]
    #v(marker-title-gap)
    #text(size: title-size, fill: luma(30), weight: 800)[#item.title]
    #if item.body != none and item.body != [] {
      v(body-gap)
      text(size: body-size, fill: luma(95), weight: 300)[#item.body]
    }
  ]
  let arrow-head() = polygon(
    (0pt, -3.0pt),
    (6.4pt, 0pt),
    (0pt, 3.0pt),
    fill: timeline-color,
  )

  if n == 0 {
    none
  } else if orientation == "vertical" {
    let vertical-col-count = if vertical-columns == auto {
      calc.min(calc.ceil(n / vertical-column-threshold), 3)
    } else {
      vertical-columns
    }
    let rows-per-col = if vertical-columns == auto and n <= vertical-column-threshold * 3 {
      vertical-column-threshold
    } else {
      calc.ceil(n / vertical-col-count)
    }

    block(width: 100%, inset: (x: 0.4em, y: 0.4em))[
      #set par(first-line-indent: 0em, spacing: 0.65em)
      #grid(
        columns: (1fr,) * vertical-col-count,
        gutter: if vertical-col-count == 1 { 0em } else { 1.1em },
        align: top,
        ..range(vertical-col-count).map(col => {
          let start = col * rows-per-col
          let end = calc.min(start + rows-per-col, n)
          block(width: 100%)[
            #if start < n {
              for (idx, item) in items.slice(start, end).enumerate() {
                grid(
                  columns: (1.8em, 1fr),
                  gutter: 0.55em,
                  align: top,
                  align(center)[#timeline-icon(icon: item.icon)],
                  block(
                    width: 100%,
                    inset: (left: 0.8em, right: 0.8em, top: 0.55em, bottom: 0.6em),
                    fill: qtheme-soft-fill(timeline-color),
                    stroke: (left: 0.22em + timeline-color),
                    radius: 0.35em,
                  )[
                    #event-card(item)
                  ],
                )
                if idx < end - start - 1 { v(0.4em) }
              }
            }
          ]
        }),
      )
    ]
  } else {
    block(width: 100%, inset: (x: 0.2em, y: 0.2em))[
      #grid(
        columns: (1fr,) * n,
        rows: (top-row-height, 9mm, bottom-row-height),
        gutter: 0em,
        ..items.enumerate().map(((idx, item)) => {
          let is-top = calc.rem(idx, 2) == 0
          let card-dx = if idx == n - 1 { 34% } else if idx == 0 { 60% } else { 52% }
          let card-width = if idx == n - 1 { last-event-width } else { event-width }
          block(width: 100%, height: top-row-height, inset: (left: 0.35em, right: 0.25em, top: 0em, bottom: top-safe-gap))[
            #if is-top {
              place(top + left, dx: card-dx, dy: 0em)[#event-card(item, width: card-width)]
            }
          ]
        }),
        ..items.enumerate().map(((idx, item)) => {
          block(width: 100%, height: 9mm)[
            #if idx == 0 {
              place(horizon + right)[
                #line(length: 78%, stroke: axis-stroke)
              ]
            } else if idx == n - 1 {
              place(horizon + center)[
                #line(length: 115%, stroke: axis-stroke)
              ]
            } else {
              place(horizon + center)[
                #line(length: 100%, stroke: axis-stroke)
              ]
            }
            #place(horizon + center, dx: icon-dx)[#timeline-icon(icon: item.icon)]
            #if idx == n - 1 {
              place(horizon + right, dx: 0.65em, dy: arrow-dy)[#arrow-head()]
            }
          ]
        }),
        ..items.enumerate().map(((idx, item)) => {
          let is-bottom = calc.rem(idx, 2) == 1
          let card-dx = if idx == n - 1 { 34% } else if idx == 0 { 60% } else { 52% }
          let card-width = if idx == n - 1 { last-event-width } else { event-width }
          block(width: 100%, height: bottom-row-height, inset: (left: 0.35em, right: 0.25em, top: bottom-safe-gap, bottom: 0em))[
            #if is-bottom {
              place(top + left, dx: card-dx, dy: 0em)[#event-card(item, width: card-width)]
            }
          ]
        }),
      )
    ]
  }
}

#let qslide-logo(logo-height: 12mm, x: 0pt, y: none, body) = {
  // The default anchor is the vertical center of the page title. Custom
  // x/dx and y/dy values are offsets from that default anchor.
  let default-y = 5mm - logo-height / 2
  let effective-y = default-y + if y == none { 0pt } else { y }
  place(top + right, dx: x, dy: effective-y, float: false)[
    #body
  ]
}

// Replace the existing left header mark for this page only. qheader()
// suppresses the YAML mark for this page; the supplied content is drawn at
// the existing header anchor.
#let qslide-header-logo(
  logo-height: 12mm,
  logo-layout: "image",
  logo-text: none,
  body,
) = context {
  // qheader() is positioned in the header box; this overlay is positioned
  // from the page edge, so compensate for the body margin and header center.
  let header-dy = -qcslides-margin-top.get() + 2.5mm
  place(top + left, dx: -10mm, dy: header-dy, float: false)[
    #if logo-layout == "image" {
      body
    } else if logo-layout == "image-text" {
      grid(
        columns: (auto, auto),
        gutter: 0.5em,
        align: horizon,
        body,
        text(size: 0.7em, fill: luma(100), tracking: 1pt, weight: 300)[#logo-text],
      )
    } else {
      qbar-text(
        border-color: theme-bar-color,
        text-size: 0.7em,
        border-size: 0.3em,
        inset-y: 0.2em,
        inset-x: 0.6em,
      )[®#logo-text]
    }
  ]
}

#let article(
  last-page: none,
  thanks-page: none,
  author-page: none,
  title: none,
  subtitle: none,
  description: none,
  categories: none,
  series: none,
  logo-text: "河南省肿瘤医院",
  logo-image: none,
  logo-height: 7mm,
  logo-layout: "text",
  title-page-style: "classic",
  title-page-bg-image: none,
  title-page-bg-opacity: 100%,
  title-page-bg-fit: "cover",
  body-bg-image: "_assets/body-bg.png",
  body-bg-opacity: 100%,
  body-bg-fit: "cover",
  title-block-width: 72%,
  title-block-y: 30%,
  title-category-fill: none,
  title-meta-color: luma(90),
  title-meta-y: 78%,
  hide-header: false,
  hide-footer: false,
  hide-page-number: false,
  series-label: "系列",
  authors: none,
  date: datetime.today().display(),
  cols: 1,
  margin: (top: 20mm, bottom: 15mm, left: 20mm, right: 20mm),
  width: 338.7mm,
  height: 190.5mm,
  lang: "en",
  region: "US",
  font: "STSong",
  fontsize: 20pt,
  title-size: none,
  title-line-height: 0.4em,
  title-font: none,
  subtitle-size: none,
  subtitle-font: none,
  heading-size: 32pt,
  heading-family: "STHeiti",
  heading-weight: "bold",
  heading-style: "normal",
  heading-color: none,
  heading-line-height: 1.3em,
  sectionnumbering: none,
  pagenumbering: "1",
  theme-color: red,
  code-font: "Menlo",
  code-size: 0.72em,
  code-leading: 0.82em,
  code-fill: none,
  code-border: none,
  code-radius: 0.35em,
  code-inset: 0.65em,
  first-line-indent: 0em,
  section-overview: false,
  section-overview-style: "simple",
  heading-image: none,
  card-image: "dog.png",
  card-bg: luma(250),
  last-page-title: "请批评指正",
  last-page-subtitle: "Thanks for your attention",
  website-url: "https://chenq.site",
  website-text: "https://chenq.site",
  wechat-text: "微信公众号【普癌新声】",
  contact-email: "chenq08\@126.com",
  author-page-title: "关注作者👀",
  author-bio: [陈琼博士#h(1em)副主任医师#h(2em)河南省癌症中心｜河南省肿瘤医院],
  wechat-image: "_assets/wechat.jpg",
  wechat-caption: "微信公众号",
  blog-image: "_assets/qsight.png",
  blog-caption: "个人网站",
  doc,
) = {

// 字体大小
let header-size = 0.7em
let effective-title-size = if title-size == none { heading-size } else { title-size }
let effective-title-font = if title-font == none { heading-family } else { title-font }
let effective-subtitle-size-classic = if subtitle-size == none { effective-title-size * 0.5 } else { subtitle-size }
let effective-subtitle-size-modern = if subtitle-size == none { effective-title-size * 0.46 } else { subtitle-size }
let effective-subtitle-font = if subtitle-font == none { effective-title-font } else { subtitle-font }
let theme-title-color = qtheme-title-color(theme-color, override: heading-color)
let theme-heading-color = qtheme-heading-color(theme-color)
let theme-bar-color = qtheme-bar-color(theme-color)
let theme-border-color = qtheme-border-color(theme-color)
let theme-soft-border-color = qtheme-soft-border-color(theme-color)
let theme-muted-border-color = qtheme-muted-border-color(theme-color)
let theme-chip-fill = qtheme-chip-fill(theme-color)
let theme-soft-fill = qtheme-soft-fill(theme-color)
let theme-subtle-fill = qtheme-subtle-fill(theme-color)
let theme-line-color = qtheme-line-color(theme-color)
let effective-code-fill = if code-fill == none { theme-subtle-fill } else { code-fill }
let effective-code-border = if code-border == none { theme-soft-border-color } else { code-border }
let code-fonts = (code-font, "DejaVu Sans Mono")

// 统一规范化可选图片路径。
// Pandoc 会将 YAML 中的 `none` 作为字符串传入，因此同时接受 Typst none
// 和常见大小写形式的 "none"；正常路径会去除首尾空格并恢复转义下划线。
let qoptional-image-path(value) = if value == none {
  none
} else {
  let candidate = value.trim()
  if ("none", "None", "NONE").contains(candidate) {
    none
  } else {
    candidate.replace("\\_", "_").replace("~", "_")
  }
}

let qlogo-image-path(value) = {
  let candidate = qoptional-image-path(value)
  if candidate == none {
    none
  } else if candidate.slice(0, 1) == "/" {
    ".quarto/qcslides-media/_qcslides-logo-" + candidate
      .replace("/", "_")
      .replace(":", "_")
      .replace(" ", "_")
  } else {
    candidate
  }
}

let effective-logo-image = qlogo-image-path(logo-image)
let effective-title-page-bg-image = qoptional-image-path(title-page-bg-image)
let effective-body-bg-image = qoptional-image-path(body-bg-image)
let effective-heading-image = qoptional-image-path(heading-image)
let effective-wechat-image = qoptional-image-path(wechat-image)
let effective-blog-image = qoptional-image-path(blog-image)

// 将当前主题色写入全局状态，供正文组件（如 qtimeline）读取
qcslides-theme-color.update(theme-color)
qcslides-inline-code-font.update(code-font)
qcslides-code-size.update(code-size)
qcslides-code-leading.update(code-leading)
qcslides-inline-code-fill.update(effective-code-fill)
qcslides-inline-code-border.update(effective-code-border)
qcslides-inline-code-radius.update(code-radius)
qcslides-code-inset.update(code-inset)
qcslides-code-fill.update(effective-code-fill)
qcslides-code-border.update(effective-code-border)
qcslides-code-radius.update(code-radius)

// 定义函数和变量
// 定义函数：带条形框的文本
let qbar-text(body,
              text-size: 1em,
              text-tracking: 2pt,
              text-weight: 300,
              text-color: luma(100),
              border-size: 0.5em,
              border-color: red,
              inset-y: 0.3em,
              inset-x: 0.5em,
              outset-x: 0em
              ) = {
  block(
    inset: (left: inset-x, right:inset-x, top: inset-y, bottom: inset-y),
    outset: (left: outset-x),
    stroke: (left: border-size + border-color),
    [
     #text(size: text-size, fill: text-color, tracking: text-tracking,
           weight: text-weight)[#body]
    ]
    )
}

// 定义函数：页眉左侧品牌标识
// 默认沿用 logo-text 文本样式；当 logo-layout 为 image 或 image-text 且提供
// logo-image 时，显示图片 Logo 或“图片 + 文字”组合。
let qlogo-mark(text-size: 0.7em) = {
  let has-logo-image = effective-logo-image != none

  if logo-layout == "image" and has-logo-image {
    image(effective-logo-image, height: logo-height)
  } else if logo-layout == "image-text" and has-logo-image {
    grid(
      columns: (auto, auto),
      gutter: 0.5em,
      align: horizon,
      image(effective-logo-image, height: logo-height),
      text(
        size: text-size,
        fill: luma(100),
        tracking: 1pt,
        weight: 300,
      )[#logo-text],
    )
  } else {
    qbar-text(border-color: theme-bar-color,
              text-size: text-size,
              border-size: 0.3em,
              inset-y: 0.2em,
              inset-x: 0.6em)[®#logo-text]
  }
}

// 定义函数：条形框qbar
let qbar(bar-width: 100%,
         bar-height: 0.2em,
         position: top + center,
         fill: gradient.linear(..color.map.crest)
         ) = { 
  place(position, rect(width: bar-width,
                       height: bar-height,
                       fill: fill
                       )
        )
}

// 定义函数：qheader
let qheader(text-size: 0.7em,
            fill: gradient.linear(..color.map.crest)
            ) = {
      qbar(bar-width: width, position: top + center, fill: fill)
      context {
        let current-page = counter(page).get().at(0)
        let header-overridden = qcslides-header-override-pages.final().contains(current-page)
        if not header-overridden {
          place(horizon + left, dx: -10mm, dy: 1.5mm,
                qlogo-mark(text-size: text-size)
                )
        }
      }
      if series != none {
      place(horizon + right, dx: 10mm,
            text(size: text-size,
                 fill: luma(100),
                 tracking: 1pt,
                 weight: 100)[#series-label#h(0.2em)\/\/#h(0.2em)#series]
            )
      }
}

// 定义函数：标题页专用页眉
// 普通 qheader() 运行在页面 header 区域；标题页手动补绘时需要使用整页坐标。
let qtitle-page-header(text-size: 0.7em,
                       fill: gradient.linear(..color.map.crest)
                       ) = {
  place(top + left, dx: -margin.left, dy: -margin.top)[
    #rect(width: width, height: 0.2em, fill: fill)
  ]

  place(top + left, dx: -10mm, dy: -margin.top + margin.top / 2)[
    #qlogo-mark(text-size: text-size)
  ]

  if series != none {
    place(top + right, dx: 10mm, dy: -margin.top + margin.top / 2)[
      #text(size: text-size,
            fill: luma(100),
            tracking: 1pt,
            weight: 100)[#series-label#h(0.2em)\/\/#h(0.2em)#series]
    ]
  }
}

// 定义状态：正文页是否启用背景图
let body-background-enabled = state("qcslides-body-background-enabled", false)

// 定义状态：正文页是否启用全局页眉
// 封面页默认关闭，避免与 qtitle-page-header() 重复；正文开始前开启。
let body-header-enabled = state("qcslides-body-header-enabled", false)

// 定义状态：是否显示自定义页脚页码
// 封面页默认关闭；正文页开启；结尾页再次关闭。
let footer-page-number-enabled = state("qcslides-footer-page-number-enabled", false)

// 定义函数：正文页整页背景图
let qbody-background() = {
  if effective-body-bg-image != none {
    image(
      effective-body-bg-image,
      width: width,
      height: height,
      fit: body-bg-fit,
    )
    if body-bg-opacity < 100% {
      place(top + left)[
        #rect(
          width: width,
          height: height,
          fill: white.transparentize(body-bg-opacity),
        )
      ]
    }
  } else {
    none
  }
}

// 定义函数：qfooter
let qfooter(text-size: 0.7em,
            fill: gradient.linear(..color.map.crest)
            ) = {
  qbar(bar-width: width, position: bottom + center, fill: fill)
  if footer-page-number-enabled.get() and not hide-page-number and counter(page).get().at(0) > 0 {
      place(horizon + right,
            text(fill: luma(80),
                 tracking: 1pt,
                 weight: 200,
                 size: text-size
                 )[第#counter(page).display("1")页]
           )
    }
}


// 定义函数：一级目录总览
// 在一级标题页显示全部一级目录，并强调当前目录
let qsection-number(idx) = {
  let n = idx + 1
  if n < 10 {
    [0#n]
  } else {
    [#n]
  }
}

let qheading-number() = {
  let n = counter(heading).get().at(0)
  if n < 10 {
    [0#n]
  } else {
    [#n]
  }
}

let qsection-overview(current) = context {
  let sections = query(heading.where(level: 1))

  align(center + horizon)[
    #block(width: 80%)[
      #set par(first-line-indent: 0em, spacing: 1.1em)
      #for (idx, section) in sections.enumerate() {
        let is-current = section.location() == current.location()
        let item-color = if is-current { theme-heading-color } else { luma(120) }
        let item-weight = if is-current { 700 } else { 300 }
        let item-size = 1.15em
        let marker-color = if is-current { theme-color } else { luma(180) }

        block(
          width: 100%,
          inset: (left: 1em, right: 1em, top: 0.45em, bottom: 0.45em),
        )[
          #grid(
            columns: (3.2em, 1fr),
            gutter: 0.8em,
            align: horizon,
            text(size: 0.85em, fill: marker-color, weight: if is-current { 700 } else { 500 })[#qsection-number(idx)],
            align(left + horizon)[
              #text(size: item-size, fill: item-color, weight: item-weight, tracking: 1pt)[#section.body]
            ],
          )
        ]
      }
    ]
  ]
}

// 定义函数：卡片式一级目录总览
// 接近 PPT 目录页：左侧目录标题，右侧圆角卡片列表
let qsection-overview-card(current) = context {
  let sections = query(heading.where(level: 1))
  let title-x = 10mm
  let list-x = 35mm
  let list-width = 75%
  let item-height = 14mm
  let item-inset = (left: 0.4em, right: 0.3em, top: 0.35em, bottom: 0.35em)
  let item-font-size = 1.0em
  let marker-radius = 1em
  let muted-color = luma(130)
  let muted-marker-color = luma(180)

  place(left + horizon, dx: title-x)[
    #block(width: 52mm)[
      #align(left)[
        #text(size: 2.35em, fill: theme-title-color, weight: 900, tracking: 6pt)[目录]
        #v(0.2em)
        #text(size: 0.8em, fill: luma(120), weight: 300, tracking: 2pt)[CONTENTS]
      ]
    ]
  ]

  place(center + horizon, dx: list-x)[
    #block(width: list-width)[
      #set par(first-line-indent: 0em, spacing: 1em)
      #for (idx, section) in sections.enumerate() {
        let is-current = section.location() == current.location()
        let item-color = if is-current { theme-heading-color } else { muted-color }
        let item-weight = if is-current { 800 } else { 400 }
        let marker-fill = if is-current { item-color } else { muted-marker-color }

        block(
          width: 100%,
          height: item-height,
          inset: item-inset,
          fill: white,
          stroke: 0.6pt + theme-muted-border-color,
          radius: 999pt,
          outset: (y: 0.25em),
        )[
          #grid(
            columns: (3.6em, 0.7em, 1fr),
            gutter: 0.9em,
            align: horizon,
            circle(
              radius: marker-radius,
              fill: marker-fill,
            )[
              #align(center + horizon)[
                #text(size: 0.9em, fill: white, weight: 800)[#qsection-number(idx)]
              ]
            ],
            rect(width: 0.7pt, height: 2em, fill: theme-soft-border-color),
            align(left + horizon)[
              #text(size: item-font-size, fill: item-color, weight: item-weight, tracking: 1pt)[#section.body]
            ],
          )
        ]
      }
    ]
  ]
}

// 设置文档元数据
set document(
    title: title,
    date: auto,
    description: description,
    keywords: ()
  )
set document(
  author: authors.map(author => content-to-string(author.name)).join(", ", last: " & "),
) if authors != none and authors != ()

//统一页面设置
qcslides-margin-top.update(margin.top)
set page(width: width,
         height: height,
         margin: margin,
         numbering: pagenumbering,
         fill: luma(255),
         background: context {
           if body-background-enabled.get() {
             qbody-background()
           } else {
             none
           }
         },
         header: context {
           if body-header-enabled.get() and not hide-header {
             qheader()
           } else {
             none
           }
         },
         footer: if not hide-footer { context[#qfooter()] } else { none }
         )
         
//设置段落格式
set par(justify: true,
        leading: 1.1em,
        spacing: 1.2em,
        first-line-indent: (amount: first-line-indent, all: true)
        )
//设置文本格式
set text(lang: lang,
         region: region,
         font: heading-family,
         tracking: 1pt,
         size: fontsize,
         weight: 100
         )

// 设置脚注引用样式：正文中的脚注上标编号使用英文字体，避免中文字体缺字
show footnote: set text(font: font)

// 脚注独立下移，不改变页面下边距及页码位置；同步减少正文与分隔线之间的
// clearance，使正文获得等量的额外可用高度。
let footnote-shift = 3mm
set footnote.entry(
  separator: move(
    dy: footnote-shift,
    line(length: 30%, stroke: 0.05em + theme-soft-border-color),
  ),
  clearance: 1em - footnote-shift,
)

// 设置脚注样式：缩小 Quarto `^[...]` 生成的脚注正文
show footnote.entry: it => {
  move(dy: footnote-shift)[
    #set text(font: font, size: 0.58em, fill: luma(80), weight: 200)
    #set par(leading: 0.75em, spacing: 0.2em)
    #it
  ]
}

// Quarto 为带 tbl-cap 的表格添加 quarto-float-tbl figure 外层。
// 默认 figure 不可分页，会阻止其中的长表跨页续排；仅放开表格浮动体，
// 避免影响普通图片和其他 figure。
show figure.where(kind: "quarto-float-tbl"): set block(breakable: true)

//设置标题序号格式
set heading(numbering: if sectionnumbering == none { none } else {
  (..numbers) => context {
    let levels = numbers.pos()
    // 没有章节时，二级标题直接从 1 开始，下级标题也省去空的章节层。
    if query(heading.where(level: 1)).len() == 0 {
      numbering(sectionnumbering, ..levels.slice(1))
    } else {
      numbering(sectionnumbering, ..levels)
    }
  }
})

//设置不同级别标题格式
show heading: it => {
  set par(first-line-indent: 0em)
  set text(tracking: 1pt,
           font: heading-family,
           weight: heading-weight,
           style: heading-style,
           fill: theme-title-color,
           size: fontsize
           )
    v(0.5em)
  if it.level == 1 {
      // 设置一级标题格式：可选显示全部一级目录并强调当前目录
      pagebreak()
      if section-overview {
        if section-overview-style == "contents-card" {
          qsection-overview-card(it)
        } else {
          qsection-overview(it)
        }
      } else {
        set text(size: 1.6em, fill: theme-heading-color)
        align(center+horizon)[
          #box[
            #if it.numbering != none { 
              circle(radius: 0.75em, fill: theme-color)[
                #align(center + horizon)[
                  #text(size: 0.82em, fill: white, weight: 900)[#qheading-number()]
                ]
              ]
              h(0.38em)
            }
            #underline(stroke: 3pt + theme-color, offset: 8pt, extent: 0pt)[
                      #it.body
                      ]
          ]
        ]
      }
      
    } else if it.level == 2 {
      pagebreak()
      // 设置二级标题格式
      set text(size: 1.4em, fill: theme-heading-color, weight: 800)
      box[
          #if it.numbering != none {
          counter(heading).display()
          }
        #h(0.3em)
        #it.body
      ]
    } else if it.level == 3 {
      // 设置三级标题格式
      //set text(size: 1.3em, fill: luma(30), weight: 700)
      box[
        \/\/\/
          #if it.numbering != none {
          counter(heading).display()
          }
        #h(0.3em)
        #it.body
      ]
    } else {
      // 其他标题
      set text(size: 1.1em, fill: luma(30), weight: 700)
      box[
        #if it.numbering != none {
          counter(heading).display()
          }
        #h(0.3em)
       #it.body
      ]
    }

}

set list(indent: 1em, spacing: 1.2em,)
set enum(indent: 1em, spacing: 1.2em,)
show list: it => block[
  #it
]
show enum: set par(leading: 1.2em)
show enum: it => block[
  #it
]


show link: underline
show strong: set text(weight: "bold", fill: theme-heading-color)
show emph: set text(weight: "bold", fill: theme-heading-color)
// Skylighting 将高亮代码块拆成多个行内 raw token。这里只统一字体与字号，
// 背景、边框和内边距仍仅由下面的块级 raw 规则负责，避免每个 token 出现小方框。
show raw: it => {
  // 行内 raw 继承所在正文的字号；块级代码在各自容器中显式应用 code-size。
  set text(font: code-fonts, tracking: 0pt)
  it
}
show raw.where(block: true): it => {
  block(
    width: 100%,
    inset: code-inset,
    outset: (y: 0.22em),
    fill: effective-code-fill,
    stroke: 0.8pt + effective-code-border,
    radius: code-radius,
  )[
    #set par(first-line-indent: 0em, leading: code-leading, spacing: 0em)
    #set text(font: code-fonts, size: code-size, tracking: 0pt)
    #it
  ]
}

show quote.where(block: true): it => {
  block(
    width: 100%,
    above: 0.6em,
    below: 0em,
    inset: (left: 1.1em, right: 1.1em, top: 0.6em, bottom: 0.6em),
    outset: (y: 0em),
    fill: theme-soft-fill,
    stroke: (left: 0.28em + theme-bar-color),
    radius: 0.35em,
  )[
    #set par(first-line-indent: 0em, leading: 1.0em, spacing: 0.45em)
    #set text(size: 0.92em, style: "normal", weight: 300, fill: luma(55))
    #it
  ]
}

// 定义函数：封面页作者信息
let qtitle-authors(meta-color: luma(90)) = {
  if authors != none {
    let count = authors.len()
    let ncols = calc.min(count, 3)
    grid(
      columns: (1fr,) * ncols,
      row-gutter: 1.2em,
      ..authors.map(author =>
          align(left)[
          #text(font:font, size: 0.88em, fill: meta-color, weight: 300)[
          #if author.name != none and author.name != "" {
            [👨‍💻 #author.name]
          }
          #if author.affiliation != none and author.affiliation != "" {
            [#h(0.4em)（#author.affiliation）]
          }
          #if author.email != none and author.email != "" {
            [#h(0.4em)📬 #author.email]
          }
          ]
          ]
      )
    )
  }
}

// 定义函数：标题页整页背景图
let qtitle-page-background() = {
  if effective-title-page-bg-image != none {
    place(top + left, dx: -margin.left, dy: -margin.top)[
      #image(
        effective-title-page-bg-image,
        width: width,
        height: height,
        fit: title-page-bg-fit,
      )
    ]
    if title-page-bg-opacity < 100% {
      place(top + left, dx: -margin.left, dy: -margin.top)[
        #rect(
          width: width,
          height: height,
          fill: white.transparentize(title-page-bg-opacity),
        )
      ]
    }
  }
}

// 定义函数：经典封面页，保留原有布局
let qtitle-page-classic() = {
  // 标题页图片
  if effective-heading-image != none {
    figure(numbering: none,
           gap: 0.1em,
           image(effective-heading-image, width: 100%, height: 25%)
      )
  } else {
    v(25%)
  }
    
  // 标题
  if title != none {
    set par(spacing: 0.8em)
    if categories != none {
      align(left)[#text(font: heading-family,
                        fill:luma(80),
                        size: header-size*1.1)[#categories]]
  }
      underline(stroke: 1.3pt + theme-color, offset: 8pt, extent: 0pt)[
      #align(left)[#block()[
        #set par(first-line-indent: 0em, leading: title-line-height, spacing: 0em)
        #set text(tracking: 1pt,
                  font: effective-title-font,
                  weight: heading-weight,
                  style: heading-style,
                  fill: theme-title-color)
          #text(size: effective-title-size)[#title]
      ]]
      ]
    if subtitle != none {
    text(font: effective-subtitle-font, size: effective-subtitle-size-classic)[#subtitle]
    }
    set par(spacing: 2em)
  }

  qtitle-authors(meta-color: luma(70))

  align(left)[#text(font: heading-family,
                    fill:luma(80),
                    size:0.9em)[📅 #date]]
}

// 定义函数：现代封面页
let qtitle-page-modern() = {
  let category-fill = if title-category-fill == none { theme-chip-fill } else { title-category-fill }

  if effective-heading-image != none {
    place(top + right)[
      #image(effective-heading-image, width: 42%, height: 100%, fit: "cover")
    ]
    place(top + right)[
      #rect(width: 42%, height: 100%, fill: white.transparentize(18%))
    ]
  }

  v(title-block-y)
  block(width: title-block-width)[
    #set par(first-line-indent: 0em, spacing: 0.55em)
    #if categories != none {
      block(
        inset: (left: 0.45em, right: 0.8em, top: 0.35em, bottom: 0.35em),
        fill: category-fill,
        radius: 999pt,
      )[
        #text(font: heading-family, size: 0.72em, fill: theme-color, weight: 500, tracking: 1pt)[#categories]
      ]
      v(0.3em)
    }
    #if title != none {
      block[
        #set par(first-line-indent: 0em, leading: title-line-height, spacing: 0em)
        #text(font: effective-title-font, size: effective-title-size * 1.05, fill: theme-title-color, weight: 900, tracking: 1pt)[#title]
      ]
    }
    #if subtitle != none {
      v(0.3em)
      text(font: effective-subtitle-font, size: effective-subtitle-size-modern, fill: luma(85), weight: 300, tracking: 1pt)[#subtitle]
    }
  ]

  place(top + left, dy: title-meta-y)[
    #block(width: 82%)[
      #qtitle-authors(meta-color: title-meta-color)
      #v(0.8em)
      #text(font: heading-family, fill: title-meta-color, size: 0.78em, weight: 300)[📅 #date]
    ]
  ]
}


// 布置title-page
qtitle-page-background()
if title-page-style == "modern" {
  qtitle-page-modern()
} else {
  qtitle-page-classic()
}
if not hide-header {
  qtitle-page-header()
}

//页面从1开始计数
counter(page).update(0)
footer-page-number-enabled.update(true)
body-background-enabled.update(true)
body-header-enabled.update(true)

// 正文内容  
if cols == 1 {
    doc
  } else {
    columns(cols, doc)
  }



// 设置结尾页面
// thanks-page 控制致谢页，author-page 控制作者介绍页。
// last-page 作为兼容旧文档的总开关：如果指定 last-page，则同时显示两个页面。
// 如果指定了 body-bg-image，结尾页面默认沿用正文页背景图。
let show-thanks-page = thanks-page == true or last-page == true
let show-author-page = author-page == true or last-page == true

if show-thanks-page or show-author-page {
  set text(font: heading-family, size: 20pt, fill: luma(100))
  set page(fill: luma(250), numbering: none, footer: context[
  #place(bottom + center,
                 rect(width: width, height: 0.2em,
                      fill: gradient.linear(..color.map.crest))
                )
  ])
  pagebreak()
  footer-page-number-enabled.update(false)
}

if show-thanks-page {
  place(horizon + center,
        [#text(size: 70pt,
               fill: theme-color,
               tracking: 40pt,
               weight: 800
             )[#last-page-title]
         #text(size: 30pt,
               fill: luma(100),
               tracking: 7pt,
               weight: 300
               )[#linebreak()#last-page-subtitle]
        ]
             )
}

if show-author-page {
  if show-thanks-page {
    pagebreak()
  }
  set par(first-line-indent: (amount: 0em, all: true), leading: 0.95em)
  let primary-author = if authors != none and authors.len() > 0 { authors.at(0) } else { none }
  let author-website-raw = if primary-author != none and primary-author.website != none and primary-author.website != "" { primary-author.website } else { website-url }
  let author-website-url = author-website-raw.replace("\\/", "/")
  let author-website-text = if primary-author != none and primary-author.website != none and primary-author.website != "" { author-website-url } else { website-text }
  let author-wechat-text = if primary-author != none and primary-author.wechat != none and primary-author.wechat != "" { primary-author.wechat } else { wechat-text }
  let author-contact-email = if primary-author != none and primary-author.email != none and primary-author.email != "" { primary-author.email } else { contact-email }
  let author-images = (
    (path: effective-wechat-image, caption: wechat-caption, scale: 1),
    // 默认网站二维码白边为 80/740，公众号为 30/430；补偿可见码区比例。
    (path: effective-blog-image, caption: blog-caption,
      scale: if effective-blog-image == "_assets/qsight.png" { (370 / 430) / (580 / 740) } else { 1 }),
  ).filter(item => item.path != none)
  v(1em)
  align(center)[
    #text(size: 1.6em, fill: luma(80), font: heading-family, tracking: 10pt,
              weight: 500)[#author-page-title]
    #linebreak()
    #qbar-text(text-weight: 300,
               text-color: luma(60),
               border-color: theme-color
               )[#author-bio]
   #v(1em)
  ]

  if author-images.len() > 0 {
    place(center + horizon, dy: 1.8em)[
      #block(
        width: if author-images.len() == 1 { 28% } else { 55% },
        inset: (top: 0em, bottom: 2.4em),
      )[
        #grid(
          columns: (1fr,) * author-images.len(),
          gutter: 1em,
          ..author-images.map(item => figure(
            numbering: none,
            layout(size => {
              let side = size.width * 78%
              box(width: side, height: side, clip: true)[
                #place(center + horizon, image(item.path,
                  width: side * item.scale, height: side * item.scale, fit: "contain"))
              ]
            }),
            caption: [#text(size: 0.9em)[#item.caption]],
          )),
        )
      ]
    ]
  }

  place(bottom + center, dy: -2.2em)[
    #grid(
      columns: (1fr, 1fr, 1fr), gutter: 1em, align: center,
      text(size:0.8em, fill: luma(100))[ 🌎 #link(author-website-url)[#author-website-text]],
      text(size:0.8em, fill: luma(100))[ ✍️ #author-wechat-text],
      text(size:0.8em, fill: luma(100))[ 📬 #author-contact-email]
    )
  ]
  
}

}
