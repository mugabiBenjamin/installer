#!/usr/bin/env bash
# /opt/tools/installer/modules/02-web-enum.sh
# Phase 4 Module: Web Fuzzing, Fingerprinting & Crawling

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/config/defaults.sh"
source "${SCRIPT_DIR}/lib/log.sh"
source "${SCRIPT_DIR}/lib/pkg.sh"

banner "Module 02: Web Enumeration & Fuzzing"