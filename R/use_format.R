#' Use a bundled Quarto format in the current project
#'
#' @param format_name String indicating which format to install.
#' @param dir Character string indicating where to install the format and
#'   example `.qmd` file. If `NULL`, files are installed into the current
#'   working directory.
#' @param use_qmd Logical, whether to copy default qmd file
#' @param qmd_name Name for the .qmd file (default is 'index.qmd')
#' @param overwrite Logical, whether to overwrite existing extension and `.qmd`
#'   files.
#' @param update_yaml Logical, whether to update the `format` field in the YAML
#'   header of `qmd_name`. This is mainly useful when `use_qmd = FALSE`. The
#'   format configuration is copied from the bundled
#'   `inst/quarto/{format_name}.qmd`
#'   file.
#'
#' @return Invisibly returns a list with paths to the installed extension and
#'   copied `.qmd` file.
#' @export
#' @examples
#' \dontrun{
#' use_format("qcreport")
#' }
use_format <- function(
  format_name = "qcreport",
  dir = NULL,
  use_qmd = FALSE,
  qmd_name = "index",
  overwrite = TRUE,
  update_yaml = TRUE
) {
  ext_root <- system.file("extdata/_extensions", package = "crformats")
  if (ext_root == "") {
    stop("Package does not contain bundled Quarto extensions.", call. = FALSE)
  }

  available <- list.files(ext_root)
  if (!format_name %in% available) {
    stop(
      "Format '",
      format_name,
      "' is not available. Available extensions: ",
      paste(available, collapse = ", "),
      call. = FALSE
    )
  }

  target_dir <- if (is.null(dir)) "." else dir
  target_ext_parent <- path(target_dir, "_extensions")
  target_ext_dir <- path(target_ext_parent, format_name)
  target_qmd <- path(target_dir, paste0(qmd_name, ".qmd"))

  source_ext_dir <- path(ext_root, format_name)
  source_qmd <- system.file(
    "quarto",
    paste0(format_name, ".qmd"),
    package = "crformats"
  )
  extension_yml <- path(source_ext_dir, "_extension.yml")

  ext_yml <- readLines(extension_yml, warn = FALSE)
  ext_ver <- gsub(
    x = ext_yml[grepl(x = ext_yml, pattern = "version:")],
    pattern = "version: ",
    replacement = ""
  )
  ext_nm <- gsub(
    x = ext_yml[grepl(x = ext_yml, pattern = "title:")],
    pattern = "title: ",
    replacement = ""
  )

  dir_create(target_dir)
  dir_create(target_ext_parent)

  if (file_exists(target_ext_dir) && !overwrite) {
    stop(
      "Target extension already exists: ",
      target_ext_dir,
      "\nUse overwrite = TRUE to overwrite it.",
      call. = FALSE
    )
  }

  if (file_exists(target_ext_dir) && overwrite) {
    unlink(target_ext_dir, recursive = TRUE, force = TRUE)
  }

  fs::dir_copy(source_ext_dir, target_ext_dir)

  copied_qmd <- NULL
  if (use_qmd) {
    if (source_qmd == "") {
      warning(
        "No bundled qmd example found for format: ",
        format_name,
        call. = FALSE
      )
    } else {
      file_copy(source_qmd, target_qmd, overwrite = overwrite)
      copied_qmd <- target_qmd
      if (interactive()) {
        file.edit(target_qmd)
      }
    }
  }

  if (!use_qmd && update_yaml) {
    if (source_qmd == "") {
      warning(
        "No bundled qmd example found for format: ",
        format_name,
        "; YAML header was not updated.",
        call. = FALSE
      )
    } else if (!file_exists(target_qmd)) {
      warning(
        "QMD file not found, YAML header was not updated: ",
        target_qmd,
        call. = FALSE
      )
    } else {
      update_qmd_format(target_qmd, source_qmd)
      message("QMD YAML format updated: ", target_qmd)
    }
  }

  message(paste(ext_nm, "v", ext_ver, "was installed to", target_ext_dir))
  if (!is.null(copied_qmd)) {
    message("Example qmd was copied to ", copied_qmd)
  }

  invisible(list(extension = target_ext_dir, qmd = copied_qmd))
}

update_qmd_format <- function(target_qmd, source_qmd) {
  source_yaml <- read_qmd_yaml(source_qmd)
  source_format <- source_yaml$format

  if (is.null(source_format)) {
    warning("No format field found in bundled qmd: ", source_qmd, call. = FALSE)
    return(invisible(target_qmd))
  }

  target <- split_qmd(target_qmd)
  target_yaml <- target$yaml
  target_yaml$format <- merge_quarto_format(target_yaml$format, source_format)

  yaml_text <- yaml::as.yaml(
    target_yaml,
    handlers = list(
      logical = \(x) {
        structure(
          ifelse(x, "true", "false"),
          class = "verbatim"
        )
      }
    )
  )
  yaml_lines <- unlist(strsplit(yaml_text, "\n", fixed = TRUE))
  yaml_lines <- yaml_lines[nzchar(yaml_lines)]

  writeLines(
    c("---", yaml_lines, "---", target$body),
    target_qmd,
    useBytes = TRUE
  )
  invisible(target_qmd)
}

read_qmd_yaml <- function(qmd_path) {
  split_qmd(qmd_path)$yaml
}

split_qmd <- function(qmd_path) {
  qmd_lines <- readLines(qmd_path, warn = FALSE)

  has_yaml <- length(qmd_lines) >= 2 && identical(qmd_lines[1], "---")
  if (!has_yaml) {
    return(list(yaml = list(), body = qmd_lines))
  }

  yaml_end <- which(qmd_lines[-1] %in% c("---", "..."))[1] + 1
  if (is.na(yaml_end)) {
    return(list(yaml = list(), body = qmd_lines))
  }

  yaml_lines <- if (yaml_end > 2) qmd_lines[2:(yaml_end - 1)] else character()
  yaml_text <- paste(yaml_lines, collapse = "\n")
  yaml <- yaml::yaml.load(yaml_text)

  if (is.null(yaml)) {
    yaml <- list()
  }

  body <- if (length(qmd_lines) > yaml_end) {
    qmd_lines[(yaml_end + 1):length(qmd_lines)]
  } else {
    character()
  }

  list(yaml = yaml, body = body)
}

merge_quarto_format <- function(target_format, source_format) {
  source_format <- normalize_quarto_format(source_format)
  target_format <- normalize_quarto_format(target_format)

  for (format_name in names(source_format)) {
    target_format[[format_name]] <- source_format[[format_name]]
  }

  target_format
}

normalize_quarto_format <- function(format) {
  if (is.null(format)) {
    return(list())
  }

  if (is.character(format) && length(format) == 1) {
    out <- list("default")
    names(out) <- format
    return(out)
  }

  if (is.list(format)) {
    if (is.null(names(format)) || any(names(format) == "")) {
      stop(
        "Unsupported unnamed format configuration in qmd YAML.",
        call. = FALSE
      )
    }
    return(format)
  }

  stop("Unsupported format configuration in qmd YAML.", call. = FALSE)
}

#' List bundled Quarto formats
#'
#' @return A character vector of available formats.
#' @export
#' @examples
#' ls_format()
#'
ls_format <- function() {
  list.files(
    system.file(path("extdata", "_extensions"), package = "crformats")
  )
}
