---
name: module_1_notes
description: Règles de gestion pour la saisie et consultation des notes
---
# Spécifications Fonctionnelles - Module 1 : Gestion des notes

## Contexte
Ce module permet aux professeurs de saisir des notes et aux élèves/parents de les consulter.
Les services associés existants dans le projet incluent `lib/services/notes_api_service.dart`.

## Règles de Saisie par le Professeur
- **Processus** : Le professeur sélectionne une classe, une matière et une évaluation. Il saisit ensuite la note de chaque élève.
- **Validation du Barème** : Toute note saisie DOIT être comprise entre 0 et la note maximale du barème configuré (ex. /20). Toute valeur hors de cette plage doit déclencher une erreur explicite.
- **Traçabilité** : Chaque note est horodatée avec l'ID du professeur l'ayant saisie.
- **Visibilité** : Une fois validée (et synchronisée), la note est immédiatement visible par l'élève et ses parents.

## Règles de Consultation (Élèves & Parents)
- **Affichage** : Notes par matière avec un historique chronologique.
- **Informations requises** : Note, matière, type d'évaluation, date, moyenne calculée par matière.
- **Hors-ligne** : Se référer au Module 6 pour le stockage et la consultation hors-ligne de ces données.
