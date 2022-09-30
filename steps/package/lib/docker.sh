ds_package() {
	if [ "$1" = "" ]; then
		error "package: docker: Too few arguments given"
	fi

	cd "$1"

	copy_docker_files "$PROJECT_DEPLOY_DIR" $PROJECT_ENVIRONMENT "$1"

	TAG=$(grep 'image:' docker-compose.yml | wc -l)
	ENV_FILE_PRESENT="true"
	COMPOSE_ENV_FILE=$(awk '/env_file:/,/\n/' docker-compose.yml | awk '{printf $2}')

	if [ "$COMPOSE_ENV_FILE" != "" ] && [ ! -f "$COMPOSE_ENV_FILE" ]; then
		ENV_FILE_PRESENT="false"
		touch "$COMPOSE_ENV_FILE"
	fi

	if [ $TAG -eq 0 ]; then
		TIMESTAMP=$(date +%Y%m%d%H%M%S)
		SRV_NAME=$(echo $SERVICE_NAME | cut -d"." -f1)
		TAG="$SRV_NAME-$PROJECT_ENVIRONMENT:$TIMESTAMP"
		BUILDSTR=$(grep 'build:' docker-compose.yml)
		if [ "$BUILDSTR" != "" ]; then
			sed -i "s/build\:/image\: $TAG\n$BUILDSTR/g" docker-compose.yml
		fi
		ds_debug_cat "docker-compose.yml"
	else
		TAG=$(grep 'image:' docker-compose.yml | awk '{print $2}')
	fi

	docker-compose build $DOCKER_COMPOSE_OPTS

	if [ "$ENV_FILE_PRESENT" = "false" ]; then
		rm -rf "$COMPOSE_ENV_FILE"
	fi

	cleanup_docker_files
}
