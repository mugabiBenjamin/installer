#!/usr/bin/env bash
# /opt/tools/installer/lib/verify.sh
# Verification runner and result reporting utilities

MISSING_CMDS=()
PASSED_CMDS=0

verify_cmd() {
  local cmd="$1"
  if command -v "${cmd}" >/dev/null 2>&1; then
    printf '  \e[1;32m%-28s INSTALLED\e[0m\n' "${cmd}"
    ((PASSED_CMDS++)) || true
    return 0
  else
    printf '  \e[1;31m%-28s NOT FOUND\e[0m\n' "${cmd}"
    MISSING_CMDS+=("${cmd}")
    return 1
  fi
}

verify_all() {
  local cmds=("$@")
  PASSED_CMDS=0
  MISSING_CMDS=()
  for c in "${cmds[@]}"; do
    verify_cmd "$c"
  done
}

print_missing_report() {
  local total=$((PASSED_CMDS + ${#MISSING_CMDS[@]}))
  section "Verification Summary: ${PASSED_CMDS}/${total} Passed"
  if [ "${#MISSING_CMDS[@]}" -gt 0 ]; then
    warn "The following ${#MISSING_CMDS[@]} command(s) were missing:"
    for m in "${MISSING_CMDS[@]}"; do
      warn "  - ${m}"
    done
  else
    log "All expected commands are present!"
  fi
}