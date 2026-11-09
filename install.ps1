<#
.SYNOPSIS
    Installs the Catelier theme into your YASB config folder.

.DESCRIPTION
    Copies config.yaml, styles.css and the flavors folder into the YASB config
    folder ($env:YASB_CONFIG_HOME, or $HOME\.config\yasb when that isn't set),
    set to the flavor and accent you choose. Existing config.yaml and styles.css
    files are backed up first, next to the originals, with a timestamp in their names.

    Run it from a clone of the repository, or straight from GitHub:

        irm https://raw.githubusercontent.com/simsrw73/catelier/main/install.ps1 | iex

    To pass options when running from GitHub:

        & ([scriptblock]::Create((irm https://raw.githubusercontent.com/simsrw73/catelier/main/install.ps1))) -Flavor latte -Accent blue

.PARAMETER Flavor
    Catppuccin flavor: latte, frappe, macchiato or mocha (the default).

.PARAMETER Accent
    Catppuccin accent color used for focus and selection. The default is the
    flavor's own, which is mauve.

.PARAMETER Translucency
    How much of the desktop shows through the bar: off (the default), subtle,
    medium or strong. Needs Windows "Transparency effects" turned on.

.PARAMETER StylesOnly
    Install styles.css and the flavors folder only, and keep your current config.yaml.

.PARAMETER InstallFont
    If JetBrainsMono Nerd Font is missing, install it with winget without asking.
    Without this switch the script asks first. Windows asks for administrator
    approval, because the font installs for all users.
#>
[CmdletBinding()]
param(
    [ValidateSet('latte', 'frappe', 'macchiato', 'mocha')]
    [string]$Flavor = 'mocha',

    [ValidateSet('default', 'rosewater', 'flamingo', 'pink', 'mauve', 'red', 'maroon', 'peach',
        'yellow', 'green', 'teal', 'sky', 'sapphire', 'blue', 'lavender')]
    [string]$Accent = 'default',

    [ValidateSet('off', 'subtle', 'medium', 'strong')]
    [string]$Translucency = 'off',

    [switch]$StylesOnly,

    [switch]$InstallFont
)

$ErrorActionPreference = 'Stop'

$repoRaw = 'https://raw.githubusercontent.com/simsrw73/catelier/main'
$flavors = 'latte', 'frappe', 'macchiato', 'mocha'
$target = if ($env:YASB_CONFIG_HOME) { $env:YASB_CONFIG_HOME } else { Join-Path $HOME '.config\yasb' }
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'

# Reads a theme file from the local clone when there is one, otherwise from GitHub.
function Get-ThemeFile([string]$RelativePath) {
    if ($PSScriptRoot) {
        $local = Join-Path $PSScriptRoot $RelativePath
        if (Test-Path $local) { return [IO.File]::ReadAllText($local) }
    }
    return (Invoke-WebRequest "$repoRaw/$RelativePath" -UseBasicParsing).Content
}

# Returns a name -> hex table, such as surface0 -> #313244, from a flavor file.
function Get-Palette([string]$Css) {
    $palette = @{}
    foreach ($m in [regex]::Matches($Css, '--([a-z0-9]+):\s*(#[0-9a-fA-F]{6});')) {
        $palette[$m.Groups[1].Value] = $m.Groups[2].Value.ToLower()
    }
    return $palette
}

function Write-ThemeFile([string]$Name, [string]$Content) {
    $dest = Join-Path $target $Name
    if (Test-Path $dest) {
        $backup = "$dest.$stamp.bak"
        Copy-Item $dest $backup
        Write-Host "Backed up $Name to $backup"
    }
    [IO.File]::WriteAllText($dest, $Content, [Text.UTF8Encoding]::new($false))
    Write-Host "Installed $Name"
}

# True when the icon font (JetBrainsMono Nerd Font Propo) is installed, for this
# user or for all users.
function Test-NerdFont {
    $keys = 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts',
    'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts'
    foreach ($key in $keys) {
        $props = Get-ItemProperty $key -ErrorAction SilentlyContinue
        if (-not $props) { continue }
        foreach ($p in $props.PSObject.Properties) {
            if ($p.Name -match '^JetBrainsMono (NFP|Nerd Font Propo)\b') { return $true }
        }
    }
    return $false
}

# Checks for the Nerd Font, and installs it with winget if the user agrees (or
# passed -InstallFont). Returns $true when the font was installed just now.
function Install-NerdFont {
    if (Test-NerdFont) { return $false }
    $fontUrl = 'https://www.nerdfonts.com/font-downloads'
    Write-Host ''
    Write-Warning 'JetBrainsMono Nerd Font is not installed. Without it, the bar shows boxes instead of icons.'
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-Host "Download JetBrainsMono from $fontUrl and install the fonts in the zip."
        return $false
    }
    if (-not $InstallFont) {
        # Read-Host throws in a non-interactive shell; treat that as "no".
        try { $answer = Read-Host 'Install it now with winget? [Y/n]' } catch { $answer = 'n' }
        if ($answer -and $answer -notmatch '^(y|yes)$') {
            Write-Host "Skipped. Install it later with: winget install --id DEVCOM.JetBrainsMonoNerdFont"
            Write-Host "or download JetBrainsMono from $fontUrl"
            return $false
        }
    }
    Write-Host 'Installing JetBrainsMono Nerd Font (Windows asks for administrator approval)...'
    winget install --id DEVCOM.JetBrainsMonoNerdFont --exact --source winget `
        --accept-package-agreements --accept-source-agreements | Out-Host
    if ($LASTEXITCODE -ne 0 -and -not (Test-NerdFont)) {
        Write-Warning "winget couldn't install the font (exit code $LASTEXITCODE). Download JetBrainsMono from $fontUrl"
        return $false
    }
    Write-Host 'Installed JetBrainsMono Nerd Font'
    return $true
}

New-Item -ItemType Directory -Force -Path (Join-Path $target 'flavors') | Out-Null

# Flavor palettes
$flavorCss = @{}
foreach ($f in $flavors) {
    $flavorCss[$f] = Get-ThemeFile "flavors/$f.css"
    [IO.File]::WriteAllText((Join-Path $target "flavors\$f.css"), $flavorCss[$f], [Text.UTF8Encoding]::new($false))
}
Write-Host "Installed flavors\ ($($flavors -join ', '))"

# styles.css: pick the flavor and accent
$styles = Get-ThemeFile 'styles.css'
$styles = $styles -replace '@import "flavors/[a-z]+\.css";', "@import `"flavors/$Flavor.css`";"
$accentVar = if ($Accent -eq 'default') { 'flavor-accent' } else { $Accent }
$styles = $styles -replace '--accent: var\(--[a-z-]+\);', "--accent: var(--$accentVar);"
$styles = $styles -replace '--accent-rgb: var\(--[a-z-]+\);', "--accent-rgb: var(--$accentVar-rgb);"
$glass = @{ off = '1', '1'; subtle = '0.6', '0.8'; medium = '0.4', '0.7'; strong = '0.2', '0.6' }[$Translucency]
$styles = $styles -replace '--bar-glass: [0-9.]+;', "--bar-glass: $($glass[0]);"
$styles = $styles -replace '--pill-glass: [0-9.]+;', "--pill-glass: $($glass[1]);"
Write-ThemeFile 'styles.css' $styles

# config.yaml: a few popup borders and labels are colors in the config, written in
# Mocha. Swap each one for the same-named color in the chosen flavor. The drive
# popup headings (#9399b2, Mocha overlay2) are muted text, so they follow the
# flavor's --fg-muted role instead, which Latte maps to a darker shade.
if (-not $StylesOnly) {
    $config = Get-ThemeFile 'config.yaml'
    if ($Flavor -ne 'mocha') {
        $from = Get-Palette $flavorCss['mocha']
        $to = Get-Palette $flavorCss[$Flavor]
        $map = @{}
        foreach ($name in $from.Keys) { $map[$from[$name]] = $to[$name] }
        $muted = [regex]::Match($flavorCss[$Flavor], '--fg-muted:\s*var\(--([a-z0-9]+)\)').Groups[1].Value
        if ($muted) { $map[$from['overlay2']] = $to[$muted] }
        # One pass, so a swapped color is never swapped again
        $config = [regex]::Replace($config, '#[0-9a-fA-F]{6}\b', {
                param($m)
                $hex = $m.Value.ToLower()
                if ($map.ContainsKey($hex)) { $map[$hex] } else { $m.Value }
            })
    }
    if ($Flavor -eq 'latte') {
        $config = $config -replace 'dark_mode: true', 'dark_mode: false'
    }
    Write-ThemeFile 'config.yaml' $config
}

$fontInstalled = Install-NerdFont

Write-Host ''
$accentName = if ($Accent -eq 'default') { "its default" } else { "a $Accent" }
$glassName = if ($Translucency -eq 'off') { 'a solid bar' } else { "$Translucency translucency" }
Write-Host "Done: Catppuccin $Flavor with $accentName accent and $glassName."
if ($fontInstalled) {
    Write-Host 'Restart YASB so it picks up the new font.'
} else {
    Write-Host 'YASB reloads on its own if watch_config is on; otherwise restart it.'
}
