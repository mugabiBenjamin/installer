#!/usr/bin/env bash
# /opt/tools/installer/modules/03-recon-active.sh
# Phase 5 Module: Active DNS & Infrastructure Reconnaissance

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/config/defaults.sh"
source "${SCRIPT_DIR}/lib/log.sh"
source "${SCRIPT_DIR}/lib/pkg.sh"
source "${SCRIPT_DIR}/lib/git.sh"
source "${SCRIPT_DIR}/managers/uv.sh"
source "${SCRIPT_DIR}/managers/golang.sh"

export DEBIAN_FRONTEND=noninteractive

banner "Module 03 (Active): Active Recon & Content Discovery"

section "Active Enumeration Utilities"

ensure_cmd dnsrecon uv_tool_install dnsrecon dnsrecon dnsrecon
ensure_cmd dnsenum apt_install dnsenum
ensure_cmd fierce uv_tool_install fierce fierce fierce
ensure_cmd wafw00f uv_tool_install wafw00f wafw00f wafw00f
ensure_cmd arjun uv_tool_install arjun arjun arjun
ensure_cmd paramspider uv_tool_install paramspider "git+https://github.com/devanshbatham/ParamSpider.git" paramspider
ensure_cmd git-dumper uv_tool_install git-dumper git-dumper git-dumper

section "Python Discovery Scripts"

if ! command -v linkfinder >/dev/null 2>&1; then
  log "Installing LinkFinder..."
  install_git_uv_tool "https://github.com/GerbenJavado/LinkFinder.git" "${TOOLS_DIR}/LinkFinder" "requirements.txt" "linkfinder.py" "${OSINT_BIN}/linkfinder"
else
  warn "linkfinder already installed — skipping"
fi

if ! command -v secretfinder >/dev/null 2>&1; then
  log "Installing SecretFinder..."
  install_git_uv_tool "https://github.com/m4ll0k/SecretFinder.git" "${TOOLS_DIR}/SecretFinder" "requirements.txt" "SecretFinder.py" "${OSINT_BIN}/secretfinder"
else
  warn "secretfinder already installed — skipping"
fi

if ! command -v photon >/dev/null 2>&1; then
  log "Installing Photon..."
  install_git_uv_tool "https://github.com/s0md3v/Photon.git" "${TOOLS_DIR}/photon" "requirements.txt" "photon.py" "${OSINT_BIN}/photon"
else
  warn "photon already installed — skipping"
fi

section "Go Discovery Scripts"

ensure_cmd dalfox go_install github.com/hahwul/dalfox/v2/cmd/dalfox
ensure_cmd metabigor go_install github.com/j3ssie/metabigor

log "Module 03 (Active): Recon tools complete."