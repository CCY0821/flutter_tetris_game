@echo off
echo 🔧 修復Android模擬器位置問題...
echo.

REM 方案1：使用PowerShell將模擬器窗口移到可見位置
echo 方案1：尋找並移動模擬器窗口...
powershell -Command "Add-Type -TypeDefinition 'using System; using System.Runtime.InteropServices; public class Win32 { [DllImport(\"user32.dll\")] public static extern IntPtr FindWindow(string lpClassName, string lpWindowName); [DllImport(\"user32.dll\")] public static extern bool SetWindowPos(IntPtr hWnd, IntPtr hWndInsertAfter, int X, int Y, int cx, int cy, uint uFlags); [DllImport(\"user32.dll\")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow); }'; $emulatorWindow = [Win32]::FindWindow($null, 'Android Emulator*'); if ($emulatorWindow -ne [IntPtr]::Zero) { [Win32]::ShowWindow($emulatorWindow, 1); [Win32]::SetWindowPos($emulatorWindow, [IntPtr]::Zero, 100, 100, 600, 800, 0x0040); Write-Host '✅ 模擬器窗口已移動到可見位置'; } else { Write-Host '❌ 未找到模擬器窗口'; }"

echo.
echo 方案2：關閉模擬器並重新啟動...
taskkill /F /IM emulator.exe >nul 2>&1
timeout /t 3 >nul

REM 設定環境變數
set ANDROID_HOME=%LOCALAPPDATA%\Android\Sdk

REM 啟動模擬器並強制指定位置
echo 🚀 重新啟動模擬器...
start "" "%ANDROID_HOME%\emulator\emulator.exe" -avd Medium_Phone_API_36.0 -no-snapshot-load -gpu host -scale 0.4 -window-x 50 -window-y 50 -window-size 400x700

echo.
echo 📋 如果還是看不到，請嘗試：
echo    1. 按 Alt+Tab 切換到模擬器
echo    2. 按 Win+左箭頭 將窗口吸附到左側
echo    3. 按 Win+上箭頭 最大化窗口
echo.

pause