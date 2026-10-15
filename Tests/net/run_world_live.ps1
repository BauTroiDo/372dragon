# World live test against the PRIVATE WSL clone (/home/ubuntu/cys-test-20260913), never the live server.
# Run by the USER (only the user types the test00 password; the script asks for it with hidden input):
#   powershell -NoProfile -ExecutionPolicy Bypass -File C:\TLBB\085\CY-Source\Tests\net\run_world_live.ps1
# Preconditions: test00 is logged out everywhere; the clone is running (this script never starts/stops it).
# Steps: read-only pre snapshot -> bot enters the world as CYTest00 (GUID 200001) for ~60 s, walks 2 steps,
# quits with CGAskQuit -> read-only post snapshot -> review. Never retry on failure (wrong passwords count per MAC).
# Every step is written to <run folder>\script.log (the password is never written anywhere).
# Maintainer self-test without any connection: set CYS_WORLD_LIVE_DRYRUN=1 (stops after the local checks).
$ErrorActionPreference = 'Continue'
$repo = 'C:\TLBB\085\CY-Source'
Set-Location $repo
$out = 'Build/Logs/2026-09-13-world/live-1/run-' + (Get-Date -Format 'yyyyMMdd-HHmmss')
New-Item -ItemType Directory -Force $out | Out-Null
$log = Join-Path $out 'script.log'
function Log([string]$m) { $line = (Get-Date -Format 'HH:mm:ss') + ' ' + $m; Write-Host $line; Add-Content -Path $log -Value $line -Encoding Ascii }
function Quit([int]$code) { Remove-Item Env:CYS_BOT_PWD -ErrorAction SilentlyContinue; Log ('exit ' + $code); exit $code }
trap { Log ('ERROR: ' + $_.Exception.Message); Quit 9 }

Log ('run folder: ' + $out)
Log ('powershell ' + $PSVersionTable.PSVersion)
if (-not (Get-Command wsl.exe -ErrorAction SilentlyContinue)) { Log 'wsl.exe not found - abort (nothing was sent).'; Quit 5 }
$bot  = Join-Path $repo 'Build\Logs\2026-09-13-world\live-1\bin\CysNetBot.exe'
$want = 'AA79EBCCC293BCC6FC850A123868433E81D0779BF726C5AADDB26C968C4C5D76'
if (-not (Test-Path $bot)) { Log ('bot not found: ' + $bot + ' - abort.'); Quit 3 }
$have = (Get-FileHash $bot -Algorithm SHA256).Hash
if ($have -ne $want) { Log ('bot hash mismatch ' + $have + ' - abort.'); Quit 3 }
Log 'local checks OK (wsl present, bot hash verified)'
if ($env:CYS_WORLD_LIVE_DRYRUN -eq '1') { Log 'DRY RUN: stopping before any connection.'; Quit 0 }

# CYS: test account file allowed by the user 14/09 (.local is git-ignored): test00=<password>
$acct = Join-Path $repo '.local\test-accounts.txt'
if (-not $env:CYS_BOT_PWD -and (Test-Path $acct)) {
    $line = Get-Content $acct | Where-Object { $_ -like 'test00=*' } | Select-Object -First 1
    if ($line) { $env:CYS_BOT_PWD = $line.Substring(7) }
}
if (-not $env:CYS_BOT_PWD) {
    $sec = Read-Host -AsSecureString 'test00 password (hidden)'
    $ptr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($sec)
    try { $env:CYS_BOT_PWD = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr) } finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr) }
    if (-not $env:CYS_BOT_PWD) { Log 'no password entered - abort (nothing was sent).'; Quit 2 }
}
Log 'password provided (not logged)'

$py = 'C:\Program Files\Python313\python.exe'
$collector = '/mnt/c/TLBB/085/CY-Source/Tests/net/collect_world_snapshot.py'

Log '[1/4] pre snapshot (read-only)'
& wsl.exe -d TLBB -u root -- python3 -B $collector collect --label pre --out-dir $out
Log ('pre snapshot exit ' + $LASTEXITCODE)
if ($LASTEXITCODE -ne 0) { Log 'pre snapshot failed - abort (nothing was sent to the game server).'; Quit 4 }

Log '[2/4] bot world session (about 70 s, hard cap about 165 s)'
& $bot --mode world --host 127.0.0.1 --port 15733 --game-port 15734 --account test00 --guid 200001 --out "$out/bot" --dwell-ms 60000 --walk 1
$botRc = $LASTEXITCODE
Remove-Item Env:CYS_BOT_PWD -ErrorAction SilentlyContinue
Log ('bot exit ' + $botRc)

Log '[3/4] post snapshot (read-only)'
& wsl.exe -d TLBB -u root -- python3 -B $collector collect --label post --out-dir $out
Log ('post snapshot exit ' + $LASTEXITCODE)

Log '[4/4] review'
& $py -B Tests/net/collect_world_snapshot.py review --pre "$out/pre.json" --post "$out/post.json" --bot "$out/bot/result.json" --out "$out/review.json"
$revRc = $LASTEXITCODE
Log ('review exit ' + $revRc)

Log ('RESULT: bot exit {0}, review exit {1}, folder {2}' -f $botRc, $revRc, $out)
if ($botRc -ne 0 -or $revRc -ne 0) { Log 'FAILED - do NOT retry. Tell Claude.'; Quit 1 }
Log 'PASSED. Tell Claude.'
Quit 0
