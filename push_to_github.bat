@echo off
title Day code len GitHub
echo ========================================================
echo   DAY DU AN KHOA HOC TAM LINH LEN GITHUB
echo ========================================================

set "PATH=F:\DevTools\git\cmd;%PATH%"
cd /d "F:\App\KHTL"

if "%~1"=="" (
    echo [HUONG DAN] Vui long nhap dia chi repository GitHub cua ban.
    echo Vi du: push_to_github.bat https://github.com/username/khoahoctamlinh.git
    echo.
    set /p REPO_URL="Nhap link GitHub repository: "
) else (
    set "REPO_URL=%~1"
)

if "%REPO_URL%"=="" (
    echo [LOI] Ban chua nhap link GitHub repository.
    pause
    exit /b 1
)

echo Dang them remote origin...
git remote remove origin 2>nul
git remote add origin %REPO_URL%
git branch -M main

echo Dang day ma nguon len GitHub (main)...
git push -u origin main

if %ERRORLEVEL% EQU 0 (
    echo ========================================================
    echo [THANH CONG] Da day ma nguon len GitHub thanh cong!
    echo ========================================================
) else (
    echo ========================================================
    echo [CHU Y] Neu hien cua so dang nhap GitHub, vui long dang nhap.
    echo ========================================================
)
pause
