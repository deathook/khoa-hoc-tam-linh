@echo off
title Build Khoa Hoc Tam Linh APK
echo ==============================================
echo   DANG TIEN HANH BUILD FILE APK - KHOA HOC TAM LINH
echo ==============================================

set "PATH=F:\DevTools\git\cmd;F:\DevTools\jdk\bin;F:\DevTools\flutter\bin;F:\DevTools\android-sdk\platform-tools;%PATH%"
set "JAVA_HOME=F:\DevTools\jdk"
set "ANDROID_HOME=F:\DevTools\android-sdk"
set "ANDROID_SDK_ROOT=F:\DevTools\android-sdk"

cd /d "F:\App\KHTL"

echo [1/2] Dang tai dependencies...
call flutter pub get

echo [2/2] Dang build APK Release...
call flutter build apk --release

if exist "build\app\outputs\flutter-apk\app-release.apk" (
    copy "build\app\outputs\flutter-apk\app-release.apk" "KhoaHocTamLinh.apk" /y
    echo ==============================================
    echo [THANH CONG] File APK da duoc tao tai:
    echo F:\App\KHTL\KhoaHocTamLinh.apk
    echo ==============================================
) else (
    echo [THAT BAI] Co loi trong qua trinh build.
)
