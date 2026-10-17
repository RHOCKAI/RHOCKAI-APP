// Force all classpath configurations to use the locally-cached AGP version.
// This prevents Flutter plugins (e.g. device_info_plus) from downloading a
// newer AGP version (8.12.x) that times out in this network environment.
buildscript {
    configurations.all {
        resolutionStrategy {
            force("com.android.tools.build:gradle:8.9.1")
        }
    }
}

allprojects {
    repositories {
        google()
        maven { url = uri("https://maven.google.com") }
        mavenCentral()
        maven { url = uri("https://jitpack.io") }
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
