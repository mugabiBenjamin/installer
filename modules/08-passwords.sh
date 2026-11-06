#!/usr/bin/env bash
# /opt/tools/installer/modules/08-passwords.sh
# Phase 4 Module: Password Cracking & Wordlist Generators

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/config/defaults.sh"
source "${SCRIPT_DIR}/lib/log.sh"
source "${SCRIPT_DIR}/lib/pkg.sh"
source "${SCRIPT_DIR}/lib/git.sh"
source "${SCRIPT_DIR}/managers/uv.sh"

banner "Module 08: Password Cracking & Analysis"

section "Core Crackers"

ensure_cmd hashcat apt_install hashcat
ensure_cmd john apt_install john
ensure_cmd hydra apt_install hydra
ensure_cmd fcrackzip apt_install fcrackzip
ensure_cmd pdfcrack apt_install pdfcrack

section "Hash Identification"

# haiti is distributed as the haiti-hash Ruby gem, not a PyPI package.
ensure_cmd haiti gem_install haiti-hash
ensure_cmd nth uv_tool_install name-that-hash name-that-hash nth

section "Custom Wordlist Generation"

if ! command -v cewl >/dev/null 2>&1; then
  sudo apt install -y cewl 2>/dev/null || gem_install cewl
else
  warn "cewl already installed — skipping"
fi

if ! command -v cupp >/dev/null 2>&1; then
  install_git_uv_tool "https://github.com/Mebus/cupp.git" "${TOOLS_DIR}/cupp" "" "cupp.py" "${OSINT_BIN}/cupp"
else
  warn "cupp already installed — skipping"
fi

if ! command -v username-anarchy >/dev/null 2>&1; then
  log "Installing username-anarchy..."
  clone_or_update "https://github.com/urbanadventurer/username-anarchy.git" "${TOOLS_DIR}/username-anarchy"
  if [ -x "${TOOLS_DIR}/username-anarchy/username-anarchy" ]; then
    sudo ln -sf "${TOOLS_DIR}/username-anarchy/username-anarchy" "${OSINT_BIN}/username-anarchy"
    log "username-anarchy installed (${OSINT_BIN}/username-anarchy)"
  fi
else
  warn "username-anarchy already installed — skipping"
fi

log "Module 08: Password tools complete."