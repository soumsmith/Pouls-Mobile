import 'dart:io';
import 'package:flutter/material.dart';
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
import '../widgets/custom_button.dart';
import '../widgets/searchable_dropdown.dart';
import '../widgets/back_button_widget.dart';
import 'login_screen.dart';

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
  final ThemeService _themeService = ThemeService();
  final TextSizeService _textSizeService = TextSizeService();
  
  bool _isLoading = false;
  bool _isSearching = false;
  bool _isLoadingEcoles = false;
  Eleve? _foundEleve;
  Ecole? _foundEcole;
  String? _errorMessage;
  
  List<Ecole> _ecoles = [];
  int? _selectedEcoleId;
  String? _selectedEcoleName;
  final TextEditingController _ecoleSearchController = TextEditingController();
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _loadEcoles();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _matriculeController.dispose();
    _ecoleSearchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadEcoles() async {
    setState(() {
      _isLoadingEcoles = true;
      _errorMessage = null;
    });
    
    print('🔄 Début du chargement des écoles...');
    
    try {
      final ecoles = await _poulsApiService.getAllEcoles();
      print('✅ ${ecoles.length} école(s) chargée(s) avec succès');
      
      setState(() {
        _ecoles = ecoles;
        _isLoadingEcoles = false;
        // Ne pas initialiser _selectedEcoleId - le champ doit rester vide
      });
      
      if (ecoles.isEmpty) {
        print('⚠️ Aucune école trouvée');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Aucune école disponible'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Erreur lors du chargement des écoles: $e');
      print('Stack trace: ${StackTrace.current}');
      
      setState(() {
        _isLoadingEcoles = false;
        _errorMessage = 'Erreur lors du chargement des écoles. Appuyez sur "Réessayer" pour recharger.';
      });
      
      if (mounted) {
        // Afficher un message d'erreur plus détaillé dans une dialog
        final errorMessage = e.toString();
        final isDnsError = errorMessage.contains('Failed host lookup') || 
                          errorMessage.contains('No address associated');
        
        if (isDnsError) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Erreur de connexion'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Impossible de se connecter au serveur. Le nom de domaine ne peut pas être résolu.',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    const Text('Solutions possibles :'),
                    const SizedBox(height: 8),
                    const Text('1. Vérifiez votre connexion internet'),
                    const Text('2. Si vous êtes sur un émulateur, vérifiez qu\'il a accès à internet'),
                    const Text('3. Testez l\'URL dans un navigateur :'),
                    const SizedBox(height: 4),
                    SelectableText(
                      'https://api-pro.pouls-scolaire.net/api/connecte/ecole',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('4. Vérifiez que le nom de domaine est correct'),
                    const Text('5. Vérifiez les paramètres DNS de votre réseau'),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Fermer'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _loadEcoles();
                  },
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: ${e.toString()}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'Réessayer',
                textColor: Colors.white,
                onPressed: () {
                  _loadEcoles();
                },
              ),
            ),
          );
        }
      }
    }
  }

  Future<void> _searchEleve() async {
    if (_matriculeController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Veuillez entrer un matricule';
      });
      return;
    }

    if (_selectedEcoleId == null) {
      setState(() {
        _errorMessage = 'Veuillez sélectionner une école';
      });
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
      print('🔍 ===== RECHERCHE D\'ÉLÈVE =====');
      print('📝 Matricule recherché: $matricule');
      print('🏫 École ID: $_selectedEcoleId');
      
      // Charger l'année scolaire ouverte
      final anneeScolaire = await _poulsApiService.getAnneeScolaireOuverte(_selectedEcoleId!);
      final idAnnee = anneeScolaire.anneeOuverteCentraleId;
      
      print('📅 Identifiant de l\'année scolaire récupéré: $idAnnee');

      // Vérifier que l'année scolaire est valide
      if (idAnnee == 0 || anneeScolaire.anneeEcoleList.isEmpty) {
        print('❌ Aucune année scolaire ouverte trouvée');
        setState(() {
          _errorMessage = 'Aucune année scolaire ouverte trouvée pour cette école';
          _isSearching = false;
        });
        return;
      }

      // Rechercher l'élève par matricule
      print('🔎 Appel de findEleveByMatricule avec:');
      print('   - École ID: $_selectedEcoleId');
      print('   - Année ID: $idAnnee');
      print('   - Matricule: $matricule');
      
      final eleve = await _poulsApiService.findEleveByMatricule(
        _selectedEcoleId!,
        idAnnee,
        matricule,
      );

      if (eleve != null) {
        // Trouver l'école correspondante
        final ecole = _ecoles.firstWhere(
          (e) => e.ecoleid == _selectedEcoleId,
          orElse: () => _ecoles.first,
        );

        print('✅ ===== ÉLÈVE SÉLECTIONNÉ =====');
        print('👤 Informations de l\'élève sélectionné:');
        print('   - Matricule: ${eleve.matriculeEleve}');
        print('   - Nom complet: ${eleve.fullName}');
        print('   - Nom: ${eleve.nomEleve}');
        print('   - Prénom: ${eleve.prenomEleve}');
        print('   - Classe ID (classeid): ${eleve.classeid}');
        print('   - Classe (libellé): ${eleve.classe}');
        print('   - École ID: ${ecole.ecoleid}');
        print('   - École: ${ecole.ecoleclibelle}');
        print('   - Année ID utilisée: $idAnnee');
        print('================================');

        setState(() {
          _foundEleve = eleve;
          _foundEcole = ecole;
          _isSearching = false;
        });
      } else {
        print('❌ Aucun élève trouvé avec le matricule: $matricule');
        setState(() {
          _errorMessage = 'Aucun élève trouvé avec ce matricule';
          _isSearching = false;
        });
      }
    } catch (e) {
      String errorMsg = 'Erreur lors de la recherche';
      if (e.toString().contains('année scolaire')) {
        errorMsg = 'Impossible de récupérer l\'année scolaire pour cette école. Veuillez réessayer ou contacter le support.';
      } else if (e.toString().contains('timeout')) {
        errorMsg = 'La requête a pris trop de temps. Vérifiez votre connexion internet.';
      } else {
        errorMsg = 'Erreur lors de la recherche: ${e.toString().split(':').last.trim()}';
      }
      
      setState(() {
        _errorMessage = errorMsg;
        _isSearching = false;
      });
      
      // Log pour le débogage
      print('Erreur recherche élève: $e');
    }
  }

  Future<void> _handleAddChild() async {
    if (_foundEleve == null || _foundEcole == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur: Informations de l\'élève manquantes'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Stocker les valeurs localement pour éviter les problèmes de null
    final eleve = _foundEleve!;
    final ecole = _foundEcole!;

    setState(() {
      _isLoading = true;
    });

    try {
      // Récupérer l'utilisateur actuel depuis AuthService avec vérification supplémentaire
      User? currentUser = AuthService.instance.getCurrentUser();
      
      // Si aucun utilisateur n'est trouvé, essayer de recharger la session
      if (currentUser == null) {
        print('⚠️ Aucun utilisateur trouvé, tentative de rechargement de la session...');
        await AuthService.instance.loadSavedSession();
        currentUser = AuthService.instance.getCurrentUser();
        
        if (currentUser == null) {
          print('❌ Échec du chargement de la session, redirection vers la connexion...');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Session expirée. Veuillez vous reconnecter.'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 3),
              ),
            );
            // Rediriger vers l'écran de connexion
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const LoginScreen()),
              (route) => false,
            );
          }
          return;
        }
      }
      
      final parentId = currentUser.id;
      print('✅ Utilisateur trouvé: ${currentUser.firstName} ${currentUser.lastName} (ID: $parentId)');
      
      // Créer le service API directement
      final apiService = AppConfig.MOCK_MODE
          ? MockApiService()
          : RemoteApiService();

      // Vérifier que les valeurs nécessaires ne sont pas vides
      if (eleve.prenomEleve.isEmpty || eleve.nomEleve.isEmpty) {
        throw Exception('Les informations de l\'élève sont incomplètes');
      }

      final newChild = Child(
        id: eleve.inscriptionsidEleve.toString(),
        firstName: eleve.prenomEleve,
        lastName: eleve.nomEleve,
        establishment: ecole.ecoleclibelle.isNotEmpty 
            ? ecole.ecoleclibelle 
            : 'École non spécifiée',
        grade: eleve.classe.isNotEmpty 
            ? eleve.classe 
            : 'Classe non spécifiée',
        photoUrl: eleve.urlPhoto,
        parentId: parentId,
      );

      // Vérifier et logger les valeurs avant sauvegarde
      print('📝 Sauvegarde de l\'élève:');
      print('   - Matricule: ${eleve.matriculeEleve}');
      print('   - Ecole ID: ${ecole.ecoleid}');
      print('   - Classe ID (classeid): ${eleve.classeid}');
      print('   - Classe Name: ${eleve.classe}');
      print('   - Photo URL: ${eleve.urlPhoto ?? "null"}');
      
      if (eleve.classeid == null || eleve.classeid == 0) {
        print('⚠️ ATTENTION: classeid est null ou 0!');
      }
      
      if (eleve.urlPhoto == null || eleve.urlPhoto!.isEmpty) {
        print('⚠️ ATTENTION: urlPhoto est null ou vide!');
      }
      
      // Sauvegarder l'enfant dans la base de données locale
      await DatabaseService.instance.saveChild(
        newChild,
        matricule: eleve.matriculeEleve,
        ecoleId: ecole.ecoleid,
        ecoleName: ecole.ecoleclibelle,
        classeId: eleve.classeid,
        classeName: eleve.classe,
      );
      
      print('✅ Enfant sauvegardé avec classeId: ${eleve.classeid}');

      // Associer le matricule au token FCM et réenregistrer le token
      await _updateNotificationTokenWithNewMatricule(parentId, eleve.matriculeEleve);

      // Ajouter l'enfant via l'API
      final success = await apiService.addChild(parentId, newChild);

      setState(() {
        _isLoading = false;
      });

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Élève ajouté avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true); // Retour avec succès
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de l\'ajout de l\'élève'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = _themeService.isDarkMode;
    
    return AnimatedBuilder(
      animation: Listenable.merge([_themeService, _textSizeService]),
      builder: (context, child) {
        return Scaffold(
          backgroundColor: AppColors.getPureBackground(isDarkMode),
          body: CustomScrollView(
            slivers: [
              _buildSliverAppBar(),
              SliverToBoxAdapter(
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildWelcomeSection(),
                                const SizedBox(height: 32),
                                _buildSearchForm(),
                                if (_foundEleve != null && _foundEcole != null) ...[
                                  const SizedBox(height: 24),
                                  _buildFoundStudentCard(),
                                ],
                                //const SizedBox(height: 24),
                                //_buildInfoCard(),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSliverAppBar() {
    final theme = Theme.of(context);
    final isDarkMode = _themeService.isDarkMode;
    
    return SliverAppBar(
      expandedHeight: 20,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.getPureAppBarBackground(isDarkMode),
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'Ajouter un élève',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: _textSizeService.getScaledFontSize(20),
          ),
        ),
        titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
      ),
      leading: const BackButtonWidget(),
      actions: [
        IconButton(
          icon: Icon(Icons.help_outline, color: theme.iconTheme.color),
          onPressed: () {
            _showHelpDialog();
          },
        ),
      ],
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.successGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.success.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.9),
            ),
            child: Icon(
              Icons.person_add,
              size: 25,
              color: AppColors.success,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ajouter votre enfant',
                  style: TextStyle(
                    fontSize: _textSizeService.getScaledFontSize(20),
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Retrouvez facilement votre enfant en entrant son matricule scolaire',
                  style: TextStyle(
                    fontSize: _textSizeService.getScaledFontSize(13),
                    color: Colors.white70,
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

  Widget _buildSearchForm() {
    final isDarkMode = _themeService.isDarkMode;
    
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.getSurfaceColor(isDarkMode),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.3),
          width: 0,
        ),
        // boxShadow: [
        //   BoxShadow(
        //     color: Colors.black.withOpacity(0.3),
        //     blurRadius: 15,
        //     offset: const Offset(0, 4),
        //   ),
        // ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Recherche',
            style: TextStyle(
              fontSize: _textSizeService.getScaledFontSize(20),
              fontWeight: FontWeight.bold,
              color: AppColors.getTextColor(isDarkMode),
            ),
          ),
          const SizedBox(height: 20),
          _buildSchoolField(),
          const SizedBox(height: 20),
          _buildMatriculeField(),
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            _buildErrorMessage(),
          ],
          const SizedBox(height: 24),
          CustomButton(
            text: _isSearching ? 'Recherche en cours...' : 'Rechercher mon enfant',
            onPressed: _isSearching ? null : () => _searchEleve(),
            isLoading: _isSearching,
          ),
        ],
      ),
    );
  }

  Widget _buildSchoolField() {
    final isDarkMode = _themeService.isDarkMode;
    
    if (_isLoadingEcoles) {
      return Container(
        decoration: BoxDecoration(
          color: AppColors.getSurfaceColor(isDarkMode),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.getBorderColor(isDarkMode),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(
              Icons.school,
              color: AppColors.getTextColor(isDarkMode, type: TextType.secondary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Chargement des écoles...',
                style: TextStyle(
                  color: AppColors.getTextColor(isDarkMode, type: TextType.secondary),
                ),
              ),
            ),
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    if (_ecoles.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SearchableDropdown(
            label: 'École *',
            value: _errorMessage ?? 'Aucune école disponible',
            items: ['Aucune école disponible'],
            onChanged: (String value) {},
            isDarkMode: isDarkMode,
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _loadEcoles,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ],
      );
    }
    
    // Préparer la liste des noms d'écoles pour le SearchableDropdown
    final ecoleNames = _ecoles.map((ecole) => ecole.ecoleclibelle).toList();
    
    return SearchableDropdown(
      label: 'École *',
      value: _selectedEcoleName ?? 'Sélectionner une école...',
      items: ecoleNames,
      onChanged: (String selectedName) {
        // Trouver l'école correspondante par nom
        final selectedEcole = _ecoles.firstWhere(
          (ecole) => ecole.ecoleclibelle == selectedName,
        );
        
        setState(() {
          _selectedEcoleId = selectedEcole.ecoleid;
          _selectedEcoleName = selectedName;
          _foundEleve = null;
          _foundEcole = null;
          _errorMessage = null;
        });
      },
      isDarkMode: isDarkMode,
    );
  }

  Widget _buildMatriculeField() {
    final isDarkMode = _themeService.isDarkMode;
    
    return Container(
      decoration: BoxDecoration(
        color: AppColors.getSurfaceColor(isDarkMode),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.getBorderColor(isDarkMode),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'MATRICULE DE L\'ÉLÈVE *',
            style: TextStyle(
              color: AppColors.getTextColor(isDarkMode, type: TextType.secondary),
              fontSize: _textSizeService.getScaledFontSize(11),
            ),
          ),
          const SizedBox(height: 4),
          TextFormField(
            controller: _matriculeController,
            decoration: const InputDecoration(
              hintText: 'Ex: 24047355B',
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              isDense: true,
            ),
            style: TextStyle(
              fontSize: _textSizeService.getScaledFontSize(12),
              fontWeight: FontWeight.w500,
              color: AppColors.getTextColor(isDarkMode),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez entrer le matricule';
              }
              return null;
            },
            autofocus: true,
            onFieldSubmitted: (_) => _searchEleve(),
          ),
          // const SizedBox(height: 4),
          // Text(
          //   'Vous trouverez ce numéro sur les documents scolaires',
          //   style: TextStyle(
          //     fontSize: 10,
          //     color: AppColors.getTextColor(isDarkMode, type: TextType.secondary).withOpacity(0.8),
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage() {
    final isDarkMode = _themeService.isDarkMode;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.toSurface(),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.error.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: AppColors.error,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(
                fontSize: _textSizeService.getScaledFontSize(14),
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFoundStudentCard() {
    final theme = Theme.of(context);
    final eleve = _foundEleve!;
    final ecole = _foundEcole!;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(15),
        // boxShadow: [
        //   BoxShadow(
        //     color: isDarkMode 
        //         ? AppColors.black.withOpacity(0.4)
        //         : AppColors.primary.withOpacity(0.15),
        //     blurRadius: 20,
        //     offset: const Offset(0, 8),
        //   ),
        //   BoxShadow(
        //     color: isDarkMode 
        //         ? AppColors.black.withOpacity(0.2)
        //         : AppColors.shadowLight,
        //     blurRadius: 10,
        //     offset: const Offset(0, 2),
        //   ),
        // ],
      ),
      child: Column(
        children: [
          // Header avec succès
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.green.shade50,
                  Colors.green.shade100,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Row(
              //mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.green,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Élève trouvé !',
                  style: TextStyle(
                    fontSize: _textSizeService.getScaledFontSize(17),
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
          
          // Contenu principal
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Photo et informations principales
                Row(
                  children: [
                    // Photo de profil
                    Hero(
                      tag: 'student_photo_${eleve.matriculeEleve}',
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppColors.primaryGradient,
                        ),
                        child: ClipOval(
                          child: eleve.urlPhoto != null && eleve.urlPhoto!.isNotEmpty
                              ? Image.network(
                                  eleve.urlPhoto!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: theme.dividerColor,
                                      child: Icon(
                                        Icons.person,
                                        size: 40,
                                        color: theme.iconTheme.color?.withOpacity(0.6),
                                      ),
                                    );
                                  },
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 3,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          theme.primaryColor,
                                        ),
                                      ),
                                    );
                                  },
                                )
                              : Icon(
                                  Icons.person,
                                  size: 40,
                                  color: Colors.white,
                                ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // Informations principales
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                eleve.nomEleve ?? 'Nom inconnu',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: _textSizeService.getScaledFontSize(20),
                                ),
                              ),
                              Text(
                                eleve.prenomEleve ?? 'Prénom inconnu',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: theme.textTheme.titleMedium?.color?.withOpacity(0.8),
                                  fontSize: _textSizeService.getScaledFontSize(16),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Informations détaillées compactes
                _buildCompactInfoRow(Icons.school, 'École', ecole.ecoleclibelle),
                const SizedBox(height: 8),
                _buildCompactInfoRow(Icons.class_, 'Classe', eleve.classe),
                const SizedBox(height: 8),
                _buildCompactInfoRow(Icons.badge, 'Matricule', eleve.matriculeEleve),
                
                const SizedBox(height: 20),
                
                // Bouton d'action
                Container(
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.green.shade400,
                        Colors.green.shade700,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: _isLoading ? null : _handleAddChild,
                      child: Center(
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text(
                                'Ajouter cet élève à mon compte',
                                style: TextStyle(
                                  fontSize: _textSizeService.getScaledFontSize(16),
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactInfoRow(IconData icon, String label, String value) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: theme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon, 
              size: 16, 
              color: theme.primaryColor,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '$label:',
            style: TextStyle(
              fontSize: _textSizeService.getScaledFontSize(12),
              fontWeight: FontWeight.w600,
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: _textSizeService.getScaledFontSize(14),
                fontWeight: FontWeight.w500,
                color: theme.textTheme.bodyMedium?.color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentInfoRow(IconData icon, String label, String value) {
    final isDarkMode = _themeService.isDarkMode;
    
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDarkMode 
                ? const Color(0xFF4F46E5).withOpacity(0.1)
                : const Color(0xFF4F46E5).withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon, 
            size: 20, 
            color: isDarkMode ? const Color(0xFF4F46E5) : const Color(0xFF4F46E5),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '$label:',
          style: TextStyle(
            fontSize: _textSizeService.getScaledFontSize(14),
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.grey[300] : const Color(0xFF6B7280),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: _textSizeService.getScaledFontSize(14),
              fontWeight: FontWeight.w500,
              color: isDarkMode ? Colors.grey[100] : const Color(0xFF374151),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard() {
    final isDarkMode = _themeService.isDarkMode;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode 
            ? const Color(0xFF4F46E5).withOpacity(0.1)
            : const Color(0xFF4F46E5).withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode 
              ? const Color(0xFF4F46E5).withOpacity(0.3)
              : const Color(0xFF4F46E5).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDarkMode 
                  ? const Color(0xFF4F46E5).withOpacity(0.2)
                  : const Color(0xFF4F46E5).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.info_outline,
              color: isDarkMode ? const Color(0xFF4F46E5) : const Color(0xFF4F46E5),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Besoin d\'aide ?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.white : const Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Le matricule se trouve sur les documents scolaires de votre enfant',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDarkMode ? Colors.grey[300] : const Color(0xFF6B7280),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    final isDarkMode = _themeService.isDarkMode;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Comment trouver le matricule ?'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Le matricule de votre enfant se trouve généralement sur :',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildHelpItem('📄', 'Carnet de correspondance'),
              _buildHelpItem('🎓', 'Bulletin scolaire'),
              _buildHelpItem('📝', 'Carte d\'élève'),
              _buildHelpItem('💻', 'Portail en ligne de l\'école'),
              const SizedBox(height: 16),
              const Text(
                'Le matricule est généralement composé de chiffres et parfois de lettres.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Compris'),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  /// Met à jour le token de notification avec le nouveau matricule
  Future<void> _updateNotificationTokenWithNewMatricule(String userId, String newMatricule) async {
    try {
      print('🔄 Mise à jour du token de notification avec le nouveau matricule: $newMatricule');
      
      final notificationService = NotificationService();
      
      // Obtenir le token de manière asynchrone (récupère depuis Firebase si nécessaire)
      final token = await notificationService.getTokenAsync();
      
      if (token == null || token.isEmpty) {
        print('⚠️ Aucun token FCM disponible actuellement.');
        print('   Le matricule sera associé au token lors de la prochaine initialisation des notifications.');
        print('   Ou lorsque le token FCM sera disponible.');
        // Ne pas bloquer l'ajout de l'élève si le token n'est pas disponible
        // Le token sera mis à jour lors de la prochaine initialisation
        return;
      }
      
      // Récupérer tous les matricules de l'utilisateur (y compris le nouveau)
      final databaseService = DatabaseService.instance;
      final childrenInfo = await databaseService.getChildrenInfoByParent(userId);
      
      // Extraire les matricules non null
      final matricules = childrenInfo
          .map((info) => info['matricule'] as String?)
          .where((matricule) => matricule != null && matricule.isNotEmpty)
          .cast<String>()
          .toList();
      
      if (matricules.isEmpty) {
        print('⚠️ Aucun matricule trouvé pour l\'utilisateur');
        return;
      }
      
      print('📋 Matricules à associer au token: ${matricules.length}');
      for (final matricule in matricules) {
        print('   - $matricule');
      }
      
      // Déterminer le type d'appareil
      final deviceType = Platform.isIOS ? 'ios' : 'android';
      
      // Réenregistrer le token avec tous les matricules
      final apiService = PoulsScolaireApiService();
      final success = await apiService.registerNotificationToken(
        token,
        userId,
        deviceType: deviceType,
        matricules: matricules,
      );
      
      if (success) {
        print('✅ Token de notification mis à jour avec succès avec ${matricules.length} matricule(s)');
      } else {
        print('❌ Erreur lors de la mise à jour du token de notification');
      }
    } catch (e) {
      print('❌ Erreur lors de la mise à jour du token de notification: $e');
      // Ne pas bloquer l'ajout de l'élève si la mise à jour du token échoue
    }
  }
}
