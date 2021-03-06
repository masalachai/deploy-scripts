#!/bin/sh

set -e

SCRIPT_PATH=$(dirname $(readlink -f $0))
. $SCRIPT_PATH/common.sh


JAVA_PID=$(ps -elf | grep '=37567' | grep -v grep | awk '{print $4}')
if [ "$JAVA_PID" != "" ]; then
	printf "Killing old java PID: $JAVA_PID ... "
	kill -9 $JAVA_PID
	success 'done'
fi
copy_deployment_files 'java' $SCRIPT_PATH/resources/java-mvnw-project

title 'TEST - editing configs'
cd $COPY_PROJECT_DIR/java-project
SERVICE_NAME="java-deploy-test"
PROJECT_ENVIRONMENT="default"
DEPLOYMENT_DIR="$TEST_WORKING_DIR/$SERVICE_NAME/$PROJECT_ENVIRONMENT"

PROJECT_DEPLOY_DIR="$COPY_PROJECT_DIR/java-project/deploy"
DEPLOY_SCRIPTS_HOME="$SCRIPT_PATH/../"
printf "\nDEPLOYMENT_DIR=$DEPLOYMENT_DIR\nDEPLOYMENT_SERVER=localhost\nDEPLOYMENT_SERVER_USER=$USER\nREPO=file://$COPY_PROJECT_DIR/java-project\nSERVICE_NAME=$SERVICE_NAME\nLINKED_FILES=\n" >> deploy/app-config.sh
printf "GIT_BRANCH=master\nSERVICE_PORT=37567\n" >> deploy/environments/default/config.sh
cat deploy/app-config.sh deploy/environments/default/config.sh
# hack for hardcoded nginx conf copying. to be made configurable later.
touch deploy/environments/default/assets/nginx.conf
# add some hook scripts
mkdir -p deploy/scripts
echo 'echo "Running post deployment scripts"' >> deploy/scripts/post_deploy.sh
echo 'echo "Running pre build scripts"' >> deploy/scripts/pre_build.sh
echo 'echo "Running post build scripts"' >> deploy/scripts/post_build.sh
title 'TEST - deploying default environment'
rm -rf $TEST_WORKING_DIR
#sh deploy/deploy.sh default
PROJECT_DEPLOY_DIR=$PROJECT_DEPLOY_DIR sh $SCRIPT_PATH/../scripts/deploy.sh default
cd $TEST_WORKING_DIR/java-deploy-test/default/current
title 'TEST - check web application'
sleep 5
wget localhost:37567
printf 'Checking index page contents ... '
if [ $(grep -c 'Example Spring Boot Application!' index.html) -eq 1 ]; then
	success 'success!'
else
	error 'fail! :('
fi
sh deploy/run.sh stop
cd $SCRIPT_PATH/../
rm -rf /tmp/deploy-scripts
