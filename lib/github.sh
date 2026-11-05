#!/usr/bin/env bash
# /opt/tools/installer/lib/github.sh
# GitHub API release queries and archive download/extraction primitives

# Used by the download helpers below; source it here so modules that only
# source lib/github.sh still have register_tmp available.
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/trap.sh"

fetch_latest_github_release() {
  local repo="$1" pattern="$2" exclude="${3:-__NO_EXCLUDE__}"
  local result
  result=$(wget -qO- "https://api.github.com/repos/${repo}/releases/latest" 2>/dev/null \
    | grep '"browser_download_url"' \
    | grep -i "${pattern}" \
    | grep -v "${exclude}" \
    | head -1 \
    | cut -d '"' -f 4) || true
  printf '%s' "${result}"
}

download_binary() {
  local url="$1" dest="$2" tmp
  tmp="$(mktemp "${TMPDIR:-/tmp}/download_binary.XXXXXX")" || {
    warn "Failed to create a temporary file for ${dest}"
    return 1
  }
  register_tmp "${tmp}"
  log "Downloading binary from ${url} to ${dest}..."
  if wget -q --show-progress -O "${tmp}" "${url}"; then
    sudo install -Dm755 "${tmp}" "${dest}"
  else
    warn "Failed to download ${url}"
    return 1
  fi
}

download_and_extract_tar() {
  local url="$1" dest_dir="$2" binary_name="$3"
  local tmp_tar="/tmp/download_$(date +%s).tar.gz"
  register_tmp "${tmp_tar}"
  wget -q --show-progress -O "${tmp_tar}" "${url}" \
    && tar -xzf "${tmp_tar}" -C /tmp \
    && sudo mv "/tmp/${binary_name}" "${dest_dir}/${binary_name}" \
    && sudo chmod +x "${dest_dir}/${binary_name}"
}

download_and_unzip() {
  local url="$1" dest_dir="$2" binary_name="$3"
  local tmp_zip="/tmp/download_$(date +%s).zip"
  register_tmp "${tmp_zip}"
  wget -q --show-progress -O "${tmp_zip}" "${url}" \
    && unzip -qo "${tmp_zip}" "${binary_name}" -d /tmp \
    && sudo mv "/tmp/${binary_name}" "${dest_dir}/${binary_name}" \
    && sudo chmod +x "${dest_dir}/${binary_name}"
}