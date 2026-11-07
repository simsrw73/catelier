<#
.SYNOPSIS
    Installs the Catelier theme into your YASB config folder.

.DESCRIPTION
    Copies config.yaml and styles.css into the YASB config folder
    ($env:YASB_CONFIG_HOME, or $HOME\.config\yasb when that isn't set).
    Existing files are backed up first, next to the originals, with a
    timestamp in their names.

    Run it from a clone of the repository, or straight from GitHub:

        irm https://raw.githubusercontent.com/simsrw73/catelier/main/install.ps1 | iex

.PARAMETER StylesOnly
    Install styles.css only and keep your current config.yaml.
#>
[CmdletBinding()]
param(
    [switch]$StylesOnly
)

$ErrorActionPreference = 'Stop'

$repoRaw = 'https://raw.githubusercontent.com/simsrw73/catelier/main'
$target = if ($env:YASB_CONFIG_HOME) { $env:YASB_CONFIG_HOME } else { Join-Path $HOME '.config\yasb' }
$files = if ($StylesOnly) { @('styles.css') } else { @('config.yaml', 'styles.css') }
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'

New-Item -ItemType Directory -Force -Path $target | Out-Null

foreach ($name in $files) {
    $dest = Join-Path $target $name

    if (Test-Path $dest) {
        $backup = "$dest.$stamp.bak"
        Copy-Item $dest $backup
        Write-Host "Backed up $name to $backup"
    }

    $local = if ($PSScriptRoot) { Join-Path $PSScriptRoot $name }
    if ($local -and (Test-Path $local)) {
        Copy-Item $local $dest -Force
    } else {
        Invoke-WebRequest "$repoRaw/$name" -OutFile $dest -UseBasicParsing
    }
    Write-Host "Installed $name to $dest"
}

Write-Host ''
Write-Host 'Done. YASB reloads on its own if watch_config is on; otherwise restart it.'
