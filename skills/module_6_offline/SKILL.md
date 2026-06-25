---
name: module_6_offline
description: Stratégies de cache local, horodatage et synchronisation différée
---
# Spécifications Fonctionnelles - Module 6 : Fonctionnement Hors-Ligne (Offline)

## Contexte
L'application doit être pleinement fonctionnelle (en saisie et lecture) sans connexion internet.
Services associés : `lib/services/connectivity_service.dart`.

## Saisie et Lecture Hors-Ligne
- Les notes, l'appel, et le cahier de texte doivent pouvoir être saisis sans réseau.
- Les données préalablement synchronisées (en cache) doivent rester consultables.

## Synchronisation Différée
- **Stockage Local** : Toute donnée saisie hors-ligne est sauvegardée localement avec son horodatage réel exact de saisie.
- **Synchro Automatique** : Au retour du réseau, les requêtes en attente s'exécutent en arrière-plan sans action de l'utilisateur.
- **Résolution de Conflit** : En cas d'incohérence entre les données locales et serveur, appliquer la stratégie prioritaire à l'horodatage le plus récent (sauf si une validation manuelle est explicitement requise par une règle métier).
- **UI** : L'interface doit clairement indiquer "En attente de synchronisation" ou "Synchronisé".
