# Manual Fix for Google ML Kit Namespace Issue

Since the batch script had issues with escaping special characters, follow these manual steps:

## Step 1: Find your pub cache directory

Run this command:
```
flutter pub cache dir
```

This will show where your pub cache is located (likely in your AppData folder).

## Step 2: Fix the Google ML Kit Commons package

1. Navigate to:
   ```
   [your_pub_cache_path]\hosted\pub.dev\google_mlkit_commons-0.5.0\android
   ```

2. Edit the file `build.gradle` with any text editor

3. Replace its contents with:
```groovy
group 'com.google_mlkit_commons'
version '1.0'

buildscript {
    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        classpath 'com.android.tools.build:gradle:7.3.0'
    }
}

rootProject.allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

apply plugin: 'com.android.library'

android {
    namespace 'com.google_mlkit_commons'
    compileSdkVersion 33

    defaultConfig {
        minSdkVersion 21
        targetSdkVersion 33
    }

    compileOptions {
        sourceCompatibility JavaVersion.VERSION_1_8
        targetCompatibility JavaVersion.VERSION_1_8
    }

    dependencies {
        implementation 'com.google.android.gms:play-services-base:18.2.0'
    }
}
```

## Step 3: Fix the Google ML Kit Image Labeling package

1. Navigate to:
   ```
   [your_pub_cache_path]\hosted\pub.dev\google_mlkit_image_labeling-0.9.0\android
   ```

2. Edit the file `build.gradle` with any text editor

3. Replace its contents with:
```groovy
group 'com.google_mlkit_image_labeling'
version '1.0'

buildscript {
    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        classpath 'com.android.tools.build:gradle:7.3.0'
    }
}

rootProject.allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

apply plugin: 'com.android.library'

android {
    namespace 'com.google_mlkit_image_labeling'
    compileSdkVersion 33

    defaultConfig {
        minSdkVersion 21
        targetSdkVersion 33
    }

    compileOptions {
        sourceCompatibility JavaVersion.VERSION_1_8
        targetCompatibility JavaVersion.VERSION_1_8
    }

    dependencies {
        implementation 'com.google.android.gms:play-services-base:18.2.0'
        implementation 'com.google.android.gms:play-services-mlkit-image-labeling:17.0.1'
    }
}
```

## Step A4: Rebuild your project

Run these commands:
```
flutter clean
flutter pub get
flutter run
```

This should fix the namespace issue and allow the app to build successfully. 