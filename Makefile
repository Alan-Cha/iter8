# Image URL to use all building/pushing image targets
IMG ?= iter8-controller:latest

all: manager

# Build manager binary
manager: generate fmt vet
	go build -o bin/manager github.com/iter8-tools/iter8-controller/cmd/manager

# Run against the Kubernetes cluster configured in $KUBECONFIG or ~/.kube/config
run: generate fmt vet load
	go run ./cmd/manager/main.go

# Generate iter8 crds and rbac manifests
manifests:
	go run vendor/sigs.k8s.io/controller-tools/cmd/controller-gen/main.go crd \
	  paths=./pkg/apis/... output:crd:dir=./install/helm/iter8-controller/templates/crds
	./hack/crd_fix.sh

# Prepare Kubernetes cluster for iter8 (running in cluster or locally):
#   install CRDs
#   install configmap/iter8-metrics is defined in namespace iter8 (creating namespace if needed)
load: manifests
	helm template install/helm/iter8-controller \
	  --name iter8-controller \
	  -x templates/default/namespace.yaml \
	  -x templates/crds/iter8.tools_experiments.yaml \
	  -x templates/metrics/iter8_metrics.yaml \
	  -x templates/notifier/iter8_notifiers.yaml\
	| kubectl apply -f -

# Deploy controller to the Kubernetes cluster configured in $KUBECONFIG or ~/.kube/config
deploy: manifests
	helm template install/helm/iter8-controller \
	  --name iter8-controller \
	  --set image.repository=`echo ${IMG} | cut -f1 -d':'` \
	  --set image.tag=`echo ${IMG} | cut -f2 -d':'` \
	| kubectl apply -f -

# Run go fmt against code
fmt:
	go fmt ./pkg/... ./cmd/...

# Run go vet against code
vet:
	go vet ./pkg/... ./cmd/...

# Generate code
generate:
ifndef GOPATH
	$(error GOPATH not defined, please define GOPATH. Run "go help gopath" to learn more about GOPATH)
endif
	go generate ./pkg/... ./cmd/...

# Build the docker image
docker-build:
	docker build . -t ${IMG}

# Push the docker image
docker-push:
	docker push ${IMG}

build-default: manifests
	echo '# Generated by make build-default; DO NOT EDIT' > install/iter8-controller.yaml
	helm template install/helm/iter8-controller \
   		--name iter8-controller \
	>> install/iter8-controller.yaml
	echo '# Generated by make build-default; DO NOT EDIT' > install/iter8-controller-telemetry-v2.yaml
	helm template install/helm/iter8-controller \
   		--name iter8-controller \
			--set istioTelemetry=v2 \
 	>> install/iter8-controller-telemetry-v2.yaml

.PHONY: changelog
changelog:
	@sed -n '/$(ver)/,/=====/p' CHANGELOG | grep -v $(ver) | grep -v "====="

tests:
	go test ./test/.
	test/e2e/e2e.sh --skip-setup
