allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Keep Gradle build outputs outside OneDrive to avoid file-lock issues on clean tasks.
val userHome = System.getProperty("user.home")
val externalBuildRoot = File(userHome, ".flutter-build/HugerRush-Mobile")
val newBuildDir: Directory =
    rootProject.layout
        .dir(providers.provider { externalBuildRoot })
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
