import '../models/user.dart';
import '../models/code_dren_ecole.dart';
import 'app_log_service.dart';

/// Service de journalisation des ajouts d'enfants (délègue à [AppLogService]).
class ChildLogService {
  /// Envoie le log d'un ajout d'enfant réussi.
  static Future<void> logChildAdded({
    required User currentUser,
    required String matricule,
    required String nom,
    required String prenoms,
    required String grade,
    required CodeDrenEcole ecole,
    String? resolvedSchoolId,
  }) async {
    AppLogService.logChildAdded(
      currentUser: currentUser,
      matricule: matricule,
      nom: nom,
      prenoms: prenoms,
      grade: grade,
      ecole: ecole,
      resolvedSchoolId: resolvedSchoolId,
    );
  }

  /// Envoie le log d'un échec ou doublon d'ajout d'enfant.
  static Future<void> logChildAddFailed({
    required User currentUser,
    required String matricule,
    String? nom,
    String? prenoms,
    String? grade,
    required CodeDrenEcole ecole,
    required String errorMessage,
    String status = 'error',
  }) async {
    AppLogService.logChildAddFailed(
      currentUser: currentUser,
      matricule: matricule,
      nom: nom,
      prenoms: prenoms,
      grade: grade,
      ecole: ecole,
      errorMessage: errorMessage,
      status: status,
    );
  }
}
