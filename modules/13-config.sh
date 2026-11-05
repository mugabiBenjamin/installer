#!/usr/bin/env bash
# /opt/tools/installer/modules/13-config.sh
# Phase 11 Module: Shell & Tool Quality-of-Life Configurations

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/config/defaults.sh"
source "${SCRIPT_DIR}/lib/log.sh"
source "${SCRIPT_DIR}/lib/env.sh"

banner "Module 13: Environment Configurations"

section "Tmux Configuration"

if [ ! -f "${HOME}/.tmux.conf" ]; then
  log "Creating baseline ~/.tmux.conf..."
  cat << 'EOF' > "${HOME}/.tmux.conf" || warn "Failed to write ~/.tmux.conf"
# Reassign prefix to Ctrl-a
set -g prefix C-a
unbind C-b
bind C-a send-prefix

# Enable mouse support
set -g mouse on

# Use Vi keys in copy mode
setw -g mode-keys vi

# Sensible pane splits
bind | split-window -h
bind - split-window -v
unbind '"'
unbind %

# Status bar with hostname and time
set -g status-right '#H | %Y-%m-%d %H:%M '
EOF
else
  log "~/.tmux.conf already exists — skipping baseline creation"
fi

section "Vim Configuration"

if [ ! -f "${HOME}/.vimrc" ]; then
  log "Creating baseline ~/.vimrc..."
  cat << 'EOF' > "${HOME}/.vimrc" || warn "Failed to write ~/.vimrc"
" Syntax highlighting
syntax on

" Show line numbers
set number

" 4-space indentation
set tabstop=4
set shiftwidth=4
set expandtab

" Disable swap files to prevent clutter during CTFs
set noswapfile

" Filetype detection
filetype plugin indent on
EOF
else
  log "~/.vimrc already exists — skipping baseline creation"
fi

section "ZSH Tweaks & Profile Loading"

ZSHRC="${HOME}/.zshrc"

if [ -f "${ZSHRC}" ]; then
  log "Applying Oh-My-Zsh alias collision fixes..."
  
  # 'gau' (GetAllUrls) and 'gf' (GrepBugs/GrepFilter) often conflict with Oh-My-Zsh git aliases
  if ! grep -qF "unalias gau" "${ZSHRC}" 2>/dev/null; then
    echo "unalias gau 2>/dev/null || true" >> "${ZSHRC}" || warn "Failed to append gau unalias to .zshrc"
  fi
  
  if ! grep -qF "unalias gf" "${ZSHRC}" 2>/dev/null; then
    echo "unalias gf 2>/dev/null || true" >> "${ZSHRC}" || warn "Failed to append gf unalias to .zshrc"
  fi
else
  log "~/.zshrc not found — skipping ZSH alias tweaks"
fi

# Ensure /etc/profile.d/ctf-tools.sh is loaded in zsh
ensure_profile_sourced_in_zsh

echo ""
echo "====================================================================="
echo " ── Mamba/Conda Shell Integration ─────────────────────────────────"
echo "   To enable the 'mamba' and 'conda' commands in your shell context,"
echo "   you must initialize them once for your user by running:"
echo "   "
echo "     ${MINIFORGE_DIR}/bin/conda init bash"
echo "   or"
echo "     ${MINIFORGE_DIR}/bin/conda init zsh"
echo "   "
echo "   After initializing, restart your terminal or source your RC file."
echo "====================================================================="

log "Module 13: Configuration complete."