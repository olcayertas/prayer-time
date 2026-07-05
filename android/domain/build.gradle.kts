// :domain — pure Kotlin/JVM. No Android imports here (keeps it fast to test and KMP-ready).
// Home of the ported, unit-tested logic: PrayerSchedule, Qibla, LocationMatcher, DTOs, freshness.
plugins {
    alias(libs.plugins.kotlin.jvm)
}

kotlin {
    jvmToolchain(21)
}

dependencies {
    testImplementation(libs.kotlin.test.junit)
}

tasks.test {
    useJUnit()
}
