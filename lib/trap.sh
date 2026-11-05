#!/usr/bin/env bash
# /opt/tools/installer/lib/trap.sh
# Signal trap management and temporary file cleanup registry

if [ -z "${CLEANUP_FILES+x}" ]; then
  CLEANUP_FILES=()
fi

register_tmp() {
  CLEANUP_FILES+=("$1")
}

cleanup() {
  local f
  for f in "${CLEANUP_FILES[@]:-}"; do
    if [ -n "$f" ] && [ -e "$f" ]; then
      rm -rf "$f" 2>/dev/null && log "Cleaned up temporary resource: $f" || true
    fi
  done
}

trap cleanup EXIT INT TERM