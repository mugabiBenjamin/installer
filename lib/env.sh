#!/usr/bin/env bash
# /opt/tools/installer/lib/env.sh
# PATH exports, profile persistence, and shell configuration integration

PROFILE_D="/etc/profile.d/ctf-tools.sh"

persist_line() {
  local marker="$1" line="$2"
  sudo mkdir -p "$(dirname "${PROFILE_D}")"
  sudo touch "${PROFILE_D}"
  if ! sudo grep -qF "$marker" "${PROFILE_D}" 2>/dev/null; then
    printf '\n%s\n' "$line" | sudo tee -a "${PROFILE_D}" >/dev/null
    log "Persisted to ${PROFILE_D}: $line"
  else
    warn "$marker already in ${PROFILE_D} — skipping"
  fi
}

ensure_profile_sourced_in_zsh() {
  local zshrc="${HOME}/.zshrc"
  if [ -f "$zshrc" ]; then
    if ! grep -qF 'ctf-tools.sh' "$zshrc" 2>/dev/null; then
      printf '\nsource /etc/profile.d/ctf-tools.sh\n' >> "$zshrc"
      log "Added ctf-tools.sh source to $zshrc"
    else
      warn "ctf-tools.sh already sourced in $zshrc — skipping"
    fi
  fi
}

export_path() {
  local dir="$1"
  case ":${PATH}:" in
    *":${dir}:"*) ;;
    *)
      export PATH="${dir}:${PATH}"
      persist_line "${dir}" "export PATH=\"${dir}:\${PATH}\""
      ;;
  esac
}