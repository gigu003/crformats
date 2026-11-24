update_formats <- function(
  formats = c(
    "qcreport",
    "govdoc",
    "letter",
    "card",
    "qsight",
    "qcard",
    "qcslides",
    "qcfact",
    "qcbook",
    "qcv"
  ),
  type = c("typst", "revealjs", "docx"),
  base_dir = "/Users/qc0824/Documents/2_Areas/Quarto_extensions",
  overwrite = TRUE,
  clean = TRUE,
  copy_qmd = TRUE,
  qmd_name = "template.qmd",
  target_dir = here::here()
) {
  type <- match.arg(type)

  source_subdir <- switch(
    type,
    typst = "typst-formats",
    revealjs = "revealjs-formats",
    docx = "docx-formats"
  )

  source_root <- fs::path(base_dir, source_subdir)
  if (!fs::dir_exists(source_root)) {
    stop("Source directory does not exist: ", source_root, call. = FALSE)
  }

  for (name in formats) {
    source_extension <- fs::path(source_root, name, "_extensions", name)
    target_extension <- fs::path(
      target_dir,
      "inst",
      "extdata",
      "_extensions",
      name
    )
    copy_extension <- TRUE

    if (!fs::dir_exists(source_extension)) {
      warning(
        "Source extension not found: ",
        source_extension,
        call. = FALSE
      )
      next
    }

    if (fs::dir_exists(target_extension)) {
      if (!overwrite) {
        warning(
          "Target extension already exists and overwrite = FALSE: ",
          target_extension,
          call. = FALSE
        )
        copy_extension <- FALSE
      } else {
        fs::dir_delete(target_extension)
      }
    }

    if (copy_extension) {
      fs::dir_create(fs::path_dir(target_extension))
      fs::dir_copy(
        source_extension,
        target_extension,
        overwrite = overwrite
      )
    }

    if (clean && fs::dir_exists(target_extension)) {
      junk <- fs::dir_ls(
        target_extension,
        regexp = "(^|/)\\.DS_Store$",
        recurse = TRUE,
        all = TRUE,
        fail = FALSE
      )
      if (length(junk) > 0) fs::file_delete(junk)
    }

    if (copy_qmd) {
      preferred_qmd <- fs::path(source_root, name, qmd_name)
      qmd_candidates <- if (fs::file_exists(preferred_qmd)) {
        preferred_qmd
      } else {
        fs::dir_ls(
          fs::path(source_root, name),
          glob = "*.qmd",
          recurse = FALSE,
          fail = FALSE
        )
      }

      if (length(qmd_candidates) == 0) {
        warning("No qmd example found for format: ", name, call. = FALSE)
      } else {
        source_qmd <- qmd_candidates[[1]]
        target_qmd <- fs::path(
          target_dir,
          "inst",
          "quarto",
          paste0(name, ".qmd")
        )

        fs::dir_create(fs::path_dir(target_qmd))

        if (fs::file_exists(target_qmd) && !overwrite) {
          warning(
            "Target qmd already exists and overwrite = FALSE: ",
            target_qmd,
            call. = FALSE
          )
        } else {
          fs::file_copy(source_qmd, target_qmd, overwrite = overwrite)
        }
      }
    }

    message("Updated ", type, " format: ", name)
  }

  invisible(TRUE)
}
