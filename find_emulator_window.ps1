# 簡化版模擬器窗口修復腳本
Write-Host "Finding Android Emulator Window..." -ForegroundColor Cyan

# 使用Windows API移動窗口
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
using System.Text;

public class WindowHelper {
    [DllImport("user32.dll")]
    public static extern IntPtr FindWindow(string lpClassName, string lpWindowName);
    
    [DllImport("user32.dll")]
    public static extern bool SetWindowPos(IntPtr hWnd, IntPtr hWndInsertAfter, int X, int Y, int cx, int cy, uint uFlags);
    
    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
    
    [DllImport("user32.dll")]
    public static extern bool IsWindow(IntPtr hWnd);
}
"@

# 嘗試找到模擬器窗口
$windowTitles = @(
    "Android Emulator*",
    "*emulator*",
    "*Medium_Phone*"
)

$foundWindow = $false

foreach ($title in $windowTitles) {
    $window = [WindowHelper]::FindWindow($null, $title)
    if ($window -ne [IntPtr]::Zero) {
        Write-Host "Found emulator window!" -ForegroundColor Green
        [WindowHelper]::ShowWindow($window, 1)
        [WindowHelper]::SetWindowPos($window, [IntPtr]::Zero, 100, 100, 500, 800, 0x0040)
        $foundWindow = $true
        break
    }
}

if (-not $foundWindow) {
    Write-Host "No emulator window found. Restarting emulator..." -ForegroundColor Yellow
    
    # 關閉模擬器
    Stop-Process -Name "emulator*" -Force -ErrorAction SilentlyContinue
    
    # 重新啟動
    $androidHome = "$env:LOCALAPPDATA\Android\Sdk"
    $emulatorExe = "$androidHome\emulator\emulator.exe"
    
    if (Test-Path $emulatorExe) {
        Start-Process -FilePath $emulatorExe -ArgumentList "-avd Medium_Phone_API_36.0 -scale 0.4 -window-x 100 -window-y 100"
        Write-Host "Emulator restarted with visible position" -ForegroundColor Green
    }
}

Write-Host "Press Enter to continue..."
Read-Host