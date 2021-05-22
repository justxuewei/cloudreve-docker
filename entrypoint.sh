#!/bin/bash

chmod +x ./cloudreve-main

CLOUDREVE_DEFAULT_DB=cloudreve.db
CLOUDREVE_DB=db/cloudreve.db
CLOUDREVE_CONF=config/conf.ini
CLOUDREVE_INIT_LOG=init.log

if [ ! -e $CLOUDREVE_DB ]; then
    if [ ! e $CLOUDREVE_DEFAULT_DB ]; then
        nohup ./cloudreve-main -c $CLOUDREVE_CONF > $CLOUDREVE_INIT_LOG 2>&1 &
        echo "Waiting Cloudreve initializing..."
        sleep 5
        kill -9 $(ps -ef | grep cloudreve-main | grep -v grep | awk {'print $2'})
        cat $CLOUDREVE_INIT_LOG
        rm -f $CLOUDREVE_INIT_LOG
    fi
    mv $CLOUDREVE_DEFAULT_DB $CLOUDREVE_DB
    echo -e "[Database]\nDBFile=$CLOUDREVE_DB" >> $CLOUDREVE_CONF
fi

./cloudreve-main -c $CLOUDREVE_CONF

