#!/usr/bin/env bash
# /opt/tools/installer/lib/log.sh
# ANSI colored output & formatting helpers

RED='\e[1;31m'
GREEN='\e[1;32m'
YELLOW='\e[1;33m'
BLUE='\e[1;34m'
RESET='\e[0m'

log()     { printf "${GREEN}[+] %s${RESET}\n" "$*"; }
warn()    { printf "${YELLOW}[!] %s${RESET}\n" "$*"; }
err()     { printf "${RED}[-] %s${RESET}\n" "$*"; exit 1; }

banner()  {
  printf "\n${BLUE}======================================================================${RESET}\n"
  printf "${BLUE}  %s${RESET}\n" "$*"
  printf "${BLUE}======================================================================${RESET}\n\n"
}

section() { printf "\n${GREEN}=== %s ===${RESET}\n" "$*"; }