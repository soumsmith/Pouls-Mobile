import 'etablissement_consultation.dart';
import 'annee_consultation.dart';
import 'classe_consultation.dart';

/// Résultat de `ConsultationApiService.getEcolesEtClassesPourMatricule` :
/// un établissement où un matricule donné est réellement inscrit (vérifié
/// par appel direct, pas par matching de nom), son année courante, et ses
/// classes dans cet établissement pour cette année (une ou deux — cursus
/// franco-arabe, doc API-CONSULTATION-MOBILE §4.6 bis).
class EcoleAvecClasses {
  final EtablissementConsultation ecole;
  final AnneeConsultation annee;
  final List<ClasseConsultation> classes;

  EcoleAvecClasses({
    required this.ecole,
    required this.annee,
    required this.classes,
  });
}
