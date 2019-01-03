# Kubernetes in a container

## Requirements

- docker installed
- [compose-on-kubernetes](https://github.com/docker/compose-on-kubernetes)
  - present in your `GOPATH`
  - `make IMAGE_REPO_PREFIX=docker/kube-compose- bin/installer`

## Start it

```
make run-helper
```

## Building a node image

Ensure that kubernetes is cloned into `$(GOPATH)/src/k8s.io/kubernetes` with the version you are expecting
To do so, just run `git clone https://github.com/kubernetes/kubernetes $(GOPATH)/src/k8s.io/kubernetes`.

Then, whe you're on the good branch, just run `make build-node`
