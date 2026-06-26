# Graystone per-user uninstaller — removes shortcuts, registry entry, and files.
$ErrorActionPreference = 'SilentlyContinue'
$AppName    = 'Graystone'
$InstallDir = Join-Path $env:LOCALAPPDATA "Programs\$AppName"
$desktop    = [Environment]::GetFolderPath('Desktop')
$startMenu  = [Environment]::GetFolderPath('Programs')

Write-Host "Uninstalling $AppName ..."

Get-Process graystone -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Milliseconds 300

Remove-Item (Join-Path $desktop   "$AppName.lnk") -Force
Remove-Item (Join-Path $startMenu "$AppName.lnk") -Force
Remove-Item "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$AppName" -Recurse -Force

# Delete the install folder after this script (which lives inside it) exits.
Start-Process powershell -WindowStyle Hidden -ArgumentList `
    "-NoProfile -Command Start-Sleep 1; Remove-Item -LiteralPath '$InstallDir' -Recurse -Force"

Write-Host "$AppName has been removed."
