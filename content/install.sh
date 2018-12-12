#!/bin/bash

# set -x

# Requirements:
# - docker installed
# - compose-on-kubernetes
#   - present in your GOPATH
#   - make IMAGE_REPO_PREFIX=docker/kube-compose-  bin/installer
# - kind installed

# You can monitor the execution of the script with 
# KUBECONFIG="$(kind get kubeconfig-path --name=testing)" watch kubectl get all --all-namespaces

function wait_for {
  while true; do
    result=$(eval $1)
    if [[ ! -z "$result" ]]; then
      echo "COMPLETE!"
      break
    fi
    sleep 1
  done
}

function wait_for_pod_running {
  wait_for "kubectl get all --all-namespaces 2>/dev/null | grep $1 | grep \"1/1\""
}

function wait_for_everything_up {
  while true; do
    result=$(kubectl get all --all-namespaces 2>/dev/null | grep "0/1")
    if [[ ! -z "$result" ]]; then
      echo "COMPLETE!"
      break
    fi
    sleep 1
  done
}

compose_on_kube_path="$GOPATH/src/github.com/docker/compose-on-kubernetes"
kind_cluster_name=$1

##

# echo "🐳 compiling compose on kube installer"
# current_path=$(pwd)

# cd $compose_on_kube_path
# make IMAGE_REPO_PREFIX=docker/kube-compose- bin/installer
# cd $current_path

##

echo "🐳 cleaning existing cluster"
kind delete cluster --name=${kind_cluster_name}

echo "🐳 creating new cluster"
kind create cluster --name=${kind_cluster_name}
export KUBECONFIG="$(kind get kubeconfig-path --name="${kind_cluster_name}")"

kubectl cluster-info

echo "🐳 creating tiller config"
kubectl create namespace tiller
kubectl -n kube-system create serviceaccount tiller
kubectl -n kube-system create clusterrolebinding tiller --clusterrole cluster-admin --serviceaccount kube-system:tiller

echo "🐳 starting helm"
helm init --service-account tiller

wait_for_pod_running "pod/etcd-kind-testing-control-plane"
wait_for_pod_running "pod/tiller-deploy"

echo "🐳 starting etcd"
helm install --name my-etcd-operator stable/etcd-operator

wait_for_pod_running "pod/my-etcd-operator-etcd-operator-etcd-backup-operator"
wait_for_pod_running "pod/my-etcd-operator-etcd-operator-etcd-operator"
wait_for_pod_running "pod/my-etcd-operator-etcd-operator-etcd-restore-operator"

echo "🐳 preparing storage"
docker exec -it "kind-${kind_cluster_name}-control-plane" mkdir /tmp/storage

kubectl delete storageclass standard
kubectl apply -f hostpath-provisioner.yml

echo "🐳 preparing etcd"
kubectl apply -f my-etcd.yml

wait_for_pod_running "pod/compose-etcd"
wait_for_pod_running "pod/hostpath-provisioner"

echo "🐳 installing compose on kube"
$compose_on_kube_path/bin/installer -etcd-servers=http://compose-etcd-client.default.svc:2379 -tag=v0.4.16

wait_for_pod_running "pod/compose-api"
wait_for_everything_up

echo "🐳 You should now run export KUBECONFIG=\"\$HOME/.kube/kind-config-${kind_cluster_name}\""
