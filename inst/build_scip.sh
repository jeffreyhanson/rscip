#!/bin/bash

# Find MAKE
if test -z "${MAKE}"; then MAKE=`which make` 2> /dev/null; fi
if test -z "${MAKE}"; then MAKE=`which /Applications/Xcode.app/Contents/Developer/usr/bin/make` 2> /dev/null; fi

# Find CMAKE
if test -z "${CMAKE_EXE}"; then CMAKE_EXE=`which cmake4` 2> /dev/null; fi
if test -z "${CMAKE_EXE}"; then CMAKE_EXE=`which cmake3` 2> /dev/null; fi
if test -z "${CMAKE_EXE}"; then CMAKE_EXE=`which cmake2` 2> /dev/null; fi
if test -z "${CMAKE_EXE}"; then CMAKE_EXE=`which cmake` 2> /dev/null; fi
if test -z "${CMAKE_EXE}"; then CMAKE_EXE=`which /Applications/CMake.app/Contents/bin/cmake` 2> /dev/null; fi

# Throw error if can't find CMAKE
if test -z "${CMAKE_EXE}"; then
    echo "Could not find 'cmake'!"
    exit 1
fi

# Find R
: ${R_HOME=`R RHOME`}
RSCRIPT_BIN=${R_HOME}/bin/Rscript
if test -z "${R_HOME}"; then
    echo "'R_HOME' could not be found!"
    exit 1
fi

# Set file paths
R_SCIP_PKG_HOME=`pwd`
SCIP_SRC_FILE=`find "$(pwd -P)" -name "scipopt*tgz"`
SCIP_SRC_DIR=`basename ${SCIP_SRC_FILE} .tgz`
R_SCIP_SRC_DIR=`pwd`
R_SCIP_LIB_DIR=${R_SCIP_SRC_DIR}/sciplib
R_SCIP_BUILD_DIR=${R_SCIP_SRC_DIR}/sciplib/build

# Escape spaces in file paths
R_SCIP_SRC_DIR=$( echo "$R_SCIP_SRC_DIR" | sed 's/ /\\ /g' )
R_SCIP_LIB_DIR=$( echo "$R_SCIP_LIB_DIR" | sed 's/ /\\ /g' )
R_SCIP_BUILD_DIR=$( echo "$R_SCIP_BUILD_DIR" | sed 's/ /\\ /g' )

# Normalize slashes in file paths
SCIP_INCLUDE_DIR=$( echo "$SCIP_INCLUDE_DIR" | sed 's/\\/\//g' )
SCIP_CONFIG_DIR=$( echo "$SCIP_CONFIG_DIR" | sed 's/\\/\//g' )
SCIP_LIB_DIR=$( echo "$SCIP_LIB_DIR" | sed 's/\\/\//g' )
SCIP_LIB_DIR2=$( echo "$SCIP_LIB_DIR2" | sed 's/\\/\//g' )

# Find TBB directories
export TBB_DIR=`"${R_HOME}/bin/Rscript" -e "cat(system.file(package = 'RcppParallel'))"`

# Print file paths
echo ""
echo "[FILES AND FOLDERS]"
echo "R_SCIP_PKG_HOME = '${R_SCIP_PKG_HOME}'"
echo "SCIP_SRC_FILE = '${SCIP_SRC_FILE}'"
echo "SCIP_SRC_DIR = '${SCIP_SRC_DIR}'"
echo "R_SCIP_SRC_DIR = '${R_SCIP_SRC_DIR}'"
echo "R_SCIP_LIB_DIR = '${R_SCIP_LIB_DIR}'"
echo "R_SCIP_BUILD_DIR = '${R_SCIP_BUILD_DIR}'"

export CC=`"${R_HOME}/bin/R" CMD config CC`
export CXX=`"${R_HOME}/bin/R" CMD config CXX`
export CXX11=`"${R_HOME}/bin/R" CMD config CXX11`
export CXXFLAGS=`"${R_HOME}/bin/R" CMD config CXXFLAGS`
export CFLAGS=`"${R_HOME}/bin/R" CMD config CFLAGS`
export CPPFLAGS=`"${R_HOME}/bin/R" CMD config CPPFLAGS`
export LDFLAGS=`"${R_HOME}/bin/R" CMD config LDFLAGS`

echo ""
echo "[SYSTEM]"
echo "CMAKE VERSION: '`${CMAKE_EXE} --version | head -n 1`'"
echo "arch: '$(arch)'"
echo "R_ARCH: '$R_ARCH'"
echo "CC: '${CC}'"
echo "CXX: '${CXX}'"
echo "CXX11: '${CXX11}'"
echo "TBB_DIR: '${TBB_DIR}'"

# extract scipoptsuite
echo ""
echo "[EXTRACTION]"
tar -xzf "${SCIP_SRC_FILE}" -C "${R_SCIP_SRC_DIR}"
mv "${R_SCIP_SRC_DIR}/${SCIP_SRC_DIR}" "${R_SCIP_LIB_DIR}"

# apply patches
echo ""
echo "[APPLYING PATCHES]"
rm -f "${R_SCIP_LIB_DIR}/soplex/CMakeLists.txt"
rm -f "${R_SCIP_LIB_DIR}/scip/CMakeLists.txt"
rm -f "${R_SCIP_LIB_DIR}/papilo/cmake/Modules/FindTBB.cmake"
cp "${R_SCIP_PKG_HOME}/inst/patches/soplex/CMakeLists.txt" "${R_SCIP_LIB_DIR}/soplex/CMakeLists.txt"
cp "${R_SCIP_PKG_HOME}/inst/patches/scip/CMakeLists.txt" "${R_SCIP_LIB_DIR}/scip/CMakeLists.txt"
cp "${R_SCIP_PKG_HOME}/inst/patches/papilo/FindTBB.cmake" "${R_SCIP_LIB_DIR}/papilo/cmake/Modules/FindTBB.cmake"
cp "${R_SCIP_PKG_HOME}/inst/patches/soplex/FindTBB.cmake" "${R_SCIP_LIB_DIR}/soplex/cmake/Modules/FindTBB.cmake"
cp "${R_SCIP_PKG_HOME}/inst/patches/scipoptsuite/CMakeLists.txt" "${R_SCIP_LIB_DIR}/CMakeLists.txt"

# config makefile
echo ""
echo "[CONFIGURATION]"
mkdir -p "${R_SCIP_BUILD_DIR}"
cd "${R_SCIP_BUILD_DIR}"
CMAKE_OPTS="-DIPOPT=off -DGMP=on -DZIMPL=off -DREADLINE=off -DTPI=tny -DCMAKE_POSITION_INDEPENDENT_CODE:bool=ON -DSHARED:bool=off -DCMAKE_C_FLAGS_INIT:STRING=-Wno-stringop-overflow -DCMAKE_CXX_FLAGS_INIT:STRING=-Wno-stringop-overflow -DCMAKE_SHARED_LINKER_FLAGS_INIT:STRING=-Wno-stringop-overflow -DTBB_DIR=${TBB_DIR} -DTBB_ROOT_DIR=${TBB_ROOT_DIR}"
${CMAKE_EXE} .. ${CMAKE_OPTS} -G "Unix Makefiles"

# build scip
echo ""
echo "[BUILDING]"
MAKE_OPTS="ZLIB=false READLINE=false TPI=tny SHARED=false"
${MAKE} libscip ${MAKE_OPTS}

# clean up
find "${R_SCIP_LIB_DIR}" -name "Makefile" -delete
find "${R_SCIP_LIB_DIR}" -name "CITATION.cff" -delete
