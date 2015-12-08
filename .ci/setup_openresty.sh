#!/bin/bash

if [ "$OPENRESTY_TESTS" != "yes" ]; then
  exit
  echo "Exiting, no openresty tests"
fi

set -e

cd $HOME
mkdir -p $OPENRESTY_DIR

if [ ! "$(ls -A $OPENRESTY_DIR)" ]; then
  OPENRESTY_BASE=ngx_openresty-$OPENRESTY_VERSION

  tree $LUAJIT_DIR

  curl https://openresty.org/download/$OPENRESTY_BASE.tar.gz | tar xz
  pushd $OPENRESTY_BASE
  ./configure \
    --prefix=$OPENRESTY_DIR \
    --without-http_coolkit_module \
    --without-lua_resty_dns \
    --without-lua_resty_lrucache \
    --without-lua_resty_upstream_healthcheck \
    --without-lua_resty_websocket \
    --without-lua_resty_upload \
    --without-lua_resty_string \
    --without-lua_resty_mysql \
    --without-lua_resty_redis \
    --without-http_redis_module \
    --without-http_redis2_module \
    --without-lua_redis_parser

  make
  make install
  cd $HOME
fi

git clone git://github.com/travis-perl/helpers travis-perl-helpers
pushd travis-perl-helpers
source ./init
popd
cpan-install Test::Nginx::Socket
