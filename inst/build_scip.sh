#!/bin/bash

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

R_SCIP_PKG_HOME=`pwd`
SCIP_SRC_FILE=`find "$(pwd -P)" -name "scipopt*"`
SCIP_SRC_DIR=${R_SCIP_PKG_HOME}/inst/`basename ${SCIP_SRC_FILE} .tgz`
R_SCIP_BUILD_DIR=${SCIP_SRC_DIR}/build
R_SCIP_LIB_DIR=${R_SCIP_PKG_HOME}/src/SCIPlib

echo ""
echo "[FILES AND FOLDERS]"
echo "R_SCIP_PKG_HOME = '${R_SCIP_PKG_HOME}'"
echo "SCIP_SRC_DIR = '${SCIP_SRC_DIR}'"
echo "SCIP_SRC_FILE = '${SCIP_SRC_FILE}'"
echo "R_SCIP_BUILD_DIR = '${R_SCIP_BUILD_DIR}'"
echo "R_SCIP_LIB_DIR = '${R_SCIP_LIB_DIR}'"

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

# extract scipoptsuite
echo ""
echo "[EXTRACTION]"
cd ${R_SCIP_PKG_HOME}/inst
tar -xzvf ${SCIP_SRC_FILE}
mkdir -p ${R_SCIP_BUILD_DIR}

# config makefile
echo ""
echo "[CONFIGURATION]"
cd ${R_SCIP_BUILD_DIR}
CMAKE_OPTS="-DIPOPT=off -DGMP=on -DZIMPL=off -DREADLINE=off"
# CMAKE_OPTS="-DIPOPT=off -DGMP=on -DZIMPL=off -DREADLINE=off -DTPI=tny"
#CMAKE_OPTS="-DAUTOBUILD=on"
${CMAKE_EXE} .. ${CMAKE_OPTS} -G "Unix Makefiles"

# build scip
echo ""
echo "[BUILDING]"
MAKE_OPTS="ZLIB=false READLINE=false SHARED=true"
${MAKE} libscip ${MAKE_OPTS}

# copy to package directory
echo ""
echo "[INSTALLATION]"
mkdir -p ${R_SCIP_LIB_DIR}
mkdir -p ${R_SCIP_LIB_DIR}/lib
mkdir -p ${R_SCIP_LIB_DIR}/include
mkdir -p ${R_SCIP_LIB_DIR}/config
cp -R ${R_SCIP_BUILD_DIR}/lib/. ${R_SCIP_LIB_DIR}/lib
cp -R ${SCIP_SRC_DIR}/scip/src/. ${R_SCIP_LIB_DIR}/include
cp -R ${R_SCIP_BUILD_DIR}/scip/. ${R_SCIP_LIB_DIR}/config
