#!/usr/bin/env bash
set -euo pipefail

# refresh-aws-creds.sh
# Small helper to refresh/establish AWS credentials for local dev.
# Supports two modes: aws-vault and aws SSO (AWS CLI v2).
# Usage:
#  ./refresh-aws-creds.sh --profile <profile> --mode aws-vault -- <command...>
#  ./refresh-aws-creds.sh --profile <profile> --mode sso -- <command...>
# If no command is provided, opens a sub-shell with credentials.

show_help() {
  cat <<EOF
Usage: $0 --profile <profile> --mode aws-vault|sso [-- <command>]

Examples:
  # start an interactive shell with aws-vault creds
  ./refresh-aws-creds.sh --profile dev-user --mode aws-vault

  # run terraform plan inside aws-vault context
  ./refresh-aws-creds.sh --profile dev-user --mode aws-vault -- terraform plan

  # login via AWS SSO and run a command using the named profile
  ./refresh-aws-creds.sh --profile sso-profile --mode sso -- aws sts get-caller-identity
EOF
}

PROFILE=""
MODE=""

if [[ $# -eq 0 ]]; then
  show_help
  exit 1
fi

while [[ $# -gt 0 ]]; do
  case "$1" in
    --profile)
      PROFILE="$2"; shift 2;;
    --mode)
      MODE="$2"; shift 2;;
    --)
      shift; break;;
    -h|--help)
      show_help; exit 0;;
    *)
      echo "Unknown arg: $1" >&2; show_help; exit 2;;
  esac
done

if [[ -z "$PROFILE" || -z "$MODE" ]]; then
  echo "--profile and --mode are required" >&2
  show_help
  exit 2
fi

CMD=("$@")

case "$MODE" in
  aws-vault)
    if ! command -v aws-vault >/dev/null 2>&1; then
      echo "aws-vault not found in PATH. Install it first: https://github.com/99designs/aws-vault" >&2
      exit 3
    fi

    if [[ ${#CMD[@]} -eq 0 ]]; then
      echo "Launching interactive shell with aws-vault profile: $PROFILE"
      aws-vault exec "$PROFILE" -- bash
    else
      echo "Running: ${CMD[*]} using aws-vault profile: $PROFILE"
      aws-vault exec "$PROFILE" -- "${CMD[*]}"
    fi
    ;;

  sso)
    if ! command -v aws >/dev/null 2>&1; then
      echo "AWS CLI not found in PATH. Install aws-cli v2 and configure SSO profile" >&2
      exit 3
    fi

    echo "Logging into AWS SSO profile: $PROFILE"
    aws sso login --profile "$PROFILE"

    # When using SSO profiles, aws CLI honors the profile by passing --profile
    if [[ ${#CMD[@]} -eq 0 ]]; then
      echo "No command provided — opening a sub-shell with AWS profile $PROFILE available via --profile (use --profile to pass to CLI calls)."
      echo "Tip: run 'aws --profile $PROFILE sts get-caller-identity' to check creds"
      # Open a shell that keeps PROFILE variable so the user can easily use --profile
      PS1="(aws-sso:$PROFILE) \w$ " bash
    else
      echo "Running: ${CMD[*]} using AWS CLI profile: $PROFILE"
      aws --profile "$PROFILE" ${CMD[*]}
    fi
    ;;

  *)
    echo "Unknown mode: $MODE. Use aws-vault or sso." >&2
    exit 2
    ;;
esac
