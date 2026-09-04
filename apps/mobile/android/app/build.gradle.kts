import java.util.Base64

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.happypawsnetwork.mobile"
    compileSdk = 37
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.happypawsnetwork.mobile"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        var mapsApiKey = ""
        val dartDefines = project.findProperty("dart-defines") as? String
        if (dartDefines != null) {
            dartDefines.split(",").forEach {
                try {
                    val decoded = String(Base64.getDecoder().decode(it), Charsets.UTF_8)
                    if (decoded.startsWith("GOOGLE_MAPS_API_KEY=")) {
                        mapsApiKey = decoded.substring("GOOGLE_MAPS_API_KEY=".length)
                    }
                } catch (_: Exception) {}
            }
        }
        if (mapsApiKey.isEmpty()) {
            val envFile = rootProject.file("../.env")
            if (envFile.exists()) {
                envFile.readLines().forEach { line ->
                    val trimmed = line.trim()
                    if (trimmed.startsWith("GOOGLE_MAPS_API_KEY=")) {
                        mapsApiKey = trimmed.substring("GOOGLE_MAPS_API_KEY=".length).trim().trim('"', '\'')
                    }
                }
            }
        }
        manifestPlaceholders += mapOf("GOOGLE_MAPS_API_KEY" to mapsApiKey)
    }

    signingConfigs {
        create("release") {
            val keystoreFile = file("upload-keystore.jks")
            if (keystoreFile.exists()) {
                storeFile = keystoreFile
                storePassword = System.getenv("KEYSTORE_PASSWORD")
                keyAlias = System.getenv("KEY_ALIAS")
                keyPassword = System.getenv("KEY_PASSWORD")
            }
        }
    }

    buildTypes {
        release {
            val releaseSigning = signingConfigs.getByName("release")
            signingConfig = if (file("upload-keystore.jks").exists()) releaseSigning else signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("androidx.core:core-splashscreen:1.0.1")
}

