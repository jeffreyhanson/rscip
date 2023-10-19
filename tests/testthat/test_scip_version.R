test_that("gets version number", {
  # get version number
  v <- scip_version()
  expect_true(is.character(v))
  expect_gt(nchar(v), 0)
})
