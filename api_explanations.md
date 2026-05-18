# Explications Détaillées des Fonctionnalités APIs "Vie-Écoles"

Ce document fournit une explication concrète et approfondie pour **chaque API** listée dans la documentation technique. Il détaille le rôle technique au niveau du serveur (Backend) et la fonctionnalité métier concrète qu'elle apporte aux parents sur l'application mobile (Frontend), accompagnée de son niveau d'implémentation.

---

## 📊 Légende des Voyants

* 🟢 **VERT** : API Entièrement Implémentée et Opérationnelle
* 🟡 **ORANGE** : API Partiellement Implémentée ou comportant des optimisations/corrections en suspens
* 🔴 **ROUGE** : API Non Encore Implémentée

---

## 📑 1. Nouvelles APIs (Section 1)

### 🟢 1.1 Liste des catégories de produits (`GET /vie-ecoles/categories-produits`)
* **Rôle technique (Backend)** : Récupère la liste de toutes les catégories d'articles scolaires configurées sur la plateforme e-commerce Libouli (ex: Manuels Scolaires, Uniformes, Sacs à dos, Papeterie).
* **Fonctionnalité parent (Mobile)** : Alimente les onglets de filtres dans la boutique en ligne (`shop_screen.dart`). Le parent peut filtrer instantanément les articles par catégorie pour trouver plus rapidement les fournitures de son enfant.

### 🔴 1.2 Statuts d'affectation d'une école (`GET /vie-ecoles/statut-affectation?ecole={codeecole}`)
* **Rôle technique (Backend)** : Vérifie le statut d'une école partenaire spécifique dans le système national/privé (ex: affecté par l'État, non affecté, statut de la subvention).
* **Fonctionnalité parent (Mobile)** : Utilisé lors du parcours d'inscription pour informer le parent si l'élève est orienté officiellement vers cet établissement et si les tarifs subventionnés s'appliquent.

### 🟢 1.3 Liste des coulisses de l'excellence (`GET /ecoles/coulisseexcellencelist?ecole={codeecole}`)
* **Rôle technique (Backend)** : Récupère un catalogue de vidéos mettant en avant les réussites scolaires, projets créatifs et distinctions des élèves, incluant les liens d'intégration YouTube.
* **Fonctionnalité parent (Mobile)** : Alimente le fil d'actualité vidéo "Coulisses de l'Excellence" (`coulisse_video_feed_screen.dart`). Le parent peut visionner de courtes vidéos YouTube montrant les réussites de l'école ou de ses enfants.

### 🟢 1.4 Liste vidéo (visites guidées, présentations, avis...) (`GET /vie-ecoles/videos?ecole={ecole}&type_video={type_video}`)
* **Rôle technique (Backend)** : Fournit des vidéos promotionnelles ou informatives de l'école (ex: visite virtuelle des locaux, mot d'accueil de la direction, présentations pédagogiques) filtrées côté serveur via `type_video`.
* **Fonctionnalité parent (Mobile)** : Alimente l'écran de découverte multimédia (`visite_guidee_video_feed_screen.dart`). Permet aux parents curieux de visiter virtuellement l'école et de consulter les présentations. *Remarque : Le filtrage est désormais fait côté serveur avec une sécurité de validation côté client.*

### 🟢 1.5 Récupérer les paiements scolarité élève (`GET /vie-ecoles/paiements-scolarite-eleve/{matricule}?ecole={ecole}`)
* **Rôle technique (Backend)** : Interroge la base de données financière de l'école pour extraire l'historique complet des paiements effectués pour un élève (reçus, paiements mobiles, dates, montants).
* **Fonctionnalité parent (Mobile)** : Affiche l'historique des paiements dans l'onglet scolarité (`student_scolarite_screen.dart`). Le parent peut consulter l'historique de chaque versement, le mode de paiement utilisé et télécharger ses reçus officiels directement sur son téléphone.

### 🟢 1.6 Notification de l'état de la scolarité (`GET /vie-ecoles/echeance-notification/{matricule}`)
* **Rôle technique (Backend)** : Génère des alertes financières en comparant l'échéancier obligatoire de l'école avec les paiements réels reçus pour un élève, identifiant tout retard de paiement.
* **Fonctionnalité parent (Mobile)** : Affiche des notifications d'alerte et des badges de rappel sur l'écran d'accueil du parent si une échéance de scolarité est en retard ou arrive bientôt à terme.

### 🟢 1.7 Marquer des messages comme lus (`POST /vie-ecoles/messages/marquer-comme-lu`)
* **Rôle technique (Backend)** : Met à jour le statut des messages reçus par le parent pour une conversation donnée, passant leur état de "non lu" à "lu".
* **Fonctionnalité parent (Mobile)** : Déclenché automatiquement dès que le parent ouvre la discussion avec l'école (`student_messages_screen.dart`), ce qui réinitialise le compteur de notifications de messages non lus sur son tableau de bord.

### 🟡 1.8 Consultation des présences et absences (`GET /vie-ecoles/gestion-presence-eleve/{matricule}?ecole={code_ecole}&date={date}&type={type}`)
* **Rôle technique (Backend)** : Récupère le registre de présence de l'élève pour une journée ou une période sélectionnée (présent, absent justifié/non justifié, retard).
* **Fonctionnalité parent (Mobile)** : Affiche un calendrier de présence interactif (`student_access_control_screen.dart`). *Remarque : Seuls le matricule et l'école sont envoyés pour l'instant. Les paramètres optionnels `date` et `type` manquent.*

### 🟢 1.9 Statistique globale des présences (`GET /vie-ecoles/statistiques-presence-eleve/{matricule}?ecole={code_ecole}`)
* **Rôle technique (Backend)** : Calcule le taux de présence cumulé sur l'année en cours (ex: 95% de présence, 5 jours d'absence non justifiés).
* **Fonctionnalité parent (Mobile)** : Affiche des graphiques de synthèse sur la fiche de l'élève. Permet au parent de suivre la régularité et l'assiduité globale de son enfant tout au long de l'année scolaire.

### 🟢 1.10 Récupération des produits scolaires souscrits (`GET /vie-ecoles/abonnement-services/eleve/{matricule}?ecole={code_ecole}`)
* **Rôle technique (Backend)** : Récupère la liste des services annexes auxquels l'élève est activement abonné pour l'année scolaire courante (ex: Cantine active, Transport scolaire ligne 3).
* **Fonctionnalité parent (Mobile)** : Affiche un récapitulatif des abonnements actifs dans le profil de l'élève. Le parent peut voir immédiatement quels services extra-scolaires sont payés et opérationnels.

### 🟢 1.11 Consultation des activités extra-scolaires (`GET /vie-ecoles/activite-service/{service_uid}/eleve/{matricule}?ecole={ecole}`)
* **Rôle technique (Backend)** : Fournit le détail quotidien d'un service (ex: pour la cantine, le menu du jour consommé; pour le transport, le trajet effectué).
* **Fonctionnalité parent (Mobile)** : Permet de suivre au jour le jour les activités de son enfant (ex : savoir s'il a bien mangé à la cantine ce midi ou s'il est bien monté dans le bus scolaire).

### 🔴 1.12 Consultation des points d'arrêt d'un voyage (`GET /vie-ecoles/service/point-arrets/{id_voyage}?ecole={code}`)
* **Rôle technique (Backend)** : Récupère la liste ordonnée des arrêts de bus prévus pour un trajet de transport scolaire en cours.
* **Fonctionnalité parent (Mobile)** : Intégrable dans un module de suivi de transport en temps réel. Permet au parent de voir où se trouve le bus de son enfant et à quel arrêt il s'est arrêté.

### 🟢 1.13 Interaction de like sur vidéo (`POST /vie-ecoles/interactions/like`)
* **Rôle technique (Backend)** : Enregistre le vote favorable (like) ou défavorable (dislike) d'un parent identifié sur une vidéo de l'école.
* **Fonctionnalité parent (Mobile)** : Gérée via la méthode `InteractionApiService.toggleLike()`. L'interface de flux vidéo (`coulisse_video_feed_screen.dart`) intègre désormais un bouton « J'aime » avec mise à jour instantanée (optimistic UI) et synchronisation automatique/restauration en arrière-plan en cas de perte de connexion ou d'erreur réseau.

### 🟢 1.14 Interaction commenter, noter ou partager (`POST /vie-ecoles/interactions/store`)
* **Rôle technique (Backend)** : Enregistre un nouveau commentaire textuel, une note d'évaluation (1 à 5 étoiles) ou un log de partage d'une vidéo spécifique.
* **Fonctionnalité parent (Mobile)** : Permet au parent d'écrire un commentaire sous une vidéo, de lui attribuer une note ou de la partager avec son réseau.

### 🟢 1.15 Lister les intéractions d'une vidéo (`GET /vie-ecoles/interactions/list?video_id={id}&type={type}`)
* **Rôle technique (Backend)** : Extrait tous les commentaires ou avis postés par l'ensemble des parents pour une vidéo donnée.
* **Fonctionnalité parent (Mobile)** : Affiche la section des commentaires sous le lecteur vidéo dans l'application, créant un espace de discussion communautaire entre parents.

### 🟢 1.16 Supprimer un commentaire (`DELETE /vie-ecoles/interactions/comment/{id_comment}?user_id={idUser}`)
* **Rôle technique (Backend)** : Supprime définitivement de la base de données un commentaire posté par l'utilisateur.
* **Fonctionnalité parent (Mobile)** : Offre au parent la possibilité de retirer un commentaire qu'il a précédemment publié sous une vidéo de l'école.

### 🟢 1.17 Modifier un commentaire (`POST /vie-ecoles/interactions/comment/update/{id_comment}`)
* **Rôle technique (Backend)** : Met à jour le contenu textuel d'un commentaire existant.
* **Fonctionnalité parent (Mobile)** : Permet à un parent d'éditer ou de corriger le texte d'un commentaire qu'il a publié sur une vidéo.

### 🟢 1.18 Réservation de ticket parent (`POST /vie-ecoles/billetterie/participer/{id_evenement}`)
* **Rôle technique (Backend)** : Enregistre une commande de billets pour un événement scolaire (ex: fête de fin d'année, concert) en associant le numéro du parent et les quantités par catégorie de prix (ex: 2 tickets Standard, 1 ticket VIP).
* **Fonctionnalité parent (Mobile)** : Gère le formulaire de réservation dans l'écran de l'événement (`event_detail_screen.dart`). Le parent réserve directement ses places pour assister aux activités scolaires.

### 🟢 1.19 Catégories de tickets disponibles (`GET /vie-ecoles/billetterie/categories/{eventId}`)
* **Rôle technique (Backend)** : Renvoie la liste de toutes les catégories de places définies pour un événement (ex: VIP à 10 000 FCFA, Standard à 2 000 FCFA) avec leurs tarifs respectifs et le stock restant.
* **Fonctionnalité parent (Mobile)** : Affiche le sélecteur de tickets et les prix associés lorsque le parent s'apprête à réserver des places pour un événement.

### 🟢 1.20 Liste des tickets réservés par le parent (`GET /vie-ecoles/billetterie/ticket-commande/{numero_parent}`)
* **Rôle technique (Backend)** : Récupère l'historique complet de toutes les réservations de tickets d'événements effectuées par un numéro de téléphone parent.
* **Fonctionnalité parent (Mobile)** : Alimente l'écran "Mes Tickets" (`my_tickets_screen.dart`). Le parent peut afficher à tout moment ses billets électroniques, générer le PDF ou présenter le **QR Code** à l'entrée de l'école pour validation.

### 🟢 1.21 Annuler un ticket (`GET /vie-ecoles/billetterie/annuler/participation/...`)
* **Rôle technique (Backend)** : Annule une participation enregistrée et libère les places réservées dans le stock global.
* **Fonctionnalité parent (Mobile)** : Intégrée dans `TicketService.cancelTicket()` et rendue accessible sur l'écran des billets (`my_tickets_screen.dart`). Si le billet est encore valide ou non utilisé, le parent peut cliquer sur le bouton « Annuler le ticket », valider la boîte de dialogue de confirmation, et libérer instantanément la réservation auprès du serveur avec actualisation de l'affichage.

---

## 🏫 2. Gestion des Établissements (Section 2)

### 🟢 2.1 Consultation de la liste des établissements (`GET /ecoles/list`)
* **Rôle technique (Backend)** : Recherche et filtre l'annuaire général de tous les établissements partenaires enregistrés sur Pouls (par pays, ville, quartier, mot-clé, type).
* **Fonctionnalité parent (Mobile)** : Gère le moteur de recherche d'écoles (`establishment_screen.dart`). Le parent peut rechercher une école à proximité, consulter sa fiche et vérifier sa compatibilité.

### 🟢 2.2 Profil et détails d'une école (`GET /ecoles/detail-ecole/{ecole}`)
* **Rôle technique (Backend)** : Extrait toutes les informations administratives d'une école (adresse, géolocalisation, photos de la galerie, contacts téléphoniques, descriptifs, mot du fondateur).
* **Fonctionnalité parent (Mobile)** : Affiche la fiche de profil premium d'un établissement (`establishment_detail_screen.dart`). Permet au parent d'explorer l'école, de l'appeler ou de voir son positionnement sur une carte.

### 🟢 2.3 Consultation des frais de scolarité par classe (`GET /ecoles/scolarites/{ecole}?niveau={niveau}`)
* **Rôle technique (Backend)** : Fournit la grille de tarification annuelle complète d'une école pour une classe donnée (frais d'inscription, frais de scolarité de base, fournitures obligatoires).
* **Fonctionnalité parent (Mobile)** : Alimente l'onglet de consultation des tarifs dans la fiche d'établissement (`establishment_detail_screen.dart`). Désormais, le paramètre `niveau` est envoyé en paramètre de requête à l'API lors de l'utilisation des puces de filtrage interactives.

### 🟢 2.4 Liste des niveaux d'une école (`GET /ecoles/niveaux/{ecole}`)
* **Rôle technique (Backend)** : Liste tous les niveaux d'enseignement actifs au sein d'une école (ex: CP1, CP2, 6ème, 3ème, Terminale).
* **Fonctionnalité parent (Mobile)** : Utilisé dans les sélecteurs déroulants pour filtrer la grille des tarifs ou pour sélectionner la classe lors d'une demande d'inscription d'un élève.

### 🟢 2.5 Paramètres généraux de l'école (`GET /vie-ecoles/parametre/ecole?ecole={code}`)
* **Rôle technique (Backend)** : Fournit les règles métiers et configurations techniques d'un établissement (ex: logo, devise locale, modes de paiement en ligne autorisés, activation de la cantine/transport).
* **Fonctionnalité parent (Mobile)** : Configure dynamiquement les options de l'application selon l'école sélectionnée (ex : activer ou désactiver les boutons de paiement mobile en ligne).

### 🟢 2.6 Frais scolaires d'un élève via son UID (`GET /preinscription/scolarite/branche/{uid}?ecole={ecole}`)
* **Rôle technique (Backend)** : Récupère la structure financière détaillée (échéances précises avec dates limites et rubriques obligatoires/facultatives) associée à une branche d'enseignement (ex: Classe de 6ème).
* **Fonctionnalité parent (Mobile)** : Alimente l'étape financière de l'inscription (`inscription_screen.dart`). Le parent peut choisir les options et valider l'échéancier de paiement personnalisé pour son enfant.

---

## 🤝 3. Intégration et Demandes (Section 3)

### 🟢 3.1 Demande d'intégration (`POST /preinscription/demande-integration`)
* **Rôle technique (Backend)** : Crée un dossier de demande de transfert ou d'intégration d'un nouvel élève dans une école partenaire, en joignant les données civiles de la famille et les pièces justificatives numérisées (bulletins, extrait de naissance).
* **Fonctionnalité parent (Mobile)** : Permet aux parents de soumettre un dossier d'admission complet en téléversant les documents de l'élève depuis leur mobile vers l'administration de la nouvelle école.

### 🟡 3.2 Résultat de demande d'intégration (`GET /preinscription/demande-integration/consulte`)
* **Rôle technique (Backend)** : Recherche et suit le statut de traitement d'un dossier de demande d'intégration (en cours, accepté, rejeté avec motif).
* **Fonctionnalité parent (Mobile)** : Fournit un tableau de bord de suivi. *Remarque : Seule la recherche par matricule est fonctionnelle pour l'instant. La recherche par nom/prénoms (Cas B) n'est pas codée.*

### 🟢 3.3 Informations relatives à l'élève (`GET /vie-ecoles/eleve/detail/{matricule}`)
* **Rôle technique (Backend)** : Recherche et extrait la fiche d'identité officielle d'un élève à partir de son numéro matricule unique (nom, prénoms, classe actuelle, école, photo).
* **Fonctionnalité parent (Mobile)** : Gère l'ajout d'un nouvel enfant sur l'application parent (`add_child_screen.dart`). Lorsque le parent saisit le matricule de son enfant, cette API valide instantanément son identité et affiche sa photo pour confirmer le lien familial.

---

## 📢 4. Communication et Actualités (Section 4)

### 🟢 4.1 Consultation des actualités (Blog) (`GET /ecoles/blogs-list`)
* **Rôle technique (Backend)** : Extrait les articles de blog, communiqués de presse ou actualités publiés par la direction de l'école ou le groupe d'enseignement.
* **Fonctionnalité parent (Mobile)** : Alimente le flux d'actualités général (`all_blogs_screen.dart`, `blog_detail_screen.dart`). Le parent reste informé de la vie quotidienne de l'école, des projets pédagogiques et des articles de conseils de l'école.

### 🟢 4.2 Événements scolaires (`GET /ecoles/evenements-list`)
* **Rôle technique (Backend)** : Fournit le calendrier de tous les événements programmés au sein de l'établissement (réunions parents-profs, fêtes scolaires, compétitions sportives, journées thématiques).
* **Fonctionnalité parent (Mobile)** : Alimente l'agenda scolaire (`all_events_screen.dart`). Permet aux parents de noter les dates clés et d'accéder directement à l'achat de tickets en ligne si l'événement est payant.

---

## 🏆 5. Interactions Parents & Parrainage (Section 5)

### 🟢 5.1 Recommandation d'écoles (`POST /ecoles/nonpartenaires`)
* **Rôle technique (Backend)** : Enregistre les coordonnées d'un établissement d'enseignement non-partenaire suggéré par un parent pour que les équipes de Pouls puissent le démarcher.
* **Fonctionnalité parent (Mobile)** : Gère le formulaire de recommandation (`parent_suggestion_screen.dart`). Le parent peut inviter la direction de son ancienne école ou de l'école de son quartier à rejoindre la plateforme.

### 🟢 5.2 Parrainage et codes promotionnels (`GET /vie-ecoles/info-parrainage/{numero}`)
* **Rôle technique (Backend)** : Récupère les données d'affiliation d'un parent (son code promo unique, la liste des filleuls inscrits grâce à lui et le montant cumulé de ses commissions).
* **Fonctionnalité parent (Mobile)** : Affiche l'espace "Parrainage" dans le profil (`profile_screen.dart`). Le parent peut partager son code de parrainage via WhatsApp ou SMS et suivre ses gains/commissions reversés par la plateforme Libouli.

### 🟢 5.3 Soumission d'un avis d'école (`POST /vie-ecoles/avis/{numero}`)
* **Rôle technique (Backend)** : Soumet une note chiffrée (1 à 5) et un commentaire rédigé par un parent pour évaluer globalement un établissement d'enseignement.
* **Fonctionnalité parent (Mobile)** : Gère la boîte de dialogue "Laisser un Avis". Permet au parent de partager son retour d'expérience constructif avec la direction et la communauté.

### 🟢 5.4 Liste des avis d'une école (`GET ecoles/avis/{ecole}?per_page={per_page}`)
* **Rôle technique (Backend)** : Fournit tous les avis publics déposés par les familles pour une école, ainsi que sa note moyenne globale.
* **Fonctionnalité parent (Mobile)** : Affiche les témoignages des parents d'élèves sur le profil de l'école (`establishment_detail_screen.dart`). Aide les futurs parents à se faire un avis éclairé.

---

## 📝 6. Inscriptions Élèves Complexes (Section 6)

### 🟢 6.1 Inscription et réinscription d'un élève (`POST /vie-ecoles/inscription-eleve/{matricule}?ecole={ecole}`)
* **Rôle technique (Backend)** : Enregistre définitivement la demande d'inscription ou de réinscription d'un élève avec son package financier configuré (choix des échéances scolaires obligatoires et services facultatifs).
* **Fonctionnalité parent (Mobile)** : Soumet le dossier complet à la fin du tunnel d'inscription (`inscription_screen.dart`). Confirme officiellement la place de l'élève pour la rentrée prochaine auprès du secrétariat.

### 🔴 6.2 Inscription : Paiement en ligne (`GET /vie-ecoles/inscription-eleve/paiement-en-ligne/{matricule}`)
* **Rôle technique (Backend)** : Génère un lien de paiement direct et sécurisé pour régler instantanément les frais d'inscription administratifs de l'élève.
* **Fonctionnalité parent (Mobile)** : Déclenche la redirection vers la passerelle de paiement mobile (Orange Money, Wave, etc.) pour finaliser immédiatement la création du dossier d'inscription.

### 🟢 6.3 Vérification réservation élève (`GET vie-ecoles/reservation/eleve/{matricule}`)
* **Rôle technique (Backend)** : Vérifie dans la base si le parent a déjà effectué un versement de réservation pour bloquer une place pour cet élève dans sa future classe.
* **Fonctionnalité parent (Mobile)** : Affiche à l'écran si la place de l'élève est pré-réservée et le montant déjà versé à déduire des futurs frais de scolarité globaux.

### 🔴 6.4 Réservation de place (paiement en ligne) (`POST /vie-ecoles/reservation/payer/{matricule}`)
* **Rôle technique (Backend)** : Initialise une transaction spécifique de réservation de classe par paiement mobile (PEL) pour sécuriser une place avant l'inscription finale.
* **Fonctionnalité parent (Mobile)** : Permet aux parents de verser un acompte rapide de réservation en ligne pour garantir la place de leur enfant pendant les périodes de forte affluence.

### 🟢 6.5 Services extrascolaires école (`GET /preinscription/services?ecole={code}`)
* **Rôle technique (Backend)** : Récupère la liste de tous les services payants additionnels offerts par l'école (Cantine scolaire, Lignes de transport, Garderie, Assurances).
* **Fonctionnalité parent (Mobile)** : Affiche les options complémentaires au cours du tunnel d'inscription. Le parent choisit de cocher ou non l'abonnement à la cantine ou au bus pour l'année.

### 🟢 6.6 Échéancier d'un service (`GET /preinscription/service/echeances/{uid}?ecole={code}`)
* **Rôle technique (Backend)** : Fournit le plan de facturation détaillé associé à un service extra-scolaire (ex : mensualités ou paiement trimestriel pour la cantine).
* **Fonctionnalité parent (Mobile)** : Présente au parent les détails financiers précis du service sélectionné (montants et dates limites) pour éviter toute mauvaise surprise.

### 🟢 6.7 Zones de transport scolaires (`GET /preinscription/service/zones?ecole={code}`)
* **Rôle technique (Backend)** : Récupère les différentes zones de desserte géographiques couvertes par les bus scolaires de l'établissement avec la tarification spécifique de chaque zone.
* **Fonctionnalité parent (Mobile)** : Affiche un sélecteur de zones (ex : Zone A, Zone B, Ligne Est) lors de la souscription au service de transport pour appliquer le bon tarif de trajet.

### 🔴 6.8 Points d'arrêt d'une zone (`GET /preinscription/service/{points_arret}/{id}?ecole={code}`)
* **Rôle technique (Backend)** : Extrait tous les points d'arrêt ou points de rendez-vous physiques configurés pour les bus dans une zone sélectionnée.
* **Fonctionnalité parent (Mobile)** : Permet au parent de sélectionner le point d'arrêt précis le plus proche de son domicile pour la prise en charge et le dépôt quotidien de son enfant.

### 🟢 6.8 (bis) Emploi du temps élève (`GET /vie-ecoles/emploi-du-temps-eleve/{matricule}?ecole={ecole}`)
* **Rôle technique (Backend)** : Récupère l'emploi du temps hebdomadaire complet de l'élève (matières, horaires, salles de classe, noms des enseignants).
* **Fonctionnalité parent (Mobile)** : Alimente l'agenda quotidien de l'élève (`student_timetable_screen.dart`). Le parent sait en permanence quel cours suit son enfant à chaque heure de la journée.

### 🟢 6.9 Contrôle d'accès (Journal des passages) (`GET /vie-ecoles/controle-acces/{matricule}?ecole={ecole}`)
* **Rôle technique (Backend)** : Liste les logs de pointage physique de l'élève enregistrés par les bornes RFID, tourniquets ou QR codes aux entrées et sorties de l'école.
* **Fonctionnalité parent (Mobile)** : Alimente le module de sécurité (`student_access_control_screen.dart`). Reste la source d'information principale pour rassurer le parent sur l'heure exacte à laquelle son enfant a franchi les grilles de l'établissement (matin et soir).

### 🟢 6.10 État de scolarité de l'élève (`GET /vie-ecoles/scolarite-eleve/{matricule}?ecole={ecole}`)
* **Rôle technique (Backend)** : Calcule l'état financier en temps réel de la scolarité de l'élève (total dû, total payé, reste à payer, liste de toutes les échéances passées et futures).
* **Fonctionnalité parent (Mobile)** : Alimente l'onglet financier de l'élève (`student_scolarite_screen.dart`). Affiche un indicateur de progression des paiements et la liste complète des échéances scolaires à solder.

### 🟢 6.11 Paiement de la scolarité en ligne (`POST /vie-ecoles/scolarite/paiement-en-ligne/{matricule}?montant={montant}`)
* **Rôle technique (Backend)** : Initialise une transaction financière sécurisée pour régler une partie ou la totalité de la scolarité en cours, renvoyant l'URL de la passerelle de paiement en ligne (PEL).
* **Fonctionnalité parent (Mobile)** : Intègre le module de paiement mobile (`PaiementService`). Le parent saisit le montant à régler, choisit son opérateur mobile money et effectue la validation de la transaction directement depuis son smartphone.

### 🟢 6.12 Fournitures scolaires par classe (`GET /vie-ecoles/fournitures-scolaires/{matricule}`)
* **Rôle technique (Backend)** : Récupère la liste officielle des fournitures, livres et manuels scolaires requis pour la classe de l'élève, établie par ses enseignants.
* **Fonctionnalité parent (Mobile)** : Alimente l'écran de consultation des fournitures (`shop_screen.dart`). Permet au parent de consulter la liste des cahiers et manuels demandés et de les ajouter en un clic à son panier d'achat.

---

## 🛒 7. Libouli: achat et livraison (Section 7)

### 🟢 7.1 Consultation de la liste des produits (`GET /produits/list`)
* **Rôle technique (Backend)** : Recherche et filtre le catalogue complet des produits e-commerce disponibles (manuels, trousses, cahiers, cartables, uniformes) avec gestion des stocks et de la pagination.
* **Fonctionnalité parent (Mobile)** : Gère le catalogue marchand principal de l'application (`shop_screen.dart`). Le parent navigue, recherche par mot-clé et sélectionne ses produits.

### 🟢 7.2 Détail d'un produit (`GET /vie-ecoles/produit/detail/{produit_uid}`)
* **Rôle technique (Backend)** : Récupère la fiche descriptive enrichie d'un article (plusieurs visuels, caractéristiques techniques, tailles et pointures en stock, avis).
* **Fonctionnalité parent (Mobile)** : Alimente la fiche produit détaillée (`product_detail_screen.dart`). Le parent y choisit la quantité et la taille/couleur avant de l'ajouter au panier de commande.

### 🟢 7.3 Achat ou commande d'articles (`POST /vie-ecoles/commander`)
* **Rôle technique (Backend)** : Valide le panier d'achat, enregistre les coordonnées de livraison (adresse postale ou option de retrait à l'école) et crée la commande commerciale.
* **Fonctionnalité parent (Mobile)** : Gère le processus de finalisation d'achat (`cart_screen.dart`). Permet au parent de passer sa commande de fournitures scolaires pour la rentrée en toute simplicité.

### 🟢 7.4 Communes de livraison et tarifs (`GET /vie-ecoles/liste-lieux-livraison`)
* **Rôle technique (Backend)** : Récupère la liste des communes desservies par le service logistique de livraison à domicile avec le coût associé à chaque zone de livraison.
* **Fonctionnalité parent (Mobile)** : Affiche les options de frais de livraison dynamique dans le résumé du panier (`cart_screen.dart`), calculant automatiquement le prix total (articles + frais de livraison).

### 🟢 7.5 Détail et traitement de la commande (`GET /vie-ecoles/suivi-commandes/{numero}`)
* **Rôle technique (Backend)** : Fournit le statut d'acheminement et de préparation de chaque commande passée par le parent (ex : payé, en cours de préparation, expédié, livré).
* **Fonctionnalité parent (Mobile)** : Alimente l'écran de suivi des achats (`orders_screen.dart`). Le parent suit l'avancement de son colis en temps réel pour savoir quand il sera livré.

---

## 💬 8. Interaction école & parent : Messagerie (Section 8)

### 🟢 8.1 Notifications groupées (Messages de l'école) (`GET /vie-ecoles/liste-messages-groupe/{matricule}`)
* **Rôle technique (Backend)** : Extrait toutes les annonces générales diffusées par la direction de l'école à toute une classe ou à tout l'établissement (ex: réunion de rentrée, rappel de fermeture, alertes météo).
* **Fonctionnalité parent (Mobile)** : Alimente la boîte de réception des circulaires scolaires de l'enfant (`messages_screen.dart`). Le parent reçoit et consulte toutes les lettres d'information officielles de l'administration.

### 🟢 8.2 Marquer une notification comme lue (`PUT /vie-ecoles/message-groupe/update-statut/{matricule}/{id_message}?statut=1`)
* **Rôle technique (Backend)** : Met à jour le statut d'une annonce spécifique reçue pour indiquer qu'elle a été ouverte par le parent.
* **Fonctionnalité parent (Mobile)** : Dès que le parent clique pour lire une circulaire ou annonce, l'application met à jour le statut en arrière-plan, enlevant l'indicateur "nouveau" et décrémentant le compteur global d'alertes.

### 🟢 8.3 Liste des discussions de messagerie (`GET /vie-ecoles/messages/liste/{numero_tel}`)
* **Rôle technique (Backend)** : Liste toutes les conversations actives pour un numéro de parent (une conversation correspondant à un enfant).
* **Fonctionnalité parent (Mobile)** : Permet de basculer d'une discussion d'un enfant à l'autre au sein de l'onglet messagerie pour simplifier les échanges.

### 🟢 8.4 Messages d'une conversation élève (`GET /messages/{numero_parent}/eleve/{matricule}`)
* **Rôle technique (Backend)** : Charge le fil de discussion personnalisé et sécurisé concernant un élève en particulier (messages échangés entre les enseignants et le parent).
* **Fonctionnalité parent (Mobile)** : Affiche le tchat de discussion bilatéral dans l'écran de messagerie (`student_messages_screen.dart`). Le parent y voit l'historique complet des messages privés échangés avec les enseignants de sa classe.

### 🟢 8.5 Envoyer un message (multimédia) (`POST /vie-ecoles/messages/envoyer/{numero}`)
* **Rôle technique (Backend)** : Envoie un message dans la discussion en acceptant différents types de contenus en format Multipart (texte pur, image du travail de l'élève, note vocale explicative ou pièce jointe PDF).
* **Fonctionnalité parent (Mobile)** : Permet au parent de dialogue en direct avec l'enseignant, de poser une question par note vocale ou d'envoyer la photo d'un devoir ou d'un certificat d'absence directement depuis le clavier de tchat.

---

## 🔑 9. Inscription & Authentification (Section 9)

### 🟢 9.1 Création de compte parent (`POST /espace-parent/inscription`)
* **Rôle technique (Backend)** : Enregistre le profil d'un nouveau parent dans la base centrale de Pouls (nom, prénoms, numéro de téléphone, mot de passe sécurisé, question secrète de récupération de compte).
* **Fonctionnalité parent (Mobile)** : Gère l'écran de création de compte (`signup_screen.dart`). Permet à une nouvelle famille de s'inscrire pour commencer à l'utiliser.

### 🟢 9.2 Connexion simple parent (`POST /vie-ecoles/auth/parent/connexion?numero={phone}`)
* **Rôle technique (Backend)** : Vérifie le numéro de téléphone saisi et authentifie instantanément le parent s'il possède déjà un compte, lui fournissant ses clés de session et ses données utilisateur.
* **Fonctionnalité parent (Mobile)** : Gère l'accès sécurisé à l'application (`login_screen.dart`), connectant le parent à son espace personnel de manière simple et sécurisée.
