plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    // Package name chuẩn của Thắng
    namespace = "com.shin.media.mediapp"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {

        isCoreLibraryDesugaringEnabled = true

        // Đồng bộ Java 17 để khớp với JDK 21 của Thắng
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.shin.media.mediapp"


        minSdk = 25
        targetSdk = 34
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
            // Thêm dòng này nếu muốn build bản release mượt hơn
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // CỰC KỲ QUAN TRỌNG: Thư viện hỗ trợ "dịch" Java đời cũ sang Java đời mới
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")

    // Các thư viện mặc định của Flutter
    implementation("org.jetbrains.kotlin:kotlin-stdlib-jdk7: 1.9.10")
}
