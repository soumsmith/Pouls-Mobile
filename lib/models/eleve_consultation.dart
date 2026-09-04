/// Élève renvoyé par GET /consultation/etablissements/{schoolId}/annees/{annee}/eleves
///
/// `classeRef` est une référence opaque — jamais interprétée ni composée.
/// Un même matricule peut apparaître deux fois dans la liste si l'élève est
/// inscrit dans deux classes la même année : ne jamais en élire une d'office.
class EleveConsultation {
  final String matricule;
  final String nom;
  final String prenoms;
  final String classeRef;
  final String classeLibelle;

  EleveConsultation({
    required this.matricule,
    required this.nom,
    required this.prenoms,
    required this.classeRef,
    required this.classeLibelle,
  });

  String get fullName => '$nom $prenoms';

  factory EleveConsultation.fromJson(Map<String, dynamic> json) {
    return EleveConsultation(
      matricule: json['matricule'] as String? ?? '',
      nom: json['nom'] as String? ?? '',
      prenoms: json['prenoms'] as String? ?? '',
      classeRef: json['classeRef'] as String? ?? '',
      classeLibelle: json['classeLibelle'] as String? ?? '',
    );
  }
}
