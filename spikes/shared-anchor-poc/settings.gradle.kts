// Phase 1 shared-anchor proof of concept (docs/PHASE_0_AUDIT.md section 6, D-044).
// Standalone: not part of the Flutter app. Plugin versions match android/settings.gradle.kts
// (AGP 8.11.1, Kotlin 2.2.20, Gradle 8.14) so build evidence carries over to Phase 2.
pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("com.android.application") version "8.11.1" apply false
    id("org.jetbrains.kotlin.android") version "2.2.20" apply false
    id("org.jetbrains.kotlin.plugin.compose") version "2.2.20" apply false
}

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.name = "shared-anchor-poc"
include(":app")
