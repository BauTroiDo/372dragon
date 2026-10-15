# CYS: deterministic blank-frame gate shared by smoke and its regression test.
if (-not ('CysBlankPixels' -as [type])) {
    Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;

public sealed class CysBlankPixels {
    public int Width;
    public int Height;
    public double Coverage;
    public static CysBlankPixels Inspect(string path) {
        using (var input = new Bitmap(path))
        using (var bitmap = new Bitmap(input.Width, input.Height, PixelFormat.Format32bppArgb)) {
            using (var graphics = Graphics.FromImage(bitmap)) graphics.DrawImageUnscaled(input, 0, 0);
            var data = bitmap.LockBits(new Rectangle(0, 0, bitmap.Width, bitmap.Height),
                ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb);
            long covered = 0;
            try {
                var bytes = new byte[bitmap.Width * 4];
                var luma = new int[bitmap.Width];
                var histogram = new int[256];
                for (int y = 0; y < bitmap.Height; ++y) {
                    Marshal.Copy(IntPtr.Add(data.Scan0, y * data.Stride), bytes, 0, bytes.Length);
                    Array.Clear(histogram, 0, histogram.Length);
                    for (int x = 0; x < bitmap.Width; ++x) {
                        int p = x * 4;
                        int value = (299 * bytes[p + 2] + 587 * bytes[p + 1] + 114 * bytes[p] + 500) / 1000;
                        luma[x] = value;
                        ++histogram[value];
                    }
                    int left = (bitmap.Width - 1) / 2, right = bitmap.Width / 2;
                    int seen = 0, low = -1, high = 0;
                    for (int v = 0; v < histogram.Length; ++v) {
                        seen += histogram[v];
                        if (low < 0 && seen > left) low = v;
                        if (seen > right) { high = v; break; }
                    }
                    double median = (low + high) / 2.0;
                    for (int x = 0; x < bitmap.Width; ++x)
                        if (Math.Abs(luma[x] - median) > 12.0) ++covered;
                }
            } finally { bitmap.UnlockBits(data); }
            return new CysBlankPixels { Width = bitmap.Width, Height = bitmap.Height,
                Coverage = (double)covered / ((long)bitmap.Width * bitmap.Height) };
        }
    }
}
'@
}

function Get-CysBlankFrame {
    param([string]$PngPath, [string]$LogText = '')
    $reasons = New-Object System.Collections.Generic.List[string]
    $result = [ordered]@{ detected = $false; coverage = $null; width = $null; height = $null; bytes = $null; reasons = @() }
    if ($LogText -match '(?i)model creation failed') { $reasons.Add('model_creation_failed') }
    if (-not $PngPath -or -not (Test-Path -LiteralPath $PngPath -PathType Leaf)) {
        $reasons.Add('png_missing')
    } else {
        $result.bytes = (Get-Item -LiteralPath $PngPath).Length
        try {
            $pixels = [CysBlankPixels]::Inspect($PngPath)
            $result.width = $pixels.Width
            $result.height = $pixels.Height
            $result.coverage = $pixels.Coverage
            if ($pixels.Width -eq 1280 -and $pixels.Height -eq 720 -and $result.bytes -lt 20KB) {
                $reasons.Add('png_under_20kb')
            }
            if ($pixels.Coverage -lt 0.005) { $reasons.Add('coverage_under_0.5pct') }
        } catch {
            $reasons.Add('png_unreadable')
            $result.error = $_.Exception.Message
        }
    }
    $result.detected = $reasons.Count -gt 0
    $result.reasons = $reasons.ToArray()
    return $result
}
