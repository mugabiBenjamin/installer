#!/usr/bin/env bash
# /opt/tools/installer/modules/01-network.sh
# Phase 4 Module: Network Scanning & Enumeration Tools

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/config/defaults.sh"
source "${SCRIPT_DIR}/lib/log.sh"
source "${SCRIPT_DIR}/lib/pkg.sh"
source "${SCRIPT_DIR}/lib/github.sh"
source "${SCRIPT_DIR}/managers/homebrew.sh"
source "${SCRIPT_DIR}/managers/golang.sh"

export DEBIAN_FRONTEND=noninteractive

banner "Module 01: Network Scanning & Enumeration"

section "Core Network Scanners"

ensure_cmd nmap apt_install nmap
ensure_cmd tcpdump apt_install tcpdump
ensure_cmd masscan apt_install masscan

# Wireshark with non-root packet capture configuration
if ! command -v wireshark >/dev/null 2>&1; then
  log "Installing Wireshark & tshark with non-root capture enabled..."
  echo "wireshark-common wireshark-common/install-setuid boolean true" | sudo debconf-set-selections
  apt_install wireshark
  apt_install tshark
  sudo dpkg-reconfigure -f noninteractive wireshark-common 2>/dev/null || true
  sudo usermod -aG wireshark "$USER" || warn "Failed to add $USER to wireshark group"
else
  warn "wireshark already installed — skipping"
fi

section "Advanced Discovery & Enumeration"

ensure_cmd rustscan brew_install rustscan
ensure_cmd amass brew_install amass
ensure_cmd naabu go_install github.com/projectdiscovery/naabu/v2/cmd/naabu

section "SMB Enumeration"

ensure_cmd smbclient apt_install smbclient
ensure_cmd smbmap apt_install smbmap

log "Module 01: Network scanning tools complete."