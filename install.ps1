#requires -Version 5.1
<#
.SYNOPSIS
  install.ps1 — symlink this repo's agent config back into your home directories.
  Native Windows counterpart of install.sh.

.DESCRIPTION
  Links created:
    ~\.agents\skills        ->  <repo>\skills          (skills, shared)
    ~\.claude\skills        ->  <repo>\skills          (skills, shared)
    ~\.claude\hooks         ->  <repo>\hooks
    ~\.claude\settings.json ->  <repo>\settings.json
    ~\.claude\CLAUDE.md     ->  <repo>\CLAUDE.md

  Symlink privileges: needs EITHER "Developer Mode" ON
  (Settings > Privacy & security > For developers) OR an elevated shell.
  If neither is present, this script self-elevates via UAC. Pass -NoElevate
  to instead open the Developer Mode settings page and exit.

  Safety (matches install.sh):
    * already a symlink   -> re-pointed
    * empty leftover dir  -> removed
    * real file/dir       -> moved to "<target>.backup" (timestamped if taken)

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File .\install.ps1
#>

[CmdletBinding()]
param(
  [switch]$NoElevate,
  [switch]$Elevated   # internal: set when this script re-launched itself via UAC
)

$ErrorActionPreference = 'Stop'

# ---- privilege check: Developer Mode OR Administrator ----------------------
function Test-DevMode {
  $key = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock'
  try {
    (Get-ItemProperty -Path $key -Name AllowDevelopmentWithoutDevLicense -ErrorAction Stop).AllowDevelopmentWithoutDevLicense -eq 1
  } catch { $false }
}
function Test-Admin {
  $id = [Security.Principal.WindowsIdentity]::GetCurrent()
  ([Security.Principal.WindowsPrincipal]$id).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-DevMode) -and -not (Test-Admin)) {
  if ($NoElevate) {
    Write-Host "Developer Mode is OFF and this shell is not elevated." -ForegroundColor Yellow
    Write-Host "Opening Developer settings - turn on 'Developer Mode', then re-run this script." -ForegroundColor Yellow
    Start-Process 'ms-settings:developers'
    exit 1
  }
  Write-Host "Need symlink privileges - relaunching as Administrator via UAC..." -ForegroundColor Yellow
  Start-Process -FilePath (Get-Process -Id $PID).Path -Verb RunAs -ArgumentList @(
    '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$PSCommandPath`"", '-Elevated'
  )
  exit
}

# ---- locate repo root (this script's directory) ---------------------------
$REPO   = $PSScriptRoot
$AGENTS = Join-Path $HOME '.agents'
$CLAUDE = Join-Path $HOME '.claude'

# ---- pretty output --------------------------------------------------------
function Write-Ok   ($m) { Write-Host "  + $m" -ForegroundColor Green }
function Write-Info ($m) { Write-Host "  . $m" -ForegroundColor DarkGray }
function Write-Warn ($m) { Write-Host "  ! $m" -ForegroundColor Yellow }
function Write-Err  ($m) { Write-Host "  x $m" -ForegroundColor Red }

$script:Failed = $false

function Test-IsSymlink ($path) {
  $item = Get-Item -LiteralPath $path -Force -ErrorAction SilentlyContinue
  $item -and $item.LinkType -eq 'SymbolicLink'
}
function Test-IsEmptyDir ($path) {
  (Test-Path -LiteralPath $path -PathType Container) -and
  -not (Get-ChildItem -LiteralPath $path -Force -ErrorAction SilentlyContinue)
}

# link_one <source-in-repo> <target-in-home>
function Link-One ($src, $dest) {
  if (-not (Test-Path -LiteralPath $src)) {
    Write-Warn "skip (source missing): $($src.Replace("$REPO\", ''))"
    return
  }

  $parent = Split-Path -Parent $dest
  if (-not (Test-Path -LiteralPath $parent)) {
    New-Item -ItemType Directory -Path $parent -Force | Out-Null
  }

  if (Test-IsSymlink $dest) {
    (Get-Item -LiteralPath $dest -Force).Delete()        # already a symlink -> re-point
  } elseif (Test-IsEmptyDir $dest) {
    Remove-Item -LiteralPath $dest -Force                # empty leftover dir -> drop it
  } elseif (Test-Path -LiteralPath $dest) {
    $backup = "$dest.backup"                             # real file/dir -> preserve it
    if (Test-Path -LiteralPath $backup) {
      $backup = "$dest.backup.$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    }
    Move-Item -LiteralPath $dest -Destination $backup
    Write-Info "backed up existing -> $backup"
  }

  try {
    New-Item -ItemType SymbolicLink -Path $dest -Target $src -ErrorAction Stop | Out-Null
    Write-Ok "$dest  ->  $($src.Replace("$REPO\", ''))"
  } catch {
    Write-Err "failed to link $dest"
    Write-Err "  enable Developer Mode or run this shell as Administrator"
    $script:Failed = $true
  }
}

# ---- run ------------------------------------------------------------------
Write-Host "Installing agent config" -ForegroundColor White
Write-Info "repo: $REPO"
Write-Host ""

Link-One (Join-Path $REPO 'skills')        (Join-Path $AGENTS 'skills')   # skills -> .agents
Link-One (Join-Path $REPO 'skills')        (Join-Path $CLAUDE 'skills')   # skills -> .claude
Link-One (Join-Path $REPO 'hooks')         (Join-Path $CLAUDE 'hooks')
Link-One (Join-Path $REPO 'settings.json') (Join-Path $CLAUDE 'settings.json')
Link-One (Join-Path $REPO 'CLAUDE.md')     (Join-Path $CLAUDE 'CLAUDE.md')

Write-Host ""
if (-not $script:Failed) {
  Write-Ok "Done. All links are in place."
} else {
  Write-Err "Finished with errors (see above)."
}

if ($Elevated) { Read-Host "Press Enter to close" | Out-Null }
if ($script:Failed) { exit 1 }
