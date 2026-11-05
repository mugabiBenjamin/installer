#!/usr/bin/env bash
# /opt/tools/installer/managers/rust.sh
# Rustup toolchain installer and Cargo environment setup

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/config/defaults.sh"
source "${SCRIPT_DIR}/lib/log.sh"
source "${SCRIPT_DIR}/lib/env.sh"

install_rust() {
  log "Setting up Rust (rustup)..."
  if ! command -v cargo >/dev/null 2>&1; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path \
      || warn "Rust installation failed"
  else
    log "Rust already present — updating..."
    rustup update stable || warn "Rust update failed"
  fi

  if [ -f "${HOME}/.cargo/env" ]; then
    source "${HOME}/.cargo/env"
    persist_line 'cargo/env' ". \"${HOME}/.cargo/env\""
  fi

  export_path "${HOME}/.cargo/bin"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  install_rust
fi