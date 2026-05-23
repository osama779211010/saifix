# Flutter / Dart
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }
-dontwarn io.flutter.**

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# OkHttp / HTTP
-dontwarn okhttp3.**
-dontwarn okio.**

# Kotlin
-keep class kotlin.** { *; }
-dontwarn kotlin.**

# WorkManager
-keep class androidx.work.** { *; }
-dontwarn androidx.work.**

# Local notifications
-keep class com.dexterous.** { *; }

# ML Kit
-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**

# QR scanner (ZXing / ML Kit barcode)
-keep class com.journeyapps.** { *; }
-dontwarn com.journeyapps.**

# General - keep model classes and enums
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses

# Prevent removing serializable classes
-keepclassmembers class * implements java.io.Serializable {
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}