# CYS-PERF: process launcher shared by the perf runners (dot-source it).
# Invoke-CysPerfProcess starts an executable with a given environment (inherited, then restored), shows its window
# without taking the focus (SW_SHOWNOACTIVATE) or hides it, waits up to a timeout and kills only that process.
if (-not ('CysPerfLaunch' -as [type])) {
    Add-Type -TypeDefinition @'
using System;
using System.ComponentModel;
using System.Runtime.InteropServices;
using System.Text;
public static class CysPerfLaunch {
    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    struct STARTUPINFO {
        public int cb; public string lpReserved; public string lpDesktop; public string lpTitle;
        public int dwX, dwY, dwXSize, dwYSize, dwXCountChars, dwYCountChars, dwFillAttribute, dwFlags;
        public short wShowWindow, cbReserved2; public IntPtr lpReserved2, hStdInput, hStdOutput, hStdError;
    }
    [StructLayout(LayoutKind.Sequential)]
    struct PROCESS_INFORMATION { public IntPtr hProcess, hThread; public int dwProcessId, dwThreadId; }
    [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    static extern bool CreateProcessW(string app, StringBuilder cmd, IntPtr pa, IntPtr ta, bool inherit, uint flags,
                                      IntPtr env, string cwd, ref STARTUPINFO si, out PROCESS_INFORMATION pi);
    [DllImport("kernel32.dll")] static extern bool CloseHandle(IntPtr h);
    // show: 4 = SW_SHOWNOACTIVATE (visible, keeps the user's focus), 0 = SW_HIDE
    public static int Start(string exe, string args, string cwd, short show) {
        STARTUPINFO si = new STARTUPINFO();
        si.cb = Marshal.SizeOf(typeof(STARTUPINFO));
        si.dwFlags = 1; // STARTF_USESHOWWINDOW
        si.wShowWindow = show;
        PROCESS_INFORMATION pi;
        StringBuilder cmd = new StringBuilder("\"" + exe + "\" " + args);
        if (!CreateProcessW(exe, cmd, IntPtr.Zero, IntPtr.Zero, false, 0, IntPtr.Zero, cwd, ref si, out pi))
            throw new Win32Exception(Marshal.GetLastWin32Error());
        CloseHandle(pi.hThread);
        CloseHandle(pi.hProcess);
        return pi.dwProcessId;
    }
}
'@
}

function Invoke-CysPerfProcess {
    param(
        [Parameter(Mandatory=$true)][string]$Exe,
        [string]$Arguments = '',
        [Parameter(Mandatory=$true)][string]$WorkingDirectory,
        [System.Collections.IDictionary]$Env = @{},
        [int]$TimeoutSeconds = 300,
        [switch]$Hidden
    )
    $saved = @{}
    foreach ($k in @($Env.Keys) + @('CYS_BOT_PWD','CYS_WSL_LOGIN_TEST')) { $saved[$k] = [Environment]::GetEnvironmentVariable($k, 'Process') }
    $result = [ordered]@{ exe = $Exe; pid = $null; exit_code = $null; timed_out = $false; seconds = 0.0; error = $null }
    $clock = [Diagnostics.Stopwatch]::StartNew()
    try {
        [Environment]::SetEnvironmentVariable('CYS_BOT_PWD', $null, 'Process')
        [Environment]::SetEnvironmentVariable('CYS_WSL_LOGIN_TEST', $null, 'Process')
        foreach ($k in $Env.Keys) { [Environment]::SetEnvironmentVariable($k, [string]$Env[$k], 'Process') }
        $show = if ($Hidden) { [int16]0 } else { [int16]4 }
        $procId = [CysPerfLaunch]::Start($Exe, $Arguments, $WorkingDirectory, $show)
        $result.pid = $procId
        $proc = Get-Process -Id $procId -ErrorAction SilentlyContinue
        if ($proc) {
            if (-not $proc.WaitForExit($TimeoutSeconds * 1000)) {
                $result.timed_out = $true
                Stop-Process -Id $procId -Force
                $proc.WaitForExit(10000) | Out-Null
            }
            try { $result.exit_code = $proc.ExitCode } catch { }
        }
    } catch {
        $result.error = $_.Exception.Message
    } finally {
        foreach ($k in $saved.Keys) { [Environment]::SetEnvironmentVariable($k, $saved[$k], 'Process') }
    }
    $result.seconds = $clock.Elapsed.TotalSeconds
    return $result
}
