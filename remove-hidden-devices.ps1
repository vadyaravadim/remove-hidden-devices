# ============================================================================
# Remove Unknown Devices
# Removes all devices with 'Unknown' status from Device Manager
# 
# Author: https://github.com/vadyaravadim
# Version: 1.0
# Requirements: Windows 10/11, Run as Administrator
# ============================================================================

Write-Host "==================================="
Write-Host "REMOVE UNKNOWN DEVICES"
Write-Host "==================================="
Write-Host ""

# Check Administrator privileges
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "ERROR: Run PowerShell as Administrator!"
    pause
    exit
}

try {
    # Get unknown devices
    Write-Host "Scanning for unknown devices..."
    $UnknownDevices = Get-PnpDevice | Where-Object { $_.Status -eq 'Unknown' }
    
    if ($UnknownDevices.Count -eq 0) {
        Write-Host ""
        Write-Host "✓ No unknown devices found"
        Write-Host ""
        pause
        exit
    }
    
    Write-Host ""
    Write-Host "Found $($UnknownDevices.Count) unknown device(s):"
    Write-Host ""
    
    $UnknownDevices | ForEach-Object { 
        Write-Host "   → $($_.FriendlyName)"
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
    Write-Host "✓ Done"
    Write-Host ""
    
} catch {
    Write-Host ""
    Write-Host "ERROR: $($_.Exception.Message)"
    Write-Host ""
}

pause