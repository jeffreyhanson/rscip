#include <R_ext/Error.h>
#include <R_ext/Print.h>

void SCIP_exit_replacement(int c) {
    Rf_error("SCIP exited with code %d", c);
}

void SCIP_abort_replacement(void) {
    Rf_error("SCIP aborted");
}
