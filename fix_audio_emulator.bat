@echo off
echo 🔧 修復Android模擬器音頻問題...
echo =================================

echo 🔇 關閉現有模擬器...
taskkill /f /im emulator.exe 2>nul

echo ⏳ 等待進程完全關閉...
timeout /t 3 /nobreak >nul

echo 🎵 啟動模擬器（強制音頻支援）...
emulator -avd TestPhone -audio-out default -audio-in default -window-x 100 -window-y 100 -scale 0.4 -gpu host -verbose

pause