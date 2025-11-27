#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR/infra"

if ! command -v terraform >/dev/null 2>&1; then
  echo "terraform is not installed or not on PATH" >&2
  exit 1
fi

read -r -p "This will destroy resources managed by infra/. Are you sure? (yes/no) " answer
case "$answer" in
  [yY]|[yY][eE][sS]) terraform init -input=false && terraform destroy -auto-approve ;;
  *) echo "Aborting destroy" ;;
esac
