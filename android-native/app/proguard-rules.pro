-keepattributes Signature
-keepattributes *Annotation*
-keep class com.xneo.app.model.** { *; }
-keep class retrofit2.** { *; }
-keepclassmembers class * {
    @retrofit2.http.* <methods>;
}
