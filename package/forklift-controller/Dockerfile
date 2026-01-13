FROM registry.suse.com/bci/bci-base:15.7
# Required to be able to get files from within the pod

RUN zypper -n rm container-suseconnect && \
    zypper -n install tar && \
    zypper -n clean -a

COPY forklift-controller /usr/local/bin/forklift-controller
ENTRYPOINT ["/usr/local/bin/forklift-controller"]