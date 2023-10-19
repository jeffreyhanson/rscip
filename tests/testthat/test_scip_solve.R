test_that("works with sparse matrix", {
  # run optimization
  x <- scip_solve(
    obj = c(1, 1, 2),
    modelsense = "max",
    lb = c(0, 0, 0),
    ub = c(1, 1, 1),
    rhs = c(4, 1),
    sense = c("<=", ">="),
    vtype = c("B", "B", "B"),
    A = as_Matrix(
      matrix(c(1, 2, 3, 1, 1, 0), nrow = 2, ncol = 3, byrow = TRUE),
      "dgCMatrix"
    ),
    verbose = FALSE
  )
  # tests
  expect_type(x, "list")
  expect_named(x, c("objval", "x", "status"))
  expect_equal(x$objval, 3)
  expect_equal(x$x, c(1, 0 ,1))
  expect_equal(x$status, "SCIP_STATUS_OPTIMAL")
})

test_that("works with basic matrix", {
  # run optimization
  x <- scip_solve(
    obj = c(1, 1, 2),
    modelsense = "max",
    lb = c(0, 0, 0),
    ub = c(1, 1, 1),
    rhs = c(4, 1),
    sense = c("<=", ">="),
    vtype = c("B", "B", "B"),
    A = matrix(c(1, 2, 3, 1, 1, 0), nrow = 2, ncol = 3, byrow = TRUE),
    verbose = FALSE
  )
  # tests
  expect_type(x, "list")
  expect_named(x, c("objval", "x", "status"))
  expect_equal(x$objval, 3)
  expect_equal(x$x, c(1, 0 ,1))
  expect_equal(x$status, "SCIP_STATUS_OPTIMAL")
})

test_that("handles infeasible problems", {
  # run optimization
  x <- scip_solve(
    obj = c(1, 2),
    modelsense = "max",
    A = matrix(c(1, 1, 1, 1), ncol = 2, nrow = 2),
    vtype = c("B", "B"),
    sense = c(">=", "="),
    rhs = c(1, 1),
    ub = c(1, 1),
    lb = c(1, 1),
    verbose = FALSE
  )
  # tests
  expect_type(x, "list")
  expect_equal(x$objval, NULL)
  expect_equal(x$x, NULL)
  expect_equal(x$status, "SCIP_STATUS_INFEASIBLE")
})

test_that("handles unbounded problems", {
  # run optimization
  x <- scip_solve(
    obj = c(1, 2),
    A = matrix(c(1, 1, 1, 1), ncol = 2, nrow = 2),
    vtype = c("C", "C"),
    sense = c(">=", ">="),
    rhs =  c(0, 0),
    ub = c(Inf, Inf),
    lb = c(0, 0),
    verbose = FALSE
  )
  # tests
  expect_type(x, "list")
  expect_named(x, c("objval", "x", "status"))
  expect_equal(x$objval, NULL)
  expect_equal(x$x, NULL)
  expect_equal(x$status, "SCIP_STATUS_UNBOUNDED")
})

test_that("handles integer variables", {
  # simulate data
  set.seed(1)
  max_capacity <- 1000
  n <- 10
  weights <- round(runif(n, max = max_capacity))
  cost <- round(runif(n) * 100)
  # run optimization
  x <- scip_solve(
    obj = cost,
    A = matrix(weights, ncol = n, nrow = 1),
    vtype = rep("I", n),
    sense = c("<="),
    rhs = max_capacity,
    modelsense = "max",
    lb = rep.int(0, n),
    ub = rep.int(5, n),
    verbose = FALSE
  )
  # tests
  expect_type(x, "list")
  expect_named(x, c("objval", "x", "status"))
  expect_true(all(x$x %in% seq(0, 5)))
})

test_that("handles continuous variables", {
  # simulate data
  set.seed(1)
  max_capacity <- 1000
  n <- 10
  weights <- round(runif(n, max = max_capacity))
  cost <- round(runif(n) * 100)
  # run optimization
  x <- scip_solve(
    obj = cost,
    A = matrix(weights, ncol = n, nrow = 1),
    vtype = rep("C", n),
    sense = c("<="),
    rhs = max_capacity,
    modelsense = "max",
    lb = rep.int(0, n),
    ub = rep.int(5, n),
    verbose = FALSE
  )
  # tests
  expect_type(x, "list")
  expect_named(x, c("objval", "x", "status"))
  expect_true(all(x$x >= 0))
  expect_true(all(x$x <= 5))
  expect_gt(max(x$x %% 1), 0) # check all numbers aren't just integers
})

test_that("fails if constraints and obj lengths do not match", {
  expect_error(
    scip_solve(
      obj = c(1, 2),
      A = matrix(c(1, 2), ncol = 1, nrow = 2),
      vtype = c("B", "B"),
      sense = c("<=", "<="),
      rhs = c(1, 2),
      lb = c(0, 0),
      ub = c(1, 1),
      verbose = FALSE
    ),
    "not equal to"
  )
})

test_that("fails if constraints and rhs lengths do not match", {
  expect_error(
    scip_solve(
      obj = c(1, 2),
      A = matrix(c(1, 2), ncol = 1, nrow = 2),
      vtype = c("B", "B"),
      sense = c("<=", "<="),
      rhs = c(1, 2, 1),
      lb = c(0, 0),
      ub = c(1, 1),
      verbose = FALSE
    ),
    "not equal to"
  )
})

test_that("fails if constraints and sense lengths do not match", {
  expect_error(
    scip_solve(
      obj = c(1, 2),
      A = matrix(c(1, 2), ncol = 1, nrow = 2),
      vtype = c("B", "B"),
      sense = c("<=", "<=", "="),
      rhs = c(1, 2),
      lb = c(0, 0),
      ub = c(1, 1),
      verbose = FALSE
    ),
    "not equal to"
  )
})

test_that("fails if obj and lb lengths do not match", {
  expect_error(
    scip_solve(
      obj = c(1, 2),
      A = matrix(c(1, 2), ncol = 1, nrow = 2),
      vtype = c("B", "B"),
      sense = c("<=", "<="),
      rhs = c(1, 2),
      lb = c(0, 0, 1),
      ub = c(1, 1),
      verbose = FALSE
    ),
    "not equal to"
  )
})

test_that("fails if obj and ub lengths do not match", {
  expect_error(
    scip_solve(
      obj = c(1, 2),
      A = matrix(c(1, 2), ncol = 1, nrow = 2),
      vtype = c("B", "B"),
      sense = c("<=", "<="),
      rhs = c(1, 2),
      lb = c(0, 0),
      ub = c(1, 1, 1),
      verbose = FALSE
    ),
    "not equal to"
  )
})

test_that("fails if obj and vtype lengths do not match", {
  expect_error(
    scip_solve(
      obj = c(1, 2),
      A = matrix(c(1, 2), ncol = 1, nrow = 2),
      vtype = c("B", "B", "C"),
      sense = c("<=", "<="),
      rhs = c(1, 2),
      lb = c(0, 0),
      ub = c(1, 1),
      verbose = FALSE
    ),
    "not equal to"
  )
})
