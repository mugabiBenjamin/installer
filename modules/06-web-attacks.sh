#!/usr/bin/env bash
# /opt/tools/installer/modules/06-web-attacks.sh
# Phase 8 Module: Focused Web Application Attack Frameworks

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/config/defaults.sh"
source "${SCRIPT_DIR}/lib/log.sh"
source "${SCRIPT_DIR}/lib/pkg.sh"
source "${SCRIPT_DIR}/lib/git.sh"
source "${SCRIPT_DIR}/managers/uv.sh"
source "${SCRIPT_DIR}/managers/golang.sh"

export DEBIAN_FRONTEND=noninteractive

banner "Module 06: Web Application Attacks"

section "Go Web Attack Tools"

# dalfox checked early in case 03-recon-active already installed it
ensure_cmd dalfox go_install github.com/hahwul/dalfox/v2/cmd/dalfox
ensure_cmd byp4xx go_install github.com/lobuhi/byp4xx@latest
ensure_cmd interactsh-client go_install github.com/projectdiscovery/interactsh/cmd/interactsh-client

section "Python Web Attack Frameworks"

ensure_cmd corscanner uv_tool_install corscanner corscanner corscanner

if ! command -v xsstrike >/dev/null 2>&1; then
  log "Installing XSStrike..."
  install_git_uv_tool "https://github.com/s0md3v/XSStrike.git" "${TOOLS_DIR}/XSStrike" "requirements.txt" "xsstrike.py" "${OSINT_BIN}/xsstrike"
else
  warn "xsstrike already installed — skipping"
fi

if ! command -v jwt_tool >/dev/null 2>&1; then
  log "Installing jwt_tool..."
  install_git_uv_tool "https://github.com/ticarpi/jwt_tool.git" "${TOOLS_DIR}/jwt_tool" "requirements.txt" "jwt_tool.py" "${OSINT_BIN}/jwt_tool"
else
  warn "jwt_tool already installed — skipping"
fi

if ! command -v commix >/dev/null 2>&1; then
  log "Installing commix..."
  # Commix relies heavily on stdlib but we wrap it in an isolated environment anyway for cleanliness
  install_git_uv_tool "https://github.com/commixproject/commix.git" "${TOOLS_DIR}/commix" "" "commix.py" "${OSINT_BIN}/commix"
else
  warn "commix already installed — skipping"
fi

if ! command -v ghauri >/dev/null 2>&1; then
  log "Installing ghauri..."
  install_git_uv_tool "https://github.com/r0oth3x49/ghauri.git" "${TOOLS_DIR}/ghauri" "requirements.txt" "ghauri.py" "${OSINT_BIN}/ghauri"
else
  warn "ghauri already installed — skipping"
fi

log "Module 06: Web application attack tools complete."