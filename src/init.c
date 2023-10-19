#include <R.h>
#include <Rinternals.h>
#include <stdlib.h> // for NULL
#include <R_ext/Rdynload.h>

/* FIXME: 
   Check these declarations against the C/Fortran source code.
*/

/* .Call calls */
extern SEXP _rscip_rcpp_scip_solve(void *, void *, void *, void *, void *, void *, void *, void *, void *, void *, void *, void *, void *, void *, void *, void *, void *);
extern SEXP _rscip_rcpp_scip_version(void);

static const R_CallMethodDef CallEntries[] = {
    {"_rscip_rcpp_scip_solve",   (DL_FUNC) &_rscip_rcpp_scip_solve,   17},
    {"_rscip_rcpp_scip_version", (DL_FUNC) &_rscip_rcpp_scip_version,  0},
    {NULL, NULL, 0}
};

void R_init_rscip(DllInfo *dll)
{
    R_registerRoutines(dll, NULL, CallEntries, NULL, NULL);
    R_useDynamicSymbols(dll, FALSE);
}
