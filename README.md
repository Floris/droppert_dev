# droppert.dev

`droppert.dev` is the landing dashboard for the Droppert tooling suite, powered by [Homepage](https://gethomepage.dev/).

## Included links

- `json.droppert.dev`
- `diff.droppert.dev`
- `convert.droppert.dev`

## Local development

Build and run the dashboard locally:

```bash
docker build -t droppert-dev .
docker run --rm -p 3000:3000 droppert-dev
```

Then open `http://localhost:3000`.

## Project structure

```text
droppert_dev/
|-- config/
|-- public/
|-- .github/
|-- Dockerfile
`-- README.md
```

## Deployment

The live Kubernetes manifests are managed in `../website-k8s`.

## Container Runtime

The dashboard is deployed with a non-root runtime in Kubernetes. The cluster
manifests also provide a writable log directory at `/app/config/logs` for the
Homepage container.
