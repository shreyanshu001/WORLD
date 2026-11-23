import org.jetbrains.kotlin.gradle.dsl.JvmTarget

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("org.jetbrains.kotlin.plugin.compose")
}

android {
    // Placeholder, like the app's com.example.worlds (D-009). ARCore keyless
    // authorization binds the Google Cloud OAuth client to this package name
    // and the signing certificate's SHA-1, so change both together.
    namespace = "com.example.worlds.arspike"
    compileSdk = 36

    defaultConfig {
        applicationId = "com.example.worlds.arspike"
        // ARCore "AR Optional" apps may go lower, but Geospatial and the
        // app's own minSdk (24) make 24 the useful floor.
        minSdk = 24
        targetSdk = 36
        versionCode = 1
        versionName = "0.1.0-spike"
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            // Field tests use debug builds; a release build is not needed.
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    buildFeatures {
        compose = true
    }

    testOptions {
        unitTests.isReturnDefaultValues = false
    }
}

kotlin {
    compilerOptions {
        jvmTarget.set(JvmTarget.JVM_17)
    }
}

dependencies {
    // SceneView 2.3.4 (2026-10-10): built with Kotlin 2.2.21, ARCore 1.52.0 and
    // Filament 1.68.2. The 4.x line needs Kotlin 2.3-2.4, which the WORLDS
    // toolchain (Kotlin 2.2.20) cannot read. See README.md.
    implementation("io.github.sceneview:arsceneview:2.3.4")
    // Pinned to what SceneView 2.3.4 was built against (latest is 1.57.0).
    implementation("com.google.ar:core:1.52.0")
    // Geospatial needs fused location; keyless ARCore authorization needs auth.
    implementation("com.google.android.gms:play-services-location:21.3.0")
    implementation("com.google.android.gms:play-services-auth:21.3.0")

    implementation("androidx.activity:activity-compose:1.11.0")
    implementation("androidx.compose.material3:material3:1.4.0")
    implementation("androidx.lifecycle:lifecycle-runtime-compose:2.9.4")

    testImplementation("junit:junit:4.13.2")
    // Real org.json for JVM unit tests (android.jar only has stubs).
    testImplementation("org.json:json:20250517")
}
