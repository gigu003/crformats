#' Copy an Internal File from the Package
#'
#'
#' @param folder A string indicating the internal folder in the package
#'    (relative to `inst/`) containing the file.
#' @param file A string specifying the name of the file to copy.
#' @param dest A string specifying the destination path (including filename) to
#'    copy the file to.
#' @param overwrite Logical; if `TRUE`, will overwrite the file at the
#'    destination if it exists. Default is `FALSE`.
#'
#' @return `NULL` (invisibly). The function is called for its side effect of
#'    copying a file.
copy_internal_file <- function(folder, file, dest, overwrite = FALSE) {
  f <- system.file(folder, file, package = "crformats")
  if (f == "") {
    stop("Internal file not found in package: ", file,
         "\nMake sure it is located in inst/", folder)
  }
  fs::file_copy(f, dest, overwrite = overwrite)
}
