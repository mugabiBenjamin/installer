#!/usr/bin/env bash
# /opt/tools/installer/modules/09-wireless.sh
# Phase 8 Module: Wireless Audit & Frame Analysis Suite

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/config/defaults.sh"
source "${SCRIPT_DIR}/lib/log.sh"
source "${SCRIPT_DIR}/lib/pkg.sh"

banner "Module 09: Wireless Security Tools"