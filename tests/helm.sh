#!/bin/sh

set -e

SCRIPT_PATH=$(dirname $(readlink -f $0))
. $SCRIPT_PATH/common.sh

copy_deployment_files 'python' $SCRIPT_PATH/resources/django_project "default" "helm"

title 'TEST - editing configs'
cd $COPY_PROJECT_DIR/python-project
SERVICE_NAME="python-deploy-test"
PROJECT_ENVIRONMENT="default"
DEPLOYMENT_DIR="$TEST_WORKING_DIR/$SERVICE_NAME/$PROJECT_ENVIRONMENT"
PROJECT_DEPLOY_DIR="$COPY_PROJECT_DIR/python-project/deploy"
HOST="test-deploy-scripts.dev.finology.com.my"
CERT_SECRET="python-deploy-test-cert-secret"
DOCKER_REPO="dockerhub.finology.com.my/$SERVICE_NAME"
TIMESTAMP=$(date +%Y%m%d%H%M%S)
DOCKER_IMAGE="$DOCKER_REPO:$TIMESTAMP"

	OVERRIDE_CONFIG=$(cat <<-END
image:
  repository: $DOCKER_REPO
  tag: latest
  pullPolicy: Always

imagePullSecrets:
  - name: fincred

fullnameOverride: $SERVICE_NAME

serviceAccount:
  create: false

ingress:
  enabled: true
  annotations:
    kubernetes.io/ingress.class: nginx
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
  hosts:
    - host: $HOST
      paths:
        - path: /
          pathType: ImplementationSpecific
          backend:
            service:
              name: $SERVICE_NAME
              port:
                number: 80
  tls:
    - hosts:
      - $HOST
      secretName: python-deploy-test-cert-secret

END
	)

cp -r $SCRIPT_PATH/../projects/python/template/docker $PROJECT_DEPLOY_DIR/
cp -r $SCRIPT_PATH/../projects/python/template/environments/$PROJECT_ENVIRONMENT/docker $PROJECT_DEPLOY_DIR/environments/$PROJECT_ENVIRONMENT/
printf "$OVERRIDE_CONFIG" > $PROJECT_DEPLOY_DIR/environments/$PROJECT_ENVIRONMENT/kubernetes/helm/override.yaml

printf "\nDEPLOYMENT_DIR=$TEST_WORKING_DIR\nDEPLOYMENT_SERVER=localhost\nDEPLOYMENT_SERVER_USER=$USER\nREPO=file://$COPY_PROJECT_DIR/python-project\nSERVICE_NAME=$SERVICE_NAME\nLINKED_FILES=\nLINKED_DIRS=\"\"\n" >> deploy/app-config.sh
printf "PROJECT_ENVIRONMENT=$PROJECT_ENVIRONMENT\nGIT_BRANCH=master\nPACKAGE=docker\nPUSH=docker\nPOST_PUSH=helm\nKUBERNETES_CLUSTER=dev\nDOCKER_IMAGE=$DOCKER_IMAGE\n" >> deploy/environments/default/config.sh
cat deploy/app-config.sh
cat deploy/environments/default/config.sh
# sed -i "s/apiVersion: networking.k8s.io\/v1beta1/apiVersion: networking\.k8s\.io\/v1/g" $PROJECT_DEPLOY_DIR/environments/$PROJECT_ENVIRONMENT/kubernetes/helm/templates/ingress.yaml
title 'helm: override'
cat "$PROJECT_DEPLOY_DIR/environments/$PROJECT_ENVIRONMENT/kubernetes/helm/override.yaml"
title 'helm: debug template'
helm template "$PROJECT_DEPLOY_DIR/environments/$PROJECT_ENVIRONMENT/kubernetes/helm" --debug -f "$PROJECT_DEPLOY_DIR/environments/$PROJECT_ENVIRONMENT/kubernetes/helm/override.yaml"
title 'TEST - deploying default environment'
rm -rf $TEST_WORKING_DIR

PROJECT_DEPLOY_DIR=$PROJECT_DEPLOY_DIR sh $SCRIPT_PATH/../scripts/deploy.sh default
cd $COPY_PROJECT_DIR
sleep 40
title 'TEST - check web application'
wget "https://$HOST/"
printf 'Checking index page contents ... '
if [ $(grep -c 'The install worked successfully! Congratulations!' index.html) -eq 2 ]; then
	success 'success!'
else
	error 'fail! :('
fi
export KUBECONFIG="$HOME/.kube/dev.yaml"
helm uninstall $SERVICE_NAME
rm -rf $HOME/.kube/sites/dev/letsencrypt-staging/*deploy-scripts.finology.com.my
rm -rf $HOME/.kube/sites/dev/*deploy-scripts.finology.com.my
cd $SCRIPT_PATH/../
rm -rf /tmp/deploy-scripts
