param([string]$SmokeJson = '', [string]$Out = '')
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'ci_common.ps1')
$P = Get-CysPaths
$env:TEMP = Join-Path $P.Root 'Build\ci\tmp'
$env:TMP = $env:TEMP
New-Item -ItemType Directory -Force $env:TEMP | Out-Null
. (Join-Path $PSScriptRoot 'ci_blank_detector.ps1')
if (-not $Out) { $Out = Join-Path $P.Root ('Build\Logs\' + (Get-Date -Format 'yyyy-MM-dd') + '-gpt-p0-2\test-' + (Get-Date -Format 'HHmmss-fffffff')) }
New-Item -ItemType Directory -Force $Out | Out-Null
if (-not $SmokeJson) {
    $stage = Read-JsonFile (Join-Path $P.Bin64 'cys_stage.json')
    if (-not $stage) { throw 'Run stage and smoke first, or pass -SmokeJson' }
    $SmokeJson = Join-Path $P.LogsCi ($stage.short + '\smoke.json')
}
$smoke = Read-JsonFile $SmokeJson
if (-not $smoke -or $smoke.result -ne 'OK' -or @($smoke.viewer).Count -lt 5) {
    throw 'Regression needs a successful smoke with at least five real viewer frames'
}
$rows = New-Object System.Collections.Generic.List[object]
function Assert-Frame([string]$Name, [string]$Path, [bool]$Expected, [string]$LogText = '', [string]$OnlyReason = '') {
    $r = Get-CysBlankFrame $Path $LogText
    $ok = $r.detected -eq $Expected
    if ($OnlyReason) { $ok = $ok -and $r.reasons.Count -eq 1 -and $r.reasons[0] -eq $OnlyReason }
    $rows.Add([ordered]@{ name = $Name; ok = $ok; expected_blank = $Expected; actual = $r; png = $Path })
    $label = if ($r.detected) { 'FAIL' } else { 'OK' }
    Write-Host ($Name + ': detector=' + $label + ' expected_blank=' + $Expected + ' bytes=' + $r.bytes + ' coverage=' + $r.coverage + ' reasons=' + ($r.reasons -join ','))
}
$oldBlank = Join-Path $P.LogsCi 'dd597ff\smoke\viewer\M25.png'
if (-not (Test-Path -LiteralPath $oldBlank) -or (Get-Item -LiteralPath $oldBlank).Length -ne 4836) { throw 'Historical M25 fixture must be the original 4836-byte PNG' }
Assert-Frame 'historical-M25' $oldBlank $true
foreach ($v in $smoke.viewer) { Assert-Frame ('real-' + $v.case) $v.png.path $false }
Assert-Frame 'failed-model-with-real-png' $smoke.viewer[0].png.path $true 'model creation failed' 'model_creation_failed'

# A valid but padded gradient isolates the coverage rule from compressed PNG size.
$padded = Join-Path $Out 'gradient-padded.png'
$bytes = [IO.File]::ReadAllBytes($oldBlank)
$payload = New-Object byte[] 25000
[Array]::Copy($bytes, $payload, $bytes.Length)
[IO.File]::WriteAllBytes($padded, $payload)
Assert-Frame 'coverage-only' $padded $true '' 'coverage_under_0.5pct'

# Broad black/white halves have full coverage, but compress below 20 KB.
$small = Join-Path $Out 'small-checker.png'
$bitmap = New-Object Drawing.Bitmap(1280, 720)
$g = [Drawing.Graphics]::FromImage($bitmap)
try {
    $g.Clear([Drawing.Color]::Black)
    $g.FillRectangle([Drawing.Brushes]::White, 0, 0, 640, 720)
    $bitmap.Save($small, [Drawing.Imaging.ImageFormat]::Png)
} finally { $g.Dispose(); $bitmap.Dispose() }
Assert-Frame 'size-only' $small $true '' 'png_under_20kb'
Assert-Frame 'missing-png' (Join-Path $Out 'absent.png') $true '' 'png_missing'
$broken = Join-Path $Out 'invalid.png'
[IO.File]::WriteAllText($broken, 'not a PNG')
Assert-Frame 'invalid-png' $broken $true '' 'png_unreadable'
$bad = @($rows | Where-Object { -not $_.ok })
Write-JsonFile ([ordered]@{ smoke = $SmokeJson; checks = $rows.ToArray(); passed = $rows.Count - $bad.Count; failed = $bad.Count }) (Join-Path $Out 'results.json')
Write-Host ('BLANK DETECTOR: ' + ($rows.Count - $bad.Count) + '/' + $rows.Count + ' checks passed; failures=' + $bad.Count + '; ' + $Out)
if ($bad.Count) { exit 1 }
exit 0
