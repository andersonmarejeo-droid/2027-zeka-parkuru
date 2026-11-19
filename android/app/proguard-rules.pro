# Flutter Wrapper & Engine
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.**  { *; }
-dontwarn com.google.android.play.core.**

# Flutter SoLoud (Native / JNI / FFI koruması)
-keep class com.mrlooi.flutter_soloud.** { *; }
-keep class * implements io.flutter.plugin.common.MethodChannel$MethodCallHandler { *; }
-keepclasseswithmembernames class * {
    native <methods>;
}

# Firebase & Google Play Services
-keepattributes *Annotation*,Signature,InnerClasses,EnclosingMethod
-dontwarn com.google.android.gms.**
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-keep class com.google.firebase.** { *; }

# Firebase Crashlytics & Analytics
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception

# Cloud Firestore & Protobuf
-dontwarn io.grpc.**
-keep class io.grpc.** { *; }
-dontwarn com.google.protobuf.**
-keep class com.google.protobuf.** { *; }

# Flutter Local Notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# Desugaring
-dontwarn java.time.**

# Keep models & json serialization
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}
