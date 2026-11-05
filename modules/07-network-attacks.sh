#!/usr/bin/env bash
# /opt/tools/installer/modules/07-network-attacks.sh
# Phase 8 Module: Active Network Protocol Attacks & Poisoning

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/config/defaults.sh"
source "${SCRIPT_DIR}/lib/log.sh"
source "${SCRIPT_DIR}/lib/pkg.sh"

banner "Module 07: Network Protocol Attacks"