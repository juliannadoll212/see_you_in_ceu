@echo off
echo Applying patches to Flutter plugins...

set PLUGIN_PATH=%LOCALAPPDATA%\Pub\Cache\hosted\pub.dev\flutter_local_notifications-9.1.5\android\build.gradle
set PATCH_PATH=%~dp0patches\flutter_local_notifications_build.gradle

echo.
echo Patching flutter_local_notifications plugin...
echo Source: %PATCH_PATH%
echo Target: %PLUGIN_PATH%

if exist "%PLUGIN_PATH%" (
    copy /Y "%PATCH_PATH%" "%PLUGIN_PATH%"
    echo Patch applied successfully.
) else (
    echo ERROR: Plugin build.gradle not found at expected location.
    echo Please verify the plugin path: %PLUGIN_PATH%
)

echo.
echo All patches completed.
pause 