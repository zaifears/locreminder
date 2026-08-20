# Services and receivers are instantiated by the system by name, so they
# must survive shrinking even though nothing in the app calls them directly.
-keep class com.zaifears.locreminder.** { *; }

# Flutter's own embedding classes must not be stripped — except the two
# classes that exist solely to support Play Store "deferred components"
# (dynamic feature delivery), which this app doesn't use:
#   - PlayStoreDeferredComponentManager: typed with real Play Core
#     interfaces (SplitInstallManager, its listeners, ...), so keeping it
#     keeps them too.
#   - FlutterPlayStoreSplitApplication: `extends SplitCompatApplication`
#     (forcing that Play Core class to survive as its superclass) and
#     directly `new`s a PlayStoreDeferredComponentManager in onCreate(),
#     which alone was enough to keep the other four classes reachable
#     even with the manager itself excluded above.
# Neither is ever instantiated here — the manifest uses Flutter's default
# Application class, not this one — so both are safe to drop, and with
# them, every Play Core class they reference. This is what F-Droid's
# non-free-code scanner flags, even though nothing here ever calls it.
-keep class !io.flutter.embedding.android.FlutterPlayStoreSplitApplication,!io.flutter.embedding.engine.deferredcomponents.**,io.flutter.** { *; }

# With the manager above no longer kept, its reference to Play Store
# "deferred components" (dynamic feature delivery) classes is genuinely
# unresolved. R8 fails the build over that unless told it's fine to leave
# unresolved: https://docs.flutter.dev/reference/android-r8
-dontwarn com.google.android.play.core.**
