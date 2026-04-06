# ⚡ ShxdowCleaner — v3.4

<div align="center">

![Microsoft](https://img.shields.io/badge/Microsoft-Certified%20Logic-0078D4?style=for-the-badge&logo=microsoft)
![PowerShell](https://img.shields.io/badge/PowerShell-Core%20%7C%207.4-blue?style=for-the-badge&logo=powershell)
![Windows](https://img.shields.io/badge/Windows-Server%20%26%20Desktop-0078D4?style=for-the-badge&logo=windows)
![GitHub](https://img.shields.io/badge/Open--Source-MIT%20License-lightgrey?style=for-the-badge&logo=github)
![Azure](https://img.shields.io/badge/Cloud-Azure%20Hybrid%20Ready-0089D6?style=for-the-badge&logo=microsoftazure)
![Security](https://img.shields.io/badge/Security-AMSI%20Compliant-red?style=for-the-badge&logo=checkmarx)
![Optimization](https://img.shields.io/badge/Performance-Kernel%20Flush-FFB900?style=for-the-badge&logo=speedtest)
![Status](https://img.shields.io/badge/Update-April%202026-brightgreen?style=for-the-badge)


</div>

---

## 🖥️ System Requirements

| Component | Requirement |
|-----------|-------------|
| OS | Windows 10 / 11 |
| Shell | PowerShell 5.1 or higher |
| Runtime | .NET (for RAM Flush & system APIs) |
| Privileges | Administrator required |

---

## ✨ Features

### 🌍 Multilanguage
Full **French** and **English** support. Language is selected on first launch and saved automatically in `config.json`. Won't be asked again unless the file is deleted.

### 🧹 Cleaning Modules

| # | Module | What it cleans |
|---|--------|----------------|
| 1 | **Temp** | User/System Temp, Prefetch, Thumbnails, Recent Items, Telemetry Logs |
| 2 | **Web** | Chrome, Edge, Brave, FireFox, Opera GX, Discord, Spotify, Teams, Office |
| 3 | **Gaming** | Steam, Riot Client, Valorant, Fortnite, Epic Games, EAC |
| 4 | **System** | Windows Update cache, Event Logs, CBS Logs, WER Reports, Recycle Bin |
| 5 | **Optimisation** | RAM, DNS, ARP, VBS, Telemetry
| 6 | **Hardware** | Intel Driver Logs, Surface Diagnostics, Intel GPU Cache, Ghost PnP Devices |

### ⚡ Performance Tweaks — `[5] Opti`
- **RAM Flush** via native C# `EmptyWorkingSet` API
- **VBS / HVCI disabled** — registry tweak for maximum FPS
- **GameDVR disabled** — stops background game capture
- **Background apps disabled** globally
- **Telemetry services stopped** (`DiagTrack`, `dmwappushservice`) and set to disabled
- **DNS & ARP cache** flushed (`ipconfig /flushdns`, `netsh`)
- **SSD ReTrim** via `Optimize-Volume -ReTrim`
- **Registry backup** exported to `C:\RegistryBackups\` before any change

### 🛡️ Safety & Reliability
- Real-time **action logging** with timestamps → `%TEMP%\ShxdowCleaner.log`
- **Real disk gain** calculated from actual drive free space (before/after), not estimated
- Execution time displayed after each run
- Optional **Desktop report** (`Shxdow_Report.txt`) with total gain and date
- Optional **system restart** prompt after cleanup

---

## 📥 Installation

1. Go to the [**Releases**](https://github.com/Shxdow2/Shxdow-Cleanup/releases) page.
2. Download **`ShxdowCleaner.exe`**.
3. Right-click **`ShxdowCleaner.exe`** → **Run as Administrator**.

> [!IMPORTANT]
> Administrator privileges are mandatory. System-level optimizations, registry modifications, and hardware cleaning will be skipped if the tool is not elevated.

---

## 📁 File Structure

```
Shxdow-Cleanup/
├── Shxdow-Cleanup.exe     ← Standalone App (Run as Admin)
├── config.json            ← Auto-generated preferences
└── CHANGELOG.md           ← History of evolutions
```

> `config.json` stores your language preference, backup directory path, logging toggle, and enabled modules. You can edit it manually if needed.

---

## ⚙️ config.json

```json
{
    "language": "FR",
    "backupDir": "C:\\RegistryBackups",
    "enableLogging": true,
    "modules": {
        "gaming": true,
        "web": true,
        "hardware": true,
        "opti": true
    }
}

```

Set `"language"` to `"EN"` for English. Set any module to `false` to skip it entirely.

---

## 📊 Changelog

### [v3.4] — 2026-04-05 — (The Final Evolution)
- 🚀 Native Binary: Migrated from script to Standalone Executable (.exe).

- 🎨 UI Overhaul: New High-Definition 256x256 icon and branding.

- 🥷 Stealth Mode: Console window is now completely hidden.

- ✅ Full FR/EN i18n: Multi-language engine with dynamic config saving.

- ✅ Hardware Module: Added Intel/Surface logs and Ghost PnP removal.

- ✅ Opti+: Integrated VBS/HVCI deep disable for gaming performance.

### [v3.3.1] — 2026-04-03
- ✅ Full **FR/EN internationalization** — language selected at first launch, persisted in config
- ✅ Translation dictionary `$Msgs` with dynamic `$M` loader
- ✅ Added **Brave** and **Opera GX** to web cleaning module
- ✅ New **Hardware module** — Intel/Surface logs, GPU cache, Ghost PnP device removal
- ✅ **SSD ReTrim** via `Optimize-Volume`
- ✅ **RAM Flush** via native C# `EmptyWorkingSet`
- ✅ **VBS / HVCI** deep disable via registry

### [v3.3] — 2026-04-02
- ✅ Full fusion of v3.1 and v3.2.2 commands
- 🔧 Try/Catch error handling across all modules
- 🔧 Log persistence fixed

---

## ⚠️ Disclaimer

This tool modifies **system services, registry keys, and hardware settings**.  
A registry backup is automatically exported to `C:\RegistryBackups\` before any optimization is applied.  

---

<div align="center">

*Crafted by **Shxdow** · 2026 · Built for performance, designed for control*

**#ShxdowCleanup · #PowerShell · #Windows10 · #Windows11 · #Gaming · #Optimization**

</div>
