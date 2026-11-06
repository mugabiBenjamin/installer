#!/usr/bin/env bash
# /opt/tools/installer/modules/03-recon-passive.sh
# Phase 5 Module: Passive Intelligence & OSINT Reconnaissance

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/config/defaults.sh"
source "${SCRIPT_DIR}/lib/log.sh"
source "${SCRIPT_DIR}/lib/env.sh"
source "${SCRIPT_DIR}/lib/pkg.sh"
source "${SCRIPT_DIR}/lib/github.sh"
source "${SCRIPT_DIR}/lib/git.sh"
source "${SCRIPT_DIR}/managers/uv.sh"
source "${SCRIPT_DIR}/managers/golang.sh"

banner "Module 03 (Passive): Reconnaissance & OSINT"

section "OSINT CLI Utilities"

ensure_cmd shodan uv_tool_install shodan shodan shodan
ensure_cmd censys uv_tool_install censys censys censys
ensure_cmd cloud_enum uv_tool_install cloud_enum "git+https://github.com/initstring/cloud_enum.git" cloud_enum
ensure_cmd holehe uv_tool_install holehe holehe holehe
ensure_cmd crosslinked uv_tool_install crosslinked crosslinked crosslinked

section "Complex OSINT Frameworks"

# theHarvester
if ! command -v theHarvester >/dev/null 2>&1; then
  log "Installing theHarvester..."
  clone_or_update "https://github.com/laramies/theHarvester.git" "${TOOLS_DIR}/theHarvester"
  if command -v uv >/dev/null 2>&1; then
    (
      cd "${TOOLS_DIR}/theHarvester"
      uv sync
    ) && {
      sudo ln -sf "${TOOLS_DIR}/theHarvester/.venv/bin/theHarvester" "${OSINT_BIN}/theHarvester"
      log "theHarvester installed (${OSINT_BIN}/theHarvester)"
    } || warn "theHarvester uv sync failed"
  else
    warn "uv not available — theHarvester requires uv"
  fi
else
  warn "theHarvester already installed — skipping"
fi

# SpiderFoot
if ! command -v spiderfoot >/dev/null 2>&1; then
  log "Installing SpiderFoot..."
  clone_or_update "https://github.com/smicallef/spiderfoot.git" "${TOOLS_DIR}/spiderfoot"
  if [ -f "${TOOLS_DIR}/spiderfoot/requirements.txt" ]; then
    (
      cd "${TOOLS_DIR}/spiderfoot"
      uv venv --clear .venv
      # Workaround: lxml 4.9.x has no standard wheel for newest Python versions
      grep -q '^lxml' requirements.txt && sed -i '/^lxml/d' requirements.txt
      uv pip install --python .venv/bin/python "lxml>=4.9.2" --only-binary=:all: --no-cache || warn "lxml binary wheel failed"
      uv pip install --python .venv/bin/python -r requirements.txt
    ) && {
      sudo tee "${OSINT_BIN}/spiderfoot" >/dev/null <<EOF
#!/usr/bin/env bash
exec "${TOOLS_DIR}/spiderfoot/.venv/bin/python" "${TOOLS_DIR}/spiderfoot/sf.py" "\$@"
EOF
      sudo chmod +x "${OSINT_BIN}/spiderfoot"
      log "SpiderFoot installed (${OSINT_BIN}/spiderfoot)"
    } || warn "SpiderFoot: pip install failed"
  fi
else
  warn "spiderfoot already installed — skipping"
fi

# Recon-ng
if ! command -v recon-ng >/dev/null 2>&1; then
  log "Installing Recon-ng..."
  install_git_uv_tool "https://github.com/lanmaster53/recon-ng.git" "${TOOLS_DIR}/recon-ng" "REQUIREMENTS" "recon-ng" "${OSINT_BIN}/recon-ng"
else
  warn "recon-ng already installed — skipping"
fi

# Sherlock
if ! command -v sherlock >/dev/null 2>&1; then
  log "Installing Sherlock..."
  clone_or_update "https://github.com/sherlock-project/sherlock.git" "${TOOLS_DIR}/sherlock"
  if [ -f "${TOOLS_DIR}/sherlock/pyproject.toml" ]; then
    (
      cd "${TOOLS_DIR}/sherlock"
      uv venv --clear .venv
      uv pip install --python .venv/bin/python -e .
    ) && {
      if [ -x "${TOOLS_DIR}/sherlock/.venv/bin/sherlock" ]; then
        sudo ln -sf "${TOOLS_DIR}/sherlock/.venv/bin/sherlock" "${OSINT_BIN}/sherlock"
        log "Sherlock installed (${OSINT_BIN}/sherlock)"
      else
        warn "Sherlock executable was not created in .venv/bin"
      fi
    } || warn "Sherlock: pip install failed"
  fi
else
  warn "sherlock already installed — skipping"
fi

# Trufflehog
if ! command -v trufflehog >/dev/null 2>&1; then
  log "Installing Trufflehog..."
  TRUFFLE_URL=$(fetch_latest_github_release "trufflesecurity/trufflehog" "trufflehog_.*_linux_amd64\.tar\.gz")
  if [ -n "${TRUFFLE_URL:-}" ]; then
    download_and_extract_tar "${TRUFFLE_URL}" "${OSINT_BIN}" "trufflehog"
    log "Trufflehog installed (${OSINT_BIN}/trufflehog)"
  else
    warn "Could not resolve Trufflehog release URL"
  fi
else
  warn "trufflehog already installed — skipping"
fi

section "Go Passive Recon Tools"

ensure_cmd assetfinder go_install github.com/tomnomnom/assetfinder
ensure_cmd waybackurls go_install github.com/tomnomnom/waybackurls

section "Configuration Templates"

load_env "${SCRIPT_DIR}/.env"

# theHarvester API keys
HARVESTER_CONF_DIR="${HOME}/.theHarvester"
HARVESTER_CONF_FILE="${HARVESTER_CONF_DIR}/api-keys.yaml"
if [ ! -f "${HARVESTER_CONF_FILE}" ]; then
  log "Creating theHarvester api-keys.yaml from .env..."
  mkdir -p "${HARVESTER_CONF_DIR}"
  (
    umask 077
    cat <<EOF > "${HARVESTER_CONF_FILE}"
# Generated from .env by the installer. Edit .env instead of this file.
apikeys:
  shodan: "${SHODAN_API_KEY:-}"
  hunter: "${HUNTER_API_KEY:-}"
  securityTrails: "${SECURITYTRAILS_API_KEY:-}"
  fullhunt: "${FULLHUNT_API_KEY:-}"
EOF
  )
  chmod 600 "${HARVESTER_CONF_FILE}"
else
  log "theHarvester api-keys.yaml already exists — preserving"
fi

# Amass config
AMASS_CONF_DIR="${HOME}/.config/amass"
AMASS_CONF_FILE="${AMASS_CONF_DIR}/config.ini"
if [ ! -f "${AMASS_CONF_FILE}" ]; then
  log "Creating Amass config.ini from .env..."
  mkdir -p "${AMASS_CONF_DIR}"
  (
    umask 077
    {
      amass_has_creds=false
      echo "# Generated from .env by the installer. Edit .env instead of this file."
      if [ -n "${SHODAN_API_KEY:-}" ]; then
        amass_has_creds=true
        echo
        echo "[data_sources.Shodan]"
        echo "apikey = ${SHODAN_API_KEY}"
      fi
      if [ -n "${CENSYS_API_ID:-}" ] && [ -n "${CENSYS_API_SECRET:-}" ]; then
        amass_has_creds=true
        echo
        echo "[data_sources.Censys]"
        echo "apikey = ${CENSYS_API_ID}"
        echo "secret = ${CENSYS_API_SECRET}"
      fi
      if [ "$amass_has_creds" = false ]; then
        echo
        echo "# No Amass credentials were found in .env."
        echo "# Set SHODAN_API_KEY, CENSYS_API_ID, and CENSYS_API_SECRET, then remove this file and rerun."
      fi
    } > "${AMASS_CONF_FILE}"
  )
  chmod 600 "${AMASS_CONF_FILE}"
else
  log "Amass config.ini already exists — preserving"
fi

# Shodan CLI
if [ -n "${SHODAN_API_KEY:-}" ]; then
  if [ -d "${HOME}/.shodan" ]; then
    SHODAN_CONF_DIR="${HOME}/.shodan"
  else
    SHODAN_CONF_DIR="${HOME}/.config/shodan"
  fi
  SHODAN_KEY_FILE="${SHODAN_CONF_DIR}/api_key"
  if [ ! -f "${SHODAN_KEY_FILE}" ]; then
    log "Writing Shodan CLI API key from .env..."
    mkdir -p "${SHODAN_CONF_DIR}"
    (umask 077; printf '%s\n' "${SHODAN_API_KEY}" > "${SHODAN_KEY_FILE}")
    chmod 600 "${SHODAN_KEY_FILE}"
  else
    log "Shodan CLI API key already exists — preserving"
  fi
fi

# Censys CLI
if [ -n "${CENSYS_API_ID:-}" ] || [ -n "${CENSYS_API_SECRET:-}" ] || [ -n "${CENSYS_ASM_API_KEY:-}" ]; then
  CENSYS_CONF_DIR="${HOME}/.config/censys"
  CENSYS_CONF_FILE="${CENSYS_CONF_DIR}/censys.cfg"
  if [ ! -f "${CENSYS_CONF_FILE}" ]; then
    log "Writing Censys CLI config from .env..."
    mkdir -p "${CENSYS_CONF_DIR}"
    (
      umask 077
      cat <<EOF > "${CENSYS_CONF_FILE}"
[DEFAULT]
api_id = ${CENSYS_API_ID:-}
api_secret = ${CENSYS_API_SECRET:-}
asm_api_key = ${CENSYS_ASM_API_KEY:-}
color = auto
EOF
    )
    chmod 600 "${CENSYS_CONF_FILE}"
  else
    log "Censys CLI config already exists — preserving"
  fi
fi

log "Module 03 (Passive): Recon tools complete."
