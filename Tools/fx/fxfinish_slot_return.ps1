# CYS-FXFINISH: tra khe. CHAY KE CA KHI LUOT HONG (luat so khe: moi NHAN dung mot TRA).
# ASCII only.
param([string]$Note = '')
$ErrorActionPreference = 'Stop'
$root = 'C:\TLBB\085\CY-Source'
$now = (Get-Date).ToString('HH:mm')
$line = @"

fx-finish | TRA khe ($now) | hai luot replay ngoai tuyen xong. $Note
  Bang chung: Build\Logs\2026-09-20-fx-finish\ (ab-verdict.txt) va
  Build\Logs\2026-09-19-fx-cy-baseline\ours\b09-r6, b09-r7.
  KHONG restart server, KHONG ghi Mongo. Khe Game.exe rong ve phia toi.
"@
Add-Content -LiteralPath (Join-Path $root 'Build\game-slot-queue.txt') -Value $line -Encoding UTF8
Write-Host 'DA GHI TRA khe.'
