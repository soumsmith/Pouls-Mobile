---
name: store-deployment
description: Guide complet pour préparer, signer et déployer une application Flutter sur le Google Play Store et l'Apple App Store.
tags: [flutter, release, deployment, play-store, app-store, keystore, certificates]
---

# App Store & Play Store Deployment Skill

Ce "skill" explique comment configurer les clés de signature, modifier les versions et générer les builds de production pour envoyer votre application sur les stores (Google Play Store & Apple App Store).

## 0. Informations de Compte (À retenir !)
**Très important :** Avant de commencer, notez et conservez précieusement les adresses e-mail (Comptes Google et Apple) utilisées pour créer les comptes développeurs. Si vous publiez l'application, les futures mises à jour **doivent obligatoirement** être poussées depuis ces mêmes comptes.
- **Compte Google Play Console :** *[Votre e-mail Google]*
- **Compte Apple Developer :** *[Votre e-mail / Apple ID]*

## 1. Mise à jour de la Version (Commun aux deux)

Avant chaque publication, vous devez incrémenter le numéro de version dans le fichier `pubspec.yaml` (à la racine du projet).

```yaml
# Format: version: X.Y.Z+BuildNumber
version: 1.0.6+7
```
- **X.Y.Z** (ex: `1.0.6`) : C'est ce que l'utilisateur verra sur le Store.
- **BuildNumber** (ex: `+7`) : Code technique interne. **Doit être incrémenté à chaque upload (+1)**, sinon les stores refuseront le fichier.

---

## 2. Déploiement Android (Google Play Store)

### Étape A : Générer un Keystore de signature
Le Keystore est le "coffre-fort" qui prouve que vous êtes bien le créateur de l'application. Gardez-le précieusement, s'il est perdu, vous ne pourrez plus mettre l'app à jour !

Dans votre terminal (à la racine du projet), tapez cette commande (sur Mac) :
```bash
keytool -genkey -v -keystore android/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```
*Répondez aux questions (Nom, Prénom, Pays) et définissez un mot de passe.*

### Étape B : Fichier `key.properties`
Créez un fichier nommé `key.properties` dans le dossier `android/` (NE LE COMMITEZ PAS SUR GIT).
```properties
storePassword=LE_MOT_DE_PASSE_CHOISI
keyPassword=LE_MOT_DE_PASSE_CHOISI
keyAlias=upload
storeFile=../upload-keystore.jks
```

### Étape C : Configurer `build.gradle`
Ouvrez le fichier `android/app/build.gradle` et ajoutez la configuration pour charger le keystore :

```groovy
// En haut du fichier, avant la balise "android"
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    // ...
    signingConfigs {
        release {
            keyAlias = keystoreProperties['keyAlias']
            keyPassword = keystoreProperties['keyPassword']
            storeFile = keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword = keystoreProperties['storePassword']
        }
    }

    buildTypes {
        release {
            signingConfig signingConfigs.release // Assigner la clé
            // minifyEnabled true
            // shrinkResources true
        }
    }
}
```

### Étape D : Générer l'App Bundle
L'AAB (Android App Bundle) est le format moderne requis par Google Play.
Exécutez dans le terminal :
```bash
flutter build appbundle --release
```
Le fichier généré se trouvera dans `build/app/outputs/bundle/release/app-release.aab`. C'est ce fichier qu'il faut glisser-déposer sur la Google Play Console !

### Étape E : Sauvegarde de Sécurité (Crucial)
**Attention :** Le fichier `.jks` et le `key.properties` ne doivent **jamais** être commités sur Git pour des raisons de sécurité (ils sont souvent dans `.gitignore`). 
Par conséquent, si vous changez d'ordinateur, vous ne les récupérerez pas en clonant le projet. Si vous perdez ce Keystore, vous ne pourrez plus **jamais** mettre l'application à jour.

**1. Comment le retrouver si vous l'avez perdu sur votre Mac ?**
Si vous avez généré un Keystore dans le passé et ne savez plus où il est, tapez dans le terminal :
```bash
find ~ -name "*.jks" 2>/dev/null
```

**2. Comment le sauvegarder (Zip) ?**
Il est fortement recommandé de le compresser dans une archive sécurisée par mot de passe et de le stocker ailleurs (clé USB, Google Drive, iCloud).
Dans le terminal (à la racine du projet), tapez :
```bash
zip -e keystore_backup.zip android/upload-keystore.jks android/key.properties
```
*(Le terminal vous demandera d'entrer un mot de passe pour protéger le Zip. Stockez ensuite ce fichier `keystore_backup.zip` en lieu sûr).*

---

## 3. Déploiement iOS (Apple App Store)

*Pré-requis : Vous devez avoir un Mac, Xcode installé, et un compte "Apple Developer Program" (payant).*

### Étape A : Identifiants & Certificats sur Apple Developer
1. Allez sur [developer.apple.com](https://developer.apple.com/) > "Certificates, Identifiers & Profiles".
2. Créez un **App ID** (ex: `com.pouls.mobile`).
3. Allez sur **App Store Connect** et créez une nouvelle App en liant cet Identifiant.

### Étape B : Configuration Xcode
Ouvrez le dossier iOS de Flutter dans Xcode :
```bash
open ios/Runner.xcworkspace
```

1. Dans le navigateur de gauche, cliquez sur la racine **Runner**.
2. Allez dans l'onglet **Signing & Capabilities**.
3. Cochez **"Automatically manage signing"**.
4. Sélectionnez votre "Team" (votre compte développeur Apple). Xcode va générer les certificats (Provisioning Profiles) automatiquement pour vous.

### Étape C : Vérification des Permissions (Info.plist)
Apple est très strict sur la vie privée. Si votre app utilise la caméra ou les photos, ajoutez les justifications dans `ios/Runner/Info.plist` :

```xml
<key>NSCameraUsageDescription</key>
<string>Cette application utilise l'appareil photo pour scanner des documents.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Cette application nécessite l'accès à vos photos pour uploader votre profil.</string>
```

### Étape D : Générer l'archive (IPA)
Vous pouvez générer le build avec Flutter directement pour préparer le fichier à uploader :
```bash
flutter build ipa --release
```
Cette commande va :
1. Compiler le code Flutter.
2. Créer une archive Xcode.
3. Générer un fichier `.ipa` dans `build/ios/ipa/`.

Ensuite, vous pouvez soit utiliser le logiciel **Transporter** (sur le Mac App Store) pour envoyer ce fichier `.ipa` sur App Store Connect, soit le faire via Xcode (`Product > Archive`, puis bouton `Distribute App`).

---

## 4. Configuration Firebase (Pre-Release)

Si votre application utilise Firebase (Authentification, Firestore, Push Notifications...), vous devez configurer les clés de production.

### Étape A : Les fichiers de configuration
Vérifiez que vous avez bien placé vos fichiers de configuration Firebase :
- **Android :** `android/app/google-services.json`
- **iOS :** `ios/Runner/GoogleService-Info.plist` (Doit être lié via Xcode !)

### Étape B : L'empreinte SHA-1 (Crucial pour Android)
L'erreur n°1 lors d'un déploiement Firebase est d'oublier d'ajouter le certificat `SHA-1` et `SHA-256` de votre clé de **Production** (votre Keystore) dans la console Firebase. Si vous l'oubliez, l'authentification Google ou par Numéro de Téléphone plantera en production !

Pour obtenir ces clés depuis le Keystore généré précédemment, tapez :
```bash
keytool -list -v -keystore android/upload-keystore.jks -alias upload
```
Copiez les empreintes SHA-1 et SHA-256 qui s'affichent et collez-les dans :
*Firebase Console > Paramètres du projet > Vos applications > Android > Empreintes de certificats SHA.*

---

## 5. Checklist Avant Publication
- [ ] **Politique de Confidentialité (Obligatoire)** : Préparez une page web hébergeant votre Politique de Confidentialité. Google Play et App Store exigent une URL valide décrivant les données collectées (même s'il n'y en a pas). Sans cela, votre app sera rejetée.
- [ ] Mettre à jour les icônes d'application (utilisez `flutter_launcher_icons`).
- [ ] Retirer les `print()` ou utiliser le package `logger` (Flutter retire le code de debug en release mais c'est plus propre).
- [ ] Tester sur un émulateur en mode release (`flutter run --release`) pour détecter les bugs silencieux.
- [ ] Incrémenter le Build Number dans `pubspec.yaml` !
