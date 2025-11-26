#' Use the docx templates in the manuscript package
#'
#' @param name Name of the docx template.
#' @param overwrite Whether overwrite the template file if it existed.
#'
#' @return Created docx template.
#' @export
#'
use_docx_template <- function(name = "english", overwrite = TRUE) {
  template <- paste0(name, ".docx")
  tem_path <- fs::path("formats", "templates")
  if(!fs::dir_exists(tem_path)){
    fs::dir_create(tem_path)
  }

  file_path <- fs::path(tem_path, template)
  if (!fs::file_exists(file_path)) {
      copy_internal_file("docx_templates", template,
                         fs::path("formats", "templates", template))
    } else if (overwrite){
      copy_internal_file("docx_templates", template,
                         fs::path("formats", "templates", template),
                         overwrite = TRUE)
      cat(paste0("Template file already existed, and it has been overwrite."),
          fill = TRUE)
    } else {
      cat(paste0("Template file already existed.",
                 "You cancer specific overwrite = TRUE to overwrite it."),
          fill = TRUE)
    }
}

#' List available docx templates in the package
#'
#' @return A character vector of docx template file names.
#' @export
#'
ls_docx_template <- function() {
  # Get the path to the docx_templates folder
  docx_path <- fs::path(system.file(package = "manuscript"), "docx_templates")

  # Check if the path exists
  if (!fs::dir_exists(docx_path)) {
    stop("Directory 'docx_templates' not found in the package.")
  }
  # List files in the docx_templates folder
  docx_files <- list.files(docx_path, pattern = "\\.docx$", full.names = FALSE)

  return(docx_files)
}
