<#PSScriptInfo

.VERSION 1.0.0

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
.NOTES
    Requirements: Windows 10/11. The script requests administrator rights on
    its own (UAC prompt).
.LINK
    https://github.com/vadyaravadim/remove-hidden-devices
#>

# Launched via `irm <url> | iex` - no file on disk. Save the script to the
# user profile and rerun it from there (the rerun handles elevation).
if (-not $PSCommandPath) {
    # The piped text is not recoverable from inside iex ($MyInvocation there
    # holds the caller's command line, not the script body) - download the
    # script.
    try {
        $body = Invoke-RestMethod 'https://raw.githubusercontent.com/vadyaravadim/remove-hidden-devices/main/remove-hidden-devices.ps1' -TimeoutSec 30
    } catch {
        Write-Host "ERROR: could not download the script ($($_.Exception.Message)). Check your internet connection, or save the script to a file and run it from there." -ForegroundColor Red
        return
    }
    $saved = Join-Path $env:USERPROFILE 'remove-hidden-devices.ps1'
    if ((Test-Path $saved) -and ([IO.File]::ReadAllText($saved) -cne $body)) {
        Copy-Item $saved "$saved.bak" -Force
        Write-Host "Existing $saved differs - previous copy kept as $saved.bak" -ForegroundColor Yellow
    }
    [IO.File]::WriteAllText($saved, $body, [Text.Encoding]::UTF8)
    Write-Host "Script saved to: $saved" -ForegroundColor Cyan
    powershell -NoProfile -ExecutionPolicy Bypass -File $saved
    # The rerun's exit code stays in $LASTEXITCODE for scripted callers.
    return
}

Write-Host "==================================="
Write-Host "REMOVE UNKNOWN DEVICES"
Write-Host "==================================="
Write-Host ""

# Self-elevate via UAC when not running as Administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Not running as Administrator. Requesting elevation..."
    try {
        Start-Process -FilePath 'powershell.exe' -Verb RunAs -ArgumentList @(
            '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$PSCommandPath`"")
    } catch {
        # Not always a refusal (UAC service disabled, ...) - show the real cause.
        Write-Host "ERROR: elevation failed ($($_.Exception.Message)). Run this script as Administrator."
        pause
    }
    exit
}

try {
    # Get unknown devices
    Write-Host "Scanning for unknown devices..."
    $UnknownDevices = Get-PnpDevice | Where-Object { $_.Status -eq 'Unknown' }
    
    if ($UnknownDevices.Count -eq 0) {
        Write-Host ""
        Write-Host "No unknown devices found"
        Write-Host ""
        pause
        exit
    }
    
    Write-Host ""
    Write-Host "Found $($UnknownDevices.Count) unknown device(s):"
    Write-Host ""
    
    $UnknownDevices | ForEach-Object { 
        Write-Host "   -> $($_.FriendlyName)"
    }
    
    Write-Host ""
    Write-Host "==================================="
    $Confirm = Read-Host "Remove these devices? (Y/N)"
    
    if ($Confirm -ne 'Y' -and $Confirm -ne 'y') {
        Write-Host ""
        Write-Host "Operation cancelled"
        Write-Host ""
        pause
        exit
    }
    
    Write-Host ""
    Write-Host "Removing devices..."
    
    foreach ($Device in $UnknownDevices) {
        pnputil /remove-device "$($Device.InstanceId)"
    }
    
    Write-Host ""
    Write-Host "==================================="
    Write-Host "REMOVE UNKNOWN DEVICES COMPLETED"
    Write-Host "==================================="
    Write-Host ""
    Write-Host "For full registry changes to take effect,"
    Write-Host "a system restart is recommended."
    Write-Host ""

    $reboot = Read-Host "Restart computer now? (y/n)"
    if ($reboot -eq "y" -or $reboot -eq "Y") {
        Write-Host ""
        Write-Host "Restarting in 10 seconds..."
        Write-Host "Press Ctrl+C to cancel"
        
        for ($i = 10; $i -gt 0; $i--) {
            Write-Host "Restarting in $i seconds..." -NoNewline
            Start-Sleep -Seconds 1
            Write-Host "`r" -NoNewline
        }
        
        Write-Host ""
        Write-Host "Restarting..." -ForegroundColor Green
        Restart-Computer -Force
    } else {
        Write-Host ""
        Write-Host "Restart cancelled." -ForegroundColor Yellow
        Write-Host "Don't forget to restart your computer later"
        Write-Host "for full registry changes to take effect!"
    }
    
} catch {
    Write-Host ""
    Write-Host "ERROR: $($_.Exception.Message)"
    Write-Host ""
}

pause