
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

// 定义函数：Quarto 原生 callout 的 qcard 样式
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
    fill: calloutColor.lighten(92%),
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
#let qmetric(
  value: none,
  label: none,
  note: none,
  fill: red.lighten(94%),
  strokeColor: red,
) = {
  align(center + horizon)[
    #block(
      width: 82%,
      inset: (x: 1.5em, y: 1.2em),
      stroke: 1.2pt + strokeColor,
      fill: fill,
      radius: 0.5em,
    )[
      #align(center)[
        #text(size: 3.2em, fill: strokeColor, weight: 900, tracking: 1pt)[#value]
        #if label != none {
          v(0.4em)
          text(size: 1.15em, fill: luma(45), weight: 500)[#label]
        }
        #if note != none {
          v(0.5em)
          text(size: 0.85em, fill: luma(90), weight: 300)[#note]
        }
      ]
    ]
  ]
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


#let article(
  title-page: none,
  last-page: none,
  title: none,
  subtitle: none,
  description: none,
  categories: none,
  series: none,
  logo-text: "河南省肿瘤医院",
  title-page-style: "classic",
  title-block-width: 72%,
  title-block-y: 30%,
  title-category-fill: none,
  title-meta-color: luma(90),
  title-decoration: true,
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
  heading-size: 32pt,
  heading-family: "STHeiti",
  heading-weight: "bold",
  heading-style: "normal",
  heading-color: black,
  heading-line-height: 1.3em,
  sectionnumbering: none,
  pagenumbering: "1",
  theme-color: red,
  first-line-indent: 0em,
  section-overview: false,
  section-overview-style: "simple",
  section-overview-title-x: 10mm,
  section-overview-list-x: 35mm,
  section-overview-list-width: 68%,
  section-overview-item-height: 14mm,
  section-overview-item-inset: (left: 0.85em, right: 1.3em, top: 0.35em, bottom: 0.35em),
  section-overview-item-font-size: 1.0em,
  section-overview-marker-radius: 1.15em,
  section-overview-muted-color: luma(130),
  section-overview-muted-marker-color: luma(180),
  heading-image: none,
  card-image: "dog.png",
  card-bg: luma(250),
  last-page-title: "请批评指正",
  last-page-subtitle: "Thanks for your attention",
  website-url: "https://chenq.site",
  website-text: "https://www.chenq.site",
  wechat-text: "微信公众号【普癌新声】",
  contact-email: "chenq08\@126.com",
  author-page-title: "关注作者👀",
  author-bio: [陈琼博士#h(1em)副主任医师#h(2em)河南省癌症中心｜河南省肿瘤医院],
  wechat-image: "_assets/wechat.jpg",
  wechat-caption: "微信公众号",
  blog-image: "_assets/qsight.png",
  blog-caption: "Qsight博客",
  doc,
) = {

// 字体大小
let header-size = 0.7em

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
      place(horizon + left, dx: -10mm,
            qbar-text(border-color: theme-color,
                      text-size: text-size,
                      border-size: 0.3em,
                      inset-y: 0.2em,
                      inset-x: 0.6em)[®#logo-text]
            )
      if series != none {
      place(horizon + right, dx: 10mm,
            text(size: text-size,
                 fill: luma(100),
                 tracking: 1pt,
                 weight: 100)[#series-label#h(0.2em)\/\/#h(0.2em)#series]
            )
      }
}

// 定义函数：qfooter
let qfooter(text-size: 0.7em,
            fill: gradient.linear(..color.map.crest)
            ) = {
  qbar(bar-width: width, position: bottom + center, fill: fill)
  if not hide-page-number and counter(page).get().at(0) > 1 {
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

let qsection-overview(current) = context {
  let sections = query(heading.where(level: 1))

  align(center + horizon)[
    #block(width: 80%)[
      #set par(first-line-indent: 0em, spacing: 1.1em)
      #for (idx, section) in sections.enumerate() {
        let is-current = section.location() == current.location()
        let item-color = if is-current { theme-color } else { luma(120) }
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
            text(size: item-size, fill: item-color, weight: item-weight, tracking: 1pt)[#section.body],
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

  place(left + horizon, dx: section-overview-title-x)[
    #block(width: 52mm)[
      #align(left)[
        #text(size: 2.35em, fill: theme-color, weight: 900, tracking: 6pt)[目录]
        #v(0.2em)
        #text(size: 0.8em, fill: luma(120), weight: 300, tracking: 2pt)[CONTENTS]
      ]
    ]
  ]

  place(center + horizon, dx: section-overview-list-x)[
    #block(width: section-overview-list-width)[
      #set par(first-line-indent: 0em, spacing: 1em)
      #for (idx, section) in sections.enumerate() {
        let is-current = section.location() == current.location()
        let item-color = if is-current { theme-color } else { section-overview-muted-color }
        let item-weight = if is-current { 800 } else { 400 }
        let marker-fill = if is-current { theme-color } else { section-overview-muted-marker-color }

        block(
          width: 100%,
          height: section-overview-item-height,
          inset: section-overview-item-inset,
          fill: white,
          stroke: 0.6pt + theme-color.lighten(78%),
          radius: 999pt,
          outset: (y: 0.25em),
        )[
          #grid(
            columns: (3.6em, 0.7em, 1fr),
            gutter: 0.9em,
            align: horizon,
            circle(
              radius: section-overview-marker-radius,
              fill: marker-fill,
            )[
              #align(center + horizon)[
                #text(size: 0.9em, fill: white, weight: 800)[#qsection-number(idx)]
              ]
            ],
            rect(width: 0.7pt, height: 2em, fill: theme-color.lighten(72%)),
            text(size: section-overview-item-font-size, fill: item-color, weight: item-weight, tracking: 1pt)[#section.body],
          )
        ]
      }
    ]
  ]
}

// 设置文档元数据
set document(
    title: title,
    author: "陈琼博士",
    date: auto,
    description: description,
    keywords: ()
  )

//统一页面设置
set page(width: width,
         height: height,
         margin: margin,
         numbering: pagenumbering,
         fill: luma(255),
         header: if not hide-header { context[#qheader()] } else { none },
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
//设置标题序号格式
set heading(numbering: sectionnumbering)

//设置不同级别标题格式
show heading: it => {
  set par(first-line-indent: 0em)
  set text(tracking: 1pt,
           font: heading-family,
           weight: heading-weight,
           style: heading-style,
           fill: heading-color,
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
        set text(size: 1.6em, fill: theme-color)
        align(center+horizon)[
          #box[
            #if it.numbering != none {
              counter(heading).display()
            }
            #h(0.3em)
            #underline(stroke: 3pt + theme-color, offset: 8pt, extent: 0pt)[
                      #it.body
                      ]
          ]
        ]
      }
      
    } else if it.level == 2 {
      pagebreak()
      // 设置二级标题格式
      set text(size: 1.4em, fill: luma(30), weight: 800)
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
show strong: set text(weight: "bold", fill: theme-color)
show emph: set text(weight: "bold", fill: theme-color)
show raw.where(block: false): text.with(
  fill: blue.darken(50%)
)
show raw.where(block: true): it => {
  set par(leading: 0.9em)
  set text(font: "Menlo", size: 0.9em)
  it
}

show quote.where(block: true): it => {
  set par(leading: 1.2em)
  set text(size:1em, style: "italic", weight: 200, fill: luma(50))
  qbar-text(inset-x: 2em, outset-x: -1.4em, inset-y: 0.7em,
            border-color: theme-color)[#it]
  set text(size: fontsize)
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

// 定义函数：经典封面页，保留原有布局
let qtitle-page-classic() = {
  // 标题页图片
  if heading-image != none {
    figure(numbering: none,
           gap: 0.1em,
           image(heading-image, width: 100%, height: 25%)
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
        #set text(tracking: 1pt,
                  font: heading-family,
                  weight: heading-weight,
                  style: heading-style,
                  fill: heading-color)
          #text(size: heading-size)[#title]
      ]]
      ]
    if subtitle != none {
    text(size: heading-size*0.5)[#subtitle]
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
  let category-fill = if title-category-fill == none { theme-color.lighten(92%) } else { title-category-fill }

  if heading-image != none {
    place(top + right)[
      #image(heading-image, width: 42%, height: 100%, fit: "cover")
    ]
    place(top + right)[
      #rect(width: 42%, height: 100%, fill: white.transparentize(18%))
    ]
  }

  if title-decoration {
    place(top + right, dx: -10mm, dy: 28mm)[
      #circle(radius: 18mm, fill: theme-color.lighten(88%))
    ]
  }

  v(title-block-y)
  block(width: title-block-width)[
    #set par(first-line-indent: 0em, spacing: 0.55em)
    #if categories != none {
      block(
        inset: (x: 0.8em, y: 0.35em),
        fill: category-fill,
        radius: 999pt,
      )[
        #text(font: heading-family, size: 0.72em, fill: theme-color, weight: 500, tracking: 1pt)[#categories]
      ]
      v(0.45em)
    }
    #if title != none {
      text(font: heading-family, size: heading-size * 1.05, fill: heading-color, weight: 900, tracking: 1pt)[#title]
    }
    #if subtitle != none {
      v(0.3em)
      text(font: heading-family, size: heading-size * 0.46, fill: luma(85), weight: 300, tracking: 1pt)[#subtitle]
    }
  ]

  place(bottom + left, dy: -14mm)[
    #block(width: 82%)[
      #qtitle-authors(meta-color: title-meta-color)
      #v(0.8em)
      #text(font: heading-family, fill: title-meta-color, size: 0.78em, weight: 300)[📅 #date]
    ]
  ]
}


// 布置title-page
if title-page-style == "modern" {
  qtitle-page-modern()
} else {
  qtitle-page-classic()
}

//页面从1开始计数
counter(page).update(0)

// 正文内容  
if cols == 1 {
    doc
  } else {
    columns(cols, doc)
  }



// 设置谢谢关注页面
if last-page != none {
  set text(font: heading-family, size: 20pt, fill: luma(100))
  set page(fill: luma(250), footer: context[
  #place(bottom + center,
                 rect(width: width, height: 0.2em,
                      fill: gradient.linear(..color.map.crest))
                )
  #place(top+center)[
    #grid(
      columns: (1fr, 1fr, 1fr), gutter: 1em, align: center,
      text(size:0.8em, fill: luma(100))[ 🌎 #link(website-url)[#website-text]],
      text(size:0.8em, fill: luma(100))[ ✍️ #wechat-text],
      text(size:0.8em, fill: luma(100))[ 📬 #contact-email]
    )
    ]
  ])

  place(horizon + center,
        [#text(size: 70pt,
               fill: theme-color,
               tracking: 40pt,
               weight: 800
             )[#last-page-title]
         #text(size: 30pt,
               fill: luma(100),
               tracking: 2pt,
               weight: 300
               )[#linebreak()#last-page-subtitle]
        ]
             )

  pagebreak()
  set par(first-line-indent: (amount: 0em, all: true), leading: 0.95em)
  v(1em)
  align(center)[
  #text(size: 1.6em, fill: luma(80), font: heading-family, tracking: 10pt,
            weight: 500)[#author-page-title]
  #linebreak()
  #qbar-text(text-weight: 300,
             text-color: luma(60)
             )[#author-bio]
  ]
  
  grid(columns: (auto, 1fr, 1fr, auto), gutter: 1em,
      h(20%),
      figure(numbering: none,
             image(wechat-image, width: 90%),
             caption: [#text(size:0.9em)[#wechat-caption]]
             ),
      figure(numbering: none,
             image(blog-image, width: 90%),
             caption: [#text(size:0.9em)[#blog-caption]]
             ),
      h(20%)
  )
  
  }
  
}
