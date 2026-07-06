// Root build — declares every plugin used across modules with `apply false`, so the Kotlin/AGP
// plugin artifacts land on the build classpath once (at the catalog version) and each module applies
// only what it needs, without version-resolution conflicts.
plugins {
    alias(libs.plugins.android.application) apply false
    alias(libs.plugins.kotlin.android) apply false
    alias(libs.plugins.kotlin.jvm) apply false
    alias(libs.plugins.kotlin.serialization) apply false
    alias(libs.plugins.kotlin.compose) apply false
    alias(libs.plugins.ksp) apply false
    alias(libs.plugins.hilt) apply false
}
