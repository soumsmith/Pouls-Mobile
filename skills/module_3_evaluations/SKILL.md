---
name: module_3_evaluations
description: Règles de notation anonyme des cours, calcul des indicateurs et notation des écoles
---
# Spécifications Fonctionnelles - Module 3 : Notation et évaluation de la qualité

## Contexte
Gestion des retours qualitatifs sur les cours et les établissements scolaires.

## Notation des professeurs sur un cours
- **Processus** : L'élève peut noter de 1 à 5 un cours après l'avoir suivi.
- **Anonymat** : La note doit rester anonyme pour le professeur (moyenne agrégée uniquement).
- **Vérification de Présence** : Un élève ne peut noter qu'un cours auquel il était effectivement PRÉSENT (nécessite le croisement avec les données d'appel du Module 4).

## Notation automatique du système
- Le système calcule un indicateur de qualité par professeur basé sur :
  1. Ponctualité et régularité de l'appel numérique.
  2. Régularité de saisie du cahier de texte.
  3. Respect des délais de saisie des notes.
- Cet indicateur est réservé à la Direction d'école.

## Notation des écoles
- **Acteurs** : Élèves et/ou Parents.
- **Critères indépendants** : Qualité perçue, niveau des notes, confort, propreté générale, propreté des toilettes.
- **Règle** : Pas de note globale imposée, chaque critère est noté séparément. Les résultats sont consultables au niveau national (agrégés).
