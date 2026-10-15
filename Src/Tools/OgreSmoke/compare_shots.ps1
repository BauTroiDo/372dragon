# CYS: side-by-side before/after sheets for OgreSmoke runs (2026-09-12). Windows PowerShell 5.1.
#   powershell -NoProfile -File compare_shots.ps1 -Before <dir> -After <dir> -Out <dir> [-Labels <models list>]
# Writes compare_grid.png (both grid.png stacked) and compare_shots.png (each shot_NN.png pair,
# centre crop, before left / after right, 4 pairs per row).
param(
    [Parameter(Mandatory = $true)][string]$Before,
    [Parameter(Mandatory = $true)][string]$After,
    [Parameter(Mandatory = $true)][string]$Out,
    [string]$Labels = ""
)
Add-Type -AssemblyName System.Drawing
New-Item -ItemType Directory -Force $Out | Out-Null

$names = @()
if ($Labels -and (Test-Path $Labels)) {
    foreach ($l in (Get-Content $Labels -Encoding UTF8)) {
        if ($l.Trim() -eq "" -or $l.TrimStart().StartsWith("#")) { continue }
        $names += ($l -split "`t")[0]
    }
}

$font = [System.Drawing.Font]::new("Segoe UI", [single]13, [System.Drawing.FontStyle]::Bold)
$brush = [System.Drawing.Brushes]::White

function Rect([int]$x, [int]$y, [int]$w, [int]$h) { return [System.Drawing.Rectangle]::new($x, $y, $w, $h) }
# centre crop covering the same field of view whatever the capture size (sized for 1920x1080 shots)
function CenterCrop($img) {
    $w = [int]($img.Width * $cw / 1920)
    $h = [int]($img.Height * $ch / 1080)
    return Rect ([int](($img.Width - $w) / 2)) ([int](($img.Height - $h) / 2)) $w $h
}

# grid: before on top, after below, at half size
$gb = [System.Drawing.Image]::FromFile((Join-Path $Before "grid.png"))
$ga = [System.Drawing.Image]::FromFile((Join-Path $After "grid.png"))
$w = [int]($gb.Width / 2)
$h = [int]($gb.Height / 2)
$sheet = [System.Drawing.Bitmap]::new($w, [int]($h * 2))
$g = [System.Drawing.Graphics]::FromImage($sheet)
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$g.DrawImage($gb, (Rect 0 0 $w $h))
$g.DrawImage($ga, (Rect 0 $h $w $h))
$g.DrawString("BEFORE (OGRE 0.85 material path)", $font, $brush, [single]10, [single]8)
$g.DrawString("AFTER (B auto constants + keywords + runtime VS variants)", $font, $brush, [single]10, [single]($h + 8))
$sheet.Save((Join-Path $Out "compare_grid.png"), [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose(); $sheet.Dispose(); $gb.Dispose(); $ga.Dispose()

# shots: centre crop of each 1920x1080 shot, before | after
$shots = @(Get-ChildItem -Path $After -Filter "shot_*.png" | Sort-Object Name)
$cw = 640
$ch = 760
$perRow = 4
$rows = [int][math]::Ceiling($shots.Count / $perRow)
$cellW = $cw * 2 + 12
$cellH = $ch + 34
$sheet = [System.Drawing.Bitmap]::new([int]($cellW * $perRow), [int]($cellH * $rows))
$g = [System.Drawing.Graphics]::FromImage($sheet)
$g.Clear([System.Drawing.Color]::FromArgb(20, 20, 24))
for ($i = 0; $i -lt $shots.Count; $i++) {
    $a = [System.Drawing.Image]::FromFile($shots[$i].FullName)
    $bPath = Join-Path $Before $shots[$i].Name
    $x0 = [int](($i % $perRow) * $cellW)
    $y0 = [int]([math]::Floor($i / $perRow) * $cellH)
    if (Test-Path $bPath) {
        $b = [System.Drawing.Image]::FromFile($bPath)
        $g.DrawImage($b, (Rect $x0 ($y0 + 30) $cw $ch), (CenterCrop $b), [System.Drawing.GraphicsUnit]::Pixel)
        $b.Dispose()
    }
    $g.DrawImage($a, (Rect ($x0 + $cw) ($y0 + 30) $cw $ch), (CenterCrop $a), [System.Drawing.GraphicsUnit]::Pixel)
    $a.Dispose()
    $label = $shots[$i].BaseName
    if ($i -lt $names.Count) { $label = $label + "  " + $names[$i] }
    $g.DrawString($label + "   (before | after)", $font, $brush, [single]($x0 + 6), [single]($y0 + 4))
}
$sheet.Save((Join-Path $Out "compare_shots.png"), [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose(); $sheet.Dispose()
"wrote " + (Join-Path $Out "compare_grid.png") + " and compare_shots.png (" + $shots.Count + " pairs)"
