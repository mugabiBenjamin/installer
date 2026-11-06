# Modular CTF & Penetration Testing Tool Installer Framework

A modular, idempotent Bash framework for provisioning a Debian/Ubuntu host with CTF and penetration-testing tooling (OSCP-aligned). Instead of one monolithic script, it separates orchestration, configuration, reusable helpers, toolchain managers, installation modules, and post-install verification.

> **Project status:** the module layer is implemented and runnable, but some orchestration wiring is still manual. Read [Current wiring status](#current-wiring-status) before your first full run.

## Contents

- [Modular CTF \& Penetration Testing Tool Installer Framework](#modular-ctf--penetration-testing-tool-installer-framework)
  - [Contents](#contents)
  - [Overview](#overview)
  - [Features](#features)
  - [Requirements](#requirements)
  - [Quick start](#quick-start)
  - [Installing on an existing machine](#installing-on-an-existing-machine)
    - [1. Inventory what is already present](#1-inventory-what-is-already-present)
    - [2. Source existing PATH settings first](#2-source-existing-path-settings-first)
    - [3. Run only the managers you need](#3-run-only-the-managers-you-need)
    - [4. Do not run the full bootstrap blindly](#4-do-not-run-the-full-bootstrap-blindly)
    - [5. Check for directory and PATH conflicts](#5-check-for-directory-and-path-conflicts)
    - [6. Run only missing categories or modules](#6-run-only-missing-categories-or-modules)
    - [7. Know what idempotency covers](#7-know-what-idempotency-covers)
  - [How the installer works](#how-the-installer-works)
  - [Categories and modules](#categories-and-modules)
  - [Toolchain managers](#toolchain-managers)
  - [CLI reference](#cli-reference)
  - [Verification](#verification)
  - [Current wiring status](#current-wiring-status)
  - [Extending the framework](#extending-the-framework)
    - [Add a module](#add-a-module)
    - [Add a tool to an existing module](#add-a-tool-to-an-existing-module)
  - [Troubleshooting](#troubleshooting)
  - [Conventions](#conventions)
  - [Security notice](#security-notice)

## Overview

The installer is organized as a pipeline:

```text
install.sh
  -> config/        paths, flags, category-to-module mapping
  -> modules/       one script per tool category
  -> lib/           logging, package wrappers, git/GitHub helpers, PATH, traps
  -> managers/      Go, Homebrew, uv, Rust, Mamba, and Ruby bootstrap scripts
  -> verify/        expected-binary list and verification runner
```

Each module is standalone and can be run directly. Most install steps are guarded by `command -v` or directory checks, so re-running a module is generally safe.

## Features

- **Category-based installation** - install everything, a subset (`--only`), or everything except selected categories (`--skip`).
- **Idempotent guards** - `ensure_cmd` checks for an existing binary before invoking an installer.
- **Multiple package sources** - APT, Homebrew, Go, uv, Cargo, Mamba, RubyGems, and direct GitHub release downloads.
- **Isolated Python tooling** - Python tools get their own uv-managed virtual environments instead of modifying the system Python.
- **PATH persistence** - manager scripts write to `/etc/profile.d/ctf-tools.sh` so toolchains survive new shells.
- **Post-install verification** - `verify/verify.sh` checks a curated list of expected binaries.
- **Failure isolation** - the orchestrator runs every selected module, records failures, and reports them at the end.
- **Temporary-file cleanup** - `lib/trap.sh` provides a temporary-file registry and an exit/interrupt cleanup trap for modules that source it.

## Requirements

- Debian or Ubuntu (tested on Ubuntu 26.04.1 LTS).
- `x86_64`: several download patterns hard-code `amd64` artifacts.
- Bash 4 or newer (the category map uses associative arrays).
- A non-root user with working `sudo` access.
- `git` available before cloning the repository.
- `unzip` for modules that extract GitHub archives; the bootstrap package list does not currently include it.
- An internet connection.
- Enough disk space for heavy components such as Ghidra, Havoc, SageMath, SecLists, and BloodHound CE.

> Run the framework as a normal sudo-capable user, not as root. The scripts call `sudo` internally and use `$USER`/`$HOME` for ownership and user-level installs. Running `sudo bash install.sh` makes those values point at root and produces the wrong ownership and paths.

## Quick start

The repository is expected to live at `/opt/tools/installer`; paths in `config/defaults.sh` are hard-coded to that location.

```bash
# The orchestrator expects this exact location, and /opt is normally root-owned.
sudo mkdir -p /opt/tools
sudo chown "$USER":"$USER" /opt/tools
git clone https://github.com/mugabiBenjamin/installer.git /opt/tools/installer
cd /opt/tools/installer

# 1. Create directories and install base APT dependencies.
#    Module 00 is not run automatically by install.sh.
bash modules/00-bootstrap.sh

# 2. Install the toolchains you need (see Toolchain managers).
#    install.sh does not install these automatically.
bash managers/golang.sh
bash managers/uv.sh
bash managers/rust.sh
bash managers/homebrew.sh
bash managers/mamba.sh
bash managers/ruby.sh

# 3. Load the PATH changes persisted by the managers.
#    A new login shell works too.
source /etc/profile.d/ctf-tools.sh

# 4. Run the default category set (C2 is excluded by default).
bash install.sh

# 5. Check which expected binaries are present.
bash verify/verify.sh
```

Run a focused installation instead:

```bash
bash install.sh --only web,passwords
bash install.sh --skip windows,wireless
```

Individual modules can also be run directly, for example `bash modules/08-passwords.sh`.

Scripts are committed without the executable bit (`100644`), so invoke them with `bash` rather than `./install.sh`.

On a machine that already has some toolchains or tools, use the flow in [Installing on an existing machine](#installing-on-an-existing-machine) rather than running the quick start wholesale.

## Installing on an existing machine

The same code paths apply, but an existing host needs more inventory and less blind execution. The main risks are:

- installing a second copy of a toolchain that is present but not on `PATH`
- letting `00-bootstrap.sh` run a blanket `apt upgrade`
- changing ownership of existing tool directories
- treating a non-empty but invalid directory as a valid installation

### 1. Inventory what is already present

```bash
bash verify/verify.sh || true

for c in go brew uv cargo ruby gem mamba; do
  printf '%-6s ' "$c"
  command -v "$c" || echo MISSING
done

type -a go brew uv cargo ruby gem mamba 2>/dev/null

ls -la /opt/tools \
       /usr/share/seclists \
       /usr/share/payloadsallthethings \
       /usr/share/wordlists
```

`verify/verify.sh` checks the global expected list and exits non-zero when anything is missing, so `|| true` keeps the shell moving.

### 2. Source existing PATH settings first

```bash
source /etc/profile.d/ctf-tools.sh 2>/dev/null || true
```

If a toolchain exists outside the default paths, add it to `PATH` before running modules. `ensure_cmd` only checks whether the command is visible; an off-PATH Go, uv, or Cargo installation is treated as missing.

### 3. Run only the managers you need

- Toolchain present and on `PATH`: skip its manager.
- Toolchain present but not on `PATH`: source or add its path; do not reinstall it.
- Toolchain missing: run its manager.
- Toolchain present but outdated: `ensure_cmd` still skips it. Upgrade it manually or remove the old binary first.

### 4. Do not run the full bootstrap blindly

`modules/00-bootstrap.sh` runs `sudo apt upgrade -y` and recursively changes ownership of `/opt/tools`, `/usr/share/wordlists`, `/usr/share/seclists`, and `/usr/share/payloadsallthethings`.

If that is not acceptable, comment out the upgrade or prepare the directories manually:

```bash
sudo mkdir -p /opt/tools \
              /usr/share/seclists \
              /usr/share/payloadsallthethings \
              /opt/tools/post-exploit/linux \
              /opt/tools/post-exploit/windows

sudo chown -R "$USER":"$USER" \
  /opt/tools \
  /usr/share/seclists \
  /usr/share/payloadsallthethings \
  /usr/share/wordlists
```

Then install only the base packages you actually need.

### 5. Check for directory and PATH conflicts

- `clone_or_update` expects a real `.git` directory. A non-empty directory without `.git` can block a clone.
- `12-wordlists.sh` only checks whether SecLists and PayloadsAllTheThings are non-empty. A partial or unrelated directory is treated as installed.
- Modules that create wrappers or symlinks use `ln -sf`; inspect `/usr/local/bin` for custom links that could be replaced.
- Existing `~/.tmux.conf`, `~/.vimrc`, theHarvester API keys, and Amass config are preserved because they are only created when absent.
- Check which binary wins when PATH precedence matters:

  ```bash
  type -a <command>
  ```

### 6. Run only missing categories or modules

```bash
bash install.sh --only passwords,wordlists
bash install.sh --only web,recon
bash install.sh --skip windows,wireless,re
```

For tighter control, run individual modules:

```bash
bash modules/08-passwords.sh
bash modules/12-wordlists.sh
```

`install.sh` always runs the global verification step at the end, even with `--only` or `--skip`, so expect unrelated missing-binary warnings.

### 7. Know what idempotency covers

- `ensure_cmd` skips an existing command regardless of its version.
- `clone_or_update` pulls existing Git repositories.
- APT-based package loops can be re-run safely.
- Some wrapper and symlink modules overwrite their generated wrappers on re-run.
- A skipped tool is not necessarily the version you want; check it manually.

Verify after each batch:

```bash
bash verify/verify.sh
```

## How the installer works

`install.sh` performs the following steps:

1. Sources `config/defaults.sh`, `config/categories.sh`, `lib/log.sh`, and `lib/trap.sh`.
2. Parses `--only`, `--skip`, `--minimal`, `--no-ghidra`, and `--no-pwndbg`.
3. Resolves the active category list. If `--only` is present it wins; otherwise `ALL_CATEGORIES` is used minus any `--skip` entries.
4. Expands each category through `CATEGORY_MAP` into an ordered list of module files.
5. Runs each module with `bash <module>` in a child process, recording non-zero exits.
6. Runs `verify/verify.sh` as an advisory final check.
7. Exits non-zero only when a module returned a non-zero status.

Modules are executed in category order, and categories that map to multiple modules preserve their listed order (`recon` runs passive then active; `postexploit` runs Linux then Windows).

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

`modules/00-bootstrap.sh` is a base-system module, but it is not currently listed in `CATEGORY_MAP`; run it manually (see [Current wiring status](#current-wiring-status)).

## Toolchain managers

Manager scripts bootstrap the toolchains used by modules. They are standalone: run the script directly to install, or source it to use its functions.

| Script                 | Installs                                 | Persisted path                      |
| ---------------------- | ---------------------------------------- | ----------------------------------- |
| `managers/golang.sh`   | Go in `/usr/local/go`, `GOPATH=$HOME/go` | `/usr/local/go/bin`, `$HOME/go/bin` |
| `managers/homebrew.sh` | Homebrew on Linux                        | Homebrew `shellenv`                 |
| `managers/uv.sh`       | uv                                       | `$HOME/.local/bin`                  |
| `managers/rust.sh`     | rustup, Cargo                            | `$HOME/.cargo/bin`                  |
| `managers/mamba.sh`    | Miniforge/Mamba                          | `/opt/miniforge3/bin`               |
| `managers/ruby.sh`     | Ruby, RubyGems                           | user gem bin directory              |

Run the managers before modules that depend on them:

```bash
bash managers/golang.sh
bash managers/uv.sh
bash managers/rust.sh
bash managers/homebrew.sh
bash managers/mamba.sh
bash managers/ruby.sh
```

Each manager appends its environment setup to `/etc/profile.d/ctf-tools.sh`. That file is not sourced automatically by an already-running shell, so `source` it or open a new login shell before running modules. If a manager writes to a system prefix, make sure that prefix is writable by the target user; do not run a whole manager as root just to satisfy one path.

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

Valid categories are the left-hand column of [Categories and modules](#categories-and-modules). C2 is intentionally absent from `ALL_CATEGORIES`; use `bash install.sh --only c2` to install it.

## Verification

`verify/verify.sh` checks every command listed in `verify/expected_cmds.sh` with `command -v` and exits non-zero if anything is missing.

```bash
bash verify/verify.sh
```

Important details:

- Verification is global. `--category` is accepted by the argument parser but ignored.
- `install.sh` runs verification at the end of every install, including `--only` and `--skip` runs. A verification failure is downgraded to a warning there, so a partial install can finish with exit status 0 while reporting missing binaries.
- `verify/expected_cmds.sh` is a target list, not a guarantee that a module installs every entry. Some expected binaries are not currently installed by any module (for example `tmux`, `jq`, and `pandoc`).

## Current wiring status

These behaviors are verified against the current scripts and are easy to miss:

- `modules/00-bootstrap.sh` is not in `CATEGORY_MAP`, so `install.sh` never runs it. Run it manually on a fresh host.
- `install.sh` does not call the manager installers. Sourcing `managers/*.sh` only defines functions; it does not install Go, uv, Rust, Homebrew, Mamba, or Ruby. Modules that need a missing toolchain warn and return success without installing anything.
- `--no-ghidra`, `--no-pwndbg`, and `--minimal` are parsed but not currently enforced.
- Modules run in child `bash` processes. PATH changes and exports do not carry from one module to the next; only `/etc/profile.d/ctf-tools.sh` persists across shells.
- `config/defaults.sh` hard-codes `/opt/tools/installer`, `/opt/tools`, and system paths. Moving the repository requires editing that file.
- Scripts use `set -uo pipefail` but not `set -e`. Most helpers convert failures into warnings and return 0, so exit status alone is not proof that a tool installed. Inspect the log output and run verification.
- `config/versions.sh` exists but is not sourced anywhere; its pins are currently inert.

## Extending the framework

### Add a module

1. Create `modules/NN-name.sh` using the existing module pattern:

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

2. Register the file in `config/categories.sh`:
   - Add it to `CATEGORY_MAP` under the appropriate category.
   - Add the category to `ALL_CATEGORIES` if it should run by default.

3. Add every expected binary to `verify/expected_cmds.sh`.

4. Check syntax:

   ```bash
   bash -n install.sh config/*.sh lib/*.sh managers/*.sh modules/*.sh verify/*.sh
   ```

### Add a tool to an existing module

Use the idempotent wrappers rather than calling package managers directly:

```bash
ensure_cmd <binary> apt_install <package>
ensure_cmd <binary> go_install <module-path>
ensure_cmd <binary> brew_install <formula>
ensure_cmd <binary> cargo_install <crate>
ensure_cmd <binary> uv_tool_install <name> <package> <binary>
ensure_cmd <binary> gem_install <gem>
ensure_cmd <binary> mamba_install <package> [channel]
```

Use `fetch_latest_github_release <owner/repo> <include-regex> [exclude-regex]` for release assets. It returns an empty string on failure, so guard the result with `[ -n "$URL" ]`. Register downloaded archives with `register_tmp` after sourcing `lib/trap.sh` so they are cleaned up.

## Troubleshooting

| Symptom                                           | Likely cause and fix                                                                                                                  |
| ------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------- |
| `./install.sh: Permission denied`                 | Scripts are stored without the executable bit. Run `bash install.sh`.                                                                 |
| `go`, `uv`, `cargo`, `brew`, or `mamba` not found | Run the corresponding manager, then `source /etc/profile.d/ctf-tools.sh` or open a new login shell.                                   |
| A module reports success but tools are missing    | The required toolchain was unavailable; wrappers warn and return 0. Install the manager and re-run the module.                        |
| `verify.sh` reports many missing binaries         | Expected; verification is global and includes tools not installed by every category. Compare against the categories you actually ran. |
| `--no-ghidra` or `--no-pwndbg` has no effect      | These flags are not currently wired through to module 11. Edit `config/defaults.sh` or run `--only` without the `re` category.        |
| Wireshark cannot capture as a normal user         | Group membership changes require a logout/login (or a new session) before they apply.                                                 |
| apt packages fail to install                      | Check network access and whether the package exists for your distribution; modules log a warning and continue.                        |
| An existing tool is skipped                       | That is the idempotency guard working. Remove the binary or directory only if you intend to reinstall it.                             |
| Re-running the installer                          | Safe in most cases because modules check for existing commands, repositories, and files first.                                        |

## Conventions

- Keep scripts Bash-only and start them with `set -uo pipefail`.
- Resolve paths from `BASH_SOURCE`, not the caller's working directory.
- Use `banner`, `section`, `log`, `warn`, and `err` from `lib/log.sh` instead of raw `echo` for status output.
- Prefer the wrappers in `lib/pkg.sh` so new tools remain idempotent and skippable.
- Register temporary files with `register_tmp` and source `lib/trap.sh` where cleanup is needed.
- Git history uses imperative, capitalized subjects, `feat/<area>` branches, and pull-request merges.
- Do not commit `repomix-output.xml`; it is generated output and already gitignored.
- There is no automated test suite or CI. Use `bash -n` for syntax checks and `verify/verify.sh` for installed-binary checks.

## Security notice

This project installs offensive security tooling and modifies system packages, PATH configuration, and tool directories. Use it only on systems you own or are explicitly authorised to test. Prefer an isolated VM or lab environment, and review module contents before running them with `sudo`.
