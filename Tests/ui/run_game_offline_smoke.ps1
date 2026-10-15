param(
    [Parameter(Mandatory=$true)][string]$Stage,
    [string]$OutDir = '',
    [ValidateRange(15,300)][int]$Seconds = 60
)
$ErrorActionPreference = 'Stop'
$root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
function InBuild([string]$path) {
    if (-not [IO.Path]::IsPathRooted($path)) { $path=Join-Path $root $path }
    $full=[IO.Path]::GetFullPath($path)
    if (-not $full.StartsWith((Join-Path $root 'Build')+'\',[StringComparison]::OrdinalIgnoreCase)) { throw 'Path must be inside CY-Source Build.' }
    $cursor=$full
    while ($cursor) {
        $item=Get-Item -LiteralPath $cursor -Force -ErrorAction SilentlyContinue
        if ($item -and ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw 'Do not traverse junctions.' }
        $cursor=Split-Path -Parent $cursor
    }
    return $full
}
$Stage=InBuild $Stage
if (-not $OutDir) { $OutDir='Build\Logs\game-offline-ui\'+(Get-Date -Format 'yyyyMMdd-HHmmss-fffffff') }
$OutDir=InBuild $OutDir
if (Test-Path -LiteralPath $OutDir) { throw 'Choose a new output path; preserve existing evidence.' }
$bin=Join-Path $Stage 'Bin64'
$manifest=Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $bin 'offline_stage.json') | ConvertFrom-Json
foreach ($f in $manifest.files) {
    if ([IO.Path]::GetFileName($f.name) -ne $f.name) { throw 'Invalid manifest filename.' }
    if ((Get-FileHash -LiteralPath (Join-Path $bin $f.name)).Hash.ToLowerInvariant() -ne $f.sha256) { throw ('Staged binary differs: '+$f.name) }
}
$game=Join-Path $bin 'Game.exe'
if (@($manifest.files | Where-Object { $_.name -eq 'Game.exe' -and $_.kind -eq 'ours' }).Count -ne 1) { throw 'Only the CI Game.exe is authorized.' }
$cfg=[IO.File]::ReadAllText((Join-Path $bin 'WXSystem.cfg'))
foreach ($setting in @('GameServer_Address=127.0.0.1','GameServer_Port=14400','GameServer_ConnectDirect=0','System_CodePage=65001')) {
    if (-not $cfg.Contains($setting)) { throw ('Offline configuration missing '+$setting) }
}
$login=[IO.File]::ReadAllText((Join-Path $Stage 'Patch\WXLoginServer.txt'))
if ($login -notmatch 'IP=127\.0\.0\.1\r?\nPORT=14400') { throw 'Dummy login endpoint missing.' }
# CYS: modern lists take precedence in Game; inspect every endpoint before launch.
$modernPath=Join-Path $Stage 'Patch\LoginServer.txt'
if (Test-Path -LiteralPath $modernPath) {
    $inside=$false; $modernRows=0
    foreach ($line in [IO.File]::ReadAllLines($modernPath)) {
        $text=$line.TrimStart()
        if ($text -eq 'SERVER_BEGIN') { $inside=$true; continue }
        if ($text -eq 'SERVER_END') { $inside=$false; continue }
        if (-not $inside -or -not $text -or $text.StartsWith('#')) { continue }
        $fields=$text.Split(',')
        if ($fields.Count -notin @(14,15)) { throw 'Invalid modern dummy login row.' }
        foreach ($index in 8..11) {
            if (($index -eq 8 -or $fields[$index]) -and $fields[$index] -ne '127.0.0.1:14400') { throw 'Modern login endpoint must be the dummy server.' }
        }
        if ($fields[12] -notin @('0','1')) { throw 'Offline smoke requires a normal region.' }
        $modernRows++
    }
    if ($modernRows -ne 1) { throw 'Offline smoke requires exactly one modern dummy server.' }
}
foreach ($helper in @('CrashReport.exe','Helper.exe')) {
    if (Test-Path -LiteralPath (Join-Path $bin $helper)) { throw ('Unexpected helper: '+$helper) }
}
[void][IO.Directory]::CreateDirectory($OutDir)
$env:TEMP=Join-Path $OutDir 'tmp';$env:TMP=$env:TEMP
[void][IO.Directory]::CreateDirectory($env:TEMP)
$before=@(Get-ChildItem -LiteralPath (Join-Path $Stage 'ScreenShots') -Filter 'cys-ui-*.png' -ErrorAction SilentlyContinue | ForEach-Object Name)
$arguments='-fl -cys-offline-ui-smoke'
$started=Get-Date
$connections=New-Object 'System.Collections.Generic.List[object]'
$terminated=$false;$process=$null
try {
    $process=Start-Process -FilePath $game -ArgumentList $arguments -WorkingDirectory $bin -WindowStyle Hidden -PassThru
    while (-not $process.HasExited -and (Get-Date) -lt $started.AddSeconds($Seconds)) {
        Start-Sleep -Seconds 2
        $process.Refresh()
        if ($process.HasExited) { break }
        foreach ($socket in @(Get-NetTCPConnection -OwningProcess $process.Id -ErrorAction SilentlyContinue)) {
            $connections.Add([ordered]@{remote=$socket.RemoteAddress;port=$socket.RemotePort;state=[string]$socket.State})
            if ($socket.RemoteAddress -notin @('0.0.0.0','::','127.0.0.1','::1')) { throw 'Unexpected external connection from the offline Game.' }
        }
    }
} finally {
    if ($process -and -not $process.HasExited) { $process.Kill();$process.WaitForExit();$terminated=$true }
    foreach ($name in @('WXClient.log','WXRender.log','UISystem.log','Ogre.log','WXC_SML.TXT')) {
        $path=Join-Path $bin $name
        if (Test-Path -LiteralPath $path) { Copy-Item -LiteralPath $path -Destination $OutDir }
    }
    $shots=@(Get-ChildItem -LiteralPath (Join-Path $Stage 'ScreenShots') -Filter 'cys-ui-*.png' -ErrorAction SilentlyContinue | Where-Object { $_.Name -notin $before })
    $records=@(foreach ($shot in $shots) {
        Copy-Item -LiteralPath $shot.FullName -Destination $OutDir
        [ordered]@{name=$shot.Name;sha256=(Get-FileHash -LiteralPath $shot.FullName).Hash;bytes=$shot.Length}
    })
    $run=[ordered]@{sha=$manifest.sha;started=$started.ToString('o');finished=(Get-Date).ToString('o');command=$game+' '+$arguments;cwd=$bin;terminated_after_timeout=$terminated;pid=$null;exit_code=$null;shots=$records;sockets=$connections.ToArray()}
    if ($process) { $run.pid=$process.Id;$run.exit_code=$process.ExitCode;$process.Dispose() }
    [IO.File]::WriteAllText((Join-Path $OutDir 'run.json'),($run|ConvertTo-Json -Depth 6),(New-Object Text.UTF8Encoding($false)))
}
$log=[IO.File]::ReadAllText((Join-Path $OutDir 'WXClient.log'))
if (-not $terminated -or $records.Count -ne 2 -or $log.Contains('fatal exception') -or -not $log.Contains('capture=1')) {
    throw ('Offline Game did not meet the runtime gate; see '+$OutDir)
}
Write-Host ('Game survived '+$Seconds+' seconds, two back-buffer captures saved. Inspect their contents: '+$OutDir)
