@echo off
echo ===================================================
echo Alternative Flutter Build Method
echo ===================================================
echo.
echo This script uses Flutter tools directly to build the APK
echo bypassing some Gradle configuration issues.
echo.

:: Set environment variables
set FLUTTER_ROOT=C:\Users\63945\Desktop\See You - Copy - Copy\flutter
if not exist "%FLUTTER_ROOT%" (
    echo FLUTTER_ROOT not found at %FLUTTER_ROOT%
    echo Please edit this script and set the correct path
    exit /b 1
)

:: Clean the project first
echo Cleaning project...
call flutter clean

:: Get dependencies
echo Getting dependencies...
call flutter pub get

:: Build with special flags
echo Building with special configuration...
call flutter build apk ^
  --debug ^
  --android-skip-build-dependency-validation ^
  --no-shrink ^
  --split-debug-info=build/debug-info ^
  --build-name=1.0.0 ^
  --build-number=1

echo.
if %ERRORLEVEL% EQU 0 (
    echo Build completed successfully!
    echo APK location: build\app\outputs\flutter-apk\app-debug.apk
) else (
    echo Build failed with error code: %ERRORLEVEL%
)

echo.
echo If the build succeeded, install on your device with:
echo flutter install
echo.

pause 