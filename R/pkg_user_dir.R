#' Locate a package user directory
#'
#' Return the platform-specific directory that R reserves for a package's user
#' data, configuration, or cache. The directory is not created by this
#' function. For example, on macOS `pkg_user_dir("crflow")` returns
#' `~/Library/Preferences/org.R-project.R/R/crflow`.
#'
#' @param package A single package name.
#' @param which Type of directory to return: `"config"` (the default),
#'   `"data"`, or `"cache"`.
#'
#' @return A character string containing the platform-specific directory path.
#' @export
#'
#' @examples
#' pkg_user_dir("crflow")
#' pkg_user_dir("crflow", which = "cache")
pkg_user_dir <- function(package, which = c("config", "data", "cache")) {
  if (
    !is.character(package) ||
      length(package) != 1 ||
      is.na(package) ||
      !nzchar(package)
  ) {
    stop("`package` must be one non-empty package name.", call. = FALSE)
  }

  tools::R_user_dir(package, match.arg(which))
}
