#' @include internal.R
NULL

#' SCIP status message
#'
#' Get the SCIP status message associated with a SCIP status code.
#'
#' @param x `numeric` status code.
#'
#' @return A `character` message.
#'
#' @noRd
scip_status_message <- function(x) {
  if (is.null(x)) return("NOT RECOGNIZED")
  switch(
    as.character(x),
    "0" = "SCIP_STATUS_UNKNOWN",
    "1" = "SCIP_STATUS_USERINTERRUPT",
    "2" = "SCIP_STATUS_NODELIMIT",
    "3" = "SCIP_STATUS_TOTALNODELIMIT",
    "4" = "SCIP_STATUS_STALLNODELIMIT",
    "5" = "SCIP_STATUS_TIMELIMIT",
    "6" = "SCIP_STATUS_MEMLIMIT",
    "7" = "SCIP_STATUS_GAPLIMIT",
    "8" = "SCIP_STATUS_SOLLIMIT",
    "9" = "SCIP_STATUS_BESTSOLLIMIT",
    "10" = "SCIP_STATUS_RESTARTLIMIT",
    "11" = "SCIP_STATUS_OPTIMAL",
    "12" = "SCIP_STATUS_INFEASIBLE",
    "13" = "SCIP_STATUS_UNBOUNDED",
    "14" = "SCIP_STATUS_INFORUNBD",
    "15" = "SCIP_STATUS_TERMINATE",
    "NOT RECOGNIZED"
  )
}
