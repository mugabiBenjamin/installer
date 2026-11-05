#!/usr/bin/env bash
# /opt/tools/installer/modules/14-cargo-tools.sh
# Phase 10 Module: Rust-based CLI Utilities via Cargo

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/config/defaults.sh"
source "${SCRIPT_DIR}/lib/log.sh"
source "${SCRIPT_DIR}/lib/pkg.sh"

banner "Module 14: Cargo Package Utilities"