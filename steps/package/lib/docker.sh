ds_package() {
	if [ "$1" = "" ]; then
		error "package: docker: Too few arguments given"
	fi

	copy_dockerfile "$PROJECT_DEPLOY_DIR" $PROJECT_ENVIRONMENT "$1"

	if [ "$DOCKER_IMAGE" = "" ]; then
		TIMESTAMP=$(date +%Y%m%d%H%M%S)
		DOCKER_IMAGE="$(echo $SERVICE_NAME | cut -d"." -f1):$TIMESTAMP"
	fi

	if [ ! -f "$DOCKER_COMPOSE_BUILD_FILE"  ]; then
		DOCKER_COMPOSE_BUILD_NEW=$(cat <<-END
version: '$DOCKER_COMPOSE_YAML_VERSION'

services:
  default:
    image: $DOCKER_IMAGE
    build:
      context: $1
      dockerfile: Dockerfile
      args:
        PROJECT_ENVIRONMENT: $PROJECT_ENVIRONMENT
END
	)

		DOCKER_COMPOSE_BUILD_FILE="$1/docker-compose.build.yml"
		printf "$DOCKER_COMPOSE_BUILD_NEW" > $DOCKER_COMPOSE_BUILD_FILE
	fi

	export PROJECT_ENVIRONMENT="$PROJECT_ENVIRONMENT"
	export APP_DIR="$1"
	export DOCKER_COMPOSE_BUILD_PATH=$DOCKER_COMPOSE_BUILD_FILE
	export DOCKER_IMAGE=$DOCKER_IMAGE

	docker-compose -f "$DOCKER_COMPOSE_BUILD_FILE" $DOCKER_COMPOSE_OPTS build
}
