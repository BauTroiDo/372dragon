param([string]$OutDir = '', [string]$NativeTree = 'Build\cmake\host-2-x64')
$ErrorActionPreference = 'Stop'
$root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
if (-not $OutDir) { $OutDir = Join-Path $root ('Build\Logs\2026-09-19-metatable-sweep\probe-'+(Get-Date -Format 'yyyyMMdd-HHmmss')) }
$OutDir = [IO.Path]::GetFullPath($OutDir)
if (-not $OutDir.StartsWith((Join-Path $root 'Build')+'\',[StringComparison]::OrdinalIgnoreCase)) { throw 'Output must be inside repo Build.' }
if (Test-Path -LiteralPath $OutDir) { throw 'Choose a new output path; preserve old evidence.' }
[void][IO.Directory]::CreateDirectory($OutDir)
$env:TEMP = Join-Path $OutDir 'tmp'; $env:TMP = $env:TEMP
[void][IO.Directory]::CreateDirectory($env:TEMP)
. (Join-Path $root 'Tools\build\ci_common.ps1')
Import-VcVars -VsPath (Find-VsBuildTools) -Arch x64
$tree = [IO.Path]::GetFullPath((Join-Path $root $NativeTree))
if (-not $tree.StartsWith((Join-Path $root 'Build\cmake')+'\',[StringComparison]::OrdinalIgnoreCase)) { throw 'Native tree must be inside repo Build/cmake.' }
$cegui = Join-Path $root 'Src\ThirdParty\CEGUI-0.4.1\CEGUI\include'
$ft = Join-Path $root 'Src\ThirdParty\FreeType\include'
$exe = Join-Path $OutDir 'metatable_cast_probe.exe'
$args = @('/nologo','/MD','/EHsc','/O2','/std:c++14','/source-charset:utf-8','/execution-charset:.936',
          ('/I'+$cegui),('/I'+$ft),
          ('/I'+(Join-Path $root 'Src\Client\CEGUIFalagardEx')),
          ('/I'+(Join-Path $root 'Src\ThirdParty\CEGUI-0.4.1\CEGUI\WidgetSets\Falagard\include')),
          ('/Fo'+$OutDir+'\'),('/Fe'+$exe),
          (Join-Path $PSScriptRoot 'metatable_cast_probe.cpp'),
          (Join-Path $tree 'lib\CEGUIBase.lib'),(Join-Path $tree 'lib\CEGUIFalagard.lib'),'normaliz.lib')
$rc = Invoke-CmdLogged -CommandLine ('cl.exe '+(Join-CmdArgs $args)) -LogFile (Join-Path $OutDir 'build.log')
if ($rc) { throw ('Probe compile failed; see '+$OutDir) }
foreach ($name in @('CEGUIBase.dll','CEGUIFalagard.dll')) {
    [IO.File]::Copy((Join-Path $tree ('bin\'+$name)),(Join-Path $OutDir $name),$true)
}
$start = New-Object Diagnostics.ProcessStartInfo
$start.FileName=$exe; $start.WorkingDirectory=$OutDir; $start.UseShellExecute=$false; $start.CreateNoWindow=$true
$start.Arguments=Join-CmdArgs @((Join-Path $root 'Assets\CanonicalCY\Data\InterfaceFolder\Schema\NotoSansSC-Regular.ttf'))
$start.RedirectStandardOutput=$true; $start.RedirectStandardError=$true
$process=New-Object Diagnostics.Process; $process.StartInfo=$start
try {
    if (-not $process.Start()) { throw 'Could not start the probe.' }
    $stdout=$process.StandardOutput.ReadToEndAsync(); $stderr=$process.StandardError.ReadToEndAsync()
    if (-not $process.WaitForExit(60000)) { $process.Kill(); $process.WaitForExit(); throw 'Probe timeout.' }
    $output=$stdout.GetAwaiter().GetResult()+$stderr.GetAwaiter().GetResult()
    [IO.File]::WriteAllText((Join-Path $OutDir 'probe.log'),$output,(New-Object Text.UTF8Encoding($false)))
    Write-Host $output
    $result=[ordered]@{build_rc=$rc;run_rc=$process.ExitCode;
        source=(Get-FileHash -LiteralPath (Join-Path $PSScriptRoot 'metatable_cast_probe.cpp')).Hash;
        cegui_base=(Get-FileHash -LiteralPath (Join-Path $OutDir 'CEGUIBase.dll')).Hash;
        cegui_falagard=(Get-FileHash -LiteralPath (Join-Path $OutDir 'CEGUIFalagard.dll')).Hash;
        out=$OutDir;native_tree=$tree}
    [IO.File]::WriteAllText((Join-Path $OutDir 'result.json'),($result|ConvertTo-Json),(New-Object Text.UTF8Encoding($false)))
    if ($process.ExitCode) { throw ('Probe reported a failed check: '+$OutDir) }
} finally { $process.Dispose() }
