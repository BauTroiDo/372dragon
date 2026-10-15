# Chạy bộ ca đối chứng (cases.json) bằng TlbbViewer và lưu ảnh vào ours\<nhãn>\.
# Cách dùng:
#   powershell -NoProfile -File run_ours.ps1 [-Viewer <đường dẫn TlbbViewer.exe>] [-Label <tên>] [-Kind all|model|effect|scene] [-Max N]
param(
    [string]$Viewer = 'C:\TLBB\085\CY-Source\Build\cmake\viewer-x64\bin\TlbbViewer.exe',
    [string]$Label = (Get-Date -Format 'yyyyMMdd-HHmm'),
    [ValidateSet('all', 'model', 'effect', 'scene')][string]$Kind = 'all',
    [int]$Max = 0,
    [string]$Size = '1280x720'
)
$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$cases = Get-Content -Raw -Encoding UTF8 (Join-Path $here 'cases.json') | ConvertFrom-Json
$out = Join-Path $here ("ours\" + $Label)
New-Item -ItemType Directory -Force $out | Out-Null
$rows = New-Object System.Collections.Generic.List[string]
$rows.Add("id`tkind`tname`texit`tseconds")

function Invoke-Case($id, $kind, $name, $argList) {
    $png = Join-Path $out ($id + '.png')
    $sw = [Diagnostics.Stopwatch]::StartNew()
    $p = Start-Process -FilePath $Viewer -ArgumentList ($argList + @('--shot', "`"$png`"", '--size', $Size)) `
        -WorkingDirectory (Split-Path -Parent $Viewer) -Wait -PassThru -WindowStyle Hidden
    $sw.Stop()
    $rows.Add(("{0}`t{1}`t{2}`t{3}`t{4:N1}" -f $id, $kind, $name, $p.ExitCode, $sw.Elapsed.TotalSeconds))
}

$n = 0
if ($Kind -in 'all', 'model') {
    foreach ($m in $cases.models) {
        if ($Max -and $n -ge $Max) { break }; $n++
        $a = @('--model', "`"$($m.obj)`"", '--frames', '30', '--dt', '0.033')
        if ($m.anim) { $a += @('--anim', "`"$($m.anim)`"") }
        Invoke-Case $m.id 'model' $m.obj $a
    }
}
if ($Kind -in 'all', 'effect') {
    foreach ($e in $cases.effects) {
        if ($Max -and $n -ge $Max) { break }; $n++
        Invoke-Case $e.id 'effect' $e.effect @('--effect', "`"$($e.effect)`"", '--frames', '60', '--dt', '0.033')
    }
}
if ($Kind -in 'all', 'scene') {
    foreach ($s in $cases.scenes) {
        if ($Max -and $n -ge $Max) { break }; $n++
        Invoke-Case $s.id 'scene' $s.scene @('--scene', "`"$($s.scene)`"", '--frames', '30', '--dt', '0.033')
    }
}
[IO.File]::WriteAllLines((Join-Path $out 'run.tsv'), $rows, (New-Object Text.UTF8Encoding($true)))
"Xong: $($rows.Count - 1) ca -> $out"
