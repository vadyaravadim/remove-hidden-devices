<div align="center">

# Remove Hidden Devices

**Clean out ghost devices. Declutter Device Manager. One confirmation.**

An open-source PowerShell script that removes **ghost / hidden devices** (devices that are no longer present) from Windows Device Manager — leftovers from every USB stick, headset, and dongle you ever plugged in.
Zero install. Zero dependencies. You see the full list before anything is removed.

[![lint](https://img.shields.io/github/actions/workflow/status/vadyaravadim/remove-hidden-devices/lint.yml?label=lint&logo=powershell)](https://github.com/vadyaravadim/remove-hidden-devices/actions/workflows/lint.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Windows 10/11](https://img.shields.io/badge/Windows-10%20%7C%2011-0078D4?logo=windows)](https://www.microsoft.com/windows)
[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-5391FE?logo=powershell&logoColor=white)](https://docs.microsoft.com/en-us/powershell/)
[![Latest release](https://img.shields.io/github/v/release/vadyaravadim/remove-hidden-devices)](https://github.com/vadyaravadim/remove-hidden-devices/releases)
[![PowerShell Gallery](https://img.shields.io/powershellgallery/v/remove-hidden-devices?logo=powershell&label=PS%20Gallery)](https://www.powershellgallery.com/packages/remove-hidden-devices)
[![GitHub Stars](https://img.shields.io/github/stars/vadyaravadim/remove-hidden-devices?style=social)](https://github.com/vadyaravadim/remove-hidden-devices/stargazers)

**Part of the [RigPolice Latency Toolbox](https://rigpolice.com/system/latency-toolbox/?utm_source=github&utm_medium=readme&utm_campaign=remove-hidden-devices) — check every button and the scroll wheel with the free [Mouse Test](https://rigpolice.com/mouse/tests/mouse-test/?utm_source=github&utm_medium=readme&utm_campaign=remove-hidden-devices)**

If it cleans up your Device Manager, a ⭐ helps others find it.

</div>

---

## Quick Start

**Easiest — one line, in any PowerShell** (it self-elevates):

```powershell
irm https://github.com/vadyaravadim/remove-hidden-devices/releases/latest/download/remove-hidden-devices.ps1 | iex
```

The script saves itself to `%USERPROFILE%\remove-hidden-devices.ps1` and reruns from there; an existing copy at that path that differs is kept as `.bak`.

**From the PowerShell Gallery**, in PowerShell 7 (`pwsh`):

```powershell
Install-Script remove-hidden-devices
remove-hidden-devices                # then run it by name (open a NEW PowerShell window first, so the Scripts folder is on PATH)
```

The script self-elevates. Update later with `Update-Script remove-hidden-devices`. Not in the Windows PowerShell 5.1 that comes with Windows: there `Install-Script` wants an admin console and the default execution policy blocks the installed script — use the one-liner instead.

**Or clone:**

```powershell
git clone https://github.com/vadyaravadim/remove-hidden-devices.git
cd remove-hidden-devices
.\Run.bat
```

**Or download the ZIP** (no PowerShell needed): click **Code ▸ Download ZIP** at the top of this page, unzip, then double-click **`Run.bat`**.

Whichever method you use: click **Yes** on the UAC prompt (the script requests admin rights on its own), then pick the devices to remove in the grid (`Ctrl+A` for all) and click **OK**.

### Running it again

To clean up again after more ghost devices pile up, run it the way you installed it:

| Installed via | Command |
|---------------|---------|
| PowerShell Gallery (PowerShell 7) | `remove-hidden-devices` |
| ZIP or clone | `.\Run.bat` from the script's folder |
| One-liner | `powershell -ExecutionPolicy Bypass -File "$env:USERPROFILE\remove-hidden-devices.ps1"` |

**Just looking?** Add `-Status` to any of these commands: it lists the hidden devices and removes nothing, so it needs no admin rights.

Calling `.\remove-hidden-devices.ps1` directly only works if your execution policy allows scripts — Windows blocks them by default, which is what `Run.bat` and `-ExecutionPolicy Bypass` get around.

## What It Does

1. **Scans** for all devices that are no longer present — the ghost devices Device Manager only shows under *View ▸ Show hidden devices*
2. **Shows the full list** with each device's class, then a grid to pick which ones to remove — `Ctrl+A` for all, **Cancel** touches nothing. Without a desktop (Server Core) there is no grid, and it asks one `Y/N` for the whole list instead
3. **Removes** the devices you picked via the built-in `pnputil /remove-device` and reports how many were removed
4. **Asks for a restart only if Windows needs one** to finish — `pnputil` reports that per device

```
===================================
  REMOVE HIDDEN DEVICES vX.Y.Z
===================================

Scanning for hidden devices...

Found 3 hidden device(s):

   -> Generic USB Hub  [USB]
   -> HID-compliant mouse  [Mouse]
   -> USB Composite Device  [USB]

(grid: pick the devices to remove, then OK)
Removing 3 device(s)...
```

## The Problem: Ghost Devices

Windows keeps a registry entry for **every device ever connected** — each USB stick, phone, headset, VM adapter, and docking station stays behind as a hidden "ghost" entry after you unplug it. Over the years they pile up into hundreds of stale entries.

**What it fixes:** a Device Manager full of greyed-out duplicates (`USB Composite Device`, `Unknown Device`, …). Nothing more: it makes no speed or latency claim.

## Requirements

| | |
|---|---|
| **Windows** | 10, 11 |
| **PowerShell** | Windows PowerShell 5.1+ (ships with Windows 10/11) |
| **Rights** | Administrator (the script self-elevates via UAC) |

## How It Works

The script uses two documented, built-in tools — no third-party binaries:

- [`Get-PnpDevice`](https://learn.microsoft.com/en-us/powershell/module/pnpdevice/get-pnpdevice) lists all Plug and Play devices; devices that are no longer present report `Present = False` — the same ghost entries Device Manager greys out under *Show hidden devices*
- [`pnputil /remove-device <InstanceId>`](https://learn.microsoft.com/en-us/windows-hardware/drivers/devtest/pnputil-command-syntax) removes each device node from the system

## Verify

Open **Device Manager** → **View ▸ Show hidden devices**: the greyed-out ghost entries are gone. Or run the script with `-Status` — it reports `No hidden devices found.`

## Full Cleanup: Leftover Drivers

Removing the devices does not remove their driver packages from the DriverStore. For a complete cleanup:

1. Run this script to remove the ghost devices
2. Use [**Driver Store Explorer**](https://github.com/lostindark/DriverStoreExplorer) to delete the orphaned driver packages they left behind

## FAQ

### What are hidden (ghost) devices?

Registry entries for hardware that was connected at some point but is not present now. Device Manager hides them by default; *View ▸ Show hidden devices* reveals them as greyed-out entries. They serve no purpose once the hardware is gone.

### Is it safe to remove them?

The script only targets devices Windows reports as not present. Hardware that is connected and working is not in the list. Still, **pick only what you want gone**: removal is permanent, there is no undo file. A monitor you plug into another port, or switch off, shows up as a ghost too, and its entry holds per-monitor settings such as an EDID override or a color profile.

### What happens if I remove a device I still use sometimes?

Nothing dramatic — Windows re-detects it and reinstalls the driver the next time you plug it in. You may need to redo per-device settings (e.g. a manually assigned COM port number).

### Do I need to restart?

Usually not. If Windows needs a restart to finish removing a device, `pnputil` reports it and the script tells you to restart. It never restarts the computer on its own.

### How is this different from clicking through Device Manager manually?

Device Manager makes you right-click ▸ Uninstall each ghost entry one by one — painful with hundreds of them. This script removes the ones you pick in one pass, using the same underlying mechanism.

## Related

- [CPU Parking Disabler](https://github.com/vadyaravadim/cpu-parking-disabler) — disable CPU core parking on Windows 10/11, with the parked-core count shown before and after
- [MSI Mode Utility](https://github.com/vadyaravadim/msi-mode-utility) — enable MSI mode (Message Signaled Interrupts) for GPU, USB, network & audio devices
- [Interrupt Affinity Utility](https://github.com/vadyaravadim/interrupt-affinity-utility) — pin GPU, network, USB & audio interrupts to specific CPU cores (P/E-core aware)
- [Timer Resolution Utility](https://github.com/vadyaravadim/timer-resolution-utility) — set 0.5 ms timer resolution, disable dynamic tick, un-force HPET — with a built-in Sleep(1) benchmark
- [GameDVR & FSO Disabler](https://github.com/vadyaravadim/gamedvr-fso-disabler) — disable Game DVR / Xbox Game Bar capture and Fullscreen Optimizations on Windows 10/11

Same idea across the series: one transparent PowerShell script, no binaries, you see exactly what changes.

## Disclaimer

Device removal is permanent — there is no undo file. Review the device list carefully before clicking OK. Reconnecting the hardware makes Windows reinstall it. Use at your own risk.

## License

[MIT](LICENSE) — use at your own risk.

---

<div align="center">

If this cleaned up your Device Manager, consider giving it a ⭐

[Report Issues](https://github.com/vadyaravadim/remove-hidden-devices/issues)

</div>
