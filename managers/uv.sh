#!/usr/bin/env bash
# /opt/tools/installer/managers/uv.sh
# Manager stub for uv Python package installer

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/config/defaults.sh"
source "${SCRIPT_DIR}/lib/log.sh"

install_uv() {
  log "Stub: uv manager (Phase 1)"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  install_uv
fi