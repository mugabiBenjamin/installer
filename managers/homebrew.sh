#!/usr/bin/env bash
# /opt/tools/installer/managers/homebrew.sh
# Homebrew package manager setup and PATH persistence

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/config/defaults.sh"
source "${SCRIPT_DIR}/lib/log.sh"
source "${SCRIPT_DIR}/lib/env.sh"

source_brew() {
  if [ -x /home/linuxbrew/.linuxbrew/bin/brew ]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  elif [ -x "${HOME}/.linuxbrew/bin/brew" ]; then
    eval "$("${HOME}/.linuxbrew/bin/brew" shellenv)"
  fi
}

brew_rc_line() {
  if [ -x /home/linuxbrew/.linuxbrew/bin/brew ]; then
    echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"'
  elif [ -x "${HOME}/.linuxbrew/bin/brew" ]; then
    echo 'eval "$("${HOME}/.linuxbrew/bin/brew" shellenv)"'
  fi
}

install_homebrew() {
  log "Setting up Homebrew..."
  if ! command -v brew >/dev/null 2>&1; then
    NONINTERACTIVE=1 /bin/bash -c \
      "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" \
      || warn "Homebrew installation failed"
  else
    log "Homebrew already installed."
  fi

  source_brew

  local rc_line
  rc_line=$(brew_rc_line)
  if [ -n "${rc_line}" ]; then
    persist_line 'brew shellenv' "${rc_line}"
  else
    warn "Could not resolve Homebrew PATH — subsequent brew installs may fail"
  fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  install_homebrew
fi