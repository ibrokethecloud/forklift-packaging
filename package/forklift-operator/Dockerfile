FROM gmehta3/harvester-ansible-operator:main-head

WORKDIR /app
COPY operator/requirements.yml requirements.yml
COPY operator/watches.yaml watches.yaml
COPY operator/roles roles
RUN ansible-galaxy collection install -r /app/requirements.yml