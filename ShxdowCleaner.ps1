#Requires -RunAsAdministrator
<#
  SHXDOW CLEANUP v3.1 - THE ULTIMATE MERGE
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
$W [4]$RE   $C Système     $RE— Update, Logs, CBS, Event Logs
$W [5]$RE   $C Optimisation$RE— Cleanmgr, TRIM, RAM, DNS, Registry
$W [6]$RE   $C Hardware    $RE— Surface Pro 8 & Intel Specific
$W [7]$RE   $C Périphiques $RE— Device Cleanup (Fantômes)
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
    if (-not (Confirm-Task $label $explication)) { return 0 }
    if (-not (Test-Path $path)) { Write-OK $label "Inexistant"; return 0 }
    $before = Get-Size $path
    Get-ChildItem $path -Recurse -Force -EA SilentlyContinue | Remove-Item -Recurse -Force -EA SilentlyContinue
    $freed = $before - (Get-Size $path)
    if ($freed -gt 0) { Write-OK $label (Fmt $freed) } else { Write-OK $label "Rien à nettoyer" }
    return $freed
}
#endregion

#region CORE CLEANUP LOOP
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
        }

        # --- MODULE 3: GAMING ---
        if ($choice -match "[O3]") {
            Write-Section "GAMING CACHE"
            $TotalFreed += Clean-Target "$env:LOCALAPPDATA\FortniteGame\Saved\ShaderCache" "Fortnite Shaders" "Shaders Fortnite"
            $TotalFreed += Clean-Target "$env:LOCALAPPDATA\FortniteGame\Saved\Logs" "Fortnite Logs" "Logs Fortnite"
            $TotalFreed += Clean-Target "$env:LOCALAPPDATA\EpicGamesLauncher\Saved\webcache" "Epic Cache" "Cache Epic Games"
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
        }

        # --- MODULE 5: OPTIMISATION ---
        if ($choice -match "[O5]") {
            Write-Section "OPTIMIZATION"
            ipconfig /flushdns | Out-Null
            netsh interface ip delete arpcache | Out-Null
            Optimize-Volume -DriveLetter C -ReTrim -EA SilentlyContinue
            $code = 'using System;using System.Runtime.InteropServices;public class Shxdow{[DllImport("psapi.dll")]public static extern bool EmptyWorkingSet(IntPtr h);}'
            Add-Type $code -EA SilentlyContinue
            Get-Process | ForEach-Object { [Shxdow]::EmptyWorkingSet($_.Handle) } 2>$null
            Write-Found "RAM, DNS et SSD optimisés"
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

        # Rapport sur le bureau
        $reportPath = "$env:USERPROFILE\Desktop\ShxdowReport.txt"
        "SHXDOW CLEANUP v3.1`nLibéré: $(Fmt $realFreed)`nDate: $(Get-Date)" | Out-File $reportPath
        Write-Host "`n  [!] Action terminée. Appuie sur une touche..." -ForegroundColor Gray
        $null = [Console]::ReadKey()
    }
}
# ===== EXECUTION MODE =====
Write-Host ""
Write-Host "[1] Exécuter tout"
Write-Host "[2] Lancer avec pause"
$mode = Read-Host "Choix"

if ($mode -eq "2") {
    Read-Host "Appuie sur ENTER pour lancer chaque partie"
}

# ===== START V1 =====
#Requires -RunAsAdministrator
<#
  SHXDOW CLEANER v1.0
  by Shxdow
  Performance - Stockage - FTN
  Requires: PowerShell 5.1+ | Run As Administrator
#>

#region INIT
Set-StrictMode -Version Latest
$ErrorActionPreference = "SilentlyContinue"

$script:Ver       = "1.0"
$script:Author    = "Shxdow"
$script:StartTime = Get-Date
$script:Total     = 0
$script:Log       = [System.Collections.Generic.List[string]]::new()
$script:Report    = "$env:USERPROFILE\Desktop\ShxdowCleaner_$(Get-Date -f 'yyyyMMdd_HHmmss').txt"
#endregion

#region HELPERS
function Get-Size([string]$p) {
    if (-not (Test-Path $p)) { return 0 }
    try { (Get-ChildItem $p -Recurse -Force -EA SilentlyContinue | Measure-Object -Property Length -Sum).Sum } catch { 0 }
}

function Fmt([long]$b) {
    switch ($b) {
        { $_ -ge 1GB } { return "{0:N2} GB" -f ($_ / 1GB) }
        { $_ -ge 1MB } { return "{0:N2} MB" -f ($_ / 1MB) }
        { $_ -ge 1KB } { return "{0:N2} KB" -f ($_ / 1KB) }
        default        { return "$b B" }
    }
}

function Write-Banner {
    Clear-Host
    Write-Host ""
    Write-Host "  =============================================" -ForegroundColor Cyan
    Write-Host "        S H X D O W   C L E A N E R" -ForegroundColor White
    Write-Host "                  v$script:Ver" -ForegroundColor DarkCyan
    Write-Host "             by  S h x d o w" -ForegroundColor DarkGray
    Write-Host "  =============================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  OS   : $([System.Environment]::OSVersion.VersionString)" -ForegroundColor DarkGray
    Write-Host "  Date : $(Get-Date -f 'dd/MM/yyyy  HH:mm:ss')" -ForegroundColor DarkGray
    Write-Host "  User : $env:USERNAME  |  Host: $env:COMPUTERNAME" -ForegroundColor DarkGray
    Write-Host "  =============================================" -ForegroundColor Cyan
    Write-Host ""
}

function Write-Section([string]$title) {
    $line = "`n  == $title =="
    Write-Host $line -ForegroundColor DarkCyan
    $script:Log.Add($line)
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
    if (-not $ok) {
        $skip = "  |  [IGNORE] $label"
        Write-Host $skip -ForegroundColor DarkGray
        $script:Log.Add($skip)
    } else {
        $script:Log.Add("  |  [OK] $label")
    }
    return $ok
}

function Write-Done([long]$freed, [string]$label) {
    $script:Total += $freed
    if ($freed -gt 0) {
        $line = "  |  [FREED] $(Fmt $freed)  --  $label"
        Write-Host $line -ForegroundColor Green
    } else {
        $line = "  |  [CLEAN] Rien a nettoyer  --  $label"
        Write-Host $line -ForegroundColor DarkGray
    }
    $script:Log.Add($line)
}

function Write-Info([string]$msg) {
    $line = "  |  [INFO] $msg"
    Write-Host $line -ForegroundColor DarkYellow
    $script:Log.Add($line)
}

function Clear-Folder([string]$path, [string]$label, [string]$explication) {
    if (-not (Confirm-Task $label $explication)) { return }
    if (-not (Test-Path $path)) { Write-Done 0 $label; return }
    $before = Get-Size $path
    Get-ChildItem $path -Force -Recurse -EA SilentlyContinue |
        Remove-Item -Force -Recurse -EA SilentlyContinue
    Write-Done ($before - (Get-Size $path)) $label
}

function Show-Progress([string]$activity, [string]$status, [int]$pct) {
    Write-Progress -Activity "Shxdow Cleaner -- $activity" -Status $status -PercentComplete $pct
}
#endregion

#region CONFIRMATION
Write-Banner

Write-Host "  Ce tool va nettoyer en profondeur votre systeme Windows." -ForegroundColor Yellow
Write-Host "  Cree et maintenu par : $script:Author" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  Lancer le nettoyage complet ? [O/N] " -NoNewline -ForegroundColor Cyan
$go = Read-Host
if ($go -notmatch "^[Oo]$") { Write-Host "`n  Annule. -- Shxdow`n" -ForegroundColor DarkGray; exit }
Write-Host ""

$diskBefore = (Get-PSDrive C).Free
#endregion

#region MODULE 1 -- FICHIERS TEMPORAIRES
Write-Section "MODULE 1   Fichiers Temporaires"
Show-Progress "Fichiers Temporaires" "Nettoyage TEMP..." 5

Clear-Folder $env:TEMP "User TEMP" `
    "Fichiers temporaires crees par vos applis. 100% supprimables, regeneres automatiquement."

Clear-Folder "$env:SystemRoot\Temp" "System TEMP" `
    "Temp systeme de Windows. Meme principe que TEMP utilisateur, sans risque."

Clear-Folder "$env:SystemRoot\Prefetch" "Prefetch" `
    "Cache de pre-chargement des executables. Windows le reconstruit seul au prochain demarrage."

Clear-Folder "$env:APPDATA\Microsoft\Windows\Recent" "Recent Files" `
    "Raccourcis vers vos fichiers recents. Aucun fichier reel supprime, purement cosmetique."

if (Confirm-Task "Cache Internet Explorer / Edge Legacy" `
    "Fichiers mis en cache par IE et Edge Legacy. Inutiles si vous ne les utilisez plus.") {
    $ieTotal = 0
    @(
        "$env:LOCALAPPDATA\Microsoft\Windows\INetCache",
        "$env:LOCALAPPDATA\Microsoft\Windows\Temporary Internet Files",
        "$env:LOCALAPPDATA\Microsoft\Windows\WebCache"
    ) | ForEach-Object {
        if (Test-Path $_) {
            $b = Get-Size $_
            Get-ChildItem $_ -Force -Recurse -EA SilentlyContinue | Remove-Item -Force -Recurse -EA SilentlyContinue
            $ieTotal += $b - (Get-Size $_)
        }
    }
    Write-Done $ieTotal "IE / Edge Legacy Cache"
}

if (Confirm-Task "Fichiers *.tmp dans AppData" `
    "Fichiers .tmp laisses par des applis dans AppData. Supprimables si les applis sont fermees.") {
    $tmpTotal = 0
    Get-ChildItem "$env:APPDATA","$env:LOCALAPPDATA" -Recurse -Include "*.tmp","*.~*" -Force -EA SilentlyContinue |
        ForEach-Object { $tmpTotal += $_.Length; Remove-Item $_.FullName -Force -EA SilentlyContinue }
    Write-Done $tmpTotal "AppData *.tmp"
}
#endregion

#region MODULE 2 -- CACHE NAVIGATEURS & APPS
Write-Section "MODULE 2   Cache Navigateurs et Applications"
Show-Progress "Cache Apps" "Navigateurs..." 18

if (Confirm-Task "Google Chrome -- Cache complet" `
    "Cache web, GPU, Service Worker de Chrome. Mots de passe et favoris PAS touches.") {
    $chromeTotal = 0
    @(
        "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache",
        "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Code Cache",
        "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\GPUCache",
        "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Media Cache",
        "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Service Worker\CacheStorage",
        "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Application Cache"
    ) | ForEach-Object {
        if (Test-Path $_) {
            $b = Get-Size $_
            Get-ChildItem $_ -Recurse -Force -EA SilentlyContinue | Remove-Item -Force -Recurse -EA SilentlyContinue
            $chromeTotal += $b - (Get-Size $_)
        }
    }
    Write-Done $chromeTotal "Chrome Cache"
}

if (Confirm-Task "Microsoft Edge -- Cache complet" `
    "Cache web et GPU de Edge Chromium. Profil et favoris intacts.") {
    $edgeTotal = 0
    @(
        "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache",
        "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Code Cache",
        "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\GPUCache"
    ) | ForEach-Object {
        if (Test-Path $_) {
            $b = Get-Size $_
            Get-ChildItem $_ -Recurse -Force -EA SilentlyContinue | Remove-Item -Force -Recurse -EA SilentlyContinue
            $edgeTotal += $b - (Get-Size $_)
        }
    }
    Write-Done $edgeTotal "Edge Cache"
}

if (Confirm-Task "Mozilla Firefox -- Cache" `
    "Dossier cache2 de tous les profils Firefox. Pas les mots de passe.") {
    $ffTotal = 0
    $ffBase = "$env:APPDATA\Mozilla\Firefox\Profiles"
    if (Test-Path $ffBase) {
        Get-ChildItem $ffBase -Directory | ForEach-Object {
            $c = Join-Path $_.FullName "cache2"
            if (Test-Path $c) {
                $b = Get-Size $c
                Get-ChildItem $c -Recurse -Force -EA SilentlyContinue | Remove-Item -Force -Recurse -EA SilentlyContinue
                $ffTotal += $b - (Get-Size $c)
            }
        }
    }
    Write-Done $ffTotal "Firefox Cache"
}

if (Confirm-Task "Microsoft Teams -- Cache" `
    "Cache, GPUCache, IndexedDB de Teams. Peut peser plusieurs GB. Teams se reconnecte normalement.") {
    $teamsTotal = 0
    @(
        "$env:APPDATA\Microsoft\Teams\Cache",
        "$env:APPDATA\Microsoft\Teams\blob_storage",
        "$env:APPDATA\Microsoft\Teams\databases",
        "$env:APPDATA\Microsoft\Teams\GPUCache",
        "$env:APPDATA\Microsoft\Teams\IndexedDB",
        "$env:APPDATA\Microsoft\Teams\Local Storage",
        "$env:APPDATA\Microsoft\Teams\tmp"
    ) | ForEach-Object {
        if (Test-Path $_) {
            $b = Get-Size $_
            Get-ChildItem $_ -Force -Recurse -EA SilentlyContinue | Remove-Item -Force -Recurse -EA SilentlyContinue
            $teamsTotal += $b - (Get-Size $_)
        }
    }
    Write-Done $teamsTotal "Teams Cache"
}

if (Confirm-Task "Discord -- Cache" `
    "Cache, Code Cache et GPUCache de Discord. Aucune donnee de compte perdue.") {
    $discordTotal = 0
    @(
        "$env:APPDATA\discord\Cache",
        "$env:APPDATA\discord\Code Cache",
        "$env:APPDATA\discord\GPUCache"
    ) | ForEach-Object {
        if (Test-Path $_) {
            $b = Get-Size $_
            Get-ChildItem $_ -Force -Recurse -EA SilentlyContinue | Remove-Item -Force -Recurse -EA SilentlyContinue
            $discordTotal += $b - (Get-Size $_)
        }
    }
    Write-Done $discordTotal "Discord Cache"
}

if (Confirm-Task "Spotify -- Cache musique" `
    "Fichiers audio mis en cache. Re-streames a la prochaine ecoute. Playlists intactes.") {
    $spotifyTotal = 0
    @(
        "$env:LOCALAPPDATA\Spotify\Storage",
        "$env:LOCALAPPDATA\Spotify\Data"
    ) | ForEach-Object {
        if (Test-Path $_) {
            $b = Get-Size $_
            Get-ChildItem $_ -Force -Recurse -EA SilentlyContinue | Remove-Item -Force -Recurse -EA SilentlyContinue
            $spotifyTotal += $b - (Get-Size $_)
        }
    }
    Write-Done $spotifyTotal "Spotify Cache"
}

Clear-Folder "$env:LOCALAPPDATA\Steam\htmlcache" "Steam htmlcache" `
    "Cache du navigateur integre a Steam. Steam continue de fonctionner normalement."

Clear-Folder "$env:LOCALAPPDATA\Microsoft\Office\16.0\OfficeFileCache" "Office FileCache" `
    "Cache de synchronisation Office. Fichiers OneDrive et documents locaux non affectes."

Clear-Folder "$env:LOCALAPPDATA\Microsoft\Windows\Explorer" "Thumbnails" `
    "Cache des miniatures de l'Explorateur. Regenere automatiquement a la prochaine ouverture."
#endregion

#region MODULE 3 -- SYSTEME WINDOWS
Write-Section "MODULE 3   Systeme Windows"
Show-Progress "Systeme" "Disk Cleanup..." 35

if (Confirm-Task "Windows Disk Cleanup (29 categories)" `
    "Lance cleanmgr en mode silencieux sur 29 categories : fichiers setup, anciennes MAJ, etc.") {
    $sageset = 7331
    $regBase = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches"
    @(
        "Active Setup Temp Folders","BranchCache","D3D Shader Cache","Delivery Optimization Files",
        "Device Driver Packages","Downloaded Program Files","GameNewsFiles","GameStatisticsFiles",
        "GameUpdateFiles","Internet Cache Files","Memory Dump Files","Offline Pages Files",
        "Old ChkDsk Files","Previous Installations","Recycle Bin","Service Pack Cleanup",
        "Setup Log Files","System error memory dump files","System error minidump files",
        "Temporary Files","Temporary Setup Files","Temporary Sync Files","Thumbnail Cache",
        "Update Cleanup","Upgrade Discarded Files","User file versions","Windows Defender",
        "Windows Error Reporting Files","Windows ESD installation files"
    ) | ForEach-Object {
        $k = Join-Path $regBase $_
        if (Test-Path $k) { Set-ItemProperty -Path $k -Name "StateFlags$sageset" -Value 2 -Type DWord -EA SilentlyContinue }
    }
    $b4 = (Get-PSDrive C).Free
    Start-Process "cleanmgr.exe" -ArgumentList "/sagerun:$sageset" -Wait -WindowStyle Hidden -EA SilentlyContinue
    Write-Done ([Math]::Max(0,(Get-PSDrive C).Free - $b4)) "Windows Disk Cleanup"
}

if (Confirm-Task "Windows Update -- SoftwareDistribution Download" `
    "Fichiers telecharges par Windows Update deja installes. Service stoppe puis redemarre.") {
    Stop-Service wuauserv -Force -EA SilentlyContinue
    $wuB = Get-Size "$env:SystemRoot\SoftwareDistribution\Download"
    Remove-Item "$env:SystemRoot\SoftwareDistribution\Download\*" -Force -Recurse -EA SilentlyContinue
    Write-Done ($wuB - (Get-Size "$env:SystemRoot\SoftwareDistribution\Download")) "Windows Update Cache"
    Start-Service wuauserv -EA SilentlyContinue
}

if (Confirm-Task "Windows Error Reporting -- Rapports de crash" `
    "Rapports d'erreurs envoyes a Microsoft. Inutiles une fois generes.") {
    $werTotal = 0
    @(
        "$env:LOCALAPPDATA\Microsoft\Windows\WER",
        "$env:ProgramData\Microsoft\Windows\WER\ReportArchive",
        "$env:ProgramData\Microsoft\Windows\WER\ReportQueue"
    ) | ForEach-Object {
        if (Test-Path $_) {
            $b = Get-Size $_
            Get-ChildItem $_ -Recurse -Force -EA SilentlyContinue | Remove-Item -Force -Recurse -EA SilentlyContinue
            $werTotal += $b - (Get-Size $_)
        }
    }
    Write-Done $werTotal "WER Reports"
}

if (Confirm-Task "Memory Dumps (MEMORY.DMP + Minidump)" `
    "Fichiers generes lors d'un crash (ecran bleu). Peuvent peser plusieurs GB.") {
    $dumpTotal = 0
    @("$env:SystemRoot\MEMORY.DMP", "$env:SystemRoot\Minidump") | ForEach-Object {
        if (Test-Path $_) {
            $item = Get-Item $_ -Force -EA SilentlyContinue
            $s = if ($item.PSIsContainer) { Get-Size $_ } else { $item.Length }
            Remove-Item $_ -Force -Recurse -EA SilentlyContinue
            $dumpTotal += $s
        }
    }
    Write-Done $dumpTotal "Memory Dumps"
}

if (Confirm-Task "Event Logs -- Tous les journaux Windows" `
    "Vide l'integralite des journaux d'evenements Windows. Sans impact fonctionnel.") {
    $elBefore = (Get-WinEvent -ListLog * -EA SilentlyContinue | Measure-Object -Property FileSize -Sum).Sum
    wevtutil el 2>$null | ForEach-Object { wevtutil cl "$_" 2>$null }
    $elAfter  = (Get-WinEvent -ListLog * -EA SilentlyContinue | Measure-Object -Property FileSize -Sum).Sum
    Write-Done ([Math]::Max(0, $elBefore - $elAfter)) "Event Logs"
}

if (Confirm-Task "Logs CBS et Setup (Panther)" `
    "Logs generes lors de l'installation de Windows et des mises a jour.") {
    Clear-Folder "$env:SystemRoot\Logs\CBS" "CBS Logs" "Logs composant CBS."
    Clear-Folder "$env:SystemRoot\Panther" "Panther Setup Logs" "Logs setup Windows."
}

if (Confirm-Task "Logs systeme *.log / *.etl de plus de 30 jours" `
    "Fichiers de log systeme vieux de plus de 30 jours. Les logs recents sont conserves.") {
    $sysLogTotal = 0
    Get-ChildItem "$env:SystemRoot\Logs" -Recurse -Include "*.log","*.etl" -Force -EA SilentlyContinue |
        Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-30) } |
        ForEach-Object { $sysLogTotal += $_.Length; Remove-Item $_.FullName -Force -EA SilentlyContinue }
    Write-Done $sysLogTotal "System Logs anciens"
}

if (Confirm-Task "Anciens points de restauration" `
    "Supprime UNIQUEMENT le point de restauration le plus ancien. Le plus recent est conserve.") {
    $rpB = (Get-PSDrive C).Free
    vssadmin delete shadows /for=C: /oldest /quiet 2>$null
    Write-Done ([Math]::Max(0,(Get-PSDrive C).Free - $rpB)) "Old Restore Points"
}
#endregion

#region MODULE 4 -- REGISTRE ET DEMARRAGE
Write-Section "MODULE 4   Registre et Demarrage"
Show-Progress "Registre" "Nettoyage MRU..." 62

if (Confirm-Task "MRU -- Documents recents, Run, TypedPaths" `
    "Efface l'historique des fichiers recents et commandes dans Executer (Win+R). Purement cosmetique.") {
    @(
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\RecentDocs",
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\RunMRU",
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\TypedPaths"
    ) | ForEach-Object {
        if (Test-Path $_) { Remove-ItemProperty -Path $_ -Name * -Force -EA SilentlyContinue }
    }
    Write-Info "MRU nettoye"
}

if (Confirm-Task "Entrees de demarrage invalides (Run / RunOnce)" `
    "Supprime uniquement les entrees Run/RunOnce dont l'executable n'existe plus sur le disque.") {
    $removedRun = 0
    @(
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run",
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\RunOnce",
        "HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce"
    ) | ForEach-Object {
        if (Test-Path $_) {
            $props = Get-ItemProperty -Path $_ -EA SilentlyContinue
            $props.PSObject.Properties | Where-Object { $_.Name -notmatch "^PS" } | ForEach-Object {
                $exe = ($_.Value -split '"')[1]
                if ($exe -and -not (Test-Path $exe)) {
                    Remove-ItemProperty -Path $_ -Name $_.Name -Force -EA SilentlyContinue
                    $removedRun++
                }
            }
        }
    }
    Write-Info "$removedRun entree(s) invalide(s) supprimee(s) du demarrage"
}

if (Confirm-Task "Taches planifiees orphelines (audit)" `
    "Detecte les taches planifiees en etat Unknown. Rapport uniquement, aucune suppression.") {
    $orphans = (Get-ScheduledTask -EA SilentlyContinue | Where-Object { $_.State -eq 'Unknown' } | Measure-Object).Count
    Write-Info "$orphans tache(s) orpheline(s) detectee(s)"
}

if (Confirm-Task "Cache COM Add-ins Office" `
    "Supprime les entrees registre de cache des add-ins COM Office. Office les recharge au prochain lancement.") {
    Remove-Item "HKCU:\Software\Microsoft\Office\*\Common\AddIns" -Force -Recurse -EA SilentlyContinue
    Write-Info "Cache COM Add-ins nettoye"
}
#endregion

#region MODULE 5 -- RESEAU ET RAM
Write-Section "MODULE 5   Reseau et Memoire RAM"
Show-Progress "Reseau et RAM" "Flush DNS..." 72

if (Confirm-Task "Flush DNS Cache" `
    "Vide le cache DNS local. Utile si des sites ne se chargent plus correctement.") {
    ipconfig /flushdns | Out-Null
    Write-Info "Cache DNS vide"
}

if (Confirm-Task "Vider le cache ARP" `
    "Efface la table ARP locale. Regeneree automatiquement. Inoffensif sur un reseau domestique.") {
    netsh interface ip delete arpcache 2>$null | Out-Null
    Write-Info "Cache ARP vide"
}

if (Confirm-Task "Purge RAM Standby (Working Sets)" `
    "Force Windows a liberer la RAM mise en veille par les processus inactifs. Effet immediat mais temporaire.") {
    $code = @"
using System;using System.Runtime.InteropServices;
public class Shxdow {
    [DllImport("psapi.dll")] public static extern bool EmptyWorkingSet(IntPtr h);
}
"@
    try {
        Add-Type $code -EA SilentlyContinue
        $cleaned = 0
        Get-Process -EA SilentlyContinue | ForEach-Object {
            try { if ([Shxdow]::EmptyWorkingSet($_.Handle)) { $cleaned++ } } catch {}
        }
        Write-Info "Working Sets purges sur $cleaned processus"
    } catch {
        Write-Info "Non disponible sur cet OS"
    }
}
#endregion

#region MODULE 6 -- OPTIMISATION DISQUE
Write-Section "MODULE 6   Optimisation Disque"
Show-Progress "Disque" "TRIM / Defrag..." 80

if (Confirm-Task "TRIM SSD / Defrag HDD (tous volumes fixes)" `
    "Envoie un TRIM sur les SSD et optimise les HDD. Recommande mensuellement. Prend 1-3 min.") {
    Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Name -match '^[A-Z]$' } | ForEach-Object {
        $vol = Get-Volume -DriveLetter $_.Name -EA SilentlyContinue
        if ($vol -and $vol.DriveType -eq 'Fixed') {
            Write-Host "  |  Optimisation $($_.Name):\ ..." -ForegroundColor DarkGray -NoNewline
            Optimize-Volume -DriveLetter $_.Name -ReTrim -Verbose:$false -EA SilentlyContinue
            Write-Host " OK" -ForegroundColor Green
        }
    }
    Write-Info "Volumes optimises"
}

if (Confirm-Task "hiberfil.sys -- Rapport" `
    "Verifie si le fichier d'hibernation est actif. Info seulement. Pour desactiver : powercfg /h off") {
    $hib = "$env:SystemRoot\hiberfil.sys"
    if (Test-Path $hib) {
        $hibSize = (Get-Item $hib -Force -EA SilentlyContinue).Length
        Write-Info "hiberfil.sys present : $(Fmt $hibSize) -- desactiver avec 'powercfg /h off'"
    } else {
        Write-Info "hiberfil.sys absent -- hibernation desactivee"
    }
}
#endregion

#region MODULE 7 -- FTN
Write-Section "MODULE 7   FTN -- Fichiers Temporaires et Nuisibles"
Show-Progress "FTN" "Fichiers nuisibles..." 88

if (Confirm-Task "Fichiers .bak / .old / .orig de plus de 3 mois" `
    "Anciens fichiers de sauvegarde automatique dans Documents/AppData. Plus de 3 mois.") {
    $bakTotal = 0
    @("$env:USERPROFILE\Documents","$env:APPDATA","$env:LOCALAPPDATA") | ForEach-Object {
        Get-ChildItem $_ -Recurse -Include "*.bak","*.old","*.orig" -Force -EA SilentlyContinue |
            Where-Object { $_.LastWriteTime -lt (Get-Date).AddMonths(-3) } |
            ForEach-Object { $bakTotal += $_.Length; Remove-Item $_.FullName -Force -EA SilentlyContinue }
    }
    Write-Done $bakTotal "Fichiers .bak/.old/.orig"
}

if (Confirm-Task "Thumbs.db -- Miniatures cachees" `
    "Fichiers heritage de Windows XP/7. Inutiles sur Windows 10/11.") {
    $thumbTotal = 0
    Get-ChildItem "$env:USERPROFILE" -Recurse -Include "Thumbs.db","ehthumbs.db" -Force -EA SilentlyContinue |
        ForEach-Object { $thumbTotal += $_.Length; Remove-Item $_.FullName -Force -EA SilentlyContinue }
    Write-Done $thumbTotal "Thumbs.db"
}

if (Confirm-Task "Logs applicatifs *.log de plus de 30 jours" `
    "Fichiers .log laisses par des applications dans AppData/ProgramData. Vieux de plus de 30 jours.") {
    $appLog = 0
    @("$env:APPDATA","$env:LOCALAPPDATA","$env:PROGRAMDATA") | ForEach-Object {
        Get-ChildItem $_ -Recurse -Include "*.log" -Force -EA SilentlyContinue |
            Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-30) -and $_.Length -gt 10KB } |
            ForEach-Object { $appLog += $_.Length; Remove-Item $_.FullName -Force -EA SilentlyContinue }
    }
    Write-Done $appLog "App Logs anciens"
}

if (Confirm-Task "__pycache__ Python" `
    "Dossiers de bytecode compile Python. Recrees automatiquement a la prochaine execution.") {
    $pyTotal = 0
    Get-ChildItem "$env:USERPROFILE" -Recurse -Directory -Filter "__pycache__" -Force -EA SilentlyContinue |
        ForEach-Object { $s = Get-Size $_.FullName; Remove-Item $_.FullName -Force -Recurse -EA SilentlyContinue; $pyTotal += $s }
    Write-Done $pyTotal "__pycache__ Python"
}

Clear-Folder "$env:APPDATA\npm-cache" "npm cache" `
    "Cache des packages Node.js. Re-telecharges si besoin."

Clear-Folder "$env:LOCALAPPDATA\pip\cache" "pip cache" `
    "Cache des packages Python. Regenere a la prochaine installation de package."

Clear-Folder "$env:LOCALAPPDATA\NuGet\Cache" "NuGet cache" `
    "Cache des packages .NET NuGet. Re-telecharges si necessaire."

if (Confirm-Task "Fortnite -- Shader Cache et Pipeline Cache DX12" `
    "Cache de shaders DX12 compiles. Se regenere au prochain lancement (quelques stutters possibles la 1ere session).") {
    $fnShaderTotal = 0
    @(
        "$env:LOCALAPPDATA\FortniteGame\Saved\ShaderCache",
        "$env:LOCALAPPDATA\FortniteGame\Saved\PipelineCache"
    ) | ForEach-Object {
        if (Test-Path $_) {
            $b = Get-Size $_
            Get-ChildItem $_ -Recurse -Force -EA SilentlyContinue | Remove-Item -Force -Recurse -EA SilentlyContinue
            $fnShaderTotal += $b - (Get-Size $_)
        }
    }
    Write-Done $fnShaderTotal "Fortnite Shader / Pipeline Cache"
}

if (Confirm-Task "Fortnite -- Logs de crash et rapports" `
    "Anciens fichiers de log et rapports de crash Fortnite. Le log actif est conserve.") {
    $fnLogTotal = 0
    @(
        "$env:LOCALAPPDATA\FortniteGame\Saved\Logs",
        "$env:LOCALAPPDATA\FortniteGame\Saved\Crashes",
        "$env:LOCALAPPDATA\FortniteGame\Saved\Backup"
    ) | ForEach-Object {
        if (Test-Path $_) {
            $b = Get-Size $_
            Get-ChildItem $_ -Recurse -Force -EA SilentlyContinue |
                Where-Object { $_.Name -ne "FortniteGame.log" } |
                Remove-Item -Force -Recurse -EA SilentlyContinue
            $fnLogTotal += $b - (Get-Size $_)
        }
    }
    Write-Done $fnLogTotal "Fortnite Logs / Crashes"
}

if (Confirm-Task "EasyAntiCheat -- Logs et temporaires" `
    "Fichiers .log et .tmp laisses par EasyAntiCheat. Aucun impact sur le jeu.") {
    $eacTotal = 0
    Get-ChildItem "$env:ProgramData\Epic\EpicGamesLauncher\Data\EasyAntiCheat" -Recurse -Include "*.log","*.tmp" -Force -EA SilentlyContinue |
        ForEach-Object { $eacTotal += $_.Length; Remove-Item $_.FullName -Force -EA SilentlyContinue }
    Write-Done $eacTotal "EasyAntiCheat Logs"
}

if (Confirm-Task "Epic Games Launcher -- Cache et Logs" `
    "Cache web du launcher Epic, logs et rapports de crash. Launcher et Fortnite restent fonctionnels.") {
    $epicTotal = 0
    @(
        "$env:LOCALAPPDATA\EpicGamesLauncher\Saved\webcache",
        "$env:LOCALAPPDATA\EpicGamesLauncher\Saved\webcache_4147",
        "$env:LOCALAPPDATA\EpicGamesLauncher\Saved\Logs",
        "$env:LOCALAPPDATA\EpicGamesLauncher\Saved\Crashes",
        "$env:LOCALAPPDATA\EpicGamesLauncher\Saved\HttpRequestCache"
    ) | ForEach-Object {
        if (Test-Path $_) {
            $b = Get-Size $_
            Get-ChildItem $_ -Recurse -Force -EA SilentlyContinue | Remove-Item -Force -Recurse -EA SilentlyContinue
            $epicTotal += $b - (Get-Size $_)
        }
    }
    Write-Done $epicTotal "Epic Launcher Cache / Logs"
}

if (Confirm-Task "Corbeille" `
    "Vide definitivement la Corbeille. Les fichiers ne seront plus recuperables apres.") {
    $rbB = (Get-PSDrive C).Free
    Clear-RecycleBin -Force -EA SilentlyContinue
    Write-Done ([Math]::Max(0,(Get-PSDrive C).Free - $rbB)) "Corbeille"
}
#endregion

#region MODULE 8 -- SURFACE PRO 8 ET INTEL
Write-Section "MODULE 8   Surface Pro 8 et Intel -- Hardware Specific"
Show-Progress "Surface / Intel" "Logs materiel..." 93

Clear-Folder "C:\Intel\Logs" "Intel Driver Logs" `
    "Dossier de logs des drivers Intel. Residus post-installation."

if (Confirm-Task "Logs Intel racine C:\Intel -- .log .txt .xml .tmp" `
    "Fichiers de log et rapport a la racine C:\Intel laisses par les installeurs de drivers Intel.") {
    $intelRootTotal = 0
    Get-ChildItem "C:\Intel" -File -Force -EA SilentlyContinue |
        Where-Object { $_.Extension -match '\.(log|txt|xml|tmp)$' } |
        ForEach-Object { $intelRootTotal += $_.Length; Remove-Item $_.FullName -Force -EA SilentlyContinue }
    Write-Done $intelRootTotal "Intel Root Logs"
}

if (Confirm-Task "Cache Intel Graphics Iris Xe -- Shader Cache" `
    "Cache de shaders compiles par le driver graphique Intel Iris Xe. Regenere automatiquement.") {
    $igccTotal = 0
    @(
        "$env:LOCALAPPDATA\Intel\IGCC",
        "$env:LOCALAPPDATA\Intel\OneAPI",
        "$env:LOCALAPPDATA\Intel\ShaderCache",
        "$env:APPDATA\Intel\ShaderCache"
    ) | ForEach-Object {
        if (Test-Path $_) {
            $b = Get-Size $_
            Get-ChildItem $_ -Recurse -Force -EA SilentlyContinue | Remove-Item -Force -Recurse -EA SilentlyContinue
            $igccTotal += $b - (Get-Size $_)
        }
    }
    Write-Done $igccTotal "Intel Graphics Cache"
}

if (Confirm-Task "Logs Intel Management Engine de plus de 14 jours" `
    "Logs du composant Intel ME. Vieux de plus de 14 jours, sans utilite courante.") {
    $meTotal = 0
    @(
        "$env:ProgramData\Intel\Intel(R) ME Components",
        "$env:ProgramData\Intel\Intel Management Engine Components"
    ) | ForEach-Object {
        if (Test-Path $_) {
            Get-ChildItem $_ -Recurse -Include "*.log","*.tmp" -Force -EA SilentlyContinue |
                Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-14) } |
                ForEach-Object { $meTotal += $_.Length; Remove-Item $_.FullName -Force -EA SilentlyContinue }
        }
    }
    Write-Done $meTotal "Intel ME Logs"
}

Clear-Folder "$env:LOCALAPPDATA\Intel\DSA" "Intel DSA Cache" `
    "Cache de l'Intel Driver Support Assistant. Redetecte les drivers au prochain lancement."

if (Confirm-Task "Logs Intel Thunderbolt 4" `
    "Logs du controleur Thunderbolt 4 du Surface Pro 8. Aucun impact sur la connectivite.") {
    $tbTotal = 0
    @(
        "$env:ProgramData\Intel\Thunderbolt",
        "$env:LOCALAPPDATA\Intel\Thunderbolt"
    ) | ForEach-Object {
        if (Test-Path $_) {
            Get-ChildItem $_ -Recurse -Include "*.log","*.tmp" -Force -EA SilentlyContinue |
                ForEach-Object { $tbTotal += $_.Length; Remove-Item $_.FullName -Force -EA SilentlyContinue }
        }
    }
    Write-Done $tbTotal "Intel Thunderbolt Logs"
}

if (Confirm-Task "Logs drivers Surface (camera, tactile, stylet) de plus de 14 jours" `
    "Logs laisses par les drivers Microsoft Surface. Vieux de plus de 14 jours. Drivers restent actifs.") {
    $surfTotal = 0
    @(
        "$env:ProgramData\Microsoft\Surface",
        "$env:ProgramData\Microsoft\SurfaceDiagnosticApp",
        "$env:ProgramData\Microsoft\SurfaceHub"
    ) | ForEach-Object {
        if (Test-Path $_) {
            Get-ChildItem $_ -Recurse -Include "*.log","*.etl","*.tmp","*.cab" -Force -EA SilentlyContinue |
                Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-14) } |
                ForEach-Object { $surfTotal += $_.Length; Remove-Item $_.FullName -Force -EA SilentlyContinue }
        }
    }
    Write-Done $surfTotal "Surface Driver Logs"
}

if (Confirm-Task "Cache Surface Diagnostic Toolkit" `
    "Cache local de l'application Surface Diagnostic. Regenere au prochain lancement.") {
    $sdtTotal = 0
    Get-ChildItem "$env:LOCALAPPDATA\Packages\Microsoft.SurfaceDiagnosticApp*" -Directory -Force -EA SilentlyContinue | ForEach-Object {
        $cache = Join-Path $_.FullName "LocalCache"
        if (Test-Path $cache) {
            $b = Get-Size $cache
            Get-ChildItem $cache -Recurse -Force -EA SilentlyContinue | Remove-Item -Force -Recurse -EA SilentlyContinue
            $sdtTotal += $b - (Get-Size $cache)
        }
    }
    Write-Done $sdtTotal "Surface Diagnostic Cache"
}

if (Confirm-Task "Fichiers firmware Surface orphelins .cab .msu de plus de 30 jours" `
    "Residus de mises a jour firmware Surface deja installees. Sans utilite une fois appliques.") {
    $fwTotal = 0
    @("$env:SystemRoot\SoftwareDistribution\Download","$env:TEMP") | ForEach-Object {
        Get-ChildItem $_ -Recurse -Include "*.cab","*.msu" -Force -EA SilentlyContinue |
            Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-30) } |
            ForEach-Object { $fwTotal += $_.Length; Remove-Item $_.FullName -Force -EA SilentlyContinue }
    }
    Write-Done $fwTotal "Firmware Update orphelins"
}

if (Confirm-Task "Cache HID Device Metadata (Type Cover / Slim Pen 2)" `
    "Logs et tmp du cache de metadonnees peripheriques HID. Sans impact sur leur fonctionnement.") {
    $hidTotal = 0
    Get-ChildItem "$env:ProgramData\Microsoft\Windows\DeviceMetadataCache" -Recurse -Include "*.log","*.tmp" -Force -EA SilentlyContinue |
        ForEach-Object { $hidTotal += $_.Length; Remove-Item $_.FullName -Force -EA SilentlyContinue }
    Write-Done $hidTotal "HID Device Metadata Cache"
}

if (Confirm-Task "WinSAT DataStore -- anciens benchmarks" `
    "Garde les 2 benchmarks les plus recents, supprime les anciens. Aucun impact sur les performances.") {
    $winsatTotal = 0
    if (Test-Path "$env:SystemRoot\Performance\WinSAT\DataStore") {
        Get-ChildItem "$env:SystemRoot\Performance\WinSAT\DataStore" -File -Force -EA SilentlyContinue |
            Sort-Object LastWriteTime -Descending |
            Select-Object -Skip 2 |
            ForEach-Object { $winsatTotal += $_.Length; Remove-Item $_.FullName -Force -EA SilentlyContinue }
    }
    Write-Done $winsatTotal "WinSAT DataStore anciens"
}

if (Confirm-Task "Telemetry et DiagTrack -- Cache Windows / Surface" `
    "Cache de telemetrie Windows et Surface. Donnees deja envoyees a Microsoft, inutiles localement.") {
    $diagTotal = 0
    @(
        "$env:ProgramData\Microsoft\Diagnosis",
        "$env:ProgramData\Microsoft\Windows\DiagnosticInfrastructure",
        "$env:LOCALAPPDATA\Microsoft\Windows\DeliveryOptimization\Cache"
    ) | ForEach-Object {
        if (Test-Path $_) {
            $b = Get-Size $_
            Get-ChildItem $_ -Recurse -Force -EA SilentlyContinue | Remove-Item -Force -Recurse -EA SilentlyContinue
            $diagTotal += $b - (Get-Size $_)
        }
    }
    Write-Done $diagTotal "Telemetry / DiagTrack Cache"
}
#endregion

# Mthode native simplifie (plus stable)
if (Confirm-Task "Device Cleanup -- Peripheriques fantomes" "Supprime les peripheriques non connectes.") {
    $removed = 0
    try {
        # On rcupre les priphriques qui ne sont pas "Prsents"
        $phantoms = Get-PnpDevice -ErrorAction SilentlyContinue | Where-Object { $_.Present -eq $false }
        
        foreach ($dev in $phantoms) {
            # Suppression via l'InstanceId
            pnputil /remove-device $dev.InstanceId /force > $null
            $removed++
        }
        Write-Info "$removed peripherique(s) fantome(s) supprimes"
    } catch {
        Write-Warning "Erreur lors du nettoyage des peripheriques."
    }
}

#region RAPPORT ET BILAN
Write-Progress -Activity "Shxdow Cleaner" -Completed
$diskAfter = (Get-PSDrive C).Free
$realFreed = $diskAfter - $diskBefore
$elapsed   = (Get-Date) - $script:StartTime

$reportContent = @"
==============================================================
  SHXDOW CLEANER v$script:Ver -- RAPPORT DE NETTOYAGE
==============================================================

  Cree par    : $script:Author
  Date        : $(Get-Date -f 'dd/MM/yyyy HH:mm:ss')
  Duree       : $($elapsed.ToString('mm\:ss'))
  Ordinateur  : $env:COMPUTERNAME  ($env:USERNAME)
  OS          : $([System.Environment]::OSVersion.VersionString)

--------------------------------------------------------------
  RESUME
--------------------------------------------------------------
  Espace libre avant : $(Fmt $diskBefore)
  Espace libre apres : $(Fmt $diskAfter)
  Reellement libere  : $(Fmt $realFreed)

--------------------------------------------------------------
  DETAIL
--------------------------------------------------------------
$($script:Log -join "`n")

--------------------------------------------------------------
  by Shxdow -- ShxdowCleaner v$script:Ver
--------------------------------------------------------------
"@
$reportContent | Out-File $script:Report -Encoding UTF8

Clear-Host
Write-Host ""
Write-Host "  ======================================================" -ForegroundColor Cyan
Write-Host "      S H X D O W   C L E A N E R   v$script:Ver" -ForegroundColor Cyan
Write-Host "  ======================================================" -ForegroundColor DarkCyan
Write-Host ("  Espace reellement libere  :  {0}" -f (Fmt $realFreed)) -ForegroundColor Green
Write-Host ("  Duree d'execution         :  {0}" -f $elapsed.ToString('mm\:ss')) -ForegroundColor Yellow
Write-Host "  Rapport sauvegarde sur le Bureau" -ForegroundColor DarkGray
Write-Host "  ======================================================" -ForegroundColor DarkCyan
Write-Host "                   by  Shxdow" -ForegroundColor DarkGray
Write-Host "  ======================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  [!] Redemarrage recommande (Windows Update / Firmware Surface)" -ForegroundColor DarkYellow
Write-Host ""
Write-Host "  Redemarrer maintenant ? [O/N] " -NoNewline -ForegroundColor Cyan
if ((Read-Host) -match "^[Oo]$") {
    Write-Host "  Redemarrage dans 10s -- by Shxdow" -ForegroundColor Red
    Start-Sleep 10
    Restart-Computer -Force
}
Write-Host "  Merci d'avoir utilise Shxdow Cleaner." -ForegroundColor DarkGray
Write-Host ""
#endregion
