all: clean contrib initc data docs test check

clean:
	rm -rf man/*

initc:
	R --slave -e "Rcpp::compileAttributes()"
	R --slave -e "tools::package_native_routine_registration_skeleton('.', 'src/init.c', character_only = FALSE)"

docs: man readme vigns site

data:
	Rscript --slave inst/scripts/builtin-data.R

man:
	R --slave -e "devtools::document()"

readme:
	R --slave -e "rmarkdown::render('README.Rmd')"

contrib:
	R --slave -e "rmarkdown::render('CONTRIBUTING.Rmd')"

vigns:
	rm -f vignettes/*.html
	rm -f .build.timestamp
	rm -f vignettes/*.R
	rm -f doc/*.html
	rm -f doc/*.Rmd
	rm -f inst/doc/*.html
	rm -f inst/doc/*.Rmd
	R --slave -e "options(rmarkdown.html_vignette.check_title = FALSE);devtools::build_vignettes()"
	cp -R doc inst/
	touch inst/doc/.gitkeep

purl_vigns:
	R --slave -e "lapply(dir('vignettes', '^.*\\\\.Rmd$$'), function(x) knitr::purl(file.path('vignettes', x), gsub('.Rmd', '.R', x, fixed = TRUE)))"
	rm -f Rplots.pdf

purl_readme:
	R --slave -e "knitr::purl('README.Rmd', 'README.R')"
	rm -f Rplots.pdf

check_vigns:
	R --slave -e "f <- sapply(dir('vignettes', '^.*\\\\.Rmd$$'), function(x) {p <- file.path(tempdir(), gsub('.Rmd', '.R', x, fixed = TRUE)); knitr::purl(file.path('vignettes', x), p); p}); for (i in f) {message('\n########################################\nstarting ', basename(i), '\n########################################\n'); source(i)}"
	rm -f Rplots.pdf

quicksite:
	R --slave -e "options(rmarkdown.html_vignette.check_title = FALSE);pkgdown::build_site(run_dont_run = TRUE, lazy = TRUE)"
	cp -R doc inst/

site:
	R --slave -e "pkgdown::clean_site()"
	R --slave -e "options(rmarkdown.html_vignette.check_title = FALSE);pkgdown::build_site(run_dont_run = TRUE, lazy = FALSE)"
	cp -R doc inst/

test:
	R --slave -e "devtools::test()" > test.log 2>&1
	rm -f tests/testthat/Rplots.pdf

quickcheck:
	echo "\n===== R CMD CHECK =====\n" > check.log 2>&1
	R --slave -e "devtools::check(build_args = '--no-build-vignettes', args = '--no-build-vignettes', run_dont_test = TRUE, vignettes = FALSE)" >> check.log 2>&1
	cp -R doc inst/
	touch inst/doc/.gitkeep

check:
	echo "\n===== R CMD CHECK =====\n" > check.log 2>&1
	R --slave -e "devtools::check(remote = FALSE, build_args = '--no-build-vignettes', args = '--no-build-vignettes', run_dont_test = TRUE, vignettes = FALSE)" >> check.log 2>&1
	cp -R doc inst/
	touch inst/doc/.gitkeep

gpcheck:
	echo "\n===== GOOD PRACTICE =====\n" > gp.log 2>&1
	R --slave -e "goodpractice::gp('.')" >> gp.log 2>&1
	cp -R doc inst/
	touch inst/doc/.gitkeep

checkascran:
	echo "\n===== R CMD CHECK =====\n" > check.log 2>&1
	R --slave -e "devtools::check(remote = TRUE, build_args = '--no-build-vignettes', args = '--no-build-vignettes', vignettes = FALSE)" >> check.log 2>&1
	cp -R doc inst/
	touch inst/doc/.gitkeep

wbcheck:
	R --slave -e "devtools::check_win_devel()"
	cp -R doc inst/

jhwbcheck:
	R --slave -e "devtools::check_win_devel(email = 'jeffrey.hanson@uqconnect.edu.au')"
	cp -R doc inst/

solarischeck:
	R --slave -e "rhub::check(platform = 'solaris-x86-patched', email = 'jeffrey.hanson@uqconnect.edu.au', show_status = FALSE)"

asancheck:
	R --slave -e "rhub::check(platform = 'linux-x86_64-rocker-gcc-san', email = 'jeffrey.hanson@uqconnect.edu.au', show_status = FALSE)"

spellcheck:
	R --slave -e "devtools::document();devtools::spell_check()"

urlcheck:
	R --slave -e "devtools::document();urlchecker::url_check()"

build:
	R --slave -e "devtools::build()"
	cp -R doc inst/
	touch inst/doc/.gitkeep

install:
	R --slave -e "devtools::install_local(force = TRUE)"

examples:
	R --slave -e "devtools::run_examples(run_donttest = TRUE, run_dontrun = TRUE);warnings()" > examples.log 2>&1
	rm -f Rplots.pdf

examples_cran:
	R --slave -e "devtools::run_examples();warnings()" > examples.log 2>&1
	rm -f Rplots.pdf

.PHONY: initc clean data docs readme contrib site test check checkwb build install man spellcheck examples purl_vigns check_vigns urlcheck
