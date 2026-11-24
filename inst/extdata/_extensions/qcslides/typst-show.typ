
// Typst custom formats typically consist of a 'typst-template.typ' (which is
// the source code for a typst template) and a 'typst-show.typ' which calls the
// template's function (forwarding Pandoc metadata values as required)
//
// This is an example 'typst-show.typ' file (based on the default template  
// that ships with Quarto). It calls the typst function named 'article' which 
// is defined in the 'typst-template.typ' file. 
//
// If you are creating or packaging a custom typst template you will likely
// want to replace this file and 'typst-template.typ' entirely. You can find
// documentation on creating typst templates here and some examples here:
//   - https://typst.app/docs/tutorial/making-a-template/
//   - https://github.com/typst/templates
#show: doc => article(
$if(title)$
  title: [$title$],
$endif$
$if(subtitle)$
  subtitle: [$subtitle$],
$endif$
$if(last-page)$
  last-page: $last-page$,
$endif$
$if(thanks-page)$
  thanks-page: $thanks-page$,
$endif$
$if(author-page)$
  author-page: $author-page$,
$endif$
$if(description)$
  description: [$description$],
$endif$
$if(categories)$
  categories:[$for(categories)$🏷️#h(0.2em)$categories$$sep$ #h(1em) $endfor$],
$endif$
$if(series)$
  series: [$series$],
$endif$
$if(logo-text)$
  logo-text: [$logo-text$],
$endif$
$if(logo-image)$
  logo-image: "$logo-image$",
$endif$
$if(logo-height)$
  logo-height: $logo-height$,
$endif$
$if(logo-layout)$
  logo-layout: "$logo-layout$",
$endif$
$if(title-page-style)$
  title-page-style: "$title-page-style$",
$endif$
$if(title-page-bg-image)$
  title-page-bg-image: "$title-page-bg-image$",
$endif$
$if(title-page-bg-opacity)$
  title-page-bg-opacity: $title-page-bg-opacity$,
$endif$
$if(title-page-bg-fit)$
  title-page-bg-fit: "$title-page-bg-fit$",
$endif$
$if(body-bg-image)$
  body-bg-image: "$body-bg-image$",
$endif$
$if(body-bg-opacity)$
  body-bg-opacity: $body-bg-opacity$,
$endif$
$if(body-bg-fit)$
  body-bg-fit: "$body-bg-fit$",
$endif$
$if(title-block-width)$
  title-block-width: $title-block-width$,
$endif$
$if(title-block-y)$
  title-block-y: $title-block-y$,
$endif$
$if(title-category-fill)$
  title-category-fill: $title-category-fill$,
$endif$
$if(title-meta-color)$
  title-meta-color: $title-meta-color$,
$endif$
$if(title-meta-y)$
  title-meta-y: $title-meta-y$,
$endif$
$if(hide-header)$
  hide-header: $hide-header$,
$endif$
$if(hide-footer)$
  hide-footer: $hide-footer$,
$endif$
$if(hide-page-number)$
  hide-page-number: $hide-page-number$,
$endif$
$if(series-label)$
  series-label: [$series-label$],
$endif$
$if(by-author)$
  authors: (
$for(by-author)$
$if(it.name.literal)$
    ( name: [$it.name.literal$],
      affiliation: [$for(it.affiliations)$$it.name$$sep$, $endfor$],
      email: [$it.email$],
      website: $if(it.metadata.website)$"$it.metadata.website$"$else$none$endif$,
      wechat: $if(it.metadata.wechat)$[$it.metadata.wechat$]$else$none$endif$ ),
$endif$
$endfor$
    ),
$endif$
$if(date)$
  date: [$date$],
$endif$
$if(lang)$
  lang: "$lang$",
$endif$
$if(region)$
  region: "$region$",
$endif$
$if(width)$
  width: $width$,
$endif$
$if(height)$
  height: $height$,
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
$if(fontsize)$
  fontsize: $fontsize$,
$elseif(brand.typography.base.size)$
  fontsize: $brand.typography.base.size$,
$endif$
$if(title-size)$
  title-size: $title-size$,
$elseif(heading-size)$
  title-size: $heading-size$,
$endif$
$if(title-line-height)$
  title-line-height: $title-line-height$,
$endif$
$if(title-font)$
  title-font: "$title-font$",
$elseif(heading-family)$
  title-font: "$heading-family$",
$elseif(brand.typography.headings.family)$
  title-font: $brand.typography.headings.family$,
$endif$
$if(subtitle-size)$
  subtitle-size: $subtitle-size$,
$endif$
$if(subtitle-font)$
  subtitle-font: "$subtitle-font$",
$endif$
$if(title)$
$if(brand.typography.headings.family)$
  heading-family: $brand.typography.headings.family$,
$endif$
$if(brand.typography.headings.weight)$
  heading-weight: $brand.typography.headings.weight$,
$endif$
$if(brand.typography.headings.style)$
  heading-style: "$brand.typography.headings.style$",
$endif$
$if(brand.typography.headings.decoration)$
  heading-decoration: "$brand.typography.headings.decoration$",
$endif$
$if(brand.typography.headings.color)$
  heading-color: $brand.typography.headings.color$,
$endif$
$if(brand.typography.headings.line-height)$
  heading-line-height: $brand.typography.headings.line-height$,
$endif$
$endif$
$if(heading-size)$
  heading-size: $heading-size$,
$endif$
$if(heading-family)$
  heading-family: "$heading-family$",
$endif$
$if(heading-image)$
  heading-image: "$heading-image$",
$endif$
$if(card-image)$
  card-image: "$card-image$",
$endif$
$if(card-bg)$
  card-bg: $card-bg$,
$endif$
$if(section-numbering)$
  sectionnumbering: "$section-numbering$",
$endif$
$if(theme-color)$
  theme-color: $theme-color$,
$endif$
$if(code-font)$
  code-font: "$code-font$",
$endif$
$if(code-size)$
  code-size: $code-size$,
$endif$
$if(code-leading)$
  code-leading: $code-leading$,
$endif$
$if(code-fill)$
  code-fill: $code-fill$,
$endif$
$if(code-border)$
  code-border: $code-border$,
$endif$
$if(code-radius)$
  code-radius: $code-radius$,
$endif$
$if(code-inset)$
  code-inset: $code-inset$,
$endif$
$if(first-line-indent)$
  first-line-indent: $first-line-indent$,
$endif$
$if(section-overview)$
  section-overview: $section-overview$,
$endif$
$if(section-overview-style)$
  section-overview-style: "$section-overview-style$",
$endif$
$if(last-page-title)$
  last-page-title: [$last-page-title$],
$endif$
$if(last-page-subtitle)$
  last-page-subtitle: [$last-page-subtitle$],
$endif$
$if(website-url)$
  website-url: "$website-url$",
$endif$
$if(website-text)$
  website-text: [$website-text$],
$endif$
$if(wechat-text)$
  wechat-text: [$wechat-text$],
$endif$
$if(contact-email)$
  contact-email: [$contact-email$],
$endif$
$if(author-page-title)$
  author-page-title: [$author-page-title$],
$endif$
$if(author-bio)$
  author-bio: [$author-bio$],
$endif$
$if(wechat-image)$
  wechat-image: "$wechat-image$",
$endif$
$if(wechat-caption)$
  wechat-caption: [$wechat-caption$],
$endif$
$if(blog-image)$
  blog-image: "$blog-image$",
$endif$
$if(blog-caption)$
  blog-caption: [$blog-caption$],
$endif$
  pagenumbering: $if(page-numbering)$"$page-numbering$"$else$none$endif$,
  cols: $if(columns)$$columns$$else$1$endif$,
  doc,
)
