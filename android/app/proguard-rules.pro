# Services and receivers are instantiated by the system by name, so they
# must survive shrinking even though nothing in the app calls them directly.
-keep class com.zaifears.locreminder.** { *; }

# Flutter's own embedding classes must not be stripped — except the
# deferred-components manager, which this app doesn't use. Keeping it also
# forces R8 to keep the real Google Play Core classes compiled into
# Flutter's own engine artifact, since its fields/methods are typed with
# Play Core interfaces. Those Play Core classes are what F-Droid's
# non-free-code scanner flags, even though nothing here ever calls them.
-keep class !io.flutter.embedding.engine.deferredcomponents.**,io.flutter.** { *; }

# With the manager above no longer kept, its reference to Play Store
# "deferred components" (dynamic feature delivery) classes is genuinely
# unresolved. R8 fails the build over that unless told it's fine to leave
# unresolved: https://docs.flutter.dev/reference/android-r8
-dontwarn com.google.android.play.core.**
