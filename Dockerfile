FROM golang:1.10.5-stretch

RUN go get sigs.k8s.io/kind && \
  go get github.com/docker/compose-on-kubernetes

RUN apt-get update && \
  apt-get install -y apt-transport-https && \
  curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - && \
  echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | tee -a /etc/apt/sources.list.d/kubernetes.list && \
  apt-get update && \
  apt-get install -y kubectl && \
  rm -rf /var/lib/apt/lists/*

RUN curl https://raw.githubusercontent.com/helm/helm/master/scripts/get | bash

RUN go get github.com/docker/cli/cmd/docker

COPY content /scripts

WORKDIR /scripts

ENTRYPOINT ["/scripts/install.sh"]
CMD ["testing"]
