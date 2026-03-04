# Implémentation de la fonctionnalité de notation

## Description
Cette implémentation ajoute la fonctionnalité de notation des établissements scolaires via un bottom sheet qui permet aux utilisateurs de laisser un témoignage.

## Fonctionnalités implémentées

### 1. Bottom sheet de notation
- **Accès**: Via le bouton "Noter" dans la page de détail d'un établissement
- **Formulaire simplifié**: Note (étoiles interactives) + Commentaire
- **Validation**: Vérification que les champs sont remplis avant l'envoi

### 2. Intégration API
- **Service utilisé**: `TestimonialService` 
- **Endpoint**: `https://api2.vie-ecoles.com/api/vie-ecoles/avis/{userNumero}`
- **Méthode**: POST
- **Données envoyées**:
  ```json
  {
    "codeecole": "code_de_l_ecole",
    "note": "5",
    "contenu": "Meilleur école."
  }
  ```

### 3. Gestion utilisateur
- **Authentification**: Récupération automatique du numéro de téléphone de l'utilisateur connecté via `AuthService`
- **Feedback utilisateur**: Messages de succès/erreur avec SnackBar
- **Indicateur de chargement**: Dialogue pendant l'appel API

## Structure du code

### Modifications apportées
1. **Imports ajoutés**:
   ```dart
   import '../services/testimonial_service.dart';
   import '../services/auth_service.dart';
   ```

2. **Méthode mise à jour**: `_showRatingBottomSheet()`
   - Formulaire simplifié (note + commentaire)
   - Étoiles interactives avec `StatefulBuilder`
   - Appel API asynchrone
   - Gestion des erreurs

3. **Flux utilisateur**:
   - Clic sur "Noter" → Ouverture du bottom sheet
   - Sélection de la note (étoiles)
   - Saisie du commentaire
   - Soumission → Appel API
   - Feedback → Fermeture du formulaire

## Points techniques importants

### Gestion d'état
- Utilisation de `StatefulBuilder` pour les étoiles interactives
- Maintien de l'état des contrôleurs de texte

### Sécurité
- Vérification de l'authentification avant l'envoi
- Validation des données côté client

### UX
- Indicateur de chargement pendant l'appel API
- Messages clairs de succès/erreur
- Réinitialisation des champs après succès

## Utilisation

1. L'utilisateur doit être connecté (via `AuthService`)
2. Naviguer vers la page de détail d'un établissement
3. Cliquer sur le bouton "Noter"
4. Sélectionner une note (1-5 étoiles)
5. Rédiger un commentaire
6. Cliquer sur "Envoyer l'avis"

Le témoignage est envoyé à l'API avec le numéro de téléphone de l'utilisateur connecté.
