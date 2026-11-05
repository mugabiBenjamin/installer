#!/usr/bin/env bash
# /opt/tools/installer/managers/mamba.sh
# Manager stub for Mamba / Miniforge package environment

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/config/defaults.sh"
source "${SCRIPT_DIR}/lib/log.sh"

install_mamba() {
  log "Stub: Mamba manager (Phase 1)"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  install_mamba
fi