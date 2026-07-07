# Proximité - ProGuard / R8 Rules for Release Builds

# Keep Play Core (needed by Flutter deferred components)
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# Keep Supabase/Dio/Ktor network models
-keep class com.supabase.** { *; }
-keep class io.ktor.** { *; }

# Keep Flutter engine classes
-keep class io.flutter.** { *; }
-keep class io.flutter.plugin.** { *; }

# Keep JSON serialization models
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Keep Kotlin coroutines
-keepnames class kotlinx.coroutines.** { *; }
