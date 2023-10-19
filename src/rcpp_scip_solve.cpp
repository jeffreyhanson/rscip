#include "package.h"

// [[Rcpp::export]]
Rcpp::List rcpp_scip_solve(
  Rcpp::CharacterVector &modelsense,
  Rcpp::NumericVector &obj,
  Rcpp::NumericVector &lb,
  Rcpp::NumericVector &ub,
  Rcpp::CharacterVector &vtype,
  Rcpp::NumericVector &rhs,
  Rcpp::CharacterVector &sense,
  Rcpp::NumericVector &A_i, // constraint matrix rows
  Rcpp::NumericVector &A_j, // constraint matrix columns
  Rcpp::NumericVector &A_x, // constraint matrix coefficients
  double gap = 0,
  double time_limit = 1e+20,
  bool first_feasible = false,
  bool presolve = true,
  std::size_t threads = 1,
  bool verbose = true,
  std::size_t display_width = 143
) {

  // Initialization
  /// initialize scip environment
  SCIP *scip = nullptr;
  SCIP_CALL(SCIPcreate(&scip));
  SCIP_CALL(SCIPincludeDefaultPlugins(scip));

  /// compute constants
  const std::size_t n_vars = obj.size();
  const std::size_t n_consts = rhs.size();

  // Build problem
  /// initialize problem
  SCIP_CALL(SCIPcreateProbBasic(scip, "PROBLEM"));

  /// set model sense
  if (modelsense[0] == "min") {
    SCIP_CALL(SCIPsetObjsense(scip, SCIP_OBJSENSE_MINIMIZE));
  } else if (modelsense[0] == "max") {
    SCIP_CALL(SCIPsetObjsense(scip, SCIP_OBJSENSE_MAXIMIZE));
  } else {
    Rcpp::stop("`modelsense` not recognized.");
  }

  /// add variables
  SCIP_Vartype var_type;
  std::vector<SCIP_VAR*> vars(n_vars);
  for (std::size_t i = 0; i < n_vars; ++i) {
    /// declare variable
    SCIP_VAR *var = nullptr;
    /// determine variable type
    if (vtype[i] == "C") {
      var_type = SCIP_VARTYPE_CONTINUOUS;
    } else if (vtype[i] == "B") {
      var_type = SCIP_VARTYPE_BINARY;
    } else if (vtype[i] == "I") {
      var_type = SCIP_VARTYPE_INTEGER;
    }
    /// add variable to problem
    SCIP_CALL(
      SCIPcreateVarBasic(
        scip,
        &var,
        NULL,
        lb[i],
        ub[i],
        obj[i],
        var_type
      )
    );
    SCIP_CALL(SCIPaddVar(scip, var));
    /// store variable
    vars[i] = var;
  }

  /// add constraints
  std::vector<SCIP_Real> A_row_coefs(n_vars);
  std::vector<SCIP_VAR*> A_row_vars(n_vars);
  std::vector<SCIP_CONS*> constraints(n_consts);
  SCIP_Real const_rhs;
  SCIP_Real const_lhs;
  std::size_t counter = 0; // counter for A_i, A_j, A_x
  std::size_t k; // counter for non-zero values in i'th constraint
  for (std::size_t i = 0; i < n_consts; ++i) {
    /// prepare vectors with contraint data
    ////
    //// here we loop over elments of A_i/A_j/A_x and use them
    //// to identify variables and coefficients for the i'th constraint
    ////
    //// N.B. we assume that elements in A_i are sorted in increasing order
    //// so that we don't have to loop over all A_i/A_j/A_x values for
    //// every constraint
    k = 0;
    for (; k < n_vars; ++k, ++counter) {
      if (A_i[counter] != i) break;
      A_row_coefs[k] = A_x[counter];
      A_row_vars[k] = vars[A_j[counter]];
    }
    /// prepare rhs and lhs for constraint
    if (sense[i] == ">=") {
      const_lhs = rhs[i];
      const_rhs = SCIPinfinity(scip);
    } else if (sense[i] == "<=") {
      const_lhs = -SCIPinfinity(scip);
      const_rhs = rhs[i];
    } else if (sense[i] == "=") {
      const_lhs = rhs[i];
      const_rhs = rhs[i];
    }
    /// add constraints to problem
    SCIP_CONS *cons = nullptr;
    SCIP_CALL(
      SCIPcreateConsBasicLinear(
        scip,
        &cons,
        std::to_string(i).c_str(),
        k,
        A_row_vars.data(),
        A_row_coefs.data(),
        const_lhs,
        const_rhs
      )
    );
    SCIP_CALL(SCIPaddCons(scip, cons));
    constraints[i] = cons;

  }

  /// free constraints
  for (std::size_t i = 0; i < n_consts; ++i) {
    SCIP_CALL(SCIPreleaseCons(scip, &constraints[i]));
  }

  // Set parameters
  SCIPsetRealParam(scip, "limits/gap", gap);
  SCIPsetRealParam(scip, "limits/time", time_limit);
  if (first_feasible) {
    SCIPsetIntParam(scip, "limits/solutions", 1);
  }
  if (!verbose) {
    SCIPsetIntParam(scip, "display/verblevel", 0);
  }
  if (threads > 1) {
    SCIPsetIntParam(scip, "parallel/maxnthreads", threads);
  }
  if (!presolve) {
    SCIPsetIntParam(scip, "presolving/milp/maxrounds", 0);
    SCIPsetIntParam(scip, "presolving/trivial/maxrounds", 0);
    SCIPsetIntParam(scip, "presolving/inttobinary/maxrounds", 0);
    SCIPsetIntParam(scip, "presolving/gateextraction/maxrounds", 0);
    SCIPsetIntParam(scip, "presolving/dualcomp/maxrounds", 0);
    SCIPsetIntParam(scip, "presolving/domcol/maxrounds", 0);
    SCIPsetIntParam(scip, "presolving/implics/maxrounds", 0);
    SCIPsetIntParam(scip, "presolving/sparsify/maxrounds", 0);
    SCIPsetIntParam(scip, "presolving/dualsparsify/maxrounds", 0);
    SCIPsetIntParam(scip, "propagating/dualfix/maxprerounds", 0);
    SCIPsetIntParam(scip, "propagating/genvbounds/maxprerounds", 0);
    SCIPsetIntParam(scip, "propagating/obbt/maxprerounds", 0);
    SCIPsetIntParam(scip, "propagating/nlobbt/maxprerounds", 0);
    SCIPsetIntParam(scip, "propagating/probing/maxprerounds", 0);
    SCIPsetIntParam(scip, "propagating/pseudoobj/maxprerounds", 0);
    SCIPsetIntParam(scip, "propagating/redcost/maxprerounds", 0);
    SCIPsetIntParam(scip, "propagating/rootredcost/maxprerounds", 0);
    SCIPsetIntParam(scip, "propagating/symmetry/maxprerounds", 0);
    SCIPsetIntParam(scip, "propagating/vbounds/maxprerounds", 0);
    SCIPsetIntParam(scip, "constraints/cardinality/maxprerounds", 0);
    SCIPsetIntParam(scip, "constraints/SOS1/maxprerounds", 0);
    SCIPsetIntParam(scip, "constraints/SOS2/maxprerounds", 0);
    SCIPsetIntParam(scip, "constraints/varbound/maxprerounds", 0);
    SCIPsetIntParam(scip, "constraints/knapsack/maxprerounds", 0);
    SCIPsetIntParam(scip, "constraints/setppc/maxprerounds", 0);
    SCIPsetIntParam(scip, "constraints/linking/maxprerounds", 0);
    SCIPsetIntParam(scip, "constraints/or/maxprerounds", 0);
    SCIPsetIntParam(scip, "constraints/and/maxprerounds", 0);
    SCIPsetIntParam(scip, "constraints/xor/maxprerounds", 0);
    SCIPsetIntParam(scip, "constraints/conjunction/maxprerounds", 0);
    SCIPsetIntParam(scip, "constraints/disjunction/maxprerounds", 0);
    SCIPsetIntParam(scip, "constraints/linear/maxprerounds", 0);
    SCIPsetIntParam(scip, "constraints/orbisack/maxprerounds", 0);
    SCIPsetIntParam(scip, "constraints/orbitope/maxprerounds", 0);
    SCIPsetIntParam(scip, "constraints/symresack/maxprerounds", 0);
    SCIPsetIntParam(scip, "constraints/logicor/maxprerounds", 0);
    SCIPsetIntParam(scip, "constraints/bounddisjunction/maxprerounds", 0);
    SCIPsetIntParam(scip, "constraints/cumulative/maxprerounds", 0);
    SCIPsetIntParam(scip, "constraints/nonlinear/maxprerounds", 0);
    SCIPsetIntParam(scip, "constraints/pseudoboolean/maxprerounds", 0);
    SCIPsetIntParam(scip, "constraints/superindicator/maxprerounds", 0);
    SCIPsetIntParam(scip, "constraints/indicator/maxprerounds", 0);
    SCIPsetIntParam(scip, "constraints/components/maxprerounds", 0);
    SCIPsetIntParam(scip, "presolving/maxrestarts", 0);
    SCIPsetIntParam(scip, "presolving/maxrounds", 0);
    SCIPsetIntParam(scip, "propagating/maxrounds", 0);
    SCIPsetIntParam(scip, "propagating/maxroundsroot", 0);
  }

  // Solve problem
  if (threads > 1) {
    SCIP_CALL(SCIPsolveParallel(scip));
  } else {
    SCIP_CALL(SCIPsolve(scip));
  }
  SCIP_SOL* sol = SCIPgetBestSol(scip);

  // Extract results
  Rcpp::NumericVector x(n_vars);
  double obj_val = 0;
  for (std::size_t i = 0; i < n_vars; ++i) {
    x[i] = SCIPgetSolVal(scip, sol, vars[i]);
    obj_val += (x[i] * obj[i]);
  }
  std::size_t status = SCIPgetStatus(scip);

  // Clean up
  for (std::size_t i = 0; i < n_vars; ++i) {
    SCIP_CALL(SCIPreleaseVar(scip, &vars[i]));
  }
  SCIP_CALL(SCIPfree(&scip));

  // Exports
  return Rcpp::List::create(
    Rcpp::Named("objval") = Rcpp::wrap(obj_val),
    Rcpp::Named("x") = Rcpp::wrap(x),
    Rcpp::Named("status") = Rcpp::wrap(status)
  );
}
