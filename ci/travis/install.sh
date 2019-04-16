#! /bin/bash
#
# Copyright 2017 - 2019 James E. King III
# Distributed under the Boost Software License, Version 1.0.
# (See accompanying file LICENSE_1_0.txt or copy at
#      http://www.boost.org/LICENSE_1_0.txt)
#
# Executes the install phase for travis
#
# If your repository has additional directories beyond
# "example", "examples", "tools", and "test" then you
# can add them in the environment variable DEPINST.
# i.e. - DEPINST="--include dirname1 --include dirname2"
#

set -ex

function show_bootstrap_log
{
    cat bootstrap.log
}

export SELF=`basename $TRAVIS_BUILD_DIR`
cd ..
if [ "$SELF" == "interval" ]; then
    export SELF=numeric/interval
fi
git clone -b $TRAVIS_BRANCH --depth 1 https://github.com/boostorg/boost.git boost-root
cd boost-root
git submodule update -q --init libs/headers
git submodule update -q --init tools/boost_install
git submodule update -q --init tools/boostdep
git submodule update -q --init tools/build
mkdir -p libs/$SELF
cp -r $TRAVIS_BUILD_DIR/* libs/$SELF
export BOOST_ROOT="`pwd`"
export PATH="`pwd`":$PATH
python tools/boostdep/depinst/depinst.py --include benchmark --include example --include examples --include tools $DEPINST $SELF

# If clang was installed from LLVM APT it will not have a /usr/bin/clang
# so we need to add the llvm bin path to the PATH
if [ "${TOOLSET%%-*}" == "clang" ]; then
    ver="${TOOLSET#*-}"
    export PATH=/usr/lib/llvm-${ver}/bin:$PATH
    ls -ls /usr/lib/llvm-${ver}/bin || true
    hash -r || true
    which clang || true
    which clang++ || true
fi

trap show_bootstrap_log ERR
./bootstrap.sh --with-toolset=${TOOLSET%%-*}
trap - ERR
./b2 headers
