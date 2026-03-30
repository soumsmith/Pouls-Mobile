# IntegrationRequestBottomSheet

Un composant Flutter réutilisable pour afficher un bottom sheet de consultation de demande d'intégration scolaire.

## Fonctionnalités

- Sélection d'une école via un dropdown
- Affichage du matricule de l'élève
- Bannière d'information
- Bouton de consultation avec état de chargement
- Gestion des erreurs et états vides

## Utilisation

```dart
import '../widgets/integration_request_bottom_sheet.dart';

// Dans votre widget
Widget _buildIntegrationRequestsTab() {
  return IntegrationRequestBottomSheet(
    matricule: widget.child.matricule,
    ecoles: _ecoles,
    isLoadingEcoles: _isLoadingEcoles,
    isLoadingIntegrationRequest: _isLoadingIntegrationRequest,
    selectedEcoleId: _selectedEcoleId,
    selectedEcoleName: _selectedEcoleName,
    onEcoleSelected: (ecoleId) {
      setState(() {
        _selectedEcoleId = ecoleId;
        final ecole = _ecoles.firstWhere((e) => e.ecoleid == ecoleId);
        _selectedEcoleName = ecole.ecoleclibelle;
      });
    },
    onConsultRequest: _consultIntegrationRequest,
    onRetryLoadEcoles: _loadEcoles,
    isDarkMode: _themeService.isDarkMode,
  );
}
```

## Paramètres

- `matricule` (String?): Matricule de l'élève à afficher
- `ecoles` (List<Ecole>): Liste des écoles disponibles
- `isLoadingEcoles` (bool): État de chargement des écoles
- `isLoadingIntegrationRequest` (bool): État de chargement de la consultation
- `selectedEcoleId` (int?): ID de l'école sélectionnée
- `selectedEcoleName` (String?): Nom de l'école sélectionnée
- `onEcoleSelected` (Function(int)): Callback lors de la sélection d'une école
- `onConsultRequest` (VoidCallback): Callback pour la consultation
- `onRetryLoadEcoles` (VoidCallback): Callback pour réessayer le chargement des écoles
- `isDarkMode` (bool): Mode sombre

## Dépendances

- `../config/app_colors.dart`
- `../widgets/searchable_dropdown.dart`
- `../models/ecole.dart`

## Personnalisation

Le composant utilise les couleurs définies dans `AppColors` et peut être adapté au mode sombre via le paramètre `isDarkMode`.
