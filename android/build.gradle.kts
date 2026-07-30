allprojects {
    repositories {
        google()
        mavenCentral()
    }

    // androidx.datastore:1.2.0 (pulled in transitively by shared_preferences_android)
    // regressed on 16 KB page size support; 1.1.7 is the last compliant release.
    // https://github.com/flutter/flutter/issues/182898
    configurations.all {
        resolutionStrategy {
            force(
                "androidx.datastore:datastore:1.1.7",
                "androidx.datastore:datastore-core:1.1.7",
                "androidx.datastore:datastore-preferences:1.1.7",
                "androidx.datastore:datastore-preferences-core:1.1.7",
            )
        }
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
