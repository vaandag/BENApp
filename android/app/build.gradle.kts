import java.util.Properties

val releaseSigningProperties = Properties()
val releaseSigningFile = rootProject.file("key.properties")
if (releaseSigningFile.exists()) {
    releaseSigningFile.inputStream().use { releaseSigningProperties.load(it) }
}

fun signingValue(name: String): String? =
    (releaseSigningProperties[name] as? String)?.takeIf { it.isNotBlank() }

val releaseSigningConfigured = listOf(
    "keyAlias",
    "keyPassword",
    "storeFile",
    "storePassword",
).all { signingValue(it) != null }

if (gradle.startParameter.taskNames.any { it.contains("release", ignoreCase = true) } &&
    !releaseSigningConfigured
) {
    throw GradleException(
        "Android release signing is not configured. Create android/key.properties " +
            "from android/key.properties.example and provide your private keystore values."
    )
}

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.ben.app"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.ben.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (releaseSigningConfigured) {
            create("release") {
                keyAlias = signingValue("keyAlias")
                keyPassword = signingValue("keyPassword")
                storeFile = file(signingValue("storeFile")!!)
                storePassword = signingValue("storePassword")
            }
        }
    }

    buildTypes {
        release {
            if (releaseSigningConfigured) {
                signingConfig = signingConfigs.getByName("release")
            }
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
