@echo off
echo Cleaning Flutter project...
flutter clean

echo Installing dependencies...
flutter pub get

echo Building APK directly with Flutter...
flutter build apk --debug --verbose

echo If successful, the APK should be at:
echo android\app\build\outputs\flutter-apk\app-debug.apk
echo.
echo If you continue to see "Gradle build failed to produce an .apk file" error:
echo 1. Try installing directly: flutter install
echo 2. Or try Flutter's repair tools: flutter doctor --android-licenses 