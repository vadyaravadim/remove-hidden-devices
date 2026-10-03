<#PSScriptInfo

.VERSION 0.0.0

.GUID b7ca4884-b23d-4029-826b-34f4b5fc496b

.AUTHOR vadyaravadim

.COMPANYNAME

.COPYRIGHT

.TAGS Windows Windows10 Windows11 DeviceManager GhostDevices HiddenDevices Cleanup PnP Drivers Tweak

.LICENSEURI https://github.com/vadyaravadim/remove-hidden-devices/blob/main/LICENSE

.PROJECTURI https://github.com/vadyaravadim/remove-hidden-devices

.ICONURI

.EXTERNALMODULEDEPENDENCIES

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES

.RELEASENOTES

.PRIVATEDATA

#>

<#
.SYNOPSIS
    Removes hidden / ghost devices (non-present hardware) from Device Manager on Windows 10/11.
.DESCRIPTION
    Enumerates devices whose driver is still registered but that are not
    currently present - the ghost entries left behind by unplugged USB sticks,
    headsets, dongles and old GPUs - and removes them so Device Manager reflects
    only hardware that is actually connected. Self-elevates via UAC. Zero
    external dependencies.
.PARAMETER Status
    List the hidden devices and change nothing. Does not need Administrator
    rights.
.NOTES
    Requirements: Windows 10/11. The script requests administrator rights on
    its own (UAC prompt).
.LINK
    https://github.com/vadyaravadim/remove-hidden-devices
#>
[CmdletBinding()]
param(
    [switch]$Status,
    [switch]$Elevated   # internal: set by the self-elevation relaunch
)

# Keep the self-elevated window open so the user can read the output.
function Wait-IfElevatedWindow {
    if ($Elevated) { Read-Host "Press Enter to close" | Out-Null }
}

# Without this, an unhandled error closes the self-elevated window before
# the user can read the message.
trap {
    Write-Host "ERROR: $_" -ForegroundColor Red
    Wait-IfElevatedWindow
    # Under `irm | iex` this runs inside the user's own session, where `exit`
    # would close their console - rethrow so only the piped script stops.
    if ($PSCommandPath) { exit 1 }
    break
}

# Launched via `irm <url> | iex` - no file on disk. Save the script to the
# user profile and rerun it from there (the rerun handles elevation).
if (-not $PSCommandPath) {
    # The piped text is not recoverable from inside iex ($MyInvocation there
    # holds the caller's command line, not the script body) - download the
    # script.
    try {
        $body = Invoke-RestMethod 'https://github.com/vadyaravadim/remove-hidden-devices/releases/latest/download/remove-hidden-devices.ps1' -TimeoutSec 30 -ErrorAction Stop
    } catch {
        Write-Host "ERROR: could not download the script ($($_.Exception.Message)). Check your internet connection, or save the script to a file and run it from there." -ForegroundColor Red
        return
    }
    $saved = Join-Path $env:USERPROFILE 'remove-hidden-devices.ps1'
    if ((Test-Path $saved) -and ([IO.File]::ReadAllText($saved) -cne $body)) {
        Copy-Item $saved "$saved.bak" -Force -ErrorAction Stop
        Write-Host "Existing $saved differs - previous copy kept as $saved.bak" -ForegroundColor Yellow
    }
    # UTF8Encoding($false) = no BOM: a BOM would break a later `irm | iex` of
    # the saved copy and violates the ASCII/no-BOM invariant the repo enforces.
    [IO.File]::WriteAllText($saved, $body, [Text.UTF8Encoding]::new($false))
    Write-Host "Script saved to: $saved" -ForegroundColor Cyan
    # @(): splatting a scalar string breaks powershell.exe -File switch binding on PS 5.1.
    $fwd = @(if ($Status) { '-Status' })
    powershell -NoProfile -ExecutionPolicy Bypass -File $saved @fwd
    # The rerun's exit code stays in $LASTEXITCODE for scripted callers.
    return
}

# Only now: under `irm | iex` the block above runs in the caller's own session,
# where Stop would stay behind in their console after the script is done.
$ErrorActionPreference = 'Stop'

# ---- Everything below -Status removes devices: Administrator required ----
$principal = New-Object Security.Principal.WindowsPrincipal(
    [Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $Status -and -not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Not running as Administrator. Requesting elevation..." -ForegroundColor Yellow
    try {
        Start-Process -FilePath 'powershell.exe' -Verb RunAs -ArgumentList @(
            '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$PSCommandPath`"", '-Elevated')
    } catch {
        # Not always a refusal (UAC service disabled, ...) - show the real cause.
        Write-Host "ERROR: elevation failed ($($_.Exception.Message)). Run this script as Administrator." -ForegroundColor Red
        Read-Host "Press Enter to close" | Out-Null
    }
    return
}

# Read from this file's own PSScriptInfo block - the one place the version
# lives (release.yml stamps the tag into it). 0.0.0 is the committed
# placeholder: a clone or ZIP of main, not a release.
$version = [regex]::Match((Get-Content -LiteralPath $PSCommandPath -Raw), '(?m)^\.VERSION\s+(\S+)').Groups[1].Value
$version = if ($version -eq '0.0.0') { 'dev build' } else { "v$version" }

Write-Host ""
Write-Host "===================================" -ForegroundColor Cyan
Write-Host "  REMOVE HIDDEN DEVICES $version" -ForegroundColor Cyan
Write-Host "===================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Scanning for hidden devices..."
# Not present = what Device Manager shows only under View > Show hidden devices.
$ghosts = @(Get-PnpDevice | Where-Object { -not $_.Present })
if (-not $ghosts) {
    Write-Host ""
    Write-Host "No hidden devices found." -ForegroundColor Green
    Wait-IfElevatedWindow
    return
}

Write-Host ""
Write-Host "Found $($ghosts.Count) hidden device(s):"
Write-Host ""
foreach ($d in $ghosts) {
    # Some ghosts carry no name; the instance ID still identifies them.
    $name = if ($d.FriendlyName) { $d.FriendlyName } else { $d.InstanceId }
    Write-Host ("   -> {0}{1}" -f $name, $(if ($d.Class) { "  [$($d.Class)]" }))
}
Write-Host ""

if ($Status) { Wait-IfElevatedWindow; return }

# Picked, not all-or-nothing: a ghost entry can carry settings worth keeping
# (a monitor's EDID override or color profile, a COM port number). Without a
# desktop (Server Core - ghost NICs after VM moves) there is no grid, so the
# all-or-nothing question stays as the fallback.
if (Get-Command Out-GridView -ErrorAction SilentlyContinue) {
    $targets = @($ghosts |
        ForEach-Object { [PSCustomObject]@{ Name = $(if ($_.FriendlyName) { $_.FriendlyName } else { $_.InstanceId }); Class = $_.Class; InstanceId = $_.InstanceId } } |
        Sort-Object Class, Name |
        Out-GridView -Title 'Select hidden devices to remove (Ctrl+A = all, Ctrl-click = several, Cancel = none)' -PassThru)
} else {
    Write-Host "==================================="
    $targets = if ((Read-Host "Remove these devices? (Y/N)") -match '^y') { $ghosts } else { @() }
}
if (-not $targets) {
    Write-Host ""
    Write-Host "Cancelled. No changes made." -ForegroundColor Yellow
    Wait-IfElevatedWindow
    return
}

Write-Host ""
Write-Host "Removing $($targets.Count) device(s)..."
$removed = 0
$needReboot = $false
foreach ($d in $targets) {
    pnputil /remove-device "$($d.InstanceId)"
    # 3010 = removed, and Windows needs a restart to finish (documented pnputil code).
    if ($LASTEXITCODE -in 0, 3010) { $removed++ }
    if ($LASTEXITCODE -eq 3010) { $needReboot = $true }
}

Write-Host ""
if ($removed -eq $targets.Count) {
    Write-Host "Removed $removed of $($targets.Count) device(s)." -ForegroundColor Green
} else {
    Write-Host "Removed $removed of $($targets.Count) device(s) - pnputil says why the rest failed above." -ForegroundColor Yellow
}
if ($needReboot) { Write-Host "Restart Windows to finish removing them." -ForegroundColor Yellow }
if ($removed) {
    Write-Host ""
    Write-Host "Useful? A star on GitHub helps others find it: https://github.com/vadyaravadim/remove-hidden-devices"
}
Wait-IfElevatedWindow
