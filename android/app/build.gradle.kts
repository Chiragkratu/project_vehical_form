plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services") 
}


dependencies {
    implementation("com.google.firebase:firebase-analytics:21.5.0")
    // Add other Firebase SDKs here if needed
}

android {
    namespace = "com.example.project_vehical_form"
    // compileSdk = flutter.compileSdkVersion
    // ndkVersion = flutter.ndkVersion

    compileSdk = 35  // 🔼 Update this to match SDK 35
    ndkVersion = "27.0.12077973"  // 🔼 Set correct NDK version

    defaultConfig {
        applicationId = "your.app.id"
        minSdk = 21
        targetSdk = 35  // 🔼 Optionally update targetSdk too
        versionCode = 1
        versionName = "1.0"
    }


    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.project_vehical_form"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
