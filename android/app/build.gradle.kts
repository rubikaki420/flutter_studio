plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {

    namespace = "com.vault.fide"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "29.0.14206865"
    buildToolsVersion = "36.1.0"

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.vault.fide"
        minSdk = 26
        targetSdk = 28
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            storeFile = file("common.jks")
            storePassword = "password"
            keyAlias = "alias"
            keyPassword = "password"
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}
dependencies {
implementation(libs.material)
  coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:1.1.5")
  implementation(project(":termux:termux-application"))
  implementation (project(":termux:terminal-emulator"))
  implementation (project(":termux:terminal-view"))
  implementation (project(":termux:termux-shared"))
  implementation ("androidx.appcompat:appcompat:1.7.1")
    implementation ("androidx.preference:preference:1.2.1")
    implementation ("androidx.drawerlayout:drawerlayout:1.2.0")
    implementation ("androidx.viewpager:viewpager:1.0.0")
    implementation ("com.google.guava:guava:24.1-jre")
    implementation ("io.noties.markwon:core:4.6.2")
    implementation ("io.noties.markwon:ext-strikethrough:4.6.2")
    implementation ("io.noties.markwon:linkify:4.6.2")
    implementation ("io.noties.markwon:recycler:4.6.2")
    implementation ("com.google.guava:listenablefuture:9999.0-empty-to-avoid-conflict-with-guava")
    implementation ("androidx.annotation:annotation:1.10.0")
}