# maps-all 17/09: DO LIVE cac canh vua bat tren server rieng (15733/15734) bang CysNetBot.
#
#   powershell -NoProfile -ExecutionPolicy Bypass -File Tools\server\maps_all_live.ps1 `
#       -OutRoot Build\Logs\2026-09-17-maps-all\live-1
#   ... -Scenes 581,179        (chi do vai canh)
#   ... -Account test12 -Guid 200013
#
# PHAI chay SAU khi nguoi dieu phoi restart server rieng: `scenemanager_core:createScenes`
# (lualib/scenemanager_core.lua:178-204) chi tao canh `active=1 and type=0` LUC KHOI DONG,
# nen dat active trong SceneInfo.ini chua du de vao duoc.
#
# Khac maps_sect_live.ps1 o mot diem: cac canh nay KHONG co cong vao san (khong nam trong
# `g_mpInfo` cua chuan_song_system.lua), nen dat THANG vi tri bang
# `char_menpai.py set --scene S --pos-x X --pos-z Z`. Toa do lay tu VI TRI MOT NPC/QUAI dat
# san trong `<map>_monster.ini` (cho do chac chan dung duoc), do san trong
# Build\Logs\2026-09-17-maps-all\70-mau-live.json.
#
# Moi canh mot phien bot:
#   1. char_menpai.py restore  -> nhan vat ve ban goc
#   2. char_menpai.py set --scene S --pos-x X --pos-z Z
#   3. bot --mode world (khong noi chuyen, khong di) -> result.json + report.tsv
#   4. logcheck.sh dem traceback/error trong dung doan log cua phien do
#   5. DAT khi: final_scene == S  VA  GCNewMonster > 0  VA  traceback=0 error=0  VA  dbc=OK
# Cuoi luot tra nhan vat ve ban goc. KHONG restart, KHONG sua bang/script server.
# Mat khau doc tu .local\test-accounts.txt, KHONG ghi ra log.
param(
    [string]$OutRoot = '',
    [string]$Scenes = '581,764,1303,433,401,1322,1313,179,173,177,156,157,174,188,775',
    [string]$Account = 'test11',
    [int]$Guid = 200012,
    [string]$Bot = 'Build\bot-unknownid\CysNetBot.exe',
    [string]$Table = 'Build\Logs\2026-09-17-maps-all\70-mau-live.json',
    [string]$Static = 'Build\Logs\2026-09-15-menpai-audit\static-menpai.json',
    [int]$DwellMs = 20000,
    [int]$RestSeconds = 10,
    [string]$Owner = 'maps-all',
    # maps-instance 17/09: cho agent khac dung lai bo do voi tai khoan/GUID cua minh ma khong
    # phai chep ban goc nhan vat vao thu muc bang chung cua maps-all. De trong = hanh vi cu.
    [string]$Orig = ''
)
$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
if (-not $OutRoot) { $OutRoot = 'Build\Logs\2026-09-17-maps-all\live-' + (Get-Date -Format 'HHmmss') }
$OutAbs = Join-Path $repo $OutRoot
$null = New-Item -ItemType Directory -Force -Path $OutAbs
$null = New-Item -ItemType Directory -Force -Path (Join-Path $OutAbs 'char')
$OutW = '/mnt/c/' + ($OutAbs.Substring(3) -replace '\\', '/')
$toolsW = '/mnt/c/TLBB/085/CY-Source/Tools/server'
$staticW = '/mnt/c/' + ((Join-Path $repo $Static).Substring(3) -replace '\\', '/')
$origAbs = if ($Orig) { Join-Path $repo $Orig } else { Join-Path $repo ('Build\Logs\2026-09-17-maps-all\char\goc-{0}.json' -f $Guid) }
if (-not (Test-Path $origAbs)) {
    throw ("thieu ban goc nhan vat: $origAbs  (tao bang: char_menpai.py save-original --guid $Guid --out ...)")
}
$origW = '/mnt/c/' + ($origAbs.Substring(3) -replace '\\', '/')
$botAbs = Join-Path $repo $Bot
$logFile = Join-Path $OutAbs 'run.log'
function Log($m) { $l = (Get-Date -Format 'HH:mm:ss') + ' ' + $m; Write-Output $l; Add-Content -Path $logFile -Value $l -Encoding UTF8 }

$MAP = Get-Content (Join-Path $repo $Table) -Raw -Encoding UTF8 | ConvertFrom-Json
$want = @($Scenes.Split(',') | ForEach-Object { [int]$_.Trim() })

if ($Account -notmatch '^test(0[0-9]|1[0-5])$') { throw "account must be test00..test15: $Account" }
if ($Guid -lt 200001 -or $Guid -gt 200016) { throw "guid must be 200001..200016: $Guid" }
$line = Get-Content (Join-Path $repo '.local\test-accounts.txt') | Where-Object { $_ -like ($Account + '=*') } | Select-Object -First 1
if (-not $line) { throw "no password line for $Account" }
$env:CYS_BOT_PWD = $line.Substring($Account.Length + 1)

# khoa theo TAI KHOAN (giong menpai_check.ps1 / maps_sect_live.ps1): hai agent dung hai tai
# khoan khac nhau thi khong chan nhau
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

# Cot `dbc`: DBC client (Assets\CanonicalCY\...\SceneDefineEx.txt, cot 0 = ID CANH SERVER) co dong
# dung ban do o ID do khong. Client tra bang packet.sceneid chu KHONG phai clientres:
# CysModernHandlers.cpp:211 -> WorldManager.cpp:96-110 Search_First_Column_Equ(0, nSceneID);
# khong co dong -> TDThrow("Invalid scene ID").
$null = & wsl.exe -d TLBB -u root -- python3 -B "$toolsW/scene_install.py" survey --scenes $Scenes --out "$OutW/survey.json" 2>&1
$dbc = @{}; $act = @{}
if (Test-Path (Join-Path $OutAbs 'survey.json')) {
    foreach ($r in (Get-Content (Join-Path $OutAbs 'survey.json') -Raw -Encoding UTF8 | ConvertFrom-Json)) {
        $dbc[[int]$r.scene] = $r.client; $act[[int]$r.scene] = $r.active
    }
}
$tsv = Join-Path $OutAbs 'results.tsv'
"scene`tten`tviec`tquai_dat_san`tdbc`tactive`tfinal_scene`tnew_monster`tobjects`tcreated`ttraceback`terror`trc`tket_qua`tdir" |
    Set-Content -Path $tsv -Encoding UTF8
Log ("==== maps_all_live owner=$Owner account=$Account guid=$Guid out=$OutRoot scenes=[$Scenes]")
if (-not (Lock-Take)) { throw 'khong lay duoc khoa' }
try {
    foreach ($row in $MAP) {
        $s = [int]$row.scene
        if ($want -notcontains $s) { continue }
        if ($null -eq $row.x) { Log "  scene $s : khong co toa do dat san, bo qua"; continue }
        $null = & wsl.exe -d TLBB -u root -- python3 -B "$toolsW/menpai_audit/char_menpai.py" restore --guid $Guid --original $origW --out "$OutW/char/s$s-restore.json" --online-check self 2>&1
        if ($LASTEXITCODE -ne 0) { Log "  scene $s : restore FAILED"; continue }
        $setArgs = @('set', '--guid', [string]$Guid, '--menpai', '0', '--xinfa-level', '1',
                     '--static', $staticW, '--out', "$OutW/char/s$s-set.json", '--online-check', 'self',
                     '--scene', [string]$s, '--pos-x', ([string]$row.x), '--pos-z', ([string]$row.z))
        $null = & wsl.exe -d TLBB -u root -- python3 -B "$toolsW/menpai_audit/char_menpai.py" @setArgs 2>&1
        if ($LASTEXITCODE -ne 0) { Log "  scene $s : set FAILED"; continue }
        $mark = (& wsl.exe -d TLBB -u root -- bash "$toolsW/menpai_audit/logmark.sh" | Out-String).Trim().Split(' ')
        $rel = "$OutRoot\s$s-" + (Get-Date -Format 'HHmmss')
        $bargs = @('--mode', 'world', '--host', '127.0.0.1', '--port', '15733', '--game-port', '15734',
                   '--account', $Account, '--guid', [string]$Guid, '--out', ($rel -replace '\\', '/'),
                   '--dwell-ms', [string]$DwellMs, '--walk', '0')
        & $botAbs @bargs *> (Join-Path $OutAbs "s$s-bot-stdout.txt")
        $rc = $LASTEXITCODE
        $dir = Join-Path $repo $rel
        $lc = (& wsl.exe -d TLBB -u root -- bash "$toolsW/menpai_audit/logcheck.sh" $mark[0] $mark[1] ("$OutW/s$s-serverlog.txt") | Out-String).Trim()
        $tb = 0; $er = 0
        if ($lc -match 'traceback=(\d+) error=(\d+)') { $tb = [int]$Matches[1]; $er = [int]$Matches[2] }
        $fs = -1; $obj = -1; $cre = -1
        $rj = Join-Path $dir 'result.json'
        if (Test-Path $rj) {
            $res = Get-Content $rj -Raw -Encoding UTF8 | ConvertFrom-Json
            $fs = $res.core.final_scene; $obj = $res.world.objects; $cre = $res.world.created
        }
        $nm = 0
        $rt = Join-Path $dir 'report.tsv'
        if (Test-Path $rt) {
            $m = Get-Content $rt | Select-String -Pattern 'GCNewMonster'
            if ($m) { $nm = [int](($m[0].ToString() -split "`t")[-1]) }
        }
        $d = $dbc[$s]; if (-not $d) { $d = '?' }
        $a = $act[$s]; if (-not $a) { $a = '?' }
        # AOI chi gui GCNewMonster cho muc TRONG TAM, nen `nm` luon NHO HON so quai dat san.
        $ok = if ($fs -eq $s -and $nm -gt 0 -and $tb -eq 0 -and $er -eq 0 -and $d -eq 'OK') { 'DAT' } else { 'CHUA DAT' }
        Log ("  scene $s $($row.ten) [$($row.viec)]: dbc=$d active=$a final_scene=$fs GCNewMonster=$nm objects=$obj $lc rc=$rc -> $ok")
        ("{0}`t{1}`t{2}`t{3}`t{4}`t{5}`t{6}`t{7}`t{8}`t{9}`t{10}`t{11}`t{12}`t{13}`t{14}" -f
            $s, $row.ten, $row.viec, $row.quai, $d, $a, $fs, $nm, $obj, $cre, $tb, $er, $rc, $ok, $rel) |
            Add-Content -Path $tsv -Encoding UTF8
        Start-Sleep -Seconds $RestSeconds
    }
    $null = & wsl.exe -d TLBB -u root -- python3 -B "$toolsW/menpai_audit/char_menpai.py" restore --guid $Guid --original $origW --out "$OutW/char/cuoi-restore.json" --online-check self 2>&1
    Log ('tra nhan vat ve ban goc rc=' + $LASTEXITCODE)
} finally {
    Lock-Drop
}
Log ('xong -> ' + $tsv)
