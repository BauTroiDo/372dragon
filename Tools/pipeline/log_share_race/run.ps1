param([ValidateRange(0,2000)][int]$PollMs=0,[string]$OutRoot)
$ErrorActionPreference='Stop'
$repo=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../..'))
$build=[IO.Path]::GetFullPath((Join-Path $repo 'Build'))
if(-not $OutRoot) { $OutRoot=Join-Path $build ('Logs/log-share-race/run-'+(Get-Date -Format 'yyyyMMdd-HHmmss-ffff')) }
$out=[IO.Path]::GetFullPath($OutRoot)
if(-not $out.StartsWith($build+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)) { throw 'Output must be a fresh directory within repository Build.' }
if(Test-Path -LiteralPath $out) { throw 'Output already exists; evidence is immutable.' }
[void][IO.Directory]::CreateDirectory($out)
$vcvars='C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvarsall.bat'
if(-not (Test-Path -LiteralPath $vcvars)) { throw 'MSVC 2022 BuildTools x64 is required.' }
$compile=Join-Path $out 'compile.cmd'
$writer=Join-Path $out 'writer.exe'
$source=Join-Path $PSScriptRoot 'writer.cpp'
$commands=@('@echo off',('call "{0}" x64 >nul' -f $vcvars),'if errorlevel 1 exit /b 1',('cl /nologo /O2 /MD /W4 /D_CRT_SECURE_NO_WARNINGS "{0}" /Fe:"{1}" /Fo:"{2}"' -f $source,$writer,(Join-Path $out 'writer.obj')))
[IO.File]::WriteAllLines($compile,$commands,[Text.Encoding]::ASCII)
& cmd.exe /d /c $compile 2>&1 | Tee-Object -FilePath (Join-Path $out 'compile.log')
if($LASTEXITCODE -ne 0) { throw 'Native writer compilation failed.' }
$rows=@()
foreach($mode in @('ReadAllText-default','ReadWrite-stream')) {
    $dir=Join-Path $out $mode
    [void][IO.Directory]::CreateDirectory($dir)
    $path=Join-Path $dir 'WXClient.log'
    [IO.File]::WriteAllText($path,"SENTINEL_START`n")
    $info=[Diagnostics.ProcessStartInfo]::new($writer)
    $info.WorkingDirectory=$dir; $info.UseShellExecute=$false; $info.CreateNoWindow=$true
    $process=[Diagnostics.Process]::Start($info)
    $reads=0; $readErrors=0
    while(-not $process.HasExited) {
        if($PollMs -gt 0) { Start-Sleep -Milliseconds $PollMs }
        try {
            if($mode -eq 'ReadAllText-default') { $data=[IO.File]::ReadAllText($path) }
            else {
                $stream=[IO.FileStream]::new($path,[IO.FileMode]::Open,[IO.FileAccess]::Read,([IO.FileShare]::ReadWrite -bor [IO.FileShare]::Delete))
                try { $reader=[IO.StreamReader]::new($stream); try { $data=$reader.ReadToEnd() } finally { $reader.Dispose() } } finally { $stream.Dispose() }
            }
            ++$reads
        } catch { ++$readErrors }
        $process.Refresh()
    }
    $process.WaitForExit(); $exitCode=$process.ExitCode; $process.Dispose()
    $final=[IO.File]::ReadAllText($path)
    $stats=Get-Content -Raw -LiteralPath (Join-Path $dir 'stats.json') | ConvertFrom-Json
    $seq=[regex]::Matches($final,'SEQ=(\d+)')
    $rows += [ordered]@{mode=$mode;poll_ms=$PollMs;reader_success=$reads;reader_errors=$readErrors;writer_exit=$exitCode;stats=$stats;sentinel_preserved=$final.StartsWith('SENTINEL_START');retained_lines=$seq.Count;first_sequence=if($seq.Count){[int]$seq[0].Groups[1].Value}else{$null};last_sequence=if($seq.Count){[int]$seq[$seq.Count-1].Groups[1].Value}else{$null};log_bytes=(Get-Item -LiteralPath $path).Length}
}
$rows | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $out 'result.json') -Encoding utf8
$rows | ConvertTo-Json -Depth 5
Write-Output $out

$after=$rows | Where-Object { $_.mode -eq 'ReadWrite-stream' }
if($after.stats.append_failed -ne 0 -or $after.stats.fallback_opened_truncates -ne 0 -or -not $after.sentinel_preserved -or $after.retained_lines -ne $after.stats.attempted) { throw 'Shared reader lost evidence.' }
