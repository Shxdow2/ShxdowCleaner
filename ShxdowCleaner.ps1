#Requires -RunAsAdministrator
<#
  SHXDOW CLEANUP v3.1
  by Shxdow
  Performance & Deep Cleanup
  Requires: PowerShell 5.1+ | Run As Administrator
#>

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = "SilentlyContinue"

#region UI & COLORS
$R  = [char]27 + "[1;31m"
$Y  = [char]27 + "[1;33m"
$G  = [char]27 + "[1;32m"
$C  = [char]27 + "[1;36m"
$W  = [char]27 + "[1;37m"
$DC = [char]27 + "[0;36m"
$RE = [char]27 + "[0m"
#endregion

#region HELPERS
function Get-Size([string]$p) {
    if (-not (Test-Path $p)) { return 0 }
    try { (Get-ChildItem $p -Recurse -Force -EA SilentlyContinue | Measure-Object -Property Length -Sum).Sum } catch { 0 }
}

function Fmt([long]$b) {
    if ($b -ge 1GB) { return "{0:N2} GB" -f ($b / 1GB) }
    if ($b -ge 1MB) { return "{0:N2} MB" -f ($b / 1MB) }
    if ($b -ge 1KB) { return "{0:N2} KB" -f ($b / 1KB) }
    return "$b B"
}

function Write-Banner {
    Clear-Host
    $b = @"
$C
  ██████╗ ██╗  ██╗██╗  ██╗██████╗  ██████╗ ██╗    ██╗    ██████╗██╗     ███████╗ █████╗ ███╗   ██╗██╗   ██╗██████╗ 
 ██╔════╝ ██║  ██║╚██╗██╔╝██╔══██╗██╔═══██╗██║    ██║   ██╔════╝██║     ██╔════╝██╔══██╗████╗  ██║██║   ██║██╔══██╗
 ███████╗ ███████║ ╚███╔╝ ██║  ██║██║   ██║██║ █╗ ██║   ██║     ██║     █████╗  ███████║██╔██╗ ██║██║   ██║██████╔╝
 ╚════██║ ██╔══██║ ██╔██╗ ██║  ██║██║   ██║██║███╗██║   ██║     ██║     ██╔══╝  ██╔══██║██║╚██╗██║██║   ██║██╔═══╝ 
 ██████╔╝ ██║  ██║██╔╝ ██╗██████╔╝╚██████╔╝╚███╔███╔╝   ╚██████╗███████╗███████╗██║  ██║██║ ╚████║╚██████╔╝██║     
 ╚═════╝  ╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝  ╚═════╝  ╚══╝╚══╝     ╚═════╝╚══════╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝ ╚═════╝ ╚═╝     
$RE$Y                                       by Shxdow  $RE$DC v3.1$RE
"@
    Write-Host $b
}

function Write-Menu {
    $m = @"
$DC╔══════════════════════════════════════════════════╗
║              $C MODULES DE NETTOYAGE $RE$DC              ║
╠══════════════════════════════════════════════════╣$RE
$W [1]$RE   $C Temporaires $RE— Windows, Prefetch, Crypto, RSA
$W [2]$RE   $C Web & Apps  $RE— Browsers, Teams, Discord, Spotify
$W [3]$RE   $C Gaming      $RE— Steam, Fortnite, Epic, Shaders
$W [4]$RE   $C Optimisation$RE— RAM, DNS, Télémétrie, GameDVR, Apps Fond, Update, Logs, CBS, Event Logs
$W [5]$RE   $C Optimisation$RE— Cleanmgr, TRIM, RAM, DNS, Registry
$W [6]$RE   $C Hardware    $RE— Surface Pro 8 & Intel Specific
$W [7]$RE   $C Périphiques $RE— Device Cleanup
$DC╠══════════════════════════════════════════════════╣$RE
$W [O]$RE   $C Lancer le nettoyage complet$RE
$W [0]$RE   $C Quitter$RE
$DC╚══════════════════════════════════════════════════╝$RE
"@
    Write-Host $m
}

function Write-Section([string]$title) {
    $line = "═" * ($title.Length + 4)
    Write-Host "`n$DC  ╔$line╗"
    Write-Host "  ║  $W$title$DC  ║"
    Write-Host "  ╚$line╝$RE`n"
}

function Write-OK([string]$label, [string]$value) {
    Write-Host "  $C$($label.PadRight(22))$RE $W$value$RE"
}

function Write-Found([string]$text) {
    Write-Host "  $G[✔]$RE $text"
}

function Write-Inp([string]$prompt) {
    Write-Host "`n$C  ►$RE $W$prompt$RE $DC>$RE " -NoNewline
    return Read-Host
}

function Confirm-Task([string]$label, [string]$explication) {
    Write-Host ""
    Write-Host "  +-------------------------------------------------------" -ForegroundColor DarkCyan
    Write-Host "  |  >> $label" -ForegroundColor White
    Write-Host "  |     $explication" -ForegroundColor DarkGray
    Write-Host "  |" -ForegroundColor DarkCyan
    Write-Host "  |  Effectuer cette operation ? [O/N] " -NoNewline -ForegroundColor Yellow
    $r = Read-Host
    $ok = $r -match "^[Oo]$"
    if (-not $ok) { Write-Found "[IGNORE] $label" }
    return $ok
}

function Clean-Target([string]$path, [string]$label, [string]$explication) {
    if ($choice -eq "O") { $ok = $true } else { $ok = Confirm-Task $label $explication }
    
    if (-not $ok) { return 0 }
    if (-not (Test-Path $path)) { Write-OK $label "Inexistant"; return 0 }
    $before = Get-Size $path
    Get-ChildItem $path -Recurse -Force -EA SilentlyContinue | Remove-Item -Recurse -Force -EA SilentlyContinue
    $freed = $before - (Get-Size $path)
    if ($freed -gt 0) { Write-OK $label (Fmt $freed) } else { Write-OK $label "Rien à nettoyer" }
    return $freed
}
#endregion

#region MAIN PROCESS
while ($true) {
    Write-Banner
    Write-Menu
    $choice = Write-Inp "Action"
    if ($choice -eq "0") { break }

    if ($choice -match "[Oo1-7]") {
        $diskBefore = (Get-PSDrive C).Free
        $TotalFreed = 0
        $startTime = Get-Date

        # --- MODULE 1: TEMPORAIRES ---
        if ($choice -match "[O1]") {
            Write-Section "FILESYSTEM CLEANUP"
            $TotalFreed += Clean-Target $env:TEMP "User Temp" "Fichiers temporaires utilisateur"
            $TotalFreed += Clean-Target "$env:SystemRoot\Temp" "System Temp" "Temp Windows"
            $TotalFreed += Clean-Target "$env:SystemRoot\Prefetch" "Prefetch" "Cache pre-chargement"
            $TotalFreed += Clean-Target "$env:APPDATA\Microsoft\Windows\Recent" "Recent Items" "Raccourcis récents"
            $TotalFreed += Clean-Target "$env:LOCALAPPDATA\Microsoft\Windows\Explorer" "Thumbnails" "Miniatures Explorer"
            $TotalFreed += Clean-Target "$env:LOCALAPPDATA\Microsoft\Windows\INetCache" "Edge/IE Legacy Cache"
            $TotalFreed += Clean-Target "C:\ProgramData\Microsoft\Diagnosis\ETLLogs" "Telemetry Logs"
        }

        # --- MODULE 2: APPS & BROWSERS ---
        if ($choice -match "[O2]") {
            Write-Section "APPS & BROWSERS"
            $TotalFreed += Clean-Target "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache" "Chrome Cache" "Cache web Chrome"
            $TotalFreed += Clean-Target "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache" "Edge Cache" "Cache web Edge"
            $TotalFreed += Clean-Target "$env:APPDATA\discord\Cache" "Discord Cache" "Cache Discord"
            $TotalFreed += Clean-Target "$env:LOCALAPPDATA\Spotify\Storage" "Spotify Cache" "Cache Spotify"
            $TotalFreed += Clean-Target "$env:LOCALAPPDATA\Steam\htmlcache" "Steam Cache" "Cache Steam"
            $TotalFreed += Clean-Target "$env:LOCALAPPDATA\Microsoft\Teams\Cache" "Teams Cache" "Cache Teams"
            $TotalFreed += Clean-Target "$env:LOCALAPPDATA\Microsoft\Office\16.0\OfficeFileCache" "Office FileCache" "Cache Office"
            $TotalFreed += Clean-Target "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data\Default\Cache" "Brave Cache" "Cache web Brave"
            $TotalFreed += Clean-Target "$env:LOCALAPPDATA\Opera Software\Opera GX Stable\Cache" "Opera GX Cache" "Cache web Opera GX"
        }

        # --- MODULE 3: GAMING ---
        if ($choice -match "[O3]") {
            Write-Section "GAMING CACHE"
            
            # Epic & EAC (Tes ajouts de la V1 optimisés)
            $TotalFreed += Clean-Target "$env:ProgramData\Epic\EpicGamesLauncher\Data\EasyAntiCheat" "EAC Logs & Tmp" "Fichiers .log et .tmp de EasyAntiCheat"
            
            $epicPaths = @(
                "$env:LOCALAPPDATA\EpicGamesLauncher\Saved\webcache",
                "$env:LOCALAPPDATA\EpicGamesLauncher\Saved\webcache_4147",
                "$env:LOCALAPPDATA\EpicGamesLauncher\Saved\Logs",
                "$env:LOCALAPPDATA\EpicGamesLauncher\Saved\Crashes",
                "$env:LOCALAPPDATA\EpicGamesLauncher\Saved\HttpRequestCache"
            )
            foreach ($path in $epicPaths) {
                $TotalFreed += Clean-Target $path "Epic Launcher Cache" "Cache web, logs et rapports de crash Epic"
            }

            # Fortnite & Riot
            $TotalFreed += Clean-Target "$env:LOCALAPPDATA\FortniteGame\Saved\ShaderCache" "Fortnite Shaders" "Shaders Fortnite"
            $TotalFreed += Clean-Target "$env:LOCALAPPDATA\FortniteGame\Saved\Logs" "Fortnite Logs" "Logs Fortnite"
            $TotalFreed += Clean-Target "$env:LOCALAPPDATA\Riot Games\Riot Client\Data\Cache" "Riot Client Cache" "Cache du client Riot"
            $TotalFreed += Clean-Target "$env:LOCALAPPDATA\Riot Games\Installers" "Riot Installers" "Anciens installeurs Riot"
            $TotalFreed += Clean-Target "$env:LOCALAPPDATA\VALORANT\Saved\Logs" "Valorant Logs" "Logs de crash Valorant"
        }

        # --- MODULE 4: SYSTEME & LOGS ---
        if ($choice -match "[O4]") {
            Write-Section "SYSTEM PURGE"
            Stop-Service -Name wuauserv, bits -Force -EA SilentlyContinue
            $TotalFreed += Clean-Target "$env:SystemRoot\SoftwareDistribution\Download" "WinUpdate" "Fichiers Windows Update"
            Start-Service -Name wuauserv, bits -EA SilentlyContinue
            wevtutil el | ForEach-Object { wevtutil cl "$_" } 2>$null
            $TotalFreed += Clean-Target "$env:SystemRoot\Logs\CBS" "CBS Logs" "Logs CBS Windows"
            Clear-RecycleBin -Force -EA SilentlyContinue
            $TotalFreed += Clean-Target "$env:ProgramData\Microsoft\Windows\WER" "Windows Error Reporting"
            Clear-RecycleBin -Force -EA SilentlyContinue
        }

        # --- MODULE 5: OPTIMISATION ---
        if ($choice -match "[O5]") {
            Write-Section "OPTIMIZATION & PRIVACY"
            ipconfig /flushdns | Out-Null
            netsh interface ip delete arpcache | Out-Null
            Optimize-Volume -DriveLetter C -ReTrim -EA SilentlyContinue
            
            $code = 'using System;using System.Runtime.InteropServices;public class Shxdow{[DllImport("psapi.dll")]public static extern bool EmptyWorkingSet(IntPtr h);}'
            Add-Type $code -EA SilentlyContinue
            Get-Process | ForEach-Object { [Shxdow]::EmptyWorkingSet($_.Handle) } 2>$null

            # Télémétrie & Privé
            $paths = @("HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection", "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection")
            foreach ($p in $paths) { if (!(Test-Path $p)) { New-Item $p -Force } Set-ItemProperty -Path $p -Name "AllowTelemetry" -Value 0 -Type DWord }
            
            Get-Service "DiagTrack", "dmwappushservice" -ErrorAction SilentlyContinue | Stop-Service -Force -PassThru | Set-Service -StartupType Disabled
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SilentInstalledAppsEnabled" -Value 0 -Type DWord
            
            # GameDVR & VBS
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR" -Name "AppCaptureEnabled" -Value 0 -Type DWord
            Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_Enabled" -Value 0 -Type DWord
            Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" -Name "Enabled" -Value 0 -Type Dword
            Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard" -Name "EnableVirtualizationBasedSecurity" -Value 0 -Type Dword
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" -Name "GlobalUserDisabled" -Value 1 -Type DWord

            Write-Found "Système optimisé (RAM, SSD, Télémétrie, GameDVR)"
        }

        # --- MODULE 6: HARDWARE ---
        if ($choice -match "[O6]") {
            Write-Section "SURFACE & INTEL"
            $TotalFreed += Clean-Target "C:\Intel\Logs" "Intel Driver Logs" "Logs drivers Intel"
            $TotalFreed += Clean-Target "$env:ProgramData\Microsoft\Surface" "Surface Diagnostic" "Diagnostic Surface"
            $TotalFreed += Clean-Target "$env:LOCALAPPDATA\Intel\ShaderCache" "Intel GPU Cache" "Cache GPU Intel"
        }

        # --- MODULE 7: DEVICES ---
        if ($choice -match "[O7]") {
            Write-Section "DEVICE CLEANUP"
            $rem = 0
            Get-PnpDevice | Where-Object { $_.Present -eq $false } | ForEach-Object {
                try { $_ | Remove-PnpDevice -Confirm:$false -EA SilentlyContinue; $rem++ } catch {}
            }
            Write-Found "$rem périphériques fantômes supprimés"
        }

        # --- FINAL REPORT ---
        $realFreed = (Get-PSDrive C).Free - $diskBefore
        $elapsed = (Get-Date) - $startTime
        Write-Section "BILAN"
        Write-OK "Espace libéré" (Fmt $realFreed)
        Write-OK "Temps" "$($elapsed.ToString('mm\:ss'))"

        Write-Host "`n  Enregistrer le rapport sur le Bureau ? [O/N] " -NoNewline -ForegroundColor Cyan
        if ((Read-Host) -match "^[Oo]$") {
            $reportPath = "$env:USERPROFILE\Desktop\ShxdowCleaner_Report.txt"
            "SHXDOW CLEANUP v3.1`nLibéré: $(Fmt $realFreed)`nTemps: $($elapsed.ToString('mm\:ss'))" | Out-File $reportPath -Encoding UTF8
            Write-Host "  [OK] Rapport sauvegardé." -ForegroundColor Green
        }

        Write-Host "`n  Redémarrer maintenant ? [O/N] " -NoNewline -ForegroundColor Cyan
        if ((Read-Host) -match "^[Oo]$") { Restart-Computer -Force }
        
        Write-Inp "Appuyez sur Entrée pour revenir au menu..." | Out-Null
    }
}
#endregion