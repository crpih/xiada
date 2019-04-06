#!/bin/sh

XIADA_PROFILE=galician_xiada
RUBY_VERSION=2.4.5
XIADA_INSTALL_DIR=/usr/local/xiada
RUBY=/home/xiada/.rbenv/versions/$RUBY_VERSION/bin/ruby
RUBYLIB=$XIADA_INSTALL_DIR/running/bin
DAEMONDIR=$XIADA_INSTALL_DIR
PORT=4000
DATABASE_NAME=training_galician_xiada_escrita.db
DATABASE=$DAEMONDIR/training/databases/$XIADA_PROFILE/$DATABASE_NAME

export RUBYLIB=$RUBYLIB
export XIADA_PROFILE=$XIADA_PROFILE

exec $RUBY $DAEMONDIR/running/bin/xiada_tagger.rb -s $PORT $DATABASE
