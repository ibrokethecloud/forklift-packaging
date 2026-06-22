FROM registry.suse.com/bci/golang:1.25 AS builder

ARG MK_HOST_ARCH
ENV ARCH=$MK_HOST_ARCH
ENV GOTOOLCHAIN=auto
ARG CONTAINER_WORKDIR=/go/src/github.com/harvester/forklift-packaging

## setup environment for packaging of forklift
RUN go install sigs.k8s.io/controller-tools/cmd/controller-gen@v0.17.0 && \
    zypper in -y docker

ENV HOME=/go/src/github.com/harvester/forklift-packaging

# ---- base ----
FROM builder AS base
WORKDIR /go/src/github.com/harvester/forklift-packaging
ARG FORKLIFT_TAG
# to exclude some files, add them in .dockerignore
COPY . .
RUN ./scripts/checkout

# ---- staging-forklift ----
FROM base AS staging-forklift

# ---- generate ----
FROM staging-forklift AS generate-manifests
ARG MK_REPO_ID

RUN --mount=type=cache,target=/go/pkg/mod,id=forklift-packaging-go-mod-${MK_REPO_ID} \
    --mount=type=cache,target=/go/src/github.com/harvester/forklift-packaging/.cache/go-build,id=forklift-packaging-go-build-${MK_REPO_ID} \
    ./scripts/generate-manifests

# ---- generate-crds ----
FROM scratch AS generate-manifests-output
COPY --from=generate-manifests /go/src/github.com/harvester/forklift-packaging/crds/ /crds/

# ---- package-forklift ----
FROM staging-forklift AS package-forklift-builder
