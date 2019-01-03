CLUSTER_NAME ?= testing
KUBE_VERSION ?= 1.11.5

build-helper:
	docker build helper --tag jdrouet/kind-helper

run-helper: build
	docker run \
		--name kind-helper \
		--network=host \
		-e KUBE_VERSION=$(KUBE_VERSION) \
		-e CLUSTER_NAME=$(CLUSTER_NAME) \
		-v $(GOPATH)/src:/go/src \
		-v /var/run/docker.sock:/var/run/docker.sock \
		-v $(HOME)/.kube/kind-config-$(CLUSTER_NAME):/root/.kube/kind-config-$(CLUSTER_NAME) \
		jdrouet/kind-helper

push-helper:
	docker push jdrouet/kind-helper

build-node:
	kind build node-image --image jdrouet/kindest-node:$(KUBE_VERSION)
