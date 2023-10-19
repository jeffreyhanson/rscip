test_that("solves simple IP", {
  # run optimization
  x <- scip_solve(
    obj = c(1, 1, 2),
    modelsense = "max",
    lb = c(0, 0, 0),
    ub = c(1, 1, 1),
    rhs = c(4, 1),
    vtype = c("B", "B", "B"),
    vtype = c("B", "B"),
    A = matrix(c(1, 2, 3, 1, 1, 0), nrow = 2, ncol = 3, byrow = TRUE)
  )
  # tests
  expect_type(x, "list")
  expect_s3_class(x$objval, "numeric")
  expect_s3_class(x$x, "numeric")
  expect_true(is.numeric(x$x))
  expect_s3_class(x$status, "character")
})
