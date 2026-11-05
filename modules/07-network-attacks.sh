#!/usr/bin/env bash
# /opt/tools/installer/modules/07-network-attacks.sh
# Phase 8 Module: Active Network Protocol Attacks & Poisoning

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/config/defaults.sh"
source "${SCRIPT_DIR}/lib/log.sh"
source "${SCRIPT_DIR}/lib/pkg.sh"
source "${SCRIPT_DIR}/lib/git.sh"
source "${SCRIPT_DIR}/lib/github.sh"
source "${SCRIPT_DIR}/managers/uv.sh"

export DEBIAN_FRONTEND=noninteractive

banner "Module 07: Network Protocol Attacks"

section "Responder"

if ! command -v responder >/dev/null 2>&1; then
  log "Installing Responder..."
  clone_or_update "https://github.com/lgandx/Responder.git" "${TOOLS_DIR}/Responder"
  if [ -f "${TOOLS_DIR}/Responder/Responder.py" ]; then
    sudo tee "${OSINT_BIN}/responder" >/dev/null <<EOF
#!/usr/bin/env bash
if [ \$# -eq 0 ]; then
  echo -e "\e[1;33m[!] Usage: sudo responder -I <interface>\e[0m"
  echo -e "    Example: sudo responder -I eth0"
  exit 1
fi
exec sudo python3 "${TOOLS_DIR}/Responder/Responder.py" "\$@"
EOF
    sudo chmod +x "${OSINT_BIN}/responder"
    log "Responder installed with sudo wrapper (${OSINT_BIN}/responder)"
  fi
else
  warn "responder already installed — skipping"
fi

section "IPv6/DNS Poisoning (mitm6)"

if ! command -v mitm6 >/dev/null 2>&1; then
  log "Installing mitm6..."
  uv_tool_install "mitm6" "mitm6" "mitm6"
  # Overwrite the default uv wrapper to enforce sudo and hint usage
  sudo tee "${OSINT_BIN}/mitm6" >/dev/null <<EOF
#!/usr/bin/env bash
if [ \$# -eq 0 ]; then
  echo -e "\e[1;33m[!] Usage: sudo mitm6 -i <interface> -d <domain>\e[0m"
  echo -e "    Example: sudo mitm6 -i eth0 -d local.corp"
  exit 1
fi
exec sudo "${TOOLS_DIR}/mitm6/.venv/bin/mitm6" "\$@"
EOF
  sudo chmod +x "${OSINT_BIN}/mitm6"
  log "mitm6 wrapper updated to enforce sudo/interface arguments"
else
  warn "mitm6 already installed — skipping"
fi

section "Bettercap"

if ! command -v bettercap >/dev/null 2>&1; then
  log "Installing bettercap..."
  # Bettercap releases as a .zip, fallback to brew if GitHub fetch fails
  BETTERCAP_ZIP_URL=$(fetch_latest_github_release "bettercap/bettercap" "linux_amd64.*\.zip")
  if [ -n "${BETTERCAP_ZIP_URL:-}" ]; then
    download_and_unzip "${BETTERCAP_ZIP_URL}" "${OSINT_BIN}" "bettercap" \
      || brew_install bettercap
  else
    warn "Could not resolve bettercap GitHub release; falling back to brew..."
    brew_install bettercap
  fi
else
  warn "bettercap already installed — skipping"
fi

section "Coercion Tools"

ensure_cmd coercer uv_tool_install coercer coercer coercer

if ! command -v petitpotam >/dev/null 2>&1; then
  log "Installing PetitPotam..."
  clone_or_update "https://github.com/topotam/PetitPotam.git" "${TOOLS_DIR}/PetitPotam"
  if [ -f "${TOOLS_DIR}/PetitPotam/PetitPotam.py" ]; then
    sudo tee "${OSINT_BIN}/petitpotam" >/dev/null <<EOF
#!/usr/bin/env bash
exec python3 "${TOOLS_DIR}/PetitPotam/PetitPotam.py" "\$@"
EOF
    sudo chmod +x "${OSINT_BIN}/petitpotam"
    log "PetitPotam installed (${OSINT_BIN}/petitpotam)"
  fi
else
  warn "petitpotam already installed — skipping"
fi

echo ""
echo "====================================================================="
echo " ── Network Attacks Notice ────────────────────────────────────────"
echo "   Responder and mitm6 require a live network interface and must"
echo "   be run with sudo (wrappers have been created to enforce this)."
echo "====================================================================="
log "Module 07: Network attack tools complete."