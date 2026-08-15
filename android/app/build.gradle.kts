import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

// Google Maps API key: read from a local, git-ignored secrets.properties for
// dev builds, or from the MAPS_API_KEY environment variable (set as a GitHub
// Actions secret) for CI builds. Falls back to a placeholder so the project
// always compiles even before a key has been configured.
val secretsPropertiesFile = rootProject.file("secrets.properties")
val secretsProperties = Properties()
if (secretsPropertiesFile.exists()) {
    FileInputStream(secretsPropertiesFile).use { secretsProperties.load(it) }
}
val mapsApiKey: String =
    secretsProperties.getProperty("MAPS_API_KEY")?.takeIf { it.isNotBlank() }
        ?: System.getenv("MAPS_API_KEY")?.takeIf { it.isNotBlank() }
        ?: "YOUR_API_KEY_HERE"

// Release signing: read from a local, git-ignored key.properties, or from
// individual RELEASE_* environment variables (set as GitHub Actions secrets)
// for CI builds. Falls back to debug signing so `flutter build apk --release`
// always produces an installable APK even without a configured keystore.
// GitHub Actions substitutes unset secrets with an empty string rather than
// leaving the env var unset, so blank values must be treated as absent too.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    FileInputStream(keystorePropertiesFile).use { keystoreProperties.load(it) }
}
fun signingProperty(key: String, env: String): String? =
    keystoreProperties.getProperty(key)?.takeIf { it.isNotBlank() }
        ?: System.getenv(env)?.takeIf { it.isNotBlank() }

val releaseStoreFilePath = signingProperty("storeFile", "RELEASE_STORE_FILE")
val hasReleaseSigning = releaseStoreFilePath != null

android {
    namespace = "com.zaifears.locreminder"
    compileSdk = 35
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.zaifears.locreminder"
        minSdk = 23
        targetSdk = 35
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["mapsApiKey"] = mapsApiKey
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                storeFile = file(releaseStoreFilePath!!)
                storePassword = signingProperty("storePassword", "RELEASE_STORE_PASSWORD")
                keyAlias = signingProperty("keyAlias", "RELEASE_KEY_ALIAS")
                keyPassword = signingProperty("keyPassword", "RELEASE_KEY_PASSWORD")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasReleaseSigning) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
    implementation("com.google.android.gms:play-services-location:21.3.0")
    implementation("androidx.core:core-ktx:1.13.1")
}
