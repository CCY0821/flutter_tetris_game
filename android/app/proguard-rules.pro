# Add project specific ProGuard rules here.
# By default, the flags in this file are appended to flags specified
# in C:\android\tools\proguard\proguard-android.txt
# You can edit the include path and order by changing the proguardFiles
# directive in build.gradle.

# For more details, see
#   http://developer.android.com/guide/developing/tools/proguard.html

# Add any project specific keep options here:

# If your project uses WebView with JS, uncomment the following
# and specify the fully qualified class name to the JavaScript interface
# class:
#-keepclassmembers class fqcn.of.javascript.interface.for.webview {
#   public *;
#}

# Keep Flutter and Dart related classes
-keep class io.flutter.** { *; }
-keep class androidx.** { *; }
-dontwarn io.flutter.**
-dontwarn androidx.**

# Audio players
-keep class com.ryanheise.audioservice.** { *; }

# Google Mobile Ads
-keep class com.google.android.gms.ads.** { *; }
-dontwarn com.google.android.gms.ads.**