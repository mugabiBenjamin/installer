#!/usr/bin/env bash
# /opt/tools/installer/managers/homebrew.sh
# Manager stub for Homebrew setup

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/config/defaults.sh"
source "${SCRIPT_DIR}/lib/log.sh"

source_brew() { :; }
brew_rc_line() { echo ""; }
install_homebrew() {
  log "Stub: Homebrew manager (Phase 1)"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  install_homebrew
fi