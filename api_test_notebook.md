# Cahier de Tests API - Pouls Mobile

Ce document sert de **cahier de test** pour toutes les API intégrées dans l'application Pouls Mobile. Il permet de suivre l'état de validation de chaque endpoint.

## Légende Statut des Tests
- ⚪ **Non Testé** : Le test n'a pas encore débuté.
- 🟡 **En cours** : Test en cours de validation ou de debug.
- 🟢 **Validé** : L'API fonctionne correctement (Success + Gestion des erreurs validée).
- 🔴 **Échec** : Un bug ou problème a été rencontré (voir colonne Problème).

---

### 🔐 Authentification & Session (`auth_service.dart`)
| Fonction | Endpoint API (Base + Route) | Méthode | Statut | Problème / Remarque |
|----------|---------------------------|---------|:---:|---------------------|
| `login` / `authenticate` | `/auth/login` (ou équivalent) | POST | ⚪ | |
| `register` | `/auth/register` (ou équivalent) | POST | ⚪ | |
| `verifyOTP` | `/auth/verify-otp` (ou équivalent)| POST | ⚪ | |

---

### 👨‍👩‍👧 Utilisateurs & Enfants (`remote_api_service.dart`, `student_detail_service.dart`)
| Fonction | Endpoint API (Base + Route) | Méthode | Statut | Problème / Remarque |
|----------|---------------------------|---------|:---:|---------------------|
| `fetchChildrenForParent` | `/api/parents/{parentId}/children` | GET | ⚪ | |
| `fetchStudentDetails` | `/eleves/{matricule}` | GET | ⚪ | |
| `getScolariteStudent` | `/scolarite/eleve/{matricule}` | GET | ⚪ | |

---

### 🏫 École & Établissement (`school_service.dart`, `ecole_eleve_service.dart`, `niveau_service.dart`)
| Fonction | Endpoint API (Base + Route) | Méthode | Statut | Problème / Remarque |
|----------|---------------------------|---------|:---:|---------------------|
| `getEcoles` | `/ecoles` | GET | ⚪ | |
| `getDetailsEcole` | `/ecoles/{ecoleCode}` | GET | ⚪ | |
| `getNiveaux` | `/ecoles/niveaux/{ecoleCode}` | GET | ⚪ | |
| `recommanderEcole` | `/ecoles/nonpartenaires` | POST | ⚪ | (`recommendation_service.dart`) |

---

### 📚 Suivi Pédagogique & Scolarité
| Fonction | Endpoint API (Base + Route) | Méthode | Statut | Problème / Remarque |
|----------|---------------------------|---------|:---:|---------------------|
| `fetchNotes` | *(Endpoint des notes)* | GET | ⚪ | (`notes_api_service.dart`) |
| `fetchBulletins` | *(Endpoint des bulletins)* | GET | ⚪ | (`bulletin_api_service.dart`) |
| `fetchTimetable` | *(Endpoint Emploi du temps)* | GET | ⚪ | (`student_timetable_service.dart`) |
| `fetchPresence` | *(Endpoint Présence/Absence)* | GET | ⚪ | (`gestion_presence_eleve_service.dart`) |
| `fetchStatistiquesPresence`| *(Endpoint Stats Présence)* | GET | ⚪ | (`statistiques_presence_service.dart`) |

---

### 💰 Paiements & Finances (`scolarite_service.dart`, `paiement_historique_service.dart`)
| Fonction | Endpoint API (Base + Route) | Méthode | Statut | Problème / Remarque |
|----------|---------------------------|---------|:---:|---------------------|
| `getEcheancier` | *(Endpoint Échéancier)* | GET | ⚪ | (`echeance_service.dart`) |
| `getPaiementHistorique`| *(Endpoint Historique paiement)* | GET | ⚪ | |
| `initiatePaiement` | *(Endpoint Initialisation paiement)*| POST | ⚪ | |
| `verifierPaiement` | *(Endpoint Vérification statut)* | GET | ⚪ | |

---

### 🛒 Boutique & Services Annexes (`order_service.dart`, `cart_service.dart`, `school_supply_service.dart`)
| Fonction | Endpoint API (Base + Route) | Méthode | Statut | Problème / Remarque |
|----------|---------------------------|---------|:---:|---------------------|
| `getFournitures` | `/fournitures-scolaires/{matricule}` | GET | ⚪ | |
| `getCategories` | `/categories` | GET | ⚪ | (`category_api_service.dart`) |
| `getProduits` | *(Endpoint Liste produits)* | GET | ⚪ | (`produit_service.dart`) |
| `getCart` / `addToCart`| *(Endpoints Panier)* | GET/POST| ⚪ | |
| `getCommandes` | *(Endpoints Historique Commandes)* | GET | ⚪ | |
| `getLieuxLivraison` | `/liste-lieux-livraison` | GET | ⚪ | (`lieu_livraison_service.dart`) |
| `getAbonnementExtra` | `/vie-ecoles/service/abonnement/eleve/{matricule}?ecole={code}` | GET | ⚪ | (`extra_scolaire_service.dart`) |
| `getActivitesExtra` | `/vie-ecoles/service/activite/{uid}/eleve/{matricule}?ecole={code}`| GET | ⚪ | |

---

### 🎟️ Billetterie & Événements (`ticket_service.dart`, `event_service.dart`)
| Fonction | Endpoint API (Base + Route) | Méthode | Statut | Problème / Remarque |
|----------|---------------------------|---------|:---:|---------------------|
| `getEvents` | *(Endpoint Événements)* | GET | ⚪ | |
| `rateEvent` | *(Endpoint Évaluation événement)* | POST | ⚪ | (`event_rating_service.dart`) |
| `getTickets` | *(Endpoint Tickets)* | GET | ⚪ | |
| `reserverTicket` | *(Endpoint Achat/Réservation Ticket)*| POST | ⚪ | |

---

### 📝 Communications & Média (`message_service.dart`, `video_service.dart`)
| Fonction | Endpoint API (Base + Route) | Méthode | Statut | Problème / Remarque |
|----------|---------------------------|---------|:---:|---------------------|
| `getMessages` | *(Endpoint Messages)* | GET | ⚪ | |
| `sendGroupMessage` | *(Endpoint Message de Groupe)* | POST | ⚪ | (`group_message_service.dart`) |
| `getVideos` | *(Endpoint base)* `?type_video={type}` | GET | ⚪ | (`video_service.dart`) |
| `getVisitesGuidees` | *(Endpoint Visites guidées)* | GET | ⚪ | (`visite_guidee_service.dart`) |
| `getCoulisses` | *(Endpoint Coulisses excellence)* | GET | ⚪ | (`coulisse_excellence_service.dart`) |
| `getBlogs` / `getNews`| *(Endpoint Actualités)* | GET | ⚪ | (`blog_service.dart`) |
| `getGalerie` | `/galerie/{ecoleCode}` (Approximatif) | GET | ⚪ | (`gallery_service.dart`) |

---

### ⚙️ Services Transverses & Autres
| Fonction | Endpoint API (Base + Route) | Méthode | Statut | Problème / Remarque |
|----------|---------------------------|---------|:---:|---------------------|
| `sendSuggestion` | *(Endpoint Suggestions)* | POST | ⚪ | (`parent_suggestion_service.dart`) |
| `sendAvis` | *(Endpoint Avis)* | POST | ⚪ | (`avis_service.dart`) |
| `getTestimonials` | *(Endpoint Témoignages)* | GET | ⚪ | (`testimonial_service.dart`) |
| `infoParrainage` | `/vie-ecoles/info-parrainage/{phone}`| GET | ⚪ | (`parrainage_service.dart`) |
| `soumettreParrainage` | `/vie-ecoles/parrainer` | POST | ⚪ | |
| `demandeIntegration` | *(Endpoint Demande intégration)* | POST | ⚪ | (`integration_service.dart`) |
| `suiviIntegration` | *(Endpoint Statut Intégration)* | GET | ⚪ | (`integration_request_service.dart`) |
| `getNotifications` | *(Endpoint Notifications push)* | GET | ⚪ | (`notification_service.dart`) |

---

*Note: Ce tableau regroupe les appels identifiés dans les fichiers du dossier `lib/services/`. Mettez à jour les statuts au fur et à mesure de l'exécution des tests sur les endpoints de développement ou de production.*
