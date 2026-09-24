
import java.util.Base64
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// La clé de publication vit hors du dépôt, comme pour BodyCount :
// android/key.properties, ignoré par git, dit où la trouver. Sans lui, la
// version de publication est signée avec la clé de débogage.
val proprietesCle = Properties().apply {
    val fichier = rootProject.file("key.properties")
    if (fichier.exists()) fichier.inputStream().use { load(it) }
}
val clePresente = proprietesCle.containsKey("storeFile")

// La démo est une application à part : autre identifiant, autre nom, autre
// adresse de retour de la banque, pour qu'elle s'installe à côté de la
// vraie sans la remplacer. Flutter passe les --dart-define à Gradle,
// encodés en base64 et séparés par des virgules.
val definitions = (project.findProperty("dart-defines") as String?)
    ?.split(",")
    ?.map { String(Base64.getDecoder().decode(it)) }
    ?: emptyList()
val demo = "DEMO=true" in definitions

android {
    namespace = "com.cybertrist.smartbudget"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    // Pour le nom de l'application, qui change avec la démo.
    buildFeatures {
        resValues = true
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // Exigé par flutter_local_notifications, la notification du compte
        // en négatif.
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        applicationId = "com.cybertrist.smartbudget"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        if (demo) applicationIdSuffix = ".demo"
        resValue("string", "app_name", if (demo) "SmartBudget démo" else "SmartBudget")
        manifestPlaceholders["schemaBanque"] = if (demo) "smartbudgetdemo" else "smartbudget"
    }

    signingConfigs {
        if (clePresente) {
            create("publication") {
                storeFile = file(proprietesCle.getProperty("storeFile"))
                storePassword = proprietesCle.getProperty("storePassword")
                keyAlias = proprietesCle.getProperty("keyAlias")
                keyPassword = proprietesCle.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName(if (clePresente) "publication" else "debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
