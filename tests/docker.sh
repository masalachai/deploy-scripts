#!/bin/sh

set -e

SCRIPT_PATH=$(dirname $(readlink -f $0))
. $SCRIPT_PATH/common.sh


copy_deployment_files 'python' $SCRIPT_PATH/resources/django_project "default" "docker"

title 'TEST - editing configs'
cd $COPY_PROJECT_DIR/python-project
SERVICE_NAME="python-deploy-test"
PROJECT_ENVIRONMENT="default"
DEPLOYMENT_DIR="$TEST_WORKING_DIR/$SERVICE_NAME/$PROJECT_ENVIRONMENT"
PROJECT_DEPLOY_DIR="$COPY_PROJECT_DIR/python-project/deploy"

cp -r $SCRIPT_PATH/../projects/python/template/docker $PROJECT_DEPLOY_DIR/
cp -r $SCRIPT_PATH/../projects/python/template/environments/$PROJECT_ENVIRONMENT/docker $PROJECT_DEPLOY_DIR/environments/$PROJECT_ENVIRONMENT/

printf "\nDEPLOYMENT_DIR=$DEPLOYMENT_DIR\nDEPLOYMENT_SERVER=localhost\nDEPLOYMENT_SERVER_USER=$USER\nREPO=file://$COPY_PROJECT_DIR/python-project\nSERVICE_NAME=$SERVICE_NAME\nLINKED_FILES=\nLINKED_DIRS=\"\"\n" >> deploy/app-config.sh
printf "PROJECT_ENVIRONMENT=$PROJECT_ENVIRONMENT\nGIT_BRANCH=master\nPACKAGE=git\nPUSH=git-bare\nDOCKERIZE=true\n" >> deploy/environments/default/config.sh
cat deploy/app-config.sh
cat deploy/environments/default/config.sh
title 'TEST - deploying default environment'
rm -rf $TEST_WORKING_DIR
PROJECT_DEPLOY_DIR=$PROJECT_DEPLOY_DIR sh $SCRIPT_PATH/../scripts/deploy.sh default
cd $TEST_WORKING_DIR/python-deploy-test/default/current
sleep 5
title 'TEST - check web application'
wget 127.0.0.1:8000
printf 'Checking index page contents ... '
if [ $(grep -c 'The install worked successfully! Congratulations!' index.html) -eq 2 ]; then
	success 'success!'
else
	error 'fail! :('
fi
docker-compose down
cd $SCRIPT_PATH/../
rm -rf /tmp/deploy-scripts
