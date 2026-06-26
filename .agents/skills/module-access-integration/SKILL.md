---
name: Intégration Module Access Guard
description: Instructions complètes pour intégrer de bout en bout le système de verrouillage (gratuit/payant) des modules sur n'importe quel écran ou application.
---

# 🚀 Guide d'intégration du système Module Access Guard

Ce skill décrit l'architecture et les étapes exactes pour intégrer le système de contrôle d'accès aux modules (Gratuit / Payant) de manière élégante et fonctionnelle.

## 🏛️ Architecture du système

Le système repose sur 3 composants clés :
1. **`AppModule` (Modèle)** : Représente la donnée brute de l'API (avec son type `gratuit` ou `payant`).
2. **`ModuleAccessService` (Service Singleton)** : Se charge de requêter l'API au démarrage, garde en mémoire les identifiants débloqués (`accessible_modules`) et fournit la méthode synchrone `isModuleAccessible(identifiant)`.
3. **`ModuleGuard` (Widget & Logique UI)** : Un widget qui superpose un cadenas parfaitement centré sur son composant enfant si l'accès est bloqué, tout en rendant le composant enfant légèrement transparent.

---

## 🛠️ Étapes d'intégration pas à pas

### 1. Initialisation globale (Au démarrage de l'app)
Pour que l'expérience soit fluide, les données doivent être chargées dès l'authentification de l'utilisateur.

```dart
// Dans votre écran principal ou wrapper de navigation (ex: MainScreenWrapper)
@override
void initState() {
  super.initState();
  // ... autres initialisations ...
  ModuleAccessService().fetchModules();
}
```

### 2. Adaptation de vos composants UI réutilisables (Les Cartes / Boutons)
**C'est la règle d'or pour un rendu UI parfait :**
Il ne faut **PAS** envelopper tout votre composant avec `ModuleGuard` depuis l'écran parent, sinon le cadenas se retrouvera décentré (souvent entre l'icône et le texte) et grisera le texte. 
Il faut plutôt faire descendre `moduleIdentifiant` dans les paramètres de votre composant, et appliquer `ModuleGuard` **uniquement autour de l'image/icône**.

**Exemple d'adaptation d'une carte (ex: `ImageMenuCard`) :**

```dart
class ImageMenuCard extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  final String moduleIdentifiant; // 1. Ajoutez ce paramètre

  const ImageMenuCard({
    required this.title,
    required this.onTap,
    this.moduleIdentifiant = '', // Par défaut vide (pas de verrouillage)
  });

  @override
  Widget build(BuildContext context) {
    // 2. Isolez la construction visuelle de votre icône
    Widget iconWidget = Container(
      width: 70, height: 70,
      decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.blue),
      child: Icon(Icons.star),
    );

    // 3. Enveloppez UNIQUEMENT l'icône avec le ModuleGuard
    if (moduleIdentifiant.isNotEmpty) {
      iconWidget = ModuleGuard(
        moduleIdentifiant: moduleIdentifiant,
        child: iconWidget,
      );
    }

    return GestureDetector(
      // 4. Interceptez le clic GLOBAL pour afficher le dialogue au lieu de naviguer
      onTap: () {
        if (moduleIdentifiant.isNotEmpty &&
            !ModuleAccessService().isModuleAccessible(moduleIdentifiant)) {
          ModuleGuard.showLockedDialog(context);
        } else {
          onTap();
        }
      },
      child: Column(
        children: [
          iconWidget, // Icône (potentiellement grisée avec cadenas)
          Text(title), // Texte TOUJOURS lisible et clair
        ],
      ),
    );
  }
}
```

### 3. Déclaration depuis vos écrans (Ex: L'écran Liste)
Depuis vos écrans métiers, il vous suffit de passer la bonne clé API (`identifiant`) à votre composant mis à jour.

```dart
ImageMenuCard(
  title: 'Présence & Conduite',
  moduleIdentifiant: 'presence-classe', // La clé API correspondante !
  onTap: () {
    // Logique de navigation standard (exécutée uniquement si accès autorisé)
    Navigator.push(context, ...); 
  },
)
```

---

## 🎨 Pourquoi cette approche ? (Bonnes Pratiques)

- **UI Pixel-Perfect** : En ciblant uniquement l'icône avec `ModuleGuard`, le widget `Stack` interne de `ModuleGuard` prend la taille exacte de l'icône. L'utilisation de `Positioned.fill` et `Align(alignment: Alignment.center)` placera donc toujours le cadenas au cœur du bouton.
- **Accessibilité du texte** : Le nom de la fonctionnalité reste parfaitement lisible, ce qui donne envie à l'utilisateur de cliquer dessus pour s'y abonner.
- **Sécurité anti-clic** : L'interception du `onTap` directement à la racine du bouton global assure que même si l'utilisateur clique sur le texte (et pas sur l'icône cadenassée), le dialogue d'abonnement apparaîtra.
- **Fail-Open** : Par défaut, si l'API est indisponible ou si un identifiant est mal renseigné (non trouvé dans la liste), le module est considéré comme accessible pour ne pas bloquer l'utilisateur par erreur.

## 🔄 Rechargement après paiement
Si l'utilisateur souscrit à un abonnement via l'application, n'oubliez pas d'appeler `await ModuleAccessService().refresh();` suite au succès du paiement pour mettre à jour instantanément tous les cadenas de l'interface !
