param([Parameter(Mandatory=$true)][string]$OutDir, [string]$NativeTree = '',
    [string]$MeshBack = 'Assets\Canonical\Data\MaterialFolder\Common\MeshBack.dds',
    [switch]$Run, [switch]$RunOnly)
$ErrorActionPreference = 'Stop'
$root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
function Resolve-RepoBuildPath([string]$Value, [string]$RequiredParent) {
    if (-not [IO.Path]::IsPathRooted($Value)) { $Value = Join-Path $root $Value }
    $full = [IO.Path]::GetFullPath($Value)
    if (-not $full.StartsWith((Join-Path $root $RequiredParent)+'\',[StringComparison]::OrdinalIgnoreCase)) {
        throw ('Path must remain within repo '+$RequiredParent)
    }
    $cursor = $full
    while ($cursor) {
        $item = Get-Item -LiteralPath $cursor -Force -ErrorAction SilentlyContinue
        if ($item -and ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw 'Path must not traverse a junction.' }
        $cursor = Split-Path -Parent $cursor
    }
    return $full
}
$OutDir = Resolve-RepoBuildPath $OutDir 'Build'
if (-not $NativeTree) { $NativeTree = 'Build\cmake\ci-x64' }
$tree = Resolve-RepoBuildPath $NativeTree 'Build\cmake'
$exe = Join-Path $OutDir 'mesh_background_probe.exe'
if (-not $RunOnly) {
    if (Test-Path -LiteralPath $OutDir) { throw 'Choose a new output directory; preserve evidence.' }
    [void][IO.Directory]::CreateDirectory($OutDir)
    $env:TEMP = Join-Path $OutDir 'tmp'; $env:TMP = $env:TEMP
    [void][IO.Directory]::CreateDirectory($env:TEMP)
    . (Join-Path $root 'Tools\build\ci_common.ps1')
    Import-VcVars -VsPath (Find-VsBuildTools) -Arch x64
    $arguments = @('/nologo','/MD','/EHsc','/O2','/std:c++17','/utf-8','/DNOMINMAX',
        '/D_SILENCE_STDEXT_HASH_DEPRECATION_WARNINGS',
        ('/I'+(Join-Path $root 'Src\Engine\OGRE\OgreMain\include')),
        ('/I'+(Join-Path $root 'Src\Engine\WXRender')),
        ('/I'+(Join-Path $root 'Src\ThirdParty\boost')),
        ('/I'+(Join-Path $tree 'cys_boost_overlay')),('/Fo'+$OutDir+'\'),('/Fe'+$exe),
        (Join-Path $PSScriptRoot 'mesh_background_probe.cpp'),(Join-Path $tree 'lib\OgreMain.lib'),'user32.lib')
    $rc = Invoke-CmdLogged -CommandLine ('cl.exe '+(Join-CmdArgs $arguments)) -LogFile (Join-Path $OutDir 'build.log')
    if ($rc) { throw ('Probe compile failed: '+$OutDir) }
    Get-ChildItem -LiteralPath (Join-Path $root 'Build\Client\Bin64') -Filter '*.dll' | ForEach-Object {
        [IO.File]::Copy($_.FullName,(Join-Path $OutDir $_.Name))
    }
    foreach ($name in @('OgreMain.dll','RenderSystem_Direct3D9.dll')) {
        [IO.File]::Copy((Join-Path $tree ('bin\'+$name)),(Join-Path $OutDir $name),$true)
    }
    [void][IO.Directory]::CreateDirectory((Join-Path $OutDir 'Common'))
    if (-not [IO.Path]::IsPathRooted($MeshBack)) { $MeshBack = Join-Path $root $MeshBack }
    $asset = [IO.Path]::GetFullPath($MeshBack)
    if (-not $asset.StartsWith($root+'\',[StringComparison]::OrdinalIgnoreCase)) { throw 'MeshBack fixture must be in this repo.' }
    [IO.File]::Copy($asset,(Join-Path $OutDir 'Common\MeshBack.dds'))
    [void][IO.Directory]::CreateDirectory((Join-Path $OutDir 'Canonical'))
    [IO.File]::Copy((Join-Path $root 'Assets\Canonical\Data\MaterialFolder\Common\MeshBack.dds'),
        (Join-Path $OutDir 'Canonical\MeshBack.dds'))
    $metadata = [ordered]@{ build_rc=$rc; native_tree=$tree;
        source=(Get-FileHash -LiteralPath (Join-Path $PSScriptRoot 'mesh_background_probe.cpp')).Hash;
        implementation=(Get-FileHash -LiteralPath (Join-Path $root 'Src\Engine\WXRender\CysUiMeshBackground.h')).Hash;
        ogre=(Get-FileHash -LiteralPath (Join-Path $OutDir 'OgreMain.dll')).Hash;
        d3d9=(Get-FileHash -LiteralPath (Join-Path $OutDir 'RenderSystem_Direct3D9.dll')).Hash;
        meshback=(Get-FileHash -LiteralPath $asset).Hash; meshback_source=$asset.Substring($root.Length+1);
        canonical_meshback=(Get-FileHash -LiteralPath (Join-Path $root 'Assets\Canonical\Data\MaterialFolder\Common\MeshBack.dds')).Hash }
    [IO.File]::WriteAllText((Join-Path $OutDir 'build-result.json'),($metadata|ConvertTo-Json),(New-Object Text.UTF8Encoding($false)))
}
if (-not ($Run -or $RunOnly)) { Write-Host ('Built probe; GPU execution requires -RunOnly -OutDir '+$OutDir); return }
if (-not (Test-Path -LiteralPath $exe)) { throw 'Build the probe first.' }
if (Test-Path -LiteralPath (Join-Path $OutDir 'tests.log')) { throw 'This evidence directory already contains a run.' }
$start = New-Object Diagnostics.ProcessStartInfo
$start.FileName=$exe; $start.WorkingDirectory=$OutDir; $start.UseShellExecute=$false; $start.CreateNoWindow=$true
$start.RedirectStandardOutput=$true; $start.RedirectStandardError=$true
$process=New-Object Diagnostics.Process; $process.StartInfo=$start
try {
    if (-not $process.Start()) { throw 'Could not start native probe.' }
    $stdout=$process.StandardOutput.ReadToEndAsync(); $stderr=$process.StandardError.ReadToEndAsync()
    $timedOut = -not $process.WaitForExit(30000)
    if ($timedOut) { $process.Kill(); $process.WaitForExit() }
    $output=$stdout.GetAwaiter().GetResult()+$stderr.GetAwaiter().GetResult()
    [IO.File]::WriteAllText((Join-Path $OutDir 'tests.log'),$output,(New-Object Text.UTF8Encoding($false)))
    Write-Host $output
    $result=[ordered]@{ run_rc=$process.ExitCode; executable=(Get-FileHash -LiteralPath $exe).Hash;
        production_helper='Src/Engine/WXRender/CysUiMeshBackground.h'; gpu='D3D9'; hidden_owner=$true; timed_out=$timedOut }
    [IO.File]::WriteAllText((Join-Path $OutDir 'result.json'),($result|ConvertTo-Json),(New-Object Text.UTF8Encoding($false)))
    if ($timedOut) { throw ('Native probe timeout; output preserved: '+$OutDir) }
    if ($process.ExitCode) { throw ('Native probe failed: '+$OutDir) }
} finally { $process.Dispose() }
