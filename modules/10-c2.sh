#!/usr/bin/env bash
# /opt/tools/installer/modules/10-c2.sh
# Phase 9 Module: Command and Control (C2) Frameworks

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/config/defaults.sh"
source "${SCRIPT_DIR}/lib/log.sh"
source "${SCRIPT_DIR}/lib/pkg.sh"

banner "Module 10: C2 Frameworks"