#!/usr/bin/env bash
# /opt/tools/installer/managers/uv.sh
# uv Python package and venv manager

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/config/defaults.sh"
source "${SCRIPT_DIR}/lib/log.sh"
source "${SCRIPT_DIR}/lib/env.sh"

install_uv() {
  log "Setting up uv..."
  if ! command -v uv >/dev/null 2>&1; then
    curl -LsSf https://astral.sh/uv/install.sh | sh \
      && log "uv installed successfully" \
      || warn "Failed to install uv"
  else
    log "uv already installed."
  fi

  export_path "${HOME}/.local/bin"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  install_uv
fi