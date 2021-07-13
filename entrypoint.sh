#!/bin/bash

# database
CLOUDREVE_DEFAULT_DB=/cloudreve/cloudreve.db
CLOUDREVE_DB=/cloudreve/db/cloudreve.db
# conf
CLOUDREVE_DEFAULT_CONF=/cloudreve/conf.ini
CLOUDREVE_CONF=/cloudreve/config/conf.ini
# init log
CLOUDREVE_INIT_LOG=/cloudreve/init.log

if [ ! -e $CLOUDREVE_DB ]; then
    if [ -e $CLOUDREVE_DEFAULT_CONF ]; then
        echo "Found config at `$CLOUDREVE_DEFAULT_CONF`, it has been moved to `$CLOUDREVE_CONF`"
        mv $CLOUDREVE_DEFAULT_CONF $CLOUDREVE_CONF
    fi
    echo -e "[Database]\nDBFile=$CLOUDREVE_DB" >> $CLOUDREVE_CONF

    if [ -e $CLOUDREVE_DEFAULT_DB ]; then
        echo "Move the database file from `$CLOUDREVE_DEFAULT_DB` to `$CLOUDREVE_DB`"
        mv $CLOUDREVE_DEFAULT_DB $CLOUDREVE_DB
    fi
fi

cloudreve -c $CLOUDREVE_CONF
