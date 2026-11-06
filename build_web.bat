@echo off
title Build Khoa Hoc Tam Linh Web
echo ==============================================
echo   DANG TIEN HANH BUILD WEB - KHOA HOC TAM LINH
echo ==============================================

set "PATH=F:\DevTools\git\cmd;F:\DevTools\jdk\bin;F:\DevTools\flutter\bin;%PATH%"
set "JAVA_HOME=F:\DevTools\jdk"

cd /d "F:\App\KHTL"

echo [1/3] Dang tai dependencies...
call flutter pub get

echo [2/3] Dang build Web Release...
call flutter build web --release --no-tree-shake-icons

if exist "KhoaHocTamLinh.apk" (
    echo [3/3] Copy bo cai APK vao thu muc web de nguoi dung tai truc tiep...
    copy /Y "KhoaHocTamLinh.apk" "build\web\KhoaHocTamLinh.apk"
)

if exist "build\web\index.html" (
    echo ==============================================
    echo [THANH CONG] Ban Web da duoc build thanh cong tai:
    echo F:\App\KHTL\build\web
    echo ==============================================
) else (
    echo [THAT BAI] Co loi trong qua trinh build Web.
)
