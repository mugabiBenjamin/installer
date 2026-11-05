#!/usr/bin/env bash
# /opt/tools/installer/install.sh
# Main orchestrator script

set -uo pipefail

INSTALLER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "${INSTALLER_DIR}/config/defaults.sh"
source "${INSTALLER_DIR}/config/categories.sh"
source "${INSTALLER_DIR}/lib/log.sh"
source "${INSTALLER_DIR}/lib/trap.sh"

# Preflight requirements
command -v sudo >/dev/null 2>&1 || err "sudo is required but not installed."

SKIP_LIST=()
ONLY_LIST=()

# Argument parsing
while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-ghidra) INSTALL_GHIDRA=false; shift ;;
    --no-pwndbg) INSTALL_PWNDBG=false; shift ;;
    --minimal)   MINIMAL=true; shift ;;
    --skip)
      IFS=',' read -r -a SKIP_LIST <<< "$2"
      shift 2
      ;;
    --only)
      IFS=',' read -r -a ONLY_LIST <<< "$2"
      shift 2
      ;;
    *)
      warn "Unknown flag: $1"
      shift
      ;;
  esac
done

# Resolve active categories
SELECTED_CATEGORIES=()
if [ "${#ONLY_LIST[@]}" -gt 0 ]; then
  SELECTED_CATEGORIES=("${ONLY_LIST[@]}")
else
  for cat in "${ALL_CATEGORIES[@]}"; do
    skip=false
    for s in "${SKIP_LIST[@]:-}"; do
      if [[ "$s" == "$cat" ]]; then
        skip=true
        break
      fi
    done
    if [ "$skip" = false ]; then
      SELECTED_CATEGORIES+=("$cat")
    fi
  done
fi

# Build ordered list of module files
MODULES_TO_RUN=()
for cat in "${SELECTED_CATEGORIES[@]}"; do
  if [[ -n "${CATEGORY_MAP[$cat]:-}" ]]; then
    for mod_file in ${CATEGORY_MAP[$cat]}; do
      MODULES_TO_RUN+=("$mod_file")
    done
  else
    warn "Category '$cat' not recognized — skipping"
  fi
done

banner "CTF Tools Modular Installer Framework"

FAILED_MODULES=()

# Execute target modules
for mod in "${MODULES_TO_RUN[@]}"; do
  mod_path="${MODULES_DIR}/${mod}"
  if [ -f "$mod_path" ]; then
    log "Executing module: ${mod}"
    if bash "$mod_path"; then
      log "Module passed: ${mod}"
    else
      warn "Module reported non-zero status: ${mod}"
      FAILED_MODULES+=("${mod}")
    fi
  else
    warn "Module file missing: ${mod_path}"
    FAILED_MODULES+=("${mod}")
  fi
done

# Final verification run
if [ -f "${INSTALLER_DIR}/verify/verify.sh" ]; then
  bash "${INSTALLER_DIR}/verify/verify.sh" || warn "Verification reported missing binaries"
fi

if [ "${#FAILED_MODULES[@]}" -gt 0 ]; then
  err "Installation finished with failed modules: ${FAILED_MODULES[*]}"
else
  log "Scaffold run completed successfully!"
fi