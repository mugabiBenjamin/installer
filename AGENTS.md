# AGENTS.md

Bash-only installer for Debian/Ubuntu CTF and pentest tooling. No package manifest, tests, linter, or CI. "Verification" is just `command -v` checks against `verify/expected_cmds.sh` (currently 124 expected commands).

`AGENTS.md` is the committed, machine-facing counterpart to `README.md`. Keep it portable and review it when installer conventions change.

## Commands

- Syntax check (the only fast check): `bash -n install.sh config/*.sh lib/*.sh managers/*.sh modules/*.sh verify/*.sh`
- Optional lint: run `shellcheck -x` on changed scripts when available; the repo does not install ShellCheck.
- Full run: `bash install.sh` as a normal sudo-capable user. Do not use `sudo bash install.sh`: modules call `sudo` internally and use `$USER`/`$HOME`, which become root under sudo.
- Focused runs:
  - `bash install.sh --only web,passwords`
  - `bash install.sh --skip windows,wireless`
  - `bash modules/08-passwords.sh` — modules and managers are standalone
- Verify installed tools: `bash verify/verify.sh`. It checks globally; `--category` is parsed but ignored. It exits 1 if any expected binary is missing.
- `install.sh` always runs `verify/verify.sh` at the end, even for `--only`/`--skip`, so partial runs end with missing-binary warnings but still exit 0.

Scripts are committed without the executable bit (`100644`), so invoke them with `bash`, not `./`.

## Wiring gotchas

- `modules/00-bootstrap.sh` is not in `CATEGORY_MAP`; `install.sh` never runs it. Run it manually first on a fresh host.
- `managers/*.sh` only define functions when sourced; nothing calls `install_golang`, `install_homebrew`, `install_uv`, `install_rust`, or `install_mamba`. Run the manager scripts manually before modules that use `go_install`, `uv_tool_install`, `brew_install`, or `cargo_install`; otherwise those helpers warn and return success.
- Each module runs in a child `bash`, so PATH and exports do not carry between modules. `lib/env.sh` persists to `/etc/profile.d/ctf-tools.sh`; it does not update the running installer.
- `--no-ghidra` and `--no-pwndbg` assign non-exported variables in `install.sh`, so module 11 still sees the defaults (`true`). `--minimal` is parsed but unused.
- `config/defaults.sh` hard-codes `/opt/tools/installer`, `/opt/tools`, and system paths. These are canonical project paths, not personal paths. Moving the repo requires editing it.
- `--only c2` is required for module 10; C2 is intentionally absent from `ALL_CATEGORIES`.
- Scripts use `set -uo pipefail` (no `-e`), and helpers convert failures to `warn` and return 0. Exit status alone cannot prove success — inspect logs and run `verify/verify.sh`.
- `config/versions.sh` is not sourced anywhere; its pins are inert.
- `lib/github.sh` sources `lib/trap.sh`, and `lib/trap.sh` preserves `CLEANUP_FILES` when sourced again. `download_binary` downloads to a user-writable temp file and installs with `sudo install -Dm755`, so it works for destinations under `/usr/local/bin`.
- `uv_tool_install <name> <pkg> <binary> [link_name]` checks the final link name for idempotency. Use the optional fourth argument when the virtualenv entry point and desired command name differ (for example `pwncat-cs` -> `pwncat`).
- `install_git_uv_tool` skips `uv pip install -r` when the requirements path is empty. This supports stdlib-only scripts such as `cupp` and `commix`.
- `gem_install` installs `libreadline-dev` and `libedit-dev` when neither readline header exists, so native gems such as `evil-winrm` can compile.

## Verification set

- `verify/expected_cmds.sh` currently contains 124 commands.
- `cloud_enum` and `bloodhound-cli` are expected; they are installed by modules 03 and 04.
- `hcxpcapngtool` is the actual command provided by the `hcxtools` package. There is no `hcxtools` binary.
- Partial runs still run the full verification and can report binaries that belong to skipped categories.

## Conventions for changes

- New module: add `modules/NN-name.sh`, register it in both `CATEGORY_MAP` and (normally) `ALL_CATEGORIES` in `config/categories.sh`, and add expected binaries to `verify/expected_cmds.sh`.
- Module filenames use `NN-name.sh`; the two `03-*` files are intentionally separate passive and active recon modules.
- In modules, prefer `ensure_cmd <cmd> <installer> ...` with `apt_install`, `go_install`, `brew_install`, `cargo_install`, `uv_tool_install`, `gem_install`, or `mamba_install`; these implement the idempotency checks.
- Use `banner`/`section`/`log`/`warn`/`err` from `lib/log.sh` (`err` exits 1). Register temporary files with `register_tmp` from `lib/trap.sh` so cleanup runs.
- `fetch_latest_github_release <owner/repo> <include-regex> [exclude-regex]` returns empty on failure; always guard with `[ -n "$URL" ]`.
- Git history uses imperative, capitalized subjects (e.g. "Add installation logic for ..."), `feat/<area>` branches, and PR merges.
- Do not commit `repomix-output.xml`, `install-*.log`, `*.log`, or local `AGENTS.local.md` files; they are gitignored.
- Keep per-directory agent instructions in nested `AGENTS.md` files when they apply to a subtree (`lib/AGENTS.md`, `modules/AGENTS.md`). Use `AGENTS.local.md` for machine-specific overrides.

## Module-specific notes

- `cloud_enum` and `paramspider` are not published on PyPI. Install them from their Git repositories with `uv_tool_install`.
- `haiti` is the `haiti-hash` Ruby gem, not a Python package.
- Impacket upstream installs scripts as `psexec.py`, `wmiexec.py`, etc. The module creates `impacket-*` symlinks for those entry points, including `impacket-psexec`.
- `pwncat-cs` 0.5.4 still imports `pkg_resources`; the module installs `setuptools<81`, writes a small import shim, and wraps it as `pwncat` on Python 3.12.
- BloodHound CE is installed as `bloodhound-cli` and runs as a Docker stack. Do not re-add a standalone `bloodhound` binary download; BloodHound CE releases have no binary assets. Do not install host Neo4j for CE unless a separate legacy setup needs it.
- Rubeus has no compiled GhostPack release asset. The fallback downloads the community-maintained SharpCollection build.
- Rizin packages are not available in the target Ubuntu release; install the static x86_64 release archive under `${TOOLS_DIR}/rizin`.
- `hcxtools` provides `hcxpcapngtool`, `hcxhashtool`, and related binaries, not a single `hcxtools` command.

## Repository hygiene and safety

This repo installs offensive-security tooling and may be shared publicly. `AGENTS.md` should contain instructions, not credentials; treat any secret in it as a bug. Before committing `AGENTS.md` or any other file, check for:

- Personal absolute paths (home-directory paths, personal tool directories).
- Internal hostnames, IP addresses, VPN names, jump-box names, or private mirrors.
- Tokens, API keys, passwords, license keys, or C2 callback URLs, even in examples.
- Personal notes, client names, or TODOs naming real people or engagements.
- Private wrappers, payloads, or tool lists that are not already public.
- Real `install-*.log` contents. Logs are machine-specific and must stay gitignored.

The canonical `/opt/tools/...` paths are intentional project paths; keep them only where `config/defaults.sh` requires them. Use `AGENTS.local.md` for machine-specific overrides and keep it gitignored.

A quick starting scan (review every match; this is not a substitute for judgment):

```bash
grep -RInE '(/home/|/Users/|api[_-]?key|secret|token|BEGIN .*PRIVATE KEY)' \
  --exclude-dir=.git --exclude='*.log' --exclude='repomix-output.xml' .
```

If a secret is committed, remove it, rotate it, and rewrite history if necessary. Deleting it in a later commit is not enough.
