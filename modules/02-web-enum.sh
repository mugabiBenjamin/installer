#!/usr/bin/env bash
# /opt/tools/installer/modules/02-web-enum.sh
# Phase 4 Module: Web Fuzzing, Fingerprinting & Crawling

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/config/defaults.sh"
source "${SCRIPT_DIR}/lib/log.sh"
source "${SCRIPT_DIR}/lib/pkg.sh"
source "${SCRIPT_DIR}/lib/github.sh"
source "${SCRIPT_DIR}/lib/git.sh"
source "${SCRIPT_DIR}/managers/golang.sh"

banner "Module 02: Web Enumeration & Fuzzing"

section "Web Fingerprinting & Scanning"

ensure_cmd whatweb apt_install whatweb
ensure_cmd ffuf apt_install ffuf
ensure_cmd sqlmap apt_install sqlmap

if ! command -v feroxbuster >/dev/null 2>&1; then
  log "Installing feroxbuster..."
  FEROX_URL=$(fetch_latest_github_release "epi052/feroxbuster" "x86_64-linux-feroxbuster\.zip")
  if [ -n "${FEROX_URL:-}" ]; then
    download_and_unzip "${FEROX_URL}" "${OSINT_BIN}" "feroxbuster"
  else
    warn "Could not resolve feroxbuster release URL"
  fi
else
  warn "feroxbuster already installed — skipping"
fi

section "ProjectDiscovery Tools"

ensure_cmd subfinder go_install github.com/projectdiscovery/subfinder/v2/cmd/subfinder
ensure_cmd nuclei go_install github.com/projectdiscovery/nuclei/v3/cmd/nuclei
ensure_cmd dnsx go_install github.com/projectdiscovery/dnsx/cmd/dnsx
ensure_cmd katana go_install github.com/projectdiscovery/katana/cmd/katana

# Custom guard for httpx to prevent conflicts with standard repos
if [ ! -x "${HOME}/go/bin/httpx" ] && [ ! -x "/usr/local/go/bin/httpx" ]; then
  go_install github.com/projectdiscovery/httpx/cmd/httpx
else
  warn "projectdiscovery/httpx already installed — skipping"
fi

section "Specialized Crawlers"

if ! command -v kr >/dev/null 2>&1; then
  log "Installing kiterunner (kr)..."
  if [ ! -d "${TOOLS_DIR}/kiterunner" ]; then
    git clone https://github.com/assetnote/kiterunner.git "${TOOLS_DIR}/kiterunner" || warn "Failed to clone kiterunner"
  fi
  if [ -d "${TOOLS_DIR}/kiterunner" ]; then
    (cd "${TOOLS_DIR}/kiterunner" && make build) || warn "Failed to build kiterunner"
    if [ -f "${TOOLS_DIR}/kiterunner/dist/kr" ]; then
      sudo ln -sf "${TOOLS_DIR}/kiterunner/dist/kr" "${OSINT_BIN}/kr"
      log "kiterunner installed (${OSINT_BIN}/kr)"
    fi
  fi
else
  warn "kiterunner (kr) already installed — skipping"
fi

log "Module 02: Web enumeration tools complete."