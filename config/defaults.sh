#!/usr/bin/env bash
# /opt/tools/installer/config/defaults.sh
# All path, directory, and global flag constants

TOOLS_DIR="/opt/tools"
OSINT_BIN="/usr/local/bin"
MINIFORGE_DIR="/opt/miniforge3"
WORDLISTS_DIR="/usr/share/wordlists"
SECLISTS_DIR="/usr/share/seclists"
PAYLOADS_DIR="/usr/share/payloadsallthethings"
POSTEXPLOIT_DIR="${TOOLS_DIR}/post-exploit"

INSTALLER_DIR="/opt/tools/installer"
MODULES_DIR="${INSTALLER_DIR}/modules"
LIB_DIR="${INSTALLER_DIR}/lib"
MANAGERS_DIR="${INSTALLER_DIR}/managers"

INSTALL_GHIDRA=true
INSTALL_PWNDBG=true
MINIMAL=false