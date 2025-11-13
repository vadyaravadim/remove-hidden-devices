# 🔧 Remove Unknown Devices

PowerShell script to remove all devices with 'Unknown' status from Windows Device Manager.

## 📋 Requirements

- Windows 10/11
- PowerShell 5.1+
- Administrator privileges

## 🚀 Usage

1. Download [Remove-UnknownDevices.ps1](Remove-UnknownDevices.ps1)
2. Right-click PowerShell/Terminal → **Run as Administrator**
3. Navigate to script directory and run:
```powershell
.\remove-hidden-devices.ps1
```

The script will:
- Scan for unknown devices
- Display the list for confirmation
- Remove devices after confirmation
- Offer system restart

## 💡 Recommended Tool

For complete cleanup, use with [**Driver Store Explorer**](https://github.com/lostindark/DriverStoreExplorer):

1. Run this script to remove unknown devices
2. Use Driver Store Explorer to delete leftover drivers from DriverStore

This combination ensures full removal of both devices and their drivers.

## ⚠️ Warning

This script permanently removes devices. Review the device list carefully before confirming removal.

## 📸 Example Output
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

Removing devices...

===================================
REMOVE UNKNOWN DEVICES COMPLETED
===================================

For full registry changes to take effect,
a system restart is recommended.

Restart computer now? (y/n):
```

## 📝 License

MIT License - feel free to use and modify.

---

**Version 1.0** | [Report Issues](https://github.com/vadyaravadim/remove-hidden-devices/issues)

⭐ If this script helped you, consider giving it a star!
