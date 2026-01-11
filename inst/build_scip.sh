#!/bin/bash

#
# Set variables
#
if test -z "${MAKE}"; then MAKE=$(command -v make 2>/dev/null); fi
if test -z "${MAKE}" && test -x /Applications/Xcode.app/Contents/Developer/usr/bin/make; then MAKE=/Applications/Xcode.app/Contents/Developer/usr/bin/make; fi

if test -z "${CMAKE_EXE}"; then CMAKE_EXE=$(command -v cmake4 2>/dev/null); fi
if test -z "${CMAKE_EXE}"; then CMAKE_EXE=$(command -v cmake3 2>/dev/null); fi
if test -z "${CMAKE_EXE}"; then CMAKE_EXE=$(command -v cmake2 2>/dev/null); fi
if test -z "${CMAKE_EXE}"; then CMAKE_EXE=$(command -v cmake 2>/dev/null); fi
if test -z "${CMAKE_EXE}" && test -x /Applications/CMake.app/Contents/bin/cmake; then CMAKE_EXE=/Applications/CMake.app/Contents/bin/cmake; fi

if test -z "${CMAKE_EXE}"; then
    echo "Could not find 'cmake'!"
    exit 1
fi

: ${R_HOME=`R RHOME`}
if test -z "${R_HOME}"; then
    echo "'R_HOME' could not be found!"
    exit 1
fi

R_SCIP_PKG_HOME=`pwd`

CFLAGS=`"${R_HOME}/bin/R" CMD config CFLAGS`
CPPFLAGS=`"${R_HOME}/bin/R" CMD config --cppflags`
CXXFLAGS=`"${R_HOME}/bin/R" CMD config CXXFLAGS`

case "$(uname -s)" in
    MINGW*|MSYS*|CYGWIN*) 
        CFLAGS="${CFLAGS} -Wno-format -Wno-format-extra-args"
        CXXFLAGS="${CXXFLAGS} -Wno-format -Wno-format-extra-args"
        ;;
esac

export CC=`"${R_HOME}/bin/R" CMD config CC`
export CXX=`"${R_HOME}/bin/R" CMD config CXX`
export CFLAGS="${CFLAGS} ${CPPFLAGS} -DNDEBUG -DSCIP_R_PACKAGE -Dexit=SCIP_exit_replacement -Dabort=SCIP_abort_replacement"
export CPPFLAGS="${CPPFLAGS}"
export CXXFLAGS="${CXXFLAGS} ${CPPFLAGS} -DNDEBUG -DSCIP_R_PACKAGE -DSOPLEX_DISABLE_STDIO -Dabort=SCIP_abort_replacement"
LDFLAGS=`"${R_HOME}/bin/R" CMD config LDFLAGS`
export LDFLAGS="${LDFLAGS}"
SCIP_SRC_FILE=`find "${R_SCIP_PKG_HOME}/inst" -maxdepth 1 -name "scipoptsuite-*.tgz" | head -n 1`
if test -z "${SCIP_SRC_FILE}"; then
    echo "Could not find 'scipoptsuite-*.tgz' in inst/"
    exit 1
fi
SCIP_SRC_DIR_NAME=`basename "${SCIP_SRC_FILE}" .tgz`
SCIP_SRC_DIR="${R_SCIP_PKG_HOME}/inst/${SCIP_SRC_DIR_NAME}"
R_SCIP_BUILD_DIR="${SCIP_SRC_DIR}/build"
R_SCIP_LIB_DIR="${R_SCIP_PKG_HOME}/src/sciplib"

# Escape spaces for CMake install prefix
R_SCIP_LIB_DIR_ESC=$(printf '%s' "${R_SCIP_LIB_DIR}" | sed 's/ /\\ /g')

echo ""
echo "CMAKE VERSION: '`${CMAKE_EXE} --version | head -n 1`'"
echo "arch: '$(arch)'"
echo "CC: '${CC}'"
echo "CXX: '${CXX}'"
echo "CXXFLAGS: '${CXXFLAGS}'"
echo "CFLAGS: '${CFLAGS}'"
echo "CPPFLAGS: '${CPPFLAGS}'"
echo "LDFLAGS: '${LDFLAGS}'"
echo "SCIP_SRC_FILE: '${SCIP_SRC_FILE}'"
echo "SCIP_SRC_DIR: '${SCIP_SRC_DIR}'"
echo "R_SCIP_BUILD_DIR: '${R_SCIP_BUILD_DIR}'"
echo "R_SCIP_LIB_DIR: '${R_SCIP_LIB_DIR}'"
echo ""

# Extract SCIPOptSuite
rm -rf "${SCIP_SRC_DIR}"
tar -xzf "${SCIP_SRC_FILE}" -C "${R_SCIP_PKG_HOME}/inst"

# Patch CMake files to silence unused test dependencies
if command -v perl >/dev/null 2>&1; then
    if [ -f "${SCIP_SRC_DIR}/scip/CMakeLists.txt" ]; then
        perl -0pi -e 's|message\(STATUS \"Finding CRITERION\"[^\n]*\n.*?endif\(\)|if(BUILD_TESTING)\nmessage(STATUS \"Finding CRITERION\")\nfind_package(CRITERION)\nif(CRITERION_FOUND)\n    message(STATUS \"Finding CRITERION - found\")\nelse()\n    message(STATUS \"Finding CRITERION - not found\")\nendif()\nendif()|s' "${SCIP_SRC_DIR}/scip/CMakeLists.txt"
    fi

    # --- Start of R-package specific fixups (replacing patches 0005, 0006, 0007, 0009) ---

    # 1. Fix xmlparse.c R_OK redefinition (Fixes 0005)
    if [ -f "${SCIP_SRC_DIR}/scip/src/xml/xmlparse.c" ]; then
        # Use loose regex for R_OK block to handle varying whitespace/newlines
        perl -0pi -e 's|#ifdef _WIN32\s*#define R_OK 0|#ifdef _WIN32\n#ifdef R_OK\n#undef R_OK\n#endif\n#define R_OK 0|s' "${SCIP_SRC_DIR}/scip/src/xml/xmlparse.c"
    fi

    # 2. Redirect SCIP output to R (Fixes 0006)
    if [ -f "${SCIP_SRC_DIR}/scip/src/scip/message_default.c" ]; then
        # Add includes
        perl -pi -e 's|#include \"scip/struct_message.h\"|#include \"scip/struct_message.h\"\n#include <R_ext/Print.h>|' "${SCIP_SRC_DIR}/scip/src/scip/message_default.c"
        
        # Replace logMessage body (using -0pi for multiline match)
        # We match the function body content somewhat loosely to be robust
        perl -0pi -e 's|if \( msg != NULL \)\n      fputs\(msg, file\);\n   fflush\(file\);|if ( msg != NULL ) { Rprintf("%s", msg); }|g' "${SCIP_SRC_DIR}/scip/src/scip/message_default.c"

        # Replace messageWarningDefault body
        perl -0pi -e 's|if \( msg != NULL && msg\[0\] != .\\0. && msg\[0\] != .\\n. \)\n      fputs\(\"WARNING: \", file\);|if ( msg != NULL && msg[0] != '\''\\0'\'' && msg[0] != '\''\\n'\'' )\n      Rprintf(\"WARNING: \");|g' "${SCIP_SRC_DIR}/scip/src/scip/message_default.c"
    fi

    # 3. Remove abort calls and use SCIPABORT (Fixes 0007)
    # def.h
    if [ -f "${SCIP_SRC_DIR}/scip/src/scip/def.h" ]; then
         # Add declaration for Rf_error (guarded) and abort replacement prototype
         perl -pi -e 's|/\*#define DEBUG\*/|/\*#define DEBUG\*/\n\n/\* Use R Error handling \*/\n#ifdef __cplusplus\nextern \"C\" {\n#endif\n#ifndef SCIP_R_ERROR_DECLARED\n#define SCIP_R_ERROR_DECLARED\nvoid Rf_error(const char *, ...);\n#endif\n#ifdef SCIP_R_PACKAGE\n#ifndef SCIP_ABORT_REPLACEMENT_DECLARED\n#define SCIP_ABORT_REPLACEMENT_DECLARED\nvoid SCIP_abort_replacement(void);\n#endif\n#endif\n#ifdef __cplusplus\n}\n#endif|' "${SCIP_SRC_DIR}/scip/src/scip/def.h"
         # Replace SCIPABORT definition
         perl -pi -e 's|#define SCIPABORT\(\)
 assert\(FALSE\)|#define SCIPABORT() Rf_error(\"SCIP Abort\")|' "${SCIP_SRC_DIR}/scip/src/scip/def.h"
    fi
    
    # lp.c ASSERT
    if [ -f "${SCIP_SRC_DIR}/scip/src/scip/lp.c" ]; then
         perl -pi -e 's|#define ASSERT\(x\) do \{ if\( !\(x\) \) abort\(\); \} while\( FALSE \)|#define ASSERT(x) do { if( !(x) ) SCIPABORT(); } while( FALSE )|' "${SCIP_SRC_DIR}/scip/src/scip/lp.c"
    fi

    # xmldef.h ALLOC_ABORT
    if [ -f "${SCIP_SRC_DIR}/scip/src/xml/xmldef.h" ]; then
         perl -pi -e 's|abort\(\);|SCIPABORT();|' "${SCIP_SRC_DIR}/scip/src/xml/xmldef.h"
    fi

    # lpi_glop.cpp abort() calls
    if [ -f "${SCIP_SRC_DIR}/scip/src/lpi/lpi_glop.cpp" ]; then
         perl -pi -e 's|abort\(\);|SCIPABORT();|g' "${SCIP_SRC_DIR}/scip/src/lpi/lpi_glop.cpp"
    fi

    # tclique_def.h - Add stdlib.h and abort replacement prototype
    if [ -f "${SCIP_SRC_DIR}/scip/src/tclique/tclique_def.h" ]; then
         echo "Patching tclique_def.h..."
         perl -pi -e 's|^#define __TCLIQUE_DEF_H__\s*$|#define __TCLIQUE_DEF_H__\n\n#include <stdlib.h>\n#ifdef SCIP_R_PACKAGE\n#ifndef SCIP_ABORT_REPLACEMENT_DECLARED\n#define SCIP_ABORT_REPLACEMENT_DECLARED\n#ifdef __cplusplus\nextern \"C\" {\n#endif\nvoid SCIP_abort_replacement(void);\n#ifdef __cplusplus\n}\n#endif\n#endif\n#endif|' "${SCIP_SRC_DIR}/scip/src/tclique/tclique_def.h"
    fi

    # dijkstra.h - Add stdlib.h and abort replacement prototype
    if [ -f "${SCIP_SRC_DIR}/scip/src/dijkstra/dijkstra.h" ]; then
         echo "Patching dijkstra.h..."
         perl -pi -e 's|^#define DIJSKSTRA_H\s*$|#define DIJSKSTRA_H\n\n#include <stdlib.h>\n#ifdef SCIP_R_PACKAGE\n#ifndef SCIP_ABORT_REPLACEMENT_DECLARED\n#define SCIP_ABORT_REPLACEMENT_DECLARED\n#ifdef __cplusplus\nextern \"C\" {\n#endif\nvoid SCIP_abort_replacement(void);\n#ifdef __cplusplus\n}\n#endif\n#endif\n#endif|' "${SCIP_SRC_DIR}/scip/src/dijkstra/dijkstra.h"
    fi

    # xmldef.h - Add stdlib.h for exit/abort prototypes
    if [ -f "${SCIP_SRC_DIR}/scip/src/xml/xmldef.h" ]; then
         echo "Patching xmldef.h..."
         perl -pi -e 's|^#define __SCIP_XMLDEF_H__\s*$|#define __SCIP_XMLDEF_H__\n\n#include <stdlib.h>|' "${SCIP_SRC_DIR}/scip/src/xml/xmldef.h"
    fi

    # 4. CppAD error handler (Fixes 0009)
    if [ -f "${SCIP_SRC_DIR}/scip/src/cppad/utility/error_handler.hpp" ]; then
        # Add extern C for Rf_error with guard
        perl -pi -e 's|# include <cstdlib>|# include <cstdlib>\n\n#ifdef SCIP_R_PACKAGE\nextern \"C\" {\n#ifndef SCIP_R_ERROR_DECLARED\n#define SCIP_R_ERROR_DECLARED\n    void Rf_error(const char *, ...);\n#endif\n}\n#endif|' "${SCIP_SRC_DIR}/scip/src/cppad/utility/error_handler.hpp"
        # Use Rf_error
        perl -pi -e 's|using std::cerr;|using std::cerr;\n#ifdef SCIP_R_PACKAGE\n        Rf_error(\"CppAD Error: %s\", msg);\n#else|' "${SCIP_SRC_DIR}/scip/src/cppad/utility/error_handler.hpp"
        # End ifdef
        perl -pi -e 's|std::exit\(1\);|std::exit(1);\n#endif|' "${SCIP_SRC_DIR}/scip/src/cppad/utility/error_handler.hpp"
    fi

    # --- End of R-package specific fixups ---
fi

PATCH_DIR="${R_SCIP_PKG_HOME}/inst/patches"
if [ -d "${PATCH_DIR}" ]; then
    if ! command -v patch >/dev/null 2>&1; then
        echo "Could not find 'patch' to apply local patches!"
        exit 1
    fi
    for patch_file in "${PATCH_DIR}"/*.patch; do
        if [ -f "${patch_file}" ]; then
            echo "Applying patch: $(basename "${patch_file}")"
            if ! patch -p1 -d "${SCIP_SRC_DIR}" < "${patch_file}"; then
                echo "Failed to apply patch: ${patch_file}"
                exit 1
            fi
        fi
    done
fi

# Setup build directory
mkdir -p "${R_SCIP_BUILD_DIR}"
mkdir -p "${R_SCIP_LIB_DIR}"
cd "${R_SCIP_BUILD_DIR}"

# Derive build options
DEFAULT_CMAKE_OPTS="\
    -DCMAKE_INSTALL_PREFIX=${R_SCIP_LIB_DIR_ESC} \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_POSITION_INDEPENDENT_CODE:bool=ON \
    -DBUILD_SHARED_LIBS:bool=OFF \
    -DSHARED:bool=OFF \
    -DBUILD_TESTING:bool=OFF \
    -DSCIP_BUILD_EXECUTABLE:bool=OFF \
    -DSOPLEX_BUILD_EXECUTABLE:bool=OFF \
    -DSOPLEX_BUILD_SHARED:bool=OFF \
    -DSOPLEX_BUILD_TESTS:bool=OFF \
    -DQUADMATH:bool=OFF \
    -DPAPILO:bool=OFF \
    -DZIMPL:bool=OFF \
    -DREADLINE:bool=OFF \
    -DIPOPT:bool=OFF \
    -DAMPL:bool=OFF \
    -DGCG:bool=OFF \
    -DUG:bool=OFF \
    -DTPI=tny \
"
CMAKE_OPTS=${DEFAULT_CMAKE_OPTS}

echo ""
echo "Cmake Options"
echo ${CMAKE_OPTS}
echo ""

${CMAKE_EXE} .. ${CMAKE_OPTS} -G "Unix Makefiles" -Wno-dev
${MAKE} install
