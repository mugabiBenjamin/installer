#!/usr/bin/env bash
# /opt/tools/installer/managers/ruby.sh
# Ruby base installation, Gem management and user bin resolution

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/config/defaults.sh"
source "${SCRIPT_DIR}/lib/log.sh"
source "${SCRIPT_DIR}/lib/env.sh"

ensure_gem() {
  if ! command -v gem >/dev/null 2>&1; then
    log "Installing Ruby and Gem dependencies..."
    sudo apt update -y >/dev/null 2>&1 || true
    sudo apt install -y ruby ruby-dev build-essential \
      || warn "Failed to install ruby core packages"
  fi
}

gem_user_bin_path() {
  if command -v ruby >/dev/null 2>&1; then
    local gem_dir
    gem_dir=$(ruby -e 'puts Gem.user_dir' 2>/dev/null || true)
    if [ -n "${gem_dir:-}" ]; then
      export_path "${gem_dir}/bin"
    fi
  fi
}

gem_install() {
  local pkg="$1"
  ensure_gem
  sudo gem install "$pkg" \
    && log "gem: $pkg installed/updated" \
    || warn "gem: failed to install $pkg"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  ensure_gem
  gem_user_bin_path
fi