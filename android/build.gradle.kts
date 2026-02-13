// android/build.gradle.kts

// 1. "buildscript" MUST be the very first block.
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // This defines the version for the whole project
        classpath("com.google.gms:google-services:4.4.1")
        // Note: If you use other plugins like Crashlytics, add them here too.
    }
}

// 2. "allprojects" configures the repositories for your App and other modules.
allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// 3. The standard Flutter configuration (Do not change)
val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
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