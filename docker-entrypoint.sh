#!/bin/sh

set -e

DEPLOY_SCRIPTS_HOME="/deploy-scripts"
VERSION=$(cat $DEPLOY_SCRIPTS_HOME/.VERSION)

show_usage() {
	printf "Usage:\n\tdocker run --rm -v [project directory path]:/project -it finology/deploy-scripts:$VERSION [environment name]\n"
	exit 1
}

create_user() {
	groupadd -g "$USER_GROUP_ID" "$CREATE_USER"
	useradd -u "$CREATE_USER_ID" -g "$USER_GROUP_ID" "$CREATE_USER"
}

show_installer_usage() {
	printf "Usage:\n\tdocker run --rm -e CREATE_USER=$USER -e CREATE_USER_ID=$(id -u $USER) -e USER_GROUP_ID=$(id -g $USER) -v [project directory path]:/project -it finology/deploy-scripts:$VERSION install [project type] [options]\n"
	exit 1
}

run_installer() {
	TEMP_INSTALL_DIR="/tmp/deploy-scripts"
	mkdir -p "$TEMP_INSTALL_DIR"
	chown "$CREATE_USER:$CREATE_USER" "$TEMP_INSTALL_DIR"

	sudo -u $CREATE_USER sh -c "sh /deploy-scripts/installer/install.sh $1 $TEMP_INSTALL_DIR $2 $3"

	DS_DIR="deploy"
	INSTALLER_CONFIG="$DEPLOY_SCRIPTS_HOME/projects/$1/installer/config.sh"
	if [ -f "$INSTALLER_CONFIG" ]; then
		. "$INSTALLER_CONFIG"
	fi

	printf "Moving deploy-scripts configs to project dir at /project/$DS_DIR ... "
	mkdir -p "/project/$DS_DIR"
	chown -R "$CREATE_USER:$CREATE_USER" /project/$DS_DIR
	mv "$TEMP_INSTALL_DIR/$DS_DIR"/* /project/$DS_DIR/
	printf "done\n"
	exit 0
}

if [ "$1" = "" ] || [ "$1" = "--help" ]; then
	show_usage
fi

if [ "$CREATE_USER" != "" ] && [ "$CREATE_USER_ID" != "" ] && [ "$USER_GROUP_ID" != "" ]; then
	if [ "$CREATE_USER" != "root" ]; then
		create_user
	fi

	if [ "$1" = "--install" ]; then
		run_installer "$2" "$3" "$4"
	fi
fi

APP_CONFIG_PATH=$(find /project -name "app-config.sh")

if [ "$APP_CONFIG_PATH" = "" ]; then
	printf "ERROR: No deploy-scripts config dir found in project. Project directory not mounted to /project?\n\n"
	show_usage
fi

DEPLOY_DIRECTORY_PATH=$(dirname $APP_CONFIG_PATH)

if [ ! -d "$DEPLOY_DIRECTORY_PATH/environments/$1" ]; then
	printf "ERROR: No environment $1 found at $DEPLOY_DIRECTORY_PATH/environments/$1\n\n"
	show_usage
fi

. $HOME/.profile
PROJECT_DEPLOY_DIR="$DEPLOY_DIRECTORY_PATH" sh $DEPLOY_SCRIPTS_HOME/deploy.sh "$1"
