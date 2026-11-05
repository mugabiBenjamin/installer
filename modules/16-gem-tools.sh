#!/usr/bin/env bash
# /opt/tools/installer/modules/16-gem-tools.sh
# Phase 10 Module: Ruby Gem Utilities

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/config/defaults.sh"
source "${SCRIPT_DIR}/lib/log.sh"
source "${SCRIPT_DIR}/lib/pkg.sh"
source "${SCRIPT_DIR}/managers/ruby.sh"

banner "Module 16: Ruby Gem Tools"

section "Ruby OSINT & Exploitation Gems"

# Steganography tool for PNG/BMP formats
ensure_cmd zsteg gem_install zsteg

# Gadget finder for glibc exploitation (pwn challenges)
ensure_cmd one_gadget gem_install one_gadget

# Idempotency guard: evil-winrm is also installed in Phase 6 (04-windows-ad.sh), 
# but ensuring it here allows this module to be run fully standalone to grab gem updates.
ensure_cmd evil-winrm gem_install evil-winrm

log "Module 16: Gem tools complete."