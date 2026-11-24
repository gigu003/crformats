test_that("update_formats copies a Quarto extension and its example", {
  base_dir <- tempfile()
  target_dir <- tempfile()
  source_dir <- fs::path(base_dir, "typst-formats", "example")
  extension_dir <- fs::path(source_dir, "_extensions", "example")

  fs::dir_create(extension_dir, recurse = TRUE)
  writeLines("extension", fs::path(extension_dir, "_extension.yml"))
  writeLines("---\nformat: html\n---", fs::path(source_dir, "template.qmd"))

  expect_invisible(
    crformats:::update_formats(
      formats = "example",
      type = "typst",
      base_dir = base_dir,
      target_dir = target_dir
    )
  )

  expect_true(fs::file_exists(fs::path(
    target_dir,
    "inst",
    "extdata",
    "_extensions",
    "example",
    "_extension.yml"
  )))
  expect_true(fs::file_exists(fs::path(
    target_dir,
    "inst",
    "quarto",
    "example.qmd"
  )))
})

test_that("update_formats copies docx Quarto extensions", {
  base_dir <- tempfile()
  target_dir <- tempfile()
  source_dir <- fs::path(base_dir, "docx-formats", "example")
  extension_dir <- fs::path(source_dir, "_extensions", "example")

  fs::dir_create(extension_dir, recurse = TRUE)
  writeLines("extension", fs::path(extension_dir, "_extension.yml"))
  writeLines("---\nformat: docx\n---", fs::path(source_dir, "template.qmd"))

  expect_invisible(
    crformats:::update_formats(
      formats = "example",
      type = "docx",
      base_dir = base_dir,
      target_dir = target_dir
    )
  )

  expect_equal(
    readLines(fs::path(
      target_dir,
      "inst",
      "extdata",
      "_extensions",
      "example",
      "_extension.yml"
    )),
    "extension"
  )
})

test_that("update_formats remains internal", {
  expect_false("update_formats" %in% getNamespaceExports("crformats"))
})
