ds_push() {
	if [ "$1" = "" ]; then
		error "push: docker: Too few arguments given to ds_push"
	fi

	if [ "$DOCKER_HOME" != "" ]; then
		DOCKER_CONFIG=$DOCKER_HOME
	fi
	docker-compose -f $DOCKER_COMPOSE_BUILD_PATH push

	if [ "$DOCKER_DELETE_LOCAL_IMAGE" = "true" ]; then
		info "Deleting $DOCKER_IMAGE from local repository"
		docker image rm -f "$IMAGE_TAG"
		if [ "$IMAGE_TAG" != "$DOCKER_IMAGE" ]; then
			docker image rm -f "$DOCKER_IMAGE"
		fi
	fi
}
