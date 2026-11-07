#!/usr/bin/env bash
# /opt/tools/installer/lib/env.sh
# PATH exports, profile persistence, and shell configuration integration

PROFILE_D="/etc/profile.d/ctf-tools.sh"

# Parse a KEY=VALUE dotenv file without sourcing it. This keeps .env from
# executing arbitrary shell code and avoids accidentally printing values.
load_env() {
  local env_file="${1:-}"
  if [ -z "$env_file" ]; then
    warn "load_env requires a file path"
    return 1
  fi
  [ -f "$env_file" ] || return 0

  local line key value
  while IFS= read -r line || [ -n "$line" ]; do
    line="${line%$'\r'}"
    line="${line#"${line%%[![:space:]]*}"}"
    line="${line%"${line##*[![:space:]]}"}"

    [ -z "$line" ] && continue
    case "$line" in
      \#*) continue ;;
      export\ *) line="${line#export }" ;;
    esac

    if [[ "$line" != *=* ]]; then
      warn "Ignoring malformed line in ${env_file}"
      continue
    fi

    key="${line%%=*}"
    value="${line#*=}"
    key="${key#"${key%%[![:space:]]*}"}"
    key="${key%"${key##*[![:space:]]}"}"

    if [[ ! "$key" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]]; then
      warn "Ignoring invalid variable name in ${env_file}: ${key}"
      continue
    fi

    value="${value#"${value%%[![:space:]]*}"}"
    value="${value%"${value##*[![:space:]]}"}"
    if [[ "$value" != \"*\" && "$value" != \'*\' ]]; then
      value="${value%%[[:space:]]#*}"
      value="${value%"${value##*[![:space:]]}"}"
    fi
    if [[ "$value" == \"*\" && "$value" == *\" ]]; then
      value="${value#\"}"
      value="${value%\"}"
    elif [[ "$value" == \'*\' && "$value" == *\' ]]; then
      value="${value#\'}"
      value="${value%\'}"
    fi

    export "${key}=${value}"
  done < "$env_file"

  log "Loaded environment variables from ${env_file}"
}

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