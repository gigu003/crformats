#' Use the docx templates in the manuscript package
#'
#' @param name Name of the docx template.
#' @param overwrite Whether to overwrite the template file if it exists.
#'
#' @return Path of the created/used template.
#' @export
#' @examples
#' \dontrun{
#' use_docx_template("chinese")
#' }
use_docx_template <- function(name = "chinese", overwrite = TRUE) {

  template <- paste0(name, ".docx")
  pkg_folder <- system.file("docx_templates", package = "crformats")
  if (pkg_folder == "") {
    stop("Package does not contain a 'inst/docx_templates' folder.
Move your templates into 'inst/docx_templates/'.")
  }

  source_file <- fs::path(pkg_folder, template)
  if (!fs::file_exists(source_file)) {
    stop("Template '", template, "' not found in inst/docx_templates/.")
  }
  dest_dir <- fs::path("formats", "templates")
  dest_file <- fs::path(dest_dir, template)


  if (!fs::dir_exists(dest_dir)){
    fs::dir_create(dest_dir, recurse = TRUE)
  }


  fs::file_copy(source_file, dest_file, overwrite = overwrite)

  if (overwrite) {
    message("Template copied and overwritten: ", dest_file)
  } else {
    message("Template copied: ", dest_file)
  }
}

#' List available docx templates in the package
#'
#' @return A character vector of docx template file names.
#' @export
#' @examples
#' ls_docx()
#'
ls_docx <- function() {

  docx_path <- system.file("docx_templates", package = "crformats")

  if (docx_path == "") {
    stop("Directory 'docx_templates' not found in the package.")
  }

  docx_files <- list.files(docx_path, pattern = "\\.docx$", full.names = FALSE)

  return(docx_files)
}
