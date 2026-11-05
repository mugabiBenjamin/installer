#!/usr/bin/env bash
# /opt/tools/installer/managers/golang.sh
# Go compiler installer, GOPATH initialization, and PATH priority setup

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/config/defaults.sh"
source "${SCRIPT_DIR}/lib/log.sh"
source "${SCRIPT_DIR}/lib/env.sh"
source "${SCRIPT_DIR}/lib/trap.sh"

install_golang() {
  log "Setting up Go (latest)..."
  local version
  version=$(curl -fsSL "https://go.dev/VERSION?m=text" | head -1) || true

  if [ -z "${version:-}" ]; then
    warn "Could not resolve latest Go version — skipping Go install"
    return 1
  fi

  local installed_version=""
  if [ -x /usr/local/go/bin/go ]; then
    installed_version=$(/usr/local/go/bin/go version 2>/dev/null | awk '{print $3}')
  fi

  if [ "${installed_version:-}" != "${version}" ]; then
    log "Installing Go ${version}..."
    local tmp_go="/tmp/go.tar.gz"
    register_tmp "${tmp_go}"
    wget -q --show-progress -O "${tmp_go}" "https://go.dev/dl/${version}.linux-amd64.tar.gz" \
      && sudo rm -rf /usr/local/go \
      && sudo tar -C /usr/local -xzf "${tmp_go}" \
      || warn "Failed to extract and install Go"
  else
    log "Go ${version} already installed — skipping."
  fi

  if [ ! -x /usr/local/go/bin/go ]; then
    err "Go installation failed — /usr/local/go/bin/go not found. Cannot continue."
  fi

  export GOPATH="${HOME}/go"
  mkdir -p "${GOPATH}/bin"

  # Go path must be exported before Mamba to ensure Go tools shadow pip tools
  export_path "/usr/local/go/bin"
  export_path "${GOPATH}/bin"
  persist_line 'GOPATH=' 'export GOPATH="${HOME}/go"'
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  install_golang
fi