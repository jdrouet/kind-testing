build:
	docker build . --tag jdrouet/kind-testing

run: build
	docker run \
		--name turkey-filling \
		--network=host \
		-e KUBE_VERSION=1.11.5 \
		-v $(GOPATH)/src:/go/src \
		-v /var/run/docker.sock:/var/run/docker.sock \
		-v $(HOME)/.kube/kind-config-1.11.5:/root/.kube/kind-config-1.11.5 \
		jdrouet/kind-testing

push:
	docker push jdrouet/kind-testing
