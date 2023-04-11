ds_post_push() {
	if [ "$1" = "" ]; then
		error "post-push: docker-pull: Too few arguments given to ds_post_push"
	fi

	cd "$1"

	if [ "$DEPLOYMENT_SERVER" = "" ] || [ "$DEPLOYMENT_SERVER_USER" = "" ]; then
		error "post-push: docker-pull: Please set DEPLOYMENT_SERVER and DEPLOYMENT_SERVER_USER to perform server side docker image pull"
	fi

	DOCKER_TARGET_FILES_DIR="$1/docker-target"
	mkdir -p "$DOCKER_TARGET_FILES_DIR"
	cd "$DOCKER_TARGET_FILES_DIR"

	copy_target_docker_compose "$PROJECT_DEPLOY_DIR" $PROJECT_ENVIRONMENT "$DOCKER_TARGET_FILES_DIR"
	cp -r "$1/deploy" "$DOCKER_TARGET_FILES_DIR"

	. "$SCRIPT_PATH/../steps/push/lib/git-bare-resources/util.sh"

	ds_create_bare_repo "$DOCKER_TARGET_FILES_DIR" "$SCRIPT_PATH/../steps/post_push/lib/docker-pull-resources/post-receive-hook"

	. "$SCRIPT_PATH/../steps/package/lib/git-resources/util.sh"

	ds_package_as_git_repo "$DOCKER_TARGET_FILES_DIR"

	info "Deploying docker-compose.yml to $DEPLOYMENT_SERVER"
	REMOTE_GIT_BARE_REPO=ssh://$DEPLOYMENT_SERVER_USER@$DEPLOYMENT_SERVER:$DEPLOYMENT_SERVER_PORT/~/.repos/$SERVICE_NAME/$PROJECT_ENVIRONMENT.git
	git remote add deploy $REMOTE_GIT_BARE_REPO 2>&1 | indent
	GIT_SSH_COMMAND="ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no" git push -u deploy $DEPLOY_BRANCH -f

	success "done"
}