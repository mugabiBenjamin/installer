#!/usr/bin/env bash
# /opt/tools/installer/modules/13-config.sh
# Phase 11 Module: Shell & Tool Quality-of-Life Configurations

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/config/defaults.sh"
source "${SCRIPT_DIR}/lib/log.sh"

banner "Module 13: Environment Configurations"