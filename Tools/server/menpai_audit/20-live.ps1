# menpai-audit: kiểm live kỹ năng phái bằng CysNetBot trên server riêng (15733/15734), nhân vật test CYTest00 (GUID 200001).
#   powershell -NoProfile -ExecutionPolicy Bypass -File 20-live.ps1 -Menpai 0,1 [-XinfaLevel 30] [-Study] [-Skills 1,2] [-MaxSkills 99]
# Mỗi phái: chờ rảnh -> char_menpai.py set (Mongo, bản ghi test) -> (tuỳ chọn) phiên --xinfa 2 ở cấp 1 -> đặt cấp XinfaLevel
# -> mỗi kỹ năng chủ động (tâm pháp yêu cầu <= XinfaLevel) một phiên bot --xinfa 1 --cast S,0 --hunt 45,152 -> dòng TSV.
# Không restart, không đụng bảng/script server. Mật khẩu test00 đọc từ .local (không ghi log).
param(
    [Parameter(Mandatory=$true)][string]$MenpaiList,
    [int]$XinfaLevel = 30,
    [switch]$Study,
    [string]$SkillList = '',
    [int]$MaxSkills = 99,
    [string]$Tag = 'live'
)
$ErrorActionPreference = 'Continue'
$Menpai = @($MenpaiList.Split(',') | Where-Object { $_ -ne '' } | ForEach-Object { [int]$_ })
$Skills = @($SkillList.Split(',') | Where-Object { $_ -ne '' } | ForEach-Object { [int]$_ })
$repo = 'C:\TLBB\085\CY-Source'
Set-Location $repo
$L = 'Build\Logs\2026-09-15-menpai-audit'
$Lw = '/mnt/c/TLBB/085/CY-Source/Build/Logs/2026-09-15-menpai-audit'
$bot = 'Build\wt-menpai-audit\Build\bot\CysNetBot.exe'
$tsv = Join-Path $L "$Tag-results.tsv"
$runlog = Join-Path $L "$Tag-run.log"
function Log([string]$m) {
    $line = (Get-Date -Format 'HH:mm:ss') + ' ' + $m; Write-Host $line
    for ($k = 0; $k -lt 5; $k++) { try { [IO.File]::AppendAllText((Join-Path $repo $runlog), $line + "`r`n"); break } catch { Start-Sleep -Milliseconds 200 } }
}

$acct = Join-Path $repo '.local\test-accounts.txt'
$line = Get-Content $acct | Where-Object { $_ -like 'test00=*' } | Select-Object -First 1
if (-not $line) { Log 'no test00 password - abort'; exit 2 }
$env:CYS_BOT_PWD = $line.Substring(7)

if (-not (Test-Path $tsv)) {
    "time`tmenpai`tskill`tname`txinfa`txinfa_req`ttargeting`tstand`tattempt`tbot_exit`tin_world`tmenpai_seen`txinfa_count`tskill_listed`tcasts`tskill_send`ttarget_lists`tdamages_pkt`tdirect_impact`tchar_buff`tdetail_buff`tdamage_dealt`tkills`tcooldown_entries`tor_codes`tlast_or`tlog_traceback`tlog_error`tcombat`tsummary`tdir" | Set-Content -Path $tsv -Encoding UTF8
}

$lockPath = Join-Path $repo 'Build\test00.lock'
function Acquire-Lock {
    for ($i = 0; $i -lt 120; $i++) {
        if (Test-Path $lockPath) {
            $it = Get-Item $lockPath -ErrorAction SilentlyContinue
            $txt = [string](Get-Content $lockPath -Raw -ErrorAction SilentlyContinue)
            if ($it -and ((Get-Date) - $it.LastWriteTime).TotalMinutes -lt 5 -and -not $txt.StartsWith('menpai-audit ')) {
                Log ('lock held: ' + $txt.Trim() + ' (wait 30 s)'); Start-Sleep -Seconds 30; continue
            }
        }
        Set-Content -Path $lockPath -Value ('menpai-audit ' + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')) -Encoding ASCII
        return $true
    }
    return $false
}
function Release-Lock {
    if (Test-Path $lockPath) {
        $txt = [string](Get-Content $lockPath -Raw -ErrorAction SilentlyContinue)
        if ($txt.StartsWith('menpai-audit ')) { [IO.File]::Delete($lockPath) }
    }
}

function Wait-Idle {
    for ($i = 0; $i -lt 60; $i++) {
        $tcp = @(Get-NetTCPConnection -State Established -ErrorAction SilentlyContinue | Where-Object { $_.RemotePort -in 15733,15734 -or $_.LocalPort -in 15733,15734 })
        $st = & wsl.exe -d TLBB -u root -- bash /mnt/c/TLBB/085/CY-Source/Tools/server/cys_server.sh status 2>&1
        $m = ($st | Select-String -Pattern 'client connections on 15733/15734: (\d+)').Matches
        $clients = if ($m.Count -gt 0) { [int]$m[0].Groups[1].Value } else { -1 }
        $gameRunning = ($st | Select-String -Pattern 'Game +running=True').Count
        if ($tcp.Count -eq 0 -and $clients -eq 0 -and $gameRunning -eq 1) { return $true }
        Log ("busy: tcp=" + $tcp.Count + " wsl_clients=" + $clients + " game_running=" + $gameRunning + " (wait 60 s)")
        Start-Sleep -Seconds 60
    }
    return $false
}

function Char-Set([int]$mp, [int]$lv, [string]$name) {
    for ($i = 0; $i -lt 5; $i++) {
        if (-not (Acquire-Lock)) { return $false }
        if (-not (Wait-Idle)) { Release-Lock; return $false }
        $o = & wsl.exe -d TLBB -u root -- python3 -B "$Lw/scripts/char_menpai.py" set --menpai $mp --xinfa-level $lv --out "$Lw/char/$name.json" 2>&1
        $rcSet = $LASTEXITCODE
        Release-Lock
        $t = (($o | Out-String).Trim() -replace '\s+', ' '); if ($t.Length -gt 300) { $t = $t.Substring(0, 300) }; Log ("char set menpai=$mp xinfa_level=$lv rc=$rcSet -> " + $t)
        if ($rcSet -eq 0) { return $true }
        Start-Sleep -Seconds 30
    }
    return $false
}

function Count-Report([string]$dir) {
    $h = @{}
    $rep = Join-Path $dir 'report.tsv'
    if (Test-Path $rep) { foreach ($r in (Import-Csv -Path $rep -Delimiter "`t")) { if ($r.dir -eq 'GC') { $h[$r.name] = [int]$r.count } } }
    return $h
}

function Run-Bot([int]$mp, [string]$label, [string[]]$extra, $skillInfo) {
    for ($attempt = 1; $attempt -le 5; $attempt++) {
        if (-not (Acquire-Lock)) { Log 'lock never free - stop'; return $null }
        if (-not (Wait-Idle)) { Release-Lock; Log 'never idle - stop'; return $null }
        # đặt lại phái/tâm pháp/kỹ năng + HP/MP ngay trước mỗi phiên (agent khác dùng chung CYTest00 có thể trả về phái 9 giữa chừng)
        $null = & wsl.exe -d TLBB -u root -- python3 -B "$Lw/scripts/char_menpai.py" set --menpai $mp --xinfa-level $script:CurLevel --refill-from "$Lw/char-original.json" --out "$Lw/char/last-set.json" 2>&1
        if ($LASTEXITCODE -ne 0) { Release-Lock; Log '  refill hp/mp failed (client connected?) - retry'; Start-Sleep -Seconds 60; continue }
        $mark = (& wsl.exe -d TLBB -u root -- bash "$Lw/scripts/logmark.sh" 2>&1 | Out-String).Trim().Split(' ')
        $rel = "Build/Logs/2026-09-15-menpai-audit/$Tag/m$mp/$label-" + (Get-Date -Format 'HHmmss') + "-a$attempt"
        $bargs = @('--mode', 'world', '--host', '127.0.0.1', '--port', '15733', '--game-port', '15734', '--account', 'test00', '--guid', '200001',
                  '--out', $rel, '--dwell-ms', '20000', '--walk', '0', '--hunt', '45,152') + $extra
        Log ("bot m$mp $label attempt $attempt : " + ($extra -join ' '))
        $t0 = Get-Date
        & $bot @bargs *> (Join-Path $L ("bot-stdout-last.txt"))
        $rc = $LASTEXITCODE
        $dir = Join-Path $repo ($rel -replace '/', '\')
        $logOut = "$Lw/$Tag/m$mp/" + (Split-Path $rel -Leaf) + "-serverlog.txt"
        $lc = (& wsl.exe -d TLBB -u root -- bash "$Lw/scripts/logcheck.sh" $mark[0] $mark[1] $logOut 2>&1 | Out-String).Trim()
        $res = $null
        if (Test-Path (Join-Path $dir 'result.json')) { $res = Get-Content (Join-Path $dir 'result.json') -Raw | ConvertFrom-Json }
        $inWorld = $res -and $res.in_world
        Log ("  rc=$rc in_world=$inWorld elapsed=" + [int]((Get-Date) - $t0).TotalSeconds + "s log: $lc")
        Start-Sleep -Seconds 10  # để server xong phiên cũ (đăng nhập lại ngay bị đá: "game socket closed")
        Release-Lock             # khoá chung Build\test00.lock (người điều phối 15/09), nghỉ >= 90 s trước khi lấy lại khoá
        Start-Sleep -Seconds 90
        if (-not $inWorld -or $rc -ne 0) {
            $err = $(if ($res) { $res.error } else { 'no result' })
            $wait = $(if ($err -match 'refused') { 180 } else { 30 })
            Log ("  session not usable (rc=$rc in_world=$inWorld error=$err) - wait $wait s, retry")
            Start-Sleep -Seconds $wait
            continue
        }
        return @{ rc = $rc; res = $res; dir = $dir; rel = $rel; log = $lc; attempt = $attempt }
    }
    return $null
}

$static = Get-Content (Join-Path $L 'static-menpai.json') -Raw -Encoding UTF8 | ConvertFrom-Json
New-Item -ItemType Directory -Force (Join-Path $L 'char') | Out-Null

foreach ($mp in $Menpai) {
    $st = $static."$mp"
    Log ("==== menpai $mp " + $st.name + " base_xinfa=" + ($st.base_xinfa -join ','))
    if ($Study) {
        $script:CurLevel = 1
        $r = Run-Bot $mp 'study' @('--xinfa', '2') $null
        if ($r) { Log ("  study: " + $r.res.skills.summary + " study_results=" + $r.res.skills.study_results) }
    }
    $script:CurLevel = $XinfaLevel
    $cands = @($st.skills | Where-Object { -not $_.passive -and ($st.learn_ids -contains $_.id) -and ($_.xinfa_req -le $XinfaLevel) })
    if ($Skills.Count -gt 0) { $cands = @($cands | Where-Object { $Skills -contains $_.id }) }
    $cands = @($cands | Select-Object -First $MaxSkills)
    Log ("  active candidates: " + ($cands | ForEach-Object { $_.id }) -join ',')
    foreach ($s in $cands) {
        $r = Run-Bot $mp ("s" + $s.id) @('--xinfa', '1', '--record', '1', '--cast', ([string]$s.id + ',0')) $s
        if (-not $r) { Log ("  skill " + $s.id + " no session"); continue }
        $res = $r.res
        $cnt = Count-Report $r.dir
        $ors = @{}
        $castKill = 0
        $cl = Join-Path $r.dir 'core-loop.tsv'
        if (Test-Path $cl) { foreach ($ln in (Get-Content $cl)) { $p = $ln.Split("`t"); if ($p.Count -ge 3 -and $p[1] -eq 'operate_result') { $ors[$p[2]] = 1 + [int]$ors[$p[2]] }; if ($p.Count -ge 3 -and $p[1] -eq 'kill') { $castKill = 1 } } }
        $combat = ''
        $fx = @(Get-ChildItem -Path $r.dir -Recurse -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -like '*.bin' } | Select-Object -First 1)
        if ($fx.Count -gt 0) { $combat = (& 'C:\Program Files\Python313\python.exe' -B (Join-Path $L 'scripts\decode_fixture.py') $fx[0].FullName ([string]$res.world.my) 2>&1 | Out-String).Trim(); Set-Content -Path (Join-Path $r.dir 'combat.json') -Value $combat -Encoding UTF8 }
        $res.core.kills = $castKill
        $orText = ($ors.GetEnumerator() | Sort-Object Name | ForEach-Object { $_.Name + 'x' + $_.Value }) -join ' '
        $listed = if ($res.core.skill_list -contains $s.id) { 1 } else { 0 }
        $tb = if ($r.log -match 'traceback=(\d+)') { $Matches[1] } else { '?' }
        $er = if ($r.log -match 'error=(\d+)') { $Matches[1] } else { '?' }
        $row = @((Get-Date -Format 'HH:mm:ss'), $mp, $s.id, $s.name, $s.xinfa, $s.xinfa_req, $s.targeting, $s.stand, $r.attempt, $r.rc, $res.in_world,
                 $res.skills.menpai, $res.skills.xinfa_count, $listed, $res.skills.casts, [int]$cnt['GCCharSkill_Send'], [int]$cnt['GCTargetListAndHitFlags'],
                 [int]$cnt['GCDetailHealsAndDamages'], [int]$cnt['GCCharDirectImpact'], [int]$cnt['GCCharBuff'], [int]$cnt['GCDetailBuff'],
                 $res.core.damage_dealt, $res.core.kills, $res.skills.cooldown_entries, $orText, $res.core.last_operate_result, $tb, $er,
                 $combat, (($res.skills.summary -replace "`t", ' ') -replace "`r?`n", ' '), $r.rel) -join "`t"
        Add-Content -Path $tsv -Value $row -Encoding UTF8
        Log ("  => skill " + $s.id + " sends=" + [int]$cnt['GCCharSkill_Send'] + " dmg_pkt=" + [int]$cnt['GCDetailHealsAndDamages'] + " dealt=" + $res.core.damage_dealt + " kill=" + $castKill + " OR=" + $orText + " tb=" + $tb + " combat=" + $combat)
    }
}
Remove-Item Env:CYS_BOT_PWD -ErrorAction SilentlyContinue
# trả CYTest00 về nguyên trạng: phái 9, tâm pháp rỗng, kỹ năng gốc, HP/MP gốc, Đại Lý (2;160,150)
for ($i = 0; $i -lt 10; $i++) {
    if ((Acquire-Lock) -and (Wait-Idle)) {
        $o1 = & wsl.exe -d TLBB -u root -- python3 -B "$Lw/scripts/char_menpai.py" restore --original "$Lw/char-original.json" --out "$Lw/char/restore-$Tag.json" 2>&1
        $rc1 = $LASTEXITCODE
        $o2 = & wsl.exe -d TLBB -u root -- python3 -B /mnt/c/TLBB/085/CY-Source/Tools/server/cs3a_move_test_char.py apply --scene 2 --x 160 --z 150 --out "$Lw/char/move-$Tag-$(Get-Date -Format HHmmss).json" 2>&1
        $rc2 = $LASTEXITCODE
        Release-Lock
        Log ("restore rc=$rc1 move rc=$rc2")
        if ($rc1 -eq 0 -and $rc2 -eq 0) { break }
    } else { Release-Lock }
    Start-Sleep -Seconds 60
}
Log 'done'



