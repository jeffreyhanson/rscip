
<!-- README.md is generated from README.Rmd. Please edit that file -->

# rscip: Interface to SCIP

<!-- badges: start -->

[![lifecycle](https://img.shields.io/badge/Lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html)
[![R-CMD-check-Ubuntu](https://img.shields.io/github/actions/workflow/status/jeffreyhanson/rscip/R-CMD-check-ubuntu.yaml?branch=master&label=Ubuntu)](https://github.com/jeffreyhanson/rscip/actions)
[![R-CMD-check-Windows](https://img.shields.io/github/actions/workflow/status/jeffreyhanson/rscip/R-CMD-check-windows.yaml?branch=master&label=Windows)](https://github.com/jeffreyhanson/rscip/actions)
[![R-CMD-check-macOS](https://img.shields.io/github/actions/workflow/status/jeffreyhanson/rscip/R-CMD-check-macos.yaml?branch=master&label=macOS)](https://github.com/jeffreyhanson/rscip/actions)
[![R-CMD-check-fedora](https://img.shields.io/github/actions/workflow/status/jeffreyhanson/rscip/R-CMD-check-fedora.yaml?branch=master&label=Fedora)](https://github.com/jeffreyhanson/rscip/actions)
[![Documentation](https://img.shields.io/github/actions/workflow/status/jeffreyhanson/rscip/documentation.yaml?branch=master&label=Documentation)](https://github.com/jeffreyhanson/rscip/actions)
[![Coverage
Status](https://img.shields.io/codecov/c/github/jeffreyhanson/rscip?label=Coverage)](https://app.codecov.io/gh/jeffreyhanson/rscip/branch/master)
[![CRAN\_Status\_Badge](http://www.r-pkg.org/badges/version/rscip)](https://CRAN.R-project.org/package=rscip)

<!-- badges: end -->

**Please understand that this package is still in early development. It
will probably not work on your computer yet.**

The *rscip* package provides an interface to the [*SCIP* (Solving
Constraint Integer Programs)](https://www.scipopt.org/) solver.
Specifically, *SCIP* is an open-source optimization solver that can
solve mixed integer programming (MILP) problems. By interfacing with the
*SCIP* solver, the *rscip* package can be used to generate optimal
solutions to optimization problems. Although *SCIP* can also solve mixed
integer non-linear programming (MINLP) problems, this functionality is
not provided by the *rscip* package.

## Installation

The package is not available on [The Comprehensive R Archive
Network](https://cran.r-project.org/). To install this package, please
use the following *R* code to install it from the [source code
repository on GitHub](https://github.com/jeffreyhanson/rscip).

``` r
if (!require(remotes)) install.packages("remotes")
remotes::install_github("jeffreyhanson/rscip")
```

## Usage

Here we will provide a brief example showing how the package can be used
to solve an optimization problem.

``` r
# load package
library(rscip)

# define optimization problem and solve it
#' # Mathematically define a mixed integer programming problem
#' ## maximize:
#' ##   1 * x + 2 * y + 0.5 * z
#' ## subject to:
#' ##   x + y <= 1
#' ##   3 * x + 4 * z >= 5
#' ##   z = 4
#' ##  x <= 10
#' ##  y <= 11
#' ##  z <= 13
#' ##  x, y, z is integer
result <- scip_solve(
  obj = c(1, 2, 0.5),
  lb = c(0, 0, 0),
  ub = c(10, 11, 13),
  vtype = c("I", "I", "I"),
  A = matrix(c(1, 1, 0, 3, 0, 4, 0, 0, 1), byrow = TRUE, nrow = 3),
  sense = c("<=", ">=", "="),
  rhs = c(1, 5, 4),
  modelsense = "max"
)

# print solution values
print(result$x)
#> [1] 0 1 4

# print objective value
print(result$objval)
#> [1] 4

# print solver status
print(result$status)
#> [1] "SCIP_STATUS_OPTIMAL"
```

## Citation

Please cite the [*SCIP* solver](https://www.scipopt.org/) when using
this *R* package in publications.

    To cite the rscip package in publications, please use:

      Bestuzheva K, Besançon M, Chen W, Chmiela A, Donkiewicz T, van
      Doornmalen J, Eifler L, Gaul O, Gamrath G, Gleixner A, Gottwald L,
      Graczyk C, Halbig K, Hoen A, Hojny C, van der Hulst R, Koch T,
      L"ubbecke M, Maher SJ, Matter F, M"uhmer E, M"uller B, Pfetsch ME,
      Rehfeldt D, Schlein S, Schl"osser F, Serrano F, Shinano Y, Sofranac
      B, Turner M, Vigerske S, Wegscheider F, Wellner P, Weninger D, Witzig
      J (2021). "The SCIP Optimization Suite 8.0." Optimization Online.
      <http://www.optimization-online.org/DB_HTML/2021/12/8728.html>.

    A BibTeX entry for LaTeX users is

      @TechReport{,
        title = {The SCIP Optimization Suite 8.0},
        author = {Ksenia Bestuzheva and Mathieu Besan{\c{c}}on and Wei-Kun Chen and Antonia Chmiela and Tim Donkiewicz and Jasper {van Doornmalen} and Leon Eifler and Oliver Gaul and Gerald Gamrath and Ambros Gleixner and Leona Gottwald and Christoph Graczyk and Katrin Halbig and Alexander Hoen and Christopher Hojny and Rolf {van der Hulst} and Thorsten Koch and Marco L{"u}bbecke and Stephen J Maher and Frederic Matter and Erik M{"u}hmer and Benjamin M{"u}ller and Marc E Pfetsch and Daniel Rehfeldt and Steffan Schlein and Franziska Schl{"o}sser and Felipe Serrano and Yuji Shinano and Boro Sofranac and Mark Turner and Stefan Vigerske and Fabian Wegscheider and Philipp Wellner and Dieter Weninger and Jakob Witzig},
        institution = {Optimization Online},
        year = {2021},
        url = {http://www.optimization-online.org/DB_HTML/2021/12/8728.html},
      }

    For package version, use "packageVersion('rscip')"
