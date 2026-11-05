#!/usr/bin/env bash
# /opt/tools/installer/modules/11-re-forensics.sh
# Phase 4 Module: Reverse Engineering, Binary Analysis & Forensics

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/config/defaults.sh"
source "${SCRIPT_DIR}/lib/log.sh"
source "${SCRIPT_DIR}/lib/pkg.sh"
source "${SCRIPT_DIR}/lib/github.sh"
source "${SCRIPT_DIR}/lib/git.sh"

export DEBIAN_FRONTEND=noninteractive

banner "Module 11: RE, Forensics & Steganography"

section "Core Binary Analysis"

ensure_cmd radare2 apt_install radare2
ensure_cmd binwalk apt_install binwalk
ensure_cmd strace apt_install strace
ensure_cmd ltrace apt_install ltrace
ensure_cmd upx apt_install upx-ucl
ensure_cmd ghex apt_install ghex

if ! command -v checksec >/dev/null 2>&1; then
  if ! sudo apt install -y checksec 2>/dev/null; then
    uv_tool_install "checksec" "checksec" "checksec"
  fi
else
  warn "checksec already installed — skipping"
fi

section "Rizin & Cutter"

if ! command -v rizin >/dev/null 2>&1; then
  if ! sudo apt install -y rizin 2>/dev/null; then
    RIZIN_URL=$(fetch_latest_github_release "rizinorg/rizin" "linux.*amd64\.deb")
    if [ -n "${RIZIN_URL:-}" ]; then
      local_rizin="/tmp/rizin.deb"
      wget -q -O "${local_rizin}" "${RIZIN_URL}" && sudo dpkg -i "${local_rizin}" && sudo apt install -f -y || warn "Failed to install rizin deb"
      rm -f "${local_rizin}"
    fi
  fi
else
  warn "rizin already installed — skipping"
fi

if ! command -v cutter >/dev/null 2>&1; then
  if ! sudo apt install -y cutter 2>/dev/null; then
    CUTTER_URL=$(fetch_latest_github_release "rizinorg/cutter" "AppImage" "\.zsync")
    if [ -n "${CUTTER_URL:-}" ]; then
      wget -q -O "${TOOLS_DIR}/cutter.AppImage" "${CUTTER_URL}" && sudo chmod +x "${TOOLS_DIR}/cutter.AppImage" && sudo ln -sf "${TOOLS_DIR}/cutter.AppImage" "${OSINT_BIN}/cutter"
    fi
  fi
else
  warn "cutter already installed — skipping"
fi

section "Ghidra & pwndbg"

if [ "${INSTALL_GHIDRA}" = true ]; then
  if ! command -v ghidraRun >/dev/null 2>&1; then
    apt_install default-jdk
    GHIDRA_URL=$(fetch_latest_github_release "NationalSecurityAgency/ghidra" "_PUBLIC.*\.zip" "src\|debug")
    if [ -n "${GHIDRA_URL:-}" ]; then
      local_ghidra="/tmp/ghidra.zip"
      wget -q -O "${local_ghidra}" "${GHIDRA_URL}" && unzip -q "${local_ghidra}" -d "${TOOLS_DIR}/" && rm -f "${local_ghidra}"
      GHIDRA_DIR=$(find "${TOOLS_DIR}" -maxdepth 1 -type d -name 'ghidra_*' | head -1)
      [ -n "${GHIDRA_DIR}" ] && sudo ln -sf "${GHIDRA_DIR}/ghidraRun" "${OSINT_BIN}/ghidraRun"
    else
      warn "Could not resolve Ghidra URL"
    fi
  else
    warn "Ghidra already installed — skipping"
  fi
fi

if [ "${INSTALL_PWNDBG}" = true ]; then
  if [ ! -d "${TOOLS_DIR}/pwndbg" ]; then
    clone_or_update "https://github.com/pwndbg/pwndbg" "${TOOLS_DIR}/pwndbg"
    (cd "${TOOLS_DIR}/pwndbg" && bash setup.sh) || warn "pwndbg setup failed"
  else
    warn "pwndbg already present — skipping"
  fi
fi

section "Forensics & Steganography"

FORENSICS_PKGS=(
  foremost scalpel libimage-exiftool-perl steghide gddrescue zbar-tools stegseek
  ffmpeg mediainfo sox imagemagick testdisk sleuthkit autopsy
)
for pkg in "${FORENSICS_PKGS[@]}"; do
  apt_install "$pkg"
done

log "Module 11: RE & Forensics complete."