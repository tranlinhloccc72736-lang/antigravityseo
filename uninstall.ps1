#!/usr/bin/env pwsh
# antigravity-seo manual-install uninstaller (Windows)
#
# Removes the orchestrator skill (~/.antigravity/skills/seo), all sub-skills
# (~/.antigravity/skills/seo-*), and all sub-agents (~/.antigravity/agents/seo-*.md).
#
# Uses glob enumeration rather than a hardcoded list so future skill
# additions are cleaned up automatically without releasing a new
# uninstaller.
#
# Plugin-install users should use Antigravity's own command instead:
#   /plugin uninstall antigravity-seo@antigravity-antigravity-seo
#   /plugin marketplace remove Antigravity/antigravity-seo

$ErrorActionPreference = "Stop"

function Write-Color($Color, $Text) {
    Write-Host $Text -ForegroundColor $Color
}

function Main {
    $SkillDir = Join-Path (Join-Path $env:USERPROFILE ".antigravity") "skills"
    $AgentDir = Join-Path (Join-Path $env:USERPROFILE ".antigravity") "agents"

    Write-Color Cyan "=== Uninstalling antigravity-seo ==="
    Write-Host ""

    $removedSkills = 0
    $removedAgents = 0

    # Remove orchestrator if present
    $orchestratorPath = Join-Path $SkillDir "seo"
    if (Test-Path $orchestratorPath -PathType Container) {
        Remove-Item -Recurse -Force $orchestratorPath
        Write-Color Green "  Removed: $orchestratorPath"
        $removedSkills++
    }

    # Remove every seo-* sub-skill directory
    if (Test-Path $SkillDir -PathType Container) {
        foreach ($subSkill in @(Get-ChildItem -Path $SkillDir -Directory -Filter "seo-*" -ErrorAction SilentlyContinue)) {
            Remove-Item -Recurse -Force $subSkill.FullName
            Write-Color Green "  Removed: $($subSkill.FullName)"
            $removedSkills++
        }
    }

    # Remove every seo-*.md agent file
    if (Test-Path $AgentDir -PathType Container) {
        foreach ($agentFile in @(Get-ChildItem -Path $AgentDir -File -Filter "seo-*.md" -ErrorAction SilentlyContinue)) {
            Remove-Item -Force $agentFile.FullName
            Write-Color Green "  Removed: $($agentFile.FullName)"
            $removedAgents++
        }
    }

    Write-Host ""
    if ($removedSkills -eq 0 -and $removedAgents -eq 0) {
        Write-Color Yellow "Nothing to remove. Antigravity SEO does not appear to be installed."
        Write-Color Yellow "If you installed via /plugin install, run /plugin uninstall instead."
        return
    }

    Write-Color Cyan "=== antigravity-seo uninstalled ($removedSkills skill dirs, $removedAgents agent files) ==="
    Write-Host ""
    Write-Color Yellow "Restart Antigravity to complete removal."
}

Main
