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
// Some plugins (e.g. file_picker) still compile against android-34 while
// flutter_plugin_android_lifecycle requires 36+. Raise library modules to 36.
subprojects {
    val raiseCompileSdk: Project.() -> Unit = {
        if (plugins.hasPlugin("com.android.library")) {
            val android = extensions.findByName("android")
            if (android != null) {
                val current =
                    (android.javaClass.methods
                        .firstOrNull { it.name == "getCompileSdkVersion" && it.parameterCount == 0 }
                        ?.invoke(android) as? String)
                        ?.removePrefix("android-")
                        ?.toIntOrNull() ?: 0
                if (current < 36) {
                    android.javaClass.methods
                        .first { it.name == "compileSdkVersion" && it.parameterTypes.singleOrNull() == Int::class.javaPrimitiveType }
                        .invoke(android, 36)
                }
            }
        }
    }
    if (state.executed) raiseCompileSdk() else afterEvaluate { raiseCompileSdk() }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
