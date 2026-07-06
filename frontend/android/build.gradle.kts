allprojects {
    repositories {
        google()
        mavenCentral()
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

// Force all Android library subprojects (Flutter plugins) to compile against
// SDK 36. Some plugins (e.g. file_picker 8.3.7) hardcode compileSdk 34 inside
// their own android {} block, which conflicts with newer transitive deps that
// require 36. Registering an afterEvaluate hook here — BEFORE the
// evaluationDependsOn(":app") call below triggers evaluation — ensures the
// override runs after each plugin's android {} block has been configured.
subprojects {
    afterEvaluate {
        if (project.hasProperty("android")) {
            val androidExtension = project.extensions.getByName("android")
            if (androidExtension is com.android.build.gradle.BaseExtension) {
                androidExtension.compileSdkVersion(36)
            }
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
