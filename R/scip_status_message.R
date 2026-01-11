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
    "1" = "SCIP_STATUS_OPTIMAL",
    "2" = "SCIP_STATUS_INFEASIBLE",
    "3" = "SCIP_STATUS_UNBOUNDED",
    "4" = "SCIP_STATUS_INFORUNBD",
    "10" = "SCIP_STATUS_USERINTERRUPT",
    "11" = "SCIP_STATUS_TERMINATE",
    "20" = "SCIP_STATUS_NODELIMIT",
    "21" = "SCIP_STATUS_TOTALNODELIMIT",
    "22" = "SCIP_STATUS_STALLNODELIMIT",
    "23" = "SCIP_STATUS_TIMELIMIT",
    "24" = "SCIP_STATUS_MEMLIMIT",
    "25" = "SCIP_STATUS_GAPLIMIT",
    "26" = "SCIP_STATUS_PRIMALLIMIT",
    "27" = "SCIP_STATUS_DUALLIMIT",
    "28" = "SCIP_STATUS_SOLLIMIT",
    "29" = "SCIP_STATUS_BESTSOLLIMIT",
    "30" = "SCIP_STATUS_RESTARTLIMIT",
    "NOT RECOGNIZED"
  )
}
