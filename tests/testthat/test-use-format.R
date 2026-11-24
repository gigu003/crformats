test_that("update_qmd_format writes YAML booleans as true and false", {
  target_qmd <- tempfile(fileext = ".qmd")
  source_qmd <- tempfile(fileext = ".qmd")

  writeLines(
    c(
      "---",
      "execute:",
      "  eval: true",
      "  echo: true",
      "  warning: false",
      "  message: false",
      "format: html",
      "---",
      "",
      "Body"
    ),
    target_qmd
  )
  writeLines(
    c(
      "---",
      "format:",
      "  qcslides-typst:",
      "    fontsize: 20pt",
      "---"
    ),
    source_qmd
  )

  crformats:::update_qmd_format(target_qmd, source_qmd)
  result <- readLines(target_qmd)

  expect_match(result, "^  eval: true$", all = FALSE)
  expect_match(result, "^  echo: true$", all = FALSE)
  expect_match(result, "^  warning: false$", all = FALSE)
  expect_match(result, "^  message: false$", all = FALSE)
  expect_no_match(result, "^  (eval|echo|warning|message): (yes|no)$")
})

test_that("format helpers are exported under their new names", {
  exports <- getNamespaceExports("crformats")

  expect_match(exports, "^use_format$", all = FALSE)
  expect_match(exports, "^ls_format$", all = FALSE)
  expect_no_match(exports, "^(use_quarto_ext|ls_ext)$")
})
