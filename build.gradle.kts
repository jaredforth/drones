plugins { id("com.android.application") version "9.4.1" }

android {
    namespace = "dev.jaredforth.drones"
    compileSdk = 37
    defaultConfig {
        applicationId = "dev.jaredforth.drones"
        minSdk = 26
        targetSdk = 37
        versionCode = 1
        versionName = "1.0"
    }
}
