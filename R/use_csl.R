#' Use a bundled CSL file
#'
#' Copy a CSL file bundled with the package from `inst/csls` to a target
#' directory. The `.csl` suffix is added automatically when omitted.
#'
#' @param name Name of the CSL file. The `.csl` suffix can be omitted.
#' @param dir Directory to copy the CSL file into. Defaults to the current
#'   working directory.
#' @param overwrite Whether to overwrite the CSL file if it already exists.
#' @param update_yaml Whether to update the YAML header of a qmd file by adding
#'   or replacing the `csl` field.
#' @param qmd_file Name of the qmd file to update when `update_yaml = TRUE`.
#'   Defaults to `"index.qmd"` in `dir`.
#'
#' @return Invisibly returns the path of the copied CSL file.
#' @export
#' @examples
#' \dontrun{
#' use_csl("chinese-gb7714-2005-numeric")
#' }
use_csl <- function(name = "chinese-gb7714-2005-numeric",
                    dir = ".",
                    overwrite = TRUE,
                    update_yaml = TRUE,
                    qmd_file = "index.qmd") {

  csl_file <- if (grepl("\\.csl$", name)) name else paste0(name, ".csl")
  csl_path <- system.file("csls", package = "crformats")

  if (csl_path == "") {
    stop("Package does not contain a 'inst/csls' folder.\n",
         "Move your CSL files into 'inst/csls/'.",
         call. = FALSE)
  }

  source_file <- fs::path(csl_path, csl_file)

  if (!fs::file_exists(source_file)) {
    available <- ls_csl()
    stop(
      "CSL file '", csl_file, "' not found in inst/csls/.",
      if (length(available) > 0) {
        paste0("\nAvailable CSL files: ", paste(available, collapse = ", "))
      },
      call. = FALSE
    )
  }

  if (!fs::dir_exists(dir)) {
    fs::dir_create(dir, recurse = TRUE)
  }

  dest_file <- fs::path(dir, csl_file)

  if (fs::file_exists(dest_file) && !overwrite) {
    stop(
      "Target CSL file already exists: ", dest_file,
      "\nUse overwrite = TRUE to overwrite it.",
      call. = FALSE
    )
  }

  fs::file_copy(source_file, dest_file, overwrite = overwrite)

  if (overwrite) {
    message("CSL file copied and overwritten: ", dest_file)
  } else {
    message("CSL file copied: ", dest_file)
  }

  if (update_yaml) {
    qmd_path <- fs::path(dir, qmd_file)

    if (!fs::file_exists(qmd_path)) {
      warning("QMD file not found, YAML header was not updated: ", qmd_path,
              call. = FALSE)
    } else {
      update_qmd_csl(qmd_path, csl_file)
      message("QMD YAML header updated: ", qmd_path)
    }
  }

  invisible(dest_file)
}

update_qmd_csl <- function(qmd_path, csl_file) {
  qmd <- split_qmd(qmd_path)
  qmd_yaml <- qmd$yaml
  qmd_yaml$csl <- csl_file

  yaml_text <- yaml::as.yaml(qmd_yaml)
  yaml_lines <- unlist(strsplit(yaml_text, "\n", fixed = TRUE))
  yaml_lines <- yaml_lines[nzchar(yaml_lines)]

  writeLines(c("---", yaml_lines, "---", qmd$body), qmd_path, useBytes = TRUE)
  invisible(qmd_path)
}

#' List available CSL files in the package
#'
#' @return A character vector of CSL file names.
#' @export
#' @examples
#' ls_csl()
ls_csl <- function() {

  csl_path <- system.file("csls", package = "crformats")

  if (csl_path == "") {
    stop("Directory 'csls' not found in the package.", call. = FALSE)
  }

  list.files(csl_path, pattern = "\\.csl$", full.names = FALSE)
}