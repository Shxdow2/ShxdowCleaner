#Requires -RunAsAdministrator
<#
  SHXDOW CLEANUP v3.3 - THE FINAL FUSION
  Build: 2026-04-02
  Author: Shxdow
  Features: JSON Config, Action Logging, Deep Gaming, Hardware Opti, SSD ReTrim & Multi-Browser
#>

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = "SilentlyContinue"

#region UI & COLORS
$C = [char]27 + "[1;36m"; $W = [char]27 + "[1;37m"; $G = [char]27 + "[1;32m"; $R = [char]27 + "[1;31m"
$Y = [char]27 + "[1;33m"; $DC = [char]27 + "[0;36m"; $RE = [char]27 + "[0m"
#endregion

#region CONFIG & LOGGING
$ConfigPath = Join-Path $PSScriptRoot "config.json"
$LogPath = "$env:TEMP\ShxdowCleaner.log"

if (Test-Path $ConfigPath) { 
    try { $Config = Get-Content $ConfigPath | ConvertFrom-Json } catch { $Config = $null } 
}
if ($null -eq $Config) {
    $Config = [PSCustomObject]@{
        backupDir = "C:\RegistryBackups"
        enableLogging = $true
        modules = @{ gaming = $true; web = $true; hardware = $true }
    }
}

function Fmt([long]$b) {
    if ($b -ge 1GB) { return "{0:N2} GB" -f ($b / 1GB) }
    if ($b -ge 1MB) { return "{0:N2} MB" -f ($b / 1MB) }
    return "{0:N2} KB" -f ($b / 1KB)
}

function Log-Action([string]$action, [long]$freed) {
    if ($Config.enableLogging) {
        $entry = "$((Get-Date -Format 'yyyy-MM-dd HH:mm:ss')) | $($action.PadRight(25)) | $(Fmt $freed)"
        $entry | Out-File $LogPath -Append -Encoding UTF8
    }
}
#endregion

#region CORE ENGINE
function Clean-Target([string]$path, [string]$label) {
    Write-Host "  $W> Analyse : $C$label$RE" -NoNewline
    if (-not (Test-Path $path)) { 
        Write-Host " $R[Inexistant]$RE"
        return 0 
    }
    
    $before = (Get-ChildItem $path -Recurse -Force -EA SilentlyContinue | Measure-Object -Property Length -Sum).Sum
    try {
        Get-ChildItem $path -Recurse -Force -EA SilentlyContinue | Remove-Item -Recurse -Force -EA SilentlyContinue
        $after = (Get-ChildItem $path -Recurse -Force -EA SilentlyContinue | Measure-Object -Property Length -Sum).Sum
        $freed = $before - $after
        
        if ($freed -gt 1024) {
            Write-Host " $G[+$(Fmt $freed)]$RE"
            Log-Action $label $freed
        } else {
            Write-Host " $DC[Déjà Vide]$RE"
        }
        return $freed
    } catch {
        Write-Host " $Y[Accès Partiel]$RE"
        return 0
    }
}
#endregion

#region MODULES
function Invoke-TempModule {
    Write-Section "FILESYSTEM & TEMP"
    $t = 0
    $t += Clean-Target $env:TEMP "User Temp"
    $t += Clean-Target "$env:SystemRoot\Temp" "System Temp"
    $t += Clean-Target "$env:SystemRoot\Prefetch" "Prefetch"
    $t += Clean-Target "$env:LOCALAPPDATA\Microsoft\Windows\Explorer" "Thumbnails"
    $t += Clean-Target "$env:APPDATA\Microsoft\Windows\Recent" "Recent Items"
    $t += Clean-Target "$env:LOCALAPPDATA\Microsoft\Windows\INetCache" "Edge/IE Legacy Cache"
    $t += Clean-Target "C:\ProgramData\Microsoft\Diagnosis\ETLLogs" "Telemetry Logs"
    return $t
}

function Invoke-WebModule {
    if (-not $Config.modules.web) { return 0 }
    Write-Section "WEB & APPS"
    $t = 0
    $t += Clean-Target "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache" "Chrome Cache"
    $t += Clean-Target "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache" "Edge Cache"
    $t += Clean-Target "$env:APPDATA\discord\Cache" "Discord Cache"
    $t += Clean-Target "$env:LOCALAPPDATA\Spotify\Storage" "Spotify Cache"
    $t += Clean-Target "$env:LOCALAPPDATA\Microsoft\Teams\Cache" "Teams Cache"
    $t += Clean-Target "$env:LOCALAPPDATA\Microsoft\Office\16.0\OfficeFileCache" "Office Cache"
    $t += Clean-Target "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data\Default\Cache" "Brave Cache"
    $t += Clean-Target "$env:LOCALAPPDATA\Opera Software\Opera GX Stable\Cache" "Opera GX Cache"
    return $t
}

function Invoke-GamingModule {
    if (-not $Config.modules.gaming) { return 0 }
    Write-Section "GAMING BOOST"
    $t = 0
    $t += Clean-Target "$env:LOCALAPPDATA\Steam\htmlcache" "Steam Web"
    $t += Clean-Target "$env:LOCALAPPDATA\Riot Games\Riot Client\Data\Cache" "Riot Client Cache"
    $t += Clean-Target "$env:LOCALAPPDATA\Riot Games\Installers" "Riot Installers"
    $t += Clean-Target "$env:LOCALAPPDATA\FortniteGame\Saved\ShaderCache" "Fortnite Shaders"
    $t += Clean-Target "$env:LOCALAPPDATA\FortniteGame\Saved\Logs" "Fortnite Logs"
    $t += Clean-Target "$env:LOCALAPPDATA\VALORANT\Saved\Logs" "Valorant Logs"
    $t += Clean-Target "$env:ProgramData\Epic\EpicGamesLauncher\Data\EasyAntiCheat" "EAC Temp"
    $epic = @("webcache", "webcache_4147", "Logs", "Crashes", "HttpRequestCache")
    foreach ($e in $epic) { $t += Clean-Target "$env:LOCALAPPDATA\EpicGamesLauncher\Saved\$e" "Epic $e" }
    return $t
}

function Invoke-SystemModule {
    Write-Section "SYSTEM PURGE"
    $t = 0
    Stop-Service wuauserv, bits -Force -EA SilentlyContinue
    $t += Clean-Target "$env:SystemRoot\SoftwareDistribution\Download" "WinUpdate"
    Start-Service wuauserv, bits -EA SilentlyContinue
    wevtutil el | ForEach-Object { wevtutil cl "$_" } 2>$null
    $t += Clean-Target "$env:SystemRoot\Logs\CBS" "CBS Windows Logs"
    $t += Clean-Target "$env:ProgramData\Microsoft\Windows\WER" "Windows Reports (WER)"
    Clear-RecycleBin -Force -EA SilentlyContinue
    return $t
}

function Invoke-HardwareModule {
    if (-not $Config.modules.hardware) { return 0 }
    Write-Section "HARDWARE & SURFACE"
    $t = 0
    $t += Clean-Target "C:\Intel\Logs" "Intel Driver Logs"
    $t += Clean-Target "$env:ProgramData\Microsoft\Surface" "Surface Diagnostic"
    $t += Clean-Target "$env:LOCALAPPDATA\Intel\ShaderCache" "Intel GPU Cache"
    $rem = 0
    Get-PnpDevice | Where-Object { $_.Present -eq $false } | ForEach-Object { try { $_ | Remove-PnpDevice -Confirm:$false; $rem++ } catch {} }
    if ($rem -gt 0) { Write-Host "  $G[✔] $rem périphériques fantômes supprimés$RE" }
    return $t
}

function Invoke-OptiModule {
    Write-Section "PERFORMANCE TWEAKS"
    $bDir = $Config.backupDir
    if (!(Test-Path $bDir)) { New-Item $bDir -ItemType Directory | Out-Null }
    reg export HKLM (Join-Path $bDir "PreOpti_$(Get-Date -Format 'HHmm').reg") /y | Out-Null
    
    # RAM Flush
    $code = 'using System;using System.Runtime.InteropServices;public class Shxdow{[DllImport("psapi.dll")]public static extern bool EmptyWorkingSet(IntPtr h);}'
    Add-Type $code -EA SilentlyContinue
    Get-Process | ForEach-Object { [Shxdow]::EmptyWorkingSet($_.Handle) } 2>$null

    # Services & Registre (VBS, DVR, Telemetry)
    $srv = @("DiagTrack", "dmwappushservice")
    foreach ($s in $srv) { Stop-Service $s -Force; Set-Service $s -StartupType Disabled }
    
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
        Set-ItemProperty -Path $key.Path -Name $key.Name -Value $key.Value -Type DWord 
    }

    ipconfig /flushdns | Out-Null
    netsh interface ip delete arpcache | Out-Null
    Optimize-Volume -DriveLetter C -ReTrim -EA SilentlyContinue
    Write-Host "  $G[✔] Optimisations complètes appliquées (VBS OFF, RAM Flush, SSD Trim)$RE"
}

function Write-Section([string]$title) {
    Write-Host "`n$DC--- [ $title ] ---$RE"
}
#endregion

#region MAIN LOOP
while ($true) {
    Clear-Host
    Write-Host "$C
  ██████╗ ██╗  ██╗██╗  ██╗██████╗  ██████╗ ██╗    ██╗    ██████╗██╗      ███████╗ █████╗ ███╗   ██╗██╗   ██╗██████╗ 
 ██╔════╝ ██║  ██║╚██╗██╔╝██╔══██╗██╔═══██╗██║    ██║   ██╔════╝██║      ██╔════╝██╔══██╗████╗  ██║██║   ██║██╔══██╗
 ███████╗ ███████║ ╚███╔╝ ██║  ██║██║   ██║██║ █╗ ██║   ██║     ██║      █████╗  ███████║██╔██╗ ██║██║   ██║██████╔╝
 ╚════██║ ██╔══██║ ██╔██╗ ██║  ██║██║   ██║██║███╗██║   ██║     ██║      ██╔══╝  ██╔══██║██║╚██╗██║██║   ██║██╔═══╝ 
 ██████╔╝ ██║  ██║██╔╝ ██╗██████╔╝╚██████╔╝╚███╔███╔╝   ╚██████╗███████╗███████╗██║  ██║██║ ╚████║╚██████╔╝██║     
 ╚═════╝  ╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝  ╚═════╝  ╚══╝╚══╝     ╚═════╝╚══════╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝ ╚═════╝ ╚═╝     
$RE$Y                                     by Shxdow  $RE$DC v3.3 FINAL$RE"

    Write-Host "`n$W [1] Temp  [2] Web  [3] Gaming  [4] Système  [5] Opti  [6] Hardware  [O] Complet  [0] Quitter$RE"
    Write-Host "`n$C ► Action > $RE" -NoNewline
    $choice = (Read-Host).ToUpper()
    if ($choice -eq "0") { break }

    $start = Get-Date
    $diskBefore = (Get-PSDrive C).Free

    switch -Regex ($choice) {
        "[O1]" { Invoke-TempModule }
        "[O2]" { Invoke-WebModule }
        "[O3]" { Invoke-GamingModule }
        "[O4]" { Invoke-SystemModule }
        "[O5]" { Invoke-OptiModule }
        "[O6]" { Invoke-HardwareModule }
    }

    $diskAfter = (Get-PSDrive C).Free
    $realGain = if ($diskAfter -gt $diskBefore) { $diskAfter - $diskBefore } else { 0 }
    
    Write-Host "`n$DC" + ("═" * 45)
    Write-Host "  $G BILAN : $(Fmt $realGain) récupérés réellement$RE"
    Write-Host "  $W Temps : $((Get-Date) - $start | ForEach-Object { "$($_.Seconds)s" }) $RE"
    Write-Host "$DC" + ("═" * 45)
    
    # --- OPTIONS DE FIN (Comme dans la 3.1) ---
    Write-Host "`n  $C[?] Enregistrer le rapport sur le Bureau ? (O/N)$RE" -NoNewline
    if ((Read-Host) -match "^[Oo]$") {
        $reportPath = "$env:USERPROFILE\Desktop\Shxdow_Report.txt"
        "SHXDOW CLEANUP v3.3`nDate: $(Get-Date)`nGain réel: $(Fmt $realGain)" | Out-File $reportPath
        Write-Host "  $G[✔] Rapport créé sur le Bureau.$RE"
    }

    Write-Host "  $Y[?] Redémarrer maintenant pour finaliser ? (O/N)$RE" -NoNewline
    if ((Read-Host) -match "^[Oo]$") { Restart-Computer -Force }

    Write-Host "`n  Appuyez sur Entrée pour continuer..." -NoNewline; Read-Host | Out-Null
}
#endregion