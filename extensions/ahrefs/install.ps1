# Antigravity SEO - Ahrefs extension installer (Windows / PowerShell).
# Mirrors extensions/ahrefs/install.sh.
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

function Test-Cmd($name) {
    $null = Get-Command $name -ErrorAction SilentlyContinue
    return $?
}

if (-not (Test-Cmd npx)) { throw "Node 18+ / npx is required." }

$SkillDir = Join-Path $HOME ".antigravity/skills"
# MCP servers live in ~/.antigravity.json (the file `antigravity mcp add` writes).
# NOT ~/.antigravity/settings.json - `mcpServers` is not a key Antigravity reads
# there, so entries written to settings.json silently never load.
$McpConfigJson = Join-Path $HOME ".antigravity.json"

if (-not (Test-Path (Join-Path $SkillDir "seo"))) {
    throw "antigravity-seo base plugin not installed."
}

$Token = Read-Host "Ahrefs API token" -AsSecureString
$Plain = [System.Net.NetworkCredential]::new("", $Token).Password
if (-not $Plain) { throw "No token provided." }

$SourceDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$SkillTarget = Join-Path $SkillDir "seo-ahrefs"
New-Item -ItemType Directory -Path $SkillTarget -Force | Out-Null
Copy-Item -Path (Join-Path $SourceDir "skills/seo-ahrefs/SKILL.md") `
          -Destination (Join-Path $SkillTarget "SKILL.md") -Force
Write-Host "[OK] Installed skill: $SkillTarget"

# Pre-warm.
& npx --yes --package=@ahrefs/mcp@0.0.11 mcp --help *> $null

# Merge ~/.antigravity.json.
$settingsContent = if (Test-Path $McpConfigJson) { Get-Content $McpConfigJson -Raw | ConvertFrom-Json } else { [pscustomobject]@{} }
if (-not $settingsContent.mcpServers) { $settingsContent | Add-Member -NotePropertyName mcpServers -NotePropertyValue ([pscustomobject]@{}) -Force }
$settingsContent.mcpServers | Add-Member -NotePropertyName 'ahrefs' -NotePropertyValue @{
    command = 'npx'
    args = @('--yes', '--package=@ahrefs/mcp@0.0.11', 'mcp')
    env = @{ AHREFS_API_TOKEN = $Plain }
} -Force
# Write atomically: stage to a temp file in the same directory, then swap
# it into place, so a crash mid-write never leaves ~/.antigravity.json truncated
# or half-written (it is shared with Antigravity and other installers).
# -Depth 100 (not the ConvertTo-Json default of 2) so an existing
# ~/.antigravity.json with deeply nested config round-trips intact.
$TempConfigJson = Join-Path (Split-Path -Parent $McpConfigJson) ".antigravity.json.$([guid]::NewGuid().ToString('N')).tmp"
$jsonText = $settingsContent | ConvertTo-Json -Depth 100
# Write without a byte-order mark: on Windows PowerShell 5.1, Set-Content -Encoding UTF8
# emits a BOM and Node's JSON.parse rejects it, which would make ~/.antigravity.json unreadable.
[System.IO.File]::WriteAllText($TempConfigJson, $jsonText, (New-Object System.Text.UTF8Encoding $false))
Move-Item -Path $TempConfigJson -Destination $McpConfigJson -Force
Write-Host "Wrote mcpServers.ahrefs to $McpConfigJson"

Write-Host ""
Write-Host "Done. Open a new Antigravity session and run /seo ahrefs metrics <url>."
