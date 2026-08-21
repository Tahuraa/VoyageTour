allprojects {
    repositories {
        google()
        mavenCentral()
    }

    // Some plugin modules (e.g. stripe_android) don't pin their own Kotlin
    // compiler target, so they fall back to the Gradle daemon's system JDK
    // instead of matching the app's JavaVersion.VERSION_17, which Gradle
    // then rejects as an inconsistent JVM target.
    tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
        compilerOptions.jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
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
