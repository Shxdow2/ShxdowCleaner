#Requires -RunAsAdministrator

# --- FIX ---
$appId = "Shxdow.Cleaner.V4"
$codeApp = @'
[DllImport("shell32.dll")]
public static extern int SetCurrentProcessExplicitAppUserModelID(string AppID);
'@
if (-not ([System.Management.Automation.PSTypeName]"Win32.WinAPIApp").Type) {
    Add-Type -MemberDefinition $codeApp -Name "WinAPIApp" -Namespace "Win32" -ErrorAction SilentlyContinue
}
[Win32.WinAPIApp]::SetCurrentProcessExplicitAppUserModelID($appId)

# --- PATCH ANTI-FLASH & ANSI COLORS ---
$Win32Code = @'
using System;
using System.Runtime.InteropServices;
public class WindowStealth {
    [DllImport("user32.dll")]
    public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);
    [DllImport("kernel32.dll")]
    public static extern bool GetConsoleMode(IntPtr hConsoleHandle, out uint lpMode);
    [DllImport("kernel32.dll")]
    public static extern bool SetConsoleMode(IntPtr hConsoleHandle, uint dwMode);
    [DllImport("kernel32.dll")]
    public static extern IntPtr GetStdHandle(int nStdHandle);
}
'@
if (-not ([System.Management.Automation.PSTypeName]"WindowStealth").Type) {
    Add-Type -TypeDefinition $Win32Code -ErrorAction SilentlyContinue
}

$hOut = [WindowStealth]::GetStdHandle(-11)
$mode = 0
if ([WindowStealth]::GetConsoleMode($hOut, [ref]$mode)) {
    [WindowStealth]::SetConsoleMode($hOut, $mode -bor 0x0004)
}

$proc = Get-Process -Id $pid
[WindowStealth]::ShowWindowAsync($proc.MainWindowHandle, 0)

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = "SilentlyContinue"

#region UI & COLORS
$ESC = [char]27
$C = "$ESC[1;36m"; $W = "$ESC[1;37m"; $G = "$ESC[1;32m"; $R = "$ESC[1;31m"
$Y = "$ESC[1;33m"; $DC = "$ESC[0;36m"; $RE = "$ESC[0m"
#endregion

#region CONFIG
$AppDataDir = Join-Path $env:APPDATA "ShxdowCleaner"
if (-not (Test-Path $AppDataDir)) { New-Item -ItemType Directory -Path $AppDataDir -Force | Out-Null }
$ConfigPath = Join-Path $AppDataDir "config.json"
$LogPath = Join-Path $env:TEMP "ShxdowCleaner.log"

if (Test-Path $ConfigPath) { 
    try { $Config = Get-Content $ConfigPath | ConvertFrom-Json } catch { $Config = $null } 
}

if ($null -eq $Config -or $null -eq $Config.language) {
    [WindowStealth]::ShowWindowAsync($proc.MainWindowHandle, 5)
    Clear-Host
    Write-Host "`n$C [1] Français  [2] English$RE"
    $langChoice = Read-Host " ► Language"
    $lang = if ($langChoice -eq "2") { "EN" } else { "FR" }
    $Config = [PSCustomObject]@{ language = $lang; backupDir = "C:\RegistryBackups"; enableLogging = $true }
    $Config | ConvertTo-Json | Set-Content $ConfigPath
} else {
    [WindowStealth]::ShowWindowAsync($proc.MainWindowHandle, 5)
}

$Msgs = @{
    FR = @{
        BannerTitle = " MODULES DE NETTOYAGE "; Menu1 = "Fichiers Temporaires & Système"; Menu2 = "Web & Apps (Browsers, Social)"; Menu3 = "Gaming (Steam, Epic, Riot)"; Menu4 = "Développement (Python, Node)"; Menu5 = "Optimisation (RAM, DNS, VBS)"; Menu6 = "Hardware (Intel, Surface)"; MenuO = "Lancer le nettoyage complet"; MenuQ = "Quitter"; Action = " Action "; Analyse = " Analyse : "; Exist = " [Inexistant]"; Empty = " [Déjà Vide]"; Partial = " [Accès Partiel]"; Ghost = " périphériques fantômes supprimés"; OptiDone = " Système optimisé"; Bilan = " BILAN : {0} récupérés"; Time = " Temps : "; ReportAsk = " Rapport Bureau ? (O/N)";
    }
    EN = @{
        BannerTitle = " CLEANUP MODULES "; Menu1 = "Temp Files & System"; Menu2 = "Web & Apps (Browsers, Social)"; Menu3 = "Gaming (Steam, Epic, Riot)"; Menu4 = "Development (Python, Node)"; Menu5 = "Optimization (RAM, DNS, VBS)"; Menu6 = "Hardware (Intel, Surface)"; MenuO = "Launch full cleanup"; MenuQ = "Exit"; Action = " Action "; Analyse = " Scanning : "; Exist = " [Missing]"; Empty = " [Already Empty]"; Partial = " [Partial Access]"; Ghost = " ghost devices removed"; OptiDone = " System optimized"; Bilan = " TOTAL: {0} recovered"; Time = " Time: "; ReportAsk = " Desktop Report? (Y/N)"
    }
}
$M = $Msgs[$Config.language]
#endregion

# --- DÉDUPLICATION ---
$script:_cleaned = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

# --- HELPERS ---
function Fmt([long]$b) { if ($b -ge 1GB) { return "{0:N2} GB" -f ($b / 1GB) }; if ($b -ge 1MB) { return "{0:N2} MB" -f ($b / 1MB) }; return "{0:N2} KB" -f ($b / 1KB) }
function Get-Size([string]$path) { if (Test-Path $path) { return (Get-ChildItem $path -Recurse -Force -EA SilentlyContinue | Measure-Object -Property Length -Sum).Sum }; return 0 }
function Get-MultiDrivePaths([string]$subPath) { $found = @(); $drives = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Free -gt 0 }; foreach ($d in $drives) { $full = Join-Path $d.Root $subPath; if (Test-Path $full) { $found += $full } }; return $found }
function Write-Section([string]$title) { $line = "═" * ($title.Length + 4); Write-Host "`n$DC ╔$line╗"; Write-Host " ║  $W$title$DC  ║"; Write-Host " ╚$line╝$RE`n" }

# --- LOG ---
function Write-Log([string]$level, [string]$msg) {
    if ($Config.enableLogging) {
        $line = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') | $($level.PadRight(7)) | $msg"
        Add-Content -Path $LogPath -Value $line -Encoding UTF8
    }
}

# --- WARNING UNIFIÉ ---
function Confirm-Action([string]$title, [string[]]$details) {
    Write-Host "`n  $Y[!] $title$RE"
    foreach ($d in $details) { Write-Host "  $Y    • $d$RE" }
    Write-Host "  $Y    Confirmer ? (O/N) : $RE" -NoNewline
    $ok = (Read-Host) -match "^[OoYy]$"
    Write-Log "WARN" "Confirmation demandée : $title | Réponse : $(if ($ok) { 'OUI' } else { 'NON' })"
    return $ok
}

function Clean-Target([string]$path, [string]$label) {
    Write-Host "  $W>$($M.Analyse)$C$label$RE" -NoNewline
    if (-not (Test-Path $path)) { Write-Host " $($R)$($M.Exist)$RE"; Write-Log "SKIP" "$label | Inexistant | $path"; return 0 }
    $before = Get-Size $path
    try {
        Get-ChildItem $path -Recurse -Force -EA SilentlyContinue | Remove-Item -Recurse -Force -EA SilentlyContinue
        $freed = $before - (Get-Size $path)
        if ($freed -gt 1024) {
            Write-Host " $G[+$(Fmt $freed)]$RE"
            Write-Log "CLEAN" "$label | $(Fmt $freed) | $path"
            return $freed
        } else {
            Write-Host " $DC$($M.Empty)$RE"
            Write-Log "EMPTY" "$label | Déjà vide | $path"
            return 0
        }
    } catch {
        Write-Host " $Y$($M.Partial)$RE"
        Write-Log "WARN" "$label | Accès partiel | $path"
        return 0
    }
}

function Force-Delete ($Path, $Label) {
    if (Test-Path $Path) {
        Get-ChildItem -Path $Path -Recurse -Force -EA SilentlyContinue | ForEach-Object { $_.Attributes = 'Normal' }
        return Clean-Target $Path $Label
    }
    return 0
}

# --- CLEAN-ONCE (déduplication) ---
function Clean-Once([string]$path, [string]$label) {
    if ($script:_cleaned.Contains($path)) {
        Write-Log "SKIP" "$label | Déjà nettoyé cette session | $path"
        return 0
    }
    $script:_cleaned.Add($path) | Out-Null
    return Force-Delete $path $label
}

#region MODULES
function Invoke-TempModule {
    Write-Section "FILESYSTEM & SYSTEM"
    Write-Log "INFO" "=== MODULE 1 : FILESYSTEM & SYSTEM ==="
    $t = 0

    $ProcsToKill = @("EpicGamesLauncher", "CrashReportClient", "cleanmgr")
    foreach ($p in $ProcsToKill) { Stop-Process -Name $p -Force -EA SilentlyContinue }

    $sageset = 7331
    $regBase = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches"
    $cats = @(
        "Active Setup Temp Folders", "BranchCache", "Content Indexer Cleaner",
        "D3D Shader Cache", "Delivery Optimization Files", "Device Driver Packages",
        "Downloaded Program Files", "Internet Cache Files", "Memory Dump Files",
        "Old ChkDsk Files", "Previous Installations", "Recycle Bin",
        "Setup Log Files", "System error memory dump files", "System error minidump files",
        "Temporary Files", "Temporary Setup Files", "Update Cleanup",
        "Windows Defender", "Windows Error Reporting Archive Files",
        "Windows Error Reporting Queue Files", "Windows ESD installation files",
        "Windows Upgrade Log Files"
    )
    foreach ($c in $cats) {
        $k = Join-Path $regBase $c
        if (Test-Path $k) { Set-ItemProperty -Path $k -Name "StateFlags$sageset" -Value 2 -Type DWord -EA SilentlyContinue }
    }
    Start-Process "cleanmgr.exe" -ArgumentList "/sagerun:$sageset" -Wait -WindowStyle Hidden

    $t += Force-Delete $env:TEMP "User Temp"
    $t += Force-Delete "$env:SystemRoot\Temp" "System Temp"
    $t += Force-Delete "$env:SystemRoot\Prefetch" "Prefetch"
    $t += Force-Delete "$env:LOCALAPPDATA\Microsoft\Windows\Explorer" "Thumbnails"
    $t += Force-Delete "$env:APPDATA\Microsoft\Windows\Recent" "Recent Items"
    $t += Force-Delete "$env:LOCALAPPDATA\Microsoft\Windows\INetCache" "Edge/IE Legacy Cache"
    $t += Force-Delete "C:\ProgramData\Microsoft\Diagnosis\ETLLogs" "Telemetry Logs"
    $t += Clean-Once "$env:LOCALAPPDATA\CrashDumps" "Windows Crash Dumps"
    $t += Clean-Once "$env:LOCALAPPDATA\CrashReportClient\Saved\Logs" "Crash Report Logs"
    $t += Force-Delete "$env:LOCALAPPDATA\EpicGamesLauncher\Saved\webcache_4430" "Epic Web Cache"
    $t += Force-Delete "$env:LOCALAPPDATA\EpicGamesLauncher\Saved\Config\CrashReportClient" "Epic Crash Config"

    Stop-Service wuauserv, bits -Force -EA SilentlyContinue
    $t += Force-Delete "$env:SystemRoot\SoftwareDistribution\Download" "WinUpdate Cache"
    Start-Service wuauserv, bits -EA SilentlyContinue

    Write-Host "  $W>$($M.Analyse)$C Event Logs$RE" -NoNewline
    Get-WinEvent -ListLog * -EA SilentlyContinue | ForEach-Object {
        [System.Diagnostics.Eventing.Reader.EventLogSession]::GlobalSession.ClearLog($_.LogName)
    } 2>$null
    Write-Host " $G[VIDÉ]$RE"
    Write-Log "CLEAN" "Event Logs | Tous vidés"

    $t += Force-Delete "$env:SystemRoot\Logs\CBS" "CBS Windows Logs"
    $t += Force-Delete "$env:ProgramData\Microsoft\Windows\WER" "Windows Reports (WER)"

    Write-Host "  $W>$($M.Analyse)$C Setup & Panther Logs$RE" -NoNewline
    Get-ChildItem -Path "C:\Windows\Logs\*", "C:\Windows\Panther\*" -Recurse -Filter "*.log" -EA SilentlyContinue | Remove-Item -Force -EA SilentlyContinue
    Write-Host " $G[OK]$RE"
    Write-Log "CLEAN" "Setup & Panther Logs"

    Clear-RecycleBin -Force -EA SilentlyContinue
    Write-Log "CLEAN" "Corbeille vidée"

    $bakTotal = 0
    Get-ChildItem "$env:USERPROFILE\Documents","$env:LOCALAPPDATA" -Recurse -Include "*.bak","*.old" -Force -EA SilentlyContinue |
        Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-90) } | ForEach-Object {
            $bakTotal += $_.Length
            $_.Attributes = 'Normal'
            Remove-Item $_.FullName -Force -EA SilentlyContinue
        }
    Write-Host "  $W> Old Backup Files (.bak/.old):$G [+$(Fmt $bakTotal)]$RE"
    Write-Log "CLEAN" "Old .bak/.old | $(Fmt $bakTotal)"

    Write-Log "INFO" "MODULE 1 TERMINÉ | Total : $(Fmt ($t + $bakTotal))"
    return $t + $bakTotal
}

function Invoke-WebModule {
    Write-Section "WEB & APPS"
    Write-Log "INFO" "=== MODULE 2 : WEB & APPS ==="
    $t = 0
    $targets = @(
        @{p="$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache"; l="Chrome Cache"},
        @{p="$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache"; l="Edge Cache"},
        @{p="$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data\Default\Cache"; l="Brave Cache"},
        @{p="$env:LOCALAPPDATA\Opera Software\Opera GX Stable\Cache"; l="Opera GX Cache"},
        @{p="$env:APPDATA\discord\Cache"; l="Discord Cache"},
        @{p="$env:LOCALAPPDATA\Spotify\Storage"; l="Spotify Cache"},
        @{p="$env:LOCALAPPDATA\Microsoft\Teams\Cache"; l="Teams Cache"},
        @{p="$env:LOCALAPPDATA\Microsoft\Office\16.0\OfficeFileCache"; l="Office Cache"}
    )
    foreach ($tg in $targets) { $t += Clean-Target $tg.p $tg.l }
    $ffBase = "$env:APPDATA\Mozilla\Firefox\Profiles"
    if (Test-Path $ffBase) { Get-ChildItem $ffBase -Directory | ForEach-Object { $t += Clean-Target (Join-Path $_.FullName "cache2") "Firefox Cache" } }
    Write-Log "INFO" "MODULE 2 TERMINÉ | Total : $(Fmt $t)"
    return $t
}

function Invoke-GamingModule {
    Write-Section "GAMING BOOST"
    Write-Log "INFO" "=== MODULE 3 : GAMING ==="
    $t = 0
    $steamPaths = Get-MultiDrivePaths "SteamLibrary\steamapps\shadercache"
    foreach ($p in $steamPaths) { $t += Clean-Target $p "Steam Shaders ($($p.Substring(0,2)))" }
    $t += Clean-Target "$env:LOCALAPPDATA\Steam\htmlcache" "Steam Web"
    Write-Host "  $W> Cleaning Game Launchers & Crash Data...$RE"
    $t += Force-Delete "$env:LOCALAPPDATA\Riot Games\Riot Client\Data\Cache" "Riot Client Cache"
    $t += Force-Delete "$env:LOCALAPPDATA\Riot Games\Installers" "Riot Installers"
    $t += Force-Delete "$env:LOCALAPPDATA\FortniteGame\Saved\ShaderCache" "Fortnite Shaders"
    $t += Force-Delete "$env:LOCALAPPDATA\FortniteGame\Saved\Logs" "Fortnite Logs"
    $t += Force-Delete "$env:LOCALAPPDATA\VALORANT\Saved\Logs" "Valorant Logs"
    $t += Clean-Once "$env:LOCALAPPDATA\CrashDumps" "Windows Crash Dumps"
    $t += Clean-Once "$env:LOCALAPPDATA\CrashReportClient\Saved\Logs" "Crash Report Logs"
    $t += Force-Delete "$env:ProgramData\Epic\EpicGamesLauncher\Data\EasyAntiCheat" "EAC Temp"
    foreach ($e in @("webcache","webcache_4147","webcache_4430","Logs","Crashes","HttpRequestCache","Config\CrashReportClient")) {
        $t += Force-Delete "$env:LOCALAPPDATA\EpicGamesLauncher\Saved\$e" "Epic $e"
    }
    Write-Log "INFO" "MODULE 3 TERMINÉ | Total : $(Fmt $t)"
    return $t
}

function Invoke-DevModule {
    Write-Section "DEVELOPER TOOLS"
    Write-Log "INFO" "=== MODULE 4 : DEVELOPER TOOLS ==="
    $t = 0
    $t += Clean-Target "$env:APPDATA\npm-cache" "NPM Cache"
    $t += Clean-Target "$env:LOCALAPPDATA\pip\cache" "Pip Cache"
    $t += Clean-Target "$env:LOCALAPPDATA\NuGet\Cache" "NuGet Cache"
    Get-ChildItem "$env:USERPROFILE" -Recurse -Directory -Filter "__pycache__" -EA SilentlyContinue | ForEach-Object { $t += Clean-Target $_.FullName "Python pycache" }
    Write-Log "INFO" "MODULE 4 TERMINÉ | Total : $(Fmt $t)"
    return $t
}

function Invoke-OptiModule {
    Write-Section "PERFORMANCE TWEAKS"
    Write-Log "INFO" "=== MODULE 5 : PERFORMANCE TWEAKS ==="

    $confirmed = Confirm-Action "Ce module va modifier des paramètres système sensibles" @(
        "Désactivation GameDVR (capture désactivée)"
        "Désactivation Telemetry (DiagTrack, dmwappushservice)"
        "Désactivation VBS/HVCI = sécurité réduite (Credential Guard off)"
        "Applications arrière-plan désactivées"
    )
    if (-not $confirmed) { Write-Log "WARN" "Module 5 annulé par l'utilisateur"; return }

    $bDir = $Config.backupDir
    if (!(Test-Path $bDir)) { New-Item $bDir -ItemType Directory | Out-Null }

    $keysToBackup = @(
        "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection",
        "HKCU\Software\Microsoft\Windows\CurrentVersion\GameDVR",
        "HKCU\System\GameConfigStore",
        "HKLM\System\CurrentControlSet\Control\DeviceGuard"
    )
    foreach ($k in $keysToBackup) {
        $safe = $k -replace "[\\:]","_"
        $regFile = Join-Path $bDir "$safe`_$(Get-Date -Format 'HHmm').reg"
        reg export $k $regFile /y 2>$null
        Write-Log "INFO" "Backup registre : $k → $regFile"
    }

    ipconfig /flushdns | Out-Null
    Write-Log "INFO" "DNS cache vidé"
    netsh interface ip delete arpcache | Out-Null
    Write-Log "INFO" "ARP cache vidé"

    if (-not ([System.Management.Automation.PSTypeName]"Shxdow").Type) {
        $code = 'using System;using System.Runtime.InteropServices;public class Shxdow{[DllImport("psapi.dll")]public static extern bool EmptyWorkingSet(IntPtr h);}'
        Add-Type $code -EA SilentlyContinue
    }
    Get-Process | ForEach-Object { try { [Shxdow]::EmptyWorkingSet($_.Handle) } catch {} } 2>$null
    Write-Log "INFO" "RAM working sets vidés"

    foreach ($s in @("DiagTrack","dmwappushservice")) {
        Stop-Service $s -Force -EA SilentlyContinue
        Set-Service $s -StartupType Disabled -EA SilentlyContinue
        Write-Log "INFO" "Service désactivé : $s"
    }

    $regKeys = @(
        @{Path="HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection"; Name="AllowTelemetry"; Value=0},
        @{Path="HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR"; Name="AppCaptureEnabled"; Value=0},
        @{Path="HKCU:\System\GameConfigStore"; Name="GameDVR_Enabled"; Value=0},
        @{Path="HKLM:\System\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity"; Name="Enabled"; Value=0},
        @{Path="HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard"; Name="EnableVirtualizationBasedSecurity"; Value=0},
        @{Path="HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications"; Name="GlobalUserDisabled"; Value=1}
    )
    foreach ($key in $regKeys) {
        if (!(Test-Path $key.Path)) { New-Item $key.Path -Force | Out-Null }
        Set-ItemProperty -Path $key.Path -Name $key.Name -Value $key.Value -Type DWord -EA SilentlyContinue
        Write-Log "INFO" "Registre modifié : $($key.Path) | $($key.Name) = $($key.Value)"
    }

    Optimize-Volume -DriveLetter C -ReTrim -EA SilentlyContinue
    Write-Log "INFO" "Optimize-Volume C: ReTrim exécuté"
    Write-Host "  $G[✔] $($M.OptiDone)$RE"
    Write-Log "INFO" "MODULE 5 TERMINÉ"
}

function Invoke-HardwareModule {
    Write-Section "HARDWARE & EXTREME CLEAN"
    Write-Log "INFO" "=== MODULE 6 : HARDWARE ==="
    $t = 0

    # 1. Intel (Logs uniquement)
    $t += Clean-Target "C:\Intel\Logs" "Intel Driver Logs"

    # 2. NVIDIA - Téléchargements & Installeurs temporaires
    $t += Clean-Target "C:\NVIDIA\DisplayDriver" "NVIDIA Extracted Drivers"
    $t += Clean-Target "C:\ProgramData\NVIDIA Corporation\NetService" "NVIDIA Driver Install Cache"
    $t += Clean-Target "$env:LOCALAPPDATA\NVIDIA Corporation\GeForce Experience\Console" "NVIDIA GFE Logs"

    # 3. Diagnostic & Surface
    $t += Clean-Target "$env:ProgramData\Microsoft\Surface" "Surface Diagnostic"

    # 4. Purge officielle Microsoft des anciens pilotes inutilisés (Sécurisé)
    Write-Host "  $W>$($M.Analyse)$C DriverStore Cleanup$RE" -NoNewline
    pnputil /cleanup-drivers | Out-Null
    Write-Host " $G[OK]$RE"
    Write-Log "CLEAN" "DriverStore cleanup exécuté"

    # 5. Nettoyage des périphériques fantômes déconnectés
    $dcPath = "$env:TEMP\DeviceCleanupCmd.exe"
    if (-not (Test-Path $dcPath)) {
        try {
            $url = "https://www.uwe-sieber.de/files/devicecleanupcmd.zip"
            $zip = "$env:TEMP\dc.zip"
            $dir = "$env:TEMP\shxdow_check"
            Write-Log "INFO" "Téléchargement DeviceCleanupCmd depuis $url"
            Invoke-WebRequest -Uri $url -OutFile $zip -ErrorAction Stop

            $expectedHash = "D4ADDF00C28D7CD58FC2D0559678CB282E8BFB45F0D4464A5E3E839022AA2631"
            $actualHash = (Get-FileHash $zip -Algorithm SHA256).Hash
            if ($actualHash -ne $expectedHash) {
                Write-Host "  $R[!] Hash invalide - fichier corrompu ou modifié$RE"
                Write-Log "ERROR" "Hash invalide | Attendu : $expectedHash | Reçu : $actualHash"
                Remove-Item $zip -Force -EA SilentlyContinue
                return $t
            }
            Write-Log "INFO" "Hash SHA256 vérifié OK"

            Unblock-File -Path $zip
            Expand-Archive -Path $zip -DestinationPath $dir -Force
            $exe = Get-ChildItem -Path $dir -Filter "DeviceCleanupCmd.exe" -Recurse | Where-Object { $_.FullName -match "x64" } | Select-Object -First 1
            if ($exe) { Move-Item $exe.FullName $dcPath -Force }
            Remove-Item $zip, $dir -Recurse -Force -EA SilentlyContinue
        } catch {
            Write-Log "ERROR" "Échec téléchargement DeviceCleanupCmd : $_"
        }
    }

    if (Test-Path $dcPath) {
        Write-Host "  $W>$($M.Analyse)$C Ghost Devices$RE" -NoNewline
        Start-Process $dcPath -ArgumentList "-v * -s" -Wait -WindowStyle Hidden
        Write-Host " $G[NETTOYÉ]$RE"
        Write-Log "CLEAN" "Ghost devices supprimés"
    }

    Write-Log "INFO" "MODULE 6 TERMINÉ | Total : $(Fmt $t)"
    return $t
}

#region MAIN LOOP
Write-Log "INFO" "=============================="
Write-Log "INFO" "SESSION DÉMARRÉE | Utilisateur : $env:USERNAME | Machine : $env:COMPUTERNAME"
Write-Log "INFO" "=============================="

while ($true) {
    Clear-Host
    Write-Host "$C
 ██████╗ ██╗  ██╗██╗  ██╗██████╗  ██████╗ ██╗    ██╗     ██████╗██╗     ███████╗ █████╗ ███╗   ██╗███████╗██████╗ 
██╔════╝ ██║  ██║╚██╗██╔╝██╔══██╗██╔═══██╗██║    ██║    ██╔════╝██║     ██╔════╝██╔══██╗████╗  ██║██╔════╝██╔══██╗
███████╗ ███████║ ╚███╔╝ ██║  ██║██║   ██║██║ █╗ ██║    ██║     ██║     █████╗  ███████║██╔██╗ ██║█████╗  ██████╔╝
╚════██║ ██╔══██║ ██╔██╗ ██║  ██║██║   ██║██║███╗██║    ██║     ██║     ██╔══╝  ██╔══██║██║╚██╗██║██╔══╝  ██╔══██╗
██████╔╝ ██║  ██║██╔╝ ██╗██████╔╝╚██████╔╝╚███╔███╔╝    ╚██████╗███████╗███████╗██║  ██║██║ ╚████║███████╗██║  ██║
╚═════╝  ╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝  ╚═════╝  ╚══╝╚══╝      ╚═════╝╚══════╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝
$RE$Y                                                by Shxdow  $RE$DC v3.4$RE"

    Write-Host "`n$DC╔══════════════════════════════════════════════════╗"
    Write-Host "$DC║            $C$($M.BannerTitle)$RE$DC                ║"
    Write-Host "$DC╠══════════════════════════════════════════════════╣$RE"
    Write-Host "  $W[1]$RE   $C$($M.Menu1)$RE"
    Write-Host "  $W[2]$RE   $C$($M.Menu2)$RE"
    Write-Host "  $W[3]$RE   $C$($M.Menu3)$RE"
    Write-Host "  $W[4]$RE   $C$($M.Menu4)$RE"
    Write-Host "  $W[5]$RE   $C$($M.Menu5)$RE"
    Write-Host "  $W[6]$RE   $C$($M.Menu6)$RE"
    Write-Host "$DC╠══════════════════════════════════════════════════╣$RE"
    Write-Host "  $W[O]$RE   $C$($M.MenuO)$RE"
    Write-Host "  $W[0]$RE   $C$($M.MenuQ)$RE"
    Write-Host "$DC╚══════════════════════════════════════════════════╝$RE"

    Write-Host "`n$C  ►$RE $W$($M.Action)$RE $DC>$RE " -NoNewline
    $choice = (Read-Host).ToUpper()
    if ($choice -eq "0") { break }

    $canProcess = $true
    if ($choice -match "^[1-6]$") {
        Write-Host "`n  $Y[!] Confirmer le module $choice ? (O/N) : $RE" -NoNewline
        if ((Read-Host) -notmatch "^[OoYy]$") { $canProcess = $false }
    }

    if ($canProcess) {
        $script:_cleaned.Clear()
        $start = Get-Date
        $totalFreed = 0
        Write-Log "INFO" "Choix utilisateur : $choice"

        if ($choice -eq "1" -or $choice -eq "O") { $totalFreed += Invoke-TempModule }
        if ($choice -eq "2" -or $choice -eq "O") { $totalFreed += Invoke-WebModule }
        if ($choice -eq "3" -or $choice -eq "O") { $totalFreed += Invoke-GamingModule }
        if ($choice -eq "4" -or $choice -eq "O") { $totalFreed += Invoke-DevModule }
        if ($choice -eq "5" -or $choice -eq "O") { Invoke-OptiModule }
        if ($choice -eq "6" -or $choice -eq "O") { $totalFreed += Invoke-HardwareModule }

        $duration = "$((Get-Date) - $start | ForEach-Object { "$($_.Seconds)s" })"
        $TailleRecup = Fmt $totalFreed

        Write-Section "BILAN"
        Write-Host "  $G $($M.Bilan -f $TailleRecup) $RE"
        Write-Host "  $W Temps : $duration $RE"
        Write-Log "INFO" "=============================="
        Write-Log "INFO" "SESSION | Total récupéré : $TailleRecup | Durée : $duration"
        Write-Log "INFO" "=============================="

        Write-Host "`n  $Y Rapport Bureau ? (O/N) : $RE" -NoNewline
        $rep = Read-Host
        if ($rep -match "[OoYy]") {
            $rpath = [System.IO.Path]::Combine([Environment]::GetFolderPath("Desktop"), "Rapport_$(Get-Date -Format 'yyyyMMdd_HHmm').txt")
            @"
SHXDOW CLEANER - RAPPORT
========================
Date    : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Machine : $env:COMPUTERNAME
User    : $env:USERNAME
Modules : $choice
Gain    : $TailleRecup
Durée   : $duration
Log     : $LogPath
"@ | Out-File $rpath -Encoding UTF8
            Write-Host "  $G [OK] Rapport créé : $rpath$RE"
            Write-Log "INFO" "Rapport bureau créé : $rpath"
        }
    }

    Write-Host "`n  Appuyez sur Entree pour continuer..."
    Read-Host | Out-Null
}

Write-Log "INFO" "SESSION TERMINÉE"
#endregion
