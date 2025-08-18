@echo off
echo 啟動Android模擬器（固定位置）...

REM 使用指定位置和大小啟動模擬器
emulator -avd Medium_Phone_API_36.0 -no-snapshot-load -wipe-data -window-x 100 -window-y 100 -window-width 480 -window-height 800

pause