#!/usr/bin/env bash
# /opt/tools/installer/managers/rust.sh
# Manager stub for Rust/Cargo toolchain

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/config/defaults.sh"
source "${SCRIPT_DIR}/lib/log.sh"

install_rust() {
  log "Stub: Rust manager (Phase 1)"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  install_rust
fi