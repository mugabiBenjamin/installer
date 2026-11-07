# Modular CTF & Penetration Testing Tool Installer

A modular, idempotent Bash framework for provisioning a Debian/Ubuntu host with CTF and penetration-testing tooling.

> **Status:** the module layer is implemented and runnable, but some orchestration is still manual. Read [Wiring status](#wiring-status) before your first full run.

## Overview

```text
install.sh
  -> config/        paths, flags, category-to-module mapping
  -> modules/       one script per tool category
  -> lib/           logging, package wrappers, git/GitHub helpers, PATH, traps
  -> managers/      Go, Homebrew, uv, Rust, Mamba, and Ruby bootstraps
  -> verify/        expected-binary list and verification runner
```

Each module is standalone (`bash modules/08-passwords.sh`) and guarded by `command -v` or directory checks, so re-runs are generally safe. `install.sh` expands the selected categories through `CATEGORY_MAP`, runs each module in a child `bash`, records non-zero exits, then runs verification. It exits non-zero only when a module failed.

## Features

- **Category-based installs** - everything, a subset (`--only`), or everything except selected categories (`--skip`).
- **Idempotent guards** - `ensure_cmd` skips a tool that already exists.
- **Multiple sources** - APT, Homebrew, Go, uv, Cargo, Mamba, RubyGems, and GitHub releases.
- **Isolated Python tooling** - uv-managed virtualenvs instead of the system Python.
- **Persistent PATH** - manager scripts append to `/etc/profile.d/ctf-tools.sh`.
- **Credentials from `.env`** - recon API keys are never embedded in tracked files.
- **Post-install verification** and temporary-file cleanup.

## Requirements

- Debian or Ubuntu (tested on Ubuntu 26.04.1 LTS), `x86_64` (several downloads hard-code `amd64`).
- Bash 4+, `git`, `unzip`, internet access.
- Disk space for Ghidra, Havoc, SageMath, SecLists, and BloodHound CE.
- A non-root user with working `sudo`.

> Run as a normal sudo-capable user, **not** with `sudo bash install.sh`. Modules call `sudo` internally and use `$USER`/`$HOME`; running as root produces wrong ownership and paths.

## Quick start

The repository must live at `/opt/tools/installer`; paths in `config/defaults.sh` are hard-coded.

```bash
sudo mkdir -p /opt/tools && sudo chown "$USER":"$USER" /opt/tools
git clone https://github.com/mugabiBenjamin/installer.git /opt/tools/installer
cd /opt/tools/installer

# Optional: recon API keys (see Secrets and environment variables).
cp .example.env .env && chmod 600 .env && $EDITOR .env

# 1. Base system - NOT run by install.sh.
bash modules/00-bootstrap.sh

# 2. Toolchains - NOT installed by install.sh; run the ones you need.
bash managers/golang.sh
bash managers/uv.sh
bash managers/rust.sh
bash managers/homebrew.sh
bash managers/mamba.sh
bash managers/ruby.sh

# 3. Load the persisted PATH (or open a new login shell).
source /etc/profile.d/ctf-tools.sh

# 4. Default categories (C2 is excluded).
bash install.sh

# 5. Check which expected binaries are present.
bash verify/verify.sh
```

Focused runs:

```bash
bash install.sh --only web,passwords
bash install.sh --skip windows,wireless,re
bash modules/08-passwords.sh    # standalone module
```

Scripts are committed without the executable bit (`100644`), so invoke them with `bash` rather than `./install.sh`.

## Secrets and environment variables

Recon credentials are read from a gitignored repository-root `.env`; commit only `.example.env`. Generated config files are:

- theHarvester: `~/.theHarvester/api-keys.yaml`
- Amass: `~/.config/amass/config.ini`
- Shodan CLI: `~/.config/shodan/api_key` (or `~/.shodan/api_key` if that directory already exists)
- Censys CLI: `~/.config/censys/censys.cfg`

Existing configs are preserved. To regenerate one, move or remove it and rerun `bash modules/03-recon-passive.sh`. Credential values are never logged, and generated files are mode `600`.

## Categories and modules

| Category      | Module(s)                                              | Main tools and components                                                                                                                                                                                                                                    |
| ------------- | ------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `network`     | `01-network.sh`                                        | nmap, tcpdump, masscan, Wireshark/tshark, rustscan, amass, naabu, smbclient, smbmap                                                                                                                                                                          |
| `web`         | `02-web-enum.sh`                                       | whatweb, ffuf, sqlmap, feroxbuster, subfinder, nuclei, dnsx, katana, httpx, kiterunner (`kr`)                                                                                                                                                                |
| `recon`       | `03-recon-passive.sh`, `03-recon-active.sh`            | shodan, censys, cloud_enum, holehe, crosslinked, theHarvester, SpiderFoot, recon-ng, Sherlock, TruffleHog, assetfinder, waybackurls, dnsrecon, dnsenum, fierce, wafw00f, arjun, ParamSpider, git-dumper, LinkFinder, SecretFinder, Photon, dalfox, Metabigor |
| `windows`     | `04-windows-ad.sh`                                     | Impacket, evil-winrm, NetExec (`nxc`), Neo4j, BloodHound CE, bloodhound-python, Kerbrute, enum4linux-ng, ldapdomaindump, pypykatz, Ligolo-ng, Chisel, pwncat-cs                                                                                              |
| `postexploit` | `05-postexploit-linux.sh`, `05-postexploit-windows.sh` | linpeas, LSE, linux-exploit-suggester, pspy, winPEAS, Rubeus, Mimikatz, SharpHound, PowerSploit, Nishang                                                                                                                                                     |
| `webattacks`  | `06-web-attacks.sh`                                    | dalfox, byp4xx, interactsh-client, corscanner, XSStrike, jwt_tool, commix, Ghauri                                                                                                                                                                            |
| `netattacks`  | `07-network-attacks.sh`                                | Responder, mitm6, Bettercap, Coercer, PetitPotam                                                                                                                                                                                                             |
| `passwords`   | `08-passwords.sh`                                      | hashcat, John the Ripper, Hydra, fcrackzip, pdfcrack, haiti, nth, CeWL, CUPP, username-anarchy                                                                                                                                                               |
| `wireless`    | `09-wireless.sh`                                       | aircrack-ng suite, hcxtools, hcxdumptool                                                                                                                                                                                                                     |
| `c2`          | `10-c2.sh`                                             | Sliver, Havoc (excluded from the default run)                                                                                                                                                                                                                |
| `re`          | `11-re-forensics.sh`                                   | radare2, binwalk, strace, ltrace, UPX, ghex, checksec, Rizin, Cutter, Ghidra, pwndbg, foremost, scalpel, exiftool, steghide, ddrescue, zbar-tools, stegseek, FFmpeg, MediaInfo, SoX, ImageMagick, TestDisk, Sleuth Kit, Autopsy                              |
| `wordlists`   | `12-wordlists.sh`                                      | SecLists, rockyou.txt, PayloadsAllTheThings, `~/wordlists` symlink                                                                                                                                                                                           |
| `config`      | `13-config.sh`                                         | baseline `~/.tmux.conf`, `~/.vimrc`, ZSH alias fixes, profile sourcing, conda init guidance                                                                                                                                                                  |
| `cargo`       | `14-cargo-tools.sh`                                    | ripgrep, fd-find, bat, hexyl, tokei                                                                                                                                                                                                                          |
| `mamba`       | `15-mamba-tools.sh`                                    | SageMath                                                                                                                                                                                                                                                     |
| `gem`         | `16-gem-tools.sh`                                      | zsteg, one_gadget, evil-winrm                                                                                                                                                                                                                                |

`modules/00-bootstrap.sh` is a base-system module but is not in `CATEGORY_MAP`; run it manually.

## Toolchain managers

Managers bootstrap the toolchains used by modules. They are standalone: run the script to install, or source it to use its functions.

| Script                 | Installs                                 | Persisted path                      |
| ---------------------- | ---------------------------------------- | ----------------------------------- |
| `managers/golang.sh`   | Go in `/usr/local/go`, `GOPATH=$HOME/go` | `/usr/local/go/bin`, `$HOME/go/bin` |
| `managers/homebrew.sh` | Homebrew on Linux                        | Homebrew `shellenv`                 |
| `managers/uv.sh`       | uv                                       | `$HOME/.local/bin`                  |
| `managers/rust.sh`     | rustup, Cargo                            | `$HOME/.cargo/bin`                  |
| `managers/mamba.sh`    | Miniforge/Mamba                          | `/opt/miniforge3/bin`               |
| `managers/ruby.sh`     | Ruby, RubyGems                           | user gem bin directory              |

Each manager appends to `/etc/profile.d/ctf-tools.sh`; an already-running shell does not pick that up, so `source` it or open a new login shell before running modules. If a manager writes to a system prefix, make that prefix writable by the target user rather than running the whole manager as root.

## CLI reference

```text
bash install.sh [--only <categories>] [--skip <categories>]
                [--minimal] [--no-ghidra] [--no-pwndbg]
```

| Flag                 | Status               | Behavior                                                         |
| -------------------- | -------------------- | ---------------------------------------------------------------- |
| `--only <cat1,cat2>` | Implemented          | Runs only the listed categories. Takes precedence over `--skip`. |
| `--skip <cat1,cat2>` | Implemented          | Runs every default category except the listed ones.              |
| `--minimal`          | Parsed, not enforced | Sets `MINIMAL=true`, but no module currently reads it.           |
| `--no-ghidra`        | Parsed, not enforced | Assigns a shell variable that module 11 does not receive.        |
| `--no-pwndbg`        | Parsed, not enforced | Assigns a shell variable that module 11 does not receive.        |

Valid categories are the left-hand column of [Categories and modules](#categories-and-modules). C2 is intentionally absent from `ALL_CATEGORIES`; use `bash install.sh --only c2`.

## Verification

`verify/verify.sh` checks every command in `verify/expected_cmds.sh` with `command -v` and exits non-zero if anything is missing.

- Verification is global; `--category` is parsed but ignored.
- `install.sh` runs it after every install, including `--only`/`--skip`, but downgrades failures to warnings. A partial install can exit 0 while reporting missing binaries.
- The expected list is a target, not a guarantee. Some entries (for example `tmux`, `jq`, `pandoc`) are not installed by any module.

## Wiring status

These behaviors are easy to miss:

- `modules/00-bootstrap.sh` is not in `CATEGORY_MAP`, so `install.sh` never runs it. Run it manually on a fresh host.
- `install.sh` does not call the manager installers. Sourcing `managers/*.sh` only defines functions. Modules that need a missing toolchain warn and return success without installing anything.
- `--minimal`, `--no-ghidra`, and `--no-pwndbg` are parsed but not currently enforced.
- Modules run in child `bash` processes, so PATH changes and exports do not carry between modules. Only `/etc/profile.d/ctf-tools.sh` persists across shells.
- `modules/03-recon-passive.sh` loads the repo-root `.env` when present and writes credentials only when the target config file is absent.
- `config/defaults.sh` hard-codes `/opt/tools/installer`, `/opt/tools`, and system paths. Moving the repository requires editing it.
- Scripts use `set -uo pipefail` but not `set -e`; most helpers turn failures into warnings and return 0. Exit status alone is not proof that a tool installed - inspect the log and run verification.
- `config/versions.sh` exists but is never sourced; its pins are inert.

## Installing on an existing machine

```bash
bash verify/verify.sh || true

for c in go brew uv cargo ruby gem mamba; do
  printf '%-6s ' "$c"
  command -v "$c" || echo MISSING
done

source /etc/profile.d/ctf-tools.sh 2>/dev/null || true
type -a go brew uv cargo ruby gem mamba 2>/dev/null
```

Then keep these risks in mind:

- **Toolchains off `PATH` count as missing.** `ensure_cmd` only checks visible commands, so add an existing toolchain to `PATH` instead of reinstalling it. Present but outdated tools are still skipped.
- **Do not run the full bootstrap blindly.** It performs `sudo apt upgrade -y` and recursively chowns `/opt/tools`, `/usr/share/wordlists`, `/usr/share/seclists`, and `/usr/share/payloadsallthethings`. If that is unwanted, prepare the directories manually and install only the base packages you need.
- **Directory and symlink conflicts.** `clone_or_update` needs a real `.git` directory, a non-empty non-git directory can block a clone, and the wordlist module treats any non-empty SecLists/PayloadsAllTheThings directory as installed. Wrappers and symlinks use `ln -sf` in `/usr/local/bin`.
- **Existing configs are preserved.** `~/.tmux.conf`, `~/.vimrc`, and recon tool configs are only created when absent; put new values in `.env`. Check `type -a <command>` when PATH precedence matters.
- **Idempotency is shallow.** Existing commands are skipped regardless of version, and some wrapper modules rewrite their generated files on re-run. Run `bash verify/verify.sh` after each batch.

## Extending the framework

### Add a module

1. Create `modules/NN-name.sh`:

   ```bash
   #!/usr/bin/env bash
   set -uo pipefail

   SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
   source "${SCRIPT_DIR}/config/defaults.sh"
   source "${SCRIPT_DIR}/lib/log.sh"
   source "${SCRIPT_DIR}/lib/pkg.sh"

   banner "Module NN: Description"

   ensure_cmd example apt_install example

   log "Module NN complete."
   ```

2. Register it in `config/categories.sh`: add the file to `CATEGORY_MAP`, and add the category to `ALL_CATEGORIES` if it should run by default.
3. Add every expected binary to `verify/expected_cmds.sh`.
4. Check syntax with `bash -n install.sh config/*.sh lib/*.sh managers/*.sh modules/*.sh verify/*.sh`.

### Add a tool to an existing module

Prefer the idempotent wrappers over calling package managers directly:

```bash
ensure_cmd <binary> apt_install <package>
ensure_cmd <binary> go_install <module-path>
ensure_cmd <binary> brew_install <formula>
ensure_cmd <binary> cargo_install <crate>
ensure_cmd <binary> uv_tool_install <name> <package> <binary>
ensure_cmd <binary> gem_install <gem>
ensure_cmd <binary> mamba_install <package> [channel]
```

Use `fetch_latest_github_release <owner/repo> <include-regex> [exclude-regex]` for release assets; it returns empty on failure, so guard with `[ -n "$URL" ]`. Source `lib/trap.sh` and use `register_tmp` for downloaded archives.

## Troubleshooting

| Symptom                                           | Cause and fix                                                                                                          |
| ------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------- |
| `./install.sh: Permission denied`                 | Scripts have no executable bit. Run `bash install.sh`.                                                                 |
| `go`, `uv`, `cargo`, `brew`, or `mamba` not found | Run the matching manager, then `source /etc/profile.d/ctf-tools.sh` or open a new login shell.                         |
| Module succeeds but tools are missing             | A required toolchain was unavailable; wrappers warn and return 0. Install the manager and re-run the module.           |
| `verify.sh` reports many missing binaries         | Expected: verification is global and includes tools from categories you did not run.                                   |
| `--no-ghidra` / `--no-pwndbg` has no effect       | Not wired through to module 11. Edit `config/defaults.sh` or skip the `re` category.                                   |
| Wireshark cannot capture as a normal user         | Group changes need a logout/login or new session.                                                                      |
| An existing tool is skipped                       | The idempotency guard. Remove the binary or directory only if you intend to reinstall it.                              |
| Recon API keys are not applied                    | Existing configs are preserved. Edit `.env`, remove the relevant config, and rerun `bash modules/03-recon-passive.sh`. |

## Conventions

- Bash only; start scripts with `set -uo pipefail` and resolve paths from `BASH_SOURCE`.
- Use `banner`, `section`, `log`, `warn`, and `err` from `lib/log.sh` instead of raw `echo`.
- Prefer `lib/pkg.sh` wrappers so tools stay idempotent; register temp files with `register_tmp`.
- Keep real credentials in `.env` (gitignored) and commit only `.example.env`. Never log credential values.
- Git history uses imperative, capitalized subjects, `feat/<area>` branches, and pull-request merges.
- Do not commit `repomix-output.xml` or logs. There is no CI: use `bash -n` for syntax and `verify/verify.sh` for binaries.

## Security notice

This project installs offensive-security tooling and modifies system packages, PATH configuration, and tool directories. Use it only on systems you own or are explicitly authorised to test. Prefer an isolated VM or lab, and review modules before running them with `sudo`.
