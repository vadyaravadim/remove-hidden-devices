<div align="center">

# Remove Hidden Devices

**Clean out ghost devices. Declutter Device Manager. One confirmation.**

An open-source PowerShell script that removes **ghost / hidden devices** (devices with `Unknown` status) from Windows Device Manager — leftovers from every USB stick, headset, and dongle you ever plugged in.
Zero install. Zero dependencies. You see the full list before anything is removed.

[![lint](https://img.shields.io/github/actions/workflow/status/vadyaravadim/remove-hidden-devices/lint.yml?label=lint&logo=powershell)](https://github.com/vadyaravadim/remove-hidden-devices/actions/workflows/lint.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Windows 10/11](https://img.shields.io/badge/Windows-10%20%7C%2011-0078D4?logo=windows)](https://www.microsoft.com/windows)
[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-5391FE?logo=powershell&logoColor=white)](https://docs.microsoft.com/en-us/powershell/)
[![Latest release](https://img.shields.io/github/v/release/vadyaravadim/remove-hidden-devices)](https://github.com/vadyaravadim/remove-hidden-devices/releases)
![GitHub Stars](https://img.shields.io/github/stars/vadyaravadim/=social)

</div>

---

## Quick Start

**Easiest — download & double-click:**

1. Click **Code ▸ Download ZIP** at the top of this page, then unzip.
2. Double-click **`Run.bat`**.
3. Click **Yes** on the UAC prompt (the script requests admin rights on its own).
4. Review the device list, confirm with `Y`.

**One-liner** instead (in any PowerShell — it self-elevates):

```powershell
irm https://raw.githubusercontent.com/vadyaravadim/remove-hidden-devices/main/remove-hidden-devices.ps1 | iex
```

The script saves itself to `%USERPROFILE%\remove-hidden-devices.ps1` and reruns from there; an existing copy at that path that differs is kept as `.bak`.

**Or clone:**

```powershell
git clone https://github.com/vadyaravadim/remove-hidden-devices.git
cd remove-hidden-devices
.\Run.bat
```

## What It Does

1. **Scans** for all devices with `Unknown` status — the ghost devices Device Manager only shows under *View ▸ Show hidden devices*
2. **Shows the full list** and asks for confirmation — nothing is touched until you say `Y`
3. **Removes** every listed device via the built-in `pnputil /remove-device`
4. **Offers a reboot** so the registry changes fully take effect

```
===================================
REMOVE UNKNOWN DEVICES
===================================

Scanning for unknown devices...

Found 3 unknown device(s):

   → Generic USB Hub
   → Unknown Device
   → USB Composite Device

===================================
Remove these devices? (Y/N): y
```

## The Problem: Ghost Devices

Windows keeps a registry entry for **every device ever connected** — each USB stick, phone, headset, VM adapter, and docking station stays behind as a hidden "ghost" entry after you unplug it. Over the years they pile up into hundreds of stale entries.

**Symptoms this fixes:**

- Cluttered Device Manager full of greyed-out duplicates (`USB Composite Device`, `Unknown Device`, …)
- COM port numbers climbing endlessly (`COM14`, `COM15`, …) because old ones are still reserved
- Driver conflicts when a re-plugged device binds to a stale entry instead of a fresh one
- Slower device enumeration on boot and plug-in

## Requirements

| | |
|---|---|
| **Windows** | 10, 11 |
| **PowerShell** | Windows PowerShell 5.1+ (ships with Windows 10/11) |
| **Rights** | Administrator (the script self-elevates via UAC) |

## How It Works

The script uses two documented, built-in tools — no third-party binaries:

- [`Get-PnpDevice`](https://learn.microsoft.com/en-us/powershell/module/pnpdevice/get-pnpdevice) lists all Plug and Play devices; devices that are no longer present report `Status = Unknown` — the same ghost entries Device Manager greys out under *Show hidden devices*
- [`pnputil /remove-device <InstanceId>`](https://learn.microsoft.com/en-us/windows-hardware/drivers/devtest/pnputil-command-syntax) removes each device node from the system

## Verify

After the reboot, open **Device Manager** → **View ▸ Show hidden devices**: the greyed-out ghost entries are gone. Or run the script again — it reports `No unknown devices found`.

## Full Cleanup: Leftover Drivers

Removing the devices does not remove their driver packages from the DriverStore. For a complete cleanup:

1. Run this script to remove the ghost devices
2. Use [**Driver Store Explorer**](https://github.com/lostindark/DriverStoreExplorer) to delete the orphaned driver packages they left behind

## FAQ

### What are hidden (ghost) devices?

Registry entries for hardware that was connected at some point but is not present now. Device Manager hides them by default; *View ▸ Show hidden devices* reveals them as greyed-out entries. They serve no purpose once the hardware is gone.

### Is it safe to remove them?

The script only targets devices with `Unknown` status — i.e. not currently present. Hardware that is connected and working is not in the list. Still, **review the list before confirming**: removal is permanent, there is no undo file.

### What happens if I remove a device I still use sometimes?

Nothing dramatic — Windows re-detects it and reinstalls the driver the next time you plug it in. You may need to redo per-device settings (e.g. a manually assigned COM port number).

### Why does it ask for a restart?

Device removal touches the registry hive that Windows reads at boot. The changes apply fully after a restart.

### How is this different from clicking through Device Manager manually?

Device Manager makes you right-click ▸ Uninstall each ghost entry one by one — painful with hundreds of them. This script removes them all in one confirmed pass, using the same underlying mechanism.

## Related

- [CPU Parking Disabler](https://github.com/vadyaravadim/cpu-parking-disabler) — disable CPU core parking on Windows 10/11 to fix micro-stutters and input lag
- [MSI Mode Utility](https://github.com/vadyaravadim/msi-mode-utility) — enable MSI mode (Message Signaled Interrupts) for GPU, USB, network & audio devices to cut DPC latency and input lag
- [Interrupt Affinity Utility](https://github.com/vadyaravadim/interrupt-affinity-utility) — pin GPU, network, USB & audio interrupts to specific CPU cores (P/E-core aware) to tame DPC latency
- [Timer Resolution Utility](https://github.com/vadyaravadim/timer-resolution-utility) — set 0.5 ms timer resolution, disable dynamic tick, un-force HPET — with a built-in Sleep(1) benchmark
- [GameDVR & FSO Disabler](https://github.com/vadyaravadim/gamedvr-fso-disabler) — disable Game DVR / Xbox Game Bar capture and Fullscreen Optimizations to fix capture stutters and frame drops

Same idea across the series: one transparent PowerShell script, no binaries, you see exactly what changes.

## Disclaimer

Device removal is permanent — there is no undo file. Review the device list carefully before confirming. Reconnecting the hardware makes Windows reinstall it. Use at your own risk.

## License

[MIT](LICENSE) — use at your own risk.

---

<div align="center">

If this cleaned up your Device Manager, consider giving it a ⭐

[Report Issues](https://github.com/vadyaravadim/remove-hidden-devices/issues)

</div>
