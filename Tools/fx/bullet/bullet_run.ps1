# CYS-BULLETFX (bullet-fx 19/09): mot luot do duong dan, OFFLINE (khong server, khong quai, khong giet).
# Chay Game.exe cua stage do dac voi CYS_WORLD_SCENARIO = kich ban `targetlist` (GC 909) va CYS_BULLET_LOG=1.
# Giu khe theo giao thuc hang doi (Build\game-slot-queue.txt / .log) va TRA khe ngay khi xong.
# usage: bullet_run.ps1 -Rep 1 [-Seconds 170] [-Stage ...] [-Scenario ...]
# ASCII only (Windows PowerShell 5.1).
param([int]$Rep = 1,
      [ValidateRange(30,300)][int]$Seconds = 170,
      [string]$Stage = 'C:\TLBB\085\CY-Source\Build\world-gui\stage-bulletfx',
      [string]$Scenario = 'C:\TLBB\085\CY-Source\Build\Logs\2026-09-19-bullet-fx\scenario\run1.replay.txt',
      [string]$Meta = 'C:\TLBB\085\CY-Source\Build\Logs\2026-09-19-bullet-fx\scenario\run1.meta.json')
$ErrorActionPreference = 'Stop'
$R = 'C:\TLBB\085\CY-Source'
# Nhat ky khe la tep DUNG CHUNG giua cac nhanh: mot lan ghi truot (tep dang bi nhanh khac mo) KHONG duoc
# lam hong ca luot do - lan truoc no da lam the that.
function Note([string]$text) {
    $line = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss') + ' ' + $text
    for ($i = 0; $i -lt 40; $i++) {
        try { [IO.File]::AppendAllText("$R\Build\game-slot-queue.log", $line + [Environment]::NewLine); return }
        catch { Start-Sleep -Milliseconds 250 }
    }
    Write-Host "KHONG ghi duoc vao nhat ky khe: $line"
}
$logs = "$R\Build\Logs\2026-09-19-bullet-fx"
$fixture = "$R\Build\Logs\2026-09-14-world-replay\world_session_1.bin"
$outDir = "$logs\run-r$Rep"
if (Test-Path -LiteralPath $outDir) { throw "chon -Rep khac: $outDir da co" }
if (-not (Test-Path -LiteralPath $Scenario)) { throw "khong co kich ban $Scenario" }
if (-not (Test-Path -LiteralPath "$Stage\Bin64\Game.exe")) { throw "khong co $Stage\Bin64\Game.exe" }
$m = Get-Content -Raw -Encoding UTF8 $Meta | ConvertFrom-Json

$vars = @{
    'CYS_WORLD_SCENARIO' = $Scenario
    'CYS_BULLET_LOG'     = '1'      # CYS-BULLETFX: bat cac chot do (mac dinh TAT)
    'CYS_SFX_LOG'        = '1'      # de thay `animation hit` / `magic send`: cong IsBeAttackEffectShowed
    'CYS_SFX_SHOT_MS'    = [string]$m.shot_ms
    'CYS_SFX_CAM'        = '0.400,-24.00'   # cung may quay voi fx-cy-baseline (orbit 14,6 m, yaw -23,98)
    'CYS_SFX_CAM_ADDH'   = '1.5'
    'CYS_AA'             = 'cy'
    'CYS_TEXFILTER'      = 'ogre'
}
# giu khe
$lock = "$R\Build\game-slot.lock"; $waited = 0
while ($true) {
    $busy = @(Get-Process -Name Game -ErrorAction SilentlyContinue).Count -gt 0
    if (-not $busy -and (Test-Path -LiteralPath $lock)) {
        $own = (Get-Content -LiteralPath $lock -ErrorAction SilentlyContinue) -match '^bullet-fx'
        $busy = -not $own -and ((Get-Date) - (Get-Item -LiteralPath $lock).LastWriteTime).TotalMinutes -lt 5
    }
    if (-not $busy) { break }
    if ($waited -ge 1500) { throw 'khe Game.exe ban qua 25 phut' }
    Start-Sleep -Seconds 2; $waited += 2
}
[IO.File]::WriteAllText($lock, 'bullet-fx ' + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss') + " r$Rep")
Note("bullet-fx: NHAN khe (cho $waited s, 0 Game.exe; uu tien 3). Luot r${Rep}: replay OFFLINE, khong server, khong dang nhap, khong giet quai, <=$Seconds s.")
Write-Host "khe sau $waited s"
try {
    foreach ($k in $vars.Keys) { [Environment]::SetEnvironmentVariable($k, $vars[$k], 'Process') }
    $ErrorActionPreference = 'Continue'
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$R\Tools\game\run_world_replay.ps1" `
        -Stage $Stage -Fixture $fixture -OutDir $outDir -Seconds $Seconds -WaitMinutes 2 2>&1 |
        Out-String -Stream | Select-Object -Last 6
    $ErrorActionPreference = 'Stop'
} finally {
    foreach ($k in $vars.Keys) { [Environment]::SetEnvironmentVariable($k, $null, 'Process') }
    if ((Test-Path -LiteralPath $lock) -and ((Get-Content -LiteralPath $lock) -match '^bullet-fx')) { [IO.File]::Delete($lock) }
    if (-not (Test-Path -LiteralPath (Join-Path $outDir 'WXClient.log'))) { Note("bullet-fx: TRA KHE (luot r${Rep} khong ra bang chung)") }
}
$env_used = [ordered]@{}; foreach ($k in ($vars.Keys | Sort-Object)) { $env_used[$k] = $vars[$k] }
$man = [ordered]@{ rep = $Rep; stage = $Stage; scenario = $Scenario; env = $env_used
                   game_sha256 = (Get-FileHash "$Stage\Bin64\Game.exe").Hash.ToLower()
                   render_sha256 = (Get-FileHash "$Stage\Bin64\Render.dll").Hash.ToLower()
                   scenario_sha256 = (Get-FileHash $Scenario).Hash.ToLower(); shots = @() }
foreach ($f in Get-ChildItem -LiteralPath $outDir -Filter '*.png' -ErrorAction SilentlyContinue | Sort-Object Name) {
    $man.shots += [ordered]@{ name = $f.Name; sha256 = (Get-FileHash $f.FullName).Hash.ToLower(); bytes = $f.Length }
}
$man | ConvertTo-Json -Depth 4 | Set-Content -Encoding UTF8 (Join-Path $outDir 'manifest.json')
Note("bullet-fx: TRA KHE sau luot r${Rep} (anh " + $man.shots.Count + ", bang chung $outDir).")
Write-Host ("anh: " + $man.shots.Count + "  -> " + $outDir)
Select-String -LiteralPath "$outDir\WXClient.log" -Pattern 'CYS-BULLETFX' -ErrorAction SilentlyContinue |
    Select-Object -First 8 | ForEach-Object { $_.Line }
