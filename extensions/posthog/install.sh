#!/usr/bin/env bash
# Antigravity SEO: PostHog extension installer.
#
# Plugin installs already ship the skill (skills/seo-posthog) and the agent
# (agents/seo-posthog.md), so only the MCP server is registered there. Manual
# installs (~/.antigravity/skills/seo) also get the skill and agent copied. Data
# comes from the PostHog MCP server, so no credential is collected or stored
# here.
set -euo pipefail

main() {
    SKILL_DIR="${HOME}/.antigravity/skills"
    AGENTS_DIR="${HOME}/.antigravity/agents"

    echo "════════════════════════════════════════"
    echo "║ Antigravity SEO - PostHog extension      ║"
    echo "════════════════════════════════════════"

    SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" >/dev/null 2>&1 && pwd)"

    # Support both manual (~/.antigravity/skills/seo) and plugin installs
    # (${ANTIGRAVITY_PLUGIN_ROOT}, this checkout, or ~/.antigravity/plugins/cache/...).
    # A plugin install never populates ~/.antigravity/skills/seo, so that check alone
    # would always abort; check the plugin locations too before failing.
    INSTALL_MODE=""
    PLUGIN_ROOT=""
    if [ -d "${SKILL_DIR}/seo" ]; then
        INSTALL_MODE="manual"
    elif [ -n "${ANTIGRAVITY_PLUGIN_ROOT:-}" ] && [ -d "${ANTIGRAVITY_PLUGIN_ROOT}/skills/seo" ]; then
        INSTALL_MODE="plugin"; PLUGIN_ROOT="${ANTIGRAVITY_PLUGIN_ROOT}"
    else
        _OWN_ROOT="$(cd "${SOURCE_DIR}/../.." >/dev/null 2>&1 && pwd || true)"
        if [ -n "${_OWN_ROOT}" ] && [ -d "${_OWN_ROOT}/skills/seo" ] && [ -f "${_OWN_ROOT}/.antigravity-plugin/plugin.json" ]; then
            INSTALL_MODE="plugin"; PLUGIN_ROOT="${_OWN_ROOT}"
        else
            _GLOB_MATCH=$(ls -d "${HOME}/.antigravity/plugins/cache/"*/antigravity-seo/*/skills/seo 2>/dev/null | tail -n1 || true)
            if [ -n "${_GLOB_MATCH}" ] && [ -d "${_GLOB_MATCH}" ]; then
                INSTALL_MODE="plugin"; PLUGIN_ROOT="$(cd "${_GLOB_MATCH}/../.." >/dev/null 2>&1 && pwd)"
            fi
        fi
    fi
    if [ -z "${INSTALL_MODE}" ]; then
        echo "✗ antigravity-seo base not installed (no plugin install and no ~/.antigravity/skills/seo)."
        exit 1
    fi

    if [ "${INSTALL_MODE}" = "plugin" ]; then
        echo "✓ antigravity-seo plugin detected: registering the MCP server only."
        if [ ! -f "${PLUGIN_ROOT}/skills/seo-posthog/SKILL.md" ] || [ ! -f "${PLUGIN_ROOT}/agents/seo-posthog.md" ]; then
            echo "! This plugin version does not ship the seo-posthog skill and agent yet."
            echo "  Update the antigravity-seo plugin, then /seo posthog will load."
        fi
    fi

    if [ "${INSTALL_MODE}" = "manual" ]; then
        # Neither file carries a ${ANTIGRAVITY_PLUGIN_ROOT} launcher path, so a plain
        # copy is correct for a manual install.
        mkdir -p "${SKILL_DIR}/seo-posthog"
        cp "${SOURCE_DIR}/skills/seo-posthog/SKILL.md" "${SKILL_DIR}/seo-posthog/SKILL.md"
        echo "✓ Installed skill: ${SKILL_DIR}/seo-posthog/SKILL.md"

        mkdir -p "${AGENTS_DIR}"
        cp "${SOURCE_DIR}/agents/seo-posthog.md" "${AGENTS_DIR}/seo-posthog.md"
        echo "✓ Installed agent: ${AGENTS_DIR}/seo-posthog.md"
    fi

    if command -v antigravity >/dev/null 2>&1; then
        echo
        REPLY=""
        read -rp "Register the PostHog MCP server now (https://mcp.posthog.com/mcp)? [y/N]: " REPLY || REPLY=""
        if [[ "${REPLY}" =~ ^[Yy]$ ]]; then
            if antigravity mcp add --transport http posthog https://mcp.posthog.com/mcp; then
                echo "✓ MCP server registered. Run /mcp in Antigravity to authenticate."
            else
                echo "! Could not register the MCP server. See extensions/posthog/docs/POSTHOG-SETUP.md"
            fi
        fi
    else
        echo
        echo "! 'antigravity' CLI not found. Register the MCP server manually:"
        echo "  antigravity mcp add --transport http posthog https://mcp.posthog.com/mcp"
    fi

    echo
    echo "Use read-only PostHog access when you authenticate (see the setup doc)."
    echo "Done. Verify inside Antigravity with: /seo posthog check"
    echo "Full docs: extensions/posthog/docs/POSTHOG-SETUP.md"
}
main "$@"
