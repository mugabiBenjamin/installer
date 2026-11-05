#!/usr/bin/env bash
# /opt/tools/installer/config/categories.sh
# Category short-names mapping & default run lists

declare -A CATEGORY_MAP=(
  ["network"]="01-network.sh"
  ["web"]="02-web-enum.sh"
  ["recon"]="03-recon-passive.sh 03-recon-active.sh"
  ["windows"]="04-windows-ad.sh"
  ["postexploit"]="05-postexploit-linux.sh 05-postexploit-windows.sh"
  ["webattacks"]="06-web-attacks.sh"
  ["netattacks"]="07-network-attacks.sh"
  ["passwords"]="08-passwords.sh"
  ["wireless"]="09-wireless.sh"
  ["c2"]="10-c2.sh"
  ["re"]="11-re-forensics.sh"
  ["wordlists"]="12-wordlists.sh"
  ["config"]="13-config.sh"
  ["cargo"]="14-cargo-tools.sh"
  ["mamba"]="15-mamba-tools.sh"
  ["gem"]="16-gem-tools.sh"
)

# Default run list (excludes C2 framework module by default)
ALL_CATEGORIES=(
  "network"
  "web"
  "recon"
  "windows"
  "postexploit"
  "webattacks"
  "netattacks"
  "passwords"
  "wireless"
  "re"
  "wordlists"
  "config"
  "cargo"
  "mamba"
  "gem"
)