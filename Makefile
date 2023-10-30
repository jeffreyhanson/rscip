all: clean contrib initc data docs test check

clean:
	rm -rf man/*

initc:
	R --slave -e "Rcpp::compileAttributes()"
	R --slave -e "tools::package_native_routine_registration_skeleton('.', 'src/init.c', character_only = FALSE)"

docs: man readme site

man:
	R --slave -e "devtools::document()"

readme:
	R --slave -e "rmarkdown::render('README.Rmd')"

contrib:
	R --slave -e "rmarkdown::render('CONTRIBUTING.Rmd')"

purl_readme:
	R --slave -e "knitr::purl('README.Rmd', 'README.R')"
	rm -f Rplots.pdf

quicksite:
	R --slave -e "options(rmarkdown.html_vignette.check_title = FALSE);pkgdown::build_site(run_dont_run = TRUE, lazy = TRUE)"

site:
	R --slave -e "pkgdown::clean_site()"
	R --slave -e "options(rmarkdown.html_vignette.check_title = FALSE);pkgdown::build_site(run_dont_run = TRUE, lazy = FALSE)"

test:
	R --slave -e "devtools::test()" > test.log 2>&1
	rm -f tests/testthat/Rplots.pdf

quickcheck:
	echo "\n===== R CMD CHECK =====\n" > check.log 2>&1
	R --slave -e "devtools::check(build_args = '--no-build-vignettes', args = '--no-build-vignettes', run_dont_test = TRUE, vignettes = FALSE)" >> check.log 2>&1

check:
	echo "\n===== R CMD CHECK =====\n" > check.log 2>&1
	R --slave -e "devtools::check(remote = FALSE, build_args = '--no-build-vignettes', args = '--no-build-vignettes', run_dont_test = TRUE, vignettes = FALSE)" >> check.log 2>&1

gpcheck:
	echo "\n===== GOOD PRACTICE =====\n" > gp.log 2>&1
	R --slave -e "goodpractice::gp('.')" >> gp.log 2>&1

checkascran:
	echo "\n===== R CMD CHECK =====\n" > check.log 2>&1
	R --slave -e "devtools::check(remote = TRUE, build_args = '--no-build-vignettes', args = '--no-build-vignettes', vignettes = FALSE)" >> check.log 2>&1

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

install:
	R --slave -e "devtools::install_local(force = TRUE)"

examples:
	R --slave -e "devtools::run_examples(run_donttest = TRUE, run_dontrun = TRUE);warnings()" > examples.log 2>&1
	rm -f Rplots.pdf

examples_cran:
	R --slave -e "devtools::run_examples();warnings()" > examples.log 2>&1
	rm -f Rplots.pdf

.PHONY: initc clean data docs readme contrib site test check checkwb build install man spellcheck examples check_vigns urlcheck
