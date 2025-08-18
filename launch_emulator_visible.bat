@echo off
echo 啟動Android模擬器（可見位置）...

REM 設定Android SDK路徑
set ANDROID_HOME=%LOCALAPPDATA%\Android\Sdk
set PATH=%ANDROID_HOME%\emulator;%PATH%

REM 使用具體的位置和大小參數啟動模擬器
cd /d "%ANDROID_HOME%\emulator"
emulator.exe -avd Medium_Phone_API_36.0 -no-snapshot-load -gpu host -skin 1080x2400 -scale 0.3 -window-x 100 -window-y 100

pause