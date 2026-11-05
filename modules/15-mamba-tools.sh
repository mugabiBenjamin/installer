#!/usr/bin/env bash
# /opt/tools/installer/modules/15-mamba-tools.sh
# Phase 10 Module: Scientific & Mathematical Tools via Mamba

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/config/defaults.sh"
source "${SCRIPT_DIR}/lib/log.sh"
source "${SCRIPT_DIR}/lib/pkg.sh"
source "${SCRIPT_DIR}/managers/mamba.sh"

banner "Module 15: Mamba Package Environment"

section "Mathematical & Crypto Frameworks"

# SageMath is an extremely heavy math software package used extensively in 
# cryptography CTFs. It is best installed via conda-forge.
ensure_cmd sage mamba_install sage conda-forge

# ---------------------------------------------------------
# Placeholder for future mamba packages. 
# Format: ensure_cmd <binary_name> mamba_install <package_name> <channel>
# Example: ensure_cmd jupyter mamba_install jupyter conda-forge
# ---------------------------------------------------------

log "Module 15: Mamba tools complete."