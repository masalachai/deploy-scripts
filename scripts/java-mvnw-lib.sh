#!/bin/sh

set -e

SCRIPT_PATH=$(dirname $(readlink -f $0))
. $SCRIPT_PATH/util.sh
title 'build - java maven wrapper'

if [ "$PROJECT_DEPLOY_DIR" = "" ] || [ "$PROJECT_ENVIRONMENT" = "" ]; then
	echo "No project deploy directory supplied to java deploy script"
	exit
fi

. $PROJECT_DEPLOY_DIR/app-config.sh
. $PROJECT_DEPLOY_DIR/environments/$PROJECT_ENVIRONMENT/config.sh

if [ "$DEPLOYMENT_DIR" = "" ]; then
	DEPLOYMENT_DIR='$HOME/sites'
fi

WORK_DIR=$PROJECT_DEPLOY_DIR/work
DEPLOY_REPO=$WORK_DIR/deploy-repo

cd $WORK_DIR/repo
./mvnw package -Dmaven.test.skip=true 2>&1 | indent
title 'build - java - prepare-deployment'
cd target/
WARFILE=$(ls *RELEASE.war 2>/dev/null | head -n1)
if [ "$WARFILE" = "" ]; then
	WARFILE=$(ls *RELEASE.jar | head -n1)
fi
if [ "$WARFILE" = "" ]; then
	error "No jar or war file found to deploy"
fi

cp $WARFILE $PROJECT_DEPLOY_DIR/work
mkdir -p $DEPLOY_REPO
cd $DEPLOY_REPO

if [ "$GIT_PUSH_REMOTE" = "" ] || [ "$GIT_PUSH_BRANCH" = "" ]; then
	error "No git remote or branch specified to push to"
fi

git init 2>&1 | indent
git remote add origin $GIT_PUSH_REMOTE
git config user.name "deployer"
git config user.email "techgroup@loanstreet.com.my"
git fetch
git checkout $GIT_PUSH_BRANCH
git pull origin $GIT_PUSH_BRANCH
cp $PROJECT_DEPLOY_DIR/work/$WARFILE ./
git add $WARFILE 2>&1 | indent
git commit . -m "commit to repository" 2>&1 | indent
git push origin $GIT_PUSH_BRANCH