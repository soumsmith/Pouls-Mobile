/// Classe renvoyée par GET /consultation/etablissements/{schoolId}/eleves/{matricule}/classes
///
/// `classeRef` est une référence opaque — jamais interprétée ni composée.
/// `niveau` manque sur les années H: (archive), l'archive ne le porte pas à
/// ce niveau de détail.
class ClasseConsultation {
  final String classeRef;
  final String libelle;
  final String? niveau;
  final int? effectif;

  ClasseConsultation({
    required this.classeRef,
    required this.libelle,
    this.niveau,
    this.effectif,
  });

  factory ClasseConsultation.fromJson(Map<String, dynamic> json) {
    return ClasseConsultation(
      classeRef: json['classeRef'] as String? ?? '',
      libelle: json['libelle'] as String? ?? '',
      niveau: json['niveau'] as String?,
      effectif: json['effectif'] as int?,
    );
  }
}
