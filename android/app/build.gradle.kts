import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "ke.co.hempongroup.invoiceeasy"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "ke.co.hempongroup.invoiceeasy"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }
    signingConfigs {
        create("release") {
            val keyPropertiesFile = rootProject.file("key.properties")
            if (keyPropertiesFile.exists()) {
                val keyProperties = Properties().apply {
                    keyPropertiesFile.inputStream().use { load(it) }
                }
                val storeFilePath = keyProperties.getProperty("storeFile")
                if (!storeFilePath.isNullOrBlank()) {
                    storeFile = rootProject.file(storeFilePath)
                }
                storePassword = keyProperties.getProperty("storePassword")
                keyAlias = keyProperties.getProperty("keyAlias")
                keyPassword = keyProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            // Production builds must use the release keystore configured in
            // android/key.properties. Never fall back to the debug key.
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}


tasks.register("verifyReleaseSigning") {
    doLast {
        val keyPropertiesFile = rootProject.file("key.properties")
        check(keyPropertiesFile.exists()) {
            "Production release signing is not configured. Copy android/key.properties.example to android/key.properties and fill in the release keystore values."
        }
        val keyProperties = Properties().apply {
            keyPropertiesFile.inputStream().use { load(it) }
        }
        listOf("storeFile", "storePassword", "keyAlias", "keyPassword").forEach { key ->
            check(!keyProperties.getProperty(key).isNullOrBlank()) {
                "Missing '$key' in android/key.properties."
            }
        }
        check(rootProject.file(keyProperties.getProperty("storeFile")).exists()) {
            "Release keystore file does not exist: ${keyProperties.getProperty("storeFile")}"
        }
    }
}


tasks.configureEach {
    if (name == "assembleRelease") {
        dependsOn("verifyReleaseSigning")
    }
}
