import java.util.Properties
import java.util.Base64
import java.net.URI

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val signingProperties = Properties().apply {
    val propertiesFile = rootProject.file("key.properties")
    if (propertiesFile.exists()) propertiesFile.inputStream().use { load(it) }
}
fun signingValue(name: String, environment: String): String? =
    System.getenv(environment)?.takeIf { it.isNotBlank() }
        ?: signingProperties.getProperty(name)?.takeIf { it.isNotBlank() }

val releaseApplicationId = providers.gradleProperty("codepath.applicationId")
    .orElse(providers.environmentVariable("ANDROID_APPLICATION_ID")).orNull
val keystorePath = signingValue("storeFile", "ANDROID_KEYSTORE_PATH")
val keystorePassword = signingValue("storePassword", "ANDROID_KEYSTORE_PASSWORD")
val releaseKeyAlias = signingValue("keyAlias", "ANDROID_KEY_ALIAS")
val releaseKeyPassword = signingValue("keyPassword", "ANDROID_KEY_PASSWORD")

android {
    namespace = "com.example.codepath"
    compileSdk = 36
    ndkVersion = "28.2.13676358"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = releaseApplicationId ?: "com.example.codepath"
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (keystorePath != null) storeFile = rootProject.file(keystorePath)
            storePassword = keystorePassword
            keyAlias = releaseKeyAlias
            keyPassword = releaseKeyPassword
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

tasks.matching { it.name == "preReleaseBuild" }.configureEach {
    doFirst {
        val dartDefines = (project.findProperty("dart-defines") as? String)
            .orEmpty().split(",").filter { it.isNotBlank() }.associate { encoded ->
                val decoded = String(Base64.getDecoder().decode(encoded), Charsets.UTF_8)
                val parts = decoded.split("=", limit = 2)
                parts[0] to parts.getOrElse(1) { "" }
            }
        for (name in listOf("API_BASE_URL", "PRIVACY_POLICY_URL", "ACCOUNT_DELETION_URL")) {
            val uri = try { URI(dartDefines[name].orEmpty()) } catch (_: Exception) { null }
            require(uri?.scheme == "https" && !uri.host.isNullOrBlank() && uri.userInfo == null) {
                "Defina $name como URL HTTPS usando --dart-define ou --dart-define-from-file."
            }
            if (name == "API_BASE_URL") {
                require((uri!!.path.isNullOrEmpty() || uri.path == "/") && uri.query == null && uri.fragment == null) {
                    "API_BASE_URL deve conter apenas a origem HTTPS, sem caminho, query ou fragmento."
                }
            }
        }
        require(dartDefines["SUPPORT_EMAIL"].orEmpty().matches(Regex("[^\\s@]+@[^\\s@]+\\.[^\\s@]+"))) {
            "Defina SUPPORT_EMAIL com um endereço válido."
        }
        require(!releaseApplicationId.isNullOrBlank() &&
            !releaseApplicationId.startsWith("com.example.") &&
            releaseApplicationId.matches(Regex("[a-zA-Z][a-zA-Z0-9_]*(\\.[a-zA-Z][a-zA-Z0-9_]*)+"))) {
            "Defina ANDROID_APPLICATION_ID com o identificador definitivo do aplicativo."
        }
        require(listOf(keystorePath, keystorePassword, releaseKeyAlias, releaseKeyPassword)
            .all { !it.isNullOrBlank() }) {
            "Configure a chave de upload em android/key.properties ou nas variáveis ANDROID_KEY*."
        }
        require(rootProject.file(keystorePath!!).isFile) { "Keystore de release não encontrado." }
    }
}

flutter {
    source = "../.."
}
