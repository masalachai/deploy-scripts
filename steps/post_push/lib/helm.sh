ds_post_push() {
	if [ "$1" = "" ]; then
		error "post-push: helm: Too few arguments given to ds_post_push"
	fi

	cd "$1"
	if [ "$KUBERNETES_CLUSTER" = "" ]; then
		error "post-push: helm: no KUBERNETES_CLUSTER value set"
	fi

	if [ "$KUBERNETES_CLUSTER_CONFIG" = "" ]; then
		KUBERNETES_CLUSTER_CONFIG="$KUBERNETES_HOME/$KUBERNETES_CLUSTER.yaml"
	fi

	export KUBECONFIG="$KUBERNETES_CLUSTER_CONFIG"

	if [ "$HELM_DIR" = "" ]; then
		HELM_DIR="$PROJECT_DEPLOY_DIR/environments/$PROJECT_ENVIRONMENT/kubernetes/helm"
	fi

	if [ ! -d "$HELM_DIR" ]; then
		error "Helm chart directory not found at $HELM_DIR"
	fi

	OPERATION=upgrade
	EXISTING_RELEASE=$(helm list | grep $SERVICE_NAME | wc -l)
	if [ $EXISTING_RELEASE -eq 0 ]; then
		OPERATION=install
		INGRESS_CREATE="true"
	fi

	HELM_OPTS=""
	if [ "$HELM_IMAGE" = "" ]; then
		if [ "$DOCKER_IMAGE" != "" ]; then
			HELM_IMAGE=$DOCKER_IMAGE
		fi
	fi

	if [ "$HELM_IMAGE" != "" ]; then
		HELM_IMAGE_REPO="$(echo $HELM_IMAGE | cut -d":" -f1)"
		HELM_IMAGE_TAG="$(echo $HELM_IMAGE | cut -d":" -f2)"
		HELM_OPTS="$HELM_OPTS --set image.repository=$HELM_IMAGE_REPO --set image.tag=$HELM_IMAGE_TAG"
	fi

	if [ -f "$HELM_DIR/override.yaml" ]; then
		HELM_OPTS="$HELM_OPTS -f $HELM_DIR/override.yaml"
	fi

	ds_debug_exec "helm template $HELM_DIR/ --debug $HELM_OPTS"

	debug "helm $OPERATION $SERVICE_NAME $HELM_DIR/ $HELM_OPTS"

	helm $OPERATION $SERVICE_NAME $HELM_DIR/ $HELM_OPTS
}

