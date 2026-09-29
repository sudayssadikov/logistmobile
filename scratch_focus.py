import subprocess

cmd = '''powershell -NoProfile -Command "
Add-Type -TypeDefinition '@\"
using System;
using System.Runtime.InteropServices;
public class WinUtil {
    [DllImport(\\\"user32.dll\\\")]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool SetForegroundWindow(IntPtr hWnd);

    [DllImport(\\\"user32.dll\\\")]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
}
\"@'

$processes = Get-Process chrome -ErrorAction SilentlyContinue
foreach ($p in $processes) {
    if ($p.MainWindowHandle -ne 0 -and $p.MainWindowTitle -ne '') {
        Write-Host ('Title: ' + $p.MainWindowTitle + ' (PID: ' + $p.Id + ')')
        [WinUtil]::ShowWindow($p.MainWindowHandle, 9)
        [WinUtil]::SetForegroundWindow($p.MainWindowHandle)
    }
}
"'''

p = subprocess.run(cmd, shell=True, capture_output=True, text=True)
print("STDOUT:", p.stdout)
print("STDERR:", p.stderr)
