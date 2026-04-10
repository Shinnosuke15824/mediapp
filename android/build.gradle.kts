allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val rootBuildDir = "../../build"
rootProject.layout.buildDirectory.set(file(rootBuildDir))

subprojects {
    val newBuildDir = "$rootBuildDir/${project.name}"
    project.layout.buildDirectory.set(file(newBuildDir))

    // THAY THẾ afterEvaluate BẰNG whenPluginAdded
    // Cách này giúp can thiệp vào cấu hình mà không gây lỗi "already evaluated"
    project.plugins.withType<com.android.build.gradle.BasePlugin> {
        val android = project.extensions.getByName("android") as com.android.build.gradle.BaseExtension
        android.compileOptions {
            sourceCompatibility = JavaVersion.VERSION_17
            targetCompatibility = JavaVersion.VERSION_17
        }

        // Đặc trị lỗi 'ambiguous' cho Java 17/21
        project.tasks.withType<JavaCompile>().configureEach {
            options.compilerArgs.addAll(listOf("-Xlint:-options", "-Xlint:-unchecked", "-nowarn"))
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}