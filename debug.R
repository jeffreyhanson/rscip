devtools::load_all()
x <- scip_solve(
  obj = c(1, 1, 2),
  modelsense = "max",
  lb = c(0, 0, 0),
  ub = c(1, 1, 1),
  rhs = c(4, 1),
  sense = c("<=", ">="),
  vtype = c("B", "B", "B"),
  A = A
)
