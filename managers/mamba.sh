#!/usr/bin/env bash
# /opt/tools/installer/managers/mamba.sh
# Miniforge / Mamba package manager initialization

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/config/defaults.sh"
source "${SCRIPT_DIR}/lib/log.sh"
source "${SCRIPT_DIR}/lib/env.sh"
source "${SCRIPT_DIR}/lib/trap.sh"
source "${SCRIPT_DIR}/lib/github.sh"

install_mamba() {
  log "Setting up Mamba (Miniforge)..."

  if [ -x "${MINIFORGE_DIR}/bin/mamba" ]; then
    log "Mamba already installed — updating..."
    "${MINIFORGE_DIR}/bin/mamba" update -n base -c conda-forge mamba -y \
      || warn "Mamba update failed"
  else
    local installer_url
    installer_url=$(fetch_latest_github_release "conda-forge/miniforge" "Linux-x86_64\.sh")
    
    if [ -n "${installer_url:-}" ]; then
      local tmp_mamba="/tmp/miniforge.sh"
      register_tmp "${tmp_mamba}"
      wget -q --show-progress -O "${tmp_mamba}" "${installer_url}" \
        && bash "${tmp_mamba}" -b -u -p "${MINIFORGE_DIR}" \
        && log "Mamba installed at ${MINIFORGE_DIR}" \
        || warn "Failed to install Mamba"
    else
      warn "Could not resolve Miniforge installer URL — skipping."
    fi
  fi

  # Path is exported here. Since this runs after Go in the lifecycle,
  # Mamba will be lower priority in PATH than GOPATH binaries.
  export_path "${MINIFORGE_DIR}/bin"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  install_mamba
fi