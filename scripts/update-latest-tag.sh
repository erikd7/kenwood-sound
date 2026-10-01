#!/bin/bash
set -euo pipefail

REMOTE="${1:-origin}"
TAG_NAME="${2:-latest}"

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Error: this script must run inside a git repository." >&2
  exit 1
fi

git fetch --tags --force "$REMOTE"
git tag -f "$TAG_NAME" HEAD
git push "$REMOTE" "refs/tags/$TAG_NAME" --force

echo "Updated $REMOTE/$TAG_NAME to $(git rev-parse --short HEAD)"
