# See You in CEU - Flutter App

## Build Error Fix Instructions

If you encounter this error:

```
FAILURE: Build failed with an exception.

* What went wrong:
A problem occurred configuring project ':flutter_local_notifications'.
> Could not create an instance of type com.android.build.api.variant.impl.LibraryVariantBuilderImpl.
   > Namespace not specified. Specify a namespace in the module's build file...
```

Follow these steps to fix it:

### Option 1: Run the Fix Script (Recommended)

1. Run the included batch file to automatically patch the flutter_local_notifications plugin:
   ```
   fix_flutter_notifications.bat
   ```

2. After the patch is applied, run:
   ```
   flutter pub get
   flutter run
   ```

### Option 2: Manually Patch the Plugin

1. Locate the flutter_local_notifications plugin directory:
   ```
   %LOCALAPPDATA%\Pub\Cache\hosted\pub.dev\flutter_local_notifications-9.1.5\android
   ```

2. Make a backup of the original build.gradle file:
   ```
   copy build.gradle build.gradle.backup
   ```

3. Edit the build.gradle file and add this line inside the android section:
   ```
   namespace 'com.dexterous.flutterlocalnotifications'
   ```

4. Run `flutter clean` and `flutter pub get`

## About

See You in CEU is a lost and found app for Centro Escolar University students.

# see_you_in_ceu

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
