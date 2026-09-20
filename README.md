# droppert.dev

`droppert.dev` is the landing dashboard for the Droppert tooling suite, powered by [Homepage](https://gethomepage.dev/).

## Included links

- `json.droppert.dev`
- `xml.droppert.dev`
- `diff.droppert.dev`
- `convert.droppert.dev`

## Local development

Run the bounded repository validation and container build:

```bash
./scripts/validate.sh
```

The command builds the image but does not start it or contact production
services. To inspect the dashboard locally after validation:

```bash
docker run --rm -p 3000:3000 droppert-dev:validation
```

Then open `http://localhost:3000`.

## Project structure

```text
droppert_dev/
|-- config/
|-- public/
|-- .github/
|-- scripts/
|-- Dockerfile
`-- README.md
```

## Deployment

Pull requests validate the repository and build the image for `linux/amd64`
and `linux/arm64` without publishing it. A verified push to `main` publishes:

```text
ghcr.io/floris/droppert_dev:sha-<full-git-sha>
```

The immutable full-SHA tag is the only published tag and is never overwritten
by a workflow rerun. Its OCI metadata records the repository source and exact
Git revision. Mutable `main` and `latest` aliases are deliberately unsupported;
the deployment must migrate from any existing `main` reference to the full-SHA
tag.

Do not rerun the removed historical `Build and Push Docker Image` workflow.
Runs created from commits that still contain that legacy workflow can publish
mutable `main` or `latest` aliases. The current workflow cannot technically
prevent a historical workflow definition from being rerun, so deployments must
not rely on those aliases.

The live Kubernetes manifests are managed in the separate `website-k8s`
repository. Updating this repository never deploys directly: after the image
is published, update both the application workload and any related jobs in
`website-k8s` to the same immutable tag and let ArgoCD reconcile it.

## Container Runtime

The dashboard image is built to run as fixed non-root UID/GID `10001`.
It prepares `/app/config`, `/app/public`, and `/app/config/logs` so the
Kubernetes deployment can safely enforce `runAsNonRoot`, `runAsUser`, and
`runAsGroup`.

On the software-factory host, where access to a container socket is forbidden,
run only the static portion:

```bash
./scripts/validate.sh --static-only
```
