@echo off
title Khoa Hoc Tam Linh - Web Preview
echo ========================================================
echo   KHOI DONG BAN WEB - KHOA HOC TAM LINH
echo ========================================================
cd /d "F:\App\KHTL"

if not exist "build\web\index.html" (
    echo [THONG BAO] Ban Web chua duoc build. Dang tu dong build...
    call build_web.bat
)

echo Dang khoi chay may chu web tai: http://localhost:8080
"F:\DevTools\flutter\bin\cache\dart-sdk\bin\dart.exe" serve_web.dart
pause
