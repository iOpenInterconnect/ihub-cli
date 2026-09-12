# iHub core CLI

`ihub` is the small command-line interface for installing and removing projects
managed by iHub. Project metadata is kept separately in `core/projects`, which
makes the CLI suitable as the backend for a future TUI.

## Run it locally

```bash
./core/ihub list
./core/ihub status uxplay
./core/ihub install uxplay
./core/ihub update uxplay
```

To use it as `ihub` from any directory, add `core` to your `PATH` or create a
symlink to `core/ihub` in a directory already on your `PATH`.

## Automation

Pass `--json` to receive exactly one JSON document on standard output. Command
and installer messages go to standard error, so JSON output is safe to parse.

```bash
./core/ihub list --json
./core/ihub install uxplay --dry-run --json
./core/ihub update uxplay --dry-run --json
```

Exit codes are `0` for a successful command, `1` for a failed project action,
`2` for invalid input, and `3` for an unknown project.

## Add a project

Add a small Bash definition in `core/projects/<id>.sh`:

```bash
PROJECT_ID="example"
PROJECT_NAME="Example"
PROJECT_DESCRIPTION="One-sentence description."
PROJECT_INSTALL_SCRIPT="example/install.sh"
PROJECT_UNINSTALL_SCRIPT="example/uninstall.sh"
PROJECT_UPDATE_SCRIPT="example/update.sh"
PROJECT_HOME_DIR="Example"
```

The install and uninstall script paths are relative to the repository root.
`PROJECT_HOME_DIR` is relative to `IHUB_HOME`, which defaults to `~/.ihub`.
