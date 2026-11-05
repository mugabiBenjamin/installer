#!/usr/bin/env bash
# /opt/tools/installer/lib/git.sh
# Git repository management and uv python environment tool wrappers

clone_or_update() {
  local repo_url="$1" dest_dir="$2"
  if [ ! -d "${dest_dir}/.git" ]; then
    git clone "${repo_url}" "${dest_dir}" || warn "Failed to clone ${repo_url}"
  else
    git -C "${dest_dir}" pull || warn "Failed to update ${dest_dir}"
  fi
}

install_git_uv_tool() {
  local repo_url="$1" dir="$2" req_file="$3" binary_name="$4" wrapper_dest="$5"
  clone_or_update "${repo_url}" "${dir}"
  if [ -d "${dir}" ]; then
    (
      cd "${dir}"
      uv venv --clear .venv
      uv pip install --python .venv/bin/python -r "${req_file}"
    ) && {
      sudo tee "${wrapper_dest}" >/dev/null <<EOF
#!/usr/bin/env bash
exec "${dir}/.venv/bin/python" "${dir}/${binary_name}" "\$@"
EOF
      sudo chmod +x "${wrapper_dest}"
      log "Installed wrapper for ${binary_name} at ${wrapper_dest}"
    } || warn "uv install for ${dir} failed"
  fi
}