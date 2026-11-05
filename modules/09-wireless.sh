#!/usr/bin/env bash
# /opt/tools/installer/modules/09-wireless.sh
# Phase 8 Module: Wireless Audit & Frame Analysis Suite

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/config/defaults.sh"
source "${SCRIPT_DIR}/lib/log.sh"
source "${SCRIPT_DIR}/lib/pkg.sh"
source "${SCRIPT_DIR}/lib/github.sh"

export DEBIAN_FRONTEND=noninteractive

banner "Module 09: Wireless Security Tools"

section "Aircrack-ng Suite"

ensure_cmd aircrack-ng apt_install aircrack-ng

section "HCX Tools"

ensure_cmd hcxtools apt_install hcxtools

if ! command -v hcxdumptool >/dev/null 2>&1; then
  log "Installing hcxdumptool..."
  if ! sudo apt install -y hcxdumptool 2>/dev/null; then
    warn "hcxdumptool not in apt — attempting GitHub release fallback..."
    HCX_URL=$(fetch_latest_github_release "ZerBea/hcxdumptool" "x86_64.*linux")
    if [ -n "${HCX_URL:-}" ]; then
      download_binary "${HCX_URL}" "${OSINT_BIN}/hcxdumptool"
    else
      warn "Could not resolve hcxdumptool release URL; manual compile may be required."
    fi
  else
    log "apt: hcxdumptool installed"
  fi
else
  warn "hcxdumptool already installed — skipping"
fi

echo ""
echo "====================================================================="
echo " ── Wireless Setup Notice ─────────────────────────────────────────"
echo "   Wireless attacks require a WiFi adapter that supports monitor"
echo "   mode and packet injection. The script cannot configure hardware."
echo "====================================================================="
log "Module 09: Wireless tools complete."