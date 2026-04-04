# ⚡ Shxdow Cleanup — v3.3.1

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
| 2 | **Web** | Chrome, Edge, Brave, Opera GX, Discord, Spotify, Teams, Office |
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

1. Go to the [**Releases**](https://github.com/Shxdow2/Shxdow-Cleanup/releases) page
2. Download **`Cleanup-Shxdow.7z`**
3. Extract the archive anywhere on your machine
4. Right-click **`Shxdow-Cleanup-Launcher.bat`** → **Run as Administrator**

> [!IMPORTANT]
> Administrator privileges are **strictly required**. Without elevation, system paths, registry keys, and hardware-level commands will silently fail or be skipped.

> [!NOTE]
> On first launch, you will be prompted to choose your language (FR/EN). This is saved in `config.json` next to the script and won't be asked again.

---

## 📁 File Structure

```
Shxdow-Cleanup/
├── Shxdow-Cleanup-Launcher.bat   ← Entry point (run this as Admin)
├── ShxdowCleanup.ps1             ← Main script
├── config.json                   ← Auto-generated on first run
└── CHANGELOG.md
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
        "hardware": true
    }
}
```

Set `"language"` to `"EN"` for English. Set any module to `false` to skip it entirely.

---

## 📊 Changelog

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
