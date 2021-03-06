#!/bin/sh

if [ ! -f ./config.sh ]; then
	echo "No config.sh supplied. exiting."
fi

. ./config.sh
. ./util.sh

if [ $DEPLOYMENT_SERVER_USER = "" ] || [ $SERVICE_NAME = "" ]; then
	echo "Bare repo creation: DEPLOYMENT_SERVER_USER or SERVICE_NAME not set. exiting."
	exit
fi

SCRIPT_DIR=$(dirname $(readlink -f $0))
BARE_REPO_DIR=$HOME/.repos/$SERVICE_NAME/$PROJECT_ENVIRONMENT.git
POST_RECEIVE_HOOK="post-receive-hook"

if [ ! -d $BARE_REPO_DIR ]; then
	echo "Creating bare repo directory at $BARE_REPO_DIR"
	mkdir -p $BARE_REPO_DIR && cd $BARE_REPO_DIR
	if [ ! -d ./.git ]; then
		echo "Initializing bare repo"
		git init --bare | indent
	fi
fi

echo "Copying post-receive hook from $POST_RECEIVE_HOOK"
cp $SCRIPT_DIR/$POST_RECEIVE_HOOK $BARE_REPO_DIR/hooks/post-receive
cp $SCRIPT_DIR/config.sh $BARE_REPO_DIR/hooks/
cp $SCRIPT_DIR/post-deploy-utils.sh $BARE_REPO_DIR/hooks/
cp $SCRIPT_DIR/post-receive-utils.sh $BARE_REPO_DIR/hooks/
cp $SCRIPT_DIR/util.sh $BARE_REPO_DIR/hooks/
cd $BARE_REPO_DIR/hooks && chmod +x post-receive
echo "Post-receive hook deployed. Cleaning up"
cd /tmp
rm -rf $SCRIPT_DIR
