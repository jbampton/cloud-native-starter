#!/bin/bash

root_folder=$(cd $(dirname $0); cd ..; pwd)

exec 3>&1

function _out() {
  echo "$(date +'%F %H:%M:%S') $@"
}

function setup() {
  _out Deploying web-api-java-jee
  
  cd ${root_folder}/web-api-java-jee
  kubectl delete -f deployment/kubernetes.yaml
  kubectl delete -f deployment/istio.yaml

  mvn clean
  mvn package

  file="${root_folder}/web-api-java-jee/liberty-opentracing-zipkintracer-1.2-sample.zip"
  if [ -f "$file" ]
  then
	  echo "$file found"
  else
	  curl -L -o $file https://github.com/WASdev/sample.opentracing.zipkintracer/releases/download/1.2/liberty-opentracing-zipkintracer-1.2-sample.zip
  fi
  
  eval $(minikube docker-env)
  docker build -f Dockerfile.previousdownload -t web-api:1 .

  kubectl apply -f deployment/kubernetes.yaml
  kubectl apply -f deployment/istio.yaml

  minikubeip=$(minikube ip)
  nodeport=$(kubectl get svc web-api --output 'jsonpath={.spec.ports[*].nodePort}')
  _out Minikube IP: ${minikubeip}
  _out NodePort: ${nodeport}
  
  _out Done deploying web-api-java-jee
  _out Open the OpenAPI explorer: http://${minikubeip}:${nodeport}/openapi/ui/
}

setup