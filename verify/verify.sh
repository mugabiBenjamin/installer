#!/usr/bin/env bash
# /opt/tools/installer/verify/verify.sh
# Standalone execution post-install verification runner

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/config/defaults.sh"
source "${SCRIPT_DIR}/lib/log.sh"
source "${SCRIPT_DIR}/lib/verify.sh"
source "${SCRIPT_DIR}/verify/expected_cmds.sh"

category=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --category) category="$2"; shift 2 ;;
    *) shift ;;
  esac
done

banner "Verification Suite"
verify_all "${EXPECTED_CMDS[@]:-}"
print_missing_report

if [ "${#MISSING_CMDS[@]}" -gt 0 ]; then
  exit 1
fi