# forklift-packaging

Repo contains manifests to allow re-packaging of forklift using dapper


Input fields

| Name | Description |
|-------|-----------------------------------------------------------------------------|
| TAG | TAG to be provided for generated artifacts, defaults to `$branch-head` |
| FORKLIFT_TAG |  Forklift tag to be checked out from repo before packaging components |
| REPO | parent repo for images, defaults to `rancher` |
| COMPONENT_NAME | used in package-forklift to quickly package a specific component, default behaviour is to package all available components |



The repo contains all the manifests needed for repackaging upstream forklift with sles bcl images.

For now all packaging has been validated against upstream forklift v2.9.2

Please copy `$HOME/.docker` to the repo directory to ensure images can be pushed successfully to docker repo.

### Ansible Operator
To get start we first need to package a base ansible operator image

```
# Override REPO and TAG by passing corresponding tags
make package-ansible-operator
```


will build a local ansible-operator image tagged `rancher/harvester-ansible-operator:main-head` which is used by the `forklift-operator` image


## Forklift operator
Packaging of `forklift-operator` uses the ansible operator image generated from the previous step.

The ansible operator leverages a watches.yaml and an ansible role to run when the watched object is created.

The packaging patches the upstream forkliftcontroller role to fix minor issues with resource creation when cluster is not an openshift cluster. In addition, the watches.yml also fixes the GC logic, when a `forkliftcontroller` object is deleted to ensure all `forklift-operator` managed objects are removed from the cluster.

To build

```
PUSH=true REPO=gmehta3 FORKLIFT_TAG=v2.9.2 COMPONENT_NAME=forklift-operator make package-forklift
```

## Forklift api

```
PUSH=true REPO=gmehta3 FORKLIFT_TAG=v2.9.2 COMPONENT_NAME=forklift-api make package-forklift
```

## Forklift controller

```
PUSH=true REPO=gmehta3 FORKLIFT_TAG=v2.9.2 COMPONENT_NAME=forklift-controller make package-forklift
```

## Openstack populator

```
PUSH=true REPO=gmehta3 FORKLIFT_TAG=v2.9.2 COMPONENT_NAME=openstack-populator make package-forklift
```


## Openstack populator

```
PUSH=true REPO=gmehta3 FORKLIFT_TAG=v2.9.2 COMPONENT_NAME=openstack-populator make package-forklift
```

## ova provider server

```
PUSH=true REPO=gmehta3 FORKLIFT_TAG=v2.9.2 COMPONENT_NAME=ova-provider-server make package-forklift
```

## ovirt populator

```
PUSH=true REPO=gmehta3 FORKLIFT_TAG=v2.9.2 COMPONENT_NAME=ovirt-populator make package-forklift
```

## populator controller

```
PUSH=true REPO=gmehta3 FORKLIFT_TAG=v2.9.2 COMPONENT_NAME=populator-controller make package-forklift
```

## validation

```
PUSH=true REPO=gmehta3 FORKLIFT_TAG=v2.9.2 COMPONENT_NAME=validation make package-forklift
```

## virt-v2v

```
PUSH=true REPO=gmehta3 FORKLIFT_TAG=v2.9.2 COMPONENT_NAME=virt-v2v make package-forklift
```

## vsphere-xcopy-populator

```
PUSH=true REPO=gmehta3 FORKLIFT_TAG=v2.9.2 COMPONENT_NAME=vsphere-xcopy-populator make package-forklift
```

Once ansible-operator image has been build, all images can be built by simply skipping `COMPONENT_NAME` variable

```
PUSH=true REPO=gmehta3 FORKLIFT_TAG=v2.9.2 make package-forklift
```

# Deploying

Before deploying please ensure `cert-manager` is deployed to the target harvester cluster

```
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.19.2/cert-manager.yaml
```

Once cert-manager is up and running, the forklift operator can be deployed by using the helm chart available in `forklift-operator` directory


```
kubectl create ns forklift
cd forklift-operator
helm upgrade --install forklift-operator . -n forklift
```

This should install the `forklift-operator` in the `forklift` namespace

Once the operator is running, we can deploy `forklift` components by creating the `forkliftcontroller` cr

```
apiVersion: forklift.konveyor.io/v1beta1
kind: ForkliftController
metadata:
  name: forklift-controller
spec:
  feature_ui_plugin: "false"
```