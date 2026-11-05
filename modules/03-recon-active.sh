#!/usr/bin/env bash
# /opt/tools/installer/modules/03-recon-active.sh
# Phase 5 Module: Active DNS & Infrastructure Reconnaissance

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/config/defaults.sh"
source "${SCRIPT_DIR}/lib/log.sh"
source "${SCRIPT_DIR}/lib/pkg.sh"

banner "Module 03 (Active): Active Recon & Content Discovery"