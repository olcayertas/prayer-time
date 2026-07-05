pluginManagement {
    repositories {
        google {
            content {
                includeGroupByRegex("com\\.android.*")
                includeGroupByRegex("com\\.google.*")
                includeGroupByRegex("androidx.*")
            }
        }
        mavenCentral()
        gradlePluginPortal()
    }
}

@Suppress("UnstableApiUsage")
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.name = "NamazVaktiAndroid"

// :domain is a pure Kotlin/JVM module (the ported, unit-tested logic — no Android imports), so it
// builds and tests on any JDK without the Android SDK. :app is the Android + Compose shell.
include(":domain")
include(":app")
