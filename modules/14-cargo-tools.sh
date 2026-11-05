#!/usr/bin/env bash
# /opt/tools/installer/modules/14-cargo-tools.sh
# Phase 10 Module: Rust-based CLI Utilities via Cargo

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/config/defaults.sh"
source "${SCRIPT_DIR}/lib/log.sh"
source "${SCRIPT_DIR}/lib/pkg.sh"
source "${SCRIPT_DIR}/managers/rust.sh"

banner "Module 14: Cargo Package Utilities"

section "Rust CLI Tools"

# ripgrep installs as 'rg'
ensure_cmd rg cargo_install ripgrep

# fd-find installs as 'fd'
ensure_cmd fd cargo_install fd-find

ensure_cmd bat cargo_install bat
ensure_cmd hexyl cargo_install hexyl
ensure_cmd tokei cargo_install tokei

log "Module 14: Cargo tools complete."