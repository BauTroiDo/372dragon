# CYS: parse measured phases only; absent log measurements remain null/empty.
function Get-CysViewerTimings {
    param([string]$LogPath, [string]$Stdout)

    $invariant = [Globalization.CultureInfo]::InvariantCulture
    $scripts = New-Object 'System.Collections.Generic.List[object]'
    $groups = New-Object 'System.Collections.Generic.Dictionary[string,string]' ([StringComparer]::Ordinal)
    $logText = ''
    $engineReady = $null
    $cache = $null
    if ($LogPath -and (Test-Path -LiteralPath $LogPath -PathType Leaf)) {
        # Engine resource names use GBK. Read only; never rewrite these logs.
        $logText = [IO.File]::ReadAllText($LogPath, [Text.Encoding]::GetEncoding(936))
    }
    foreach ($line in ($logText -split '\r?\n')) {
        $start = [regex]::Match($line, '\[TlbbViewer\] parsing script (.+) \(group (.+)\)\s*$')
        if ($start.Success) {
            $groups[$start.Groups[1].Value] = $start.Groups[2].Value
            continue
        }
        $done = [regex]::Match($line, '\[TlbbViewer\] (.+) parsed in (\d+) ms\s*$')
        if ($done.Success) {
            $name = $done.Groups[1].Value
            $group = $null
            if ($groups.ContainsKey($name)) {
                $group = $groups[$name]
                [void]$groups.Remove($name)
            }
            $scripts.Add([ordered]@{
                name = $name
                group = $group
                milliseconds = [int]::Parse($done.Groups[2].Value, $invariant)
            })
        }
    }
    # Prefer stdout, which also survives a missing engine log; use the last
    # reported total in each stream and fall back to the engine log if absent.
    foreach ($stream in @($Stdout, $logText)) {
        if ($null -eq $engineReady) {
            $ready = [regex]::Matches([string]$stream, 'engine ready in (\d+) ms\b')
            if ($ready.Count -gt 0) {
                $engineReady = [int]::Parse($ready[$ready.Count - 1].Groups[1].Value, $invariant)
            }
        }
        if ($null -eq $cache) {
            $hits = [regex]::Matches([string]$stream, 'shader cache hits (\d+)\s*/\s*misses (\d+)\b')
            if ($hits.Count -gt 0) {
                $last = $hits[$hits.Count - 1]
                $cache = [ordered]@{
                    hits = [int]::Parse($last.Groups[1].Value, $invariant)
                    misses = [int]::Parse($last.Groups[2].Value, $invariant)
                }
            }
        }
    }
    return [ordered]@{
        engine_ready_ms = $engineReady
        scripts = $scripts.ToArray()
        shader_cache = $cache
    }
}

function Get-CysOgreTimings {
    param([string]$Stdout)

    $invariant = [Globalization.CultureInfo]::InvariantCulture
    $bootstrap = $null
    $general = $null
    $cache = $null
    $number = '(\d+(?:\.\d+)?(?:[eE][+-]?\d+)?)'
    $phases = [regex]::Matches([string]$Stdout,
        ('resources: Bootstrap ' + $number + '\s+s, General ' + $number + '\s+s\b'))
    if ($phases.Count -gt 0) {
        $last = $phases[$phases.Count - 1]
        $bootstrap = 1000.0 * [double]::Parse($last.Groups[1].Value, $invariant)
        $general = 1000.0 * [double]::Parse($last.Groups[2].Value, $invariant)
    }
    # This is the scripts-phase total, before model-specific variants compile.
    $hits = [regex]::Matches([string]$Stdout,
        'shader cache after scripts: hits (\d+), misses \(compiled\) (\d+)\b')
    if ($hits.Count -gt 0) {
        $last = $hits[$hits.Count - 1]
        $cache = [ordered]@{
            hits = [int]::Parse($last.Groups[1].Value, $invariant)
            misses = [int]::Parse($last.Groups[2].Value, $invariant)
        }
    }
    return [ordered]@{
        bootstrap_ms = $bootstrap
        general_ms = $general
        shader_cache = $cache
    }
}
