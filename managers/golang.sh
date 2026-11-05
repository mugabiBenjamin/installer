#!/usr/bin/env bash
# /opt/tools/installer/managers/golang.sh
# Manager stub for Go environment setup

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/config/defaults.sh"
source "${SCRIPT_DIR}/lib/log.sh"

install_golang() {
  log "Stub: Go manager (Phase 1)"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  install_golang
fi