#include "package.h"

// [[Rcpp::export]]
Rcpp::CharacterVector rcpp_scip_version(
) {
  int major = SCIPmajorVersion();
  int minor = SCIPminorVersion();
  int tech = SCIPtechVersion();
  std::string version =
    std::to_string(major) + "." +
    std::to_string(minor) + "." +
    std::to_string(tech);
  return Rcpp::wrap(version);
}
