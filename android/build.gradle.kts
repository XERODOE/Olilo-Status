plugins {
    id("com.android.application") version "9.2.1" apply false
    id("com.google.gms.google-services") version "4.4.4" apply false
    id("org.jetbrains.kotlin.plugin.compose") version "2.2.10" apply false
    id("org.jetbrains.kotlin.plugin.serialization") version "2.2.10" apply false
    // Gradle Play Publisher: builds, signs and uploads the App Bundle to Google
    // Play. 4.x is the first line that supports Android Gradle Plugin 9.
    id("com.github.triplet.play") version "4.0.0" apply false
}
