#!/usr/bin/env bash
# /opt/tools/installer/modules/01-network.sh
# Phase 4 Module: Network Scanning & Enumeration Tools

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/config/defaults.sh"
source "${SCRIPT_DIR}/lib/log.sh"
source "${SCRIPT_DIR}/lib/pkg.sh"

banner "Module 01: Network Scanning & Enumeration"