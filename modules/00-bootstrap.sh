#!/usr/bin/env bash
# /opt/tools/installer/modules/00-bootstrap.sh
# Phase 3 Module: Base system package setup & directory initialization

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/config/defaults.sh"
source "${SCRIPT_DIR}/lib/log.sh"
source "${SCRIPT_DIR}/lib/pkg.sh"

export DEBIAN_FRONTEND=noninteractive

banner "Module 00: Bootstrap Base Environment"

# 1. Directory Initialization
section "Directory Initialization"
log "Creating base directory structure..."

# Ensure system-level bin directory exists
sudo mkdir -p "${OSINT_BIN}"

# Create tool directories
sudo mkdir -p \
  "${TOOLS_DIR}" \
  "${POSTEXPLOIT_DIR}/linux" \
  "${POSTEXPLOIT_DIR}/windows" \
  "${WORDLISTS_DIR}" \
  "${SECLISTS_DIR}" \
  "${PAYLOADS_DIR}"

# Grant ownership to the current user for tool and payload directories 
# (avoids needing sudo to write files or run git clones inside them)
sudo chown -R "$USER":"$USER" \
  "${TOOLS_DIR}" \
  "${WORDLISTS_DIR}" \
  "${SECLISTS_DIR}" \
  "${PAYLOADS_DIR}" \
  || warn "Failed to set user ownership on some directories"

log "Directories initialized."


# 2. System Updates
section "System Updates"
log "Updating APT package lists..."
sudo apt update -y || warn "apt update encountered errors"

log "Upgrading installed packages..."
sudo apt upgrade -y || warn "apt upgrade encountered errors"


# 3. Base Package Installation
section "Core APT Dependencies"
log "Installing build tools, headers, and bootstrap utilities..."

# We use an array to install packages individually via the apt_install wrapper 
# from lib/pkg.sh. This ensures a single broken package name doesn't abort 
# the entire installation process.
BOOTSTRAP_PKGS=(
  build-essential curl wget git vim binutils htop gnupg tree plocate make
  python3-venv python3-dev
  libxml2-dev libxslt1-dev libxslt-dev libffi-dev libssl-dev
  libgmp-dev libmpfr-dev libmpc-dev
  ruby ruby-dev
  rlwrap socat proxychains4
  snmp snmp-mibs-downloader onesixtyone redis-tools
  bubblewrap
)

for pkg in "${BOOTSTRAP_PKGS[@]}"; do
  # Check if installed first to keep output clean and fast
  if dpkg -l "$pkg" &>/dev/null; then
    log "apt: $pkg already installed"
  else
    apt_install "$pkg"
  fi
done


# 4. SNMP Configuration
section "SNMP Configuration"
log "Enabling SNMP MIBs for enumeration tools..."

# Comment out 'mibs :' in the snmp.conf file if it exists, enabling all MIBs
if [ -f /etc/snmp/snmp.conf ]; then
  sudo sed -i 's/^mibs :/#mibs :/' /etc/snmp/snmp.conf 2>/dev/null \
    && log "Commented out 'mibs :' in /etc/snmp/snmp.conf" \
    || warn "Failed to modify /etc/snmp/snmp.conf"
fi

# Download MIB databases
if command -v download-mibs >/dev/null 2>&1; then
  sudo download-mibs 2>/dev/null \
    && log "SNMP MIBs downloaded and configured successfully" \
    || warn "download-mibs encountered an issue"
else
  warn "download-mibs command not found — SNMP setup incomplete"
fi

log "Module 00: Bootstrap complete."