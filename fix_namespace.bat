@echo off
echo Fixing flutter_local_notifications namespace issue...

set "PLUGIN_DIR=%LOCALAPPDATA%\Pub\Cache\hosted\pub.dev\flutter_local_notifications-9.1.5\android"
set "BUILD_GRADLE=%PLUGIN_DIR%\build.gradle"

if not exist "%PLUGIN_DIR%" (
    echo Plugin directory not found!
    echo Run 'flutter pub get' first, then try again.
    exit /b 1
)

if not exist "%BUILD_GRADLE%" (
    echo build.gradle not found!
    exit /b 1
)

echo Creating backup of original build.gradle...
copy "%BUILD_GRADLE%" "%BUILD_GRADLE%.bak"

echo Adding namespace to build.gradle...
powershell -Command "(Get-Content '%BUILD_GRADLE%') -replace 'android \{', 'android {\r\n    namespace ''com.dexterous.flutterlocalnotifications''' | Set-Content '%BUILD_GRADLE%'"

echo Patch applied! Please run:
echo   flutter clean
echo   flutter pub get
echo   flutter run

exit /b 0 