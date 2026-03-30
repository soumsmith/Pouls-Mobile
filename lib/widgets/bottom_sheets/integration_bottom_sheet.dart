import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:parents_responsable/config/app_colors.dart';
import 'package:parents_responsable/config/app_dimensions.dart';
import 'package:parents_responsable/models/ecole.dart';
import 'package:parents_responsable/services/integration_service.dart';
import 'package:parents_responsable/widgets/custom_file_field.dart';
import 'package:parents_responsable/widgets/custom_loader.dart';
import 'package:parents_responsable/widgets/custom_text_field.dart';

// ── Date Input Formatter ───────────────────────────────────────────────────────
class _DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.length < oldValue.text.length) {
      String text = newValue.text.replaceAll(RegExp(r'[^0-9/]'), '');
      if (oldValue.selection.baseOffset > 0 &&
          oldValue.text.length > newValue.text.length) {
        int deletedIndex = newValue.selection.baseOffset;
        if (deletedIndex > 0 && deletedIndex <= text.length) {
          if (deletedIndex > 0 && text[deletedIndex - 1] == '/') {
            text =
                text.substring(0, deletedIndex - 1) +
                (deletedIndex < text.length
                    ? text.substring(deletedIndex)
                    : '');
          }
        }
      }
      return TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    }

    String text = newValue.text.replaceAll(RegExp(r'[^0-9/]'), '');
    if (newValue.text.contains('-') && !newValue.text.contains('/')) {
      text = text.replaceAll('-', '/');
    }
    if (text.length > 10) text = text.substring(0, 10);

    if (text.length >= 2 && !text.contains('/')) {
      text = text.substring(0, 2) + '/' + text.substring(2);
    }
    if (text.length >= 5 && text.indexOf('/', text.indexOf('/') + 1) == -1) {
      int firstSlash = text.indexOf('/');
      if (firstSlash != -1) {
        String day = text.substring(0, firstSlash);
        String monthYear = text.substring(firstSlash + 1);
        if (monthYear.length >= 2) {
          text =
              day +
              '/' +
              monthYear.substring(0, 2) +
              '/' +
              monthYear.substring(2);
        }
      }
    }

    List<String> parts = text.split('/');
    if (parts.length >= 3) {
      if (parts[0].length == 2 && int.tryParse(parts[0]) != null) {
        if (int.parse(parts[0]) > 31) parts[0] = '31';
      }
      if (parts[1].length == 2 && int.tryParse(parts[1]) != null) {
        if (int.parse(parts[1]) > 12) parts[1] = '12';
      }
      text = parts.join('/');
    }

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  showIntegrationBottomSheet — Fonction utilitaire d'affichage
// ═══════════════════════════════════════════════════════════════════════════════

/// Affiche le bottom sheet d'intégration pour un établissement donné.
void showIntegrationBottomSheet({
  required BuildContext context,
  Ecole? ecole,
  GlobalKey<ScaffoldMessengerState>? scaffoldMessengerKey,
  void Function(String demandeUid)? onSuccess,
  void Function(String error)? onError,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => Container(
      constraints: BoxConstraints(
        minHeight: 100,
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : AppColors.screenCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Handle bar ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.screenDivider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.person_add_alt_1_rounded,
                        color: Color(0xFF3B82F6),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Intégrer',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? Colors.white
                                  : AppColors.screenTextPrimary,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const Text(
                            'Nous rejoindre',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.screenTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF2A2A2A)
                              : AppColors.screenSurface,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.close,
                          size: 16,
                          color: isDark
                              ? Colors.white54
                              : AppColors.screenTextSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(color: AppColors.screenDivider, height: 1),
              ],
            ),
          ),

          // ── Form content ────────────────────────────────────────────────
          // MODIFIÉ : Padding simple, plus de SingleChildScrollView ici
          Flexible(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              child: IntegrationFormContent(
                ecole: ecole,
                scaffoldMessengerKey: scaffoldMessengerKey,
                onSuccess: onSuccess,
                onError: onError,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
//  IntegrationBottomSheet — Widget stateful externalisé
// ═══════════════════════════════════════════════════════════════════════════════

class IntegrationBottomSheet extends StatelessWidget {
  final Ecole? ecole;
  final GlobalKey<ScaffoldMessengerState>? scaffoldMessengerKey;
  final void Function(String demandeUid)? onSuccess;
  final void Function(String error)? onError;

  const IntegrationBottomSheet({
    super.key,
    this.ecole,
    this.scaffoldMessengerKey,
    this.onSuccess,
    this.onError,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      constraints: BoxConstraints(
        minHeight: 100,
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : AppColors.screenCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Handle bar ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.screenDivider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.person_add_alt_1_rounded,
                        color: Color(0xFF3B82F6),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Intégrer',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? Colors.white
                                  : AppColors.screenTextPrimary,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const Text(
                            'Nous rejoindre',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.screenTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF2A2A2A)
                              : AppColors.screenSurface,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.close,
                          size: 16,
                          color: isDark
                              ? Colors.white54
                              : AppColors.screenTextSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(color: AppColors.screenDivider, height: 1),
              ],
            ),
          ),

          // ── Form content ────────────────────────────────────────────────
          // MODIFIÉ : Padding simple, plus de SingleChildScrollView ici
          Flexible(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              child: IntegrationFormContent(
                ecole: ecole,
                scaffoldMessengerKey: scaffoldMessengerKey,
                onSuccess: onSuccess,
                onError: onError,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  IntegrationFormContent — Contenu du formulaire (logique + UI)
// ═══════════════════════════════════════════════════════════════════════════════

class IntegrationFormContent extends StatefulWidget {
  final Ecole? ecole;
  final GlobalKey<ScaffoldMessengerState>? scaffoldMessengerKey;
  final void Function(String demandeUid)? onSuccess;
  final void Function(String error)? onError;

  const IntegrationFormContent({
    super.key,
    this.ecole,
    this.scaffoldMessengerKey,
    this.onSuccess,
    this.onError,
  });

  @override
  State<IntegrationFormContent> createState() => _IntegrationFormContentState();
}

class _IntegrationFormContentState extends State<IntegrationFormContent> {
  static const _actionColor = Color(0xFF3B82F6);

  // ── Wizard state ────────────────────────────────────────────────────────
  int _currentStep = 0;
  final int _totalSteps = 5;

  // ── Step titles ───────────────────────────────────────────────────────────
  final List<String> _stepTitles = [
    'Informations de l\'élève',
    'Contacts et Parents',
    'Scolarité antérieure',
    'Documents et finalisation',
    'Récapitulatif',
  ];

  // ── Step icons ─────────────────────────────────────────────────────────────
  final List<IconData> _stepIcons = [
    Icons.person_rounded,
    Icons.phone_rounded,
    Icons.school_rounded,
    Icons.description_rounded,
    Icons.summarize_rounded,
  ];

  // ── Champs de formulaire ─────────────────────────────────────────────────
  final _studentNameController = TextEditingController();
  final _studentFirstNameController = TextEditingController();
  final _matriculeController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _lieuNaissanceController = TextEditingController();
  final _nationaliteController = TextEditingController();
  final _adresseController = TextEditingController();
  final _contact1Controller = TextEditingController();
  final _contact2Controller = TextEditingController();
  final _nomPereController = TextEditingController();
  final _nomMereController = TextEditingController();
  final _nomTuteurController = TextEditingController();
  final _niveauAntController = TextEditingController();
  final _ecoleAntController = TextEditingController();
  final _moyenneAntController = TextEditingController();
  final _rangAntController = TextEditingController();
  final _decisionAntController = TextEditingController();
  final _motifController = TextEditingController();
  final _filiereController = TextEditingController();

  // ── Sélecteurs ───────────────────────────────────────────────────────────
  String _selectedSexe = 'M';
  String _selectedStatutAff = 'Affecté';

  // ── Fichiers ─────────────────────────────────────────────────────────────
  String? _bulletinFile;
  String? _certificatVaccinationFile;
  String? _certificatScolariteFile;
  String? _extraitNaissanceFile;
  String? _cniParentFile;

  // ── États d'erreur ────────────────────────────────────────────────────────
  bool _studentNameError = false;
  bool _studentFirstNameError = false;
  bool _matriculeError = false;
  bool _birthDateError = false;
  bool _adresseError = false;
  bool _contact1Error = false;
  bool _nomPereError = false;
  bool _nomMereError = false;

  @override
  void initState() {
    super.initState();
    _studentNameController.addListener(() {
      if (_studentNameController.text.isNotEmpty && _studentNameError) {
        setState(() => _studentNameError = false);
      }
    });
    _studentFirstNameController.addListener(() {
      if (_studentFirstNameController.text.isNotEmpty &&
          _studentFirstNameError) {
        setState(() => _studentFirstNameError = false);
      }
    });
    _birthDateController.addListener(() {
      if (_birthDateController.text.isNotEmpty && _birthDateError) {
        setState(() => _birthDateError = false);
      }
    });
    _contact1Controller.addListener(() {
      if (_contact1Controller.text.isNotEmpty && _contact1Error) {
        setState(() => _contact1Error = false);
      }
    });
  }

  @override
  void dispose() {
    _studentNameController.dispose();
    _studentFirstNameController.dispose();
    _matriculeController.dispose();
    _birthDateController.dispose();
    _lieuNaissanceController.dispose();
    _nationaliteController.dispose();
    _adresseController.dispose();
    _contact1Controller.dispose();
    _contact2Controller.dispose();
    _nomPereController.dispose();
    _nomMereController.dispose();
    _nomTuteurController.dispose();
    _niveauAntController.dispose();
    _ecoleAntController.dispose();
    _moyenneAntController.dispose();
    _rangAntController.dispose();
    _decisionAntController.dispose();
    _motifController.dispose();
    _filiereController.dispose();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  String _convertDateFormat(String inputDate) {
    if (inputDate.isEmpty) return '';
    final cleaned = inputDate.replaceAll(' ', '');
    final regex = RegExp(r'^(\d{2})/(\d{2})/(\d{4})$');
    if (!regex.hasMatch(cleaned)) return inputDate;
    final m = regex.firstMatch(cleaned)!;
    return '${m.group(3)}-${m.group(2)}-${m.group(1)}';
  }

  void _showSnack(String message, {bool isError = false}) {
    final messenger =
        widget.scaffoldMessengerKey?.currentState ??
        ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red[400] : const Color(0xFFF59E0B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ── Navigation methods ───────────────────────────────────────────────────
  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      if (_validateCurrentStep()) {
        setState(() => _currentStep++);
      }
    } else {
      _submit();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        if (_studentNameController.text.isEmpty ||
            _studentFirstNameController.text.isEmpty ||
            _matriculeController.text.isEmpty ||
            _birthDateController.text.isEmpty ||
            _adresseController.text.isEmpty) {
          _showSnack('Veuillez remplir tous les champs obligatoires');
          return false;
        }
        final dateRegex = RegExp(r'^\d{2}/\d{2}/\d{4}$');
        if (!dateRegex.hasMatch(_birthDateController.text)) {
          _showSnack('Format de date invalide. Utilisez JJ/MM/AAAA');
          return false;
        }
        return true;

      case 1:
        if (_contact1Controller.text.isEmpty ||
            _nomPereController.text.isEmpty ||
            _nomMereController.text.isEmpty) {
          _showSnack('Veuillez remplir tous les champs obligatoires');
          return false;
        }
        return true;

      case 2:
        return true;

      case 3:
        return true;

      case 4:
        return true;

      default:
        return true;
    }
  }

  // ── Soumission ────────────────────────────────────────────────────────────
  Future<void> _submit() async {
    setState(() {
      _studentNameError = false;
      _studentFirstNameError = false;
      _matriculeError = false;
      _birthDateError = false;
      _adresseError = false;
      _contact1Error = false;
      _nomPereError = false;
      _nomMereError = false;
    });

    bool hasError = false;
    if (_studentNameController.text.isEmpty) {
      setState(() => _studentNameError = true);
      hasError = true;
    }
    if (_studentFirstNameController.text.isEmpty) {
      setState(() => _studentFirstNameError = true);
      hasError = true;
    }
    if (_matriculeController.text.isEmpty) {
      setState(() => _matriculeError = true);
      hasError = true;
    }
    if (_birthDateController.text.isEmpty) {
      setState(() => _birthDateError = true);
      hasError = true;
    }
    if (_adresseController.text.isEmpty) {
      setState(() => _adresseError = true);
      hasError = true;
    }
    if (_contact1Controller.text.isEmpty) {
      setState(() => _contact1Error = true);
      hasError = true;
    }
    if (_nomPereController.text.isEmpty) {
      setState(() => _nomPereError = true);
      hasError = true;
    }
    if (_nomMereController.text.isEmpty) {
      setState(() => _nomMereError = true);
      hasError = true;
    }

    if (hasError) {
      _showSnack('Veuillez remplir tous les champs obligatoires');
      return;
    }

    final dateRegex = RegExp(r'^\d{2}/\d{2}/\d{4}$');
    if (!dateRegex.hasMatch(_birthDateController.text)) {
      setState(() => _birthDateError = true);
      _showSnack('Format de date invalide. Utilisez JJ/MM/AAAA');
      return;
    }

    final requestData = <String, dynamic>{
      'nom': _studentNameController.text,
      'prenoms': _studentFirstNameController.text,
      'matricule': _matriculeController.text,
      'sexe': _selectedSexe,
      'date_naissance': _convertDateFormat(_birthDateController.text),
      'lieu_naissance': _lieuNaissanceController.text,
      'nationalite': _nationaliteController.text.isNotEmpty
          ? _nationaliteController.text
          : 'Ivoirienne',
      'adresse': _adresseController.text,
      'contact_1': _contact1Controller.text,
      'contact_2': _contact2Controller.text,
      'nom_pere': _nomPereController.text.isNotEmpty
          ? _nomPereController.text
          : null,
      'nom_mere': _nomMereController.text.isNotEmpty
          ? _nomMereController.text
          : null,
      'nom_tuteur': _nomTuteurController.text,
      'niveau_ant': _niveauAntController.text,
      'ecole_ant': _ecoleAntController.text,
      'moyenne_ant': _moyenneAntController.text,
      'rang_ant': _rangAntController.text.isNotEmpty
          ? int.tryParse(_rangAntController.text)
          : '',
      'decision_ant': _decisionAntController.text,
      'bulletin': _bulletinFile ?? '',
      'certificat_vaccination': _certificatVaccinationFile ?? '',
      'certificat_scolarite': _certificatScolariteFile ?? '',
      'extrait_naissance': _extraitNaissanceFile ?? '',
      'cni_parent': _cniParentFile ?? '',
      'motif': _motifController.text.isNotEmpty
          ? _motifController.text
          : 'Nouvelle inscription',
      'statut_aff': _selectedStatutAff,
      'filiere': _filiereController.text.isNotEmpty
          ? _filiereController.text
          : 'primaire',
    };

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      builder: (_) => CustomLoader(
        message: 'Envoi de la demande...',
        loaderColor: Colors.red,
        size: 80.0,
        showBackground: true,
        backgroundColor: Colors.white.withOpacity(0.9),
      ),
    );

    try {
      final result = await IntegrationService.submitIntegrationRequest(
        widget.ecole?.parametreCode ?? '',
        requestData,
      );
      Navigator.of(context).pop();

      if (result['success'] == true) {
        Navigator.of(context).pop();
        await Future.delayed(const Duration(milliseconds: 300));

        final demandeUid = result['data']?['demande_uid'] as String? ?? '';

        widget.onSuccess?.call(demandeUid);

        final messenger =
            widget.scaffoldMessengerKey?.currentState ??
            ScaffoldMessenger.of(context);
        messenger.showSnackBar(
          SnackBar(
            content: const Text('Demande d\'intégration envoyée avec succès!'),
            backgroundColor: Colors.green[500],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );

        if (demandeUid.isNotEmpty && context.mounted) {
          _showSuccessDialog(demandeUid);
        }
      } else {
        final errMsg = result['error'] ?? 'Erreur lors de l\'envoi';
        widget.onError?.call(errMsg);
        _showSnack(errMsg, isError: true);
      }
    } catch (e) {
      Navigator.of(context).pop();
      Navigator.of(context).pop();
      await Future.delayed(const Duration(milliseconds: 300));
      final errMsg = e.toString();
      widget.onError?.call(errMsg);
      _showSnack('Erreur: $errMsg', isError: true);
    }
  }

  // ── Dialog succès ─────────────────────────────────────────────────────────
  void _showSuccessDialog(String demandeUid) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF34D399), Color(0xFF10B981)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 36,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Demande envoyée !',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1A2E),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Votre demande d\'intégration a été soumise avec succès et est en cours de traitement.',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF8A8A9A),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FF),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFEEEFF5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: AppColors.screenOrange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.tag_rounded,
                            color: AppColors.screenOrange,
                            size: 15,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Numéro de suivi',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF8A8A9A),
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            demandeUid,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.screenOrange,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: demandeUid));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Numéro copié !'),
                              ),
                            );
                          },
                          child: const Icon(
                            Icons.copy_rounded,
                            size: 16,
                            color: AppColors.screenOrange,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.screenOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'OK, j\'ai compris',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  Build — MODIFIÉ : progress + navigation fixes, seul le step scrolle
  // ═══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      // mainAxisSize: MainAxisSize.min retiré → on veut occuper tout l'espace
      // disponible pour que Flexible + SingleChildScrollView fonctionnent
      children: [
        // ── Progress indicator (FIXE) ───────────────────────────────────────
        _buildProgressIndicator(),
        const SizedBox(height: 20),

        // ── Contenu de l'étape (SCROLLABLE) ────────────────────────────────
        Flexible(
          child: SingleChildScrollView(
            child: _buildCurrentStep(),
          ),
        ),

        const SizedBox(height: 16),

        // ── Navigation buttons (FIXE) ───────────────────────────────────────
        _buildNavigationButtons(),
        const SizedBox(height: 20),
      ],
    );
  }

  // ── Progress indicator ─────────────────────────────────────────────────────
  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.screenCard,
        borderRadius: BorderRadius.circular(
          AppDimensions.getMediumCardBorderRadius(context),
        ),
        boxShadow: AppDimensions.getLightShadow(context),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(_totalSteps, (index) {
              final isCompleted = index < _currentStep;
              final isCurrent = index == _currentStep;

              return Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? AppColors.screenOrange
                            : isCurrent
                                ? _actionColor
                                : AppColors.screenDivider,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        isCompleted
                            ? Icons.check_rounded
                            : _stepIcons[index],
                        color: isCompleted || isCurrent
                            ? Colors.white
                            : AppColors.screenTextSecondary,
                        size: 16,
                      ),
                    ),
                    if (index < _totalSteps - 1)
                      Expanded(
                        child: Container(
                          height: 2,
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          color: index < _currentStep
                              ? AppColors.screenOrange
                              : AppColors.screenDivider,
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          Text(
            'Étape ${_currentStep + 1} sur $_totalSteps: ${_stepTitles[_currentStep]}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.screenTextSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ── Current step content ───────────────────────────────────────────────────
  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildStep1();
      case 1:
        return _buildStep2();
      case 2:
        return _buildStep3();
      case 3:
        return _buildStep4();
      case 4:
        return _buildStep5();
      default:
        return Container();
    }
  }

  // ── Navigation buttons ─────────────────────────────────────────────────────
  Widget _buildNavigationButtons() {
    return Row(
      children: [
        if (_currentStep > 0)
          Expanded(
            child: SizedBox(
              height: 50,
              child: OutlinedButton(
                onPressed: _previousStep,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.screenDivider),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      AppDimensions.getButtonBorderRadius(context),
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.arrow_back_rounded,
                      size: 18,
                      color: AppColors.screenTextSecondary,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Précédent',
                      style: TextStyle(
                        color: AppColors.screenTextSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        if (_currentStep > 0) const SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.screenOrange,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    AppDimensions.getButtonBorderRadius(context),
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _currentStep == _totalSteps - 1
                        ? 'Envoyer la demande'
                        : 'Suivant',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (_currentStep < _totalSteps - 1) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded, size: 18),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Step 1: Student Information ─────────────────────────────────────────────
  Widget _buildStep1() {
    return _formSectionCard(
      title: 'Informations de l\'élève',
      icon: Icons.person_rounded,
      children: [
        CustomTextField(
          label: 'Nom',
          hint: 'Entrez le nom complet',
          icon: Icons.person_rounded,
          controller: _studentNameController,
          required: true,
          hasError: _studentNameError,
          iconColor: _actionColor,
          focusBorderColor: _actionColor,
        ),
        CustomTextField(
          label: 'Prénoms',
          hint: 'Entrez les prénoms',
          icon: Icons.person_outline_rounded,
          controller: _studentFirstNameController,
          required: true,
          hasError: _studentFirstNameError,
          iconColor: _actionColor,
          focusBorderColor: _actionColor,
        ),
        CustomTextField(
          label: 'Matricule',
          hint: 'Entrez le matricule',
          icon: Icons.badge_rounded,
          controller: _matriculeController,
          required: true,
          hasError: _matriculeError,
          iconColor: _actionColor,
          focusBorderColor: _actionColor,
        ),
        StatefulBuilder(
          builder: (context, ss) => _buildDropdown(
            'Sexe',
            'Sélectionner le sexe',
            Icons.person_rounded,
            value: _selectedSexe,
            items: ['M', 'F'],
            onChanged: (v) => ss(() => _selectedSexe = v ?? 'M'),
          ),
        ),
        CustomTextField(
          label: 'Date de naissance',
          hint: 'JJ/MM/AAAA',
          icon: Icons.cake_rounded,
          controller: _birthDateController,
          keyboardType: TextInputType.number,
          required: true,
          hasError: _birthDateError,
          inputFormatters: [_DateInputFormatter()],
        ),
        CustomTextField(
          label: 'Lieu de naissance',
          hint: 'Entrez le lieu de naissance',
          icon: Icons.location_on_rounded,
          controller: _lieuNaissanceController,
          iconColor: _actionColor,
          focusBorderColor: _actionColor,
        ),
        CustomTextField(
          label: 'Nationalité',
          hint: 'Entrez la nationalité',
          icon: Icons.flag_rounded,
          controller: _nationaliteController,
          iconColor: _actionColor,
          focusBorderColor: _actionColor,
        ),
        CustomTextField(
          label: 'Adresse',
          hint: 'Entrez l\'adresse complète',
          icon: Icons.home_rounded,
          controller: _adresseController,
          maxLines: 2,
          required: true,
          hasError: _adresseError,
          iconColor: _actionColor,
          focusBorderColor: _actionColor,
        ),
      ],
    );
  }

  // ── Step 2: Contacts and Parents ─────────────────────────────────────────────
  Widget _buildStep2() {
    return Column(
      children: [
        _formSectionCard(
          title: 'Contacts',
          icon: Icons.phone_rounded,
          children: [
            CustomTextField(
              label: 'Contact 1',
              hint: 'Numéro principal',
              icon: Icons.phone_rounded,
              controller: _contact1Controller,
              keyboardType: TextInputType.phone,
              required: true,
              hasError: _contact1Error,
              iconColor: _actionColor,
              focusBorderColor: _actionColor,
            ),
            CustomTextField(
              label: 'Contact 2',
              hint: 'Numéro secondaire',
              icon: Icons.phone_android_rounded,
              controller: _contact2Controller,
              keyboardType: TextInputType.phone,
              iconColor: _actionColor,
              focusBorderColor: _actionColor,
            ),
          ],
        ),
        _formSectionCard(
          title: 'Informations des parents',
          icon: Icons.family_restroom_rounded,
          children: [
            CustomTextField(
              label: 'Nom du père',
              hint: 'Nom complet du père',
              icon: Icons.person_rounded,
              controller: _nomPereController,
              required: true,
              hasError: _nomPereError,
              iconColor: _actionColor,
              focusBorderColor: _actionColor,
            ),
            CustomTextField(
              label: 'Nom de la mère',
              hint: 'Nom complet de la mère',
              icon: Icons.person_outline_rounded,
              controller: _nomMereController,
              required: true,
              hasError: _nomMereError,
              iconColor: _actionColor,
              focusBorderColor: _actionColor,
            ),
            CustomTextField(
              label: 'Nom du tuteur',
              hint: 'Nom du tuteur (optionnel)',
              icon: Icons.supervisor_account_rounded,
              controller: _nomTuteurController,
              iconColor: _actionColor,
              focusBorderColor: _actionColor,
            ),
          ],
        ),
      ],
    );
  }

  // ── Step 3: Previous Schooling ───────────────────────────────────────────────
  Widget _buildStep3() {
    return _formSectionCard(
      title: 'Scolarité antérieure',
      icon: Icons.school_rounded,
      children: [
        CustomTextField(
          label: 'Niveau antérieur',
          hint: 'Ex: CP1, 6ème...',
          icon: Icons.school_rounded,
          controller: _niveauAntController,
          iconColor: _actionColor,
          focusBorderColor: _actionColor,
        ),
        CustomTextField(
          label: 'École antérieure',
          hint: 'Nom de l\'école précédente',
          icon: Icons.account_balance_rounded,
          controller: _ecoleAntController,
          iconColor: _actionColor,
          focusBorderColor: _actionColor,
        ),
        CustomTextField(
          label: 'Moyenne antérieure',
          hint: 'Ex: 12.5',
          icon: Icons.grade_rounded,
          controller: _moyenneAntController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          iconColor: _actionColor,
          focusBorderColor: _actionColor,
        ),
        CustomTextField(
          label: 'Rang antérieur',
          hint: 'Ex: 3ème',
          icon: Icons.format_list_numbered_rounded,
          controller: _rangAntController,
          keyboardType: TextInputType.number,
          iconColor: _actionColor,
          focusBorderColor: _actionColor,
        ),
        CustomTextField(
          label: 'Décision',
          hint: 'Ex: Passage, Redoublement...',
          icon: Icons.gavel_rounded,
          controller: _decisionAntController,
        ),
      ],
    );
  }

  // ── Step 4: Documents and Finalization ─────────────────────────────────────────
  Widget _buildStep4() {
    return Column(
      children: [
        _formSectionCard(
          title: 'Documents à fournir',
          icon: Icons.description_rounded,
          children: [
            CustomFileField(
              label: 'Bulletin scolaire',
              hint: 'Sélectionner le bulletin',
              icon: Icons.description_rounded,
              fileName: _bulletinFile,
              onTap: () => _showFilePickerMessage('bulletin'),
            ),
            CustomFileField(
              label: 'Certificat de vaccination',
              hint: 'Sélectionner le certificat',
              icon: Icons.medical_services_rounded,
              fileName: _certificatVaccinationFile,
              onTap: () => _showFilePickerMessage('certificat_vaccination'),
            ),
            CustomFileField(
              label: 'Certificat de scolarité',
              hint: 'Sélectionner le certificat',
              icon: Icons.school_rounded,
              fileName: _certificatScolariteFile,
              onTap: () => _showFilePickerMessage('certificat_scolarite'),
            ),
            CustomFileField(
              label: 'Extrait de naissance',
              hint: 'Sélectionner l\'extrait',
              icon: Icons.card_membership_rounded,
              fileName: _extraitNaissanceFile,
              onTap: () => _showFilePickerMessage('extrait_naissance'),
            ),
            CustomFileField(
              label: 'CNI des parents',
              hint: 'Sélectionner la CNI',
              icon: Icons.credit_card_rounded,
              fileName: _cniParentFile,
              onTap: () => _showFilePickerMessage('cni_parent'),
            ),
          ],
        ),
        _formSectionCard(
          title: 'Détails de la demande',
          icon: Icons.note_rounded,
          children: [
            CustomTextField(
              label: 'Motif',
              hint: 'Ex: Nouvelle inscription, Transfert...',
              icon: Icons.note_rounded,
              controller: _motifController,
            ),
            StatefulBuilder(
              builder: (context, ss) => _buildDropdown(
                'Statut d\'affectation',
                'Sélectionner le statut',
                Icons.assignment_turned_in_rounded,
                value: _selectedStatutAff,
                items: ['Affecté', 'En attente', 'Refusé'],
                onChanged: (v) =>
                    ss(() => _selectedStatutAff = v ?? 'Affecté'),
              ),
            ),
            CustomTextField(
              label: 'Filière',
              hint: 'Ex: primaire, secondaire, technique...',
              icon: Icons.category_rounded,
              controller: _filiereController,
            ),
          ],
        ),
      ],
    );
  }

  // ── Step 5: Récapitulatif ─────────────────────────────────────────────────────
  Widget _buildStep5() {
    return Column(
      children: [
        _formSectionCard(
          title: 'Récapitulatif de la demande',
          icon: Icons.summarize_rounded,
          children: [
            _buildSummaryItem('Informations élève', [
              'Nom: ${_studentNameController.text}',
              'Prénoms: ${_studentFirstNameController.text}',
              'Matricule: ${_matriculeController.text}',
              'Sexe: ${_selectedSexe}',
              'Date de naissance: ${_birthDateController.text}',
              'Lieu: ${_lieuNaissanceController.text}',
              'Nationalité: ${_nationaliteController.text}',
              'Adresse: ${_adresseController.text}',
            ]),
            const SizedBox(height: 16),
            _buildSummaryItem('Contacts et Parents', [
              'Contact 1: ${_contact1Controller.text}',
              'Contact 2: ${_contact2Controller.text}',
              'Nom du père: ${_nomPereController.text}',
              'Nom de la mère: ${_nomMereController.text}',
              if (_nomTuteurController.text.isNotEmpty)
                'Nom du tuteur: ${_nomTuteurController.text}',
            ]),
            const SizedBox(height: 16),
            _buildSummaryItem('Scolarité antérieure', [
              if (_niveauAntController.text.isNotEmpty)
                'Niveau: ${_niveauAntController.text}',
              if (_ecoleAntController.text.isNotEmpty)
                'École: ${_ecoleAntController.text}',
              if (_moyenneAntController.text.isNotEmpty)
                'Moyenne: ${_moyenneAntController.text}',
              if (_rangAntController.text.isNotEmpty)
                'Rang: ${_rangAntController.text}',
              if (_decisionAntController.text.isNotEmpty)
                'Décision: ${_decisionAntController.text}',
            ]),
            const SizedBox(height: 16),
            _buildSummaryItem('Détails de la demande', [
              'Motif: ${_motifController.text}',
              'Statut: ${_selectedStatutAff}',
              'Filière: ${_filiereController.text}',
            ]),
            const SizedBox(height: 16),
            _buildSummaryItem('Documents', [
              if (_bulletinFile != null) '✅ Bulletin scolaire',
              if (_certificatVaccinationFile != null)
                '✅ Certificat de vaccination',
              if (_certificatScolariteFile != null)
                '✅ Certificat de scolarité',
              if (_extraitNaissanceFile != null) '✅ Extrait de naissance',
              if (_cniParentFile != null) '✅ CNI des parents',
              if (_bulletinFile == null &&
                  _certificatVaccinationFile == null &&
                  _certificatScolariteFile == null &&
                  _extraitNaissanceFile == null &&
                  _cniParentFile == null)
                'Aucun document sélectionné',
            ]),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryItem(String title, List<String> items) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.screenSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.screenDivider.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.screenTextPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...items.where((item) => item.isNotEmpty).map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 4,
                        height: 4,
                        margin: const EdgeInsets.only(top: 8, right: 8),
                        decoration: const BoxDecoration(
                          color: AppColors.screenOrange,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          item,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.screenTextSecondary,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }

  // ── UI helpers ────────────────────────────────────────────────────────────
  void _showFilePickerMessage(String fileType) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sélection de fichier pour: $fileType'),
        backgroundColor: AppColors.screenOrange,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _formSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: AppColors.screenCard,
        borderRadius: BorderRadius.circular(
          AppDimensions.getLargeCardBorderRadius(context),
        ),
        boxShadow: AppDimensions.getLightShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.screenOrangeLight,
                    borderRadius: BorderRadius.circular(
                      AppDimensions.getBadgeBorderRadius(context),
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: AppColors.screenOrange,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.screenTextPrimary,
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Divider(color: AppColors.screenDivider, height: 1),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _intersperse(children, const SizedBox(height: 12)),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _intersperse(List<Widget> widgets, Widget separator) {
    final result = <Widget>[];
    for (var i = 0; i < widgets.length; i++) {
      result.add(widgets[i]);
      if (i < widgets.length - 1) result.add(separator);
    }
    return result;
  }

  Widget _buildDropdown(
    String label,
    String hint,
    IconData icon, {
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
    bool required = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.screenTextSecondary,
              ),
            ),
            if (required)
              const Text(
                ' *',
                style: TextStyle(
                  color: AppColors.screenOrange,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: value,
          items: items
              .map(
                (i) => DropdownMenuItem(
                  value: i,
                  child: Text(
                    i,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.screenTextPrimary,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
          dropdownColor: Colors.white,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              fontSize: 13,
              color: Color(0xFFBBBBBB),
            ),
            prefixIcon: Icon(
              icon,
              color: AppColors.screenOrange,
              size: 18,
            ),
            filled: true,
            fillColor: AppColors.screenSurface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                AppDimensions.getSmallCardBorderRadius(context),
              ),
              borderSide: const BorderSide(color: AppColors.screenDivider),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                AppDimensions.getSmallCardBorderRadius(context),
              ),
              borderSide: const BorderSide(color: AppColors.screenDivider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                AppDimensions.getSmallCardBorderRadius(context),
              ),
              borderSide: const BorderSide(
                color: AppColors.screenOrange,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}