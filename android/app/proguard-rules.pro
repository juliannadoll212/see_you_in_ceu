# Keep Firebase Authentication and Google Sign-In classes
-keep class com.google.android.gms.** { *; }
-keep class com.google.firebase.** { *; }
-keep class androidx.** { *; }

# Keep Conscrypt for SSL connections
-keep class com.google.android.gms.org.conscrypt.** { *; }
-keepclassmembers class com.google.android.gms.org.conscrypt.** {
    *;
}

# Keep Java Socket implementation
-keep class java.net.Socket { *; }
-keep class java.net.SocketImpl { *; }
-keepclassmembers class java.net.Socket { 
    private java.net.SocketImpl impl;
}

# Keep multidex related classes
-keep class androidx.multidex.** { *; }

# Prevent R8 from removing classes or methods that are accessed through reflection
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception

# Additional rules
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn javax.annotation.**
-dontwarn org.conscrypt.** 