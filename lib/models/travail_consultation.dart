/// Élément renvoyé par GET .../eleves/{matricule}/travail — fusionne le
/// cahier de textes et les contenus pédagogiques, du plus récent au plus
/// ancien, déjà filtré côté serveur (contenu publié, date de visibilité
/// passée) : remplace les appels séparés à /devoirs et /contenus, qui
/// obligeaient l'application à fusionner elle-même, inventer un ordre et une
/// borne (doc §2, "route à préférer").
///
/// Les champs pour `source: CAHIER_DE_TEXTES` reprennent ceux de l'ancien
/// GET .../devoirs, avec `aRendreLe` à la place de `prochaineSeance` (doc) —
/// une indication de la séance suivante, jamais une échéance garantie.
///
/// Les champs pour `source: CONTENU_PEDAGOGIQUE` (hors `source` et
/// `piecesJointes`, seuls confirmés par la doc) sont une best-effort : à
/// ajuster dès qu'un exemple réel de réponse est disponible pour cette
/// source.
class TravailConsultation {
  static const sourceCahierDeTextes = 'CAHIER_DE_TEXTES';
  static const sourceContenuPedagogique = 'CONTENU_PEDAGOGIQUE';

  final String source;
  final String matiereCode;
  final String matiere;
  final String classeRef;
  final String classe;
  final String? donneLe;
  final String? seance;
  final String professeur;
  final String? consigne;
  final String? aRendreLe;
  final String? titre;
  final String? description;
  final List<PieceJointe> piecesJointes;

  bool get estCahierDeTextes => source == sourceCahierDeTextes;
  bool get estContenuPedagogique => source == sourceContenuPedagogique;

  TravailConsultation({
    required this.source,
    required this.matiereCode,
    required this.matiere,
    required this.classeRef,
    required this.classe,
    this.donneLe,
    this.seance,
    required this.professeur,
    this.consigne,
    this.aRendreLe,
    this.titre,
    this.description,
    this.piecesJointes = const [],
  });

  factory TravailConsultation.fromJson(Map<String, dynamic> json) {
    return TravailConsultation(
      source: json['source'] as String? ?? '',
      matiereCode: json['matiereCode'] as String? ?? '',
      matiere: json['matiere'] as String? ?? '',
      classeRef: json['classeRef'] as String? ?? '',
      classe: json['classe'] as String? ?? '',
      donneLe: json['donneLe'] as String?,
      seance: json['seance'] as String?,
      professeur: json['professeur'] as String? ?? '',
      consigne: json['consigne'] as String?,
      aRendreLe: json['aRendreLe'] as String?,
      titre: json['titre'] as String?,
      description: json['description'] as String?,
      piecesJointes: (json['piecesJointes'] as List?)
              ?.map((e) => PieceJointe.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

/// Pièce jointe d'un contenu pédagogique. `id` est l'`attachmentId` à passer
/// à GET .../contenus/fichiers/{attachmentId} (doc recette 05/10/2026, §2)
/// pour en récupérer les octets — `fileKey` est une clé de stockage interne,
/// jamais exploitable côté client. `fileUrl` reste `null` pour les fichiers
/// téléversés (c'est le cas de `fileKey`) et n'est renseigné que pour les
/// pièces ajoutées par adresse.
class PieceJointe {
  final String? id;
  final String? fileKey;
  final String? fileUrl;
  final String? fileName;
  final String? contentType;

  PieceJointe({this.id, this.fileKey, this.fileUrl, this.fileName, this.contentType});

  factory PieceJointe.fromJson(Map<String, dynamic> json) {
    return PieceJointe(
      id: json['id'] as String?,
      fileKey: json['fileKey'] as String?,
      fileUrl: json['fileUrl'] as String?,
      fileName: json['fileName'] as String?,
      contentType: json['contentType'] as String?,
    );
  }
}
