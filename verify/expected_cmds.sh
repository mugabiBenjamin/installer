#!/usr/bin/env bash
# /opt/tools/installer/verify/expected_cmds.sh
# Array definition of expected binaries across all phases

EXPECTED_CMDS=(
  # Bootstrap / utilities
  vim objdump htop gpg tree tmux jq pandoc uv rlwrap socat proxychains4 download-mibs
  
  # Package managers
  brew cargo rustc go mamba
  
  # Network / scanning
  nmap tcpdump tshark rustscan naabu masscan amass subfinder smbclient smbmap onesixtyone snmpwalk redis-cli
  
  # Web enum
  whatweb ffuf feroxbuster httpx nuclei dnsx katana kr sqlmap
  
  # Recon passive
  shodan censys theHarvester spiderfoot recon-ng sherlock trufflehog assetfinder waybackurls holehe crosslinked
  
  # Recon active
  dnsrecon dnsenum fierce wafw00f arjun paramspider linkfinder secretfinder git-dumper dalfox metabigor photon
  
  # Windows / AD
  impacket-secretsdump impacket-psexec impacket-wmiexec evil-winrm nxc kerbrute enum4linux-ng ldapdomaindump pypykatz bloodhound-python ligolo-proxy chisel pwncat
  
  # Passwords
  hashcat john hydra fcrackzip haiti nth cewl cupp username-anarchy
  
  # Wireless
  aircrack-ng airodump-ng hcxtools hcxdumptool
  
  # Web attacks
  xsstrike jwt_tool commix byp4xx interactsh-client corscanner ghauri
  
  # Network attacks
  responder mitm6 bettercap coercer petitpotam
  
  # RE / forensics
  radare2 binwalk rizin ghex strace ltrace upx foremost exiftool steghide zbarimg ffmpeg mediainfo sox
  
  # Cargo
  rg fd bat hexyl tokei
  
  # Gem
  zsteg one_gadget
)