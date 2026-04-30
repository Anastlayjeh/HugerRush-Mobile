allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val localBuildRoot = File(
    System.getenv("LOCALAPPDATA") ?: System.getProperty("java.io.tmpdir"),
    "HungerRushMobile/gradle-build",
)
val newBuildDir: Directory = rootProject.layout.dir(
    rootProject.providers.provider { localBuildRoot },
).get()
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
