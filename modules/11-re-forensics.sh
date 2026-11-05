#!/usr/bin/env bash
# /opt/tools/installer/modules/11-re-forensics.sh
# Phase 4 Module: Reverse Engineering, Binary Analysis & Forensics

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/config/defaults.sh"
source "${SCRIPT_DIR}/lib/log.sh"
source "${SCRIPT_DIR}/lib/pkg.sh"

banner "Module 11: RE, Forensics & Steganography"