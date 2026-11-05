#!/usr/bin/env bash
# /opt/tools/installer/modules/10-c2.sh
# Phase 9 Module: Command and Control (C2) Frameworks
# Note: Excluded from default run; must be invoked with --only c2

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/config/defaults.sh"
source "${SCRIPT_DIR}/lib/log.sh"
source "${SCRIPT_DIR}/lib/pkg.sh"
source "${SCRIPT_DIR}/lib/github.sh"
source "${SCRIPT_DIR}/lib/git.sh"
source "${SCRIPT_DIR}/managers/golang.sh"

export DEBIAN_FRONTEND=noninteractive

banner "Module 10: C2 Frameworks"

section "Sliver C2"

if ! command -v sliver-server >/dev/null 2>&1; then
  log "Installing Sliver via official install script..."
  
  # The official Sliver install script automatically fetches the latest release,
  # places binaries in /usr/local/bin, and attempts to set up a systemd service.
  local_sliver_script="/tmp/sliver-install.sh"
  wget -q --show-progress -O "${local_sliver_script}" "https://raw.githubusercontent.com/BishopFox/sliver/master/scripts/install.sh" \
    || warn "Failed to download Sliver installation script"
  
  if [ -f "${local_sliver_script}" ]; then
    sudo bash "${local_sliver_script}" || warn "Sliver install script encountered errors"
    rm -f "${local_sliver_script}"
  fi
  
  if command -v sliver-server >/dev/null 2>&1; then
    log "Sliver installed successfully"
  else
    warn "Sliver binaries not found in PATH after installation"
  fi
else
  warn "sliver-server already installed — skipping"
fi

section "Havoc C2"

HAVOC_DIR="${TOOLS_DIR}/Havoc"

if [ ! -d "${HAVOC_DIR}" ] || [ ! -x "${HAVOC_DIR}/havoc" ]; then
  log "Installing Havoc build dependencies..."
  
  # Havoc requires heavy compilation dependencies for both the Teamserver and Client
  HAVOC_DEPS=(
    cmake libssl-dev libboost-all-dev g++ mingw-w64 python3-dev 
    qtbase5-dev libqt5websockets5-dev python3-websockets nasm
  )
  for pkg in "${HAVOC_DEPS[@]}"; do
    apt_install "$pkg"
  done

  log "Cloning Havoc Framework..."
  clone_or_update "https://github.com/HavocFramework/Havoc.git" "${HAVOC_DIR}"
  
  if [ -d "${HAVOC_DIR}" ]; then
    log "Building Havoc Teamserver and Client (this may take a while)..."
    (
      cd "${HAVOC_DIR}"
      
      log "Building Teamserver..."
      # Go dependencies are fetched automatically by make
      make ts-build || warn "Havoc teamserver build encountered errors"
      
      log "Building Client..."
      make client-build || warn "Havoc client build encountered errors"
    )
    
    if [ -x "${HAVOC_DIR}/havoc" ]; then
      log "Havoc successfully built at ${HAVOC_DIR}"
    else
      warn "Havoc binary not found; compilation may have failed."
    fi
  fi
else
  warn "Havoc directory or binary already exists — skipping"
fi

echo ""
echo "====================================================================="
echo " ── C2 Frameworks Post-Install Setup ──────────────────────────────"
echo ""
echo " Sliver:"
echo "   Start Teamserver: sudo systemctl start sliver (if systemd supported)"
echo "                     or simply run 'sudo sliver-server'"
echo "   Start Client:     sliver"
echo ""
echo " Havoc:"
echo "   Havoc is intentionally not symlinked to PATH due to local assets."
echo "   Start Teamserver: cd ${HAVOC_DIR} && ./havoc server --profile profiles/havoc.yaotl -v --debug"
echo "   Start Client:     cd ${HAVOC_DIR} && ./havoc client"
echo "====================================================================="
log "Module 10: C2 tools complete."