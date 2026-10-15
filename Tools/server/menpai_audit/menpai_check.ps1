# menpai-verify 16/09: MỘT lệnh kiểm live kỹ năng môn phái 15 phái trên server riêng (15733/15734), chạy lại được.
#
#   powershell -NoProfile -ExecutionPolicy Bypass -File Tools\server\menpai_audit\menpai_check.ps1 `
#       -OutRoot Build\Logs\2026-09-16-menpai-verify\check-1 -Owner menpai-verify
#   ... -MenpaiList 6,12 -SkillList "471,822" -MaxSkills 3 -Study -AggregateOnly
#   ... -TargetSelf -Bot Build\bot-17-09\CysNetBot.exe   (chiêu chỉ dùng cho đồng minh: nhắm chính bot)
#   ... -AimAt pos            (chiêu đặt theo VỊ TRÍ: gửi toạ độ thay vì id đối tượng — targeting_logic 7)
#   ... -PreCast "434,-1"     (tung chiêu đặt trạng thái TRƯỚC chiêu đo, trong CÙNG một phiên -> --cast-seq)
#   ... -HpValue 3000         (đặt attrib.hp thấp trước mỗi phiên -> đo được chiêu trị liệu)
#
# Mỗi phái: chờ server rảnh -> char_menpai.py set (Mongo bản ghi test CYTest00 200001) -> mỗi kỹ năng chủ động
# (tâm pháp yêu cầu <= XinfaLevel) một phiên CysNetBot --cast <id>,0 --hunt 45,152 -> một dòng live-results.tsv.
# Với -TargetSelf thì đích là ',-1' (chính bot) thay cho ',0' (quái gần nhất); phần còn lại của luồng giữ nguyên.
# Cuối lượt trả CYTest00 nguyên trạng (phái 9, tâm pháp rỗng, kỹ năng gốc, cảnh 2 160,150) rồi gộp bảng bằng
# aggregate_check.py -> aggregate.json + table.md. KHÔNG restart, KHÔNG sửa bảng/script server.
# Mật khẩu đọc từ .local\test-accounts.txt theo ĐÚNG tài khoản (không ghi ra log). Khoá THEO TÀI KHOẢN: Build\<account>.lock.
#
# ĐO SONG SONG (bot-pos-seq 17/09): -Account test01 -Guid 200002 ... Server riêng có 16 tài khoản test00..test15 ứng
# với CYTest00..CYTest15, GUID 200001..200016. Hai tiến trình dùng hai tài khoản KHÁC nhau không chặn nhau vì:
#   * khoá là Build\<account>.lock, không còn Build\test00.lock cứng;
#   * char_menpai.py chỉ ghi ĐÚNG MỘT document theo attrib.guid;
#   * Wait-Idle bỏ điều kiện "0 kết nối trên 15733/15734" (xem chú thích tại hàm) vì con số đó là TOÀN CỤC:
#     giữ nó thì phiên của agent khác sẽ chặn chính mình và không ai chạy được.
# Chạy KHÔNG truyền -Account/-Guid/-Parallel thì mọi thứ y như trước: test00/200001, cổng chặn nghiêm ngặt.
param(
    [string]$OutRoot = '',
    [string]$MenpaiList = '0,1,2,3,4,5,6,7,8,10,11,12,13,14,15',
    [string]$SkillList = '',
    [int]$MaxSkills = 99,
    [int]$XinfaLevel = 30,
    [string]$Tag = 'live',
    [string]$Owner = 'menpai-verify',
    [string]$Bot = 'Build\wt-menpai-audit\Build\bot\CysNetBot.exe',
    [string]$Static = 'Build\Logs\2026-09-15-menpai-audit\static-menpai.json',
    [string]$CharOriginal = 'Build\Logs\2026-09-15-menpai-audit\char-original.json',
    [string]$Label = '',
    # Nghỉ giữa hai phiên bot. Mặc định 90 s là luật dùng chung CYTest00 khi có agent khác đang đo;
    # khi chỉ còn một agent thì hạ xuống ~20 s là đủ (bẫy duy nhất là server giữ phiên vài giây sau khi bot thoát,
    # đã có 10 s chờ riêng trước khi nhả khoá).
    [int]$RestSeconds = 90,
    [int]$Level = 0,                      # > 0: dat attrib.level truoc moi phien (luot do bo sung MP cao)
    [int]$MpValue = 0,                    # > 0: dat attrib.mp truoc moi phien (TEN KHAC $mp = so phai!)
    # -HpValue: > 0 -> char_menpai.py set --hp N ngay truoc moi phien. Dung de do chieu TRI LIEU (3557 金针渡劫,
    # 3558 柳暗花明): mau day thi heal_sum = 0 va khong phan biet duoc "chay" voi "khong tac dung".
    # HP ghi SAU --refill-from nen luon thang gia tri goc; server doc thang attrib.hp khi dang nhap va KHONG tu hoi day
    # (bang chung: char/last-set.json cua cac luot truoc co hp 2230 < hp_max 2250 qua nhieu phien).
    # (TEN KHAC moi bien vong lap $mp/$s/$st/$r/$res — PowerShell khong phan biet hoa thuong.)
    [int]$HpValue = 0,
    # -RageValue: > 0 -> char_menpai.py set --rage N ngay truoc moi phien. Dung cho 10 chieu doi NO KHI:
    # chung tra ve or_code -25 OR_NOT_ENOUGH_RAGE (define.lua:418) va bi xep "khong_kiem_duoc" chu KHONG phai hong.
    # (TEN KHAC moi bien vong lap $mp/$s/$st/$r/$res — PowerShell khong phan biet hoa thuong.)
    [int]$RageValue = 0,
    # -Account / -Guid: tai khoan + nhan vat cho luot nay (test00..test15 <-> 200001..200016). Mac dinh = nhu cu.
    [string]$Account = 'test00',
    [int]$Guid = 200001,
    # -Parallel: ep che do song song ngay ca khi dung test00/200001 (bo dieu kien "0 ket noi" trong Wait-Idle).
    # Truyen -Account/-Guid khac mac dinh thi tu dong bat, khong can co nay.
    [switch]$Parallel,
    [switch]$Study,
    # -TargetSelf: đổi '--cast <id>,0' (quái gần nhất) thành '--cast <id>,-1' (chính bot) để đo nhóm chiêu CHỈ dùng
    # cho đồng minh - 3557 峨嵋, 3558 天山, 3432 鬼谷, 4624 恶人谷 - vì mọi quái đều bị server trả -16 (sai phe).
    # Cần bản bot có cú pháp mới: -Bot Build\bot-17-09\CysNetBot.exe (bản cũ sẽ báo "--cast needs SKILL,TARGET").
    # (Tên KHÔNG trùng biến vòng lặp $mp/$s/$st/$r; PowerShell không phân biệt hoa thường.)
    # -ExtraSkills: id kỹ năng KHÔNG nằm trong learn_ids của phái (chiêu biến thể: 蝎行无阻 841/844/847,
    # 千机变 2922, 罂毒歌 2263, 定海神针 544...). Vừa thêm vào skill_list của nhân vật, vừa cho qua bộ lọc learn_ids.
    [string]$ExtraSkills = '',
    [switch]$TargetSelf,
    # -AimAt: hau to dich cua '--cast <id>,<dich>' cho MOI ky nang trong luot. '' = giu hanh vi cu ( ,0 hoac ,-1 khi
    # -TargetSelf ). Gia tri hop le giong bot: '0' quai gan nhat, '-1'/'self' chinh bot, '<objid>', 'pos' (vi tri cua
    # chinh bot), 'pos:DX,DZ' (vi tri bot + do lech). 'pos' la cach DUY NHAT do duoc chieu dat theo vi tri
    # (targeting_logic 7 TARGET_AE_AROUND_POSITION: 4468 诸葛神弩, 841/844/847 蝎行无阻).
    # -AimAt thang -TargetSelf khi ca hai cung co.
    [string]$AimAt = '',
    # -PreCast: cac buoc DAT TRANG THAI tung truoc chieu do, trong CUNG mot phien -> bot chay '--cast-seq "<PreCast>;<id>,<dich>"'.
    # Cu phap giong --cast-seq: "SKILL,TARGET" cach nhau bang ';'. Vi du -PreCast "434,-1" de vao trang thai 巨蝎
    # truoc khi do 841/844/847 蝎行无阻. Toi da 5 buoc dat + 1 chieu do.
    [string]$PreCast = '',
    [switch]$NoRestore,
    [switch]$AggregateOnly
)
$ErrorActionPreference = 'Continue'
$repo = 'C:\TLBB\085\CY-Source'
Set-Location $repo
if (-not $OutRoot) { $OutRoot = 'Build\Logs\{0}-menpai-check\{1}' -f (Get-Date -Format 'yyyy-MM-dd'), $Tag }
$py = 'C:\Program Files\Python313\python.exe'
# công cụ đi kèm nằm CẠNH script này (bản chép trong worktree cũng chạy được), không phải trong cây chính
$tools = $PSScriptRoot
$toolsRel = $tools
if ($tools.StartsWith($repo)) { $toolsRel = $tools.Substring($repo.Length).TrimStart('\') }
$toolsW = '/mnt/c/TLBB/085/CY-Source/' + ($toolsRel -replace '\\', '/')
# char_menpai.py / logmark.sh / logcheck.sh chỉ có ở bản gốc trong cây chính (WSL đọc qua /mnt/c)
$srvW = '/mnt/c/TLBB/085/CY-Source/Tools/server/menpai_audit'
if (-not (Test-Path (Join-Path $tools 'char_menpai.py'))) { $toolsW = $srvW }
$OutRootAbs = if ([IO.Path]::IsPathRooted($OutRoot)) { $OutRoot } else { Join-Path $repo $OutRoot }
$OutRel = $OutRootAbs.Substring($repo.Length).TrimStart('\') -replace '\\', '/'
$OutW = '/mnt/c/TLBB/085/CY-Source/' + $OutRel
New-Item -ItemType Directory -Force $OutRootAbs | Out-Null
New-Item -ItemType Directory -Force (Join-Path $OutRootAbs 'char') | Out-Null
$tsv = Join-Path $OutRootAbs 'live-results.tsv'
$runlog = Join-Path $OutRootAbs 'run.log'
$StaticAbs = if ([IO.Path]::IsPathRooted($Static)) { $Static } else { Join-Path $repo $Static }
# Đo song song: bật khi tài khoản/nhân vật khác mặc định, hoặc khi được ép bằng -Parallel.
$parMode = $Parallel.IsPresent -or $Account -ne 'test00' -or $Guid -ne 200001
# Chốt chặn của char_menpai.py set/restore: 'any' = không được còn kết nối nào (mặc định, như cũ);
# 'self' = chỉ quan tâm nhân vật này (đo song song — xem chú thích Wait-Idle và docstring char_menpai.py).
$charGate = if ($parMode) { @('--online-check', 'self') } else { @() }
# Bản gốc là file RIÊNG của từng nhân vật (char_menpai.py từ chối restore bằng bản gốc của nhân vật khác).
# Người gọi truyền -CharOriginal thì tôn trọng NGUYÊN VĂN (kiểm bằng PSBoundParameters, không so chuỗi: so chuỗi sẽ
# ghi đè cả khi người gọi cố ý truyền đúng đường dẫn mặc định); không truyền thì nhân vật khác CYTest00 dùng file
# riêng của mình, tạo lần đầu bằng save-original nếu chưa có.
if ($Guid -ne 200001 -and -not $PSBoundParameters.ContainsKey('CharOriginal')) {
    $CharOriginal = 'Build\Logs\2026-09-17-bot-pos-seq\char-original-{0}.json' -f $Guid
}
$CharOrigAbs = if ([IO.Path]::IsPathRooted($CharOriginal)) { $CharOriginal } else { Join-Path $repo $CharOriginal }
$CharOrigW = '/mnt/c/TLBB/085/CY-Source/' + ($CharOrigAbs.Substring($repo.Length).TrimStart('\') -replace '\\', '/')
$StaticW = '/mnt/c/TLBB/085/CY-Source/' + ($StaticAbs.Substring($repo.Length).TrimStart('\') -replace '\\', '/')

function Log([string]$m) {
    $line = (Get-Date -Format 'HH:mm:ss') + ' ' + $m
    Write-Host $line
    for ($k = 0; $k -lt 5; $k++) { try { [IO.File]::AppendAllText($runlog, $line + "`r`n"); break } catch { Start-Sleep -Milliseconds 200 } }
}

function Aggregate {
    $args2 = @('-X', 'utf8', '-B', (Join-Path $tools 'aggregate_check.py'), '--results', $tsv, '--static', $StaticAbs,
               '--menpai', $MenpaiList, '--xinfa-level', $XinfaLevel, '--repo', $repo)
    if ($Label) { $args2 += @('--label', $Label) }
    & $py @args2 | Tee-Object -FilePath (Join-Path $OutRootAbs 'table.txt')
    Log ('aggregate rc=' + $LASTEXITCODE + ' -> ' + (Join-Path $OutRel 'table.md'))
}

if ($AggregateOnly) { Aggregate; exit 0 }

$Menpai = @($MenpaiList.Split(',') | Where-Object { $_ -ne '' } | ForEach-Object { [int]$_ })
$Skills = @($SkillList.Split(',') | Where-Object { $_ -ne '' } | ForEach-Object { [int]$_ })
$botAbs = if ([IO.Path]::IsPathRooted($Bot)) { $Bot } else { Join-Path $repo $Bot }
if (-not (Test-Path $botAbs)) { Log ('bot not found: ' + $botAbs); exit 2 }
# -Bot mặc định vẫn là bản cũ Build\wt-menpai-audit (các lượt đo cũ tái lập được). Bản cũ KHÔNG hiểu 'pos',
# '--cast-seq' hay tài khoản khác test00 -> mọi phiên sẽ hỏng sau 5 lần thử. Hỏi --help một lần và dừng NGAY
# với thông báo rõ thay vì để hỏng lúc chạy: bản có đủ tính năng là Build\bot-17-09\CysNetBot.exe (bot-pos-seq 17/09).
$botHelp = (& $botAbs --help 2>&1 | Out-String)
$needNew = @()
if ($Account -ne 'test00' -and $botHelp -notlike '*test00..test15*') { $needNew += 'parallel accounts (--account test01..test15)' }
if ($AimAt -like 'pos*' -and $botHelp -notlike '*pos:DX,DZ*') { $needNew += 'ground target (--cast <id>,pos)' }
if ($PreCast -and $botHelp -notlike '*--cast-seq*') { $needNew += 'skill chain (--cast-seq)' }
if ($needNew.Count -gt 0) {
    Log ('this bot build does not support: ' + ($needNew -join '; ') + ' -> use -Bot Build\bot-17-09\CysNetBot.exe')
    Log ('  bot in use: ' + $botAbs)
    exit 2
}

if ($Account -notmatch '^test(0[0-9]|1[0-5])$') { Log ('account must be test00..test15: ' + $Account); exit 2 }
if ($Guid -lt 200001 -or $Guid -gt 200016) { Log ('guid must be 200001..200016: ' + $Guid); exit 2 }
$acct = Join-Path $repo '.local\test-accounts.txt'
$line = Get-Content $acct | Where-Object { $_ -like ($Account + '=*') } | Select-Object -First 1
if (-not $line) { Log ('no password line for ' + $Account + ' - abort'); exit 2 }
$env:CYS_BOT_PWD = $line.Substring($Account.Length + 1)

if (-not (Test-Path $tsv)) {
    "time`tmenpai`tskill`tname`txinfa`txinfa_req`ttargeting`tstand`tattempt`tbot_exit`tin_world`tmenpai_seen`txinfa_count`tskill_listed`tcasts`tskill_send`ttarget_lists`tdamages_pkt`tdirect_impact`tchar_buff`tdetail_buff`tdamage_dealt`tkills`tcooldown_entries`tor_codes`tlast_or`tlog_traceback`tlog_error`tcombat`tsummary`tdir" | Set-Content -Path $tsv -Encoding UTF8
}

# Khoá THEO TÀI KHOẢN: hai lượt trên hai tài khoản khác nhau không chặn nhau; cùng tài khoản thì vẫn xếp hàng
# như cũ. Build\test00.lock giữ nguyên tên cho lượt mặc định nên các lượt đang chạy vẫn khoá đúng chỗ.
$lockPath = Join-Path $repo ('Build\{0}.lock' -f $Account)
$lockPrefix = $Owner + ' '
function Acquire-Lock {
    for ($i = 0; $i -lt 120; $i++) {
        if (Test-Path $lockPath) {
            $it = Get-Item $lockPath -ErrorAction SilentlyContinue
            $txt = [string](Get-Content $lockPath -Raw -ErrorAction SilentlyContinue)
            if ($it -and ((Get-Date) - $it.LastWriteTime).TotalMinutes -lt 5 -and -not $txt.StartsWith($lockPrefix)) {
                Log ('lock held: ' + $txt.Trim() + ' (wait 30 s)'); Start-Sleep -Seconds 30; continue
            }
        }
        Set-Content -Path $lockPath -Value ($lockPrefix + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')) -Encoding ASCII
        return $true
    }
    return $false
}
function Release-Lock {
    if (Test-Path $lockPath) {
        $txt = [string](Get-Content $lockPath -Raw -ErrorAction SilentlyContinue)
        if ($txt.StartsWith($lockPrefix)) { [IO.File]::Delete($lockPath) }
    }
}
# Chờ server dùng được.
#   Mặc định (một tài khoản): như cũ — server chạy VÀ không còn kết nối nào trên 15733/15734.
#   Song song ($parMode): CHỈ đòi server chạy. Lý do: 'client connections on 15733/15734' và Get-NetTCPConnection đều
#   là số TOÀN CỤC, không tách được theo tài khoản; giữ điều kiện đó thì phiên của agent khác (hoặc của chính lượt
#   song song bên cạnh) sẽ chặn mình vĩnh viễn. Cái mà điều kiện này bảo vệ — không ghi Mongo khi nhân vật đang
#   online — giờ do KHOÁ THEO TÀI KHOẢN lo: mỗi lượt chỉ chạm đúng document attrib.guid của mình và chỉ có một
#   tiến trình giữ Build\<account>.lock. Số kết nối vẫn được ghi vào run.log để đọc lại được.
#   RỦI RO CÒN LẠI (ghi rõ, không giấu): nếu có người mở Game.exe bằng ĐÚNG tài khoản này trong lúc chạy song song
#   thì không còn chốt chặn nào bắt được — hãy đừng làm vậy, hoặc chạy lượt đó ở chế độ mặc định.
function Wait-Idle {
    for ($i = 0; $i -lt 60; $i++) {
        $tcp = @(Get-NetTCPConnection -State Established -ErrorAction SilentlyContinue | Where-Object { $_.RemotePort -in 15733,15734 -or $_.LocalPort -in 15733,15734 })
        $st = & wsl.exe -d TLBB -u root -- bash /mnt/c/TLBB/085/CY-Source/Tools/server/cys_server.sh status 2>&1
        $m = ($st | Select-String -Pattern 'client connections on 15733/15734: (\d+)').Matches
        $clients = if ($m.Count -gt 0) { [int]$m[0].Groups[1].Value } else { -1 }
        $gameRunning = ($st | Select-String -Pattern 'Game +running=True').Count
        if ($gameRunning -eq 1 -and ($parMode -or ($tcp.Count -eq 0 -and $clients -eq 0))) {
            if ($parMode -and ($tcp.Count -gt 0 -or $clients -gt 0)) {
                Log ("  parallel gate: other sessions present (tcp=" + $tcp.Count + " wsl_clients=" + $clients + ") - continue, lock is per account")
            }
            return $true
        }
        Log ("busy: tcp=" + $tcp.Count + " wsl_clients=" + $clients + " game_running=" + $gameRunning + " (wait 60 s)")
        Start-Sleep -Seconds 60
    }
    return $false
}
function Count-Report([string]$dir) {
    $h = @{}
    $rep = Join-Path $dir 'report.tsv'
    if (Test-Path $rep) { foreach ($r in (Import-Csv -Path $rep -Delimiter "`t")) { if ($r.dir -eq 'GC') { $h[$r.name] = [int]$r.count } } }
    return $h
}
function Run-Bot([int]$mp, [string]$label, [string[]]$extra) {
    for ($attempt = 1; $attempt -le 5; $attempt++) {
        if (-not (Acquire-Lock)) { Log 'lock never free - stop'; return $null }
        if (-not (Wait-Idle)) { Release-Lock; Log 'never idle - stop'; return $null }
        # đặt lại phái/tâm pháp/kỹ năng + HP/MP ngay trước mỗi phiên (nhân vật có thể dùng chung với agent khác)
        $lvArgs = @('--guid', [string]$Guid) + $charGate
        if ($Level -gt 0) { $lvArgs += @('--level', [string]$Level) }
        if ($MpValue -gt 0) { $lvArgs += @('--mp', [string]$MpValue) }
        if ($HpValue -gt 0) { $lvArgs += @('--hp', [string]$HpValue) }
        if ($RageValue -gt 0) { $lvArgs += @('--rage', [string]$RageValue) }
        if ($ExtraSkills) { $lvArgs += @('--extra-skills', $ExtraSkills) }
        $null = & wsl.exe -d TLBB -u root -- python3 -B "$toolsW/char_menpai.py" set --menpai $mp --xinfa-level $script:CurLevel --static $StaticW --refill-from $CharOrigW --out "$OutW/char/last-set.json" @lvArgs 2>&1
        if ($LASTEXITCODE -ne 0) { Release-Lock; Log '  set/refill failed (client connected?) - retry'; Start-Sleep -Seconds 60; continue }
        $mark = (& wsl.exe -d TLBB -u root -- bash "$toolsW/logmark.sh" 2>&1 | Out-String).Trim().Split(' ')
        $rel = "$OutRel/live/m$mp/$label-" + (Get-Date -Format 'HHmmss') + "-a$attempt"
        $bargs = @('--mode', 'world', '--host', '127.0.0.1', '--port', '15733', '--game-port', '15734', '--account', $Account, '--guid', [string]$Guid,
                   '--out', $rel, '--dwell-ms', '20000', '--walk', '0', '--hunt', '45,152') + $extra
        Log ("bot m$mp $label attempt $attempt : " + ($extra -join ' '))
        $t0 = Get-Date
        & $botAbs @bargs *> (Join-Path $OutRootAbs 'bot-stdout-last.txt')
        $rc = $LASTEXITCODE
        $dir = Join-Path $repo ($rel -replace '/', '\')
        $logOut = "$OutW/live/m$mp/" + (Split-Path $rel -Leaf) + "-serverlog.txt"
        $lc = (& wsl.exe -d TLBB -u root -- bash "$toolsW/logcheck.sh" $mark[0] $mark[1] $logOut 2>&1 | Out-String).Trim()
        $res = $null
        if (Test-Path (Join-Path $dir 'result.json')) { $res = Get-Content (Join-Path $dir 'result.json') -Raw | ConvertFrom-Json }
        $inWorld = $res -and $res.in_world
        Log ("  rc=$rc in_world=$inWorld elapsed=" + [int]((Get-Date) - $t0).TotalSeconds + "s log: $lc")
        Start-Sleep -Seconds 10             # server còn giữ phiên vài giây sau khi bot thoát
        Release-Lock
        Start-Sleep -Seconds $RestSeconds   # nghỉ giữa hai lượt (xem tham số -RestSeconds)
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

# LƯU Ý: tên biến PowerShell không phân biệt hoa thường; đặt tên khác [string]$Static kẻo bị ép về chuỗi
$staticData = Get-Content $StaticAbs -Raw -Encoding UTF8 | ConvertFrom-Json
# hậu tố đích của --cast cho mọi kỹ năng trong lượt: -AimAt thắng -TargetSelf, không có cả hai thì ',0' như cũ
$castAim = if ($AimAt) { $AimAt } elseif ($TargetSelf) { '-1' } else { '0' }
$castTargetKind = "$castAim" + $(if ($PreCast) { " after [$PreCast]" } else { '' })
Log ("==== menpai_check owner=$Owner out=$OutRel menpai=$MenpaiList skills=[$SkillList] xinfa=$XinfaLevel" +
     " account=$Account guid=$Guid parallel=$parMode lock=" + (Split-Path $lockPath -Leaf) +
     " cast_target=$castTargetKind hp=$HpValue mp=$MpValue rage=$RageValue level=$Level bot=$botAbs original=$CharOriginal")

# Bản gốc của nhân vật này phải có trước khi đổi phái, nếu không thì cuối lượt không trả về được.
if (-not (Test-Path $CharOrigAbs)) {
    if (-not $parMode) { Log ("char original missing: $CharOriginal - abort"); exit 2 }
    if (-not (Acquire-Lock)) { Log 'lock never free - stop'; exit 2 }
    if (-not (Wait-Idle)) { Release-Lock; Log 'never idle - stop'; exit 2 }
    $null = & wsl.exe -d TLBB -u root -- python3 -B "$toolsW/char_menpai.py" save-original --guid $Guid --out $CharOrigW 2>&1
    $rcSave = $LASTEXITCODE
    Release-Lock
    Log ("save-original guid=$Guid rc=$rcSave -> $CharOriginal")
    if ($rcSave -ne 0 -or -not (Test-Path $CharOrigAbs)) { Log 'cannot create the character original - abort'; exit 2 }
}

foreach ($mp in $Menpai) {
    $st = $staticData."$mp"
    Log ("==== menpai $mp " + $st.name + " base_xinfa=" + ($st.base_xinfa -join ','))
    if ($Study) {
        $script:CurLevel = 1
        $r = Run-Bot $mp 'study' @('--xinfa', '2')
        if ($r) { Log ("  study: " + $r.res.skills.summary + " study_results=" + $r.res.skills.study_results) }
    }
    $script:CurLevel = $XinfaLevel
    $extraIds = @($ExtraSkills -split ',' | Where-Object { $_ -match '^\s*\d+\s*$' } | ForEach-Object { [int]$_ })
    $cands = @($st.skills | Where-Object { -not $_.passive -and (($st.learn_ids -contains $_.id) -or ($extraIds -contains $_.id)) -and ($_.xinfa_req -le $XinfaLevel) })
    if ($Skills.Count -gt 0) { $cands = @($cands | Where-Object { $Skills -contains $_.id }) }
    $cands = @($cands | Select-Object -First $MaxSkills)
    Log ("  active candidates: " + (($cands | ForEach-Object { $_.id }) -join ','))
    foreach ($s in $cands) {
        # -AimAt / -TargetSelf quyết định đích; -PreCast biến một lần tung thành chuỗi --cast-seq trong CÙNG phiên
        $castArg = [string]$s.id + ',' + $castAim
        $castOpt = if ($PreCast) { @('--cast-seq', ($PreCast + ';' + $castArg)) } else { @('--cast', $castArg) }
        $r = Run-Bot $mp ("s" + $s.id) (@('--xinfa', '1', '--record', '1') + $castOpt)
        if (-not $r) { Log ("  skill " + $s.id + " no session"); continue }
        $res = $r.res
        $cnt = Count-Report $r.dir
        $ors = @{}
        $castKill = 0
        $cl = Join-Path $r.dir 'core-loop.tsv'
        if (Test-Path $cl) { foreach ($ln in (Get-Content $cl)) { $p = $ln.Split("`t"); if ($p.Count -ge 3 -and $p[1] -eq 'operate_result') { $ors[$p[2]] = 1 + [int]$ors[$p[2]] }; if ($p.Count -ge 3 -and $p[1] -eq 'kill') { $castKill = 1 } } }
        $combat = ''
        $fx = @(Get-ChildItem -Path $r.dir -Recurse -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -like '*.bin' } | Select-Object -First 1)
        if ($fx.Count -gt 0) {
            $combat = (& $py -X utf8 -B (Join-Path $tools 'decode_fixture.py') $fx[0].FullName ([string]$res.world.my) ([string]$s.id) 2>&1 | Out-String).Trim()
            Set-Content -Path (Join-Path $r.dir 'combat.json') -Value $combat -Encoding UTF8
        }
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
        Log ("  => skill " + $s.id + " sends=" + [int]$cnt['GCCharSkill_Send'] + " dmg_pkt=" + [int]$cnt['GCDetailHealsAndDamages'] + " dealt=" + $res.core.damage_dealt + " kill=" + $castKill + " OR=" + $orText + " tb=" + $tb)
    }
}
Remove-Item Env:CYS_BOT_PWD -ErrorAction SilentlyContinue

if (-not $NoRestore) {
    # trả nhân vật nguyên trạng theo BẢN GỐC CỦA CHÍNH NÓ: phái, tâm pháp, kỹ năng, level, HP/MP, cảnh + toạ độ.
    # BẪY: cs3a_move_test_char.py ghi CỨNG GUID 200001 (CYTest00). Gọi nó trong lượt của nhân vật khác sẽ dời NHẦM
    # CYTest00. Vì vậy chỉ chạy bước đó khi Guid = 200001; nhân vật khác đã được char_menpai.py restore trả
    # attrib.sceneid + attrib.world_pos về đúng bản gốc của mình (RESTORE_KEYS), nên không cần bước dời.
    for ($i = 0; $i -lt 10; $i++) {
        if ((Acquire-Lock) -and (Wait-Idle)) {
            $null = & wsl.exe -d TLBB -u root -- python3 -B "$toolsW/char_menpai.py" restore --guid $Guid --original $CharOrigW --out "$OutW/char/restore-$Tag.json" @charGate 2>&1
            $rc1 = $LASTEXITCODE
            $rc2 = 0
            if ($Guid -eq 200001) {
                $null = & wsl.exe -d TLBB -u root -- python3 -B /mnt/c/TLBB/085/CY-Source/Tools/server/cs3a_move_test_char.py apply --scene 2 --x 160 --z 150 --out "$OutW/char/move-$Tag.json" 2>&1
                $rc2 = $LASTEXITCODE
            }
            Release-Lock
            Log ("restore guid=$Guid rc=$rc1 move rc=$rc2" + $(if ($Guid -ne 200001) { ' (move skipped: cs3a_move_test_char.py is hardcoded to 200001)' } else { '' }))
            if ($rc1 -eq 0 -and $rc2 -eq 0) { break }
        } else { Release-Lock }
        Start-Sleep -Seconds 60
    }
}
Aggregate
Log 'done'
