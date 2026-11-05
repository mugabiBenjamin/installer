#!/usr/bin/env bash
# /opt/tools/installer/managers/ruby.sh
# Manager stub for Ruby / Gem package manager

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/config/defaults.sh"
source "${SCRIPT_DIR}/lib/log.sh"

ensure_gem() { :; }
gem_user_bin_path() { echo ""; }
gem_install() {
  log "Stub: Ruby manager gem_install '$1' (Phase 1)"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  ensure_gem
fi