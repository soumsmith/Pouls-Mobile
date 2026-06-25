---
name: module_4_appel_numerique
description: Logique d'autorisation de l'appel (GPS/Clé), notifications configurables
---
# Spécifications Fonctionnelles - Module 4 : Appel numérique

## Contexte
Permet au professeur de marquer la présence/absence, sous condition de vérification géographique ou de clé de sécurité.
Services associés : `lib/services/gestion_presence_eleve_service.dart`, `lib/services/statistiques_presence_service.dart`.

## Validation Présent/Absent
- Le professeur marque les élèves. L'appel ne peut être effectué qu'APRÈS autorisation réussie.

## Notifications & Alerte Sonore
- **Configuration** : Notification paramétrable (Avant, Pendant, Après le début, Avant la fin, Après la fin du cours).
- **Alerte** : Une alerte sonore (alarme) spécifique DOIT être jouée pour garantir que la notification de l'appel n'est pas manquée.

## Autorisation de l'appel (Verrouillage de sécurité)
L'appel nécessite une de ces deux conditions validées :
1. **Géolocalisation (Voie Principale)** : Le GPS confirme que le professeur est dans le périmètre de l'école.
2. **Clé Numérique (Voie de Secours)** : En cas d'échec GPS, saisie d'un PIN à 4 chiffres généré par le Directeur des études (au niveau de l'école).
- **Audit** : La méthode d'autorisation utilisée doit être enregistrée et envoyée au serveur.
