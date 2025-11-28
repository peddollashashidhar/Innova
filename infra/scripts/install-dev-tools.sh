#!/usr/bin/env bash
set -euo pipefail

# install-dev-tools.sh
# Interactive helper to install aws-cli v2 and aws-vault on Linux/macOS/WSL.
# By default it prints the actions and asks for confirmation. Use --yes to auto-run.

PROCEED=no
AUTO=no
SKIP_AWS_CLI=no
SKIP_AWS_VAULT=no

while [[ $# -gt 0 ]]; do
  case "$1" in
    --yes|-y) AUTO=yes; shift;;
    --skip-aws-cli) SKIP_AWS_CLI=yes; shift;;
    --skip-aws-vault) SKIP_AWS_VAULT=yes; shift;;
    -h|--help) echo "Usage: $0 [--yes] [--skip-aws-cli] [--skip-aws-vault]"; exit 0;;
    *) echo "Unknown arg: $1" >&2; exit 2;;
  esac
done

OS_NAME=$(uname -s)
ARCH="$(uname -m)"

case "$ARCH" in
  x86_64|amd64) ARCH_TAG=amd64 ;; 
  aarch64|arm64) ARCH_TAG=arm64 ;; 
  *) ARCH_TAG=amd64 ;;
esac

is_command() { command -v "$1" >/dev/null 2>&1; }

confirm() {
  if [[ "$AUTO" == "yes" ]]; then
    return 0
  fi
  read -r -p "$1 (yes/no): " ans
  case "$ans" in
    [yY]|[yY][eE][sS]) return 0 ;;
    *) return 1 ;;
  esac
}

echo "Detected OS: $OS_NAME, ARCH: $ARCH"

if [[ "$SKIP_AWS_CLI" == "no" ]]; then
  echo "\n=== AWS CLI v2 ==="
  if is_command aws; then
    echo "aws is already installed: $(aws --version 2>/dev/null || true)"
  else
    case "$OS_NAME" in
      Linux)
        echo "Will install AWS CLI v2 by downloading package and running the installer (Linux)."
        if confirm "Install AWS CLI v2 now?"; then
          tmpdir=$(mktemp -d)
          pushd "$tmpdir"
          curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-${ARCH_TAG}.zip" -o awscliv2.zip
          unzip -q awscliv2.zip
          sudo ./aws/install
          popd
          rm -rf "$tmpdir"
          echo "aws installed: $(aws --version)"
        else
          echo "Skipping aws-cli installation."
        fi
        ;;
      Darwin)
        echo "macOS detected — will use Homebrew if available, otherwise show manual steps."
        if is_command brew; then
          if confirm "Run 'brew install awscli' now?"; then
            brew install awscli
            echo "aws installed: $(aws --version)"
          fi
        else
          echo "Homebrew not found. Install Homebrew (https://brew.sh/) or run the following manually:"
          echo "curl 'https://awscli.amazonaws.com/AWSCLIV2.pkg' -o 'AWSCLIV2.pkg' && sudo installer -pkg AWSCLIV2.pkg -target /"
        fi
        ;;
      *)
        echo "Unknown OS: $OS_NAME — please install AWS CLI v2 manually from https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"
        ;;
    esac
  fi
fi

if [[ "$SKIP_AWS_VAULT" == "no" ]]; then
  echo "\n=== aws-vault ==="
  if is_command aws-vault; then
    echo "aws-vault already installed: $(aws-vault --version 2>/dev/null || true)"
  else
    case "$OS_NAME" in
      Linux)
        echo "Installing aws-vault binary for Linux ($ARCH_TAG)."
        if confirm "Install aws-vault now?"; then
          latest_url="https://github.com/99designs/aws-vault/releases/latest/download/aws-vault-linux-${ARCH_TAG}"
          sudo curl -fsSL -o /usr/local/bin/aws-vault "$latest_url"
          sudo chmod +x /usr/local/bin/aws-vault
          echo "aws-vault installed to /usr/local/bin/aws-vault"
        else
          echo "Skipping aws-vault installation."
        fi
        ;;
      Darwin)
        if is_command brew; then
          if confirm "Install aws-vault via Homebrew (brew install --cask aws-vault)?"; then
            brew install --cask --no-quarantine aws-vault || brew install aws-vault || true
          fi
        else
          echo "Please install aws-vault manually: https://github.com/99designs/aws-vault#install"
        fi
        ;;
      *)
        echo "For Windows, please install aws-vault via winget or Chocolatey, e.g. 'winget install --id 99designs.aws-vault' or use the binary from releases." ;;
    esac
  fi
fi

echo "\n== Done. Quick checks:"
 if is_command aws; then echo "aws: $(aws --version)"; else echo "aws: not installed"; fi
 if is_command aws-vault; then echo "aws-vault: $(aws-vault --version 2>/dev/null || true)"; else echo "aws-vault: not installed"; fi

echo "\nNOTE: This script performs interactive actions and is designed to be safe. On company laptops you may wish to review commands and get approval before running." 
