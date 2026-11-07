<#
.SYNOPSIS
    Builds Catelier Lite, the two-file version for the YASB theme gallery.

.DESCRIPTION
    The gallery stores only config.yaml and styles.css. This writes a copy of
    each to dist\catelier-lite\ and zips them as dist\catelier-lite.zip:

    - styles.css gets the Mocha palette inlined in place of its @import.
    - config.yaml leaves out the drive health widget, which needs
      LibreHardwareMonitor and sensor IDs from each user's own machine.
    - Both files say they're Catelier Lite and link to the full version.

    Every rewrite must match exactly once, so the build stops instead of
    producing a broken theme when the source files change.
#>
[CmdletBinding()]
param(
    [string]$Out = (Join-Path $PSScriptRoot 'dist')
)

$ErrorActionPreference = 'Stop'

$repo = 'https://github.com/simsrw73/catelier'
$utf8 = [Text.UTF8Encoding]::new($false)

function Read-Source([string]$RelativePath) {
    [IO.File]::ReadAllText((Join-Path $PSScriptRoot $RelativePath)).Replace("`r`n", "`n")
}

# Replaces one exact occurrence of $Old with $New, or stops the build.
function Edit-Once([string]$Text, [string]$Old, [string]$New, [string]$What) {
    $count = ([regex]::Matches($Text, [regex]::Escape($Old))).Count
    if ($count -ne 1) { throw "build-gallery: expected one match for $What, found $count" }
    return $Text.Replace($Old, $New)
}

# Same, for a regex pattern. The replacement is literal text.
function Edit-OncePattern([string]$Text, [string]$Pattern, [string]$New, [string]$What) {
    $matches = [regex]::Matches($Text, $Pattern, 'Singleline')
    if ($matches.Count -ne 1) { throw "build-gallery: expected one match for $What, found $($matches.Count)" }
    return $Text.Remove($matches[0].Index, $matches[0].Length).Insert($matches[0].Index, $New)
}

# ── styles.css ──
$styles = Read-Source 'styles.css'
$mocha = (Read-Source 'flavors/mocha.css').TrimEnd()

$styles = Edit-Once $styles ' * Catelier — a Catppuccin theme for YASB
 * https://github.com/simsrw73/catelier
' " * Catelier Lite — a Catppuccin Mocha theme for YASB, from the YASB theme gallery.
 * The full version, with all four flavors, accent and translucency options and
 * GlazeWM support, is at $repo
" 'the header'

$styles = Edit-Once $styles ' * Flavor: change the file name to latte, frappe, macchiato or mocha.
 * (install.ps1 -Flavor does this for you, along with the matching colors in config.yaml.)
 */
@import "flavors/mocha.css";
' " * Lite has the Mocha palette built in, below. The full version adds Latte, Frappé
 * and Macchiato: $repo
 */
$mocha
" 'the flavor import'

$styles = Edit-Once $styles 'Change both numbers (install.ps1 -Translucency does this for you):' `
    'Change both numbers:' 'the translucency note'

$styles = Edit-Once $styles 'docs/glazewm.md shows how to swap it in.' `
    "$repo/blob/main/docs/glazewm.md shows how to swap it in." 'the GlazeWM link'

# The drive health widget isn't in Lite, so its popup styles go too
$styles = Edit-OncePattern $styles '/\* ── Drives \(LibreHardwareMonitor\) ──.*?(?=/\* ── Calendar ── \*/)' '' 'the drive styles'

if ($styles -match '@import') { throw 'build-gallery: styles.css still has an @import' }

# ── config.yaml ──
$config = Read-Source 'config.yaml'

$config = Edit-Once $config '# Catelier — a Catppuccin theme for YASB and komorebi.
# https://github.com/simsrw73/catelier
' "# Catelier Lite — a Catppuccin Mocha theme for YASB and komorebi, from the YASB
# theme gallery. The full version, with all four flavors, accent and translucency
# options, GlazeWM support and a drive health widget, is at
# $repo
" 'the header'

$config = Edit-Once $config '["memory", "cpu", "gpu", "disk", "ssd_health", "traffic"]' `
    '["memory", "cpu", "gpu", "disk", "traffic"]' 'the metrics group'

$config = Edit-OncePattern $config '  # Drive health and temperature.*?\n\n(?=  traffic:)' '' 'the drive health widget'

if ($config -match 'ssd_health|libre_monitor') { throw 'build-gallery: config.yaml still mentions the drive health widget' }

# ── Write ──
$dir = Join-Path $Out 'catelier-lite'
New-Item -ItemType Directory -Force -Path $dir | Out-Null
[IO.File]::WriteAllText((Join-Path $dir 'styles.css'), $styles, $utf8)
[IO.File]::WriteAllText((Join-Path $dir 'config.yaml'), $config, $utf8)

$zip = Join-Path $Out 'catelier-lite.zip'
Compress-Archive -Path (Join-Path $dir 'config.yaml'), (Join-Path $dir 'styles.css') -DestinationPath $zip -Force

Write-Host "Built Catelier Lite in $dir"
Write-Host "Gallery ZIP: $zip"
