#Requires -RunAsAdministrator
<#
  SHXDOW CLEANUP v3.3.1
  Build: 2026-04-04 | Author: Shxdow
  FULL PATCH: v1 (System/Registry) + v2 (Dev/Cleanmgr) + Gaming Extended
#>

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = "SilentlyContinue"

#region UI & COLORS
$C = [char]27 + "[1;36m"; $W = [char]27 + "[1;37m"; $G = [char]27 + "[1;32m"; $R = [char]27 + "[1;31m"
$Y = [char]27 + "[1;33m"; $DC = [char]27 + "[0;36m"; $RE = [char]27 + "[0m"
#endregion

#region CONFIG & LANGUAGE ENGINE
$ConfigPath = Join-Path $PSScriptRoot "config.json"
$LogPath = "$env:TEMP\ShxdowCleaner.log"

if (Test-Path $ConfigPath) { 
    try { $Config = Get-Content $ConfigPath | ConvertFrom-Json } catch { $Config = $null } 
}

if ($null -eq $Config -or $null -eq $Config.language) {
    Clear-Host
    Write-Host "`n$C [1] Français  [2] English$RE"
    $langChoice = Read-Host " ► Language"
    $lang = if ($langChoice -eq "2") { "EN" } else { "FR" }
    
    $Config = [PSCustomObject]@{
        language = $lang
        backupDir = "C:\RegistryBackups"
        enableLogging = $true
        modules = @{ gaming = $true; web = $true; hardware = $true; dev = $true }
    }
    $Config | ConvertTo-Json | Set-Content $ConfigPath
}

$Msgs = @{
    FR = @{
        BannerTitle = " MODULES DE NETTOYAGE "
        Menu1 = "Fichiers Temporaires & Système"
        Menu2 = "Web & Apps — Browsers, Social, Office"
        Menu3 = "Gaming — Steam, Fortnite, Epic, Riot"
        Menu4 = "Développement — Python, Node.js"
        Menu5 = "Optimisation — RAM, DNS, Telemetry, VBS OFF"
        Menu6 = "Hardware — Surface & Intel Specific"
        MenuO = "Lancer le nettoyage complet"
        MenuQ = "Quitter"
        Action = " Action "; Analyse = " Analyse : "; Exist = " [Inexistant]"; Empty = " [Déjà Vide]"; Partial = " [Accès Partiel]"
        Ghost = " périphériques fantômes supprimés"; OptiDone = " Système optimisé (RAM, Services, Télémétrie, VBS OFF)"
        Bilan = " BILAN : {0} récupérés réellement"; Time = " Temps : "; ReportAsk = " Rapport Bureau ? (O/N)"
    }
    EN = @{
        BannerTitle = " CLEANUP MODULES "
        Menu1 = "Temp Files & System (Deep Purge)"
        Menu2 = "Web & Apps — Browsers, Social, Office"
        Menu3 = "Gaming — Steam, Fortnite, Epic, Riot"
        Menu4 = "Development — Python, Node.js, NuGet"
        Menu5 = "Optimization — RAM, DNS, Telemetry, VBS OFF"
        Menu6 = "Hardware — Surface & Intel Specific"
        MenuO = "Launch full cleanup"
        MenuQ = "Exit"
        Action = " Action "; Analyse = " Scanning : "; Exist = " [Missing]"; Empty = " [Already Empty]"; Partial = " [Partial Access]"
        Ghost = " ghost devices removed"; OptiDone = " System optimized (RAM, Services, Telemetry, VBS OFF)"
        Bilan = " TOTAL: {0} actually recovered"; Time = " Time: "; ReportAsk = " Desktop Report? (Y/N)"
    }
}
$M = $Msgs[$Config.language]
#endregion

#region HELPERS
function Fmt([long]$b) {
    if ($b -ge 1GB) { return "{0:N2} GB" -f ($b / 1GB) }
    if ($b -ge 1MB) { return "{0:N2} MB" -f ($b / 1MB) }
    return "{0:N2} KB" -f ($b / 1KB)
}

function Get-Size([string]$path) {
    if (Test-Path $path) {
        return (Get-ChildItem $path -Recurse -Force -EA SilentlyContinue | Measure-Object -Property Length -Sum).Sum
    }
    return 0
}

# --- NOUVELLE FONCTION MULTI-DRIVE ---
function Get-MultiDrivePaths([string]$subPath) {
    $found = @()
    $drives = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Free -gt 0 }
    foreach ($d in $drives) {
        $full = Join-Path $d.Root $subPath
        if (Test-Path $full) { $found += $full }
    }
    return $found
}
# -------------------------------------

function Log-Action([string]$action, [long]$freed) {
    if ($Config.enableLogging) {
        $entry = "$((Get-Date -Format 'yyyy-MM-dd HH:mm:ss')) | $($action.PadRight(25)) | $(Fmt $freed)"
        $entry | Out-File $LogPath -Append -Encoding UTF8
    }
}

function Write-Section([string]$title) {
    $line = "═" * ($title.Length + 4)
    Write-Host "`n$DC  ╔$line╗"
    Write-Host "  ║  $W$title$DC  ║"
    Write-Host "  ╚$line╝$RE`n"
}
#endregion

#region CORE ENGINE
function Clean-Target([string]$path, [string]$label) {
    Write-Host "  $W>$($M.Analyse)$C$label$RE" -NoNewline
    if (-not (Test-Path $path)) { Write-Host " $($R)$($M.Exist)$RE"; return 0 }
    
    $before = Get-Size $path
    try {
        Get-ChildItem $path -Recurse -Force -EA SilentlyContinue | Remove-Item -Recurse -Force -EA SilentlyContinue
        $after = Get-Size $path
        $freed = $before - $after
        if ($freed -gt 1024) { Write-Host " $G[+$(Fmt $freed)]$RE"; Log-Action $label $freed } 
        else { Write-Host " $DC$($M.Empty)$RE" }
        return $freed
    } catch { Write-Host " $Y$($M.Partial)$RE"; return 0 }
}
#endregion

#region MODULES
function Invoke-TempModule {
    Write-Section "FILESYSTEM & SYSTEM"
    $t = 0

    # --- Cleanmgr Sagerun (v2) ---
    $sageset = 7331
    $regBase = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches"
    $cats = @("Active Setup Temp Folders","BranchCache","D3D Shader Cache","Delivery Optimization Files","Device Driver Packages","Downloaded Program Files","Internet Cache Files","Memory Dump Files","Old ChkDsk Files","Previous Installations","Recycle Bin","Setup Log Files","System error memory dump files","Temporary Files","Update Cleanup","Windows Defender")
    foreach ($c in $cats) { 
        $k = Join-Path $regBase $c
        if (Test-Path $k) { Set-ItemProperty -Path $k -Name "StateFlags$sageset" -Value 2 -Type DWord -EA SilentlyContinue }
    }
    Start-Process "cleanmgr.exe" -ArgumentList "/sagerun:$sageset" -Wait -WindowStyle Hidden

    # --- Cibles Fusionnées (v1 + v2) ---
    $t += Clean-Target $env:TEMP "User Temp"
    $t += Clean-Target "$env:SystemRoot\Temp" "System Temp"
    $t += Clean-Target "$env:SystemRoot\Prefetch" "Prefetch"
    $t += Clean-Target "$env:LOCALAPPDATA\Microsoft\Windows\Explorer" "Thumbnails"
    $t += Clean-Target "$env:APPDATA\Microsoft\Windows\Recent" "Recent Items"
    $t += Clean-Target "$env:LOCALAPPDATA\Microsoft\Windows\INetCache" "Edge/IE Legacy Cache"
    $t += Clean-Target "C:\ProgramData\Microsoft\Diagnosis\ETLLogs" "Telemetry Logs"

    # --- Purge Système Profonde (v1) ---
    Stop-Service wuauserv, bits -Force -EA SilentlyContinue
    $t += Clean-Target "$env:SystemRoot\SoftwareDistribution\Download" "WinUpdate Cache"
    Start-Service wuauserv, bits -EA SilentlyContinue
    wevtutil el | ForEach-Object { wevtutil cl "$_" } 2>$null # Clear Event Logs
    $t += Clean-Target "$env:SystemRoot\Logs\CBS" "CBS Windows Logs"
    $t += Clean-Target "$env:ProgramData\Microsoft\Windows\WER" "Windows Reports (WER)"
    Clear-RecycleBin -Force -EA SilentlyContinue

    # --- .bak / .old files (v2) ---
    $bakTotal = 0
    Get-ChildItem "$env:USERPROFILE\Documents","$env:LOCALAPPDATA" -Recurse -Include "*.bak","*.old" -Force -EA SilentlyContinue | 
        Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-90) } | ForEach-Object { $bakTotal += $_.Length; Remove-Item $_.FullName -Force }
    Write-Host "  $W> Old Backup Files (.bak/.old):$G [+$(Fmt $bakTotal)]$RE"

    return $t + $bakTotal
}

function Invoke-WebModule {
    Write-Section "WEB & APPS"
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
    
    # Firefox dynamique (v2)
    $ffBase = "$env:APPDATA\Mozilla\Firefox\Profiles"
    if (Test-Path $ffBase) { Get-ChildItem $ffBase -Directory | ForEach-Object { $t += Clean-Target (Join-Path $_.FullName "cache2") "Firefox Cache" } }
    return $t
}

function Invoke-GamingModule {
    Write-Section "GAMING BOOST"
    $t = 0
    
    # --- Steam Multi-Drive ---
    $steamPaths = Get-MultiDrivePaths "SteamLibrary\steamapps\shadercache"
    foreach ($p in $steamPaths) { $t += Clean-Target $p "Steam Shaders ($($p.Substring(0,2)))" }
    $t += Clean-Target "$env:LOCALAPPDATA\Steam\htmlcache" "Steam Web"

    # --- Epic & Riot (Standard) ---
    $t += Clean-Target "$env:LOCALAPPDATA\Riot Games\Riot Client\Data\Cache" "Riot Client Cache"
    $t += Clean-Target "$env:LOCALAPPDATA\Riot Games\Installers" "Riot Installers"
    $t += Clean-Target "$env:LOCALAPPDATA\FortniteGame\Saved\ShaderCache" "Fortnite Shaders"
    $t += Clean-Target "$env:LOCALAPPDATA\FortniteGame\Saved\Logs" "Fortnite Logs"
    $t += Clean-Target "$env:VALORANT\Saved\Logs" "Valorant Logs"
    $t += Clean-Target "$env:ProgramData\Epic\EpicGamesLauncher\Data\EasyAntiCheat" "EAC Temp"

    $epic = @("webcache", "webcache_4147", "Logs", "Crashes", "HttpRequestCache")
    foreach ($e in $epic) { 
        $t += Clean-Target "$env:LOCALAPPDATA\EpicGamesLauncher\Saved\$e" "Epic $e" 
    }
    return $t
}

function Invoke-DevModule {
    Write-Section "DEVELOPER TOOLS"
    $t = 0
    $t += Clean-Target "$env:APPDATA\npm-cache" "NPM Cache"
    $t += Clean-Target "$env:LOCALAPPDATA\pip\cache" "Pip Cache"
    $t += Clean-Target "$env:LOCALAPPDATA\NuGet\Cache" "NuGet Cache"
    Get-ChildItem "$env:USERPROFILE" -Recurse -Directory -Filter "__pycache__" -EA SilentlyContinue | ForEach-Object {
        $t += Clean-Target $_.FullName "Python pycache"
    }
    return $t
}

function Invoke-OptiModule {
    Write-Section "PERFORMANCE TWEAKS"
    $bDir = $Config.backupDir
    if (!(Test-Path $bDir)) { New-Item $bDir -ItemType Directory | Out-Null }
    reg export HKLM (Join-Path $bDir "PreOpti_$(Get-Date -Format 'HHmm').reg") /y | Out-Null
    
    # Network & RAM Flush
    ipconfig /flushdns | Out-Null
    netsh interface ip delete arpcache | Out-Null
    $code = 'using System;using System.Runtime.InteropServices;public class Shxdow{[DllImport("psapi.dll")]public static extern bool EmptyWorkingSet(IntPtr h);}'
    Add-Type $code -EA SilentlyContinue
    Get-Process | ForEach-Object { [Shxdow]::EmptyWorkingSet($_.Handle) } 2>$null

    # Services Télémétrie & Registre (Exclusif v1)
    $srv = @("DiagTrack", "dmwappushservice")
    foreach ($s in $srv) { Stop-Service $s -Force -EA SilentlyContinue; Set-Service $s -StartupType Disabled -EA SilentlyContinue }
    
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
    }

    Optimize-Volume -DriveLetter C -ReTrim -EA SilentlyContinue
    Write-Host "  $G[✔] $($M.OptiDone)$RE"
}

function Invoke-HardwareModule {
    Write-Section "HARDWARE SPECIFIC"
    $t = 0
    $t += Clean-Target "C:\Intel\Logs" "Intel Driver Logs"
    $t += Clean-Target "$env:ProgramData\Microsoft\Surface" "Surface Diagnostic"
    $t += Clean-Target "$env:LOCALAPPDATA\Intel\ShaderCache" "Intel GPU Cache"
    
    $rem = 0
    Get-PnpDevice | Where-Object { $_.Present -eq $false } | ForEach-Object { try { $_ | Remove-PnpDevice -Confirm:$false; $rem++ } catch {} }
    if ($rem -gt 0) { Write-Host "  $G[✔] $rem $($M.Ghost)$RE" }
    return $t
}
#endregion

#region MAIN LOOP
while ($true) {
    Clear-Host
    Write-Host "$C
  ██████╗ ██╗  ██╗██╗  ██╗██████╗  ██████╗ ██╗    ██╗    ██████╗██╗     ███████╗ █████╗ ███╗   ██╗██╗   ██╗██████╗ 
 ██╔════╝ ██║  ██║╚██╗██╔╝██╔══██╗██╔═══██╗██║    ██║   ██╔════╝██║     ██╔════╝██╔══██╗████╗  ██║██║   ██║██╔══██╗
 ███████╗ ███████║ ╚███╔╝ ██║  ██║██║   ██║██║ █╗ ██║   ██║     ██║     █████╗  ███████║██╔██╗ ██║██║   ██║██████╔╝
 ╚════██║ ██╔══██║ ██╔██╗ ██║  ██║██║   ██║██║███╗██║   ██║     ██║     ██╔══╝  ██╔══██║██║╚██╗██║██║   ██║██╔═══╝ 
 ██████╔╝ ██║  ██║██╔╝ ██╗██████╔╝╚██████╔╝╚███╔███╔╝   ╚██████╗███████╗███████╗██║  ██║██║ ╚████║╚██████╔╝██║     
 ╚═════╝  ╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝  ╚═════╝  ╚══╝╚══╝     ╚═════╝╚══════╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝ ╚═════╝ ╚═╝     
$RE$Y                                           by Shxdow  $RE$DC v3.3.1$RE"

    Write-Host "`n$DC╔══════════════════════════════════════════════════╗"
    Write-Host "$DC║        $C$($M.BannerTitle)$RE$DC                    ║"
    Write-Host "$DC╠══════════════════════════════════════════════════╣$RE"
    Write-Host "$W [1]$RE   $C $($M.Menu1)$RE"
    Write-Host "$W [2]$RE   $C $($M.Menu2)$RE"
    Write-Host "$W [3]$RE   $C $($M.Menu3)$RE"
    Write-Host "$W [4]$RE   $C $($M.Menu4)$RE"
    Write-Host "$W [5]$RE   $C $($M.Menu5)$RE"
    Write-Host "$W [6]$RE   $C $($M.Menu6)$RE"
    Write-Host "$DC╠══════════════════════════════════════════════════╣$RE"
    Write-Host "$W [O]$RE   $C $($M.MenuO)$RE"
    Write-Host "$W [0]$RE   $C $($M.MenuQ)$RE"
    Write-Host "$DC╚══════════════════════════════════════════════════╝$RE"

    Write-Host "`n$C  ►$RE $W$($M.Action)$RE $DC>$RE " -NoNewline
    $choice = (Read-Host).ToUpper()
    if ($choice -eq "0") { break }

    # --- AJOUT ICI ---
    $canProcess = $true
    if ($choice -match "^[1-6]$") {
        Write-Host "`n  $Y[!] Confirmer le lancement du module $choice ? (O/N) : $RE" -NoNewline
        if ((Read-Host) -notmatch "^[OoYy]$") { $canProcess = $false }
    }

    if ($canProcess) {
        $start = Get-Date
        # --- SCAN DE TOUS LES DISQUES AVANT ---
        $drivesBefore = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Free -gt 0 }

        switch -Regex ($choice) {
            "[O1]" { Invoke-TempModule }
            "[O2]" { Invoke-WebModule }
            "[O3]" { Invoke-GamingModule }
            "[O4]" { Invoke-DevModule }
            "[O5]" { Invoke-OptiModule }
            "[O6]" { Invoke-HardwareModule }
        }

        # --- CALCUL DU GAIN TOTAL (MULTI-DRIVE) ---
        $drivesAfter = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Free -gt 0 }
        $realGain = 0
        foreach ($dAfter in $drivesAfter) {
            $dBefore = $drivesBefore | Where-Object Name -eq $dAfter.Name
            if ($null -ne $dBefore -and $dAfter.Free -gt $dBefore.Free) {
                $realGain += ($dAfter.Free - $dBefore.Free)
            }
        }
        
        Write-Section "BILAN"
        Write-Host ("  $G" + ($M.Bilan -f (Fmt $realGain)) + "$RE")
        Write-Host "  $W$($M.Time)$((Get-Date) - $start | ForEach-Object { "$($_.Seconds)s" }) $RE"
        
        Write-Host "`n  $C[?]$($M.ReportAsk)$RE" -NoNewline
        if ((Read-Host) -match "^[OoYy]$") {
            $reportPath = "$env:USERPROFILE\Desktop\Shxdow_Report.txt"
            "SHXDOW CLEANUP v3.3.2`nDate: $(Get-Date)`nGain: $(Fmt $realGain)" | Out-File $reportPath
            Write-Host "  $G [✔] Done.$RE"
        }
    } # --- FERMETURE DU BLOC PROCESS ---

    Write-Host "`n  Press Enter to continue..."; Read-Host | Out-Null
}
