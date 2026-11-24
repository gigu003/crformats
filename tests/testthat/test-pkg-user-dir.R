test_that("pkg_user_dir returns R's package-specific directory", {
  expect_identical(
    pkg_user_dir("crflow"),
    tools::R_user_dir("crflow", "config")
  )
  expect_identical(
    pkg_user_dir("crflow", which = "cache"),
    tools::R_user_dir("crflow", "cache")
  )
})

test_that("pkg_user_dir requires one non-empty package name", {
  expect_snapshot(error = TRUE, pkg_user_dir(character()))
  expect_snapshot(error = TRUE, pkg_user_dir(""))
})
