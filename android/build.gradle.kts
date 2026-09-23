allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.set(newBuildDir)

subprojects {
    val subprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.set(subprojectBuildDir)
}

/*
 * إصلاح مشكلة namespace في isar_flutter_libs 3.1.0+1
 * عند استخدام Android Gradle Plugin 8+
 */
subprojects {
    afterEvaluate {
        if (name == "isar_flutter_libs") {
            extensions.findByName("android")?.let { androidExtension ->
                androidExtension.javaClass.methods
                    .firstOrNull { it.name == "getNamespace" }
                    ?.let {
                        try {
                            val namespace = it.invoke(androidExtension)
                            if (namespace == null) {
                                androidExtension.javaClass.methods
                                    .firstOrNull { method ->
                                        method.name == "setNamespace" &&
                                            method.parameterTypes.size == 1
                                    }
                                    ?.invoke(
                                        androidExtension,
                                        "dev.isar.isar_flutter_libs"
                                    )
                            }
                        } catch (_: Exception) {
                            // يتم تجاهل الخطأ إذا كان namespace موجودًا أصلًا
                        }
                    }
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