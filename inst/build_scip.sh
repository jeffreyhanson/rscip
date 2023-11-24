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
# Determine TBB installation
echo "Looking for TBB installation.."
if [ `uname` = "Darwin" ]; then
  ## macOS
  echo " searching in HomeBrew installation"
  ### find TBB homebew installation
  BREW_TBB_LIB_DIR=`brew --prefix tbb`
  cd ${BREW_TBB_LIB_DIR}
  tree .
  ### find directory containing library files
  TBB_LIB_DIR=`find "$(pwd -P)" -name libtbb.so -printf '%h\n'`
  if [ -z "${TBB_LIB_DIR}" ]; then
    TBB_LIB_DIR=`find "$(pwd -P)" -name libtbb.dynlib -printf '%h\n'`
  fi
  if [ -z "${TBB_LIB_DIR}" ]; then
    echo "  couldn't TBB library directory"
    exit 1
  fi
  export TBB_DIR=`dirname $TBB_LIB_DIR`
  ### reset directory
  cd ${R_SCIP_PKG_HOME}
else
  pkg-config --version >/dev/null 2>&1
  if [ $? -eq 0 ]; then
    ## Linux
    echo " assuming is installed on system"
    ### use system libraries
  else
    ## Windows
    ### use RcppParallel
    echo " searching in RcppParallel package"
    export TBB_DIR=`"${R_HOME}/bin/Rscript" -e "cat(system.file(package = 'RcppParallel'))"`
  fi
fi

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
if [ ! -z $TBB_DIR ]; then
  echo "TBB_DIR: '${TBB_DIR}'"
else
  echo "TBB_DIR: NOT SET"
fi

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
cp "${R_SCIP_PKG_HOME}/inst/patches/scipoptsuite/CMakeLists.txt" "${R_SCIP_LIB_DIR}/CMakeLists.txt"

# config makefile
echo ""
echo "[CONFIGURATION]"
mkdir -p "${R_SCIP_BUILD_DIR}"
cd "${R_SCIP_BUILD_DIR}"
CMAKE_OPTS="-DIPOPT=off -DLUSOL=on -DGMP=on -DZIMPL=off -DREADLINE=off -DTPI=tny -DCMAKE_POSITION_INDEPENDENT_CODE:bool=ON -DSHARED:bool=off -DCMAKE_C_FLAGS_INIT:STRING=-Wno-stringop-overflow -DCMAKE_CXX_FLAGS_INIT:STRING=-Wno-stringop-overflow -DCMAKE_SHARED_LINKER_FLAGS_INIT:STRING=-Wno-stringop-overflow"
if [ ! -z $TBB_DIR]; then
  CMAKE_OPTS="${CMAKE_OPTS} -DTBB_DIR=${TBB_DIR} -DTBB_ROOT_DIR=${TBB_DIR}"
fi
if [ -d "${R_SCIP_PKG_HOME}/openblas" ]; then
  BLAS_DIR="${R_SCIP_PKG_HOME}/openblas"
  CMAKE_OPTS="${CMAKE_OPTS} -DCMAKE_PREFIX_PATH=${BLAS_DIR}/lib -DBLA_VENDOR=OpenBLAS"
fi

echo ""
echo "Using CMAKE_OPTS=${CMAKE_OPTS}"
echo ""
${CMAKE_EXE} .. ${CMAKE_OPTS} -G "Unix Makefiles"

# build scip
echo ""
echo "[BUILDING]"
MAKE_OPTS="ZLIB=false READLINE=false TPI=tny SHARED=false"
echo ""
echo "Using MAKE_OPTS=${MAKE_OPTS}"
echo ""
${MAKE} libscip ${MAKE_OPTS}

# clean up files to pass CRAN checks
find "${R_SCIP_LIB_DIR}" -name "Makefile" -delete
find "${R_SCIP_LIB_DIR}" -name "CITATION.cff" -delete
