# Simplified Proguard rules to avoid build failures

# Optimization passes (can be high, but let's keep it standard)
-optimizationpasses 5

# Basic shrinking rules
-dontpreverify
-allowaccessmodification

# Keep Flutter and Plugins
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Firebase (let it use its own rules mostly)
-dontwarn com.google.firebase.**
-keep class com.google.firebase.** { *; }

# Ignore warnings for deferred components if not used
-dontwarn io.flutter.embedding.engine.deferredcomponents.**
-dontwarn com.google.android.play.core.**

# WebView
-keep class android.webkit.** { *; }
