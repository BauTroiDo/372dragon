# CYS-PROJSIZE: hai canh A/B tren CUNG MOT binary, khac dung `CYS_RINGSIZE`.
# ASCII only. Moi luot vao THU MUC RIENG <nhan>-<HHmmss>; khong bao gio ghi de len luot truoc.
param([int]$Seconds = 200)
$ErrorActionPreference = 'Stop'
$root = 'C:\TLBB\085\CY-Source'
$stage = Join-Path $root 'Build\world-gui\stage-projsize'
$logs = Join-Path $root 'Build\Logs\2026-09-20-projsize'
$runner = Join-Path $root 'Tools\game\run_world_gui_live.ps1'
$env:PYTHONIOENCODING = 'utf-8'
# Bien nay thua ke qua ProcessStartInfo vi runner dung UseShellExecute=$false (auraring bay 5).
$env:CYS_AURARING_LIVE = '1'
$env:CYS_AURARING = '1'              # ban va ghep chi so cua auraring: BAT o CA HAI canh (da commit)
$env:CYS_AURARING_SWEEP = '300,1000,800'
# fps-move 20/09: hai dong "CYS-RINGSIZE" nam tren duong MOI KHUNG nen tu nay MAC DINH TAT (ban choi stage-play-5 ghi
# 124.132 dong / 19 phut). Bo do nay DOC chinh cac dong do => phai bat tuong minh, o CA HAI canh.
$env:CYS_RINGSIZE_LOG = '1'
$results = @()
foreach ($e in @(0, 1)) {
    $env:CYS_RINGSIZE = "$e"
    $tag = 'e' + $e + '-' + (Get-Date).ToString('HHmmss')
    $out = Join-Path $logs $tag
    Write-Host ("=== luot $tag : CYS_RINGSIZE=$e CYS_AURARING_SWEEP=" + $env:CYS_AURARING_SWEEP)
    & $runner -Stage $stage -OutDir $out -Seconds $Seconds -Account 'test02' -Role 'CYTest02'
    Write-Host ("luot $tag rc=$LASTEXITCODE")
    $results += $out
}
Remove-Item Env:CYS_RINGSIZE -ErrorAction SilentlyContinue
Remove-Item Env:CYS_RINGSIZE_LOG -ErrorAction SilentlyContinue
Write-Host '=== thu muc hai luot ==='
$results | ForEach-Object { Write-Host $_ }
