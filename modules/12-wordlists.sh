#!/usr/bin/env bash
# /opt/tools/installer/modules/12-wordlists.sh
# Phase 4 Module: Standard Wordlist Repositories (SecLists, PayloadAllTheThings)

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/config/defaults.sh"
source "${SCRIPT_DIR}/lib/log.sh"

banner "Module 12: Wordlists & Payloads"