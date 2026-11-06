# Rapport — Échec de résolution du `schoolId` (notes/bulletins introuvables pour certains enfants)

**Date** : 2026-11-06
**Statut** : ✅ Résolu — 3 bugs identifiés et corrigés (voir §2), confirmé par test réel sur l'enfant `23610800W`.
**Symptôme initial** : pour l'enfant `23610800W` (GROUPE SCOLAIRE GNAKAN YOPOUGON GESCO), l'écran de détail élève affichait correctement les informations de base (profil, présence, échéances, via l'API `api2.vie-ecoles.com` — toujours en production et activement utilisée, pas un système remplacé), mais **les notes/bulletins ne se chargeaient jamais** (API `api-pedagogie.pouls-scolaire.net`, bloc "consultation"). Pour un autre enfant (`123456M`, COLLEGE PRIVÉ GAIN HIGHT SCHOOL), tout fonctionnait.

---

## 1. Contexte technique

L'application interroge deux systèmes distincts pour un même élève, **tous deux en production et activement utilisés en parallèle** — "vie-ecoles" n'est pas un système déprécié ou en cours de remplacement, c'est le système qui gère aujourd'hui profil/présence/échéances/messages, pendant que "Pouls pédagogie" est le système dédié aux notes/bulletins :

| Système | Hôte | Données | Identifiant établissement attendu |
|---|---|---|---|
| vie-ecoles (actif) | `api2.vie-ecoles.com` | Profil élève, présence, échéances, messages | code texte (ex: `gnakan`, `gainhs`), stocké sous `paramEcole` côté app |
| Pouls pédagogie (actif) | `api-pedagogie.pouls-scolaire.net` | Années, classes, bulletins, notes | `schoolId` — UUID opaque, propre à ce système |

Le `schoolId` n'est **pas connu directement** : il doit être déduit du code vie-ecoles (`paramEcole`, ex. `gnakan`) via une table de correspondance. Cette correspondance est reconstruite en mémoire par `ConsultationApiService.getEtablissements()` (lib/services/consultation_api_service.dart:144), qui combine deux appels :

1. `GET https://api-pedagogie.pouls-scolaire.net/api/v1/consultation/etablissements`
   → renvoie pour chaque établissement : `schoolId`, `code` (code interne Pouls, sans rapport avec vie-ecoles), `nom`, `archive`, `reference`, `indiceVieEcoles` (indice masqué, non exploitable).
2. `GET https://api-pedagogie.pouls-scolaire.net/api/v1/integrations/vie-ecoles/admin/schools`
   → renvoie, par `schoolId`, le `vieEcolesCode` réel (c'est la valeur stockée ensuite dans `EtablissementConsultation.paramEcole`).

La fonction `ConsultationApiService.findSchoolIdByCode(code, {expectedName})` (lib/services/consultation_api_service.dart:233) filtre cette liste combinée pour retrouver le `schoolId` correspondant à un code vie-ecoles donné, avec une vérification de nom en cas de candidats multiples.

Le point d'entrée applicatif principal est `_doHealMissingSchoolId()` dans lib/screens/child_list_screen.dart:9223 : si `_consultationSchoolId` est `null` à l'ouverture de la fiche élève (schoolId jamais résolu/persisté), l'app retente une résolution à la volée via `findSchoolIdByCode`. Si elle échoue, `schoolId` reste `null` et **tous** les écrans qui en dépendent (notes, bulletins, devoirs, pièces jointes, PDF de bulletin...) restent bloqués — avec des comportements d'échec non uniformes dans le code (`throw Exception(...)` dans certains écrans, `return` silencieux dans d'autres, cf. §6).

---

## 2. Bugs identifiés et déjà corrigés

### Bug 1 — Comparaison contre le mauvais champ (`code` au lieu de `paramEcole`)

**Avant correction** (lib/services/consultation_api_service.dart:236) :
```dart
final candidates = etablissements.where((e) => e.code == code).toList();
```

`e.code` est un identifiant **interne à l'API de consultation Pouls** (ex. `"002016"`, `"EP0318"`, `"033162"`), sans rapport avec le code vie-ecoles attendu (ex. `"gnakan"`, `"gainhs"`). Le vrai équivalent du code vie-ecoles est `e.paramEcole`, résolu séparément via l'API `integrations/vie-ecoles/admin/schools` et documenté dans le modèle (`lib/models/etablissement_consultation.dart:28-36`) comme *"la seule source valide"*.

Cette confusion entre deux champs tous deux nommés "code" est un bug déjà connu en partie ailleurs dans le code : `_healLegacyParamEcoleIfNeeded()` (lib/screens/child_list_screen.dart:9159) existe spécifiquement pour corriger un `Child.paramEcole` qui aurait été enregistré à tort avec `e.code` au lieu de `e.paramEcole` — mais ce correctif n'avait jamais été répercuté dans `findSchoolIdByCode`, qui committait exactement la même erreur.

**Conséquence** : pour tout établissement où `code` ≠ `paramEcole` (cas fréquent, cf. tableau en §1), la résolution échouait **systématiquement et silencieusement** (`Candidats trouvés pour ce code: 0`), bloquant notes/bulletins pour l'enfant concerné en permanence (aucune nouvelle tentative ne pouvait réussir, le bug étant dans la logique elle-même, pas dans les données).

**Correctif appliqué** :
```dart
final candidates = etablissements.where((e) => e.paramEcole == code).toList();
```

### Bug 2 — Sensibilité à la casse non gérée sur la comparaison de code

Après le correctif du Bug 1, le même élève (`23610800W`, code vie-ecoles `gnakan`) échouait encore avec `Candidats trouvés pour ce code: 0`. Investigation sur les logs de production (liste complète des 103 établissements) :

```
72. Groupe Scolaire Gnakan             (paramecole: GNAKAN)
73. groupe scolaire gnakan             (paramecole: GNAKAN)
74. Groupe Scolaire Gnakan Maternelle  (paramecole: GNAKAN)
```

`paramEcole` est renseigné en **majuscules** (`"GNAKAN"`) côté API, alors que le code vie-ecoles transmis par l'app est en **minuscules** (`"gnakan"`, tel que stocké depuis `api2.vie-ecoles.com`). La comparaison `e.paramEcole == code` était une égalité stricte, sans normalisation — alors que la comparaison de *nom* (`expectedName`), elle, était déjà normalisée (`trim().toLowerCase()`) via `_normalizeName`. L'asymétrie entre les deux comparaisons (nom normalisé, code non normalisé) était la cause directe.

**Correctif appliqué** :
```dart
final normalizedCode = code.trim().toLowerCase();
final candidates = etablissements
    .where((e) => (e.paramEcole ?? '').trim().toLowerCase() == normalizedCode)
    .toList();
```

### Bug 3 — Ambiguïté quand plusieurs établissements partagent le même code vie-ecoles (résolu)

Même avec les deux correctifs ci-dessus, le cas `GNAKAN` échouait encore, pour une raison différente :

Trois établissements distincts partagent le même `paramEcole = GNAKAN` :

| Nom | schoolId | archive |
|---|---|---|
| Groupe Scolaire Gnakan | `f67f4121-8505-41ee-a20c-02cb78238833` | `true` |
| groupe scolaire gnakan | `19bf7f31-9772-4d53-9984-46a8c47cdc87` | `false` |
| Groupe Scolaire Gnakan Maternelle | `9156ce67-1f02-4e02-8500-adbe2b0315df` | `false` |

`findSchoolIdByCode` exige, quand plusieurs candidats partagent un code, une **correspondance exacte de nom** (normalisée casse/espaces) avec `expectedName` — ici `"GROUPE SCOLAIRE GNAKAN YOPOUGON GESCO"` (nom tel que connu côté `api2.vie-ecoles.com`). Aucun des 3 noms ci-dessus ne correspond exactement (différence de formulation entre les deux systèmes : suffixe "YOPOUGON GESCO" absent côté Pouls). Résultat : `⚠️ Aucun candidat ne correspond au nom attendu` → `null` → notes/bulletins bloqués, malgré les deux corrections précédentes.

**La correspondance exacte de nom seule n'était pas la bonne approche** : vie-ecoles et Pouls pédagogie sont deux systèmes remplis par des personnes différentes, avec des conventions de nommage différentes (suffixes, casse, orthographe) — une égalité stricte de texte échoue à chaque petite différence de saisie. Elle reste néanmoins utile comme premier filtre rapide et sans risque (elle résout déjà la majorité des cas), donc conservée telle quelle ; ce qui manquait était un **repli** pour quand elle échoue avec plusieurs candidats restants.

**Correctif appliqué** — cascade de désambiguïsation dans `findSchoolIdByCode` (nouveau paramètre optionnel `matricule`), voir `_disambiguateCandidates` (lib/services/consultation_api_service.dart) :

1. **Vérification de l'inscription réelle de l'élève**, en priorité, sur **tous** les candidats y compris les archivés (appel `getAnnees` puis `getClasses(schoolId, matricule, anneeRef)`). Celui qui renvoie une classe réelle pour ce matricule est retenu.
   - ⚠️ Piège rencontré en testant : une première version excluait les établissements `archive: true` *avant* ce test, en partant de l'hypothèse qu'un établissement archivé ne pouvait plus avoir d'élève actif. Sur `23610800W`, les 2 candidats non-archivés ont tous les deux renvoyé `404 "Cet élève n'appartient pas à cet établissement"` — l'élève était en réalité rattaché à l'établissement **archivé**. `archive` est une métadonnée Pouls, pas une preuve que plus aucun élève n'y est historiquement rattaché. La vérification d'inscription doit donc porter sur l'ensemble des candidats, archivés inclus, et prévaloir sur le statut d'archivage.
2. Seulement si ce test est inconcluant (pas de `matricule` fourni, élève introuvable sur aucun candidat, ou trouvé sur plusieurs à la fois) : repli sur l'exclusion des `archive: true` ; si un seul établissement actif reste, le retenir par défaut.
3. Si l'ambiguïté persiste malgré tout : ne pas deviner, retourner `null` comme avant, avec un log détaillé.

Le paramètre `matricule` est renseigné à l'appel depuis `_doHealMissingSchoolId()` (lib/screens/child_list_screen.dart:9238-9242), où le matricule de l'élève est déjà connu. L'appel depuis `add_child_screen.dart` (au moment de l'ajout d'un enfant, matricule pas encore saisi) reste inchangé, sans ce paramètre — best-effort comme avant.

**Confirmé en conditions réelles** sur l'enfant `23610800W` : résolution réussie après ce correctif.

### Ce n'est pas un cas isolé — d'autres établissements ambigus restent à nettoyer côté backend

En parcourant la liste des 103 établissements renvoyés (log partiellement tronqué au-delà du 86ᵉ), **au moins 16 groupes de code partagés** ont été identifiés, suivant presque toujours le même schéma : un même groupe scolaire déclaré plusieurs fois pour ses différentes branches (maternelle / primaire / collège général / technique / professionnel), parfois avec en plus un doublon archivé de l'enregistrement principal.

| Code vie-ecoles (`paramEcole`) | Établissements concernés | Archivés |
|---|---|---|
| GNAKAN | Gnakan / Gnakan (doublon) / Gnakan Maternelle | 1/3 |
| gainhs | COLLEGE PRIVE BKB / COLLEGE PRIVÉ GAIN HIGHT SCHOOL / GAIN GROUPE SARL TECHNIQUE / LYCEE SUCCESS EXCELLENCE | 1/4 |
| kobenan | Bondoukou / Bondoukou Professionnel / Bondoukou Technique | 3/3 (tous archivés) |
| cmtd | Diaby Moderne / Diaby Moderne Technique / Diaby Professionnel | 3/3 |
| marshall | Marshall Yopougon Professionnel / Marshall Yopougon Technique | 1/2 |
| cesap1 | Cesa Plateau / Cesa du Plateau Professionnel | 2/2 |
| annour | An-Nour d'Abobo / École Islamique An-Nour | 2/2 |
| hinneh/HINNEH | Hînneh Biabou / Hinneh Maternelle / Hinneh Primaire | 1/3 |
| EPPD | École Primaire Privée Diaby ×2 (doublon exact) | 0/2 |
| NAYEBA | Nayeba / EPV Nayeba ×2 (+ autres vus hors de la portion tronquée) | 3/3 |
| cesak | Cesa Koumassi BTS / ENS SEC GEN / ENS SEC TECH | 3/3 |
| GERMINAL | Germinal / Germinal Professionnel / Germinal Technique | 3/3 |
| IGON | Igon / Igon Maternelle / Igon Primaire | 1/3 |
| stetherese/STETHERESE | Sainte Thérèse Koumassi / Sainte Thérèse Technique | 1/2 |
| CPPG/cppg | Philippe Germark / Philippe Germark Technique | 1/2 |
| CPFG | Boyanaho Bangolo / Fohoundi Garango (noms sans rapport apparent, à vérifier côté données) | 0/2 |

**Observation importante** : dans plusieurs groupes (`kobenan`, `cmtd`, `annour`, `cesap1`, `NAYEBA`, `cesak`, `GERMINAL`), **tous** les candidats sont `archive: true`. Une stratégie qui se contenterait d'exclure les établissements archivés ne suffirait donc pas systématiquement — et retomberait à zéro candidat dans ces cas.

---

## 4. Pistes de solution

### Option A — Cascade de désambiguïsation (✅ implémentée, voir Bug 3 en §2)

Décrite et implémentée en §2 (Bug 3) : vérification de l'inscription réelle de l'élève (archivés inclus) en priorité, repli sur l'exclusion des archivés si inconcluant, sinon `null` sans deviner.

*Avantage* : signal fort basé sur la vraie donnée d'inscription de l'élève plutôt qu'un matching textuel approximatif ; a résolu le cas `GNAKAN` dès le premier test réel.
*Limite connue* : si l'élève n'a tout simplement aucune donnée de scolarité enregistrée côté Pouls pédagogie pour cette école (aucun des candidats ne renvoie de classe pour son matricule), la fonction retourne toujours `null` — ce n'est alors plus un bug app mais un vrai manque de données côté backend pour cet élève, à vérifier au cas par cas.

### Option B — Nettoyage des données côté backend (toujours recommandé pour les 15+ autres groupes ambigus du tableau ci-dessus)

Le cœur du problème est une donnée ambiguë : plusieurs établissements distincts partagent un même code d'intégration vie-ecoles (`paramEcole`). Une solution durable consiste à :
- Supprimer ou fusionner les doublons exacts (ex. `EPPD` ×2, `Groupe Scolaire Gnakan` archivé vs actif).
- Attribuer un code vie-ecoles distinct par branche quand c'est pertinent (ex. un sous-code pour Gnakan Maternelle), ou au contraire acter qu'un seul `schoolId` doit faire autorité pour tout le groupe scolaire si les branches ne sont pas réellement distinctes pour l'élève final.

*Avantage* : règle le problème à la source, pour toutes les apps consommatrices (pas seulement Pouls-Mobile), de façon pérenne.
*Inconvénient* : hors du périmètre de ce projet mobile, nécessite une action côté équipe backend/données, délai non maîtrisé par l'app.

### Option C — Ne rien changer côté logique, traiter au cas par cas

Garder le comportement actuel (retour `null`, pas de résolution) et whitelister manuellement en dur les `schoolId` pour les établissements problématiques déjà identifiés.

*Avantage* : zéro risque de mauvais rattachement (aucune heuristique).
*Inconvénient* : ne passe pas à l'échelle (16+ groupes déjà identifiés sur une liste tronquée à 86/103 établissements), nécessite une maintenance manuelle à chaque nouvel établissement ambigu, et ne retrouve l'élève que de façon figée tant qu'on ne met pas sa fiche à jour.

---

## 5. Recommandation

**Option A est implémentée et déployée côté app** (§2, Bug 3) et a résolu le cas `GNAKAN` en conditions réelles. **Option B reste recommandée en complément** : signaler à l'équipe backend les 15+ autres groupes de code partagés identifiés en §2 (tableau), pour nettoyer les doublons à la source — la cascade de désambiguïsation ne couvrira pas 100 % des cas (ex. élève sans aucune donnée Pouls pédagogie enregistrée), ces cas résiduels resteront visibles en logs pour investigation manuelle plutôt que de risquer un mauvais rattachement d'élève à un établissement.

---

## 6. Annexes — effets de bord déjà notés (hors scope de ce rapport mais à surveiller)

Le traitement du cas `schoolId == null` n'est **pas homogène** dans lib/screens/child_list_screen.dart :
- Certains écrans lèvent une `Exception('Établissement introuvable dans l'API de consultation')`, remontée en message d'erreur visible à l'utilisateur (notes, bulletins, devoirs, pièces jointes, PDF de bulletin).
- D'autres (ex. stats de notes) se contentent d'un `return` silencieux qui coupe juste l'état de chargement, sans aucun feedback utilisateur — l'écran reste alors juste visuellement "vide" ou bloqué en chargement, ce qui peut compliquer le diagnostic terrain d'un futur cas similaire si les logs ne sont pas consultés.

Il pourrait être utile d'harmoniser ce comportement (toujours lever une exception propre, affichée à l'utilisateur) indépendamment du correctif de résolution du `schoolId` lui-même.

---

## 7. Fichiers concernés

| Fichier | Élément |
|---|---|
| lib/services/consultation_api_service.dart | `findSchoolIdByCode` (corrigé), `getEtablissements`, `_normalizeName` |
| lib/models/etablissement_consultation.dart | Modèle `EtablissementConsultation` (`code` vs `paramEcole` vs `indiceVieEcoles`) |
| lib/models/code_dren_ecole.dart | Modèle `CodeDrenEcole` (code vie-ecoles issu de la recherche DREN) |
| lib/screens/add_child_screen.dart | Appel initial à `findSchoolIdByCode` lors de l'ajout d'un enfant |
| lib/screens/child_list_screen.dart | `_doHealMissingSchoolId`, `_resolveConsultationSchoolId`, `_healLegacyParamEcoleIfNeeded`, tous les écrans consommant `schoolId` (notes, bulletins, devoirs...) |
