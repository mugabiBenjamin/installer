#!/usr/bin/env bash
# /opt/tools/installer/modules/04-windows-ad.sh
# Phase 6 Module: Active Directory & Windows Exploitation

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/config/defaults.sh"
source "${SCRIPT_DIR}/lib/log.sh"
source "${SCRIPT_DIR}/lib/pkg.sh"

banner "Module 04: Windows & Active Directory Attacks"