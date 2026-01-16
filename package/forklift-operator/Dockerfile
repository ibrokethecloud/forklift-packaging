FROM registry.suse.com/bci/bci-base:15.7

ENV VERSION=v1.42.0
ARG ARCH

RUN zypper -n addrepo https://download.opensuse.org/repositories/systemsmanagement:ansible/15.7/systemsmanagement:ansible.repo && \
    zypper -n --gpg-auto-import-keys refresh && \
    zypper -n rm container-suseconnect && \
    zypper -n install ansible && \
    zypper -n clean -a && \
    echo "found arch: $ARCH" && \
    curl -L -o /usr/local/bin/ansible-operator https://github.com/operator-framework/ansible-operator-plugins/releases/download/${VERSION}/ansible-operator_linux_${ARCH} && \
    chmod +x /usr/local/bin/ansible-operator

ENV TINI_VERSION=v0.19.0
RUN curl -o /tini -fSL https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini-${ARCH} \
  && chmod +x /tini && /tini --version

WORKDIR /app
COPY operator/requirements.yml requirements.yml
COPY operator/watches.yaml watches.yaml
COPY operator/roles roles
RUN ansible-galaxy collection install -r /app/requirements.yml
ENTRYPOINT ["/tini", "--", "/usr/local/bin/ansible-operator", "run", "--watches-file=./watches.yaml"]