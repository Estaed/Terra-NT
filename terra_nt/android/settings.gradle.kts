pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "9.1.0" apply false
    id("org.jetbrains.kotlin.android") version "2.4.0" apply false
    // Task-23: reads android/app/google-services.json into resources (Google Sign-In's server client id).
    id("com.google.gms.google-services") version "4.5.0" apply false
    // Task-29: uploads mapping and routes crashes to the Firebase console (docs/PRD.md D13).
    id("com.google.firebase.crashlytics") version "3.0.6" apply false
}

include(":app")
