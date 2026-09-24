import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/child.dart';
import '../models/code_dren_ecole.dart';
import '../models/user.dart';
import '../services/consultation_api_service.dart';
import '../services/ecole_eleve_service.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../services/text_size_service.dart';
import '../config/app_colors.dart';
import '../config/app_dimensions.dart';
import '../widgets/custom_sliver_app_bar.dart';
import '../widgets/recommendation_bottom_sheet.dart';
import '../utils/notification_helper.dart';
import '../services/recommendation_service.dart';
import '../widgets/main_screen_wrapper.dart';
import '../utils/auth_guard.dart';

// ─── DESIGN TOKENS (centralisés dans AppColors) ────────────────────────────────

/// Écran pour ajouter un élève, en 2 étapes : code DREN de l'école puis
/// matricule de l'élève — même parcours que le wizard "Nouvelle Inscription"
/// (InscriptionBottomSheet), recherche via api2.vie-ecoles.com.
class AddChildScreen extends StatefulWidget {
  const AddChildScreen({super.key});

  @override
  State<AddChildScreen> createState() => _AddChildScreenState();
}

class _AddChildScreenState extends State<AddChildScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final ConsultationApiService _consultationApi = ConsultationApiService();
  final TextSizeService _textSizeService = TextSizeService();

  final TextEditingController _recommenderNameController =
      TextEditingController();
  final TextEditingController _etablissementController =
      TextEditingController();
  final TextEditingController _paysRecommendController =
      TextEditingController();
  final TextEditingController _villeRecommendController =
      TextEditingController();

  final TextEditingController _parentNomController = TextEditingController();
  final TextEditingController _parentPrenomController = TextEditingController();
  final TextEditingController _parentTelephoneController =
      TextEditingController();
  final TextEditingController _parentEmailController = TextEditingController();

  final TextEditingController _ordreController = TextEditingController();
  final TextEditingController _adresseEtablissementController =
      TextEditingController();

  final TextEditingController _paysParentController = TextEditingController();
  final TextEditingController _villeParentController = TextEditingController();
  final TextEditingController _adresseParentController =
      TextEditingController();

  // Recherche de l'école par code DREN (api2.vie-ecoles.com)
  final TextEditingController _drenController = TextEditingController();
  bool _isSearchingEcole = false;
  CodeDrenEcole? _foundEcole;

  // Recherche de l'élève par matricule (une fois l'école trouvée)
  final TextEditingController _matriculeController = TextEditingController();
  bool _isSearching = false;
  Map<String, dynamic>? _foundEleve;

  // `schoolId` (API de consultation) résolu en plus du code vie-ecoles, pour
  // que l'enfant garde notes/bulletins/années — best-effort, `null` si
  // l'établissement n'existe pas (encore) côté API de consultation.
  String? _resolvedSchoolId;

  String? _errorMessage;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isFoundStudentSheetOpen = false;

  @override
  void initState() {
    super.initState();
    _textSizeService.addListener(() {
      if (mounted) setState(() {});
    });

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();
  }

  void _showRecommendationBottomSheet() {
    showModalBottomSheet(
      constraints: const BoxConstraints(maxWidth: double.infinity),
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RecommendationBottomSheet(
        icon: Icons.recommend_rounded,
        accentColor: AppColors.screenOrange,
        recommenderNameController: _recommenderNameController,
        etablissementController: _etablissementController,
        paysRecommendController: _paysRecommendController,
        villeRecommendController: _villeRecommendController,
        parentNomController: _parentNomController,
        parentPrenomController: _parentPrenomController,
        parentTelephoneController: _parentTelephoneController,
        parentEmailController: _parentEmailController,
        ordreController: _ordreController,
        adresseEtablissementController: _adresseEtablissementController,
        paysParentController: _paysParentController,
        villeParentController: _villeParentController,
        adresseParentController: _adresseParentController,
        title: 'Recommander une école',
        subtitle:
            'Votre école n\'est pas dans la liste ? Proposez-la pour l\'ajouter.',
        onSubmit: (context) async {
          try {
            await RecommendationService.submitRecommendation(
              etablissement: _etablissementController.text,
              pays: _paysRecommendController.text,
              ville: _villeRecommendController.text,
              ordre: _ordreController.text.isEmpty
                  ? '1'
                  : _ordreController.text,
              adresseEtablissement: _adresseEtablissementController.text.isEmpty
                  ? 'Non spécifiée'
                  : _adresseEtablissementController.text,
              nomParent: _parentNomController.text,
              prenomParent: _parentPrenomController.text,
              telephone: _parentTelephoneController.text,
              email: _parentEmailController.text.isEmpty
                  ? 'email@example.com'
                  : _parentEmailController.text,
              paysParent: _paysParentController.text.isEmpty
                  ? _paysRecommendController.text
                  : _paysParentController.text,
              villeParent: _villeParentController.text.isEmpty
                  ? _villeRecommendController.text
                  : _villeParentController.text,
              adresseParent: _adresseParentController.text.isEmpty
                  ? 'Non spécifiée'
                  : _adresseParentController.text,
            );

            if (mounted) Navigator.of(context).pop();
            if (mounted) {
              NotificationHelper.showSuccess('Recommandation envoyée avec succès!');
            }

            _etablissementController.clear();
            _paysRecommendController.clear();
            _villeRecommendController.clear();
            _parentNomController.clear();
            _parentPrenomController.clear();
            _parentTelephoneController.clear();
            _parentEmailController.clear();
            _ordreController.clear();
            _adresseEtablissementController.clear();
            _paysParentController.clear();
            _villeParentController.clear();
            _adresseParentController.clear();
            _recommenderNameController.clear();
          } catch (e) {
            if (!mounted) return;
            NotificationHelper.showError('Erreur: $e');
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    _drenController.dispose();
    _matriculeController.dispose();

    _recommenderNameController.dispose();
    _etablissementController.dispose();
    _paysRecommendController.dispose();
    _villeRecommendController.dispose();
    _parentNomController.dispose();
    _parentPrenomController.dispose();
    _parentTelephoneController.dispose();
    _parentEmailController.dispose();
    _ordreController.dispose();
    _adresseEtablissementController.dispose();
    _paysParentController.dispose();
    _villeParentController.dispose();
    _adresseParentController.dispose();

    _animationController.dispose();
    super.dispose();
  }

  // ─── ÉTAPE 1 : recherche de l'école par code DREN ──────────────────────────
  Future<void> _searchEcole() async {
    FocusScope.of(context).unfocus();

    final codeDren = _drenController.text.trim();
    if (codeDren.isEmpty) {
      setState(() => _errorMessage = 'Veuillez entrer le code DREN de l\'école');
      return;
    }

    setState(() {
      _isSearchingEcole = true;
      _errorMessage = null;
      _foundEcole = null;
      _resolvedSchoolId = null;
    });

    try {
      final ecole = await EcoleEleveService.rechercherParCodeDren(codeDren);

      // Best-effort, non bloquant : résout aussi le `schoolId` de l'API de
      // consultation (par le code DREN, qui correspond au `code` de
      // GET /consultation/etablissements) pour que l'enfant garde notes,
      // bulletins et années une fois ajouté. `null` si l'établissement n'y
      // figure pas (encore) — n'empêche pas l'ajout.
      String? schoolId;
      try {
        schoolId = await _consultationApi.findSchoolIdByCode(
          ecole.codeDren ?? codeDren,
          expectedName: ecole.nom,
        );
      } catch (_) {
        schoolId = null;
      }

      if (mounted) {
        setState(() {
          _foundEcole = ecole;
          _resolvedSchoolId = schoolId;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = _readableError(e));
      }
    } finally {
      if (mounted) setState(() => _isSearchingEcole = false);
    }
  }

  /// "Retour" — réinitialise la recherche d'école pour repartir de zéro
  /// (l'ancien bouton orange "Rechercher l'école" devient ce bouton une fois
  /// l'école trouvée).
  void _resetEcoleSearch() {
    FocusScope.of(context).unfocus();
    setState(() {
      _drenController.clear();
      _matriculeController.clear();
      _foundEcole = null;
      _foundEleve = null;
      _resolvedSchoolId = null;
      _errorMessage = null;
    });
  }

  // ─── Recherche de l'élève par matricule (une fois l'école trouvée) ─────────
  Future<void> _searchEleve() async {
    FocusScope.of(context).unfocus();

    final ecole = _foundEcole;
    if (ecole == null) return;

    if (_matriculeController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Veuillez entrer un matricule');
      return;
    }

    setState(() {
      _isSearching = true;
      _errorMessage = null;
      _foundEleve = null;
    });

    try {
      final matricule = _matriculeController.text.trim();
      final eleveDetail = await EcoleEleveService.getEleveDetail(
        matricule,
        ecole.code,
      );

      setState(() {
        _foundEleve = eleveDetail;
        _isSearching = false;
      });

      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _showFoundStudentBottomSheet();
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = _readableError(e);
        _isSearching = false;
      });
    }
  }

  String _readableError(Object e) {
    final errorString = e.toString();
    final isNetworkError = errorString.contains('SocketException') ||
        errorString.contains('ClientException') ||
        errorString.contains('Failed host lookup') ||
        errorString.contains('No address associated') ||
        errorString.contains('Connection refused') ||
        errorString.contains('Network is unreachable') ||
        errorString.contains('Software caused connection abort');
    if (isNetworkError) return 'Vérifiez votre connexion internet';
    return errorString.replaceFirst('Exception: ', '');
  }

  Future<void> _handleAddChild(StateSetter setModalState) async {
    // Garde-fou anti double-tap : le bouton du bottom sheet n'est pas
    // reconstruit quand _isLoading change (showModalBottomSheet ne rebuild
    // pas automatiquement son contenu), donc il reste visuellement actif
    // pendant l'opération. Sans ce garde-fou, un second tap pendant que le
    // premier est encore en cours relance tout le processus en parallèle.
    if (_isLoading) return;

    if (_foundEleve == null || _foundEcole == null) {
      _showSnackbar(
        'Erreur: informations élève ou école manquantes',
        isError: true,
      );
      return;
    }
    final eleve = _foundEleve!;
    final ecole = _foundEcole!;
    setState(() => _isLoading = true);
    if (_isFoundStudentSheetOpen) setModalState(() {});

    final ok = await AuthGuard.ensureLoggedIn(
      context,
      reason: 'Connectez-vous pour ajouter votre enfant',
      onAuthenticatedAsync: () => _performAddChild(
        AuthService.instance.getCurrentUser()!,
        eleve,
        ecole,
        setModalState,
      ),
    );
    if (!ok && mounted) {
      setState(() => _isLoading = false);
      if (_isFoundStudentSheetOpen) setModalState(() {});
    }
  }

  bool _isLoading = false;

  String _eleveField(Map<String, dynamic> eleve, String key) {
    final value = eleve[key];
    if (value == null) return '';
    return value.toString().trim();
  }

  String get _eleveGrade {
    final eleve = _foundEleve;
    if (eleve == null) return '';
    final branche = _eleveField(eleve, 'branche');
    return branche.isNotEmpty ? branche : _eleveField(eleve, 'niveau');
  }

  Future<void> _performAddChild(
    User currentUser,
    Map<String, dynamic> eleve,
    CodeDrenEcole ecole,
    StateSetter setModalState,
  ) async {
    try {
      final parentId = currentUser.id;
      final matricule = _eleveField(eleve, 'matricule');
      final nom = _eleveField(eleve, 'nom');
      final prenoms = _eleveField(eleve, 'prenoms');
      if (matricule.isEmpty || (nom.isEmpty && prenoms.isEmpty)) {
        throw Exception('Informations élève incomplètes');
      }

      final childId = matricule;

      // Vérifier si l'élève existe déjà dans la base de données locale
      final existingChild = await DatabaseService.instance.getChildById(
        childId,
      );
      if (existingChild != null && existingChild.parentId == parentId) {
        setState(() => _isLoading = false);
        if (_isFoundStudentSheetOpen) setModalState(() {});
        if (mounted) {
          _showSnackbar('Cet élève est déjà ajouté', isError: true);
        }
        return;
      }

      final grade = _eleveGrade;
      final photo = _eleveField(eleve, 'photo');

      final newChild = Child(
        id: childId,
        firstName: prenoms,
        lastName: nom,
        establishment: ecole.nom.isNotEmpty
            ? ecole.nom
            : 'École non spécifiée',
        grade: grade.isNotEmpty ? grade : 'Classe non spécifiée',
        photoUrl: photo.isNotEmpty ? photo : null,
        parentId: parentId,
        // Code legacy vie-ecoles (ex. "gainhs"), attendu par toutes les
        // intégrations tierces (paiement, inscription, contrôle d'accès...).
        paramEcole: ecole.code,
      );

      print('');
      print('═══════════════════════════════════════════════════════════');
      print('💾 SAUVEGARDE LOCALE DE L\'ÉLÈVE — données stockées');
      print('═══════════════════════════════════════════════════════════');
      print('   🆔 id (matricule): ${newChild.id}');
      print('   👤 firstName: ${newChild.firstName}');
      print('   👤 lastName: ${newChild.lastName}');
      print('   🏫 establishment: ${newChild.establishment}');
      print('   📚 grade: ${newChild.grade}');
      print('   🖼️ photoUrl: ${newChild.photoUrl ?? "null"}');
      print('   👪 parentId: ${newChild.parentId}');
      print('   🔑 paramEcole (vie-ecoles): ${newChild.paramEcole ?? "null"}');
      print('   🆔 schoolId (consultation): ${_resolvedSchoolId ?? "null"}');
      print('═══════════════════════════════════════════════════════════');
      print('');

      await DatabaseService.instance.saveChild(
        newChild,
        matricule: matricule,
        ecoleName: ecole.nom,
        paramEcole: ecole.code,
        classeName: grade,
        schoolId: _resolvedSchoolId,
      );

      setState(() => _isLoading = false);
      if (_isFoundStudentSheetOpen) setModalState(() {});
      if (mounted) {
        // La notification de succès sera affichée par MainScreenWrapper

        // Forcer la navigation vers la home screen et remplacer toute la pile
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) =>
                const MainScreenWrapper(showChildAddedSuccess: true),
          ),
          (route) => false, // Supprimer tous les écrans précédents
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (_isFoundStudentSheetOpen) setModalState(() {});
      if (mounted) _showSnackbar('Erreur : $e', isError: true);
    }
  }

  // ─── HELPERS UI ────────────────────────────────────────────────────────────
  void _showSnackbar(String msg, {bool isError = false}) {
    if (isError) {
      NotificationHelper.showError(msg);
    } else {
      NotificationHelper.showSuccess(msg);
    }
  }

  void _showHelpDialog() {
    showModalBottomSheet(
      constraints: const BoxConstraints(maxWidth: double.infinity),
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return SafeArea(
          top: false,
          bottom: false,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.screenSurfaceThemed(context),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
              boxShadow: AppDimensions.getBottomSheetShadow(context),
            ),
            padding: EdgeInsets.fromLTRB(
              20,
              12,
              20,
              20 + MediaQuery.of(context).padding.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.screenDividerThemed(context),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  'Comment trouver le code DREN et le matricule ?',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: _textSizeService.getScaledFontSize(17),
                    color: AppColors.screenTextPrimaryThemed(context),
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Le code DREN de l\'école et le matricule de l\'élève se trouvent sur :',
                  style: TextStyle(
                    color: AppColors.screenTextSecondaryThemed(context),
                    fontSize: _textSizeService.getScaledFontSize(13),
                  ),
                ),
                const SizedBox(height: 14),
                _helpItem('📄', 'Carnet de correspondance'),
                _helpItem('🎓', 'Bulletin scolaire'),
                _helpItem('📝', 'Carte d\'élève'),
                _helpItem('💻', 'Portail en ligne de l\'école'),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.screenOrange,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppDimensions.getButtonBorderRadius(context),
                        ),
                      ),
                    ),
                    child: Text(
                      'Compris',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: _textSizeService.getScaledFontSize(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _helpItem(String emoji, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 10),
        Text(
          text,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.screenTextPrimaryThemed(context),
          ),
        ),
      ],
    ),
  );

  // ─── BUILD ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Theme.of(context).scaffoldBackgroundColor
            : Colors.white, // Fond blanc en mode clair
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: CustomScrollView(
            slivers: [
              CustomSliverAppBar(
                title: 'Ajouter un élève',
                actions: [_buildHelpAppBarAction()],
              ),
              SliverToBoxAdapter(
                child: SlideTransition(
                  position: _slideAnimation,
                  child: _buildBody(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHelpAppBarAction() {
    return GestureDetector(
      onTap: _showHelpDialog,
      child: Container(
        width: 40,
        height: 40,
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.screenCardThemed(context),
          borderRadius: BorderRadius.circular(
            AppDimensions.getSmallCardBorderRadius(context),
          ),
          boxShadow: AppDimensions.getSettingsCardShadow(context),
        ),
        child: const Icon(
          Icons.help_outline,
          size: 18,
          color: AppColors.screenOrange,
        ),
      ),
    );
  }

  // ─── BODY ──────────────────────────────────────────────────────────────────
  Widget _buildBody() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeroBanner(),
            const SizedBox(height: 20),
            _buildSearchPanel(),
          ],
        ),
      ),
    );
  }

  void _showFoundStudentBottomSheet() {
    if (_isFoundStudentSheetOpen) return;
    if (_foundEleve == null || _foundEcole == null) return;

    _isFoundStudentSheetOpen = true;
    showModalBottomSheet(
      constraints: const BoxConstraints(maxWidth: double.infinity),
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              top: false,
              bottom: false,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.screenSurfaceThemed(context),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                  boxShadow: AppDimensions.getBottomSheetShadow(context),
                ),
                padding: EdgeInsets.fromLTRB(
                  16,
                  10,
                  16,
                  16 + MediaQuery.of(context).padding.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 44,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AppColors.screenDividerThemed(context),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: _buildFoundStudentContent(setModalState),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      if (mounted) setState(() => _isFoundStudentSheetOpen = false);
      if (!mounted) _isFoundStudentSheetOpen = false;
    });
  }

  // ─── HERO BANNER ───────────────────────────────────────────────────────────
  Widget _buildHeroBanner() {
    return Container(
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.screenOrange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.person_add_rounded,
                    color: AppColors.screenOrange,
                    size: 24,
                  ),
                ),
                Text(
                  'Ajouter votre enfant',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: _textSizeService.getScaledFontSize(16),
                    fontWeight: FontWeight.w800,
                    color:
                        Theme.of(context).textTheme.headlineSmall?.color ??
                        Colors.black,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _foundEcole == null
                      ? 'Entrez le code DREN de l\'école'
                      : 'Entrez le matricule scolaire pour retrouver votre enfant',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: _textSizeService.getScaledFontSize(12),
                    color:
                        Theme.of(context).textTheme.bodyMedium?.color ??
                        Colors.black,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── SEARCH PANEL ──────────────────────────────────────────────────────────
  Widget _buildSearchPanel() {
    return Container(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 20, 0, 0),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.screenOrangeLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.search_rounded,
                    color: AppColors.screenOrange,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Recherche',
                  style: TextStyle(
                    fontSize: _textSizeService.getScaledFontSize(17),
                    fontWeight: FontWeight.w700,
                    color: AppColors.screenTextPrimaryThemed(context),
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 16, 0, 20),
            child: _buildSearchForm(),
          ),
        ],
      ),
    );
  }

  // ─── FORMULAIRE DE RECHERCHE (école puis élève, sur un seul écran) ─────────
  Widget _buildSearchForm() {
    final ecoleFound = _foundEcole != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!ecoleFound) ...[
          _fieldLabel('Code DREN de l\'école', required: true),
          const SizedBox(height: 6),
          _buildTextField(
            controller: _drenController,
            hintText: 'Ex: 002016',
            icon: Icons.pin_outlined,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onSubmitted: (_) => _searchEcole(),
          ),
        ],
        if (ecoleFound) ...[
          _buildEcoleFoundCard(_foundEcole!),
          const SizedBox(height: 20),
          _fieldLabel('Matricule de l\'élève', required: true),
          const SizedBox(height: 6),
          _buildTextField(
            controller: _matriculeController,
            hintText: 'Ex: 24047355B',
            icon: Icons.badge_outlined,
            keyboardType: TextInputType.text,
            onSubmitted: (_) => _searchEleve(),
          ),
        ],
        if (_errorMessage != null) ...[
          const SizedBox(height: 12),
          _buildErrorBanner(),
        ],
        const SizedBox(height: 20),
        if (!ecoleFound)
          _buildOrangeButton(
            label: _isSearchingEcole ? 'Recherche en cours...' : 'Rechercher l\'école',
            onTap: _isSearchingEcole ? null : _searchEcole,
            isLoading: _isSearchingEcole,
            icon: Icons.search_rounded,
          )
        else
          Row(
            children: [
              Expanded(
                child: _buildOrangeButton(
                  label: 'Retour',
                  onTap: _resetEcoleSearch,
                  icon: Icons.arrow_back_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildOrangeButton(
                  label: _isSearching ? 'Recherche en cours...' : 'Continuer',
                  onTap: _isSearching ? null : _searchEleve,
                  isLoading: _isSearching,
                  icon: Icons.arrow_forward_rounded,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
        const SizedBox(height: 16),
        _buildRecommendSchoolButton(),
      ],
    );
  }

  Widget _buildEcoleFoundCard(CodeDrenEcole ecole) {
    final localisation = [
      ecole.ville,
      ecole.adresse,
    ].where((v) => v != null && v.isNotEmpty).join(', ');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.success.withValues(alpha: 0.10),
            AppColors.success.withValues(alpha: 0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.success, AppColors.success.withValues(alpha: 0.75)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.success.withValues(alpha: 0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'École trouvée !',
            style: TextStyle(
              fontSize: _textSizeService.getScaledFontSize(15),
              fontWeight: FontWeight.w800,
              color: AppColors.success,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            ecole.nom,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: _textSizeService.getScaledFontSize(15),
              fontWeight: FontWeight.w700,
              color: AppColors.screenTextPrimaryThemed(context),
            ),
          ),
          if (localisation.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              localisation,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: _textSizeService.getScaledFontSize(12),
                color: AppColors.screenTextSecondaryThemed(context),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecommendSchoolButton() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subtleGray = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : const Color(0xFFEFEFF2);
    final subtleGrayText = isDark ? Colors.white70 : const Color(0xFF6B6B76);

    return GestureDetector(
      onTap: _showRecommendationBottomSheet,
      child: Container(
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: subtleGray,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.recommend_rounded,
              color: subtleGrayText,
              size: 16,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'Recommander une école',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: subtleGrayText,
                  fontWeight: FontWeight.w700,
                  fontSize: _textSizeService.getScaledFontSize(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── ÉTAPE 2 : MATRICULE ────────────────────────────────────────────────────
  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    ValueChanged<String>? onSubmitted,
  }) {
    return TextField(
      controller: controller,
      autofocus: false,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: TextStyle(
        fontSize: 14,
        color:
            Theme.of(context).textTheme.bodyLarge?.color ??
            AppColors.screenTextPrimary,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          fontSize: 13,
          color: Theme.of(context).hintColor,
        ),
        prefixIcon: Icon(icon, color: Colors.grey, size: 18),
        filled: true,
        fillColor: Theme.of(context).brightness == Brightness.dark
            ? Theme.of(context).cardColor
            : Colors.white, // Fond blanc en mode clair
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.screenDividerThemed(context)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.screenDividerThemed(context)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.screenOrange,
            width: 1.5,
          ),
        ),
      ),
      onSubmitted: onSubmitted,
    );
  }

  Widget _fieldLabel(String label, {bool required = false}) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.screenTextSecondaryThemed(context),
            letterSpacing: 0.2,
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
    );
  }

  // ─── ERROR BANNER ──────────────────────────────────────────────────────────
  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[400], size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(
                color: Colors.red[700],
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── FOUND STUDENT CARD ────────────────────────────────────────────────────
  Widget _buildFoundStudentContent(StateSetter setModalState) {
    final eleve = _foundEleve!;
    final ecole = _foundEcole!;
    final nom = _eleveField(eleve, 'nom');
    final prenoms = _eleveField(eleve, 'prenoms');
    final matricule = _eleveField(eleve, 'matricule');
    final photo = _eleveField(eleve, 'photo');
    final grade = _eleveGrade;

    return Column(
      children: [
        Row(
          children: [
            Hero(
              tag: 'student_photo_$matricule',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  width: 56,
                  height: 56,
                  color: AppColors.screenCardThemed(context),
                  child: photo.isNotEmpty
                      ? Image.network(
                          photo,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.person,
                            color: AppColors.screenTextSecondaryThemed(context),
                            size: 28,
                          ),
                        )
                      : Icon(
                          Icons.person,
                          color: AppColors.screenTextSecondaryThemed(context),
                          size: 28,
                        ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nom.isNotEmpty ? nom : 'Nom inconnu',
                    style: TextStyle(
                      fontSize: _textSizeService.getScaledFontSize(16),
                      fontWeight: FontWeight.w800,
                      color: AppColors.screenTextPrimaryThemed(context),
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    prenoms.isNotEmpty ? prenoms : 'Prénom inconnu',
                    style: TextStyle(
                      fontSize: _textSizeService.getScaledFontSize(13),
                      color: AppColors.screenTextSecondaryThemed(context),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.screenCardThemed(context),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.screenDividerThemed(context),
                          ),
                        ),
                        child: Text(
                          grade.isNotEmpty ? grade : 'Classe inconnue',
                          style: TextStyle(
                            fontSize: _textSizeService.getScaledFontSize(11),
                            color: AppColors.screenTextSecondaryThemed(context),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.successLight,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.check_rounded,
                              size: 14,
                              color: AppColors.white,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Trouvé',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Divider(color: AppColors.screenDividerThemed(context), height: 1),
        const SizedBox(height: 12),
        _infoRow(Icons.school_outlined, 'École', ecole.nom),
        const SizedBox(height: 10),
        _infoRow(Icons.badge_outlined, 'Matricule', matricule),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: _isLoading
                ? null
                : () => _handleAddChild(setModalState),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.person_add_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Ajouter cet élève à mon compte',
                        style: TextStyle(
                          fontSize: _textSizeService.getScaledFontSize(14),
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppColors.screenCardThemed(context),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.screenDividerThemed(context),
              ),
            ),
            child: Icon(
              icon,
              color: AppColors.screenTextSecondaryThemed(context),
              size: 15,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$label : $value',
              style: TextStyle(
                fontSize: _textSizeService.getScaledFontSize(13),
                fontWeight: FontWeight.w600,
                color: AppColors.screenTextPrimaryThemed(context),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ─── ORANGE BUTTON (identique CartScreen) ─────────────────────────────────
  Widget _buildOrangeButton({
    required String label,
    VoidCallback? onTap,
    bool isLoading = false,
    IconData? icon,
    Color color = AppColors.screenOrange,
    Color? shadowColor,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: color == AppColors.screenOrange
              ? const [Color(0xFFFF7A3C), AppColors.screenOrange]
              : [color.withOpacity(0.85), color],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: isLoading ? null : onTap,
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: _textSizeService.getScaledFontSize(14),
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
