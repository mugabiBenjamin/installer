#!/usr/bin/env bash
# /opt/tools/installer/lib/pkg.sh
# Package manager wrappers and command verification guards

apt_install() {
  local pkg="$1"
  if sudo apt install -y "$pkg" 2>/dev/null; then
    log "apt: $pkg installed"
  else
    warn "apt: failed to install $pkg — package may not be available"
  fi
}

brew_install() {
  local pkg="$1"
  if ! command -v brew >/dev/null 2>&1; then
    warn "brew not available; skipping $pkg"
    return 0
  fi
  if brew list --formula "$pkg" &>/dev/null; then
    warn "brew: $pkg already installed — upgrading..."
    brew upgrade "$pkg" 2>/dev/null || true
  else
    brew install "$pkg" && log "brew: $pkg installed" || warn "brew: failed to install $pkg"
  fi
}

cargo_install() {
  local pkg="$1"
  if ! command -v cargo >/dev/null 2>&1; then
    warn "cargo not available; skipping $pkg"
    return 0
  fi
  cargo install "$pkg" --locked && log "cargo: $pkg installed/updated" || warn "cargo: failed to install $pkg"
}

go_install() {
  local pkg="$1"
  if ! command -v go >/dev/null 2>&1; then
    warn "go not available; skipping $pkg"
    return 0
  fi
  go install "${pkg}@latest" && log "go install: $pkg done" || warn "go install: failed for $pkg"
}

gem_install() {
  local pkg="$1"
  if ! command -v gem >/dev/null 2>&1; then
    sudo apt install -y ruby ruby-dev build-essential 2>/dev/null || true
  fi
  sudo gem install "$pkg" && log "gem: $pkg installed" || warn "gem: failed to install $pkg"
}

mamba_install() {
  local pkg="$1" channel="${2:-conda-forge}"
  if ! command -v mamba >/dev/null 2>&1; then
    warn "mamba not available; skipping $pkg"
    return 0
  fi
  mamba install -n base -c "${channel}" -y "$pkg" && log "mamba: $pkg installed" || warn "mamba: failed to install $pkg"
}

uv_tool_install() {
  local name="$1" pkg="$2" binary="$3" link_name="${4:-$3}"
  local tool_dir="${TOOLS_DIR}/${name}"

  if command -v "${link_name}" >/dev/null 2>&1; then
    warn "${link_name} already installed — skipping"
    return 0
  fi

  if ! command -v uv >/dev/null 2>&1; then
    warn "uv not available; skipping ${name}"
    return 0
  fi

  log "Installing ${name} via uv..."
  sudo mkdir -p "${tool_dir}"
  sudo chown "$USER":"$USER" "${tool_dir}"

  uv venv --clear "${tool_dir}/.venv" \
    && uv pip install --python "${tool_dir}/.venv/bin/python" "${pkg}" \
    && sudo ln -sf "${tool_dir}/.venv/bin/${binary}" "${OSINT_BIN}/${link_name}" \
    && log "${name} installed (${OSINT_BIN}/${link_name})" \
    || warn "${name}: uv install failed"
}

ensure_cmd() {
  local cmd="$1"; shift
  if command -v "$cmd" >/dev/null 2>&1; then
    warn "$cmd already installed — skipping"
    return 0
  fi
  "$@"
}