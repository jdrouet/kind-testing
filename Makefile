build:
	docker build . --tag kind-testing

run: build
	docker run \
		--name turkey-filling \
		--network=host \
		-v $(GOPATH)/src:/go/src \
		-v /var/run/docker.sock:/var/run/docker.sock \
		-v $(HOME)/.kube/kind-config-testing:/root/.kube/kind-config-testing \
		kind-testing
