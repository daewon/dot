# Dot Install and Restore Architecture

## Goals
- Reproducible setup on a fresh machine.
- Safe cleanup that does not remove unmanaged user data.
- Idempotent setup and cleanup cycles.
- Low-change-cost maintenance when adding or removing tools.

## Path Model
- Root entrypoints (`setup.sh`, `cleanup.sh`, `verify.sh`) are thin wrappers that exec `scripts/*.sh`.
- `scripts/setup.sh`, `scripts/cleanup.sh`, and `scripts/verify.sh` compute `REPO_ROOT` from their script location.
- There is no hardcoded clone path inside scripts.
- Recommended operator path is `~/dot`, but any absolute path works if scripts are run from this repo.
- Runtime state is stored under `dot_state_dir()`:
  - `${XDG_STATE_HOME:-$HOME/.local/state}/dot`

## Core Components
- `setup.sh`: operator entrypoint wrapper.
- `cleanup.sh`: operator entrypoint wrapper.
- `verify.sh`: operator entrypoint wrapper.
- `scripts/setup.sh`: install and link managed resources, then write setup manifest.
- `scripts/cleanup.sh`: remove only setup-managed resources (manifest-first).
- `scripts/verify.sh`: execute repeat loops and assert reproducibility invariants.
- `scripts/lib/toolset.sh`: single source of truth for required and optional tool lists.
- `scripts/lib/scriptlib.sh`: shared shell utilities (command checks, path resolution, symlink target checks).
- `mise.toml`: repo-level runtime/tool version declaration.

## Shared Data Contracts

### Toolset Contract (`scripts/lib/toolset.sh`)
- `DOT_REQUIRED_MISE_TOOLS`: always installed by setup.
- `DOT_OPTIONAL_MISE_TOOLS`: installed when `INSTALL_OPTIONAL_TOOLS=1`.
- `DOT_REQUIRED_CLI_COMMANDS`: commands that `verify.sh` must find.
- `DOT_OPTIONAL_CLI_COMMANDS`: optional-profile commands that `verify.sh` must find during default setup checks.
- Version policy: use pinned tool versions (avoid `latest` in managed contracts).
- `dot_print_repo_symlink_entries <repo_root>`: canonical managed repo symlink list.
- `dot_print_prezto_runcom_symlink_entries [home_dir]`: canonical Prezto runcom symlink list.
- `dot_print_managed_git_clones [home_dir]`: canonical managed clone list.

Consumers:
- `setup.sh` installs required/optional sets.
- `cleanup.sh` removes matching global entries when `REMOVE_GLOBAL_TOOLS=1`.
- `verify.sh` checks required commands for minimal profile loops and required+optional commands for default-profile loops.

### Setup Manifest Contract
Path:
- `${XDG_STATE_HOME:-$HOME/.local/state}/dot/setup-manifest.v1.tsv`

Header rows:
- `version\t1`
- `repo_root\t<absolute_repo_path>`

Entry kinds:
- `symlink\t<path>\t<expected_target>`
- `managed_file_contains\t<path>\t<marker_text>`
- `git_clone_origin\t<path>\t<origin_substring>`
- `git_include_path\t<include_path>`

This manifest is the authoritative record of what setup manages.

## Setup Lifecycle
1. Parse and validate runtime flags (`0|1` booleans), then preflight checks (`git`, `mise`, shell helpers).
2. `mise trust` and `mise install` from `mise.toml`.
3. Install required global tools, then optional tools.
4. Ensure `zsh` exists and bootstrap Prezto.
5. Link managed runcoms, write managed `~/.zshrc` wrapper.
6. Link repo-managed dotfiles and helper wrappers.
7. Normalize `git include.path` to exactly one entry.
8. Ensure TPM path exists, bootstrap TPM, and install tmux plugins (configurable).
9. Write setup manifest last, after managed state is converged.

## Cleanup Lifecycle
1. Preflight checks.
2. Manifest mode:
  - if manifest exists and `version`/`repo_root` match current contract, validate manifest entry kinds first.
  - only after validation passes, remove by manifest entries.
  - unknown manifest entry kinds are treated as contract violations (fail-fast, before deletion).
3. Fallback mode:
  - if manifest is missing/mismatched, remove by static managed-target rules.
4. Remove `git include.path` entry.
5. Optionally remove global tool entries (`REMOVE_GLOBAL_TOOLS=1`).
6. Remove manifest file after successful manifest-based cleanup.

Safety rules:
- Keep regular files that are not setup-managed.
- Keep symlinks that point to unexpected targets.
- Remove `~/.zshrc` only when marker matches (or forced flag is set).

## Verify Lifecycle
`verify.sh` is the reproducibility proof script:
1. Parse and validate loop/flag inputs (non-negative loop counts, `0|1` booleans).
   - profile presets: `fast`, `full`, `stress` (overridable by explicit flags/env)
2. Syntax check for setup/cleanup/verify scripts.
3. Contract guardrail checks (invalid flags and manifest contract violations/fallback paths).
4. Static shell analysis via `shellcheck` when available.
5. Dry-run smoke tests.
6. Baseline setup and state assertions.
7. Setup-only loops to detect backup growth regressions.
8. Cleanup->setup loop cycles for idempotency.
9. Optional default-profile loops.
10. Final restore.

CI profile mapping:
- PR/push: `actionlint` + `verify --profile fast`
- schedule/manual: `actionlint` + `verify --profile full`

State assertions include:
- Canonical symlink targets.
- Unique `git include.path` entry.
- Required CLI command availability.
- Optional CLI command availability in default-profile checks.
- Manifest existence and required entries.

## Idempotency Guarantees
- Setup backs up only unmanaged paths.
- Managed links are rewritten with `ln -sfn`.
- Duplicate git include entries are normalized.
- Cleanup removes only recorded or known-managed targets.
- Verify loops enforce stable behavior across repeated runs.

## Extension Guide

### Add a Tool
1. Add tool id to `DOT_REQUIRED_MISE_TOOLS` or `DOT_OPTIONAL_MISE_TOOLS` in `scripts/lib/toolset.sh`.
2. Add command name to `DOT_REQUIRED_CLI_COMMANDS` if runtime-required.
3. Update `mise.toml` if repo-level runtime pinning is needed.
4. Update `SETUP.md`.
5. Run `./verify.sh`.

### Add a Managed File or Directory
1. Implement create/link logic in `scripts/setup.sh`.
2. Record the resource with `manifest_add_entry`.
3. Ensure cleanup supports the manifest entry kind.
4. Add or update assertions in `scripts/verify.sh`.
5. Run `./verify.sh`.
