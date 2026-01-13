FROM registry.suse.com/bci/bci-base:15.7
# Required to be able to get files from within the pod

RUN zypper -n rm container-suseconnect && \
    zypper -n install tar && \
    zypper -n clean -a

COPY openstack-populator /usr/local/bin/openstack-populator
ENTRYPOINT ["/usr/local/bin/openstack-populator"]