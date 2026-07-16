# Flutter engine + plugins
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.plugin.** { *; }
-dontwarn io.flutter.embedding.**

# Firebase (messaging / core)
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# LiveKit + WebRTC (live classroom)
-keep class org.webrtc.** { *; }
-keep class io.livekit.** { *; }
-keep class livekit.** { *; }
-dontwarn org.webrtc.**

# Keep native method names and annotations
-keepattributes *Annotation*, Signature, InnerClasses, EnclosingMethod
-keepclasseswithmembernames class * { native <methods>; }

# Enums (serialized by name)
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Suppress notes for missing optional classes
-dontwarn javax.annotation.**
