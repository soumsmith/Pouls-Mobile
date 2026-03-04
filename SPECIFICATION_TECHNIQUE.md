# Spécification Technique - Parents Responsable

## 1. Vue d'ensemble du Projet

**Nom de l'application**: Parents Responsable  
**Plateforme**: Flutter (multi-plateforme: iOS, Android, Web, Desktop)  
**Version**: 1.0.0+1  
**SDK Flutter**: ^3.10.7  

### 1.1 Objectif
Application mobile destinée aux parents d'élèves pour suivre la scolarité de leurs enfants, gérer les communications avec l'établissement scolaire, et accéder à divers services éducatifs.

### 1.2 Public Cible
- Parents d'élèves (primaire, collège, lycée)
- Établissements scolaires partenaires
- Personnel administratif des écoles

## 2. Architecture Technique

### 2.1 Structure du Projet
```
lib/
├── main.dart                 # Point d'entrée de l'application
├── app.dart                  # Configuration principale
├── config/                   # Configurations globales
│   ├── app_colors.dart
│   ├── app_config.dart
│   └── app_dimensions.dart
├── models/                   # Modèles de données
│   ├── child.dart
│   ├── user.dart
│   ├── cart_item.dart
│   └── [15 autres modèles]
├── screens/                  # Écrans de l'application
│   ├── splash_screen.dart
│   ├── home_screen.dart
│   ├── login_screen.dart
│   ├── child_list_screen.dart
│   └── [20 autres écrans]
├── services/                 # Services métier
│   ├── auth_service.dart
│   ├── database_service.dart
│   ├── api_service.dart
│   └── [11 autres services]
└── widgets/                  # Composants réutilisables
    ├── bottom_nav.dart
    ├── bottom_sheet_menu.dart
    └── [autres widgets]
```

### 2.2 Patterns Architecturaux
- **MVVM** (Model-View-ViewModel) avec services
- **Repository Pattern** pour l'accès aux données
- **Singleton Pattern** pour les services globaux
- **Observer Pattern** pour la gestion d'état

## 3. Stack Technologique

### 3.1 Framework & Langage
- **Flutter 3.10.7+** - Framework UI multi-plateforme
- **Dart** - Langage de programmation

### 3.2 Dépendances Principales

#### UI & Design
- `flutter_screenutil: ^5.9.0` - Design responsive
- `cupertino_icons: ^1.0.8` - Icônes iOS style

#### Base de Données & Stockage
- `sqflite: ^2.3.0` - Base de données SQLite locale
- `path: ^1.8.3` - Manipulation de chemins
- `shared_preferences: ^2.2.2` - Stockage clé-valeur

#### Réseau & API
- `http: ^1.1.0` - Client HTTP

#### Firebase (Backend Services)
- `firebase_core: ^3.6.0` - Core Firebase
- `firebase_auth: ^5.7.0` - Authentification
- `cloud_firestore: ^5.4.4` - Base de données NoSQL
- `firebase_storage: ^12.3.0` - Stockage de fichiers
- `firebase_messaging: ^15.1.3` - Notifications push
- `flutter_local_notifications: ^18.0.1` - Notifications locales

#### Utilitaires
- `url_launcher: ^6.2.5` - Lancement d'URLs
- `share_plus: ^7.2.2` - Partage de contenu
- `intl_phone_field: ^3.0.1` - Champ téléphone international
- `device_info_plus: ^10.1.0` - Informations device

## 4. Modules Fonctionnels

### 4.1 Module d'Authentification
**Fichier principal**: `lib/services/auth_service.dart`

**Fonctionnalités**:
- Connexion par téléphone avec OTP
- Vérification SMS via service dédié
- Gestion des crédits SMS
- Session persistante
- Support multi-utilisateurs

**Endpoints API prévus**:
- `POST /api/auth/login` - Connexion téléphone
- `POST /api/auth/verify-otp-and-login` - Vérification OTP
- `POST /api/auth/send-otp` - Envoi OTP
- `POST /api/auth/verify-otp-and-signup` - Création compte
- `GET /api/auth/sms-credits` - Crédits SMS

### 4.2 Module Base de Données
**Fichier principal**: `lib/services/database_service.dart`

**Fonctionnalités**:
- Gestion SQLite locale
- Sauvegarde des utilisateurs
- Cache des données
- Synchronisation avec Firestore

### 4.3 Module Gestion des Enfants
**Fichier principal**: `lib/models/child.dart`

**Données de l'enfant**:
- Informations personnelles (nom, prénom)
- Établissement scolaire
- Classe/grade
- Photo de profil
- Lien avec le parent

### 4.4 Module Communication
**Fichiers principaux**: 
- `lib/screens/messages_screen.dart`
- `lib/screens/notes_screen.dart`

**Fonctionnalités**:
- Messagerie parent-établissement
- Notes et communications officielles
- Notifications push

### 4.5 Module Commercial
**Fichiers principaux**:
- `lib/screens/shop_screen.dart`
- `lib/screens/cart_screen.dart`
- `lib/screens/orders_screen.dart`

**Fonctionnalités**:
- Boutique en ligne
- Panier d'achat
- Gestion des commandes
- Paiements intégrés

### 4.6 Module Événements
**Fichier principal**: `lib/screens/all_events_screen.dart`

**Fonctionnalités**:
- Calendrier scolaire
- Événements de l'établissement
- Inscriptions aux activités

## 5. Modèles de Données

### 5.1 User (Utilisateur/Parent)
```dart
class User {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String phone;
  final int smsCredits;
}
```

### 5.2 Child (Enfant/Élève)
```dart
class Child {
  final String id;
  final String firstName;
  final String lastName;
  final String establishment;
  final String grade;
  final String? photoUrl;
  final String parentId;
}
```

### 5.3 Autres Modèles
- `CartItem` - Articles du panier
- `AnneeScolaire` - Année scolaire
- `Event` - Événements scolaires
- `Message` - Messages
- `Order` - Commandes
- `Product` - Produits boutique

## 6. Services Techniques

### 6.1 Service Thème
**Fichier**: `lib/services/theme_service.dart`
- Gestion thème clair/sombre
- Persistance des préférences
- Adaptation automatique

### 6.2 Service SMS
**Fichier**: `lib/services/sms_service.dart`
- Interface abstraite pour envoi SMS
- Implémentation Mock pour développement
- Préparation pour service SMS réel

### 6.3 Service API
**Fichier**: `lib/services/api_service.dart`
- Client HTTP configuré
- Gestion des erreurs
- Intercepteurs pour authentification

## 7. Sécurité

### 7.1 Authentification
- Token JWT pour les sessions
- Validation OTP à 6 chiffres
- Gestion des crédits SMS anti-abus

### 7.2 Stockage Sécurisé
- `shared_preferences` pour données non sensibles
- Préparation pour `flutter_secure_storage`
- Chiffrement des données locales prévu

### 7.3 Réseau
- HTTPS obligatoire en production
- Validation des certificats SSL
- Timeout et retry automatiques

## 8. Performance & Optimisation

### 8.1 Gestion d'État
- Services singleton pour éviter les recréations
- Cache local avec SQLite
- Chargement progressif des données

### 8.2 UI Responsive
- `flutter_screenutil` pour adaptation multi-écran
- Design adaptatif (375x812 base)
- Support tablette/desktop

### 8.3 Optimisations
- Lazy loading des écrans
- Compression des images
- Cache réseau intelligent

## 9. Déploiement & CI/CD

### 9.1 Environnements
- **Développement**: Mock services, données locales
- **Staging**: API de test, Firebase staging
- **Production**: Services réels, monitoring

### 9.2 Build & Distribution
- **Android**: APK/AAB via Gradle
- **iOS**: IPA via Xcode
- **Web**: Build statique
- **Desktop**: Exécutables natifs

### 9.3 Monitoring
- Firebase Analytics
- Crashlytics
- Performance monitoring

## 10. Tests & Qualité

### 10.1 Tests Unitaires
- Services métier
- Modèles de données
- Logique utilitaire

### 10.2 Tests d'Intégration
- Flux d'authentification
- Synchronisation données
- API endpoints

### 10.3 Tests UI
- Widgets tests
- Navigation
- Formulaires

## 11. Roadmap Développement

### Phase 1 (Actuelle)
- ✅ Structure de base
- ✅ Authentification téléphone/OTP
- ✅ UI responsive
- ✅ Base de données locale

### Phase 2 (Court terme)
- 🔄 Intégration Firebase complète
- 🔄 API backend réelle
- 🔄 Notifications push
- 🔄 Synchronisation multi-device

### Phase 3 (Moyen terme)
- 📋 Module paiement
- 📋 Analytics avancés
- 📋 Mode offline avancé
- 📋 Internationalisation

### Phase 4 (Long terme)
- 📋 IA pour recommandations
- 📋 Chatbot support
- 📋 Tableau de bord admin
- 📋 API tierces

## 12. Spécifications Techniques Complémentaires

### 12.1 Configuration Requise
- **Android**: API 21+ (Android 5.0)
- **iOS**: iOS 11.0+
- **Web**: Chrome 84+, Safari 14+
- **Desktop**: Windows 10+, macOS 10.14+, Ubuntu 18.04+

### 12.2 Performance Cibles
- Démarrage < 3 secondes
- Navigation < 500ms
- Taille APK < 50MB
- Mémoire RAM < 200MB

### 12.3 Accessibilité
- Support VoiceOver/TalkBack
- Contrastes WCAG 2.1 AA
- Navigation au clavier
- Texte redimensionnable

## 13. Maintenance & Support

### 13.1 Monitoring
- Crash reporting automatique
- Performance tracking
- Analytics d'utilisation
- Alertes en temps réel

### 13.2 Mises à Jour
- Mises à jour OTA (Over-The-Air)
- Migration de base de données
- Rétro-compatibilité API
- Communication changements

---

**Document version**: 1.0  
**Date**: 27 février 2026  
**Auteur**: Cascade AI Assistant  
**Statut**: Spécification technique complète
