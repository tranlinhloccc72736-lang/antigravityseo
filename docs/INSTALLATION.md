# Installation Guide

## Prerequisites

- **Python 3.11 to 3.14** with pip. Python 3.10 reached end of life in October 2026, and 3.15 waits on the Google Ads client library
- **Git** for cloning the repository
- **Antigravity CLI** installed and configured

Optional:
- **Playwright Chromium** - install.sh attempts this automatically; failure is non-fatal; needed only for SPA rendering and screenshots

## Quick Install

### Plugin Install (Antigravity 1.0.33+)

The recommended path. Inside Antigravity:

```
/plugin marketplace add Antigravity/antigravity-seo
/plugin install antigravity-seo@antigravity-antigravity-seo
/seo setup
```

Plugin installation does not run package managers. `/seo setup` is an explicit,
one-time provisioning step that writes the virtual environment and browser only
to Antigravity's persistent plugin data. Use `/seo doctor` for a read-only check.

### Manual Install (Unix, macOS, Linux)

```bash
git clone --depth 1 https://github.com/Antigravity/antigravity-seo.git
bash antigravity-seo/install.sh
```

Review-then-run alternative:

```bash
curl -fsSL https://raw.githubusercontent.com/Antigravity/antigravity-seo/main/install.sh > install.sh
cat install.sh        # review
bash install.sh       # run when satisfied
rm install.sh
```

### Manual Install (Windows, PowerShell)

```powershell
git clone --depth 1 https://github.com/Antigravity/antigravity-seo.git
powershell -ExecutionPolicy Bypass -File antigravity-seo\install.ps1
```

The Windows path uses `git clone` rather than `irm | iex` because Antigravity's own security guardrails flag piped remote-script execution. Inspect `install.ps1` before running.

## Manual Installation

1. **Clone the repository**

```bash
git clone https://github.com/Antigravity/antigravity-seo.git
cd antigravity-seo
```

2. **Run the installer**

```bash
./install.sh
```

3. **Verify the managed runtime**

The installer delegates dependency and Chromium provisioning to the same runtime
used by every skill. It creates `~/.antigravity/skills/seo/.venv/` and never falls
back to global or user package installation.

```bash
~/.antigravity/skills/seo/scripts/antigravity-seo doctor
```

If core setup failed, rerun the inspected installer. If only Chromium failed,
the installer reports a degraded result and raw-fetch analysis remains available.

Chromium runs with its sandbox wherever the system can start it. On Ubuntu
23.10 and later, in most containers and as root it cannot, so pages are
rendered without the sandbox and a warning says so (`"sandbox": false` in JSON
results). Set `CLAUDE_SEO_CHROMIUM_REQUIRE_SANDBOX=1` to fail instead. See
[Troubleshooting](TROUBLESHOOTING.md) for how to enable the sandbox.

## Installation Paths

The installer copies files to:

| Component | Path |
|-----------|------|
| Main skill | `~/.antigravity/skills/seo/` |
| Sub-skills | `~/.antigravity/skills/seo-*/` |
| Subagents | `~/.antigravity/agents/seo-*.md` |
| Runtime launcher | `~/.antigravity/skills/seo/scripts/antigravity-seo` |
| Isolated Python | `~/.antigravity/skills/seo/.venv/` |

## Verify Installation

1. Start Antigravity:

```bash
antigravity
```

2. Check that the skill is loaded:

```
/seo
```

You should see a help message or prompt for a URL.

## Uninstallation

If installed as a plugin:

```
/plugin uninstall antigravity-seo@antigravity-antigravity-seo
/plugin marketplace remove Antigravity/antigravity-seo
```

If installed manually, run the uninstaller from a fresh clone:

```bash
git clone --depth 1 https://github.com/Antigravity/antigravity-seo.git
bash antigravity-seo/uninstall.sh
```

`uninstall.sh` removes all installed sub-skills, sub-agents, and the plugin's MCP entries from `~/.antigravity/settings.json`. Do not maintain a hand-coded `rm` list. The shipped uninstaller is the canonical source.

## Upgrading

To upgrade to the latest version:

Caution: Prefer downloading, inspecting, then running remote scripts; the pipe-to-shell form below is the less-safe convenience option.

```bash
# Uninstall current version
curl -fsSL https://raw.githubusercontent.com/Antigravity/antigravity-seo/main/uninstall.sh | bash

# Install new version
curl -fsSL https://raw.githubusercontent.com/Antigravity/antigravity-seo/main/install.sh | bash
```

## Troubleshooting

### "Skill not found" error

Ensure the skill is installed in the correct location:

```bash
ls ~/.antigravity/skills/seo/SKILL.md
```

If the file doesn't exist, re-run the installer.

### Python dependency errors

Run the managed setup again:

```bash
~/.antigravity/skills/seo/scripts/antigravity-seo setup
```

### Playwright screenshot errors

Run the managed setup again and inspect the result:

```bash
~/.antigravity/skills/seo/scripts/antigravity-seo setup
~/.antigravity/skills/seo/scripts/antigravity-seo doctor
```

### Permission errors on Unix

Make sure scripts are executable:

```bash
chmod +x ~/.antigravity/skills/seo/scripts/*.py
```
