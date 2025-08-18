# Android模擬器位置修復腳本
Write-Host "🔧 Android模擬器位置修復工具" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan

# 定義Win32 API
Add-Type -TypeDefinition @"
    using System;
    using System.Runtime.InteropServices;
    using System.Text;
    
    public class Win32Api {
        [DllImport("user32.dll")]
        public static extern IntPtr FindWindow(string lpClassName, string lpWindowName);
        
        [DllImport("user32.dll")]
        public static extern IntPtr FindWindowEx(IntPtr hwndParent, IntPtr hwndChildAfter, string lpszClass, string lpszWindow);
        
        [DllImport("user32.dll")]
        public static extern bool SetWindowPos(IntPtr hWnd, IntPtr hWndInsertAfter, int X, int Y, int cx, int cy, uint uFlags);
        
        [DllImport("user32.dll")]
        public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
        
        [DllImport("user32.dll")]
        public static extern bool IsWindow(IntPtr hWnd);
        
        [DllImport("user32.dll")]
        public static extern int GetWindowText(IntPtr hWnd, StringBuilder lpString, int nMaxCount);
        
        [DllImport("user32.dll")]
        public static extern bool EnumWindows(EnumWindowsProc enumProc, IntPtr lParam);
        
        public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);
    }
"@

Write-Host "🔍 搜尋模擬器窗口..." -ForegroundColor Yellow

# 搜尋模擬器窗口
$emulatorWindows = @()
$callback = {
    param($hWnd, $lParam)
    $title = New-Object System.Text.StringBuilder 256
    [Win32Api]::GetWindowText($hWnd, $title, $title.Capacity)
    $windowTitle = $title.ToString()
    
    if ($windowTitle -like "*Android Emulator*" -or $windowTitle -like "*emulator*" -or $windowTitle -like "*Medium_Phone*") {
        $script:emulatorWindows += $hWnd
        Write-Host "  找到窗口: $windowTitle (句柄: $hWnd)" -ForegroundColor Green
    }
    return $true
}

[Win32Api]::EnumWindows($callback, [IntPtr]::Zero)

if ($emulatorWindows.Count -gt 0) {
    Write-Host "✅ 找到 $($emulatorWindows.Count) 個模擬器窗口" -ForegroundColor Green
    
    foreach ($window in $emulatorWindows) {
        Write-Host "📱 移動窗口到可見位置..." -ForegroundColor Yellow
        
        # 顯示窗口
        [Win32Api]::ShowWindow($window, 1)  # SW_SHOWNORMAL
        
        # 移動到螢幕左上角
        $result = [Win32Api]::SetWindowPos($window, [IntPtr]::Zero, 100, 100, 500, 800, 0x0040)
        
        if ($result) {
            Write-Host "✅ 窗口已移動到位置 (100, 100)" -ForegroundColor Green
        } else {
            Write-Host "❌ 移動窗口失敗" -ForegroundColor Red
        }
    }
} else {
    Write-Host "❌ 未找到模擬器窗口" -ForegroundColor Red
    Write-Host "🔄 嘗試重新啟動模擬器..." -ForegroundColor Yellow
    
    # 關閉現有模擬器
    Get-Process -Name "emulator" -ErrorAction SilentlyContinue | Stop-Process -Force
    Start-Sleep -Seconds 2
    
    # 設定Android SDK路徑
    $androidHome = "$env:LOCALAPPDATA\Android\Sdk"
    $emulatorPath = "$androidHome\emulator\emulator.exe"
    
    if (Test-Path $emulatorPath) {
        Write-Host "🚀 啟動模擬器 (縮放40%, 位置100,100)..." -ForegroundColor Yellow
        
        $arguments = "-avd Medium_Phone_API_36.0 -no-snapshot-load -gpu host -scale 0.4 -window-x 100 -window-y 100"
        Start-Process -FilePath $emulatorPath -ArgumentList $arguments -WindowStyle Hidden
        
        Write-Host "⏳ 等待模擬器啟動..." -ForegroundColor Yellow
        Start-Sleep -Seconds 10
        
        # 再次搜尋窗口
        $emulatorWindows = @()
        [Win32Api]::EnumWindows($callback, [IntPtr]::Zero)
        
        if ($emulatorWindows.Count -gt 0) {
            Write-Host "✅ 模擬器已重新啟動並定位" -ForegroundColor Green
        }
    } else {
        Write-Host "❌ 找不到模擬器執行檔: $emulatorPath" -ForegroundColor Red
    }
}

Write-Host "`n📋 如果仍然看不到模擬器，請嘗試以下方法:" -ForegroundColor Cyan
Write-Host "   1. 按 Alt+Tab 查看所有窗口" -ForegroundColor White
Write-Host "   2. 按 Win+←/→ 將窗口吸附到螢幕邊緣" -ForegroundColor White
Write-Host "   3. 按 Win+↑ 最大化窗口" -ForegroundColor White
Write-Host "   4. 檢查工作列是否有模擬器圖示" -ForegroundColor White

Write-Host "`n按任意鍵結束..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")