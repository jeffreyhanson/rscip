#' @include internal.R
NULL

#' \emph{SCIP} version
#'
#' Get the version number of the \emph{SCIP} software installed.
#'
#' @return A `character` value containing the version number.
#'
#' @examples
#' # get version number
#' scip_version()
#'
#' @export
scip_version <- function() {
  rcpp_scip_version()
}
