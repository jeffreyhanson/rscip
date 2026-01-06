#!/bin/bash

#
# Set variables
#
if test -z "${MAKE}"; then MAKE=`which make` 2> /dev/null; fi
if test -z "${MAKE}"; then MAKE=`which /Applications/Xcode.app/Contents/Developer/usr/bin/make` 2> /dev/null; fi

if test -z "${CMAKE_EXE}"; then CMAKE_EXE=`which cmake4` 2> /dev/null; fi
if test -z "${CMAKE_EXE}"; then CMAKE_EXE=`which cmake3` 2> /dev/null; fi
if test -z "${CMAKE_EXE}"; then CMAKE_EXE=`which cmake2` 2> /dev/null; fi
if test -z "${CMAKE_EXE}"; then CMAKE_EXE=`which cmake` 2> /dev/null; fi
if test -z "${CMAKE_EXE}"; then CMAKE_EXE=`which /Applications/CMake.app/Contents/bin/cmake` 2> /dev/null; fi

if test -z "${CMAKE_EXE}"; then
    echo "Could not find 'cmake'!"
    exit 1
fi

: ${R_HOME=`R RHOME`}
if test -z "${R_HOME}"; then
    echo "'R_HOME' could not be found!"
    exit 1
fi

CFLAGS=`"${R_HOME}/bin/R" CMD config CFLAGS`
CPPFLAGS=`"${R_HOME}/bin/R" CMD config --cppflags`
CXXFLAGS=`"${R_HOME}/bin/R" CMD config CXXFLAGS`
dedupe_flags() {
    printf '%s\n' "$1" | awk '{
        out = "";
        for (i = 1; i <= NF; i++) {
            if (!seen[$i]++) {
                out = out $i " "
            }
        }
        sub(/ $/, "", out);
        print out;
    }'
}

export CC=`"${R_HOME}/bin/R" CMD config CC`
export CXX=`"${R_HOME}/bin/R" CMD config CXX11`
export CXX11=`"${R_HOME}/bin/R" CMD config CXX11`
export CFLAGS="${CFLAGS}"
export CPPFLAGS="${CPPFLAGS}"
export CXXFLAGS="${CXXFLAGS}"
LDFLAGS=`"${R_HOME}/bin/R" CMD config LDFLAGS`
LDFLAGS=`dedupe_flags "${LDFLAGS}"`
export LDFLAGS="${LDFLAGS}"

R_SCIP_PKG_HOME=`pwd`
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
echo "CXX11: '${CXX11}'"
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

# Patch CMake files to tolerate spaces in paths and silence unused test dependencies
if command -v perl >/dev/null 2>&1; then
    if [ -f "${SCIP_SRC_DIR}/scip/CMakeLists.txt" ]; then
        perl -0pi -e 's|if\(\(GIT\) AND \(EXISTS \${CMAKE_CURRENT_SOURCE_DIR}/\.git\)\)|if((GIT) AND (EXISTS \\\"\${CMAKE_CURRENT_SOURCE_DIR}/.git\\\"))|g' "${SCIP_SRC_DIR}/scip/CMakeLists.txt"
        perl -0pi -e 's|WORKING_DIRECTORY \${CMAKE_CURRENT_SOURCE_DIR}|WORKING_DIRECTORY \\\"\${CMAKE_CURRENT_SOURCE_DIR}\\\"|g' "${SCIP_SRC_DIR}/scip/CMakeLists.txt"
        perl -0pi -e 's|message\(STATUS "Finding CRITERION"\).*?endif\(\)|if(BUILD_TESTING)\nmessage(STATUS "Finding CRITERION")\nfind_package(CRITERION)\nif(CRITERION_FOUND)\n    message(STATUS "Finding CRITERION - found")\nelse()\n    message(STATUS "Finding CRITERION - not found")\nendif()\nendif()|s' "${SCIP_SRC_DIR}/scip/CMakeLists.txt"
    fi
    if [ -f "${SCIP_SRC_DIR}/soplex/CMakeLists.txt" ]; then
        perl -0pi -e 's|if\(\(GIT\) AND \(EXISTS \${CMAKE_CURRENT_SOURCE_DIR}/\.git\)\)|if((GIT) AND (EXISTS \\\"\${CMAKE_CURRENT_SOURCE_DIR}/.git\\\"))|g' "${SCIP_SRC_DIR}/soplex/CMakeLists.txt"
        perl -0pi -e 's|WORKING_DIRECTORY \${CMAKE_CURRENT_SOURCE_DIR}|WORKING_DIRECTORY \\\"\${CMAKE_CURRENT_SOURCE_DIR}\\\"|g' "${SCIP_SRC_DIR}/soplex/CMakeLists.txt"
    fi
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
    -DCMAKE_POSITION_INDEPENDENT_CODE:bool=ON \
    -DBUILD_SHARED_LIBS:bool=OFF \
    -DSHARED:bool=OFF \
    -DBUILD_TESTING:bool=OFF \
    -DSCIP_BUILD_EXECUTABLE:bool=OFF \
    -DSOPLEX_BUILD_EXECUTABLE:bool=OFF \
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

${CMAKE_EXE} .. ${CMAKE_OPTS} -G "Unix Makefiles"
${MAKE} install
