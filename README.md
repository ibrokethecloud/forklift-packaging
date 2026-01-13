# forklift-packaging

Repo contains manifests to allow re-packaging of forklift using dapper


Input fields

| Name | Description |
|-------|-----------------------------------------------------------------------------|
| TAG | TAG to be provided for generated artifacts, defaults to `$branch-head` |
| FORKLIFT_TAG |  Forklift tag to be checked out from repo before packaging components |
| REPO | parent repo for images, defaults to `rancher` |

