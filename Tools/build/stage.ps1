<#
.SYNOPSIS
  Assembles a runnable x64 layout (default Build\Client\Bin64) from a CMake build tree (default Build\cmake\ci-x64).
.DESCRIPTION
  Copies into Bin64:
    - every *.dll / *.exe of <Tree>\bin: Game.exe (when built), TlbbViewer.exe, OgreSmoke.exe, test apps, OgreMain,
      RenderSystem_Direct3D9, plugins, and the x64 cg.dll that Plugin_CgProgramManager's POST_BUILD copies into
      bin (fallback: CYS_CG_DLL of the tree's CMakeCache.txt);
    - vendor runtime: d3dx9_43.dll + D3DCompiler_43.dll from %SystemRoot%\System32, fmod.dll + fmodL.dll from the
      FMOD SDK (main tree Src\ThirdParty\_sdk\fmod\api\core\lib\x64);
    - Scorpio media (<tree source dir>\Engine\Scorpio\media -> Bin64\Media\Scorpio).
  PDBs of <Tree>\bin go to Build\Symbols\ci (smoke.ps1 points _NT_SYMBOL_PATH there).
  Game data is never copied: Assets\CanonicalCY\Data (CY 3.71; since ci-cy 14/09/2026 the only data the CI binaries
  run on, see Get-CysDataDir in ci_common.ps1) or an explicit -Data, used READ-ONLY through --data. Stage fails with
  a clear message when CanonicalCY is absent or incomplete; there is no client_GL / Canonical (GL) fallback. The
  choice is recorded in Bin64\cys_stage.json (data_dir, data_reason, sha, CI status per file, hashes) and in
  Run-TlbbViewer.cmd / Run-OgreSmoke.cmd. The resource layout is built into the viewer and OgreSmoke (data via
  --data); the only config file read is WXTerrainType.cfg from the working directory (copied from the CY 3.71
  Bin64\TerrainTypeInfo.cfg, byte-identical to client_GL's, which is the fallback).
  Bin64\ShaderCache and logs are kept unless -Clean.
.EXAMPLE
  powershell -NoProfile -ExecutionPolicy Bypass -File C:\TLBB\085\CY-Source\Tools\build\stage.ps1
.EXAMPLE
  powershell -NoProfile -ExecutionPolicy Bypass -File C:\TLBB\085\CY-Source\Tools\build\stage.ps1 -Tree Build\cmake\mat-x64
.NOTES
  Exit codes: 0 staged, 1 staged with problems (missing runtime or tool, non-x64 file), 2 error, 3 CI busy.
#>
param(
    [string]$Tree = '',
    [string]$Out = '',
    [string]$Symbols = '',
    [string]$Data = '',
    [switch]$Clean,
    [string]$Root = ''
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'ci_common.ps1')
# CYS: -Root = main tree when this copy runs from a branch worktree (Build\ci, Build\Client\Bin64, Assets of main).
if ($Root) { $script:CysRoot = (Resolve-Path -LiteralPath $Root).Path }
$P = Get-CysPaths
if (-not $Tree) { $Tree = $P.Tree } elseif (-not [System.IO.Path]::IsPathRooted($Tree)) { $Tree = Join-Path $P.Root $Tree }
if (-not $Out) { $Out = $P.Bin64 }
if (-not $Symbols) { $Symbols = $P.Symbols }

Enter-CysLock 'stage' @('tree', 'bin64')
$exitCode = 2
try {
    if (-not (Test-Path -LiteralPath $Tree)) { throw ('build tree not found: ' + $Tree) }
    $Tree = (Resolve-Path -LiteralPath $Tree).Path
    $bin = Join-Path $Tree 'bin'
    if (-not (Test-Path -LiteralPath $bin)) { throw ('no bin folder in ' + $Tree) }
    $problems = New-Object System.Collections.Generic.List[string]
    $entries = New-Object System.Collections.Generic.List[object]

    # ---- source revision of the tree (CMAKE_HOME_DIRECTORY = <checkout>\Src)
    $srcDir = Get-CMakeCacheValue $Tree 'CMAKE_HOME_DIRECTORY'
    $sha = $null
    $short = $null
    $srcDirty = $null
    if ($srcDir) {
        $srcDir = $srcDir.Replace('/', '\')
        if (Test-Path -LiteralPath $srcDir) {
            $g = Invoke-Exe git @('-C', $srcDir, 'rev-parse', 'HEAD')
            if ($g.Rc -eq 0 -and $g.Out.Count) {
                $sha = $g.Out[-1].Trim()
                $short = (Invoke-Exe git @('-C', $srcDir, 'rev-parse', '--short', $sha)).Out[-1].Trim()
                $st = @((Invoke-Exe git @('-C', $srcDir, 'status', '--porcelain', '--untracked-files=no', '--', '.')).Out | Where-Object { $_ })
                $srcDirty = ($st.Count -gt 0)
            }
        }
    }

    # ---- CI summary of the same commit + tree (per-file target status)
    $ci = $null
    $ciPath = $null
    if ($short -and -not $srcDirty) {
        $cand = Join-Path $P.LogsCi (Join-Path $short 'summary.json')
        $j = Read-JsonFile $cand
        if ($j -and $j.tree -and (Test-Path -LiteralPath $j.tree) -and ((Resolve-Path -LiteralPath $j.tree).Path -eq $Tree)) {
            $ci = $j
            $ciPath = $cand
        }
    }
    $targetStatus = @{}
    if ($ci -and $ci.targets) {
        foreach ($t in $ci.targets) {
            foreach ($a in @($t.artifacts)) { $targetStatus[(Split-Path $a -Leaf).ToLower()] = ($t.status + ' (' + $t.name + ')') }
        }
    }

    # ---- data folder (read-only, never copied): CanonicalCY (CY 3.71) or explicit -Data; throws when missing.
    $dataChoice = Get-CysDataDir $Data
    $dataDir = $dataChoice.Dir
    $dataReason = $dataChoice.Reason

    # ---- clear the previous stage (keeps README*, ShaderCache and logs unless -Clean)
    New-Item -ItemType Directory -Force $Out | Out-Null
    New-Item -ItemType Directory -Force $Symbols | Out-Null
    if ($Clean) {
        foreach ($i in @(Get-ChildItem -LiteralPath $Out -Force)) {
            if ($i.Name -like 'README*') { continue }
            Move-CysToQuarantine $i.FullName 'ci-stage-clean'
        }
    } else {
        foreach ($i in @(Get-ChildItem -LiteralPath $Out -File -Force)) {
            if ($i.Name -like 'README*') { continue }
            if ((@('.dll', '.exe', '.pdb', '.cmd', '.cfg') -contains $i.Extension.ToLower()) -or $i.Name -eq 'cys_stage.json') {
                Move-CysToQuarantine $i.FullName 'ci-stage'
            }
        }
        $media = Join-Path $Out 'Media'
        if (Test-Path -LiteralPath $media) { Move-CysToQuarantine $media 'ci-stage' }
    }
    foreach ($i in @(Get-ChildItem -LiteralPath $Symbols -Filter '*.pdb' -File -Force)) { Move-CysToQuarantine $i.FullName 'ci-stage' }

    function Add-Entry([string]$Dest, [string]$Source, [string]$Kind) {
        $fi = Get-Item -LiteralPath $Dest
        $e = [ordered]@{
            name   = $fi.Name
            kind   = $Kind
            source = $Source
            bytes  = $fi.Length
            sha256 = (Get-FileHash -LiteralPath $Dest -Algorithm SHA256).Hash.ToLower()
        }
        if (@('.dll', '.exe') -contains $fi.Extension.ToLower()) {
            $e.machine = Get-PeMachine $Dest
            if ($e.machine -ne 'x64') { $problems.Add($fi.Name + ' is ' + $e.machine + ', not x64') }
            $ts = $targetStatus[$fi.Name.ToLower()]
            if ($ts) { $e.ci_target = $ts }
        }
        $entries.Add($e)
    }

    # ---- our binaries (+ cg.dll copied into bin by the OGRE build)
    $ours = @(Get-ChildItem -LiteralPath $bin -File | Where-Object { @('.dll', '.exe') -contains $_.Extension.ToLower() })
    foreach ($f in $ours) {
        Copy-Item -LiteralPath $f.FullName -Destination $Out -Force
        $kind = 'ours'
        if ($f.Name -ieq 'cg.dll') { $kind = 'runtime: x64 cg.dll from the OGRE build output' }
        Add-Entry (Join-Path $Out $f.Name) $f.FullName $kind
    }
    if (-not (Test-Path -LiteralPath (Join-Path $Out 'cg.dll'))) {
        $cgc = Get-CMakeCacheValue $Tree 'CYS_CG_DLL'
        if ($cgc -and (Test-Path -LiteralPath $cgc)) {
            Copy-Item -LiteralPath $cgc -Destination (Join-Path $Out 'cg.dll') -Force
            Add-Entry (Join-Path $Out 'cg.dll') $cgc 'runtime: x64 cg.dll (CYS_CG_DLL fallback, read-only source)'
        } else {
            $problems.Add('cg.dll missing (not in ' + $bin + ', no CYS_CG_DLL)')
        }
    }

    # ---- vendor runtime
    $sysDir = Join-Path $env:SystemRoot 'System32'
    if (-not [Environment]::Is64BitProcess) { $sysDir = Join-Path $env:SystemRoot 'Sysnative' }
    foreach ($n in @('d3dx9_43.dll', 'D3DCompiler_43.dll')) {
        $src = Join-Path $sysDir $n
        if (Test-Path -LiteralPath $src) {
            Copy-Item -LiteralPath $src -Destination (Join-Path $Out $n) -Force
            Add-Entry (Join-Path $Out $n) $src 'runtime: DirectX June 2010'
        } else {
            $problems.Add('missing ' + $src + ' (DirectX June 2010 runtime)')
        }
    }
    $fmodDir = Join-Path $P.Root 'Src\ThirdParty\_sdk\fmod\api\core\lib\x64'
    foreach ($n in @('fmod.dll', 'fmodL.dll')) {
        $src = Join-Path $fmodDir $n
        if (Test-Path -LiteralPath $src) {
            Copy-Item -LiteralPath $src -Destination (Join-Path $Out $n) -Force
            Add-Entry (Join-Path $Out $n) $src 'runtime: FMOD Core 2.02.35 x64'
        } else {
            $problems.Add('missing ' + $src + ' (FMOD SDK)')
        }
    }

    # ---- Scorpio media (from the same source revision as the tree)
    $mediaSrc = $null
    if ($srcDir) { $mediaSrc = Join-Path $srcDir 'Engine\Scorpio\media' }
    if (-not $mediaSrc -or -not (Test-Path -LiteralPath $mediaSrc)) { $mediaSrc = Join-Path $P.Root 'Src\Engine\Scorpio\media' }
    if (Test-Path -LiteralPath $mediaSrc) {
        $mediaDst = Join-Path $Out 'Media\Scorpio'
        New-Item -ItemType Directory -Force $mediaDst | Out-Null
        foreach ($f in @(Get-ChildItem -LiteralPath $mediaSrc -File)) {
            Copy-Item -LiteralPath $f.FullName -Destination $mediaDst -Force
            Add-Entry (Join-Path $mediaDst $f.Name) $f.FullName 'media: Scorpio hardware skinning'
        }
    } else {
        $problems.Add('Scorpio media not found: ' + $mediaSrc)
    }

    # ---- terrain type config: WX::System reads "WXTerrainType.cfg" from the WORKING directory (WXSystem.cpp:552,
    #      TerrainTypeInfos::parseTerrainTypeConfigFile -> Ogre::ConfigFile::load). No file of that name exists in
    #      Reference, CY 3.71 or client_GL; both ship the same [type] texture=/effect= format as Bin64\TerrainTypeInfo.cfg
    #      (CY Game\Bin64 and client_GL\Bin64 copies are byte-identical; CY first, client_GL as fallback).
    $ttSrc = Join-Path $P.CyGameBin64 'TerrainTypeInfo.cfg'
    $ttKind = 'config: terrain types (copy of CY 3.71 Bin64\TerrainTypeInfo.cfg, read-only source)'
    if (-not (Test-Path -LiteralPath $ttSrc)) {
        $ttSrc = Join-Path (Split-Path -Parent $P.ClientGLData) 'Bin64\TerrainTypeInfo.cfg'
        $ttKind = 'config: terrain types (copy of client_GL\Bin64\TerrainTypeInfo.cfg, read-only source; CY copy absent)'
    }
    if (Test-Path -LiteralPath $ttSrc) {
        foreach ($n in @('TerrainTypeInfo.cfg', 'WXTerrainType.cfg')) {
            Copy-Item -LiteralPath $ttSrc -Destination (Join-Path $Out $n) -Force
            Add-Entry (Join-Path $Out $n) $ttSrc $ttKind
        }
    } else {
        $problems.Add('terrain type config not found: ' + $ttSrc)
    }

    # ---- symbols
    $pdbs = @(Get-ChildItem -LiteralPath $bin -Filter '*.pdb' -File)
    foreach ($f in $pdbs) { Copy-Item -LiteralPath $f.FullName -Destination $Symbols -Force }

    foreach ($need in @('TlbbViewer.exe', 'OgreSmoke.exe', 'OgreMain.dll', 'RenderSystem_Direct3D9.dll')) {
        if (-not (Test-Path -LiteralPath (Join-Path $Out $need))) { $problems.Add('not staged (not built?): ' + $need) }
    }

    # ---- wrappers that pass the staged data folder (cmd files must stay ASCII)
    $wrappers = @()
    if ($dataDir -match '^[\x20-\x7E]+$') {
        foreach ($tool in @('TlbbViewer', 'OgreSmoke')) {
            if (Test-Path -LiteralPath (Join-Path $Out ($tool + '.exe'))) {
                $name = 'Run-' + $tool + '.cmd'
                $text = '@echo off' + "`r`n" +
                    'rem Generated by CY-Source Tools\build\stage.ps1: runs the staged ' + $tool + ' on the staged data folder (read-only).' + "`r`n" +
                    '"%~dp0' + $tool + '.exe" --data "' + $dataDir + '" %*' + "`r`n" +
                    'exit /b %ERRORLEVEL%' + "`r`n"
                [System.IO.File]::WriteAllText((Join-Path $Out $name), $text, [System.Text.Encoding]::ASCII)
                $wrappers += $name
            }
        }
    } else {
        $problems.Add('data path is not ASCII; no Run-*.cmd wrappers written')
    }

    $ciResult = $null
    if ($ci) { $ciResult = $ci.result }
    $manifest = [ordered]@{
        staged       = (Get-Date).ToString('s')
        tree         = $Tree
        source_dir   = $srcDir
        sha          = $sha
        short        = $short
        source_dirty = $srcDirty
        ci_summary   = $ciPath
        ci_result    = $ciResult
        data_dir     = $dataDir
        data_reason  = $dataReason
        bin64        = $Out
        symbols      = $Symbols
        pdbs         = $pdbs.Count
        wrappers     = $wrappers
        game_exe     = [bool](Test-Path -LiteralPath (Join-Path $Out 'Game.exe'))
        files        = $entries.ToArray()
        problems     = $problems.ToArray()
    }
    Write-JsonFile $manifest (Join-Path $Out 'cys_stage.json')

    Write-Host ('staged ' + $entries.Count + ' files from ' + $Tree + ' (' + $short + ', CI ' + $ciResult + ') -> ' + $Out)
    Write-Host ('PDBs: ' + $pdbs.Count + ' -> ' + $Symbols)
    Write-Host ('data: ' + $dataDir + ' (' + $dataReason + ')')
    foreach ($pr in $problems) { Write-Host ('PROBLEM: ' + $pr) }
    if ($problems.Count) { $exitCode = 1 } else { $exitCode = 0 }
} catch {
    Write-Host ('STAGE ERROR: ' + $_.Exception.Message)
    $exitCode = 2
} finally {
    Exit-CysLock
}
exit $exitCode
