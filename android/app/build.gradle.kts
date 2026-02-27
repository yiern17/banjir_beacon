import java.util.Properties

// 1. Correct Kotlin syntax for loading properties
val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localPropertiesFile.inputStream().use { localProperties.load(it) }
}

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.banjir_beacon"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.banjir_beacon"
        minSdk = 23
        targetSdk = 33 // Notice the '=' and 'targetSdk' instead of 'targetSdkVersion'
        
        // Correct Kotlin way to handle Flutter versions
        versionCode = project.findProperty("flutter-version-code")?.toString()?.toInt() ?: 1
        versionName = project.findProperty("flutter-version-name")?.toString() ?: "1.0"
        
        multiDexEnabled = true

        // 2. Correct Kotlin Map syntax for manifestPlaceholders
        manifestPlaceholders["googleMapsKey"] = localProperties.getProperty("MAPS_API_KEY") ?: ""
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // 3. Correct Kotlin syntax for implementation strings
    implementation("com.google.android.gms:play-services-maps:18.2.0")
    implementation("com.google.android.gms:play-services-location:21.0.1")
    implementation("androidx.multidex:multidex:2.0.1")
}