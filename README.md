# ⚡ Shxdow Cleanup — v3.3.1

<div align="center">

[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%20%7C%207+-blue.svg?style=flat&logo=powershell&logoColor=white)](https://microsoft.com/powershell)
[![Windows](https://img.shields.io/badge/Windows-10%20%7C%2011-0078D6.svg?style=flat&logo=windows&logoColor=white)](https://www.microsoft.com/windows)
[![.NET](https://img.shields.io/badge/.NET-Required-512BD4.svg?style=flat&logo=dotnet&logoColor=white)](https://dotnet.microsoft.com/download)
[![Admin](https://img.shields.io/badge/Run%20As-Administrator-red.svg?style=flat&logo=shield&logoColor=white)]()
[![Lang](https://img.shields.io/badge/Language-FR%20%7C%20EN-brightgreen.svg?style=flat)]()

**A powerful, modular Windows cleanup & optimization tool built in PowerShell.**  
*Deep clean. Real gains. Zero bloat.*

</div>

---

## 🖥️ System Requirements

| Component | Requirement |
|-----------|-------------|
| OS | Windows 10 / 11 (Build 10240+) |
| Shell | PowerShell 5.1 or higher |
| Runtime | .NET (for RAM Flush & system APIs) |
| Privileges | Administrator required |

---

## ✨ Features

### 🌍 Multilanguage
Full **French** and **English** support. Language is selected on first launch and saved automatically in `config.json`.

### 🧹 Deep Cleaning Modules
| Module | What it cleans |
|--------|---------------|
| **Temp** | User/System Temp, Prefetch, Thumbnails, Telemetry |
| **Web** | Chrome, Edge, Brave, Opera GX, Discord, Spotify, Teams |
| **Gaming** | Steam, Riot, Valorant, Fortnite, Epic Games, EAC |
| **System** | Windows Update cache, Event Logs, WER Reports, Recycle Bin |
| **Hardware** | Intel/Surface logs, GPU shader cache, Ghost PnP devices |

### ⚡ Performance Tweaks
- **RAM Flush** via native C# `EmptyWorkingSet` API
- **VBS / HVCI disabled** for maximum FPS
- **GameDVR off**, background apps disabled
- **Telemetry services** stopped and disabled
- **DNS & ARP cache** flushed
- **SSD ReTrim** via `Optimize-Volume`

### 🛡️ Safety & Reliability
- Automatic **Windows version check** (Win10+ enforced)
- **Registry backup** created before any tweak
- **Corrupted config** auto-detected, renamed to `.bak` and recreated
- Real-time **action logging** to `ShxdowCleaner.log`
- **Real disk gain** measured before/after (not estimated)

---

## 📥 Installation

1. Go to the [**Releases**](https://github.com/Shxdow2/Shxdow-Cleanup/releases) page
2. Download **`Cleanup-Shxdow.7z`**
3. Extract the archive anywhere on your machine
4. Right-click **`Shxdow-Cleanup-Launcher.bat`** → **Run as Administrator**

> [!IMPORTANT]
> The script **requires Administrator privileges** to access system paths, modify registry keys, and interact with hardware. Without elevation, most modules will silently fail.

> [!NOTE]
> On first launch, you will be asked to select your language (FR/EN). This choice is saved and won't be asked again unless `config.json` is deleted or corrupted.

---

## 📁 File Structure

```
Shxdow-Cleanup/
├── Shxdow-Cleanup-Launcher.bat   ← Entry point (run this)
├── ShxdowCleanup.ps1             ← Main script
├── config.json                   ← Auto-generated on first run
└── CHANGELOG.md
```

---

## 📊 Changelog

### [v3.3.1] — 2026-04-03
- ✅ Added full **FR/EN internationalization** with persistent language config
- ✅ New **Hardware module** (Intel, Surface, Ghost PnP devices)
- ✅ **Windows version guard** — blocks execution on unsupported OS
- ✅ **Detailed report** on Desktop with per-module breakdown
- ✅ **Robust config handling** — auto-backup and recreate if corrupted
- ✅ Added **Brave** and **Opera GX** browser cache cleaning
- 🔧 Fixed switch regex collisions (`^O$`, `^1$`...)
- 🔧 Report now accepts both `Y` and `O` inputs

### [v3.3.0] — 2026-04-02
- ✅ Full fusion of v3.1 and v3.2.2 commands
- ✅ VBS / HVCI deep disable for FPS boost
- ✅ SSD ReTrim command added
- 🔧 Try/Catch error handling
- 🔧 Log persistence fix

---

## ⚠️ Disclaimer

This tool modifies **system services, registry keys, and hardware settings**.  
A registry backup is automatically created before any optimization is applied.  
Use at your own risk. Always review the script before running it.

---

<div align="center">

*Crafted by **Shxdow** · 2026 · Built for performance, designed for control*

**#ShxdowCleanup · #PowerShell · #Windows10 · #Windows11 · #Gaming · #Optimization**

</div>
