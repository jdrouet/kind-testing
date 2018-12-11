#!/bin/bash

# Requirements:
# - docker installed
# - compose-on-kubernetes
#   - present in your GOPATH
#   - make IMAGE_REPO_PREFIX=docker/kube-compose-  bin/installer
# - kind installed

# You can monitor the execution of the script with 
# KUBECONFIG="$(kind get kubeconfig-path --name=testing)" watch kubectl get all --all-namespaces

function until_not_empty {
  while true; do
    result=$(eval $1)
    if [[ ! -z "$result" ]]; then
      echo "COMPLETE!"
      break
    fi
    sleep 1
  done
}

function until_empty {
  while true; do
    result=$(eval $1)
    if [[ -z "$result" ]]; then
      echo "COMPLETE!"
      break
    fi
    sleep 1
  done
}

function wait_for_pod_running {
  until_not_empty "kubectl get all --all-namespaces | grep \"$1\" | grep \"1/1\""
}

function wait_for_everything_up {
  until_empty "kubectl get all --all-namespaces | grep \"0/1\""
}

compose_on_kube_path="$GOPATH/src/github.com/docker/compose-on-kubernetes"
kind_cluster_name=testing

kind delete cluster --name=${kind_cluster_name}
kind create cluster --name=${kind_cluster_name}
export KUBECONFIG="$(kind get kubeconfig-path --name="${kind_cluster_name}")"

kubectl cluster-info

kubectl create namespace tiller
kubectl -n kube-system create serviceaccount tiller
kubectl -n kube-system create clusterrolebinding tiller --clusterrole cluster-admin --serviceaccount kube-system:tiller
helm init --service-account tiller

wait_for_pod_running "po/etcd-kind-testing-control-plane"

helm install --name my-etcd-operator stable/etcd-operator

wait_for_pod_running "po/my-etcd-operator-etcd-operator-etcd-backup-operator"
wait_for_pod_running "po/my-etcd-operator-etcd-operator-etcd-operator"
wait_for_pod_running "po/my-etcd-operator-etcd-operator-etcd-restore-operator"

kubectl apply -f my-etcd.yml

wait_for_pod_running "po/compose-etcd"

$compose_on_kube_path/bin/installer -etcd-servers=http://compose-etcd-client.default.svc:2379 -tag=v0.4.16

wait_for_pod_running "po/compose-api"
wait_for_everything_up

DOCKER_STACK_ORCHESTRATOR=kubernetes docker version

docker stack deploy smurf -c docker-compose.yml --orchestrator=kubernetes

wait_for_pod_running "po/web-"

# service_ip=$(kubectl get service web-published -o jsonpath='{.spec.clusterIP}')

# curl http://$service_ip/
