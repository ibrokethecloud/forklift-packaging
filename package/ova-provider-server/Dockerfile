FROM registry.suse.com/bci/golang:1.25 AS builder
WORKDIR /app
COPY --chown=1001:0 ./ ./
RUN go build -buildvcs=false -ldflags="-w -s" github.com/kubev2v/forklift/cmd/ova-provider-server

FROM registry.suse.com/bci/bci-base:15.7
# Required to be able to get files from within the pod

RUN zypper -n rm container-suseconnect && \
    zypper -n install tar && \
    zypper -n clean -a

COPY --from=builder /app/ova-provider-server /usr/local/bin/ova-provider-server
ENTRYPOINT ["/usr/local/bin/ova-provider-server"]