#!/usr/bin/env bash
# /opt/tools/installer/modules/06-web-attacks.sh
# Phase 8 Module: Focused Web Application Attack Frameworks

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/config/defaults.sh"
source "${SCRIPT_DIR}/lib/log.sh"
source "${SCRIPT_DIR}/lib/pkg.sh"

banner "Module 06: Web Application Attacks"