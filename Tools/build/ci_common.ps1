# CY-Source CI - shared helpers, dot-sourced by ci.ps1, stage.ps1, smoke.ps1 and ci_loop.ps1.
# Windows PowerShell 5.1: no '&&', native stderr handled explicitly, JSON written as UTF-8 without BOM.

$script:CysRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$script:Utf8NoBom = New-Object System.Text.UTF8Encoding($false)


# CYS: preserve generated files; reject paths outside Build and every reparse ancestor.
function Move-CysToQuarantine {
    param([Parameter(Mandatory = $true)][string]$Path, [string]$Reason = 'ci-preserved')
    $build = [IO.Path]::GetFullPath((Join-Path $script:CysRoot 'Build')).TrimEnd('\')
    $source = [IO.Path]::GetFullPath($Path).TrimEnd('\')
    $prefix = $build + '\'
    if (-not $source.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) {
        throw ('quarantine source must be inside Build: ' + $source)
    }
    $relative = $source.Substring($prefix.Length)
    if ($relative -match '^(?i:_quarantine|ci\\wt)(\\|$)') {
        throw ('cannot quarantine protected path: ' + $source)
    }
    # Check ancestors before Test-Path can follow a junction outside the repository.
    $cursor = $source
    while ($cursor) {
        $item = Get-Item -LiteralPath $cursor -Force -ErrorAction SilentlyContinue
        if ($item -and ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
            throw ('cannot quarantine through a reparse point: ' + $cursor)
        }
        $cursor = Split-Path -Parent $cursor
    }
    if (-not (Test-Path -LiteralPath $source)) { return }
    $safeReason = $Reason -replace '[^A-Za-z0-9_-]', '_'
    $quarantine = Join-Path $build ('_quarantine\' + (Get-Date -Format 'yyyy-MM-dd') + '-' + $safeReason)
    $destination = [IO.Path]::GetFullPath((Join-Path $quarantine ((Get-Date -Format 'HHmmss-fffffff') + '-' + [guid]::NewGuid().ToString('N'))))
    if (-not $destination.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) {
        throw ('quarantine destination outside Build: ' + $destination)
    }
    $cursor = $destination
    while ($cursor) {
        $item = Get-Item -LiteralPath $cursor -Force -ErrorAction SilentlyContinue
        if ($item -and ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
            throw ('quarantine destination crosses a reparse point: ' + $cursor)
        }
        $cursor = Split-Path -Parent $cursor
    }
    New-Item -ItemType Directory -Path $destination -Force | Out-Null
    $target = Join-Path $destination (Split-Path -Leaf $source)
    # Both absolute endpoints have been checked; Move-Item preserves directory contents.
    Move-Item -LiteralPath $source -Destination $target -ErrorAction Stop
    $record = [ordered]@{ source = $source; destination = $target; moved = (Get-Date).ToString('s') }
    Write-JsonFile $record (Join-Path $destination 'move.json')
}

function Get-CysPaths {
    $r = $script:CysRoot
    [pscustomobject]@{
        Root          = $r
        Wt            = Join-Path $r 'Build\ci\wt'
        Tree          = Join-Path $r 'Build\cmake\ci-x64'
        LogsCi        = Join-Path $r 'Build\Logs\ci'
        Bin64         = Join-Path $r 'Build\Client\Bin64'
        Symbols       = Join-Path $r 'Build\Symbols\ci'
        Lock          = Join-Path $r 'Build\ci\ci.lock'
        Python        = 'C:\Program Files\Python313\python.exe'
        # CYS ci-cy 14/09/2026: binaries after main 75b3802 (CS1) read the CY 3.71 DBC layout, so CI data is
        # Assets\CanonicalCY\Data only. Canonical (GL) and client_GL stay listed for read-only references
        # (TerrainTypeInfo.cfg fallback, cg.dll); they are never used as the staged data folder.
        CanonicalCYData = Join-Path $r 'Assets\CanonicalCY\Data'
        ClientGLData  = 'C:\TLBB\085\client_GL\Data'
        CanonicalData = Join-Path $r 'Assets\Canonical\Data'
        CyGameBin64   = 'C:\TLBB\085\Tools\DATA NEW\CY Game\Bin64'
    }
}

# Entries a usable data folder must have (OGRE core + material templates + the three folders every tool opens +
# the CY scene folders the gates count).
$script:CysDataNeed = @('OgreCore.zip', 'MaterialTemplates.zip', 'ModelFolder', 'MaterialFolder', 'EffectFolder',
    'SceneFolder', 'Scene2Folder')

# The data folder for stage/smoke/checks: -Data when given (must exist), else Assets\CanonicalCY\Data, which must be
# complete. There is no fallback to Canonical (GL) or client_GL: a CY-layout binary on GL tables is a wrong result,
# not a degraded one. Returns @{ Dir; Reason }.
function Get-CysDataDir {
    param([string]$Explicit = '')
    $P = Get-CysPaths
    if ($Explicit) {
        if (-not (Test-Path -LiteralPath $Explicit)) { throw ('data folder not found: ' + $Explicit) }
        return [pscustomobject]@{ Dir = (Resolve-Path -LiteralPath $Explicit).Path; Reason = 'explicit -Data' }
    }
    if (-not (Test-Path -LiteralPath $P.CanonicalCYData)) {
        throw ('Assets\CanonicalCY\Data does not exist (' + $P.CanonicalCYData + '); build it with ' +
            'Tools\pipeline\build_canonical_cy.py --apply, or pass -Data. No client_GL fallback for CY binaries.')
    }
    $miss = @($script:CysDataNeed | Where-Object { -not (Test-Path -LiteralPath (Join-Path $P.CanonicalCYData $_)) })
    if ($miss.Count) {
        throw ('Assets\CanonicalCY\Data is incomplete (missing ' + ($miss -join ', ') + '); rebuild it or pass -Data')
    }
    return [pscustomobject]@{ Dir = $P.CanonicalCYData; Reason = 'Assets\CanonicalCY\Data present and complete (CY 3.71)' }
}

# Runs a native program, returns Rc + output lines (stderr merged, never a terminating error).
function Invoke-Exe {
    param([Parameter(Mandatory = $true)][string]$Exe, [string[]]$ArgList = @())
    $old = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $out = & $Exe @ArgList 2>&1 | ForEach-Object { "$_" }
        $rc = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $old
    }
    [pscustomobject]@{ Rc = $rc; Out = @($out) }
}

# Quoting for a cmd.exe command line (paths with spaces or parentheses).
function ConvertTo-CmdArg([string]$a) {
    if ($a -eq '') { return '""' }
    if ($a -match '[\s&|<>^(),;]') { return '"' + $a + '"' }
    return $a
}
function Join-CmdArgs([string[]]$Items) { ($Items | ForEach-Object { ConvertTo-CmdArg $_ }) -join ' ' }

# Quoting for CreateProcess / CommandLineToArgvW (used with ProcessStartInfo.Arguments; Unicode safe).
function ConvertTo-ProcArg([string]$a) {
    if ($a -eq '') { return '""' }
    if ($a -notmatch '[\s"]') { return $a }
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.Append('"')
    $bs = 0
    foreach ($ch in $a.ToCharArray()) {
        if ($ch -eq [char]'\') { $bs++; continue }
        if ($ch -eq [char]'"') { [void]$sb.Append('\' * (2 * $bs + 1)); [void]$sb.Append('"'); $bs = 0; continue }
        if ($bs) { [void]$sb.Append('\' * $bs); $bs = 0 }
        [void]$sb.Append($ch)
    }
    if ($bs) { [void]$sb.Append('\' * (2 * $bs)) }
    [void]$sb.Append('"')
    $sb.ToString()
}

# Runs "<CommandLine> >> <LogFile> 2>&1" through cmd.exe (raw bytes kept); returns the exit code.
function Invoke-CmdLogged {
    param([Parameter(Mandatory = $true)][string]$CommandLine, [Parameter(Mandatory = $true)][string]$LogFile)
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $env:ComSpec
    $psi.Arguments = '/d /s /c "' + $CommandLine + ' >> "' + $LogFile + '" 2>&1"'
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    $p = [System.Diagnostics.Process]::Start($psi)
    $p.WaitForExit()
    return $p.ExitCode
}

function Find-VsBuildTools {
    $vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'
    if (Test-Path -LiteralPath $vswhere) {
        $r = Invoke-Exe $vswhere @('-latest', '-products', '*', '-requires',
            'Microsoft.VisualStudio.Component.VC.Tools.x86.x64', '-property', 'installationPath')
        foreach ($line in $r.Out) {
            $p = $line.Trim()
            if ($p -and (Test-Path -LiteralPath (Join-Path $p 'VC\Auxiliary\Build\vcvarsall.bat'))) { return $p }
        }
    }
    $d = 'C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools'
    if (Test-Path -LiteralPath (Join-Path $d 'VC\Auxiliary\Build\vcvarsall.bat')) { return $d }
    throw 'MSVC Build Tools (vcvarsall.bat) not found'
}

# Imports the vcvarsall environment into this PowerShell process (child processes inherit it).
function Import-VcVars {
    param([Parameter(Mandatory = $true)][string]$VsPath, [string]$Arch = 'x64')
    $bat = Join-Path $VsPath 'VC\Auxiliary\Build\vcvarsall.bat'
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $env:ComSpec
    $psi.Arguments = '/d /s /c ""' + $bat + '" ' + $Arch + ' >nul 2>&1 && set"'
    $psi.UseShellExecute = $false
    $psi.RedirectStandardOutput = $true
    $psi.CreateNoWindow = $true
    $p = [System.Diagnostics.Process]::Start($psi)
    $text = $p.StandardOutput.ReadToEnd()
    $p.WaitForExit()
    if ($p.ExitCode -ne 0) { throw ('vcvarsall.bat ' + $Arch + ' failed, rc ' + $p.ExitCode) }
    foreach ($line in ($text -split "`r?`n")) {
        if ($line -match '^([^=]+)=(.*)$') {
            try { Set-Item -LiteralPath ('Env:' + $Matches[1]) -Value $Matches[2] } catch { }
        }
    }
    if (-not (Get-Command cl.exe -ErrorAction SilentlyContinue)) { throw 'cl.exe is not on PATH after vcvarsall' }
}

function Write-CiLog {
    param([string]$Path, [string]$Text)
    if ($Path) { [System.IO.File]::AppendAllText($Path, $Text + "`r`n", $script:Utf8NoBom) }
    Write-Host $Text
}

function Write-JsonFile {
    param($Object, [Parameter(Mandatory = $true)][string]$Path)
    $json = ConvertTo-Json -InputObject $Object -Depth 12
    [System.IO.File]::WriteAllText($Path, $json, $script:Utf8NoBom)
}

function Read-JsonFile([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path)) { return $null }
    try { return (Get-Content -Raw -Encoding UTF8 -LiteralPath $Path | ConvertFrom-Json) } catch { return $null }
}

function Get-CMakeCacheValue {
    param([string]$Tree, [string]$Name)
    $cache = Join-Path $Tree 'CMakeCache.txt'
    if (-not (Test-Path -LiteralPath $cache)) { return $null }
    foreach ($line in [System.IO.File]::ReadAllLines($cache)) {
        if ($line.StartsWith($Name + ':') -or $line.StartsWith($Name + '=')) {
            $i = $line.IndexOf('=')
            if ($i -ge 0) { return $line.Substring($i + 1) }
        }
    }
    return $null
}

# PE machine of a DLL/EXE: x64, x86, arm64, or the raw value.
function Get-PeMachine([string]$Path) {
    $fs = [System.IO.File]::OpenRead($Path)
    try {
        $br = New-Object System.IO.BinaryReader($fs)
        if ($fs.Length -lt 0x40) { return 'not-PE' }
        $fs.Position = 0x3C
        $pe = $br.ReadInt32()
        if ($pe -le 0 -or $pe -gt ($fs.Length - 6)) { return 'not-PE' }
        $fs.Position = $pe
        if ($br.ReadUInt32() -ne 0x4550) { return 'not-PE' }
        $m = $br.ReadUInt16()
        switch ($m) {
            0x8664 { return 'x64' }
            0x014C { return 'x86' }
            0xAA64 { return 'arm64' }
            default { return ('0x{0:X4}' -f $m) }
        }
    } finally {
        $fs.Dispose()
    }
}

# Resource locks (Build\ci\<name>.lock): 'tree' = Build\ci\wt + Build\cmake\ci-x64 (ci.ps1, stage.ps1 reads it),
# 'bin64' = Build\Client\Bin64 (stage.ps1, smoke.ps1). ci.ps1 and smoke.ps1 can therefore run at the same time.
# A step never waits: when a lock is held by a live PowerShell process it exits with code 3.
$script:CysHeldLocks = @()
function Enter-CysLock {
    param([string]$Step, [string[]]$Names)
    $P = Get-CysPaths
    $dir = Split-Path $P.Lock
    New-Item -ItemType Directory -Force $dir | Out-Null
    foreach ($n in $Names) {
        $f = Join-Path $dir ($n + '.lock')
        if (-not (Test-Path -LiteralPath $f)) { continue }
        $info = Get-Content -Raw -LiteralPath $f -ErrorAction SilentlyContinue
        if ($info -match 'pid=(\d+)') {
            $other = [int]$Matches[1]
            if ($other -ne $PID) {
                $proc = Get-Process -Id $other -ErrorAction SilentlyContinue
                if ($proc -and $proc.ProcessName -match '^(powershell|pwsh)$') {
                    Write-Host ('CI busy: lock ' + $n + ' held (' + $info.Trim() + '); try again later')
                    exit 3
                }
            }
        }
    }
    foreach ($n in $Names) {
        $f = Join-Path $dir ($n + '.lock')
        Set-Content -LiteralPath $f -Value ('pid=' + $PID + ' step=' + $Step + ' started=' + (Get-Date -Format s)) -Encoding ASCII
        $script:CysHeldLocks += $f
    }
}

function Exit-CysLock {
    foreach ($f in $script:CysHeldLocks) {
        if (Test-Path -LiteralPath $f) {
            $info = Get-Content -Raw -LiteralPath $f -ErrorAction SilentlyContinue
            if ($info -match ('pid=' + $PID + '\b')) { Remove-Item -LiteralPath $f -Force -ErrorAction SilentlyContinue }
        }
    }
    $script:CysHeldLocks = @()
}
