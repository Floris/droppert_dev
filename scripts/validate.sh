#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: ./scripts/validate.sh [--static-only]

Runs repository checks and, unless --static-only is supplied, builds the
container locally without starting it or contacting production services.
EOF
}

static_only=false
case "${1:-}" in
  "") ;;
  --static-only) static_only=true ;;
  -h|--help)
    usage
    exit 0
    ;;
  *)
    usage >&2
    exit 2
    ;;
esac

if (( $# > 1 )); then
  usage >&2
  exit 2
fi

repo_root="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

required_files=(
  Dockerfile
  README.md
  config/bookmarks.yaml
  config/services.yaml
  config/settings.yaml
  config/widgets.yaml
  public/icons/droppert-mark.svg
  public/images/droppert-grid.svg
)

for path in "${required_files[@]}"; do
  if [[ ! -s "$path" ]]; then
    printf 'Required file is missing or empty: %s\n' "$path" >&2
    exit 1
  fi
done

if grep -RIn $'\t' -- config; then
  printf 'Homepage YAML must use spaces, not tabs.\n' >&2
  exit 1
fi

if python3 -c 'import yaml' >/dev/null 2>&1; then
  python3 - <<'PY'
from pathlib import Path

import yaml

for path in sorted(Path("config").glob("*.yaml")):
    with path.open(encoding="utf-8") as stream:
        yaml.safe_load(stream)
PY
elif command -v ruby >/dev/null 2>&1; then
  ruby -ryaml -e '
    ARGV.each do |path|
      YAML.safe_load(File.read(path), permitted_classes: [], permitted_symbols: [], aliases: false)
    end
  ' config/*.yaml
else
  printf 'Validation requires Python with PyYAML or Ruby with Psych.\n' >&2
  exit 1
fi

python3 - <<'PY'
from pathlib import Path
from xml.etree import ElementTree

for path in sorted(Path("public").rglob("*.svg")):
    ElementTree.parse(path)
PY

grep -Fqx 'COPY --chown=10001:10001 config/ /app/config/' Dockerfile
grep -Fqx 'COPY --chown=10001:10001 public/ /app/public/' Dockerfile
grep -Fqx 'USER 10001:10001' Dockerfile
grep -Fq 'chown -R 10001:10001 /app' Dockerfile

if grep -REh '^[[:space:]]*uses:' .github/workflows \
  | grep -Ev '@[0-9a-f]{40}([[:space:]]|$)'; then
  printf 'GitHub Actions must be pinned to a full commit SHA.\n' >&2
  exit 1
fi

if grep -Eq '\$\{\{ env[.]IMAGE \}\}:(main|latest)' .github/workflows/container.yml; then
  printf 'The release workflow may publish only the immutable full-SHA tag.\n' >&2
  exit 1
fi

if [[ "$static_only" == true ]]; then
  printf 'Static validation passed.\n'
  exit 0
fi

if ! command -v docker >/dev/null 2>&1; then
  printf 'Docker is required for the container build; use --static-only when no container engine is available.\n' >&2
  exit 1
fi

docker build \
  --build-arg "VCS_REF=$(git rev-parse HEAD)" \
  --tag droppert-dev:validation \
  .

printf 'Static validation and container build passed.\n'
