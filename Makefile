# VERSION defines the project version for the bundle.
VERSION ?= 0.1.1

# CHANNELS define the bundle channels used in the bundle.
ifdef CHANNELS
BUNDLE_CHANNELS = --channels=$(CHANNELS)
else
BUNDLE_CHANNELS = --channels=stable
endif

# DEFAULT_CHANNEL defines the default channel used in the bundle.
ifdef DEFAULT_CHANNEL
BUNDLE_DEFAULT_CHANNEL = --default-channel=$(DEFAULT_CHANNEL)
else
BUNDLE_DEFAULT_CHANNEL = --default-channel=stable
endif

BUNDLE_METADATA_OPTS = $(BUNDLE_CHANNELS) $(BUNDLE_DEFAULT_CHANNEL)

# OPERATOR_IMAGE_BASE defines the docker.io namespace and part of the image name for remote images.
# This variable is used to construct full image tags for bundle and catalog images.
OPERATOR_IMAGE_BASE ?= quay.io/prismacloud/pcc-operator

# Image URL to use all building/pushing image targets
OPERATOR_IMG ?= $(OPERATOR_IMAGE_BASE):v$(VERSION)

all: help


# The help target prints out all targets with their descriptions organized
# beneath their categories. The categories are represented by '##@' and the
# target descriptions by '##'. The awk commands is responsible for reading the
# entire set of makefiles included in this invocation, looking for lines of the
# file as xyz: ## something, and then pretty-format the target and help. Then,
# if there's a line with ##@ something, that gets pretty-printed as a category.
# More info on the usage of ANSI control characters for terminal formatting:
# https://en.wikipedia.org/wiki/ANSI_escape_code#SGR_parameters
# More info on the awk command:
# http://linuxcommand.org/lc3_adv_awk.php
help: ## Print this text
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[$$()% a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)


############
# OPERATOR #
############

operator-build: ## Build operator image
	docker build -t $(OPERATOR_IMG) --build-arg VERSION=v$(VERSION) .

operator-push: ## Push operator image
	docker push $(OPERATOR_IMG)

deploy: kustomize ## Deploy to cluster specified in ~/.kube/config
	cd config/manager && $(KUSTOMIZE) edit set image controller=$(OPERATOR_IMG)
	$(KUSTOMIZE) build config/deploy | kubectl apply -f -

undeploy: ## Remove from cluster specified in ~/.kube/config
	$(KUSTOMIZE) build config/deploy | kubectl delete -f -


##########
# BUNDLE #
##########

BUNDLE_IMG ?= $(OPERATOR_IMAGE_BASE)-bundle:v$(VERSION)

.PHONY: manifests
manifests: kustomize operator-build operator-push ## Generate manifests and update image reference
	operator-sdk generate kustomize manifests -q
	repo_digest=$$(docker inspect --format '{{ .RepoDigests }}' $(OPERATOR_IMG) | grep -Eo 'quay.io/prismacloud/pcc-operator@sha256:\w{64}') \
	&& scripts/update_csv.rb "$$repo_digest" \
	&& cd config/manager && $(KUSTOMIZE) edit set image controller="$$repo_digest" \

.PHONY: bundle
bundle: manifests ## Generate bundle then validate generated files
	$(KUSTOMIZE) build config/manifests | operator-sdk generate bundle --manifests --version $(VERSION) $(BUNDLE_METADATA_OPTS)
	cd bundle/manifests \
	&& mv pcc-operator.clusterserviceversion.yaml pcc-operator.v$(VERSION).clusterserviceversion.yaml \
	&& mv pcc.paloaltonetworks.com_consoledefenders.yaml consoledefenders.pcc.paloaltonetworks.com.crd.yaml \
	&& mv pcc.paloaltonetworks.com_consoles.yaml consoles.pcc.paloaltonetworks.com.crd.yaml \
	&& mv pcc.paloaltonetworks.com_defenders.yaml defenders.pcc.paloaltonetworks.com.crd.yaml
	operator-sdk bundle validate bundle

.PHONY: bundle-build
bundle-build: ## Build bundle image
	cd bundle && docker build -f bundle.Dockerfile -t $(BUNDLE_IMG) .

.PHONY: bundle-push
bundle-push: ## Push bundle image
	docker push $(BUNDLE_IMG)


###########
# CATALOG #
###########

# A comma-separated list of bundle images (e.g. make catalog-build BUNDLE_IMGS=example.com/operator-bundle:v0.1.0,example.com/operator-bundle:v0.2.0).
# These images MUST exist in a registry and be pull-able.
BUNDLE_IMGS ?= $(BUNDLE_IMG)

# The image tag given to the resulting catalog image (e.g. make catalog-build CATALOG_IMG=example.com/operator-catalog:v0.2.0).
CATALOG_IMG ?= $(OPERATOR_IMAGE_BASE)-catalog:v$(VERSION)

# Set CATALOG_BASE_IMG to an existing catalog image tag to add $BUNDLE_IMGS to that image.
ifneq ($(origin CATALOG_BASE_IMG), undefined)
FROM_INDEX_OPT := --from-index $(CATALOG_BASE_IMG)
endif

.PHONY: catalog-build
catalog-build: opm ## Build a catalog image by adding bundle images to an empty catalog using the operator package manager tool, 'opm'
	$(OPM) index add --container-tool docker --mode semver --tag $(CATALOG_IMG) --bundles $(BUNDLE_IMGS) $(FROM_INDEX_OPT)

.PHONY: catalog-push
catalog-push: ## Push the catalog image
	docker push $(CATALOG_IMG)


############
# BINARIES #
############

OS := $(shell uname -s | tr '[:upper:]' '[:lower:]')
ARCH := $(shell uname -m | sed 's/x86_64/amd64/')

.PHONY: kustomize
KUSTOMIZE = $(shell pwd)/bin/kustomize
kustomize: ## Download kustomize locally if necessary.
ifeq (,$(wildcard $(KUSTOMIZE)))
ifeq (,$(shell which kustomize 2>/dev/null))
	@{ \
	set -e ;\
	mkdir -p $(dir $(KUSTOMIZE)) ;\
	curl -sSLo - https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize/v3.5.4/kustomize_v3.5.4_$(OS)_$(ARCH).tar.gz | \
	tar xzf - -C bin/ ;\
	}
else
KUSTOMIZE = $(shell which kustomize)
endif
endif

.PHONY: opm
OPM = ./bin/opm
opm: ## Download opm locally if necessary.
ifeq (,$(wildcard $(OPM)))
ifeq (,$(shell which opm 2>/dev/null))
	@{ \
	set -e ;\
	mkdir -p $(dir $(OPM)) ;\
	curl -sSLo $(OPM) https://github.com/operator-framework/operator-registry/releases/download/v1.17.5/$(OS)-$(ARCH)-opm ;\
	chmod +x $(OPM) ;\
	}
else
OPM = $(shell which opm)
endif
endif
