# CYS-CRASHRPT 19/09/2026 - run the deliberate-crash harness and CHECK the crash report.
#
# The point of this file: the check must be able to FAIL. Build the harness against the
# pre-patch sources (build_test.cmd <scratch copy of HEAD>) and every check below goes red,
# because the old reporter truncated addresses, never printed module+RVA, and hid the minidump
# in %TEMP% under the name dmp104.tmp.
#
# Every expected value is taken from the OS itself (the harness prints ExceptionRecord fields on
# stdout before anything the reporter does), never from the report we are testing.
#
#   .\run_test.ps1 -Exe <dir>\crashrpt_test.exe -Out <dir>
#
# Exit code 0 = every check passed.
# NOTE 19/09: never name a local $out here - PowerShell variable names are CASE-INSENSITIVE, so
# $out silently overwrites the -Out PARAMETER and checks.json lands somewhere else (or throws).
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Exe,
    [Parameter(Mandatory = $true)][string]$Out,
    [string[]]$Modes = @('noncanonical', 'high', 'write')
)
$ErrorActionPreference = 'Stop'
if (-not (Test-Path -LiteralPath $Exe)) { throw "No harness at $Exe" }
[void][IO.Directory]::CreateDirectory($Out)

$rows = New-Object 'System.Collections.Generic.List[object]'
function Check([string]$mode, [string]$name, [bool]$ok, [string]$detail) {
    $rows.Add([pscustomobject]@{ mode = $mode; check = $name; result = $(if ($ok) { 'PASS' } else { 'FAIL' }); detail = $detail })
}

foreach ($mode in $Modes) {
    $run = Join-Path $Out "run-$mode"
    Remove-Item -Recurse -Force $run -ErrorAction SilentlyContinue
    [void][IO.Directory]::CreateDirectory($run)
    Copy-Item -LiteralPath $Exe -Destination $run
    $pdb = [IO.Path]::ChangeExtension($Exe, '.pdb')
    if (Test-Path -LiteralPath $pdb) { Copy-Item -LiteralPath $pdb -Destination $run }
    $exeRun = Join-Path $run ([IO.Path]::GetFileName($Exe))

    Push-Location $run
    try { & $exeRun $mode > (Join-Path $run 'stdout.txt') 2>&1 } finally { Pop-Location }

    $so = [IO.File]::ReadAllText((Join-Path $run 'stdout.txt'))
    # Ground truth straight from the EXCEPTION_RECORD.
    $osData = ([regex]'OS faulting data addr= 0x([0-9A-F]{16})').Match($so).Groups[1].Value
    $osRva = ([regex]'OS RVA in module     = 0x([0-9A-F]{16})').Match($so).Groups[1].Value
    $osOp = ([regex]'OS Operate           = (\d+)').Match($so).Groups[1].Value
    if (-not $osData) { Check $mode 'harness_crashed' $false 'harness did not report an exception'; continue }
    Check $mode 'harness_crashed' $true "data=0x$osData rva=0x$osRva op=$osOp"

    $smlPath = Join-Path $run 'WXC_SML.TXT'
    $sml = if (Test-Path -LiteralPath $smlPath) { [IO.File]::ReadAllText($smlPath) } else { '' }

    if ($mode -eq 'cppthrow') {
        # A C++ throw is SEH code 0xE06D7363 and its FOUR parameters ARE the payload. Before 19/09 the
        # report printed the code and nothing else, so naming the thrown type still needed the dump.
        Check $mode 'code_is_cxx_throw' ($sml -match 'Code:\s+0xE06D7363\s+\(MSVC C\+\+ throw\)') 'Code line must name the C++ throw'
        Check $mode 'eh_magic_param0' ($sml -match '(?m)^Param\[0\]:\s+0x0000000019930520') 'Param[0] must be the 0x19930520 EH magic'
        $p2 = ([regex]'(?m)^Param\[2\]:\s+0x([0-9A-Fa-f]{16})\s+=\s+(\S+)\+0x([0-9A-Fa-f]+)').Match($sml)
        Check $mode 'throwinfo_as_module_rva' ($p2.Success) $(if ($p2.Success) { $p2.Groups[2].Value + '+0x' + $p2.Groups[3].Value } else { 'Param[2] not resolved to module+RVA' })
        if ($p2.Success) {
            $sym = 'C:\Program Files\LLVM\bin\llvm-symbolizer.exe'
            $mod = Join-Path $run $p2.Groups[2].Value
            $symOut = if ((Test-Path -LiteralPath $sym) -and (Test-Path -LiteralPath $mod)) {
                (& $sym --obj="$mod" --relative-address ('0x' + $p2.Groups[3].Value) 2>&1) -join ' | '
            } else { '(symbolizer or module missing)' }
            # This is the whole point: the RVA the REPORT printed must name the thrown C++ type.
            Check $mode 'throwinfo_names_cxx_type' ($symOut -match 'CysCrashRptTestThrown') $symOut
        }
        Check $mode 'dump_beside_exe' ((@(Get-ChildItem -LiteralPath $run -Filter '*.dmp' -ErrorAction SilentlyContinue)).Count -eq 1) 'minidump next to the exe'
        continue
    }

    # 1. The faulting DATA address must appear in full 64-bit width, not truncated to 32.
    $got = ([regex]'Address:\s+0x([0-9A-Fa-f]+)').Match($sml).Groups[1].Value
    Check $mode 'addr_full_64bit' ($got -eq $osData) "report=0x$got os=0x$osData"

    # 2. module + RVA, and the RVA must be the real one.
    $m = [regex]'Fault:\s+(\S+)\+0x([0-9A-Fa-f]+)'
    $fm = $m.Match($sml)
    $rvaOk = $fm.Success -and ([Convert]::ToUInt64($fm.Groups[2].Value, 16) -eq [Convert]::ToUInt64($osRva, 16))
    Check $mode 'module_plus_rva' $rvaOk $(if ($fm.Success) { $fm.Groups[1].Value + '+0x' + $fm.Groups[2].Value + " (os 0x$osRva)" } else { 'no "Fault:" line in WXC_SML.TXT' })

    # 3. WXC_SML.TXT must name the minidump, and that file must exist.
    $dmpRef = ([regex]'Minidump:\s+(.+)').Match($sml).Groups[1].Value.Trim()
    Check $mode 'sml_names_dump' ($dmpRef -and (Test-Path -LiteralPath $dmpRef)) $(if ($dmpRef) { $dmpRef } else { 'no "Minidump:" line' })

    # 4. The MAIN log must name it too - this is what nobody had on 18/09.
    $logPath = Join-Path $run 'WXClient.log'
    $log = if (Test-Path -LiteralPath $logPath) { [IO.File]::ReadAllText($logPath) } else { '' }
    # Anchored to ONE line on purpose: a loose pattern crossed newlines and happily matched the
    # "summary ->" line instead, so the check passed while the minidump line was missing.
    $logRef = ([regex]'(?m)^.*CYS-CRASHRPT:\s+minidump \(WinDbg/VS\)\s+->\s*(\S.*)$').Match($log).Groups[1].Value.Trim()
    Check $mode 'mainlog_names_dump' ($logRef -and (Test-Path -LiteralPath $logRef)) $(if ($logRef) { $logRef } else { 'WXClient.log does not name the minidump' })

    # 5. The minidump must be a real minidump, next to the exe (not hidden in %TEMP%).
    $dmpLocal = @(Get-ChildItem -LiteralPath $run -Filter '*.dmp' -ErrorAction SilentlyContinue)
    $magic = ''
    if ($dmpLocal.Count -eq 1) {
        $fs = [IO.File]::OpenRead($dmpLocal[0].FullName); $b = New-Object byte[] 4
        [void]$fs.Read($b, 0, 4); $fs.Close(); $magic = [Text.Encoding]::ASCII.GetString($b)
    }
    Check $mode 'dump_beside_exe' ($magic -eq 'MDMP') "count=$($dmpLocal.Count) magic='$magic'"

    # 6. x64 registers in the detail file - RBX/RCX carried the decisive clue on 18/09.
    $det = @(Get-ChildItem -LiteralPath $run -Filter '*.detail.txt' -ErrorAction SilentlyContinue)
    $hasRegs = $false
    if ($det.Count -eq 1) { $hasRegs = ([IO.File]::ReadAllText($det[0].FullName)) -match '(?m)^RIP: [0-9A-F]{16}' }
    Check $mode 'detail_has_x64_regs' $hasRegs "detail files=$($det.Count)"
}

$rows | Format-Table -AutoSize | Out-String -Width 200 | Write-Host
$fails = @($rows | Where-Object { $_.result -eq 'FAIL' })
($rows | ConvertTo-Json -Depth 4) | Set-Content -LiteralPath (Join-Path $Out 'checks.json') -Encoding utf8
Write-Host ('TOTAL ' + $rows.Count + '  PASS ' + ($rows.Count - $fails.Count) + '  FAIL ' + $fails.Count)
if ($fails.Count -gt 0) { exit 1 }
exit 0
