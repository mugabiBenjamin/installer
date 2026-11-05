#!/usr/bin/env bash
# /opt/tools/installer/modules/12-wordlists.sh
# Phase 4 Module: Standard Wordlist Repositories (SecLists, PayloadAllTheThings)

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/config/defaults.sh"
source "${SCRIPT_DIR}/lib/log.sh"
source "${SCRIPT_DIR}/lib/pkg.sh"
source "${SCRIPT_DIR}/lib/git.sh"

banner "Module 12: Wordlists & Payloads"

# Note: Ownership of these directories was granted to $USER in 00-bootstrap.sh, 
# so sudo is not required for cloning inside them.

section "SecLists"
if [ -d "${SECLISTS_DIR}" ] && [ "$(ls -A "${SECLISTS_DIR}" 2>/dev/null)" ]; then
  log "SecLists already present at ${SECLISTS_DIR} — skipping"
else
  log "Cloning SecLists..."
  git clone --depth 1 https://github.com/danielmiessler/SecLists.git "${SECLISTS_DIR}" || warn "Failed to clone SecLists"
fi

section "RockYou"
if [ -f "${WORDLISTS_DIR}/rockyou.txt" ]; then
  log "rockyou.txt already extracted — skipping"
elif [ -f "${WORDLISTS_DIR}/rockyou.txt.gz" ]; then
  log "Decompressing system rockyou.txt.gz..."
  sudo gzip -d "${WORDLISTS_DIR}/rockyou.txt.gz" || warn "Failed to extract rockyou.txt.gz"
else
  log "Downloading rockyou.txt directly..."
  wget -q --show-progress -O "${WORDLISTS_DIR}/rockyou.txt" "https://github.com/brannondorsey/naive-hashcat/releases/download/data/rockyou.txt" \
    || warn "Failed to download rockyou.txt"
fi

section "PayloadsAllTheThings"
if [ -d "${PAYLOADS_DIR}" ] && [ "$(ls -A "${PAYLOADS_DIR}" 2>/dev/null)" ]; then
  log "PayloadsAllTheThings already present at ${PAYLOADS_DIR} — skipping"
else
  log "Cloning PayloadsAllTheThings..."
  clone_or_update "https://github.com/swisskyrepo/PayloadsAllTheThings.git" "${PAYLOADS_DIR}" || warn "Failed to clone PayloadsAllTheThings"
fi

section "User Directory Symlink"
if [ ! -L "${HOME}/wordlists" ] && [ ! -d "${HOME}/wordlists" ]; then
  log "Creating ~/wordlists symlink..."
  ln -s "${WORDLISTS_DIR}" "${HOME}/wordlists" || warn "Failed to create ~/wordlists symlink"
else
  log "~/wordlists symlink already exists — skipping"
fi

log "Module 12: Wordlists environment complete."