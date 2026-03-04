import 'package:flutter/material.dart';
import '../models/child.dart';
import '../models/note.dart';
import '../models/note_api.dart';
import '../models/matiere.dart';
import '../models/periode.dart';
import '../models/annee_scolaire.dart';
import '../models/timetable_entry.dart';
import '../models/message.dart';
import '../models/fee.dart';
import '../services/api_service.dart';
import '../services/pouls_scolaire_api_service.dart';
import '../services/database_service.dart';
import '../services/theme_service.dart';
import '../services/text_size_service.dart';
import '../config/app_colors.dart';
import '../widgets/main_screen_wrapper.dart';
import '../screens/notes_screen_json.dart';
import '../screens/student_timetable_screen.dart';
import '../screens/student_messages_screen.dart';
import '../screens/student_scolarite_screen.dart';
import '../screens/shop_screen.dart';
import '../screens/student_access_control_screen.dart';
import '../screens/access_log_screen.dart';
import '../screens/parent_suggestion_screen.dart';
import '../screens/place_reservation_screen.dart';
import '../screens/student_detail_screen.dart';
import '../services/school_service.dart';
import '../models/school_supply.dart';
import '../services/school_supply_service.dart';
import '../services/paiement_service.dart';

/// Écran de détail d'un enfant avec onglets
class ChildListScreen extends StatefulWidget {
  final Child child;

  const ChildListScreen({
    super.key,
    required this.child,
  });

  @override
  State<ChildListScreen> createState() => _ChildListScreenState();
}

class _ChildListScreenState extends State<ChildListScreen>
    with TickerProviderStateMixin implements MainScreenChild {
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  List<Note> _notes = [];
  List<TimetableEntry> _timetable = [];
  List<Message> _messages = [];
  List<Fee> _fees = [];
  List<SchoolSupply> _schoolSupplies = [];
  bool _isLoading = true;
  bool _isLoadingSupplies = false;
  final ThemeService _themeService = ThemeService();
  final TextSizeService _textSizeService = TextSizeService();
  final SchoolSupplyService _schoolSupplyService = SchoolSupplyService();
  final PaiementService _paiementService = PaiementService();
  
  // Variables pour les données de notes globales
  GlobalAverage? _globalAverage;
  bool _isLoadingNotes = false;
  final PoulsScolaireApiService _poulsApiService = PoulsScolaireApiService();
  
  // Informations de l'enfant pour l'API
  int? _ecoleId;
  String? _ecoleCode;
  int? _classeId;
  String? _matricule;
  int? _anneeId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 16, vsync: this);
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
    
    _tabController.addListener(() {
      setState(() {});
    });
    
    _loadData();
    _animationController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadGlobalNotesData() async {
    print('📊 Chargement des notes globales - DÉMARRAGE');
    
    if (_ecoleId == null || _classeId == null || _matricule == null || _anneeId == null) {
      print('⚠️ Impossible de charger les notes: informations manquantes');
      print('   ecoleId: $_ecoleId, classeId: $_classeId, matricule: $_matricule, anneeId: $_anneeId');
      setState(() {
        _isLoadingNotes = false;
      });
      return;
    }
    
    setState(() {
      _isLoadingNotes = true;
    });
    
    try {
      // Récupérer les périodes
      final periodes = await _poulsApiService.getAllPeriodes();
      if (periodes.isEmpty) {
        print('⚠️ Aucune période disponible');
        setState(() {
          _isLoadingNotes = false;
        });
        return;
      }
      
      // Utiliser la première période (Trimestre 1) par défaut
      final periodeId = periodes.first.id;
      print('📅 Utilisation de la période: ${periodes.first.libelle} (ID: $periodeId)');
      
      // Charger les notes depuis l'API
      print('🔄 Appel API avec:');
      print('   anneeId: $_anneeId');
      print('   classeId: $_classeId');
      print('   periodeId: $periodeId');
      print('   matricule: $_matricule');
      
      final notesResult = await _poulsApiService.getNotesByEleveMatricule(
        _anneeId!,
        _classeId!,
        periodeId,
        _matricule!,
      );
      
      print('✅ Notes reçues de l\'API:');
      print('   📝 Nombre de notes: ${notesResult.notes.length}');
      print('   📊 Moyenne globale: ${notesResult.moyenneGlobale ?? "N/A"}');
      print('   🏆 Rang global: ${notesResult.rangGlobal ?? "N/A"}');
      
      setState(() {
        _globalAverage = GlobalAverage(
          trimesterAverage: notesResult.moyenneGlobale ?? 0.0,
          trimesterRank: notesResult.rangGlobal ?? 0,
          trimesterMention: _getMention(notesResult.moyenneGlobale ?? 0.0),
          annualAverage: 0.0,
          annualRank: 0,
          annualMention: '',
        );
        _isLoadingNotes = false;
      });
      
      print('✅ DONNÉES APPLIQUÉES:');
      print('   📊 Moyenne: ${_globalAverage!.trimesterAverage}');
      print('   🏆 Rang: ${_globalAverage!.trimesterRank}');
      print('   🎖️ Mention: ${_globalAverage!.trimesterMention}');
      
    } catch (e) {
      print('❌ Erreur lors du chargement des notes: $e');
      print('Stack trace: ${StackTrace.current}');
      setState(() {
        _isLoadingNotes = false;
      });
    }
  }

  String _getMention(double moyenne) {
    if (moyenne >= 16) return 'Très Bien';
    if (moyenne >= 14) return 'Bien';
    if (moyenne >= 12) return 'Assez Bien';
    if (moyenne >= 10) return 'Passable';
    return 'Insuffisant';
  }

  String _getOrdinalSuffix(int number) {
    if (number == 1) return 'er';
    return 'ème';
  }

  Future<void> _loadSchoolSupplies() async {
    if (_matricule == null) {
      print('⚠️ Impossible de charger les fournitures: matricule manquant');
      return;
    }

    setState(() {
      _isLoadingSupplies = true;
    });

    try {
      print('📚 Chargement des fournitures pour le matricule: $_matricule');
      final suppliesResponse = await _schoolSupplyService.getSchoolSupplies(_matricule!);
      
      setState(() {
        _schoolSupplies = suppliesResponse.data;
        _isLoadingSupplies = false;
      });
      
      print('✅ Fournitures chargées: ${_schoolSupplies.length} items');
    } catch (e) {
      print('❌ Erreur lors du chargement des fournitures: $e');
      setState(() {
        _isLoadingSupplies = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement des fournitures: $e')),
        );
      }
    }
  }

  Future<void> _loadData() async {
    print('📋 Début du chargement des données pour l\'enfant: ${widget.child.id}');
    setState(() {
      _isLoading = true;
    });

    try {
      final apiService = MainScreenWrapper.of(context).apiService;
      
      // Étape 1: Charger les informations de l'enfant d'abord
      print('📂 Étape 1: Récupération des informations de l\'enfant...');
      await _loadChildInfo();
      
      // Étape 2: Charger les autres données (timetable, messages, fees)
      print('📊 Étape 2: Chargement des données de base...');
      final results = await Future.wait([
        apiService.getNotesForChild(widget.child.id),
        apiService.getTimetableForChild(widget.child.id),
        apiService.getMessages(MainScreenWrapper.of(context).currentUserId ?? 'parent1'),
        apiService.getFeesForChild(widget.child.id),
      ]);

      setState(() {
        _notes = results[0] as List<Note>;
        _timetable = results[1] as List<TimetableEntry>;
        _messages = results[2] as List<Message>;
        _fees = results[3] as List<Fee>;
        _isLoading = false;
      });
      
      print('✅ Données de base chargées');
      print('   📝 Notes: ${_notes.length}');
      print('   📅 Timetable: ${_timetable.length}');
      print('   💬 Messages: ${_messages.length}');
      print('   💰 Fees: ${_fees.length}');
      
      // Étape 3: Charger les données de notes globales
      print('📊 Étape 3: Lancement du chargement des données de notes globales...');
      await _loadGlobalNotesData();
      
      // Étape 4: Charger les fournitures scolaires
      print('📚 Étape 4: Lancement du chargement des fournitures scolaires...');
      await _loadSchoolSupplies();
      
    } catch (e) {
      print('❌ Erreur lors du chargement des données: $e');
      print('Stack trace: ${StackTrace.current}');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _loadChildInfo() async {
    try {
      print('📂 Récupération des informations de l\'enfant depuis la base de données...');
      final childInfo = await DatabaseService.instance.getChildInfoById(widget.child.id);
      
      if (childInfo != null) {
        setState(() {
          _ecoleId = childInfo['ecoleId'] as int?;
          _ecoleCode = childInfo['ecoleCode'] as String?;
          _classeId = childInfo['classeId'] as int?;
          _matricule = childInfo['matricule'] as String?;
        });
        
        print('✅ Informations de l\'enfant récupérées:');
        print('   🏫 École ID: $_ecoleId');
        print('   🏫 École Code: $_ecoleCode');
        print('   📚 Classe ID: $_classeId');
        print('   🎫 Matricule: $_matricule');
        
        // Charger l'année scolaire ouverte
        if (_ecoleId != null) {
          try {
            final anneeScolaire = await _poulsApiService.getAnneeScolaireOuverte(_ecoleId!);
            setState(() {
              _anneeId = anneeScolaire.anneeOuverteCentraleId;
            });
            print('   📅 Année ID: $_anneeId');
          } catch (e) {
            print('❌ Erreur lors du chargement de l\'année scolaire: $e');
          }
        }
      } else {
        print('❌ Aucune information trouvée pour l\'enfant ${widget.child.id}');
      }
    } catch (e) {
      print('❌ Erreur lors du chargement des informations de l\'enfant: $e');
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
          body: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                _buildSliverAppBar(),
                SliverToBoxAdapter(
                  child: AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: Column(
                            children: [
                              _buildProfileHeader(),
                              _buildSummaryCards(),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  floating: false,
                  delegate: _CustomTabBarDelegate(
                    Container(
                      color: isDarkMode ? AppColors.pureBlack : AppColors.getSurfaceColor(isDarkMode),
                      child: _buildModernTabBar(),
                    ),
                  ),
                ),
              ];
            },
            body: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                    ),
                  )
                : Container(
                    color: isDarkMode ? AppColors.pureBlack : AppColors.getSurfaceColor(isDarkMode),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 100), // Marge pour éviter la bottom nav
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          NotesScreenJson(),
                          _buildBulletinsTab(),
                          StudentTimetableScreen(child: widget.child, ecoleCode: _ecoleCode),
                          _buildHomeworkTab(),
                          _buildAbsencesTab(),
                          StudentAccessControlScreen(child: widget.child),
                          _buildSanctionsTab(),
                          StudentMessagesScreen(child: widget.child),
                          StudentScolariteScreen(child: widget.child),
                          _buildDifficultiesTab(),
                          _buildEventsTab(),
                          _buildSuppliesTab(),
                          _buildOrdersTab(),
                          AccessLogScreen(childId: widget.child.id, childName: '${widget.child.firstName} ${widget.child.lastName}'),
                          ParentSuggestionScreen(parentId: 'current_parent'),
                          PlaceReservationScreen(parentId: 'current_parent'),
                        ],
                      ),
                    ),
                  ),
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
      forceElevated: false,
      surfaceTintColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          widget.child.fullName,
          style: TextStyle(
            color: theme.textTheme.titleLarge?.color,
            fontWeight: FontWeight.w600,
            fontSize: _textSizeService.getScaledFontSize(20),
          ),
        ),
        titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.notifications_outlined, color: theme.iconTheme.color),
          onPressed: () {},
        ),
        IconButton(
          icon: Icon(Icons.more_vert, color: theme.iconTheme.color),
          onPressed: () {},
        ),
      ],
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: theme.iconTheme.color),
        onPressed: () {
          if (MainScreenWrapper.maybeOf(context) != null) {
            MainScreenWrapper.of(context).navigateToHome();
          } else {
            Navigator.of(context).pop();
          }
        },
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      height: 180,
      decoration: BoxDecoration(
        gradient: AppColors.warningGradient,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.warning.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.primaryGradient,
                ),
                child: widget.child.photoUrl != null
                    ? ClipOval(
                        child: Image.network(
                          widget.child.photoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildDefaultAvatar();
                          },
                        ),
                      )
                    : _buildDefaultAvatar(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.child.fullName,
                      style: TextStyle(
                        fontSize: _textSizeService.getScaledFontSize(17),
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.child.grade,
                      style: TextStyle(
                        fontSize: _textSizeService.getScaledFontSize(13),
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.child.establishment,
                      style: TextStyle(
                        fontSize: _textSizeService.getScaledFontSize(13),
                        color: Colors.white60,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatusBadge('⭐ Excellent', AppColors.success),
              const SizedBox(width: 4),
              _buildStatusBadge('✔ Assidu', AppColors.primary),
              const SizedBox(width: 4),
              _buildStatusBadge('📈 Progression', AppColors.secondary),
            ],
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _showPaiementBottomSheet,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.payment_outlined,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Paiement',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: _textSizeService.getScaledFontSize(12),
                      fontWeight: FontWeight.w600,
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

  Widget _buildDefaultAvatar() {
    return const Icon(
      Icons.person,
      size: 30,
      color: Colors.white,
    );
  }

  Widget _buildStatusBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: _textSizeService.getScaledFontSize(10),
          fontWeight: FontWeight.w600,
          color: Color(0xFF333333),
        ),
      ),
    );
  }

  void _showPaiementBottomSheet() {
    final TextEditingController montantController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            bool isLoading = false;
            
            return Container(
              decoration: BoxDecoration(
                color: _themeService.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 20,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.payment,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Paiement en ligne',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: _themeService.isDarkMode ? Colors.white : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Entrez le montant à payer pour ${widget.child.firstName}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: _themeService.isDarkMode ? Colors.white70 : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: Icon(
                            Icons.close,
                            color: _themeService.isDarkMode ? Colors.white70 : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Montant à payer (FCFA)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _themeService.isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: montantController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'Ex: 10000',
                        prefixIcon: const Icon(Icons.attach_money),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.grey[300]!,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppColors.primary,
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: _themeService.isDarkMode 
                            ? Colors.grey[800] 
                            : Colors.grey[50],
                      ),
                      style: TextStyle(
                        fontSize: 16,
                        color: _themeService.isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : () => _effectuerPaiement(montantController.text, setState, () {
                          setState(() {
                            isLoading = true;
                          });
                        }, () {
                          setState(() {
                            isLoading = false;
                          });
                        }),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: isLoading
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text('Traitement...'),
                                ],
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.payment_outlined),
                                  SizedBox(width: 8),
                                  Text('Procéder au paiement'),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '⚠️ Le paiement sera traité via notre partenaire WicPay',
                      style: TextStyle(
                        fontSize: 12,
                        color: _themeService.isDarkMode ? Colors.white60 : Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _effectuerPaiement(String montantStr, StateSetter setState, VoidCallback setLoading, VoidCallback setLoadingFalse) async {
    if (montantStr.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer un montant')),
      );
      return;
    }

    final montant = int.tryParse(montantStr);
    if (montant == null || montant <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer un montant valide')),
      );
      return;
    }

    if (_matricule == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informations élève non disponibles')),
      );
      return;
    }

    setLoading();

    try {
      print('💳 Initialisation du paiement: $montant FCFA pour matricule $_matricule');
      
      final paiementResponse = await _paiementService.initierPaiementEnLigne(_matricule!, montant);
      
      if (paiementResponse.success && paiementResponse.url.isNotEmpty) {
        Navigator.of(context).pop(); // Fermer le bottomsheet
        
        // Afficher un message de succès
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(paiementResponse.message),
            backgroundColor: Colors.green,
          ),
        );
        
        // Rediriger vers l'URL de paiement
        final launched = await _paiementService.lancerUrlPaiement(paiementResponse.url);
        if (!launched) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Impossible d\'ouvrir la page de paiement. Veuillez réessayer.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        throw Exception('Réponse invalide du serveur');
      }
    } catch (e) {
      print('❌ Erreur lors du paiement: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du paiement: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setLoadingFalse();
    }
  }

  Widget _buildSummaryCards() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Moyenne', 
                  _globalAverage != null 
                    ? '${_globalAverage!.trimesterAverage.toStringAsFixed(2)}'
                    : '--',
                  Colors.green, 
                  Icons.trending_up,
                  isLoading: _isLoadingNotes,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSummaryCard(
                  'Rang', 
                  _globalAverage != null && _globalAverage!.trimesterRank > 0
                    ? '${_globalAverage!.trimesterRank}${_getOrdinalSuffix(_globalAverage!.trimesterRank)}'
                    : '--',
                  Colors.blue, 
                  Icons.emoji_events,
                  isLoading: _isLoadingNotes,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildSummaryCard('Présence', '95%', AppColors.success, Icons.check_circle)),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSummaryCard(
                  'Appréciation', 
                  _globalAverage != null 
                    ? _globalAverage!.trimesterMention
                    : '--',
                  AppColors.secondary, 
                  Icons.star,
                  isLoading: _isLoadingNotes,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color, IconData icon, {bool isLoading = false}) {
    final isDarkMode = _themeService.isDarkMode;
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.getSurfaceColor(isDarkMode),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: isDarkMode 
                ? AppColors.black.withOpacity(0.2)
                : AppColors.shadowLight,
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 14),
              const Spacer(),
              if (isLoading)
                SizedBox(
                  width: 10,
                  height: 10,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                )
              else
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          if (isLoading)
            SizedBox(
              height: 16,
              child: Row(
                children: [
                  Container(
                    width: 25,
                    height: 2,
                    decoration: BoxDecoration(
                      color: AppColors.getTextColor(isDarkMode, type: TextType.secondary).withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            )
          else
            Text(
              value,
              style: TextStyle(
                fontSize: _textSizeService.getScaledFontSize(16),
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          const SizedBox(height: 1),
          Text(
            title,
            style: TextStyle(
              fontSize: _textSizeService.getScaledFontSize(10),
              color: AppColors.getTextColor(isDarkMode, type: TextType.secondary),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersistentTabBar() {
    final isDarkMode = _themeService.isDarkMode;
    
    return SliverPersistentHeader(
      pinned: true,
      delegate: _TabBarDelegate(
        TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: AppColors.getTextColor(isDarkMode, type: TextType.secondary),
          indicator: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: AppColors.primaryGradient,
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          labelStyle: _textSizeService.getScaledTextStyle(
            const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          unselectedLabelStyle: _textSizeService.getScaledTextStyle(
            const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
          tabs: const [
            Tab(text: '📊 Notes'),
            Tab(text: '📋 Bulletins'),
            Tab(text: '📅 Emploi du temps'),
            Tab(text: '📝 Devoirs'),
            Tab(text: '🚸 Présence & Conduite'),
            Tab(text: '🔍 Contrôle d\'accès'),
            Tab(text: '⚠️ Sanctions'),
            Tab(text: '💬 Messages'),
            Tab(text: '💰 Scolarité & Paiements'),
            Tab(text: '📈 Difficultés'),
            Tab(text: '🎉 Événements'),
            Tab(text: '📚 Fournitures'),
            Tab(text: '🛒 Commandes'),
            Tab(text: '🔐 Logs d\'Accès'),
            Tab(text: '💡 Suggestions'),
            Tab(text: '🎫 Réservations'),
          ],
        ),
      ),
    );
  }

  Widget _buildModernTabBar() {
    final isDarkMode = _themeService.isDarkMode;
    
    return AnimatedBuilder(
      animation: Listenable.merge([_tabController, _textSizeService]),
      builder: (context, _) {
        return Container(
          height: 35,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 16,
            itemBuilder: (context, index) {
              final isSelected = _tabController.index == index;
              return GestureDetector(
                onTap: () {
                  _tabController.animateTo(index);
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? AppColors.primaryGradient
                        : null,
                    color: !isSelected
                        ? AppColors.getSurfaceColor(isDarkMode)
                        : null,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: isSelected
                        ? [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ]
                        : [],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getTabIcon(index),
                        size: 16,
                        color: isSelected
                            ? Colors.white
                            : AppColors.getTextColor(isDarkMode, type: TextType.secondary),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _getTabTitle(index),
                        style: TextStyle(
                          fontSize: _textSizeService.getScaledFontSize(14),
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : AppColors.getTextColor(isDarkMode, type: TextType.secondary),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  IconData _getTabIcon(int index) {
    switch (index) {
      case 0:
        return Icons.bar_chart_rounded;
      case 1:
        return Icons.description_rounded;
      case 2:
        return Icons.calendar_today_rounded;
      case 3:
        return Icons.edit_note_rounded;
      case 4:
        return Icons.person_off_rounded;
      case 5:
        return Icons.fingerprint_rounded;
      case 6:
        return Icons.warning_rounded;
      case 7:
        return Icons.message_rounded;
      case 8:
        return Icons.payments_rounded;
      case 9:
        return Icons.psychology_rounded;
      case 10:
        return Icons.event_rounded;
      case 11:
        return Icons.inventory_2_rounded;
      case 12:
        return Icons.shopping_cart_rounded;
      case 13:
        return Icons.security_rounded;
      case 14:
        return Icons.lightbulb_rounded;
      case 15:
        return Icons.event_seat_rounded;
      default:
        return Icons.help_rounded;
    }
  }

  String _getTabTitle(int index) {
    switch (index) {
      case 0:
        return 'Mes Notes';
      case 1:
        return 'Mes Bulletins';
      case 2:
        return 'Emploi du temps';
      case 3:
        return 'Devoirs';
      case 4:
        return 'Présence & Conduite';
      case 5:
        return 'Contrôle d\'accès';
      case 6:
        return 'Sanctions';
      case 7:
        return 'Messages';
      case 8:
        return 'Scolartité & Paiements';
      case 9:
        return 'Difficultés';
      case 10:
        return 'Événements';
      case 11:
        return 'Fournitures';
      case 12:
        return 'Commandes';
      case 13:
        return 'Logs d\'Accès';
      case 14:
        return 'Suggestions';
      case 15:
        return 'Réservations';
      default:
        return '';
    }
  }

  Widget _buildBulletinsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildInfoCard(
            '📊 Bulletins scolaires',
            'Consultez les bulletins trimestriels et annuels de votre enfant pour suivre sa progression scolaire.',
            Colors.green,
          ),
          const SizedBox(height: 20),
          _buildBulletinsList(),
        ],
      ),
    );
  }

  Widget _buildBulletinsList() {
    return Column(
      children: [
        _buildBulletinCard(
          'Bulletin du 1er trimestre',
          'Année scolaire 2023-2024',
          'Moyenne générale: 14.5/20',
          'Publié le 15 décembre 2023',
          Icons.description_rounded,
          Colors.blue,
        ),
        const SizedBox(height: 12),
        _buildBulletinCard(
          'Bulletin du 2ème trimestre',
          'Année scolaire 2023-2024',
          'Moyenne générale: 15.2/20',
          'Publié le 20 mars 2024',
          Icons.description_rounded,
          Colors.green,
        ),
        const SizedBox(height: 12),
        _buildBulletinCard(
          'Bulletin du 3ème trimestre',
          'Année scolaire 2023-2024',
          'Moyenne générale: 16.8/20',
          'Publié le 25 juin 2024',
          Icons.description_rounded,
          Colors.orange,
        ),
      ],
    );
  }

  Widget _buildBulletinCard(
    String title,
    String subtitle,
    String grade,
    String date,
    IconData icon,
    Color color,
  ) {
    final isDarkMode = _themeService.isDarkMode;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkMode 
                ? Colors.black.withOpacity(0.3)
                : color.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        grade,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      date,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios_rounded,
            size: 16,
            color: isDarkMode ? Colors.grey[400] : Colors.grey[400],
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultiesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildInfoCard(
            '🧠 Difficultés scolaires',
            'Suivi des difficultés rencontrées par votre enfant et des actions mises en place pour l\'aider.',
            Colors.orange,
          ),
          const SizedBox(height: 20),
          _buildDifficultiesList(),
        ],
      ),
    );
  }

  Widget _buildDifficultiesList() {
    return Column(
      children: [
        _buildDifficultyCard(
          'Mathématiques',
          'Difficultés en calcul mental et géométrie',
          'Soutien personnalisé mis en place',
          'En cours',
          Icons.calculate_rounded,
          Colors.red,
        ),
        const SizedBox(height: 12),
        _buildDifficultyCard(
          'Français',
          'Orthographe et grammaire',
          'Exercices supplémentaires',
          'Amélioration constatée',
          Icons.menu_book_rounded,
          Colors.orange,
        ),
        const SizedBox(height: 12),
        _buildDifficultyCard(
          'Anglais',
          'Compréhension orale',
          'Sessions avec assistant linguistique',
          'Progrès satisfaisants',
          Icons.language_rounded,
          Colors.green,
        ),
      ],
    );
  }

  Widget _buildDifficultyCard(
    String subject,
    String difficulty,
    String action,
    String status,
    IconData icon,
    Color color,
  ) {
    final isDarkMode = _themeService.isDarkMode;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkMode 
                ? Colors.black.withOpacity(0.3)
                : color.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      difficulty,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF2A2A2A) : Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Action mise en place:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  action,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
              const Spacer(),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[400],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEventsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildInfoCard(
            '📅 Événements scolaires',
            'Restez informé des événements importants de la vie scolaire de votre enfant.',
            Colors.blue,
          ),
          const SizedBox(height: 20),
          _buildEventsList(),
        ],
      ),
    );
  }

  Widget _buildEventsList() {
    return Column(
      children: [
        _buildEventCard(
          'Réunion parents-professeurs',
          'Discution sur les résultats du premier trimestre',
          '15 décembre 2023',
          '14:00',
          Icons.groups_rounded,
          Colors.blue,
        ),
        const SizedBox(height: 12),
        _buildEventCard(
          'Sortie pédagogique',
          'Visite du musée des sciences',
          '20 janvier 2024',
          '09:00',
          Icons.directions_bus_rounded,
          Colors.green,
        ),
        const SizedBox(height: 12),
        _buildEventCard(
          'Fête de l\'école',
          'Célébration annuelle avec spectacle',
          '10 juin 2024',
          '15:00',
          Icons.celebration_rounded,
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildEventCard(
    String title,
    String description,
    String date,
    String time,
    IconData icon,
    Color color,
  ) {
    final isDarkMode = _themeService.isDarkMode;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkMode 
                ? Colors.black.withOpacity(0.3)
                : color.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 14,
                      color: color,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      date,
                      style: TextStyle(
                        fontSize: 12,
                        color: color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.access_time_rounded,
                      size: 14,
                      color: color,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 12,
                        color: color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios_rounded,
            size: 16,
            color: isDarkMode ? Colors.grey[400] : Colors.grey[400],
          ),
        ],
      ),
    );
  }

  Widget _buildSuppliesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildInfoCard(
            '📚 Fournitures scolaires',
            'Liste des fournitures nécessaires et suivi de l\'état du matériel.',
            Colors.green,
          ),
          const SizedBox(height: 20),
          
          // Carte d'accès à la boutique
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const LibraryScreen(),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.1),
                    AppColors.primary.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.shopping_bag,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '🛍 Boutique Libouli',
                          style: TextStyle(
                            fontSize: _textSizeService.getScaledFontSize(16),
                            fontWeight: FontWeight.bold,
                            color: AppColors.getTextColor(_themeService.isDarkMode),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Achetez des fournitures et articles scolaires pour ${widget.child.firstName}',
                          style: TextStyle(
                            fontSize: _textSizeService.getScaledFontSize(14),
                            color: AppColors.getTextColor(_themeService.isDarkMode, type: TextType.secondary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          _buildSuppliesList(),
        ],
      ),
    );
  }

  Widget _buildSuppliesList() {
    if (_isLoadingSupplies) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Column(
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Chargement des fournitures...'),
            ],
          ),
        ),
      );
    }

    if (_schoolSupplies.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: _themeService.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.withOpacity(0.2),
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune fourniture trouvée',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _themeService.isDarkMode ? Colors.white70 : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Les fournitures scolaires seront affichées ici une fois disponibles.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: _themeService.isDarkMode ? Colors.white54 : Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    // Group supplies by type
    final Map<String, List<SchoolSupply>> groupedSupplies = {};
    for (final supply in _schoolSupplies) {
      final type = supply.type.toUpperCase();
      if (!groupedSupplies.containsKey(type)) {
        groupedSupplies[type] = [];
      }
      groupedSupplies[type]!.add(supply);
    }

    return Column(
      children: groupedSupplies.entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildSupplyCategory(
            entry.key,
            entry.value.map((supply) => _buildSupplyItemFromApi(supply)).toList(),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSupplyCategory(String title, List<Widget> items) {
    final isDarkMode = _themeService.isDarkMode;
    
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkMode 
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.green,
              ),
            ),
          ),
          ...items,
        ],
      ),
    );
  }

  Widget _buildSupplyItemFromApi(SchoolSupply supply) {
    final isDarkMode = _themeService.isDarkMode;
    
    // Determine status color based on availability
    Color statusColor = supply.statut.toLowerCase() == 'disponible' 
        ? Colors.green 
        : Colors.orange;
    
    String statusText = supply.statut.toLowerCase() == 'disponible' 
        ? 'Disponible' 
        : 'Indisponible';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  supply.libelle,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${supply.matiere} • ${supply.niveau}',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${supply.prix} FCFA',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 6,
              vertical: 3,
            ),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              statusText,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const LibraryScreen(),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.3),
                  width: 0.5,
                ),
              ),
              child: Icon(
                Icons.shopping_cart_outlined,
                color: AppColors.primary,
                size: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildInfoCard(
            '🛒 Commandes',
            'Suivi de vos commandes de fournitures scolaires et services.',
            Colors.purple,
          ),
          const SizedBox(height: 20),
          _buildOrdersList(),
        ],
      ),
    );
  }

  Widget _buildOrdersList() {
    return Column(
      children: [
        _buildOrderCard(
          'Commande #2024-001',
          'Fournitures de rentrée',
          'En cours de préparation',
          '12 janvier 2024',
          '45.99 €',
          Icons.inventory_rounded,
          Colors.blue,
        ),
        const SizedBox(height: 12),
        _buildOrderCard(
          'Commande #2023-015',
          'Cantine - Mois de janvier',
          'Livrée',
          '5 janvier 2024',
          '28.50 €',
          Icons.restaurant_rounded,
          Colors.green,
        ),
        const SizedBox(height: 12),
        _buildOrderCard(
          'Commande #2023-014',
          'Sortie scolaire',
          'Confirmée',
          '20 décembre 2023',
          '15.00 €',
          Icons.directions_bus_rounded,
          Colors.orange,
        ),
      ],
    );
  }

  Widget _buildOrderCard(
    String orderNumber,
    String description,
    String status,
    String date,
    String amount,
    IconData icon,
    Color color,
  ) {
    final isDarkMode = _themeService.isDarkMode;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkMode 
                ? Colors.black.withOpacity(0.3)
                : color.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      orderNumber,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                amount,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.calendar_today_rounded,
                size: 14,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Text(
                date,
                style: TextStyle(
                  fontSize: 12,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              const Spacer(),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[400],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ... (rest of the methods remain the same)
  Widget _buildHomeworkTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildInfoCard(
            '💡 Message important',
            'Cher parents,\nMerci de vous impliquer régulièrement dans le suivi et l\'amélioration du résultat scolaire de votre enfant.',
            Colors.blue,
          ),
          const SizedBox(height: 20),
          _buildHomeworkCategories(),
          const SizedBox(height: 20),
          _buildHomeworkContent(),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, String content, Color color) {
    final isDarkMode = _themeService.isDarkMode;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkMode 
                ? Colors.black.withOpacity(0.3)
                : color.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.info_outline,
              color: color,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: _textSizeService.getScaledFontSize(14),
                    fontWeight: FontWeight.w600,
                    color: color,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  content,
                  style: TextStyle(
                    fontSize: _textSizeService.getScaledFontSize(13),
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

  Widget _buildHomeworkCategories() {
    final isDarkMode = _themeService.isDarkMode;
    
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF4F46E5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'COURS',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: _textSizeService.getScaledFontSize(14),
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'EXERCICES',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDarkMode ? Colors.grey[400] : const Color(0xFF6B7280),
                  fontWeight: FontWeight.w600,
                  fontSize: _textSizeService.getScaledFontSize(14),
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'CORRIGÉS',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDarkMode ? Colors.grey[400] : const Color(0xFF6B7280),
                  fontWeight: FontWeight.w600,
                  fontSize: _textSizeService.getScaledFontSize(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeworkContent() {
    return Column(
      children: [
        _buildHomeworkItem(
          'Mathématiques',
          'Exercices pages 45-47',
          'Pour demain',
          Icons.calculate,
          Colors.orange,
        ),
        const SizedBox(height: 12),
        _buildHomeworkItem(
          'Français',
          'Rédaction : Mon héros préféré',
          'Pour vendredi',
          Icons.menu_book,
          Colors.blue,
        ),
        const SizedBox(height: 12),
        _buildHomeworkItem(
          'Histoire',
          'Chapitre 3 : La Révolution française',
          'Pour lundi prochain',
          Icons.public,
          Colors.green,
        ),
      ],
    );
  }

  Widget _buildHomeworkItem(String subject, String task, String deadline, IconData icon, Color color) {
    final isDarkMode = _themeService.isDarkMode;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isDarkMode 
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subject,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : const Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  task,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDarkMode ? Colors.grey[300] : const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              deadline,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAbsencesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildInfoCard(
            '📈 Suivi de présence',
            'Cher parents,\nMerci de vous impliquer régulièrement dans le suivi et l\'amélioration du résultat scolaire de votre enfant.',
            Colors.green,
          ),
          const SizedBox(height: 20),
          _buildAttendanceSummary(),
          const SizedBox(height: 20),
          _buildAbsencesList(),
        ],
      ),
    );
  }

  Widget _buildAttendanceSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Résumé mensuel',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildAttendanceStat('Présences', '18', Colors.green),
              ),
              Expanded(
                child: _buildAttendanceStat('Retards', '2', Colors.orange),
              ),
              Expanded(
                child: _buildAttendanceStat('Absences', '0', Colors.red),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceStat(String label, String value, Color color) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Center(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF6B7280),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildAbsencesList() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 24),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Aucune absence enregistrée ce mois-ci',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF065F46),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSanctionsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildInfoCard(
            '🎯 Comportement',
            'Cher parents,\nMerci de vous impliquer régulièrement dans le suivi et l\'amélioration du résultat scolaire de votre enfant.',
            Colors.purple,
          ),
          const SizedBox(height: 20),
          _buildBehaviorSummary(),
          const SizedBox(height: 20),
          _buildSanctionsList(),
        ],
      ),
    );
  }

  Widget _buildBehaviorSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Évaluation comportementale',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildBehaviorItem('Excellent', '⭐', Colors.green),
              ),
              Expanded(
                child: _buildBehaviorItem('Bon', '👍', Colors.blue),
              ),
              Expanded(
                child: _buildBehaviorItem('À améliorer', '📈', Colors.orange),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBehaviorItem(String label, String emoji, Color color) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Center(
            child: Text(
              emoji,
              style: const TextStyle(fontSize: 24),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF6B7280),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSanctionsList() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.emoji_events, color: Colors.green, size: 24),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Excellent comportement ! Aucune sanction',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF065F46),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _TabBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height + 16;

  @override
  double get maxExtent => _tabBar.preferredSize.height + 16;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: const Color(0xFFF8FAFC),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: _tabBar,
      ),
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) {
    return false;
  }
}

class _CustomTabBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget _child;

  _CustomTabBarDelegate(this._child);

  @override
  double get minExtent => 59.0; // 35 height + 12 vertical padding + 12 margin

  @override
  double get maxExtent => 59.0; // 35 height + 12 vertical padding + 12 margin

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return _child;
  }

  @override
  bool shouldRebuild(_CustomTabBarDelegate oldDelegate) {
    return false;
  }
}