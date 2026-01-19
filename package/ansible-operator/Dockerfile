# This Dockerfile defines the base image for the ansible-operator image.
# It is built with dependencies that take a while to download, thus speeding
# up ansible deploy jobs.

FROM registry.suse.com/bci/bci-base:15.7 AS basebuilder

# Install Rust so that we can ensure backwards compatibility with installing/building the cryptography wheel across all platforms
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"
RUN rustc --version

# Copy python dependencies (including ansible) to be installed using Pipenv
COPY Pipfile* ./
# Copy our local ansible-runner-http replacement module
COPY ansible_runner_http ./ansible_runner_http
# Instruct pip(env) not to keep a cache of installed packages,
# to install into the global site-packages and
# to clear the pipenv cache as well
ENV PIP_NO_CACHE_DIR=1 \
  PIPENV_SYSTEM=1 \
  PIPENV_CLEAR=1
# Ensure fresh metadata rather than cached metadata, install system and pip python deps,
# and remove those not needed at runtime.
RUN set -e \
  && zypper -n ar https://download.opensuse.org/repositories/devel:languages:python:Factory/15.6/devel:languages:python:Factory.repo \
  && zypper -n --gpg-auto-import-keys refresh \
  && zypper -n  install gcc libffi-devel openssl-devel python312-devel \
  && pushd /usr/local/bin && ln -sf ../../bin/python3.12 python3 && popd \
  && python3.12 -m ensurepip --upgrade \
  && pip3.12 install --upgrade pip~=23.3.2 \
  && pip3.12 install pipenv==2023.11.15 \
  && pipenv install --deploy \
  && pip3.12 install ansible_runner_http/ \
  && zypper remove -y gcc libffi-devel openssl-devel python312-devel \
  && zypper -n clean -a 

FROM registry.suse.com/bci/bci-base:15.7
ARG ARCH

# Label this image with the repo and commit that built it, for freshmaking purposes.
ARG GIT_COMMIT=devel
LABEL git_commit=$GIT_COMMIT
ARG VERSION=v1.42.0

RUN mkdir -p /etc/ansible \
  && echo "localhost ansible_connection=local" > /etc/ansible/hosts \
  && echo '[defaults]' > /etc/ansible/ansible.cfg \
  && echo 'roles_path = /opt/ansible/roles' >> /etc/ansible/ansible.cfg 

RUN set -e \
  && zypper -n ar https://download.opensuse.org/repositories/devel:languages:python:Factory/15.6/devel:languages:python:Factory.repo \
  && zypper -n --gpg-auto-import-keys refresh \
  && zypper -n  install python312-devel \
  && zypper -n clean -a \
  && curl -L -o /usr/local/bin/ansible-operator https://github.com/operator-framework/ansible-operator-plugins/releases/download/${VERSION}/ansible-operator_linux_${ARCH} \
  && chmod +x /usr/local/bin/ansible-operator


COPY --from=basebuilder /usr/local/lib64/python3.12/site-packages /usr/local/lib64/python3.12/site-packages
COPY --from=basebuilder /usr/local/lib/python3.12/site-packages /usr/local/lib/python3.12/site-packages
COPY --from=basebuilder /usr/local/bin /usr/local/bin

ENV TINI_VERSION=v0.19.0
RUN curl -o /tini -fSL https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini-${ARCH} \
  && chmod +x /tini && /tini --version


ENV HOME=/opt/ansible \
  USER_NAME=ansible \
  USER_UID=1001

# Ensure directory permissions are properly set
RUN echo "${USER_NAME}:x:${USER_UID}:0:${USER_NAME} user:${HOME}:/sbin/nologin" >> /etc/passwd \
  && mkdir -p ${HOME}/.ansible/tmp \
  && chown -R ${USER_UID}:0 ${HOME} \
  && chmod -R ug+rwx ${HOME}

WORKDIR ${HOME}
USER ${USER_UID}


ENTRYPOINT ["/tini", "--", "/usr/local/bin/ansible-operator", "run", "--watches-file=./watches.yaml"]
