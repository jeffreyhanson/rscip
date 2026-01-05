#pragma once
#ifndef PACKAGE_H
#define PACKAGE_H

/* Set plugins */
// [[Rcpp::plugins(cpp11)]]

/* Load header files */
// Rcpp library
#include <Rcpp.h>
/// standard libraries
#include <vector>
#include <string>
#include <math.h>
// SCIP library
#include <scip/scip.h>
#include <scip/scipdefplugins.h>
#ifdef __cplusplus
extern "C" {
#endif
#include <tpi/tpi.h>
#ifdef __cplusplus
}
#endif

/* Import namespaces */
using namespace Rcpp;

#endif
