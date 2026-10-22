# CY-Source Tools/render/WinCapture.ps1 - window capture helpers (dot-source). CYS-COLOR (color-calib 15/09).
# Captures the client area of a top-level window of a process by HWND: PrintWindow(PW_CLIENTONLY|PW_RENDERFULLCONTENT)
# first (works for D3D9/11 swap chains on Windows 10+), CopyFromScreen of the client rectangle as fallback when the
# PrintWindow image is uniformly black. Also: PostMessage key/click helpers (no focus needed, no global input).
# ASCII only (Windows PowerShell 5.1).
Add-Type -AssemblyName System.Drawing
if (-not ('CysWin' -as [type])) {
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;
public static class CysWin {
    public delegate bool EnumProc(IntPtr h, IntPtr l);
    [StructLayout(LayoutKind.Sequential)] public struct RECT { public int L, T, R, B; }
    [StructLayout(LayoutKind.Sequential)] public struct POINT { public int X, Y; }
    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc cb, IntPtr l);
    [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
    [DllImport("user32.dll")] public static extern bool GetClientRect(IntPtr h, out RECT r);
    [DllImport("user32.dll")] public static extern bool ClientToScreen(IntPtr h, ref POINT p);
    [DllImport("user32.dll")] public static extern bool PrintWindow(IntPtr h, IntPtr hdc, uint flags);
    [DllImport("user32.dll")] public static extern bool PostMessage(IntPtr h, uint msg, IntPtr w, IntPtr l);
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
    [DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern int GetWindowText(IntPtr h, System.Text.StringBuilder s, int n);
    [DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern int GetClassName(IntPtr h, System.Text.StringBuilder s, int n);
    [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
    public static List<IntPtr> Windows(uint pid) {
        var list = new List<IntPtr>();
        EnumWindows((h, l) => { uint p; GetWindowThreadProcessId(h, out p); if (p == pid && IsWindowVisible(h)) list.Add(h); return true; }, IntPtr.Zero);
        return list;
    }
    public static string Title(IntPtr h) { var s = new System.Text.StringBuilder(512); GetWindowText(h, s, 512); return s.ToString(); }
    public static string Klass(IntPtr h) { var s = new System.Text.StringBuilder(256); GetClassName(h, s, 256); return s.ToString(); }
    public static int[] Client(IntPtr h) {
        RECT r; GetClientRect(h, out r); POINT p = new POINT(); ClientToScreen(h, ref p);
        return new int[] { p.X, p.Y, r.R - r.L, r.B - r.T };
    }
    static bool Black(Bitmap b) {
        for (int y = 0; y < b.Height; y += Math.Max(1, b.Height / 24))
            for (int x = 0; x < b.Width; x += Math.Max(1, b.Width / 32)) { Color c = b.GetPixel(x, y); if (c.R + c.G + c.B > 12) return false; }
        return true;
    }
    // mode: "print", "screen", "auto" (print, screen when print is black). Returns the method used or "" on failure.
    public static string Capture(IntPtr h, string path, string mode) {
        int[] c = Client(h); if (c[2] <= 0 || c[3] <= 0) return "";
        if (mode != "screen") {
            using (var b = new Bitmap(c[2], c[3], PixelFormat.Format32bppArgb)) {
                bool ok;
                using (var g = Graphics.FromImage(b)) { IntPtr dc = g.GetHdc(); ok = PrintWindow(h, dc, 3); g.ReleaseHdc(dc); }
                if (ok && (mode == "print" || !Black(b))) { Opaque(b).Save(path, ImageFormat.Png); return "print"; }
            }
        }
        using (var b = new Bitmap(c[2], c[3], PixelFormat.Format32bppArgb)) {
            using (var g = Graphics.FromImage(b)) g.CopyFromScreen(c[0], c[1], 0, 0, new Size(c[2], c[3]));
            Opaque(b).Save(path, ImageFormat.Png); return "screen";
        }
    }
    static Bitmap Opaque(Bitmap b) {
        var o = new Bitmap(b.Width, b.Height, PixelFormat.Format24bppRgb);
        using (var g = Graphics.FromImage(o)) g.DrawImage(b, 0, 0, b.Width, b.Height);
        return o;
    }
    public static void Key(IntPtr h, int vk) { PostMessage(h, 0x100, (IntPtr)vk, IntPtr.Zero); System.Threading.Thread.Sleep(60); PostMessage(h, 0x101, (IntPtr)vk, (IntPtr)unchecked((int)0xC0000001)); }
    public static void Click(IntPtr h, int x, int y) {
        IntPtr lp = (IntPtr)((y << 16) | (x & 0xFFFF));
        PostMessage(h, 0x200, IntPtr.Zero, lp); System.Threading.Thread.Sleep(50);
        PostMessage(h, 0x201, (IntPtr)1, lp); System.Threading.Thread.Sleep(80); PostMessage(h, 0x202, IntPtr.Zero, lp);
    }
}
'@
}
[void][CysWin]::SetProcessDPIAware()

function Get-CysMainWindow([int]$ProcessId) {
    $best = [IntPtr]::Zero; $area = 0
    foreach ($h in [CysWin]::Windows([uint32]$ProcessId)) {
        $c = [CysWin]::Client($h); $a = $c[2] * $c[3]
        if ($a -gt $area) { $area = $a; $best = $h }
    }
    return $best
}
