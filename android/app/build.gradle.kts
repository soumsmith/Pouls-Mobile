plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.groupegain.parents_responsable"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.groupegain.parents_responsable"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // ffmpeg_kit_flutter_new_audio exige au minimum l'API 24 (Android 7.0)
        minSdk = maxOf(flutter.minSdkVersion, 24)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Les téléphones réels tournent en arm64-v8a (récents) ou armeabi-v7a
        // (anciens). x86/x86_64 ne sert qu'aux émulateurs et Chromebooks
        // Intel, quasi inexistants côté parents/écoles ciblés par l'appli.
        // Les retirer allège l'AAB (Play Store livre déjà un split par ABI,
        // mais l'AAB uploadé et les tests via bundletool en profitent aussi).
        ndk {
            abiFilters += listOf("arm64-v8a", "armeabi-v7a")
        }

        // L'app est entièrement en français (aucune gestion de Locale dans
        // main.dart) : restreindre les ressources traduites embarquées par
        // Firebase/Play Services/AndroidX aux langues réellement utiles
        // évite de livrer des chaînes pour des dizaines de langues inutiles.
        resourceConfigurations += listOf("fr", "en")
    }

    signingConfigs {
        create("release") {
            storeFile = file("key/groupe-gain-key.jks")
            storePassword = "groupgain2026"
            keyAlias = "groupe-gain-key"
            keyPassword = "groupgain2026"
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }

    // `ndk.abiFilters` ne suffit pas : les .so précompilés livrés par les
    // AAR de certains plugins (ex: ffmpeg_kit) pour x86_64 passent quand
    // même dans le merge. On les exclut explicitement du packaging final.
    packaging {
        jniLibs {
            excludes += setOf("**/x86_64/**", "**/x86/**")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    implementation("com.google.android.material:material:1.12.0")
    implementation("androidx.activity:activity-ktx:1.10.1")
}
