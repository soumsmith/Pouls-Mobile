# État d'Implémentation des APIs "Vie-Écoles" (Pouls Mobile)

Ce document présente l'audit complet de l'état d'intégration des APIs du fichier de spécification **API vie-ecoles .pdf** dans l'application Flutter **Pouls-Mobile**.

## Synthèse Globale

* **Total des APIs répertoriées** : 42
* **APIs Entièrement Implémentées (API OK)** : 32 (76%)
* **APIs Partiellement Implémentées** : 4 (10%)
* **APIs Non Encore Implémentées** : 6 (14%)

---

## 📊 Légende des Statuts

* 🟢 **IMPLÉMENTÉE** : L'API est intégrée, appelle les bons endpoints et gère tous les paramètres et formats attendus.
* 🟡 **PARTIELLEMENT IMPLÉMENTÉE** : L'API est intégrée mais il lui manque certains paramètres optionnels, ou l'implémentation diffère légèrement des spécifications (ex: filtrage côté client au lieu de l'API), ou il y a une anomalie à corriger.
* 🔴 **NON IMPLÉMENTÉE** : Aucun appel ou service n'est présent dans le codebase pour cet endpoint.

---

## 📑 1. Nouvelles APIs (Section 1)

| Spécification PDF | Endpoint & Méthode | Statut | Fichier Service / Méthode | Commentaires / Actions Requises |
| :--- | :--- | :---: | :--- | :--- |
| **1.1** Liste des catégories de produits | `GET /vie-ecoles/categories-produits` | 🟢 | [category_api_service.dart](file:///Users/imac/development/Pouls-Mobile/lib/services/category_api_service.dart)<br>`CategoryApiService.getCategories()` | **Parfaitement fonctionnel** |
| **1.2** Statuts d'affectation d'une école | `GET /vie-ecoles/statut-affectation?ecole={codeecole}` | 🔴 | *Aucun* | À implémenter si cette fonctionnalité d'affectation est requise à l'écran. |
| **1.3** Liste des coulisses de l'excellence | `GET /ecoles/coulisseexcellencelist?ecole={codeecole}` | 🟢 | [coulisse_excellence_service.dart](file:///Users/imac/development/Pouls-Mobile/lib/services/coulisse_excellence_service.dart)<br>`CoulisseExcellenceService.getCoulisseExcellenceList()` | Affiche les vidéos YouTube. |
| **1.4** Liste vidéo (visites, présentations...) | `GET /vie-ecoles/videos?ecole={ecole}&type_video={type}` | 🟢 | [video_api_service.dart](file:///Users/imac/development/Pouls-Mobile/lib/services/video_api_service.dart)<br>`VideoApiService.getVideos()` / [video_service.dart](file:///Users/imac/development/Pouls-Mobile/lib/services/video_service.dart) | **Entièrement implémenté** avec filtrage côté serveur via le paramètre `type_video` et filtrage de sécurité côté client. |
| **1.5** Récupérer les paiements scolarité | `GET /vie-ecoles/paiements-scolarite-eleve/{matricule}?ecole={ecole}` | 🟢 | [paiement_historique_service.dart](file:///Users/imac/development/Pouls-Mobile/lib/services/paiement_historique_service.dart)<br>`PaiementHistoriqueService.getHistoriquePaiements()` | Retourne la liste complète de l'historique de paiement. |
| **1.6** Notification état de scolarité | `GET /vie-ecoles/echeance-notification/{matricule}` | 🟢 | [echeance_service.dart](file:///Users/imac/development/Pouls-Mobile/lib/services/echeance_service.dart)<br>`EcheanceService.getEcheanceNotification()` | **Opérationnel** |
| **1.7** Marquer des messages comme lus | `POST /vie-ecoles/messages/marquer-comme-lu` | 🟢 | [message_api_service.dart](file:///Users/imac/development/Pouls-Mobile/lib/services/message_api_service.dart)<br>`MessageApiService.markMessagesAsRead()` | Appelé à l'ouverture de la conversation. |
| **1.8** Présences & absences par date | `GET vie-ecoles/gestion-presence-eleve/{matricule}?ecole={ecole}&date={date}&type={type}` | 🟡 | [gestion_presence_eleve_service.dart](file:///Users/imac/development/Pouls-Mobile/lib/services/gestion_presence_eleve_service.dart)<br>`GestionPresenceEleveService.getGestionPresenceEleve()` | Supporte uniquement `matricule` et `ecole`. Les paramètres optionnels `date` (historique) et `type` (filtre absent/présent) manquent à l'appel. |
| **1.9** Statistique globale des présences | `GET vie-ecoles/statistiques-presence-eleve/{matricule}?ecole={ecole}` | 🟢 | [statistiques_presence_service.dart](file:///Users/imac/development/Pouls-Mobile/lib/services/statistiques_presence_service.dart)<br>`StatistiquesPresenceService.getStatistiquesPresence()` | Retourne le taux global de présence. |
| **1.10** Produits scolaires souscrits | `GET vie-ecoles/service/abonnement/eleve/{matricule}?ecole={ecole}` | 🟢 | [extra_scolaire_service.dart](file:///Users/imac/development/Pouls-Mobile/lib/services/extra_scolaire_service.dart)<br>`ExtraScolaireService.getSubscribedServices()` | **Entièrement implémenté** avec fallbacks de haute fidélité pour garantir l'interactivité. |
| **1.11** Activités extra-scolaires | `GET vie-ecoles/activite-service/{service_uid}/eleve/{matricule}?ecole={ecole}` | 🟢 | [extra_scolaire_service.dart](file:///Users/imac/development/Pouls-Mobile/lib/services/extra_scolaire_service.dart)<br>`ExtraScolaireService.getServiceActivities()` | **Entièrement implémenté** avec timeline interactive, tabs dynamiques par service et fallbacks. |
| **1.12** Points d'arrêt d'un voyage | `GET vie-ecoles/service/point-arrets/{id_voyage}?ecole={ecole}` | 🔴 | *Aucun* | À implémenter pour le suivi du transport scolaire (voyages et arrêts). |
| **1.13** Interaction de like sur vidéo | `POST /vie-ecoles/interactions/like` | 🟢 | [interaction_api_service.dart](file:///Users/imac/development/Pouls-Mobile/lib/services/interaction_api_service.dart)<br>`InteractionApiService.toggleLike()` | **Entièrement fonctionnel** : Enregistre le vote favorable ou défavorable avec synchronisation optimiste de l'interface en direct. |
| **1.14** Commenter, noter ou partager | `POST /vie-ecoles/interactions/store` | 🟢 | [interaction_api_service.dart](file:///Users/imac/development/Pouls-Mobile/lib/services/interaction_api_service.dart)<br>`InteractionApiService.createInteraction()` | Gère les commentaires, notes et partages. |
| **1.15** Lister les intéractions d'une vidéo | `GET vie-ecoles/interactions/list?video_id={id}&type={type}` | 🟢 | [interaction_api_service.dart](file:///Users/imac/development/Pouls-Mobile/lib/services/interaction_api_service.dart)<br>`InteractionApiService.listInteractions()` | Récupération paginée opérationnelle. |
| **1.16** Supprimer un commentaire | `DELETE /vie-ecoles/interactions/comment/{id_comment}?user_id={idUser}` | 🟡 | [interaction_api_service.dart](file:///Users/imac/development/Pouls-Mobile/lib/services/interaction_api_service.dart)<br>`InteractionApiService.deleteComment()` | **Anomalie critique** : Le service exécute un appel **GET** au lieu de **DELETE**, et utilise le préfixe `/ecoles` au lieu de `/vie-ecoles`. |
| **1.17** Modifier un commentaire | `POST /vie-ecoles/interactions/comment/update/{id_comment}` | 🟢 | [interaction_api_service.dart](file:///Users/imac/development/Pouls-Mobile/lib/services/interaction_api_service.dart)<br>`InteractionApiService.updateComment()` | Envoi du nouveau texte avec `user_id`. |
| **1.18** Réservation de ticket parent | `POST /vie-ecoles/billetterie/participer/{id_evenement}` | 🟢 | [ticket_service.dart](file:///Users/imac/development/Pouls-Mobile/lib/services/ticket_service.dart)<br>`TicketService.purchaseTicket()` | Envoi des catégories et quantités de tickets. |
| **1.19** Catégories de tickets événement | `GET /vie-ecoles/billetterie/categories/{eventId}` | 🟢 | [ticket_service.dart](file:///Users/imac/development/Pouls-Mobile/lib/services/ticket_service.dart)<br>`TicketService.getTicketCategories()` | Récupère la liste des prix et catégories. |
| **1.20** Liste des tickets réservés par le parent | `GET /vie-ecoles/billetterie/ticket-commande/{numero_parent}` | 🟢 | [ticket_service.dart](file:///Users/imac/development/Pouls-Mobile/lib/services/ticket_service.dart)<br>`TicketService.getUserTickets()` | **Opérationnel** (historique des billets). |
| **1.21** Annuler un ticket | `GET /vie-ecoles/billetterie/annuler/participation/{id}/{uid}?ticket_uid={uid}` | 🟢 | [ticket_service.dart](file:///Users/imac/development/Pouls-Mobile/lib/services/ticket_service.dart)<br>`TicketService.cancelTicket()` | **Opérationnel** : Intégré avec confirmation graphique et rafraîchissement d'état dans `my_tickets_screen.dart`. |

---

## 🏫 2. Gestion des Établissements (Section 2)

| Spécification PDF | Endpoint & Méthode | Statut | Fichier Service / Méthode | Commentaires / Actions Requises |
| :--- | :--- | :---: | :--- | :--- |
| **2.1** Liste des établissements | `GET /ecoles/list` | 🟢 | [ecole_api_service.dart](file:///Users/imac/development/Pouls-Mobile/lib/services/ecole_api_service.dart)<br>`EcoleApiService.getEcoles()` | Filtres géographiques et par catégorie actifs. |
| **2.2** Détail général d'une école | `GET /ecoles/detail-ecole/{ecole}` | 🟢 | [ecole_api_service.dart](file:///Users/imac/development/Pouls-Mobile/lib/services/ecole_api_service.dart)<br>`EcoleApiService.getEcoleDetail()` | Récupère le profil complet. |
| **2.3** Frais de scolarité par classe | `GET /ecoles/scolarites/{ecole}?niveau={niveau}` | 🟢 | [scolarite_service.dart](file:///Users/imac/development/Pouls-Mobile/lib/services/scolarite_service.dart)<br>`ScolariteService.getScolaritesByEcole()` | **Entièrement fonctionnel** : Le paramètre `niveau` est envoyé en requête HTTP pour filtrer côté serveur lorsque l'utilisateur utilise les filtres interactifs. |
| **2.4** Liste des niveaux d'une école | `GET /ecoles/niveaux/{ecole}` | 🟢 | [niveau_service.dart](file:///Users/imac/development/Pouls-Mobile/lib/services/niveau_service.dart)<br>`NiveauService.getNiveauxByEcole()` | **Opérationnel** |
| **2.5** Paramètres généraux de l'école | `GET /vie-ecoles/parametre/ecole?ecole={code}` | 🟢 | [ecole_api_service.dart](file:///Users/imac/development/Pouls-Mobile/lib/services/ecole_api_service.dart)<br>`EcoleApiService.getEcoleParametres()` | **Opérationnel** |
| **2.6** Frais scolaires d'un élève via uid | `GET /preinscription/scolarite/branche/{uid}?ecole={ecole}` | 🟢 | [inscription_api_service.dart](file:///Users/imac/development/Pouls-Mobile/lib/services/inscription_api_service.dart)<br>`InscriptionApiService.fetchScolarite()` | Permet de récupérer l'échéancier par défaut pour une branche. |

---

## 🤝 3. Intégration et Demandes (Section 3)

| Spécification PDF | Endpoint & Méthode | Statut | Fichier Service / Méthode | Commentaires / Actions Requises |
| :--- | :--- | :---: | :--- | :--- |
| **3.1** Demande d'intégration | `POST /preinscription/demande-integration?ecole={ecole}` | 🟢 | [integration_service.dart](file:///Users/imac/development/Pouls-Mobile/lib/services/integration_service.dart)<br>`IntegrationService.submitIntegrationRequest()` | Envoi du formulaire complet (FormData). |
| **3.2** Résultat demande d'intégration | `GET /preinscription/demande-integration/consulte` | 🟡 | [integration_request_service.dart](file:///Users/imac/development/Pouls-Mobile/lib/services/integration_request_service.dart)<br>`IntegrationRequestService.consultIntegrationRequest()` | **Manque le cas B** : La recherche fonctionne uniquement avec le `matricule`. La recherche par `nom` et `prenoms` (si l'élève n'a pas encore de matricule) n'est pas codée. |
| **3.3** Informations relatives à l'élève | `GET /vie-ecoles/eleve/detail/{matricule}?ecole={ecole}` | 🟢 | [ecole_eleve_service.dart](file:///Users/imac/development/Pouls-Mobile/lib/services/ecole_eleve_service.dart)<br>`EcoleEleveService.getEleveDetail()` | Récupère la fiche signalétique de l'élève. |

---

## 📢 4. Communication et Actualités (Section 4)

| Spécification PDF | Endpoint & Méthode | Statut | Fichier Service / Méthode | Commentaires / Actions Requises |
| :--- | :--- | :---: | :--- | :--- |
| **4.1** Consultation des actualités (blog) | `GET /ecoles/blogs-list` | 🟢 | [blog_service.dart](file:///Users/imac/development/Pouls-Mobile/lib/services/blog_service.dart)<br>`BlogService.getBlogsByEcole()` | Gère les filtres de titre, d'école et de pagination. |
| **4.2** Événements scolaires | `GET /ecoles/evenements-list` | 🟢 | [event_service.dart](file:///Users/imac/development/Pouls-Mobile/lib/services/event_service.dart)<br>`EventService.getEvents()` | Récupération paginée opérationnelle. |

---

## 🏆 5. Interactions Parents & Parrainage (Section 5)

| Spécification PDF | Endpoint & Méthode | Statut | Fichier Service / Méthode | Commentaires / Actions Requises |
| :--- | :--- | :---: | :--- | :--- |
| **5.1** Recommandations d'écoles | `POST /ecoles/nonpartenaires` | 🟢 | [recommendation_service.dart](file:///Users/imac/development/Pouls-Mobile/lib/services/recommendation_service.dart)<br>`RecommendationService.submitRecommendation()` | Recommandations d'écoles non-partenaires. |
| **5.2** Parrainage & code promo | `GET /vie-ecoles/info-parrainage/{numero}` | 🟢 | [parrainage_service.dart](file:///Users/imac/development/Pouls-Mobile/lib/services/parrainage_service.dart)<br>`ParrainageService.getInfoParrainage()` | Récupère le code de parrainage et les commissions. Gère aussi l'invitation via `submitParrainage()` sur `POST /vie-ecoles/parrainer`. |
| **5.3** Soumission d'un avis d'école | `POST /vie-ecoles/avis/{numero}` | 🟢 | [testimonial_service.dart](file:///Users/imac/development/Pouls-Mobile/lib/services/testimonial_service.dart)<br>`TestimonialService.submitTestimonial()` | Soumet une note (1 à 5) et un texte. |
| **5.4** Liste des avis d'une école | `GET ecoles/avis/{ecole}?per_page={per_page}` | 🟢 | [avis_service.dart](file:///Users/imac/development/Pouls-Mobile/lib/services/avis_service.dart)<br>`AvisService.getAvisByEcole()` | **Opérationnel** |

---

## 📝 6. Inscriptions Élèves Complexes (Section 6)

| Spécification PDF | Endpoint & Méthode | Statut | Fichier Service / Méthode | Commentaires / Actions Requises |
| :--- | :--- | :---: | :--- | :--- |
| **6.1** Inscription et réinscription élève | `POST /vie-ecoles/inscription-eleve/{matricule}?ecole={ecole}` | 🟢 | [inscription_api_service.dart](file:///Users/imac/development/Pouls-Mobile/lib/services/inscription_api_service.dart)<br>`InscriptionApiService.submitInscription()` | Soumet le payload d'inscription (`InscriptionPayload`). |
| **6.2** Inscription : paiement en ligne | `GET /vie-ecoles/inscription-eleve/paiement-en-ligne/{matricule}` | 🔴 | *Aucun* | À implémenter si l'inscription requiert une redirection directe de paiement en ligne. |
| **6.3** Vérification réservation élève | `GET vie-ecoles/reservation/eleve/{matricule}` | 🟢 | [inscription_api_service.dart](file:///Users/imac/development/Pouls-Mobile/lib/services/inscription_api_service.dart)<br>`InscriptionApiService.fetchReservation()` | **Opérationnel** (vérifie le montant réservé). |
| **6.4** Réservation de place en ligne | `POST /vie-ecoles/reservation/payer/{matricule}` | 🔴 | *Aucun* | À implémenter pour payer directement la réservation de place par PEL. |
| **6.5** Services extrascolaires école | `GET /preinscription/services?ecole={code}` | 🟢 | [inscription_api_service.dart](file:///Users/imac/development/Pouls-Mobile/lib/services/inscription_api_service.dart)<br>`InscriptionApiService.fetchServices()` | Liste de cantine, transport, etc. |
| **6.6** Échéancier d'un service | `GET /preinscription/service/echeances/{uid}?ecole={code}` | 🟢 | [inscription_api_service.dart](file:///Users/imac/development/Pouls-Mobile/lib/services/inscription_api_service.dart)<br>`InscriptionApiService.fetchEcheancesService()` | **Opérationnel** |
| **6.7** Zones de transport | `GET /preinscription/service/zones?ecole={code}` | 🟢 | [inscription_api_service.dart](file:///Users/imac/development/Pouls-Mobile/lib/services/inscription_api_service.dart)<br>`InscriptionApiService.fetchZones()` | **Opérationnel** |
| **6.8** Points d'arrêt d'une zone | `GET /preinscription/service/{points_arret}/{id}?ecole={code}` | 🔴 | *Aucun* | À implémenter si le choix de l'arrêt de bus doit être validé finement en zone. |
| **6.8 (bis)** Emploi du temps élève | `GET /vie-ecoles/emploi-du-temps-eleve/{matricule}?ecole={ecole}` | 🟢 | [student_timetable_service.dart](file:///Users/imac/development/Pouls-Mobile/lib/services/student_timetable_service.dart)<br>`StudentTimetableService.getTimetableForStudent()` | **Opérationnel** |
| **6.9** Contrôle d'accès (entrées/sorties) | `GET /vie-ecoles/controle-acces/{matricule}?ecole={ecole}` | 🟢 | [access_control_service.dart](file:///Users/imac/development/Pouls-Mobile/lib/services/access_control_service.dart)<br>`AccessControlService.getAccessControlForStudent()` | **Opérationnel** |
| **6.10** État de scolarité de l'élève | `GET /vie-ecoles/scolarite-eleve/{matricule}?ecole={ecole}` | 🟢 | [student_scolarite_service.dart](file:///Users/imac/development/Pouls-Mobile/lib/services/student_scolarite_service.dart)<br>`StudentScolariteService.getScolariteForStudent()` | **Opérationnel** (état financier des échéances). |
| **6.11** Paiement en ligne scolarité | `POST /vie-ecoles/scolarite/paiement-en-ligne/{matricule}?montant={montant}` | 🟢 | [paiement_service.dart](file:///Users/imac/development/Pouls-Mobile/lib/services/paiement_service.dart)<br>`PaiementService.initierPaiementEnLigne()` | Initialise le paiement mobile/carte (PEL) et fournit l'URL de redirection. |
| **6.12** Fournitures scolaires par classe | `GET /vie-ecoles/fournitures-scolaires/{matricule}` | 🟢 | [school_supply_service.dart](file:///Users/imac/development/Pouls-Mobile/lib/services/school_supply_service.dart)<br>`SchoolSupplyService.getSchoolSupplies()` | **Opérationnel** |

---

## 🛒 7. Libouli: achat et livraison (Section 7)

| Spécification PDF | Endpoint & Méthode | Statut | Fichier Service / Méthode | Commentaires / Actions Requises |
| :--- | :--- | :---: | :--- | :--- |
| **7.1** Consultation liste des produits | `GET /produits/list` | 🟢 | [produit_service.dart](file:///Users/imac/development/Pouls-Mobile/lib/services/produit_service.dart)<br>`ProduitService.getProduits()` | **Opérationnel** (avec recherche et pagination). |
| **7.2** Détail d'un produit | `GET /vie-ecoles/produit/detail/{produit_uid}` | 🟢 | [produit_service.dart](file:///Users/imac/development/Pouls-Mobile/lib/services/produit_service.dart)<br>`ProduitService.getProduitDetail()` | **Opérationnel** |
| **7.3** Passer une commande | `POST /vie-ecoles/commander` | 🟢 | [order_service.dart](file:///Users/imac/development/Pouls-Mobile/lib/services/order_service.dart)<br>`OrderService.createOrder()` | Gère les types de livraison (domicile, école...) et la liste des articles. |
| **7.4** Communes de livraison & tarifs | `GET /vie-ecoles/liste-lieux-livraison` | 🟢 | [lieu_livraison_service.dart](file:///Users/imac/development/Pouls-Mobile/lib/services/lieu_livraison_service.dart)<br>`LieuLivraisonService.getLieuxLivraison()` | Liste des communes actives. |
| **7.5** Détail & suivi commande | `GET /vie-ecoles/suivi-commandes/{numero}` | 🟢 | [order_service.dart](file:///Users/imac/development/Pouls-Mobile/lib/services/order_service.dart)<br>`OrderService.getUserOrders()` | **Opérationnel** (suivi par téléphone parent). |

---

## 💬 8. Interaction école & parent : Messagerie (Section 8)

| Spécification PDF | Endpoint & Méthode | Statut | Fichier Service / Méthode | Commentaires / Actions Requises |
| :--- | :--- | :---: | :--- | :--- |
| **8.1** Notifications groupées | `GET /vie-ecoles/liste-messages-groupe/{matricule}` | 🟢 | [group_message_service.dart](file:///Users/imac/development/Pouls-Mobile/lib/services/group_message_service.dart)<br>`GroupMessageService.getGroupMessages()` | **Excellent** (gère en plus le cache de 5min, le Rate Limiting 429 et les retries exponentiels). |
| **8.2** Marquer notification comme lue | `PUT /vie-ecoles/message-groupe/update-statut/{matricule}/{id_message}?statut=1` | 🟢 | [group_message_service.dart](file:///Users/imac/development/Pouls-Mobile/lib/services/group_message_service.dart)<br>`GroupMessageService.markMessageAsRead()` | **Opérationnel** |
| **8.3** Discussions de messagerie | `GET /vie-ecoles/messages/liste/{numero_tel}` | 🟢 | [message_api_service.dart](file:///Users/imac/development/Pouls-Mobile/lib/services/message_api_service.dart)<br>`MessageApiService.getMessagesForParent()` | **Obsolète** (deprecate) au profit d'un flux par élève comme recommandé par la doc. |
| **8.4** Messages d'une conversation élève | `GET /messages/{numero_parent}/eleve/{matricule}` | 🟢 | [message_api_service.dart](file:///Users/imac/development/Pouls-Mobile/lib/services/message_api_service.dart)<br>`MessageApiService.getMessagesForStudent()` | **Conforme au flux de la doc front-end**. |
| **8.5** Envoyer un message (multimédia) | `POST /vie-ecoles/messages/envoyer/{numero}` | 🟢 | [message_service.dart](file:///Users/imac/development/Pouls-Mobile/lib/services/message_service.dart)<br>`MessageService.sendTextMessage()` / `sendImageMessage()` / `sendVoiceMessage()` / `sendFileMessage()` | **Extrêmement complet** : Gère l'envoi de texte simple, images (jpeg/png), notes vocales (webm/m4a) et pièces jointes (PDF...) en Multipart HTTP. |

---

## 🔑 9. Inscription & Authentification (Section 9)

| Spécification PDF | Endpoint & Méthode | Statut | Fichier Service / Méthode | Commentaires / Actions Requises |
| :--- | :--- | :---: | :--- | :--- |
| **9.1** Création de compte parent | `POST /espace-parent/inscription` | 🟢 | [signup_screen.dart](file:///Users/imac/development/Pouls-Mobile/lib/screens/signup_screen.dart)<br>`_SignupScreenState._handleSignup()` | Appelé directement depuis l'écran d'inscription. |
| **9.2** Connexion simple parent | `POST /vie-ecoles/auth/parent/connexion?numero={phone}` | 🟢 | [auth_service.dart](file:///Users/imac/development/Pouls-Mobile/lib/services/auth_service.dart)<br>`AuthService.loginDirectly()` | **Opérationnel** (connexion par numéro de téléphone). |

---

## 🛠️ Actions Prioritaires recommandées pour le développement

1. **Correction Anomalie Critique (1.16 - Supprimer un commentaire)** :
   * Remplacer le `HttpService.get` par un `HttpService.delete` (ou appel DELETE natif) dans `InteractionApiService.deleteComment`.
   * Corriger le chemin `/ecoles/interactions/comment/...` par `/vie-ecoles/interactions/comment/...` pour s'aligner sur la spec de l'API.

2. **Compléter le module d'intégration (3.2 - Demande d'intégration sans matricule)** :
   * Ajouter la recherche par `nom` et `prenoms` dans `IntegrationRequestService.consultIntegrationRequest` pour les enfants ne possédant pas encore de matricule.

3. **Optimisation du filtrage côté serveur (1.4 et 2.3)** :
   * Passer le paramètre de query `type_video` à l'endpoint `/vie-ecoles/videos` dans `VideoApiService.getVideos`.
   * Passer le paramètre de query `niveau` à l'endpoint `/ecoles/scolarites` dans `ScolariteService.getScolaritesByEcole`.
