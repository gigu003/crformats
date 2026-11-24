# Compatibility entrypoint for maintainers who still source this file.
#
# For ordinary development, run `devtools::load_all()` once and call
# `crformats:::update_formats()` directly. Sourcing this file retains the
# previous workflow without requiring an installed package.
source(file.path("R", "update_formats.R"), local = globalenv())
