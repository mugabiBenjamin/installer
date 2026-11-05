#!/usr/bin/env bash
# /opt/tools/installer/verify/verify.sh
# Standalone execution post-install verification runner

set -uo pipefail

# Resolve paths relative to the script location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Graceful sourcing of dependencies
for dep in "config/defaults.sh" "lib/log.sh" "lib/verify.sh" "verify/expected_cmds.sh"; do
  if [ -f "${SCRIPT_DIR}/${dep}" ]; then
    source "${SCRIPT_DIR}/${dep}"
  else
    echo -e "\e[1;31m[-] Critical error: Missing dependency ${SCRIPT_DIR}/${dep}\e[0m"
    exit 1
  fi
done

# Argument Parsing
category=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --category) 
      category="$2"
      shift 2 
      ;;
    *) 
      warn "Unknown flag: $1"
      shift 
      ;;
  esac
done

banner "System Tool Verification Suite"

# Note: In this flat array structure, --category is parsed but we verify all
# tools globally. For strict category filtering, EXPECTED_CMDS would need to 
# be transitioned to an associative array in the future.
if [ -n "$category" ]; then
  log "Category filter provided: $category (Note: currently verifying global expected lists)"
fi

log "Initiating binary verification checks..."

# Execute verification using the lib/verify.sh helper
verify_all "${EXPECTED_CMDS[@]:-}"

# Generate the final report
print_missing_report

# Exit non-zero if any expected commands failed to install
if [ "${#MISSING_CMDS[@]}" -gt 0 ]; then
  err "Verification failed. ${#MISSING_CMDS[@]} binaries are missing from the system."
  exit 1
fi

log "All expected CTF tools are successfully installed and in PATH!"
exit 0