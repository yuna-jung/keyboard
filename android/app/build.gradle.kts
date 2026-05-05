import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Load `android/key.properties` (untracked — see android/.gitignore). Falls
// through gracefully when the file is absent so CI / fresh checkouts can
// still produce debug builds without the release keystore on disk.
val keystoreProperties = Properties().apply {
    val keystorePropertiesFile = rootProject.file("key.properties")
    if (keystorePropertiesFile.exists()) {
        load(FileInputStream(keystorePropertiesFile))
    }
}

// Load `android/local.properties` (gitignored). Carries third-party API keys
// (currently GIPHY) into BuildConfig so the IME can read them without
// shipping the secret in any tracked file. Missing key falls back to "" —
// fresh checkouts still build; the GIF tab will toast a setup notice.
val localProperties = Properties().apply {
    val localPropertiesFile = rootProject.file("local.properties")
    if (localPropertiesFile.exists()) {
        load(FileInputStream(localPropertiesFile))
    }
}
val giphyApiKey: String = (localProperties["GIPHY_API_KEY"] as String?) ?: ""

android {
    namespace = "com.yunajung.fonki"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    buildFeatures {
        buildConfig = true
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.yunajung.fonkii"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            val storeFileName = keystoreProperties["storeFile"] as String?
            if (storeFileName != null) {
                storeFile = file(storeFileName)
                storePassword = keystoreProperties["storePassword"] as String?
                keyAlias = keystoreProperties["keyAlias"] as String?
                keyPassword = keystoreProperties["keyPassword"] as String?
            }
        }
    }

    buildTypes {
        release {
            // Use the release signing config when key.properties is present;
            // fall back to debug keys otherwise so local `flutter run --release`
            // still works without the production keystore.
            signingConfig = if (keystoreProperties.isEmpty) {
                signingConfigs.getByName("debug")
            } else {
                signingConfigs.getByName("release")
            }
            buildConfigField("String", "GIPHY_API_KEY", "\"$giphyApiKey\"")
        }
        debug {
            buildConfigField("String", "GIPHY_API_KEY", "\"$giphyApiKey\"")
        }
    }
}

flutter {
    source = "../.."
}
