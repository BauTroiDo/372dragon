# CYS-QUEST: live NPC dialogue / mission / NPC transfer run of CysNetBot against the PRIVATE server (login 15733 / game 15734).
# Same guard rails as run_inventory_live.ps1: read-only pre/post snapshots (collect_world_snapshot.py in WSL), one bot
# session, review, never retry. The test00 password comes from CYS_BOT_PWD or CY-Source/.local/test-accounts.txt (allowed
# by the user 14/09); it is never written anywhere.
#   powershell -NoProfile -ExecutionPolicy Bypass -File Tests\net\run_quest_live.ps1 -Bot <CysNetBot.exe> -OutRoot <Build\Logs\...>
#     -Talk "160,158" [-Quest accept|complete|full] [-QuestScript 210262] [-TalkOption 1001] [-Goto X,Z -GotoScene ID]
param(
    [Parameter(Mandatory=$true)][string]$Bot,
    [Parameter(Mandatory=$true)][string]$OutRoot,
    [Parameter(Mandatory=$true)][string]$Talk,
    [string]$Quest = '',
    [string]$QuestScript = '',
    [string]$TalkOption = '',
    [string]$Goto = '',
    [string]$GotoScene = '',
    [string]$TalkScene = '',
    [int]$DwellMs = 20000
)
$ErrorActionPreference = 'Continue'
$repo = 'C:\TLBB\085\CY-Source'
Set-Location $repo
if ($OutRoot -notmatch '\\Build\\Logs\\' -and $OutRoot -notmatch '^Build[\\/]Logs[\\/]') { throw 'OutRoot must lie below Build\Logs' }
$out = Join-Path $OutRoot ('run-' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
New-Item -ItemType Directory -Force $out | Out-Null
$log = Join-Path $out 'script.log'
function Log([string]$m) { $line = (Get-Date -Format 'HH:mm:ss') + ' ' + $m; Write-Host $line; Add-Content -Path $log -Value $line -Encoding UTF8 }
function Quit([int]$code) { Remove-Item Env:CYS_BOT_PWD -ErrorAction SilentlyContinue; Log ('exit ' + $code); exit $code }
trap { Log ('ERROR: ' + $_.Exception.Message); Quit 9 }

Log ('run folder: ' + $out)
if (-not (Get-Command wsl.exe -ErrorAction SilentlyContinue)) { Log 'wsl.exe not found - abort (nothing was sent).'; Quit 5 }
if (-not (Test-Path $Bot)) { Log ('bot not found: ' + $Bot + ' - abort.'); Quit 3 }
Log ('bot sha256 ' + (Get-FileHash $Bot -Algorithm SHA256).Hash)

$acct = Join-Path $repo '.local\test-accounts.txt'
if (-not $env:CYS_BOT_PWD -and (Test-Path $acct)) {
    $line = Get-Content $acct | Where-Object { $_ -like 'test00=*' } | Select-Object -First 1
    if ($line) { $env:CYS_BOT_PWD = $line.Substring(7) }
}
if (-not $env:CYS_BOT_PWD) { Log 'no password available (CYS_BOT_PWD or .local/test-accounts.txt) - abort (nothing was sent).'; Quit 2 }
Log 'password provided (not logged)'

$py = 'C:\Program Files\Python313\python.exe'
$collector = '/mnt/c/TLBB/085/CY-Source/Tests/net/collect_world_snapshot.py'
$outWsl = ([IO.Path]::GetFullPath($out)).Substring($repo.Length + 1).Replace('\', '/')

Log '[1/4] pre snapshot (read-only)'
& wsl.exe -d TLBB -u root -- python3 -B $collector collect --label pre --out-dir $outWsl
Log ('pre snapshot exit ' + $LASTEXITCODE)
if ($LASTEXITCODE -ne 0) { Log 'pre snapshot failed - abort (nothing was sent to the game server).'; Quit 4 }

$botOut = $outWsl + '/bot'
$args = @('--mode', 'world', '--host', '127.0.0.1', '--port', '15733', '--game-port', '15734', '--account', 'test00', '--guid', '200001',
          '--out', $botOut, '--dwell-ms', [string]$DwellMs, '--walk', '0', '--talk', $Talk)
if ($Quest) { $args += @('--quest', $Quest) }
if ($QuestScript) { $args += @('--quest-script', $QuestScript) }
if ($TalkOption) { $args += @('--talk-option', $TalkOption) }
if ($Goto) { $args += @('--goto', $Goto) }
if ($GotoScene) { $args += @('--goto-scene', $GotoScene) }
if ($TalkScene) { $args += @('--talk-scene', $TalkScene) }
Log ('[2/4] bot quest session: ' + ($args -join ' '))
& $Bot @args
$botRc = $LASTEXITCODE
Remove-Item Env:CYS_BOT_PWD -ErrorAction SilentlyContinue
Log ('bot exit ' + $botRc)

Log '[3/4] post snapshot (read-only)'
& wsl.exe -d TLBB -u root -- python3 -B $collector collect --label post --out-dir $outWsl
Log ('post snapshot exit ' + $LASTEXITCODE)

Log '[4/4] review'
& $py -B Tests/net/collect_world_snapshot.py review --pre "$outWsl/pre.json" --post "$outWsl/post.json" --bot "$outWsl/bot/result.json" --out "$outWsl/review.json"
$revRc = $LASTEXITCODE
Log ('review exit ' + $revRc)
Log ('RESULT: bot exit {0}, review exit {1}, folder {2}' -f $botRc, $revRc, $out)
if ($botRc -ne 0) { Log 'FAILED - do NOT retry blindly.'; Quit 1 }
Log 'PASSED.'
Quit 0
