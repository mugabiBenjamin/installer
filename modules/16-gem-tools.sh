#!/usr/bin/env bash
# /opt/tools/installer/modules/16-gem-tools.sh
# Phase 10 Module: Ruby Gem Utilities

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/config/defaults.sh"
source "${SCRIPT_DIR}/lib/log.sh"
source "${SCRIPT_DIR}/lib/pkg.sh"

banner "Module 16: Ruby Gem Tools"