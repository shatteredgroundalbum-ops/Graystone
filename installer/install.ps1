# Graystone per-user installer — no admin, no signing, no third-party tools.
# Copies the app into %LOCALAPPDATA%\Programs\Graystone and creates shortcuts.
param(
    [string]$Source = (Join-Path $PSScriptRoot 'app')
)

$ErrorActionPreference = 'Stop'
$AppName    = 'Graystone'
$Version    = '1.0.0'
$InstallDir = Join-Path $env:LOCALAPPDATA "Programs\$AppName"
$ExePath    = Join-Path $InstallDir 'graystone.exe'

if (-not (Test-Path (Join-Path $Source 'graystone.exe'))) {
    Write-Host "ERROR: graystone.exe not found in '$Source'." -ForegroundColor Red
    Write-Host "Run BUILD.bat first, or point -Source at the Release folder." -ForegroundColor Red
    exit 1
}

Write-Host "Installing $AppName to $InstallDir ..."

# Stop a running instance so files can be overwritten.
Get-Process graystone -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Milliseconds 300

if (Test-Path $InstallDir) { Remove-Item $InstallDir -Recurse -Force }
New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
Copy-Item -Path (Join-Path $Source '*') -Destination $InstallDir -Recurse -Force

# Bundle the uninstaller next to the app.
if (Test-Path (Join-Path $PSScriptRoot 'uninstall.ps1')) {
    Copy-Item (Join-Path $PSScriptRoot 'uninstall.ps1') (Join-Path $InstallDir 'uninstall.ps1') -Force
}

function New-Shortcut($linkPath) {
    $shell = New-Object -ComObject WScript.Shell
    $sc = $shell.CreateShortcut($linkPath)
    $sc.TargetPath       = $ExePath
    $sc.WorkingDirectory = $InstallDir
    $sc.IconLocation     = $ExePath
    $sc.Description       = 'Graystone AI Dev File Manager'
    $sc.Save()
}

$desktop   = [Environment]::GetFolderPath('Desktop')
$startMenu = [Environment]::GetFolderPath('Programs')
New-Shortcut (Join-Path $desktop   "$AppName.lnk")
New-Shortcut (Join-Path $startMenu "$AppName.lnk")

# Register in Add/Remove Programs (per-user).
$uninstKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$AppName"
New-Item -Path $uninstKey -Force | Out-Null
Set-ItemProperty -Path $uninstKey -Name DisplayName     -Value $AppName
Set-ItemProperty -Path $uninstKey -Name DisplayIcon     -Value $ExePath
Set-ItemProperty -Path $uninstKey -Name DisplayVersion  -Value $Version
Set-ItemProperty -Path $uninstKey -Name Publisher       -Value 'Graystone'
Set-ItemProperty -Path $uninstKey -Name InstallLocation -Value $InstallDir
Set-ItemProperty -Path $uninstKey -Name NoModify        -Value 1 -Type DWord
Set-ItemProperty -Path $uninstKey -Name NoRepair        -Value 1 -Type DWord
Set-ItemProperty -Path $uninstKey -Name UninstallString `
    -Value "powershell -ExecutionPolicy Bypass -File `"$InstallDir\uninstall.ps1`""

Write-Host ""
Write-Host "Done! $AppName is installed." -ForegroundColor Green
Write-Host "Launch it from the Desktop shortcut or Start Menu." -ForegroundColor Green
