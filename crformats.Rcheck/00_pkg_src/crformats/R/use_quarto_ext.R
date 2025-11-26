#' Install bundled Quarto extensions into specified directory
#'
#' @param ext_name String indicating which extension to install
#' @param dir Character string indicating where extension to install
#' @param use_qmd Logical, whether to copy default qmd file
#' @param qmd_name Name for the .qmd file (default is 'index.qmd')
#'
#' @return a message if extension was successfully copied over
#' @export
#' @examples
#' \dontrun{
#' use_quarto_ext("qcreport")
#' }
use_quarto_ext <- function(ext_name = "qcreport",
                           dir = NULL,
                           use_qmd = TRUE,
                           qmd_name = "index"
                           ) {
  # Locate bundled extensions folder inside package
  folder <- system.file("extdata/_extensions", package = "crformats")

  # Check if extension is available
  available <- list.files(folder)
  stopifnot("Extension not in package" = ext_name %in% available)
  if (!is.null(dir)) fs::dir_create(dir)
  path_ext <- ifelse(
    is.null(dir),
    path("_extensions"),
    path(dir, "_extensions")
    )
  # check for existing _extensions directory
  if(!file_exists(here(path_ext))) dir_create(here(path_ext))
  message(paste0("Folder was created at", here(path_ext)))
  addr <- system.file(
    path("extdata", "_extensions", ext_name, "_extension.yml"),
    package = "crformats"
    )
  # various reading of key-value pairs for reporting
  ext_yml <- readLines(addr)

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

  # Create folder for recursive copying into ahead of time
  if(!file_exists(here(path_ext, ext_name))) dir_create(here(path_ext, ext_name))

  # copy from internals
  file.copy(
    from = system.file(
      path("extdata", "_extensions", ext_name), package = "crformats"
      ),
    to = here(path_ext),
    overwrite = TRUE,
    recursive = TRUE,
    copy.mode = TRUE
  )

  # logic check to make sure extension files were moved
  n_files <- length(dir(paste0("_extensions/", ext_name)))

  if(n_files >= 2){
    message(paste(ext_nm, "v", ext_ver, "was installed to _extensions folder in current working directory."))
  } else {
    message("Extension appears to not have been created")
  }

  if (use_qmd) {
    # Locate bundled extensions folder inside package
    tem <- system.file("quarto", paste0(ext_name, ".qmd"), package = "crformats")
    qmd_dir <- ifelse(is.null(dir),
                      paste0(qmd_name, ".qmd"),
                      path(dir, paste0(qmd_name, ".qmd"))
                      )
    file.copy(tem, qmd_dir)

    # open the new file in the editor
    file.edit(qmd_dir)
  }

}

#' List bundled Quarto extensions
#'
#' @return a string of available extensions for install
#' @export
#' @examples
#' ls_ext()
#'
ls_ext <- function(){
  list.files(
    system.file(path("extdata", "_extensions"), package = "crformats")
    )
}
