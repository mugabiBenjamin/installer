#!/usr/bin/env bash
# /opt/tools/installer/lib/github.sh
# GitHub API release queries and archive download/extraction primitives

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
  local url="$1" dest="$2"
  log "Downloading binary from ${url} to ${dest}..."
  wget -q --show-progress -O "${dest}" "${url}" && sudo chmod +x "${dest}"
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