# CY-Source Tools/perf/sample_load.ps1 - machine load while a perf run is going (perf-cy, 15/09/2026).
# Every -Every seconds: total CPU %, GPU 3D utilisation of the whole machine and of the measured process, count of
# compilers/linkers/other Game or viewer processes, and the three busiest processes. Stops after -Seconds or when
# the file -StopFile appears. ASCII only (Windows PowerShell 5.1).
param(
    [Parameter(Mandatory=$true)][string]$Out,
    [int]$Seconds = 180,
    [int]$Every = 2,
    [string]$StopFile = '',
    [string]$Watch = 'Game'
)
$ErrorActionPreference = 'SilentlyContinue'
$cores = [Environment]::ProcessorCount
$inv = [Globalization.CultureInfo]::InvariantCulture
$rows = New-Object 'System.Collections.Generic.List[string]'
$rows.Add('t_s,cpu_total_pct,gpu3d_total_pct,gpu3d_watch_pct,watch_cpu_pct,compilers,java,viewers,games,top1,top2,top3')
[IO.File]::WriteAllLines($Out, $rows)
$start = Get-Date
$prev = @{}
foreach ($p in Get-Process) { $prev[$p.Id] = $p.TotalProcessorTime.TotalMilliseconds }
$prevT = Get-Date
while (((Get-Date) - $start).TotalSeconds -lt $Seconds) {
    Start-Sleep -Seconds $Every
    if ($StopFile -and (Test-Path -LiteralPath $StopFile)) { break }
    $now = Get-Date; $dt = ($now - $prevT).TotalMilliseconds; $prevT = $now
    $procs = @(Get-Process)
    $use = @()
    $cur = @{}
    foreach ($p in $procs) {
        $ms = $p.TotalProcessorTime.TotalMilliseconds; $cur[$p.Id] = $ms
        if ($prev.ContainsKey($p.Id)) { $use += [pscustomobject]@{ n = $p.ProcessName; id = $p.Id; pct = 100.0 * ($ms - $prev[$p.Id]) / $dt / $cores } }
    }
    $prev = $cur
    $total = ($use | Measure-Object pct -Sum).Sum
    $watchIds = @($procs | Where-Object { $_.ProcessName -eq $Watch } | ForEach-Object { $_.Id })
    $watchCpu = ($use | Where-Object { $watchIds -contains $_.id } | Measure-Object pct -Sum).Sum
    $gpuAll = 0.0; $gpuWatch = 0.0
    try {
        $samples = (Get-Counter '\GPU Engine(*engtype_3D)\Utilization Percentage' -ErrorAction Stop).CounterSamples
        foreach ($s in $samples) {
            $gpuAll += $s.CookedValue
            foreach ($id in $watchIds) { if ($s.InstanceName -like ('pid_' + $id + '_*')) { $gpuWatch += $s.CookedValue } }
        }
    } catch { }
    $names = $procs | ForEach-Object { $_.ProcessName }
    $comp = @($names | Where-Object { $_ -in @('cl', 'link', 'ninja', 'cmake', 'MSBuild', 'lld-link', 'clang-cl') }).Count
    $java = @($names | Where-Object { $_ -eq 'java' }).Count
    $viewers = @($names | Where-Object { $_ -in @('TlbbViewer', 'OgreSmoke', 'CysUiViewer') }).Count
    $games = @($names | Where-Object { $_ -eq 'Game' }).Count
    $top = @($use | Where-Object { $_.n -ne 'Idle' } | Sort-Object pct -Descending | Select-Object -First 3 | ForEach-Object { [string]::Format($inv, '{0}:{1:F1}', $_.n, $_.pct) })
    while ($top.Count -lt 3) { $top += '' }
    $line = [string]::Format($inv, '{0:F1},{1:F1},{2:F1},{3:F1},{4:F1},{5},{6},{7},{8},{9},{10},{11}', [object[]]@(($now - $start).TotalSeconds, [double]$total, $gpuAll, $gpuWatch, [double]$watchCpu, $comp, $java, $viewers, $games, $top[0], $top[1], $top[2]))
    [IO.File]::AppendAllText($Out, $line + "`r`n")
}
