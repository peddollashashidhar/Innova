#!/usr/bin/env bash
set -euo pipefail

# Simple helper to run terraform init -> plan -> apply (interactive)
# Usage: ./deploy-eks.sh [--auto-approve]

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR/infra"

if ! command -v terraform >/dev/null 2>&1; then
  echo "terraform is not installed or not on PATH" >&2
  exit 1
fi

AUTO=0
if [[ "${1:-}" == "--auto-approve" ]]; then
  AUTO=1
fi

terraform init -input=false
terraform plan -out=tfplan -input=false

if [[ "$AUTO" -eq 1 ]]; then
  terraform apply -input=false -auto-approve tfplan
else
  echo
  echo "Terraform plan created at ./tfplan"
  read -r -p "Proceed to apply the plan? (yes/no) " answer
  case "$answer" in
    [yY]|[yY][eE][sS]) terraform apply -input=false tfplan ;;
    *) echo "Aborting without apply" ;;
  esac
fi
