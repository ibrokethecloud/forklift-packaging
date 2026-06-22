ROOT              := $(realpath $(dir $(realpath $(firstword $(MAKEFILE_LIST)))))
comma             := ,

# some systems requires opt-in for buildx
DOCKER_BUILDKIT   := 1
export DOCKER_BUILDKIT

ifdef CI
  BOLD  :=
  CYAN  :=
  RESET :=
else
  BOLD  := \033[1m
  CYAN  := \033[36m
  RESET := \033[0m
endif

BANNER = @printf "$(BOLD)$(CYAN)[target: $@]$(RESET)\n"

# Allocate a TTY in dev (for ctrl+c) but not in CI
MK_DOCKER_RUN_OPTS_TTY := $(if $(CI),,-it)
export MK_DOCKER_RUN_OPTS_TTY


# Safely detect a unique system identifier into a variable
MK_SYSTEM_ID := $(strip $(shell \
    if [ -s /etc/machine-id ]; then \
        cat /etc/machine-id 2>/dev/null; \
    elif command -v hostname >/dev/null 2>&1; then \
        hostname 2>/dev/null; \
    else \
        echo -n "unknown"; \
    fi))

# User might have several repos in a host. Distinguish each by using the abs path of the repo
MK_REPO_ID                := $(shell printf '%s' "$(ROOT)$(MK_SYSTEM_ID)" | sha256sum | cut -c1-8)
MK_DOCKER_PROGRESS        ?= plain
MK_DOCKER_PULL            ?= --pull
MK_PACKAGING_IMAGE        := forklift-packaging:$(MK_REPO_ID)
COMPONENT_NAME			  ?= ""

# Legacy dapper env variables
REPO                      ?=
PUSH                      ?=
DRONE_BRANCH              ?=
DRONE_TAG                 ?=
FORKLIFT_TAG              ?= v2.9.2

export MK_DOCKER_PROGRESS MK_DOCKER_PULL MK_REPO_ID
export REPO PUSH DRONE_BRANCH DRONE_TAG COMPONENT_NAME FORKLIFT_TAG

MK_HOST_ARCH ?= $(shell uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/')
ARCH := $(MK_HOST_ARCH)
export MK_HOST_ARCH
export ARCH

DOCKER_BUILD = docker build $(MK_DOCKER_PULL) \
	--progress=$(MK_DOCKER_PROGRESS) \
	--build-arg MK_REPO_ID \
	--build-arg MK_HOST_ARCH \
	--build-arg FORKLIFT_TAG \
	-f $(ROOT)/Dockerfile $(ROOT)

.PHONY: build ci generate package test validate


# ---- Directories ----
$(ROOT)/bin:
	@mkdir -p $@


# ---- Pre-generate version env for container builds (no .git needed inside Docker) ----
# Also handles git worktree checkouts where .git is a pointer file to an external directory.
gen-version-env:
	$(BANNER)
	@bash $(ROOT)/scripts/version > /dev/null


# --- generate-manifests ----
generate-manifests: gen-version-env
	$(BANNER)
	$(DOCKER_BUILD) --target generate-manifests-output --output type=local,dest=.


# ---- Test ----
package-forklift-builder: gen-version-env
	$(BANNER)
	$(DOCKER_BUILD) --target package-forklift-builder -t $(MK_PACKAGING_IMAGE)



package-forklift: package-forklift-builder
	$(BANNER)
	docker run $(MK_DOCKER_RUN_OPTS_TTY) --rm --privileged --network host \
	-e COMPONENT_NAME=$(COMPONENT_NAME) -e PUSH=$(PUSH) -e REPO=$(REPO) \
	    -v /var/run/docker.sock:/var/run/docker.sock \
	    $(MK_PACKAGING_IMAGE) \
	    ./scripts/package-forklift

package-ansible-operator: package-forklift-builder
	$(BANNER)
	docker run $(MK_DOCKER_RUN_OPTS_TTY) --rm --privileged --network host \
	    -v /var/run/docker.sock:/var/run/docker.sock \
		-e PUSH=$(PUSH) -e REPO=$(REPO) \
	    $(MK_PACKAGING_IMAGE) \
	    ./scripts/package-ansible-operator

# ---- Clean ----
clean:
	$(BANNER)
	@rm -rf $(ROOT)/bin
	@docker rmi -f $(MK_PACKAGING_IMAGE) || true

.DEFAULT_GOAL := default

default: generate-manifests

