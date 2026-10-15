# maps-sect 17/09: ĐO LIVE 12 bản đồ môn phái trên server riêng (15733/15734) bằng CysNetBot — chạy lại được.
#
#   powershell -NoProfile -ExecutionPolicy Bypass -File Tools\server\maps_sect_live.ps1 `
#       -OutRoot Build\Logs\2026-09-17-maps-sect\live-1
#   ... -Scenes 9,10            (chỉ đo vài cảnh)
#   ... -Account test02 -Guid 200003
#
# PHẢI chạy SAU khi người điều phối restart server riêng: `scenemanager_core:createScenes` chỉ tạo cảnh
# `active=1 and type=0` LÚC KHỞI ĐỘNG, nên bật active trong SceneInfo.ini chưa đủ để vào được.
#
# Mỗi cảnh một phiên bot:
#   1. char_menpai.py restore  -> nhân vật về cảnh 2 Đại Lý (160,150), môn phái gốc
#   2. char_menpai.py set --menpai M  (M = môn phái mà cảnh đó là "tổng đàn")
#      Cảnh KHÔNG có cổng vào (495 唐家堡) thì thêm --scene/--pos-x/--pos-z để đặt thẳng điểm xuất phát.
#   3. bot --talk 253,121 --talk-option 1000  ("Trở về Môn phái" của 驿站老板 崔逢九, script 990010
#      chuan_song_system.lua:80 -> g_mpInfo -> TransferFunc). Cảnh không cổng thì chỉ đăng nhập.
#   4. logcheck.sh đếm traceback/error trong đoạn log Game2 của đúng phiên đó.
#   5. Bằng chứng mỗi cảnh: result.json (core.final_scene, quest.transferred) + report.tsv (GCNewMonster).
# Cuối lượt trả nhân vật về bản gốc. KHÔNG restart, KHÔNG sửa bảng/script server.
# Mật khẩu đọc từ .local\test-accounts.txt theo đúng tài khoản, KHÔNG ghi ra log.
param(
    [string]$OutRoot = '',
    [string]$Scenes = '9,10,11,12,13,14,15,16,17,495,987,1358',
    [string]$Account = 'test01',
    [int]$Guid = 200002,
    [string]$Bot = 'Build\bot-unknownid\CysNetBot.exe',
    [string]$Original = 'Build\Logs\2026-09-17-bot-pos-seq\char-original-200002.json',
    [string]$Static = 'Build\Logs\2026-09-15-menpai-audit\static-menpai.json',
    [int]$DwellMs = 20000,
    [int]$RestSeconds = 15,
    [string]$Owner = 'maps-sect'
)
$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
if (-not $OutRoot) { $OutRoot = 'Build\Logs\2026-09-17-maps-sect\live-' + (Get-Date -Format 'HHmmss') }
$OutAbs = Join-Path $repo $OutRoot
$null = New-Item -ItemType Directory -Force -Path $OutAbs
$null = New-Item -ItemType Directory -Force -Path (Join-Path $OutAbs 'char')
$OutW = '/mnt/c/' + ($OutAbs.Substring(3) -replace '\\', '/')
$toolsW = '/mnt/c/TLBB/085/CY-Source/Tools/server'
$staticW = '/mnt/c/' + ((Join-Path $repo $Static).Substring(3) -replace '\\', '/')
$origW = '/mnt/c/' + ((Join-Path $repo $Original).Substring(3) -replace '\\', '/')
$botAbs = Join-Path $repo $Bot
$logFile = Join-Path $OutAbs 'run.log'
function Log($m) { $l = (Get-Date -Format 'HH:mm:ss') + ' ' + $m; Write-Output $l; Add-Content -Path $logFile -Value $l -Encoding UTF8 }

# Bảng cảnh. menpai = ô define.MENPAI_ATTRIBUTE mà chuan_song_system.lua g_mpInfo gắn với cảnh đó.
# x,z = toạ độ đích trong chính g_mpInfo (cột 3/4). gate=$false -> không có cổng, đặt thẳng vị trí.
$MAP = @(
    # 987 Ác Nhân Cốc: ID CẢNH MỚI (17/09) vì DBC client dòng 1063 là 凌云窟, dòng 987 mới là erengu.Scene.
    # transfer-npc đã đổi g_mpInfo 1063 -> 987 (chuan_song_system.lua:13) nên đi được bằng mục 1000.
    @{ scene = 987;  ten = 'Ac Nhan Coc';  menpai = 15; x = 125; z = 152; gate = $true },
    @{ scene = 9;    ten = 'Thieu Lam';    menpai = 0;  x = 96;  z = 127; gate = $true },
    @{ scene = 10;   ten = 'Cai Bang';     menpai = 2;  x = 91;  z = 116; gate = $true },
    @{ scene = 11;   ten = 'Minh Giao';    menpai = 1;  x = 98;  z = 167; gate = $true },
    @{ scene = 12;   ten = 'Vo Dang';      menpai = 3;  x = 103; z = 140; gate = $true },
    @{ scene = 13;   ten = 'Thien Long';   menpai = 6;  x = 96;  z = 120; gate = $true },
    @{ scene = 14;   ten = 'Tieu Dao';     menpai = 8;  x = 67;  z = 145; gate = $true },
    @{ scene = 15;   ten = 'Nga Mi';       menpai = 4;  x = 89;  z = 139; gate = $true },
    @{ scene = 16;   ten = 'Tinh Tu';      menpai = 5;  x = 96;  z = 152; gate = $true },
    @{ scene = 17;   ten = 'Thien Son';    menpai = 7;  x = 95;  z = 120; gate = $true },
    # 495 唐家堡: KHÔNG nằm trong g_mpInfo (唐门 không có ô menpai) — transfer-npc thêm mục riêng
    # index 1022 "Thành thị - Đường Gia Bảo" vào chính NPC 驿站 (chuan_song_system.lua:78).
    @{ scene = 495;  ten = 'Duong Gia Bao'; menpai = 0; x = 126; z = 68;  gate = $true; opt = 1022 },
    @{ scene = 1358; ten = 'Mo Dung';      menpai = 10; x = 28;  z = 133; gate = $true }
)
$want = @($Scenes.Split(',') | ForEach-Object { [int]$_.Trim() })

if ($Account -notmatch '^test(0[0-9]|1[0-5])$') { throw "account must be test00..test15: $Account" }
if ($Guid -lt 200001 -or $Guid -gt 200016) { throw "guid must be 200001..200016: $Guid" }
$line = Get-Content (Join-Path $repo '.local\test-accounts.txt') | Where-Object { $_ -like ($Account + '=*') } | Select-Object -First 1
if (-not $line) { throw "no password line for $Account" }
$env:CYS_BOT_PWD = $line.Substring($Account.Length + 1)

# khoá theo TÀI KHOẢN (như menpai_check.ps1): hai agent dùng hai tài khoản khác nhau không chặn nhau
$lockPath = Join-Path $repo ('Build\{0}.lock' -f $Account)
function Lock-Take {
    for ($i = 0; $i -lt 60; $i++) {
        if (Test-Path $lockPath) {
            $it = Get-Item $lockPath -ErrorAction SilentlyContinue
            $txt = [string](Get-Content $lockPath -Raw -ErrorAction SilentlyContinue)
            if ($it -and ((Get-Date) - $it.LastWriteTime).TotalMinutes -lt 5 -and -not $txt.StartsWith($Owner + ' ')) {
                Log ('lock held: ' + $txt.Trim() + ' (cho 30 s)'); Start-Sleep -Seconds 30; continue
            }
        }
        Set-Content -Path $lockPath -Value ($Owner + ' ' + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')) -Encoding ASCII
        return $true
    }
    return $false
}
function Lock-Drop { if (Test-Path $lockPath) { Remove-Item $lockPath -Force -ErrorAction SilentlyContinue } }

# Cột `dbc` = bảng DBC client (Assets\CanonicalCY, cột 0 = ID CẢNH SERVER) có dòng đúng bản đồ ở ID đó không.
# Client CY-Source tra bản đồ bằng packet.sceneid, KHÔNG phải clientres: CysModernHandlers.cpp:211 ->
# WorldManager.cpp:96-110 Search_First_Column_Equ(SCENE_SERVER_ID_COLUMN=0, nSceneID); không có dòng -> TDThrow.
$null = & wsl.exe -d TLBB -u root -- python3 -B "$toolsW/scene_install.py" survey --scenes $Scenes --out "$OutW/survey.json" 2>&1
$dbc = @{}
if (Test-Path (Join-Path $OutAbs 'survey.json')) {
    foreach ($r in (Get-Content (Join-Path $OutAbs 'survey.json') -Raw -Encoding UTF8 | ConvertFrom-Json)) { $dbc[[int]$r.scene] = $r.client }
}
$tsv = Join-Path $OutAbs 'results.tsv'
"scene`tten`tmenpai`tgate`tdbc`tfinal_scene`ttransferred`tnew_monster`tobjects`tcreated`ttraceback`terror`trc`tdir" | Set-Content -Path $tsv -Encoding UTF8
Log ("==== maps_sect_live owner=$Owner account=$Account guid=$Guid out=$OutRoot scenes=[$Scenes] bot=$botAbs")
if (-not (Lock-Take)) { throw 'khong lay duoc khoa' }
try {
    foreach ($row in $MAP) {
        if ($want -notcontains $row.scene) { continue }
        $s = $row.scene
        $null = & wsl.exe -d TLBB -u root -- python3 -B "$toolsW/menpai_audit/char_menpai.py" restore --guid $Guid --original $origW --out "$OutW/char/s$s-restore.json" --online-check self 2>&1
        if ($LASTEXITCODE -ne 0) { Log "  scene $s : restore FAILED"; continue }
        $setArgs = @('set', '--guid', [string]$Guid, '--menpai', [string]$row.menpai, '--xinfa-level', '1',
                     '--static', $staticW, '--out', "$OutW/char/s$s-set.json", '--online-check', 'self')
        if (-not $row.gate) { $setArgs += @('--scene', [string]$s, '--pos-x', [string]$row.x, '--pos-z', [string]$row.z) }
        $null = & wsl.exe -d TLBB -u root -- python3 -B "$toolsW/menpai_audit/char_menpai.py" @setArgs 2>&1
        if ($LASTEXITCODE -ne 0) { Log "  scene $s : set FAILED"; continue }
        $mark = (& wsl.exe -d TLBB -u root -- bash "$toolsW/menpai_audit/logmark.sh" | Out-String).Trim().Split(' ')
        $rel = "$OutRoot\s$s-" + (Get-Date -Format 'HHmmss')
        $bargs = @('--mode', 'world', '--host', '127.0.0.1', '--port', '15733', '--game-port', '15734',
                   '--account', $Account, '--guid', [string]$Guid, '--out', ($rel -replace '\\', '/'),
                   '--dwell-ms', [string]$DwellMs, '--walk', '0')
        # mục 1000 = "Trở về Môn phái" (tra g_mpInfo theo attrib.menpai); cảnh nào có mục riêng thì đặt `opt`
        if ($row.gate) {
            $opt = if ($row.ContainsKey('opt')) { [string]$row.opt } else { '1000' }
            $bargs += @('--talk', '253,121', '--talk-option', $opt)
        }
        & $botAbs @bargs *> (Join-Path $OutAbs "s$s-bot-stdout.txt")
        $rc = $LASTEXITCODE
        $dir = Join-Path $repo $rel
        $lc = (& wsl.exe -d TLBB -u root -- bash "$toolsW/menpai_audit/logcheck.sh" $mark[0] $mark[1] ("$OutW/s$s-serverlog.txt") | Out-String).Trim()
        $tb = 0; $er = 0
        if ($lc -match 'traceback=(\d+) error=(\d+)') { $tb = [int]$Matches[1]; $er = [int]$Matches[2] }
        $fs = -1; $tr = 'false'; $obj = -1; $cre = -1
        $rj = Join-Path $dir 'result.json'
        if (Test-Path $rj) {
            $res = Get-Content $rj -Raw -Encoding UTF8 | ConvertFrom-Json
            $fs = $res.core.final_scene; $obj = $res.world.objects; $cre = $res.world.created
            if ($res.quest -and $res.quest.transferred) { $tr = 'true' }
        }
        $nm = 0
        $rt = Join-Path $dir 'report.tsv'
        if (Test-Path $rt) {
            $m = Get-Content $rt | Select-String -Pattern 'GCNewMonster'
            if ($m) { $nm = [int](($m[0].ToString() -split "`t")[-1]) }
        }
        $d = $dbc[[int]$s]; if (-not $d) { $d = '?' }
        $ok = if ($fs -eq $s -and $nm -gt 0 -and $tb -eq 0 -and $er -eq 0 -and $d -eq 'OK') { 'OK' } else { 'CHUA DAT' }
        Log ("  scene $s $($row.ten): dbc=$d final_scene=$fs transferred=$tr GCNewMonster=$nm objects=$obj $lc rc=$rc -> $ok")
        ("{0}`t{1}`t{2}`t{3}`t{4}`t{5}`t{6}`t{7}`t{8}`t{9}`t{10}`t{11}`t{12}`t{13}" -f $s, $row.ten, $row.menpai, $row.gate, $d, $fs, $tr, $nm, $obj, $cre, $tb, $er, $rc, $rel) |
            Add-Content -Path $tsv -Encoding UTF8
        Start-Sleep -Seconds $RestSeconds
    }
    $null = & wsl.exe -d TLBB -u root -- python3 -B "$toolsW/menpai_audit/char_menpai.py" restore --guid $Guid --original $origW --out "$OutW/char/cuoi-restore.json" --online-check self 2>&1
    Log ('tra nhan vat ve ban goc rc=' + $LASTEXITCODE)
} finally {
    Lock-Drop
}
Log ('xong -> ' + $tsv)
