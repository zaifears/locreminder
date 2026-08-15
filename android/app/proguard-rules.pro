# Play Services geofencing / location classes are referenced via
# reflection-free public API, but keep them to be safe against shrinking
# aggressive enough to strip callback interfaces.
-keep class com.google.android.gms.location.** { *; }
-keep class com.zaifears.locreminder.** { *; }

# Flutter's own embedding classes must not be stripped.
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
