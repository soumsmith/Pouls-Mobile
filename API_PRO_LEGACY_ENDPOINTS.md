# Endpoints encore sur `api-pro.pouls-scolaire.net`

Suite à l'extension de l'API de consultation (`api-pedagogie.pouls-scolaire.net`,
`ConsultationApiService`) aux endpoints §4.7-4.9 (classes d'un élève, bulletins
d'une année, bulletin PDF), tous les appels historiquement listés ici pour les
notes/bulletins ont été migrés. Ce qui suit est ce qui reste **volontairement**
sur `api-pro.pouls-scolaire.net` (`AppConfig.POULS_SCOLAIRE_API_URL`), avec la
raison de chaque exception — ce n'est plus du code mort, juste hors périmètre
de l'API de consultation.

## `lib/services/pouls_scolaire_api_service.dart`

### `getAllEcoles()`
```
GET https://api-pro.pouls-scolaire.net/api/connecte/ecole
```
Appelée depuis les 3 bottom sheets d'**inscription/intégration**
(`inscription_bottom_sheet.dart`, `integration_bottom_sheet.dart`,
`integration_request_bottom_sheet.dart`) — un domaine différent de la
consultation de notes/bulletins. Elles ont besoin de `ecole.paramecole` et
`ecole.ecoleid` (int) pour construire les requêtes vers les API
inscription/intégration/Vie-École ; `EtablissementConsultation` (nouvelle API)
n'expose que `schoolId`/`code`/`nom`/`archive`, ce qui casserait ces flux.

### `getAnneeScolaireOuverte()` / `getStudentClassInfo()` — **actifs**
```
GET https://api-pro.pouls-scolaire.net/api/annee/list-ouverte-to-ecole-dto?ecole=...
GET https://api-pro.pouls-scolaire.net/api/classe-eleve/get-ecole-by-classe/{matricule}?annee=&classe=
```
Utilisés par `child_list_screen.dart` (`_loadStudentClassInfo`) pour
alimenter `_studentClassInfo`, dont `identifiantVieEcole` met à jour
`SchoolService`. Le nouvel endpoint équivalent (§4.7,
`GET .../eleves/{matricule}/classes`) ne renvoie que `classeRef`/`libelle`/
`niveau` — pas `identifiantVieEcole`. Faute d'équivalent, ce flux reste sur
`api-pro` (décision explicite, pas un oubli).

### `getElevesByEcoleAndAnnee()` / `findEleveByMatricule()` — **actifs**
```
GET https://api-pro.pouls-scolaire.net/api/inscriptions/list-eleve-classe/{idEcole}/{idAnnee}
```
Utilisés uniquement par `home_screen.dart` (`_updatePhotosInBackground`) pour
compléter la photo des enfants qui n'en ont pas. `EleveConsultation` (nouvelle
API, §4.4) n'a pas de champ photo. Faute d'équivalent, ce flux reste sur
`api-pro`.

## Cas à part — `AppConfig.API_BASE_URL` (pas actif aujourd'hui, dev local)

`registerNotificationToken()` et `unregisterNotificationToken()` (dans
`pouls_scolaire_api_service.dart`) utilisent `AppConfig.API_BASE_URL`, sans
rapport avec la consultation de notes — configuré en dev local
(`http://10.0.2.2:8889/api`) aujourd'hui.

## Migré vers l'API de consultation (`api-pedagogie.pouls-scolaire.net`)

| Ancienne plateforme | Nouvelle |
|---|---|
| `/connecte/ecole` | `GET /consultation/etablissements` |
| `/annee/list-to-ecole`, `/annee/list-opened-or-closed-to-ecole` | `GET .../annees` |
| `/periodes/list-by-annee` | `GET .../annees/{annee}/periodes` |
| `/inscriptions/list-eleve-classe` | `GET .../annees/{annee}/eleves` |
| `/notes/list-matricule-notes-moyennes` | `GET .../eleves/{matricule}/bulletin` |
| `/bulletin/get-bulletins-eleve-annee` | `GET .../eleves/{matricule}/bulletins` |
| `/imprimer-bulletin-list/spider-bulletin-matricule-mobile/...` | `GET .../eleves/{matricule}/bulletin.pdf` |
| *(aucun équivalent avant)* | `GET .../eleves/{matricule}/decision-fin-annee` |

Le bulletin PDF exige désormais un jeton Bearer : `ConsultationApiService`
télécharge les octets authentifiés et l'app les enregistre localement avant
de les afficher/partager (impossible de repasser une URL brute comme avant).

Non migré, faute d'appelant : l'endpoint classes d'un élève (§4.7,
`GET .../eleves/{matricule}/classes`) n'a pas été implémenté côté
`ConsultationApiService` — son seul appelant potentiel (`getStudentClassInfo`)
reste sur `api-pro` pour `identifiantVieEcole` (voir ci-dessus).
