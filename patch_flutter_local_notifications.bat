@echo off
echo Patching flutter_local_notifications plugin...

SET PLUGIN_DIR=%LOCALAPPDATA%\Pub\Cache\hosted\pub.dev\flutter_local_notifications-9.1.5\android

echo Plugin directory: %PLUGIN_DIR%

if not exist "%PLUGIN_DIR%" (
    echo Plugin directory not found!
    exit /b 1
)

echo Backing up original build.gradle...
copy "%PLUGIN_DIR%\build.gradle" "%PLUGIN_DIR%\build.gradle.backup"

echo Copying patched build.gradle...
copy "flutter_local_notifications_patch.gradle" "%PLUGIN_DIR%\build.gradle"

echo Patch applied successfully!
echo Please run 'flutter clean' and try building again.

exit /b 0 