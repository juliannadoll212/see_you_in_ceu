@echo off
setlocal enabledelayedexpansion

echo Starting build and run process...

:: Clean Flutter build cache and get dependencies
echo Cleaning Flutter build cache...
call flutter clean
echo Getting dependencies...
call flutter pub get

echo Building APK...
cd android
call build_apk.bat
if %ERRORLEVEL% neq 0 (
    echo Direct build failed, attempting Flutter build...
    cd ..
    call flutter build apk --debug
) else (
    cd ..
)

:: Create marker file to track successful build
echo Build completed > build\.build_completed

:: Check all possible APK locations
set "APK_FOUND=false"
set "APK_PATHS=build\app\outputs\flutter-apk\app-debug.apk build\app\outputs\apk\debug\app-debug.apk"

for %%a in (%APK_PATHS%) do (
    if exist "%%a" (
        echo Found APK at: %%a
        set "APK_PATH=%%a"
        set "APK_FOUND=true"
        goto :found_apk
    )
)

:found_apk
if "%APK_FOUND%"=="false" (
    echo ERROR: Could not find built APK in any expected location!
    echo Please check build logs for errors.
    exit /b 1
)

:: Get the device ID
echo Getting connected devices...
call flutter devices > devices.txt
for /f "tokens=1,2 delims=•" %%i in (devices.txt) do (
    set "line=%%i"
    if "!line:~0,7!"=="android" (
        set "DEVICE_ID=!line!"
        set "DEVICE_ID=!DEVICE_ID:~8!"
        set "DEVICE_ID=!DEVICE_ID: =!"
        goto :found_device
    )
)

:found_device
if not defined DEVICE_ID (
    echo No Android device found!
    exit /b 1
)

echo Installing and running on device ID: %DEVICE_ID%

:: Install the APK directly with adb
call adb -s %DEVICE_ID% install -r "%APK_PATH%"
if %ERRORLEVEL% neq 0 (
    echo Failed to install APK with ADB, trying Flutter...
    call flutter run -d %DEVICE_ID%
) else (
    :: Launch the app with adb
    echo Starting app with ADB...
    call adb -s %DEVICE_ID% shell am start -n com.example.see_you_in_ceu/com.example.see_you_in_ceu.MainActivity
)

echo Process completed! 