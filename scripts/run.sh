#!/bin/sh

SCRIPT_PATH=$(dirname $(readlink -f $0))

if [ ! -f $SCRIPT_PATH/config.sh ]; then
    echo "Please initialize config.sh with vars START_COMMAND"
    exit
fi

. $SCRIPT_PATH/config.sh

if [ "$START_COMMAND" = "" ]; then
	echo "Please supply a START_COMMAND in config.sh"
	exit
fi

PID_PATH_NAME=$HOME/sites/$SERVICE_NAME/$PROJECT_ENVIRONMENT/$SERVICE_NAME.pid

PID_COMMAND='echo $!'
PID_COMMAND="$PID_COMMAND > $PID_PATH_NAME"
START_COMMAND="$START_COMMAND & $PID_COMMAND"

case $1 in
    start)
        echo "Starting $SERVICE_NAME ($PROJECT_ENVIRONMENT) ..."
        if [ ! -f $PID_PATH_NAME ]; then
	    sh -c "$START_COMMAND"
            echo "$SERVICE_NAME ($PROJECT_ENVIRONMENT) started ..."
        else
            echo "$SERVICE_NAME ($PROJECT_ENVIRONMENT) is already running ..."
        fi
    ;;
    stop)
        if [ -f $PID_PATH_NAME ]; then
            PID=$(cat $PID_PATH_NAME);
            echo "$SERVICE_NAME ($PROJECT_ENVIRONMENT) stopping ..."
            kill $PID;
            echo "$SERVICE_NAME ($PROJECT_ENVIRONMENT) stopped ..."
            rm $PID_PATH_NAME
        else
            echo "$SERVICE_NAME ($PROJECT_ENVIRONMENT) is not running ..."
        fi
    ;;
    restart)
        if [ -f $PID_PATH_NAME ]; then
            PID=$(cat $PID_PATH_NAME);
            echo "$SERVICE_NAME ($PROJECT_ENVIRONMENT) stopping ...";
            kill $PID;
            echo "$SERVICE_NAME ($PROJECT_ENVIRONMENT) stopped ...";
            rm $PID_PATH_NAME
            echo "$SERVICE_NAME ($PROJECT_ENVIRONMENT) starting ..."
	    sh -c "$START_COMMAND"
            echo "$SERVICE_NAME ($PROJECT_ENVIRONMENT) started ..."
        else
            echo "$SERVICE_NAME ($PROJECT_ENVIRONMENT)   is not running ..."
        fi
    ;;
esac