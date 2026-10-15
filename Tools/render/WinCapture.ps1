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
    // Read-only memory scan of a process (same user): every committed readable private/mapped region is searched for
    // a little-endian float pattern; each hit is written with +-window floats as text. Used to read the CY login camera
    // (Ogre::Frustum aspect ratio next to the FOV, near/far and the camera orientation/position).
    [DllImport("kernel32.dll")] public static extern IntPtr OpenProcess(uint access, bool inherit, int pid);
    [DllImport("kernel32.dll")] public static extern bool CloseHandle(IntPtr h);
    [DllImport("kernel32.dll")] public static extern bool ReadProcessMemory(IntPtr h, IntPtr addr, byte[] buf, IntPtr size, out IntPtr read);
    [StructLayout(LayoutKind.Sequential)] public struct MBI { public IntPtr Base; public IntPtr AllocBase; public uint AllocProtect; public IntPtr Size; public uint State; public uint Protect; public uint Type; }
    [DllImport("kernel32.dll")] public static extern IntPtr VirtualQueryEx(IntPtr h, IntPtr addr, out MBI info, IntPtr len);
    public static int ScanFloat(int pid, float value, float tol, int before, int after, string outPath, int maxHits) {
        IntPtr h = OpenProcess(0x0410, false, pid); if (h == IntPtr.Zero) return -1;
        int hits = 0;
        using (var w = new System.IO.StreamWriter(outPath)) {
            long addr = 0; MBI m;
            while (hits < maxHits && VirtualQueryEx(h, (IntPtr)addr, out m, (IntPtr)Marshal.SizeOf(typeof(MBI))) != IntPtr.Zero) {
                long size = (long)m.Size; long start = (long)m.Base;
                bool readable = m.State == 0x1000 && m.Type == 0x20000 && (m.Protect & 0x100) == 0 && (m.Protect & 0x44) != 0;
                if (readable && size < (512L << 20)) {
                    byte[] buf = new byte[size]; IntPtr got;
                    if (ReadProcessMemory(h, (IntPtr)start, buf, (IntPtr)size, out got)) {
                        int n = (int)got;
                        for (int i = 0; i + 4 <= n && hits < maxHits; i += 4) {
                            float f = BitConverter.ToSingle(buf, i);
                            if (!(Math.Abs(f - value) <= tol)) continue;   // NaN never matches
                            hits++;
                            var sb = new System.Text.StringBuilder();
                            sb.AppendFormat("hit 0x{0:X} region 0x{1:X} type 0x{2:X}\n", start + i, start, m.Type);
                            for (int j = Math.Max(0, i - before); j < Math.Min(n - 4, i + after); j += 4)
                                sb.AppendFormat("  {0:+0;-0} {1,14:G7} {2:X8}\n", j - i, BitConverter.ToSingle(buf, j), BitConverter.ToUInt32(buf, j));
                            w.Write(sb.ToString());
                        }
                    }
                }
                addr = start + size; if (addr <= 0) break;
            }
        }
        CloseHandle(h); return hits;
    }
    // CYS-AA (aa-cy 15/09): read-only 'module+rva -> pointer -> +off, count int32' probe. Returns "" on failure.
    // 'chain' = pointer offsets applied after the first dereference (module+rva -> p; p = *(p+chain[i]); ints at p+off).
    public static string ReadDeref(int pid, long moduleBase, long rva, long off, int count) { return ReadChain(pid, moduleBase, rva, new long[0], off, count); }
    public static string ReadChain(int pid, long moduleBase, long rva, long[] chain, long off, int count) {
        IntPtr h = OpenProcess(0x0410, false, pid); if (h == IntPtr.Zero) return "";
        try {
            byte[] p = new byte[8]; IntPtr got;
            if (!ReadProcessMemory(h, (IntPtr)(moduleBase + rva), p, (IntPtr)8, out got)) return "";
            long obj = BitConverter.ToInt64(p, 0); if (obj == 0) return "null";
            foreach (long c in chain) {
                if (!ReadProcessMemory(h, (IntPtr)(obj + c), p, (IntPtr)8, out got)) return "";
                obj = BitConverter.ToInt64(p, 0); if (obj == 0) return "null";
            }
            byte[] b = new byte[4 * count];
            if (!ReadProcessMemory(h, (IntPtr)(obj + off), b, (IntPtr)b.Length, out got)) return "";
            var sb = new System.Text.StringBuilder(); sb.AppendFormat("obj 0x{0:X} +0x{1:X}:", obj, off);
            for (int i = 0; i < count; i++) sb.Append(" " + BitConverter.ToInt32(b, 4 * i));
            return sb.ToString();
        } finally { CloseHandle(h); }
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
