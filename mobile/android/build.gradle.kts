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

// Plugin pihak ketiga (mis. tflite_flutter) masih memakai `compileOptions`
// Java 1.8, sementara Kotlin 2.4 default ke JVM 25 → build gagal dengan
// "Inconsistent JVM Target Compatibility". Samakan semua subproject ke 17
// (versi yang sama dengan `android/app/build.gradle.kts`).
//
// `android.compileOptions` milik plugin sudah difinalisasi AGP 9 dan tidak bisa
// ditimpa, jadi target JVM disamakan di level task. Aksi `configureEach` biasa
// kalah urutan: AGP mengonfigurasi task `javac` secara lazy saat task graph
// dibentuk (setelah `afterEvaluate`). Karena itu nilainya dipaksa di
// `taskGraph.whenReady`, tepat sebelum task dieksekusi.
subprojects {
    afterEvaluate {
        tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinJvmCompile>().configureEach {
            compilerOptions.jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
        }
    }
}

gradle.taskGraph.whenReady {
    allTasks.forEach { task ->
        if (task is JavaCompile) {
            task.sourceCompatibility = JavaVersion.VERSION_17.toString()
            task.targetCompatibility = JavaVersion.VERSION_17.toString()
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
