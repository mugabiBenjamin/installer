#!/usr/bin/env bash
# /opt/tools/installer/modules/08-passwords.sh
# Phase 4 Module: Password Cracking & Wordlist Generators

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/config/defaults.sh"
source "${SCRIPT_DIR}/lib/log.sh"
source "${SCRIPT_DIR}/lib/pkg.sh"

banner "Module 08: Password Cracking & Analysis"