@echo off
echo Cleaning Android build...
cd android
call gradlew clean
cd ..

echo Cleaning Flutter build...
call flutter clean

echo Deleting build directories...
if exist "build" rmdir /S /Q build
if exist "android\.gradle" rmdir /S /Q android\.gradle
if exist "android\app\build" rmdir /S /Q android\app\build

echo Installing Flutter dependencies...
call flutter pub get

echo Building Android APK...
call flutter build apk --debug

echo Done. Check android/app/build/outputs/flutter-apk/ for the APK file if successful.
echo If you still see the "Gradle build failed to produce an .apk file" error, try running:
echo flutter install 