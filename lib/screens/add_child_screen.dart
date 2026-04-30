import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/child.dart';
import '../models/eleve.dart';
import '../models/ecole.dart';
import '../models/user.dart';
import '../services/pouls_scolaire_api_service.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../services/mock_api_service.dart';
import '../services/remote_api_service.dart';
import '../services/notification_service.dart';
import '../services/theme_service.dart';
import '../services/text_size_service.dart';
import '../config/app_config.dart';
import '../config/app_colors.dart';
import '../config/app_dimensions.dart';
import '../widgets/custom_sliver_app_bar.dart';
import '../widgets/searchable_dropdown.dart';
import '../widgets/recommendation_bottom_sheet.dart';
import '../services/recommendation_service.dart';
import 'login_screen.dart';

// ─── DESIGN TOKENS (centralisés dans AppColors) ────────────────────────────────

/// Écran pour ajouter un élève par matricule
class AddChildScreen extends StatefulWidget {
  const AddChildScreen({super.key});

  @override
  State<AddChildScreen> createState() => _AddChildScreenState();
}

class _AddChildScreenState extends State<AddChildScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _matriculeController = TextEditingController();
  final PoulsScolaireApiService _poulsApiService = PoulsScolaireApiService();
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

  bool _isLoading = false;
  bool _isSearching = false;
  bool _isLoadingEcoles = false;
  Eleve? _foundEleve;
  Ecole? _foundEcole;
  String? _errorMessage;

  List<Ecole> _ecoles = [];
  int? _selectedEcoleId;
  String? _selectedEcoleName;

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
    _loadEcoles();

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
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RecommendationBottomSheet(
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
              ScaffoldMessenger.of(this.context).showSnackBar(
                const SnackBar(
                  content: Text('Recommandation envoyée avec succès!'),
                  backgroundColor: Colors.green,
                ),
              );
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
            ScaffoldMessenger.of(this.context).showSnackBar(
              SnackBar(
                content: Text('Erreur: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      ),
    );
  }

  @override
  void dispose() {
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

  // ─── DATA ──────────────────────────────────────────────────────────────────
  Future<void> _loadEcoles() async {
    setState(() {
      _isLoadingEcoles = true;
      _errorMessage = null;
    });
    try {
      final ecoles = await _poulsApiService.getAllEcoles();
      setState(() {
        _ecoles = ecoles;
        _isLoadingEcoles = false;
      });
      if (ecoles.isEmpty && mounted) {
        _showSnackbar('Aucune école disponible', isError: true);
      }
    } catch (e) {
      setState(() {
        _isLoadingEcoles = false;
        _errorMessage = 'Erreur chargement des écoles';
      });
      final isDns =
          e.toString().contains('Failed host lookup') ||
          e.toString().contains('No address associated');
      if (isDns && mounted)
        _showDnsDialog();
      else if (mounted)
        _showSnackbar('Erreur : ${e.toString()}', isError: true);
    }
  }

  Future<void> _searchEleve() async {
    if (_matriculeController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Veuillez entrer un matricule');
      return;
    }
    if (_selectedEcoleId == null) {
      setState(() => _errorMessage = 'Veuillez sélectionner une école');
      return;
    }
    setState(() {
      _isSearching = true;
      _errorMessage = null;
      _foundEleve = null;
      _foundEcole = null;
    });
    try {
      final matricule = _matriculeController.text.trim();
      final anneeScolaire = await _poulsApiService.getAnneeScolaireOuverte(
        _selectedEcoleId!,
      );
      final idAnnee = anneeScolaire.anneeOuverteCentraleId;
      if (idAnnee == 0 || anneeScolaire.anneeEcoleList.isEmpty) {
        setState(() {
          _errorMessage = 'Aucune année scolaire ouverte pour cette école';
          _isSearching = false;
        });
        return;
      }
      final eleve = await _poulsApiService.findEleveByMatricule(
        _selectedEcoleId!,
        idAnnee,
        matricule,
      );
      if (eleve != null) {
        final ecole = _ecoles.firstWhere(
          (e) => e.ecoleid == _selectedEcoleId,
          orElse: () => _ecoles.first,
        );
        setState(() {
          _foundEleve = eleve;
          _foundEcole = ecole;
          _isSearching = false;
        });

        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _showFoundStudentBottomSheet();
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Aucun élève trouvé avec ce matricule';
          _isSearching = false;
        });
      }
    } catch (e) {
      String msg = 'Erreur lors de la recherche';
      if (e.toString().contains('année scolaire'))
        msg = 'Impossible de récupérer l\'année scolaire.';
      else if (e.toString().contains('timeout'))
        msg = 'Délai dépassé. Vérifiez votre connexion.';
      else
        msg = 'Erreur : ${e.toString().split(':').last.trim()}';
      setState(() {
        _errorMessage = msg;
        _isSearching = false;
      });
    }
  }

  Future<void> _handleAddChild() async {
    print('🔘 BUTTON CLICKED: _handleAddChild called');
    print('🔘 DEBUG: _foundEleve = ${_foundEleve?.prenomEleve} ${_foundEleve?.nomEleve}');
    print('🔘 DEBUG: _foundEcole = ${_foundEcole?.ecoleclibelle}');
    
    if (_foundEleve == null || _foundEcole == null) {
      print('❌ DEBUG: _foundEleve or _foundEcole is null');
      _showSnackbar('Erreur: informations élève ou école manquantes', isError: true);
      return;
    }
    final eleve = _foundEleve!;
    final ecole = _foundEcole!;
    print('✅ DEBUG: Starting add child process for ${eleve.prenomEleve} ${eleve.nomEleve}');
    setState(() => _isLoading = true);
    try {
      User? currentUser = AuthService.instance.getCurrentUser();
      if (currentUser == null) {
        await AuthService.instance.loadSavedSession();
        currentUser = AuthService.instance.getCurrentUser();
        if (currentUser == null) {
          _showSnackbar(
            'Session expirée. Veuillez vous reconnecter.',
            isError: true,
          );
          if (mounted)
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (_) => false,
            );
          return;
        }
      }
      final parentId = currentUser.id;
      final apiService = AppConfig.MOCK_MODE
          ? MockApiService()
          : RemoteApiService();
      if (eleve.prenomEleve.isEmpty || eleve.nomEleve.isEmpty)
        throw Exception('Informations élève incomplètes');
      final newChild = Child(
        id: eleve.inscriptionsidEleve.toString(),
        firstName: eleve.prenomEleve,
        lastName: eleve.nomEleve,
        establishment: ecole.ecoleclibelle.isNotEmpty
            ? ecole.ecoleclibelle
            : 'École non spécifiée',
        grade: eleve.classe.isNotEmpty ? eleve.classe : 'Classe non spécifiée',
        photoUrl: eleve.urlPhoto,
        parentId: parentId,
        paramEcole: ecole.paramecole?.isNotEmpty == true
            ? ecole.paramecole
            : ecole.ecolecode,
      );
      await DatabaseService.instance.saveChild(
        newChild,
        matricule: eleve.matriculeEleve,
        ecoleId: ecole.ecoleid,
        ecoleName: ecole.ecoleclibelle,
        paramEcole: ecole.paramecole?.isNotEmpty == true
            ? ecole.paramecole
            : ecole.ecolecode,
        classeId: eleve.classeid,
        classeName: eleve.classe,
      );
      await _updateNotificationTokenWithNewMatricule(
        parentId,
        eleve.matriculeEleve,
      );
      final success = await apiService.addChild(parentId, newChild);
      print('🔍 DEBUG: API service addChild result: $success');
      setState(() => _isLoading = false);
      if (success && mounted) {
        print('✅ DEBUG: Child added successfully');
        _showSnackbar('Élève ajouté avec succès');
        Navigator.of(context).pop(true); // Retourner au HomeScreen avec résultat true
      } else if (mounted) {
        print('❌ DEBUG: Failed to add child via API');
        _showSnackbar('Erreur lors de l\'ajout', isError: true);
      }
    } catch (e) {
      print('💥 DEBUG: Exception in _handleAddChild: $e');
      setState(() => _isLoading = false);
      if (mounted) _showSnackbar('Erreur : $e', isError: true);
    }
  }

  // ─── HELPERS UI ────────────────────────────────────────────────────────────
  void _showSnackbar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: isError ? Colors.red[400] : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showDnsDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Erreur de connexion',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        content: const Text(
          'Impossible de joindre le serveur. Vérifiez votre connexion internet.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _loadEcoles();
            },
            child: Text(
              'Réessayer',
              style: TextStyle(
                color: AppColors.screenOrange,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showModalBottomSheet(
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
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 24,
                  offset: const Offset(0, -8),
                ),
              ],
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
                      color: AppColors.screenDivider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  'Comment trouver le matricule ?',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: _textSizeService.getScaledFontSize(17),
                    color: AppColors.screenTextPrimaryThemed(context),
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Le matricule se trouve sur :',
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
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.screenTextPrimary,
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
        backgroundColor: AppColors.screenSurface,
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
          boxShadow: [
            BoxShadow(
              color: AppColors.screenShadowThemed(context),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
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
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 24,
                  offset: const Offset(0, -8),
                ),
              ],
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
                    color: AppColors.screenDivider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _buildFoundStudentContent(),
                ),
              ],
            ),
          ),
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
                    color: Colors.black,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Entrez le matricule scolaire pour retrouver votre enfant',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: _textSizeService.getScaledFontSize(12),
                    color: Colors.black,
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
      // decoration: BoxDecoration(
      //   color: AppColors.screenCard,
      //   borderRadius: BorderRadius.circular(24),
      //   boxShadow: const [
      //     BoxShadow(
      //       color: AppColors.screenShadow,
      //       blurRadius: 16,
      //       offset: Offset(0, 4),
      //     ),
      //   ],
      // ),
      child: Column(
        children: [
          // Header du panneau
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
                    color: AppColors.screenTextPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),

          // Formulaire
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 12, 0, 20),
            child: Column(
              children: [
                // Champ école
                _buildEcoleField(),
                const SizedBox(height: 14),
                // Champ matricule
                _buildMatriculeField(),
                // Message erreur
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  _buildErrorBanner(),
                ],
                const SizedBox(height: 20),
                // Bouton rechercher
                _buildOrangeButton(
                  label: _isSearching
                      ? 'Recherche en cours...'
                      : 'Rechercher mon enfant',
                  onTap: _isSearching ? null : _searchEleve,
                  isLoading: _isSearching,
                  icon: Icons.search_rounded,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── ÉCOLE FIELD ───────────────────────────────────────────────────────────
  Widget _buildEcoleField() {
    if (_isLoadingEcoles) {
      return _buildLoadingField('Chargement des écoles...');
    }
    if (_ecoles.isEmpty) {
      return Column(
        children: [
          _buildEmptyEcoleField(),
          const SizedBox(height: 10),
          _buildRecommendSchoolButton(),
          if (_errorMessage != null) ...[
            const SizedBox(height: 10),
            _buildRetryButton(),
          ],
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel('École', required: true),
        const SizedBox(height: 6),
        SearchableDropdown(
          label: 'École',
          value: _selectedEcoleName ?? 'Sélectionner une école...',
          items: _ecoles.map((e) => e.ecoleclibelle).toList(),
          onChanged: (String selected) {
            final ecole = _ecoles.firstWhere(
              (e) => e.ecoleclibelle == selected,
            );
            setState(() {
              _selectedEcoleId = ecole.ecoleid;
              _selectedEcoleName = selected;
              _foundEleve = null;
              _foundEcole = null;
              _errorMessage = null;
            });
          },
          isDarkMode: false,
        ),
      ],
    );
  }

  Widget _buildLoadingField(String msg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.screenSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.screenDivider),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.screenOrange,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            msg,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.screenTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyEcoleField() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[400], size: 18),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Aucune école disponible',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.screenTextPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRetryButton() {
    return GestureDetector(
      onTap: _loadEcoles,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.screenOrangeLight,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.refresh_rounded,
              color: AppColors.screenOrange,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              'Réessayer',
              style: TextStyle(
                color: AppColors.screenOrange,
                fontWeight: FontWeight.w700,
                fontSize: _textSizeService.getScaledFontSize(13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendSchoolButton() {
    return GestureDetector(
      onTap: _showRecommendationBottomSheet,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.screenOrangeLight,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.recommend_rounded,
              color: AppColors.screenOrange,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              'Recommander une école',
              style: TextStyle(
                color: AppColors.screenOrange,
                fontWeight: FontWeight.w700,
                fontSize: _textSizeService.getScaledFontSize(13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── MATRICULE FIELD ───────────────────────────────────────────────────────
  Widget _buildMatriculeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel('Matricule de l\'élève', required: true),
        const SizedBox(height: 6),
        Container(
          child: TextField(
            controller: _matriculeController,
            autofocus: false,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.screenTextPrimary,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: 'Ex: 24047355B',
              hintStyle: const TextStyle(
                fontSize: 13,
                color: Color(0xFFBBBBBB),
              ),
              prefixIcon: const Icon(
                Icons.badge_outlined,
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
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.screenDivider),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.screenDivider),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.screenOrange,
                  width: 1.5,
                ),
              ),
            ),
            onSubmitted: (_) => _searchEleve(),
          ),
        ),
      ],
    );
  }

  Widget _fieldLabel(String label, {bool required = false}) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.screenTextSecondary,
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
  Widget _buildFoundStudentContent() {
    final eleve = _foundEleve!;
    final ecole = _foundEcole!;

    return Column(
      children: [
        Row(
          children: [
            Hero(
              tag: 'student_photo_${eleve.matriculeEleve}',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  width: 56,
                  height: 56,
                  color: AppColors.screenSurface,
                  child: eleve.urlPhoto != null && eleve.urlPhoto!.isNotEmpty
                      ? Image.network(
                          eleve.urlPhoto!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.person,
                            color: AppColors.screenTextSecondary,
                            size: 28,
                          ),
                          loadingBuilder: (_, child, progress) =>
                              progress == null
                              ? child
                              : const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.screenOrange,
                                  ),
                                ),
                        )
                      : const Icon(
                          Icons.person,
                          color: AppColors.screenTextSecondary,
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
                    eleve.nomEleve ?? 'Nom inconnu',
                    style: TextStyle(
                      fontSize: _textSizeService.getScaledFontSize(16),
                      fontWeight: FontWeight.w800,
                      color: AppColors.screenTextPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    eleve.prenomEleve ?? 'Prénom inconnu',
                    style: TextStyle(
                      fontSize: _textSizeService.getScaledFontSize(13),
                      color: AppColors.screenTextSecondary,
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
                          color: AppColors.screenSurface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.screenDivider.withOpacity(0.8),
                          ),
                        ),
                        child: Text(
                          eleve.classe.isNotEmpty
                              ? eleve.classe
                              : 'Classe inconnue',
                          style: TextStyle(
                            fontSize: _textSizeService.getScaledFontSize(11),
                            color: AppColors.screenTextSecondary,
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
        const Divider(color: AppColors.screenDivider, height: 1),
        const SizedBox(height: 12),
        _infoRow(Icons.school_outlined, 'École', ecole.ecoleclibelle),
        const SizedBox(height: 10),
        _infoRow(Icons.badge_outlined, 'Matricule', eleve.matriculeEleve),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: _isLoading ? null : () {
              print('🔘 ELEVATED BUTTON PRESSED!');
              _handleAddChild();
            },
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
                      const Icon(Icons.person_add_rounded, color: Colors.white, size: 18),
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

  Widget _buildFoundStudentCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.screenCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.screenDivider.withOpacity(0.6)),
        boxShadow: const [
          BoxShadow(
            color: AppColors.screenShadow,
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: _buildFoundStudentContent(),
      ),
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
              color: AppColors.screenSurface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.screenDivider.withOpacity(0.8),
              ),
            ),
            child: Icon(icon, color: AppColors.screenTextSecondary, size: 15),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$label : $value',
              style: TextStyle(
                fontSize: _textSizeService.getScaledFontSize(13),
                fontWeight: FontWeight.w600,
                color: AppColors.screenTextPrimary,
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
        // boxShadow: [
        //   BoxShadow(
        //     color: (shadowColor ?? color).withOpacity(0.3),
        //     blurRadius: 14,
        //     offset: const Offset(0, 5),
        //   ),
        // ],
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

  // ─── NOTIFICATION TOKEN UPDATE ────────────────────────────────────────────
  Future<void> _updateNotificationTokenWithNewMatricule(
    String userId,
    String newMatricule,
  ) async {
    try {
      final notificationService = NotificationService();
      final token = await notificationService.getTokenAsync();
      if (token == null || token.isEmpty) return;
      final childrenInfo = await DatabaseService.instance
          .getChildrenInfoByParent(userId);
      final matricules = childrenInfo
          .map((info) => info['matricule'] as String?)
          .where((m) => m != null && m.isNotEmpty)
          .cast<String>()
          .toList();
      if (matricules.isEmpty) return;
      final deviceType = Platform.isIOS ? 'ios' : 'android';
      await PoulsScolaireApiService().registerNotificationToken(
        token,
        userId,
        deviceType: deviceType,
        matricules: matricules,
      );
    } catch (_) {}
  }
}
