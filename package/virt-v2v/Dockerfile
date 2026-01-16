FROM registry.opensuse.org/opensuse/bci/golang:1.25 AS builder
WORKDIR /app
COPY  --chown=1001:0 ./ ./
RUN zypper -n in libvirt-devel
RUN go build -ldflags="-w -s" -o virt-v2v-monitor ./cmd/virt-v2v-monitor/virt-v2v-monitor.go
RUN go build -ldflags="-w -s" -o image-converter ./cmd/image-converter/image-converter.go
RUN go build -ldflags="-w -s" -o virt-v2v-wrapper ./cmd/virt-v2v/entrypoint.go

## Eventually change this to BCI based images
FROM quay.io/fedora/fedora:41
RUN rm /etc/pki/tls/fips_local.cnf && \
    echo -e '[fips_sect]\ntls1-prf-ems-check = 0\nactivate = 1' > /etc/pki/tls/fips_local.cnf && \
    sed -i '/^\\[ crypto_policy \\]/a Options=RHNoEnforceEMSinFIPS' /etc/pki/tls/openssl.cnf

ENV LIBGUESTFS_DEBUG=1 LIBGUESTFS_TRACE=1

RUN mkdir /disks && \
    source /etc/os-release && \
    dnf install -y \
        virt-v2v && \
    dnf clean all

RUN dnf install -y https://kojihub.stream.centos.org/kojifiles/packages/virtio-win/1.9.40/1.el9/noarch/virtio-win-1.9.40-1.el9.noarch.rpm


# Missing `libguestfs-winsupport` in the Fedora packages, this is not needed for Fedora as the v2v uses ntfs-3g
RUN dnf -y install btrfs libguestfs libguestfs-appliance libguestfs-xfs qemu-img supermin && \
        depmod $(ls /lib/modules/ |tail -n1)

# Create tarball for the appliance.
#
# LIBGUESTFS_BACKEND=direct is required to work around the following bug:
# https://issues.redhat.com/browse/RHEL-104684
# and it can be removed when that bug gets fixed.
#
# It is also required during contianer runtime to work around the following bug:
# https://issues.redhat.com/browse/RHEL-105490
ENV LIBGUESTFS_BACKEND=direct

RUN mkdir -p /usr/lib64/guestfs/appliance && \
        cd /usr/lib64/guestfs/appliance && \
        libguestfs-make-fixed-appliance . && \
        qemu-img convert -c -O qcow2 root root.qcow2 && \
        mv -vf root.qcow2 root && \
        tar -cvf /libguestfs-appliance.tar /usr/lib64/guestfs/appliance

COPY --from=builder /app/virt-v2v-monitor /usr/local/bin/virt-v2v-monitor

COPY --from=builder /app/image-converter /usr/local/bin/image-converter

COPY --from=builder /app/virt-v2v-wrapper /usr/bin/virt-v2v-wrapper

ENTRYPOINT ["/usr/bin/virt-v2v-wrapper"]