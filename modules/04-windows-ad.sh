#!/usr/bin/env bash
# /opt/tools/installer/modules/04-windows-ad.sh
# Phase 6 Module: Active Directory & Windows Exploitation

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/config/defaults.sh"
source "${SCRIPT_DIR}/lib/log.sh"
source "${SCRIPT_DIR}/lib/pkg.sh"
source "${SCRIPT_DIR}/lib/github.sh"
source "${SCRIPT_DIR}/lib/git.sh"
source "${SCRIPT_DIR}/lib/trap.sh"
source "${SCRIPT_DIR}/managers/uv.sh"
source "${SCRIPT_DIR}/managers/ruby.sh"
source "${SCRIPT_DIR}/managers/golang.sh"

export DEBIAN_FRONTEND=noninteractive

banner "Module 04: Windows & Active Directory Attacks"

section "Impacket"

if ! command -v impacket-secretsdump >/dev/null 2>&1; then
  log "Installing Impacket..."
  IMPACKET_DIR="${TOOLS_DIR}/impacket"
  clone_or_update "https://github.com/fortra/impacket.git" "${IMPACKET_DIR}"
  if [ -d "${IMPACKET_DIR}" ]; then
    (
      cd "${IMPACKET_DIR}"
      uv venv --clear .venv
      uv pip install --python .venv/bin/python -e .
    ) && {
      for script in "${IMPACKET_DIR}/.venv/bin/"impacket-*; do
        [ -x "$script" ] || continue
        sudo ln -sf "$script" "${OSINT_BIN}/$(basename "$script")"
      done
      log "Impacket installed — scripts symlinked to ${OSINT_BIN}"
    } || warn "Impacket: uv pip install failed"
  fi
else
  warn "impacket already installed — skipping"
fi

section "Core AD Frameworks"

ensure_cmd evil-winrm gem_install evil-winrm

if ! command -v nxc >/dev/null 2>&1; then
  log "Installing NetExec (nxc)..."
  NXC_DIR="${TOOLS_DIR}/netexec"
  clone_or_update "https://github.com/Pennyw0rth/NetExec.git" "${NXC_DIR}"
  if [ -d "${NXC_DIR}" ]; then
    (
      cd "${NXC_DIR}"
      uv venv --clear .venv
      uv pip install --python .venv/bin/python -e .
    ) && {
      sudo ln -sf "${NXC_DIR}/.venv/bin/nxc" "${OSINT_BIN}/nxc"
      sudo ln -sf "${NXC_DIR}/.venv/bin/netexec" "${OSINT_BIN}/netexec" 2>/dev/null || true
      log "NetExec installed (${OSINT_BIN}/nxc)"
    } || warn "NetExec: uv pip install failed"
  fi
else
  warn "nxc already installed — skipping"
fi

section "BloodHound CE & Neo4j"

if ! command -v neo4j >/dev/null 2>&1; then
  log "Installing Neo4j (BloodHound backend)..."
  wget -qO- https://debian.neo4j.com/neotechnology.gpg.key | sudo gpg --dearmor -o /usr/share/keyrings/neo4j.gpg || warn "Failed to import Neo4j GPG key"
  echo "deb [signed-by=/usr/share/keyrings/neo4j.gpg] https://debian.neo4j.com stable latest" | sudo tee /etc/apt/sources.list.d/neo4j.list >/dev/null
  sudo apt update -y >/dev/null 2>&1 || true
  apt_install neo4j
else
  warn "neo4j already installed — skipping"
fi

if ! command -v bloodhound >/dev/null 2>&1; then
  log "Installing BloodHound CE..."
  BLOODHOUND_DIR="${TOOLS_DIR}/BloodHound"
  BH_URL=$(fetch_latest_github_release "SpecterOps/BloodHound" "linux-amd64" "sha256\|arm")
  if [ -n "${BH_URL:-}" ]; then
    bh_zip="/tmp/BloodHound.zip"
    register_tmp "${bh_zip}"
    wget -q --show-progress -O "${bh_zip}" "${BH_URL}" \
      && unzip -qo "${bh_zip}" -d "${BLOODHOUND_DIR}" \
      && sudo chmod +x "${BLOODHOUND_DIR}"/BloodHound* \
      && sudo ln -sf "${BLOODHOUND_DIR}/BloodHound" "${OSINT_BIN}/bloodhound" \
      && log "BloodHound CE installed (${OSINT_BIN}/bloodhound)" \
      || warn "BloodHound CE: download/unzip failed"
  else
    warn "Could not resolve BloodHound CE release URL"
  fi
else
  warn "bloodhound already installed — skipping"
fi

ensure_cmd bloodhound-python uv_tool_install bloodhound-python bloodhound bloodhound-python

section "AD Enumeration Scripts"

if ! command -v kerbrute >/dev/null 2>&1; then
  log "Installing Kerbrute..."
  KERB_URL=$(fetch_latest_github_release "ropnop/kerbrute" "linux_amd64")
  if [ -n "${KERB_URL:-}" ]; then
    download_binary "${KERB_URL}" "${OSINT_BIN}/kerbrute"
  else
    warn "Could not resolve kerbrute release URL"
  fi
else
  warn "kerbrute already installed — skipping"
fi

ensure_cmd enum4linux-ng install_git_uv_tool "https://github.com/cddmp/enum4linux-ng.git" "${TOOLS_DIR}/enum4linux-ng" "requirements.txt" "enum4linux-ng.py" "${OSINT_BIN}/enum4linux-ng"
ensure_cmd ldapdomaindump uv_tool_install ldapdomaindump ldapdomaindump ldapdomaindump
ensure_cmd pypykatz uv_tool_install pypykatz pypykatz pypykatz

section "Pivoting & Tunnelling"

if ! command -v ligolo-proxy >/dev/null 2>&1; then
  log "Installing Ligolo-ng..."
  LIGOLO_PROXY_URL=$(fetch_latest_github_release "nicocha30/ligolo-ng" "proxy.*linux.*amd64.*tar\.gz" "agent\|arm\|386")
  LIGOLO_AGENT_URL=$(fetch_latest_github_release "nicocha30/ligolo-ng" "agent.*linux.*amd64.*tar\.gz" "proxy\|arm\|386")
  LIGOLO_WIN_URL=$(fetch_latest_github_release "nicocha30/ligolo-ng" "agent.*windows.*amd64.*tar\.gz" "proxy\|arm\|386")

  if [ -n "${LIGOLO_PROXY_URL:-}" ]; then
    download_and_extract_tar "${LIGOLO_PROXY_URL}" "${OSINT_BIN}" "proxy"
    sudo mv "${OSINT_BIN}/proxy" "${OSINT_BIN}/ligolo-proxy"
    log "ligolo-proxy installed (${OSINT_BIN}/ligolo-proxy)"
  else
    warn "Could not resolve ligolo-ng proxy URL"
  fi

  if [ -n "${LIGOLO_AGENT_URL:-}" ]; then
    download_and_extract_tar "${LIGOLO_AGENT_URL}" "${TOOLS_DIR}" "agent"
    sudo mv "${TOOLS_DIR}/agent" "${TOOLS_DIR}/ligolo-agent-linux-amd64"
    log "ligolo-agent (Linux) saved to ${TOOLS_DIR}/ligolo-agent-linux-amd64"
  fi

  if [ -n "${LIGOLO_WIN_URL:-}" ]; then
    ligolo_win_tmp="/tmp/ligolo-agent-win.tar.gz"
    register_tmp "${ligolo_win_tmp}"
    wget -q --show-progress -O "${ligolo_win_tmp}" "${LIGOLO_WIN_URL}" \
      && tar -xzf "${ligolo_win_tmp}" -C /tmp \
      && sudo mv /tmp/agent.exe "${TOOLS_DIR}/ligolo-agent-windows-amd64.exe" \
      && log "ligolo-agent (Windows) saved to ${TOOLS_DIR}/ligolo-agent-windows-amd64.exe" \
      || warn "Failed to extract Ligolo-ng Windows agent"
  fi
else
  warn "ligolo-proxy already installed — skipping"
fi

if ! command -v chisel >/dev/null 2>&1; then
  log "Installing Chisel..."
  CHISEL_URL=$(fetch_latest_github_release "jpillora/chisel" "linux_amd64\.gz" "arm\|386")
  CHISEL_WIN_URL=$(fetch_latest_github_release "jpillora/chisel" "windows_amd64\.gz" "arm\|386")

  if [ -n "${CHISEL_URL:-}" ]; then
    chisel_gz="/tmp/chisel.gz"
    register_tmp "${chisel_gz}"
    wget -q -O "${chisel_gz}" "${CHISEL_URL}" \
      && gunzip -f "${chisel_gz}" \
      && sudo mv /tmp/chisel "${OSINT_BIN}/chisel" \
      && sudo chmod +x "${OSINT_BIN}/chisel" \
      && log "chisel installed (${OSINT_BIN}/chisel)" \
      || warn "Failed to install chisel (Linux)"
  fi

  if [ -n "${CHISEL_WIN_URL:-}" ]; then
    chisel_win_gz="/tmp/chisel-win.gz"
    register_tmp "${chisel_win_gz}"
    wget -q -O "${chisel_win_gz}" "${CHISEL_WIN_URL}" \
      && gunzip -f "${chisel_win_gz}" \
      && sudo mv /tmp/chisel_windows_amd64 "${TOOLS_DIR}/chisel-windows-amd64.exe" \
      && log "chisel (Windows) saved to ${TOOLS_DIR}/chisel-windows-amd64.exe" \
      || warn "Failed to install chisel (Windows)"
  fi
else
  warn "chisel already installed — skipping"
fi

section "Advanced Shell Handlers"

ensure_cmd pwncat uv_tool_install pwncat-cs pwncat-cs pwncat

section "Post-Install Instructions"

log "Module 04: Windows AD tools complete."
echo ""
echo "====================================================================="
echo " ── BloodHound CE (first-run setup) ──────────────────────────────"
echo "   1. Start Neo4j:   sudo neo4j start"
echo "   2. Browse to:     http://localhost:7474  (default: neo4j / neo4j)"
echo "   3. Change the default password"
echo "   4. Launch BloodHound and connect to the Neo4j instance"
echo "   Collect data: bloodhound-python -u <user> -p <pass> -d <domain> -c All"
echo ""
echo " ── Ligolo-ng (interface setup, run once) ────────────────────────"
echo "   sudo ip tuntap add user \$USER mode tun ligolo"
echo "   sudo ip link set ligolo up"
echo "   Then run the proxy:  ligolo-proxy -selfcert -laddr 0.0.0.0:11601"
echo "   Drop ligolo-agent binaries from ${TOOLS_DIR} onto the target"
echo "====================================================================="