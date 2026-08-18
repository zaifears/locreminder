# Services and receivers are instantiated by the system by name, so they
# must survive shrinking even though nothing in the app calls them directly.
-keep class com.zaifears.locreminder.** { *; }

# Flutter's own embedding classes must not be stripped.
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Flutter's embedding optionally references Play Store "deferred
# components" (dynamic feature delivery) classes even when the app doesn't
# use that feature and doesn't depend on the play-core library. R8 fails
# the build over these unresolved references unless told they're fine to
# leave unresolved: https://docs.flutter.dev/reference/android-r8
-dontwarn com.google.android.play.core.**
