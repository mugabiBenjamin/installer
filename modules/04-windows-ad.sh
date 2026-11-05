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

IMPACKET_CMDS=(impacket-secretsdump impacket-psexec impacket-wmiexec)
impacket_ready=true
for cmd in "${IMPACKET_CMDS[@]}"; do
  command -v "$cmd" >/dev/null 2>&1 || impacket_ready=false
done

if [ "$impacket_ready" = false ]; then
  log "Installing Impacket..."
  IMPACKET_DIR="${TOOLS_DIR}/impacket"
  clone_or_update "https://github.com/fortra/impacket.git" "${IMPACKET_DIR}"
  if [ -d "${IMPACKET_DIR}" ]; then
    (
      cd "${IMPACKET_DIR}"
      uv venv --clear .venv && uv pip install --python .venv/bin/python -e .
    ) && {
      # Upstream now installs scripts as psexec.py, wmiexec.py, etc. rather
      # than the impacket-* names provided by the Debian package.
      for script in "${IMPACKET_DIR}/.venv/bin/"*.py; do
        [ -x "$script" ] || continue
        sudo ln -sf "$script" "${OSINT_BIN}/impacket-$(basename "$script" .py)"
      done
      hash -r
      for cmd in "${IMPACKET_CMDS[@]}"; do
        command -v "$cmd" >/dev/null 2>&1 || warn "Impacket: $cmd still missing"
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

section "BloodHound CE"

if ! command -v bloodhound-cli >/dev/null 2>&1; then
  log "Installing BloodHound CLI..."
  BH_CLI_URL=$(fetch_latest_github_release "SpecterOps/bloodhound-cli" "bloodhound-cli-linux-amd64\.tar\.gz" "md5")
  if [ -n "${BH_CLI_URL:-}" ]; then
    bh_cli_tar="/tmp/bloodhound-cli.tar.gz"
    bh_cli_dir="$(mktemp -d /tmp/bloodhound-cli.XXXXXX)" || bh_cli_dir=""
    if [ -n "${bh_cli_dir}" ]; then
      register_tmp "${bh_cli_tar}"
      register_tmp "${bh_cli_dir}"
      wget -q --show-progress -O "${bh_cli_tar}" "${BH_CLI_URL}" \
        && tar -xzf "${bh_cli_tar}" -C "${bh_cli_dir}" \
        && sudo install -m 0755 "${bh_cli_dir}/bloodhound-cli" "${OSINT_BIN}/bloodhound-cli" \
        && log "BloodHound CLI installed (${OSINT_BIN}/bloodhound-cli)" \
        || warn "BloodHound CLI: download/install failed"
    else
      warn "Failed to create temporary directory for BloodHound CLI"
    fi
  else
    warn "Could not resolve BloodHound CLI release URL"
  fi
else
  warn "bloodhound-cli already installed — skipping"
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

if ! command -v pwncat >/dev/null 2>&1; then
  uv_tool_install pwncat-cs pwncat-cs pwncat-cs pwncat-cs
  PWNCAT_DIR="${TOOLS_DIR}/pwncat-cs"
  # pwncat-cs 0.5.4 still imports pkg_resources, which needs the distutils
  # shim from setuptools<81 and an explicit setuptools import on Python 3.12.
  if uv pip install --python "${PWNCAT_DIR}/.venv/bin/python" 'setuptools<81'; then
    cat > "${PWNCAT_DIR}/pwncat-import-shim.py" <<'PY'
import sys
import setuptools  # noqa: F401
from pwncat.__main__ import main

sys.argv[0] = "pwncat"
main()
PY
    # Replace any stale symlink left by older installer versions.
    sudo rm -f "${OSINT_BIN}/pwncat"
    sudo tee "${OSINT_BIN}/pwncat" >/dev/null <<EOF
#!/usr/bin/env bash
exec "${PWNCAT_DIR}/.venv/bin/python" "${PWNCAT_DIR}/pwncat-import-shim.py" "\$@"
EOF
    sudo chmod +x "${OSINT_BIN}/pwncat"
    log "pwncat installed (${OSINT_BIN}/pwncat)"
  else
    warn "pwncat: failed to install setuptools compatibility dependency"
  fi
else
  warn "pwncat already installed — skipping"
fi

section "Post-Install Instructions"

log "Module 04: Windows AD tools complete."
echo ""
echo "====================================================================="
echo " ── BloodHound CE (first-run setup) ──────────────────────────────"
echo "   1. Start the Docker stack: bloodhound-cli install"
echo "   2. Browse to:              http://localhost:8080/ui/login"
echo "   3. Read the initial admin password from: bloodhound-cli logs"
echo "   Collect data: bloodhound-python -u <user> -p <pass> -d <domain> -c All"
echo ""
echo " ── Ligolo-ng (interface setup, run once) ────────────────────────"
echo "   sudo ip tuntap add user \$USER mode tun ligolo"
echo "   sudo ip link set ligolo up"
echo "   Then run the proxy:  ligolo-proxy -selfcert -laddr 0.0.0.0:11601"
echo "   Drop ligolo-agent binaries from ${TOOLS_DIR} onto the target"
echo "====================================================================="