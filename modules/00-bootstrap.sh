#!/usr/bin/env bash
# /opt/tools/installer/modules/00-bootstrap.sh
# Phase 3 Module: Base system package setup & directory initialization

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/config/defaults.sh"
source "${SCRIPT_DIR}/lib/log.sh"
source "${SCRIPT_DIR}/lib/pkg.sh"

banner "Module 00: Bootstrap Base Environment"