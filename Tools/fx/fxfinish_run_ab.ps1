# CYS-FXFINISH: A/B mot bien so cho ban va "decal nam phang".
# Hai canh chay CUNG binary, CUNG stage, CUNG camera (doc tu dung luot CY b09-r1 da co),
# CUNG kich ban b09. Khac nhau DUNG MOT thu: CYS_FXPROJ (0 = duong ma cu, 1 = ban va).
# ASCII only (Windows PowerShell 5.1 - bay 1 cua crt-guard: mot ky tu khong-ASCII => khong chay).
#
#   -Check   : TIEN KIEM, KHONG khoi dong Game.exe. Chay duoc moi luc, ke ca khi khe dang khoa.
#   (khong)  : chay that. CHI chay sau khi dieu phoi ghi "TRA khe" VA fxfinish_slot_take.ps1
#              da ghi dong NHAN (cong khe + NHAN trong CUNG mot script - bay 12 cua fx-cy-2).
param([int]$Seconds = 175, [switch]$Check)
$ErrorActionPreference = 'Stop'
$R = 'C:\TLBB\085\CY-Source'
$WT = "$R\Build\wt-fxfinish"
$stage = "$R\Build\world-gui\stage-fxfinish"
$logs = "$R\Build\Logs\2026-09-19-fx-cy-baseline"
$out = "$R\Build\Logs\2026-09-20-fx-finish"
$reps = @{ '0' = 6; '1' = 7 }   # ours\b09-r6 = canh 0, ours\b09-r7 = canh 1 (r4/r5 la cua fx-cy-2)

# sha DA DANG KY TRUOC trong nguong-dang-ky-truoc.txt - khong sua o day, sua thi hai noi lech nhau
$GAME_SHA = '23aa289a4804aaba3da667ec63b25fcfebfb882cd8105e2344a1484d18dc4ad8'
$RENDER_SHA = '8ead92197ab219e3eed042e27cb3a31c82a5d45e5d56f032be5c0c6436f9d3fd'

function Test-Preflight {
    $bad = 0
    Write-Host '=== TIEN KIEM (khong khoi dong gi) ==='

    foreach ($p in @("$R\Tools\fx\baseline\fxbase_replay_run.ps1",
                     "$logs\batches\b09.replay.txt",
                     "$logs\batches\b09.batch.json",
                     "$stage\Bin64\Game.exe",
                     "$stage\Bin64\Render.dll",
                     "$stage\Bin64\WXSystem.cfg",
                     "$WT\Tools\fx\fxfinish_flat_ab.py")) {
        if (Test-Path -LiteralPath $p) { Write-Host ("  CO    " + $p) }
        else { Write-Host ("  THIEU " + $p); $bad++ }
    }

    # binary trong stage phai dung ban da dang ky nguong
    foreach ($pair in @(@("$stage\Bin64\Game.exe", $GAME_SHA), @("$stage\Bin64\Render.dll", $RENDER_SHA))) {
        $h = (Get-FileHash -LiteralPath $pair[0] -Algorithm SHA256).Hash.ToLower()
        if ($h -eq $pair[1]) { Write-Host ("  SHA OK   " + (Split-Path $pair[0] -Leaf) + " " + $h.Substring(0, 16)) }
        else { Write-Host ("  SHA LECH " + (Split-Path $pair[0] -Leaf) + " co " + $h.Substring(0, 16) + " can " + $pair[1].Substring(0, 16)); $bad++ }
    }

    # do phan giai phai la 1280x720 - fxbase_compare dung REGION co dinh cho khung 1280x720
    $cfg = Get-Content -LiteralPath "$stage\Bin64\WXSystem.cfg" -Encoding Byte
    $txt = [System.Text.Encoding]::ASCII.GetString($cfg)
    if ($txt -match 'View_Resoution=1280,720') { Write-Host '  DO PHAN GIAI 1280,720 OK' }
    else { Write-Host '  DO PHAN GIAI KHONG PHAI 1280,720 - bo so se TU CHOI cham'; $bad++ }

    # thu muc luot dich PHAI CHUA TON TAI (fxbase_replay_run.ps1 nem neu da co; kiem som cho ro)
    foreach ($fix in @('0', '1')) {
        $d = "$logs\ours\b09-r" + $reps[$fix]
        if (Test-Path -LiteralPath $d) { Write-Host ("  DA TON TAI (phai doi -Rep khac): " + $d); $bad++ }
        else { Write-Host ("  CHO TRONG: " + $d) }
    }

    # bo cham phai tu kiem duoc TRUOC khi dung no
    $env:PYTHONIOENCODING = 'utf-8'
    $st = & python -B "$WT\Tools\fx\fxfinish_flat_ab.py" --selftest 2>&1
    $line = ($st | Select-String -Pattern '^selftest:').ToString()
    Write-Host ('  bo cham ' + $line)
    if ($line -notmatch 'selftest: (\d+)/\1$') { Write-Host '  BO CHAM TU KIEM KHONG DU'; $bad++ }

    # khe: chi BAO, khong chan -Check (tien kiem chay duoc ca khi khe dang khoa)
    $gate = & python -B "$R\Tools\fx\projsize_slot_free.py" 2>&1
    Write-Host ('  cong khe: ' + ($gate -join ' | '))

    if ($bad -eq 0) { Write-Host '=== TIEN KIEM: SAN SANG ===' } else { Write-Host ("=== TIEN KIEM: " + $bad + " VAN DE ===") }
    return $bad
}

if ($Check) { exit (Test-Preflight) }

$bad = Test-Preflight
if ($bad -ne 0) { throw 'Tien kiem KHONG sach; khong chay.' }

foreach ($fix in @('0', '1')) {
    $rep = $reps[$fix]
    Write-Host ("=== canh CYS_FXPROJ=$fix -> ours\b09-r$rep")
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$R\Tools\fx\baseline\fxbase_replay_run.ps1" `
        -Batch b09 -Rep $rep -CamZoom ([double]0.400) -CamDir ([double]-23.21) `
        -Stage $stage -Seconds $Seconds `
        -Env ("CYS_FXPROJ=$fix;CYS_FXPROJ_LOG=1")
    Write-Host ("canh $fix rc=$LASTEXITCODE")
}

Write-Host '=== cham (nguong da dang ky truoc, KHONG lay CY lam moc) ==='
$env:PYTHONIOENCODING = 'utf-8'
& python -B "$WT\Tools\fx\fxfinish_flat_ab.py" --batch b09 --rep0 $reps['0'] --rep1 $reps['1'] `
    --game-sha $GAME_SHA --render-sha $RENDER_SHA --out "$out\ab-verdict.txt"
Write-Host ("ma thoat cua bo cham: $LASTEXITCODE  (0 = DAT, 1 = KHONG DAT, 2 = INVALID)")
