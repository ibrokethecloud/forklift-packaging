FROM registry.suse.com/bci/golang:1.25 AS builder
WORKDIR /app
COPY ./ ./
RUN zypper -n install python && \
    ln -s /usr/bin/python3 /usr/bin/python
WORKDIR /app/cmd/vsphere-xcopy-volume-populator
RUN go mod download && go mod verify

RUN make build
RUN make vmkfstools-wrapper
RUN ls -l /app/cmd/vsphere-xcopy-volume-populator/vmkfstools-wrapper
FROM registry.suse.com/bci/bci-base:15.7
# Required to be able to get files from within the pod

COPY --from=builder /app/cmd/vsphere-xcopy-volume-populator/bin/vsphere-xcopy-volume-populator \
    /bin/vsphere-xcopy-volume-populator

COPY --from=builder /app/cmd/vsphere-xcopy-volume-populator/vmkfstools-wrapper/vmkfstools-wrapper.vib \
    /bin/vmkfstools-wrapper.vib
COPY --from=builder /app/cmd/vsphere-xcopy-volume-populator/vmkfstools-wrapper/vib-install-playbook.yaml \
    /bin/vib-install-playbook.yaml
COPY --from=builder /app/cmd/vsphere-xcopy-volume-populator/vmkfstools-wrapper/esxi_hosts.yaml \
    /bin/esxi_hosts.yaml

ENTRYPOINT ["/bin/vsphere-xcopy-volume-populator"]