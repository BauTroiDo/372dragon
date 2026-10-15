# CYS-PROJSIZE: ghi dong TRA khe. ASCII only.
param([Parameter(Mandatory=$true)][string]$Note)
$ErrorActionPreference = 'Stop'
$root = 'C:\TLBB\085\CY-Source'
$now = (Get-Date).ToString('HH:mm')
$line = @"

projsize | TRA khe ($now) | $Note Khe Game.exe rong ve phia toi. KHONG restart server, KHONG ghi Mongo. Bang chung: Build\Logs\2026-09-20-projsize
"@
Add-Content -LiteralPath (Join-Path $root 'Build\game-slot-queue.txt') -Value $line -Encoding UTF8
Write-Host 'DA GHI TRA khe.'
