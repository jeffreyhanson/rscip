#' @include internal.R scip_status_message.R
NULL

#' Solve a mixed integer problem with \emph{SCIP}
#'
#' \href{https://www.scipopt.org/}{\emph{SCIP}
#' (Solving Constraint Integer Programs)
#' is an open-source mixed integer programming
#' solver (Bestuzheva *et al.* 2021).
#' By leveraging the \emph{SCIP} software, this function can be used to generate
#' solutions to optimization problems.
#'
#' @param obj `numeric` vector of coefficients to specify the
#' objective function. Note that arguments should have one value per decision
#' variable (i.e., column in `A`).
#'
#' @param lb `numeric` vector of lower bounds for decision
#' variables.
#' Note that arguments should have one value per decision variable
#' (i.e. column in `A`).
#'
#' @param ub `numeric` vector of upper bounds for decision variables.
#' Note that arguments should have one value per decision variable
#' (i.e., column in `A`).
#'
#' @param vtype `character` vector values that indicate the variable
#' types for each decision variable.
#' Available options include
#' `"B"` for binary variables,
#' `"C"` for continuous variables, and
#' `"I"` for integer variables.
#' Note that arguments should have one value per decision variable
#' (i.e., column in `A`).
#'
#' @param A matrix (i.e. `matrix` or \code{\link{Matrix-class}}) of
#' constraint coefficients. Here, each column corresponds to a different
#' decision variable, and each row corresponds to a different constraint.
#' To improve performance, it is recommended to specify the matrix using
#' a sparse format (see \code{\link[Matrix]{sparseMatrix}}).
#'
#' @param sense `character` vector indicating the sense values for the
#' constraints.
#' Available options include `">="`, `"<="` and `"="`.
#' Note that arguments should have one value per constraint
#' (i.e., row in `A`).
#'
#' @param modelsense `character` value indicating the model sense.
#' Available options include `"max`" to maximize the objective function,
#' or `"min"` to minimize the objective function.
#' Defaults to `"min"`.
#'
#' @param gap `numeric` optimality gap.
#' For example, a value of 0.05 means that solutions must be within
#' 5% of optimality.
#' Defaults to 0 to produce optimal solutions.
#'
#' @param threads `numeric` number of threads to use for optimization.
#' Defaults to 1.
#'
#' @param presolve `logical` should presolve routines be applied to
#' before attempting to solve the problem?
#' Defaults to `TRUE`.
#'
#' @param time_limit `numeric` maximum amount of time (seconds) permitted for
#' completing the optimization process.
#' Defaults to 1e+20.
#'
#' @param first_feasible `logical` should the optimization process stop
#' after finding a feasible solution? This is useful for verifying the
#' feasibility of an optimization process. Note that if `TRUE`, then
#' the returned solution may not meet the optimality gap (per `gap`).
#' Defaults to `FALSE`.
#'
#' @param verbose `logical` should progress be displayed during optimization?
#' Defaults to `TRUE`.
#'
#' @return A `list` containing the solution and additional information.
#' Specifically, it contains the following elements:
#'
#' \describe{
#'
#' \item{x}{\code{numeric} values of the decision variables
#' in the solution.
#'
#' \item{objval}{\code{numeric} objective value of the solution.}
#'
#' \item{status}{\code{character} description of the optimization process
#' when it finished. See the Sovler Status section for more information.
#'
#' }
#'
#' @section Solver Status:
#' The status of the SCIP solver indicates the stopping criteria for the
#' optimization process. This information can be helpful for interpreting
#' the solution. For example, if the status indicates that the stopping
#' criteria was due to a time limit, then this would suggest that the
#' solution does not meet the gap. Alternatively, if the status
#' indicates that the stopping criteria was due to the solver finding
#' an optimal solution, then this would indicate that the solution is optimal.
#' All the solver statuses are described below.
#' \describe{
#'
#' \item{SCIP_STATUS_UNKNOWN}{
#' The solving status is not yet known.
#' }
#'
#' \item{SCIP_STATUS_USERINTERRUPT}{
#' The user interrupted the solving process (by pressing CTRL-C).
#' }
#'
#' \item{SCIP_STATUS_NODELIMIT}{
#' The solving process was interrupted because the node limit was reached.
#' }
#'
#' \item{SCIP_STATUS_TOTALNODELIMIT}{
#' The solving process was interrupted because the total node limit was reached
#' (including restarts).
#' }
#'
#' \item{SCIP_STATUS_STALLNODELIMIT}{
#' The solving process was interrupted because the stalling node limit was
#' reached (no improvement with regard to the primal bound).
#' }
#'
#' \item{SCIP_STATUS_TIMELIMIT}{
#' The solving process was interrupted because the time limit was reached.
#' }
#'
#' \item{SCIP_STATUS_MEMLIMIT}{
#' The solving process was interrupted because the memory limit was reached.
#' }
#'
#' \item{SCIP_STATUS_GAPLIMIT}{
#' The solving process was interrupted because the gap limit was reached.
#' }
#'
#' \item{SCIP_STATUS_SOLLIMIT}{
#' The solving process was interrupted because the solution limit was reached.
#' }
#'
#'
#' \item{SCIP_STATUS_BESTSOLLIMIT}{
#' The solving process was interrupted because the solution improvement limit
#' was reached.
#' }
#'
#' \item{SCIP_STATUS_RESTARTLIMIT}{
#' The solving process was interrupted because the restart limit was reached.
#' }
#'
#' \item{SCIP_STATUS_OPTIMAL}{
#' The problem was solved to optimality, an optimal solution is available.
#' }
#'
#' \item{SCIP_STATUS_INFEASIBLE}{
#' The problem was proven to be infeasible.
#' }
#'
#' \item{SCIP_STATUS_UNBOUNDED}{
#' The problem was proven to be unbounded.
#' }
#'
#' \item{SCIP_STATUS_INFORUNBD}{
#' The problem was proven to be either infeasible or unbounded.
#' }
#'
#' \item{SCIP_STATUS_TERMINATE}{
#' Status if the process received a SIGTERM signal.
#' }
#'
#' }
#'
#' @references
#' Bestuzheva K., Besançon M., Chen W-K, Chmiela A., Donkiewicz T., van
#' Doornmalen J., Eifler L., Gaul O., Gamrath G., Gleixner A., Gottwald L.,
#' Graczyk C.,  Halbig K., Hoen A., Hojny C., van der Hulst R., Koch T.,
#' Lübbecke M., Maher S.J., Matter F., Mühmer E., Müller B., Pfetsch M.E.,
#' Rehfeldt D., Schlein S., Schlösser F., Serrano F., Shinano Y., Sofranac B.,
#' Turner M, Vigerske S.,  Wegscheider F., Wellner P., Weninger D., and
#' Witzig J. (2021) The SCIP Optimization Suite 8.0. Available at Optimization
#' Online and as ZIB-Report 21-41. <http://www.optimization-online.org/DB_HTML/2021/12/8728.html>

#' @examples
#' \dontrun{
#' # Mathematically define a mixed integer programming problem
#' ## maximize:
#' ##   1 * x + 2 * y + 0.5 * z (eqn 1a)
#' ## subject to:
#' ##   x + y <= 1              (eqn 1b)
#' ##   3 * x + 4 * z >= 5      (eqn 1c)
#' ##   z = 4                   (eqn 1d)
#' ##  x <= 10                  (eqn 1e)
#' ##  y <= 11                  (eqn 1f)
#' ##  z <= 13                  (eqn 1g)
#' ##  x, y, z is integer       (eqn 1h)
#'
#' # Create variables to represent this problem
#' ### define objective function (eqn 1a)
#' obj <- c(1, 2, 0.5)
#'
#' ## define constraint matrix (eqns 1c--1d)
#' A <- matrix(c(1, 1, 0, 3, 0, 4, 0, 0, 1), byrow = TRUE, nrow = 3)
#' print(A)
#'
#' ## note that we could also define the constraint matrix using a
#' ## sparse format to reduce memory consumption
#' ## (though not needed for such a small problem)
#' library(Matrix)
#' A_sp <- sparseMatrix(
#'   i = c(1, 2, 1, 2, 3),
#'   j = c(1, 1, 2, 3, 3),
#'   x = c(1, 3, 1, 4, 1))
#' print(A_sp)
#'
#' ## define sense for constraints (eqns 1c--1d)
#' sense <- c("=", "<=", "<=")
#'
#' ## define upper and lower bounds for decision variables (eqns 1e--1g)
#' lb <- c(0, 0, 0)
#' ub <- c(10, 11, 13)
#'
#' ## specify decision variable types (eqn 1h)
#' vtype <- c("I", "I", "I")
#'
#' # Generate solution
#' ## run solver (with default settings)
#' result <- scip_solve(
#'   obj = obj, lb = lb, ub = ub,
#'   A = A, sense = sense, vtype = vtype,
#'   modelsense = "max"
#' )
#'
#' ## print result
#' print(result)
#'
#' # Generate a solution with customized settings
#' ## specify that only a single thread should be used,
#' ## we only need a solution within 20% of optimality,
#' ## and that we can only spend 2 seconds for optimization
#'
#' ## run solver (with customized settings)
#' result2 <- scip_solve(
#'   obj = obj, lb = lb, ub = ub,
#'   A = A, sense = sense, vtype = vtype,
#'   modelsense = "max",
#'   gap = 0.2, threads = 1, time_limit = 2
#' )
#'
#' ## print result
#' ## we can see that this result is exactly the same as the previous
#' ## result, so these customized settings did not really any influence.
#' ## this is because the optimization problem is incredibly simple
#' ## and so SCIP can find the optimal solution pretty much instantly
#' ## we would expect such customized settings to have an influence
#' ## when solving more complex problems
#' print(result2)
#' }
#'
#' @export
scip_solve <- function(obj,
                       lb,
                       ub,
                       vtype,
                       A,
                       sense,
                       rhs,
                       modelsense = "max",
                       gap = 0,
                       threads = 1,
                       presolve = TRUE,
                       time_limit = 1e+20,
                       first_feasible = FALSE,
                       verbose = TRUE) {
  # assert arguments are valid and prepare data
  ## argument classes
  assertthat::assert_that(
    ### obj
    is.numeric(obj),
    assertthat::noNA(obj),
    ### lb
    is.numeric(lb),
    assertthat::noNA(lb),
    ### ub
    is.numeric(ub),
    assertthat::noNA(ub),
    ### vtype
    is.character(vtype),
    assertthat::noNA(vtype),
    ### A
    inherits(A, c("matrix", "Matrix")),
    ### sense
    is.character(sense),
    assertthat::noNA(sense),
    ### rhs
    is.numeric(rhs),
    assertthat::noNA(rhs),
    ### modelsense
    assertthat::is.string(modelsense),
    assertthat::noNA(modelsense),
    ### gap
    assertthat::is.number(gap),
    assertthat::noNA(gap),
    ### threads
    assertthat::is.count(threads),
    assertthat::noNA(threads),
    ### presolve
    assertthat::is.flag(presolve),
    assertthat::noNA(presolve),
    ### time_limit
    assertthat::is.count(time_limit),
    assertthat::noNA(time_limit),
    time_limit <= 1e20,
    ### first_feasible
    assertthat::is.flag(first_feasible),
    assertthat::noNA(first_feasible)
  )
  ## coerce A to sparse matrix
  if (!inherits(A, "dgTMatrix")) {
    A <- as_Matrix(A, "dgTMatrix")
  }
  ## check for missing values
  assertthat::assert_that(
    assertthat::noNA(A@x),
    msg = "`A` must not contain missing (NA) values"
  )
  # finite values
  assertthat::assert_that(
    all(is.finite(A@x)),
    msg = "`A` must not contain non-finite (Inf) values"
  )
  ## dimensionality
  assertthat::assert_that(
    length(obj) == ncol(A),
    length(lb) == ncol(A),
    length(ub) == ncol(A),
    length(vtype) == ncol(A),
    length(sense) == nrow(A)
  )
  ## feasible lower and upper bounds for variables
  assertthat::assert_that(all(ub >= lb))
  ## valid sense values
  assertthat::assert_that(
    all(sense %in% c(">=", "<=", "=")),
    msg = "`sense` must contain \">=\", \"<=\", or \"=\" values"
  )

  # extract constraint matrix in row-major format
  idx <- order(A@i)
  A_i <- A@i[idx]
  A_j <- A@j[idx]
  A_x <- A@x[idx]
  rm(A, idx)

  # run scip solver
  result <- rcpp_scip_solve(
    modelsense = modelsense,
    obj = obj,
    lb = lb,
    ub = ub,
    vtype = vtype,
    rhs = rhs,
    sense = sense,
    A_i = A_i,
    A_j = A_j,
    A_x = A_x,
    gap = gap,
    time_limit = time_limit,
    first_feasible = first_feasible,
    presolve = presolve,
    threads = threads,
    verbose = verbose,
    display_width = getOption("width")
  )

  # convert status integer to status message
  result$status <- scip_status_message(result$status)

  # ensure objval and x contain NULL values for infeasible/unbounded problems
  invalid_status <- c(
    "SCIP_STATUS_UNKNOWN",
    "SCIP_STATUS_INFEASIBLE",
    "SCIP_STATUS_UNBOUNDED",
    "SCIP_STATUS_INFORUNBD"
  )
  if (result$status %in% invalid_status) {
    result[1] <- list(NULL)
    result[2] <- list(NULL)
  }

  # return result
  result
}
