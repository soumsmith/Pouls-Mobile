import 'package:flutter/material.dart';
import '../models/child.dart';
import '../models/note.dart';
import '../models/timetable_entry.dart';
import '../models/message.dart';
import '../models/fee.dart';
import '../models/school_supply.dart';
import '../services/pouls_scolaire_api_service.dart';
import '../services/database_service.dart';
import '../services/theme_service.dart';
import '../services/text_size_service.dart';
import '../config/app_colors.dart';
import '../widgets/main_screen_wrapper.dart';
import '../widgets/student_menu_cards.dart';
import '../screens/notes_screen_json.dart';
import '../services/student_timetable_service.dart';
import '../models/student_timetable.dart';
import '../services/school_service.dart';
import '../services/access_control_service.dart';
import '../models/access_control.dart';
import '../screens/shop_screen.dart';
import '../screens/access_log_screen.dart';
import '../screens/parent_suggestion_screen.dart';
import '../screens/place_reservation_screen.dart';
import '../services/school_supply_service.dart';
import '../services/paiement_service.dart';
import '../services/student_message_service.dart';
import '../models/student_message.dart';
import '../services/student_scolarite_service.dart';
import '../models/student_scolarite.dart';
import '../services/parent_suggestion_service.dart';
import '../models/parent_suggestion.dart';
import '../services/access_log_service.dart';
import '../models/access_log.dart';
import '../services/place_reservation_service.dart';
import '../models/place_reservation.dart';

// ─── DESIGN TOKENS MODERNES INSPIRÉS DU PANIER ───────────────────────────────────
const _kSurface = Color(0xFFF8F8F8);
const _kCard = Colors.white;
const _kTextPrimary = Color(0xFF1A1A1A);
const _kTextSecondary = Color(0xFF8A8A8A);
const _kDivider = Color(0xFFF0F0F0);
const _kShadow = Color(0x0D000000);
const _kOrange = Color(0xFFFF6B2C);
const _kOrangeLight = Color(0xFFFFF0E8);

/// Écran de détail d'un enfant avec menu cartes
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
  final StudentTimetableService _timetableService = StudentTimetableService();
  final SchoolService _schoolService = SchoolService();
  final AccessControlService _accessControlService = AccessControlService();
  final StudentMessageService _messageService = StudentMessageService();
  final StudentScolariteService _scolariteService = StudentScolariteService();
  final MockParentSuggestionService _suggestionService = MockParentSuggestionService();
  final MockAccessLogService _accessLogService = MockAccessLogService();
  final MockPlaceReservationService _reservationService = MockPlaceReservationService();
  
  // Variables pour l'emploi du temps dynamique
  StudentTimetableResponse? _timetableResponse;
  bool _isLoadingTimetable = false;
  
  // Variables pour le contrôle d'accès
  List<AccessControlEntry> _accessEntries = [];
  bool _isLoadingAccessControl = false;
  
  // Variables pour les messages
  List<StudentMessage> _studentMessages = [];
  bool _isLoadingMessages = false;
  
  // Variables pour les scolarités
  List<StudentScolariteEntry> _scolariteEntries = [];
  bool _isLoadingScolarite = false;
  
  // Variables pour les suggestions
  List<ParentSuggestion> _suggestions = [];
  bool _isLoadingSuggestions = false;
  
  // Variables pour les logs d'accès
  List<AccessLog> _accessLogs = [];
  bool _isLoadingAccessLogs = false;
  
  // Variables pour les réservations
  List<PlaceReservation> _reservations = [];
  bool _isLoadingReservations = false;
  
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
    
    _loadData();
    _animationController.forward();
  }

  @override
  void dispose() {
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

      // Étape 5: Précharger l'emploi du temps
      print('📅 Étape 5: Préchargement de l\'emploi du temps...');
      await _loadTimetableData();
      
      // Étape 6: Précharger le contrôle d'accès
      print('🔒 Étape 6: Préchargement du contrôle d\'accès...');
      await _loadAccessControlData();
      
      // Étape 7: Précharger les messages
      print('💬 Étape 7: Préchargement des messages...');
      await _loadMessagesData();
      
      // Étape 8: Précharger les scolarités
      print('💰 Étape 8: Préchargement des scolarités...');
      await _loadScolariteData();
      
      // Étape 9: Précharger les suggestions
      print('💡 Étape 9: Préchargement des suggestions...');
      await _loadSuggestionsData();
      
      // Étape 10: Précharger les logs d'accès
      print('📋 Étape 10: Préchargement des logs d\'accès...');
      await _loadAccessLogsData();
      
      // Étape 11: Précharger les réservations
      print('🪑 Étape 11: Préchargement des réservations...');
      await _loadReservationsData();
      
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
    
    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : _kSurface,
      body: CustomScrollView(
        slivers: [
          _buildModernSliverAppBar(),
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  _buildModernProfileHeader(),
                  const SizedBox(height: 20),
                  _buildModernSummaryCards(),
                  const SizedBox(height: 24),
                  _buildStudentMenuCards(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentMenuCards() {
    return StudentMenuCardsFull(
      onNotes: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const NotesScreenJson(),
        ),
      ),
      onBulletins: () => _showStudentMenuBottomSheet('bulletins', _getStudentMenuCardItem('bulletins')),
      onTimetable: () async {
        // Précharger si nécessaire avant d'ouvrir le bottom sheet
        if (_timetableResponse == null && !_isLoadingTimetable) {
          await _loadTimetableData();
        }
        if (mounted) {
          _showStudentMenuBottomSheet('timetable', _getStudentMenuCardItem('timetable'));
        }
      },
      onHomework: () => _showStudentMenuBottomSheet('homework', _getStudentMenuCardItem('homework')),
      onAttendance: () => _showStudentMenuBottomSheet('attendance', _getStudentMenuCardItem('attendance')),
      onAccessControl: () async {
        // Précharger si nécessaire avant d'ouvrir le bottom sheet
        if (_accessEntries.isEmpty && !_isLoadingAccessControl) {
          await _loadAccessControlData();
        }
        if (mounted) {
          _showStudentMenuBottomSheet('accessControl', _getStudentMenuCardItem('accessControl'));
        }
      },
      onSanctions: () => _showStudentMenuBottomSheet('sanctions', _getStudentMenuCardItem('sanctions')),
      onMessages: () async {
        // Précharger si nécessaire avant d'ouvrir le bottom sheet
        if (_studentMessages.isEmpty && !_isLoadingMessages) {
          await _loadMessagesData();
        }
        if (mounted) {
          _showStudentMenuBottomSheet('messages', _getStudentMenuCardItem('messages'));
        }
      },
      onFees: () async {
        // Précharger si nécessaire avant d'ouvrir le bottom sheet
        if (_scolariteEntries.isEmpty && !_isLoadingScolarite) {
          await _loadScolariteData();
        }
        if (mounted) {
          _showStudentMenuBottomSheet('fees', _getStudentMenuCardItem('fees'));
        }
      },
      onDifficulties: () => _showStudentMenuBottomSheet('difficulties', _getStudentMenuCardItem('difficulties')),
      onEvents: () => _showStudentMenuBottomSheet('events', _getStudentMenuCardItem('events')),
      onSuggestions: () async {
        // Précharger si nécessaire avant d'ouvrir le bottom sheet
        if (_suggestions.isEmpty && !_isLoadingSuggestions) {
          await _loadSuggestionsData();
        }
        if (mounted) {
          _showStudentMenuBottomSheet('suggestions', _getStudentMenuCardItem('suggestions'));
        }
      },
      onReservations: () async {
        // Précharger si nécessaire avant d'ouvrir le bottom sheet
        if (_reservations.isEmpty && !_isLoadingReservations) {
          await _loadReservationsData();
        }
        if (mounted) {
          _showStudentMenuBottomSheet('reservations', _getStudentMenuCardItem('reservations'));
        }
      },
      onAccessLogs: () async {
        // Précharger si nécessaire avant d'ouvrir le bottom sheet
        if (_accessLogs.isEmpty && !_isLoadingAccessLogs) {
          await _loadAccessLogsData();
        }
        if (mounted) {
          _showStudentMenuBottomSheet('accessLogs', _getStudentMenuCardItem('accessLogs'));
        }
      },
      onSupplies: () => _showStudentMenuBottomSheet('supplies', _getStudentMenuCardItem('supplies')),
      onOrders: () => _showStudentMenuBottomSheet('orders', _getStudentMenuCardItem('orders')),
    );
  }

  StudentMenuCardItem _getStudentMenuCardItem(String menuType) {
    switch (menuType) {
      case 'notes':
        return StudentMenuCardItem(
          icon: Icons.bar_chart_rounded,
          label: 'Mes Notes',
          onTap: () {},
          backgroundColor: const Color(0xFFE3F2FD),
          iconColor: const Color(0xFF1976D2),
          titleColor: const Color(0xFF0D47A1),
        );
      case 'bulletins':
        return StudentMenuCardItem(
          icon: Icons.description_rounded,
          label: 'Bulletins',
          onTap: () {},
          backgroundColor: const Color(0xFFE8F5E8),
          iconColor: const Color(0xFF2E7D32),
          titleColor: const Color(0xFF1B5E20),
        );
      case 'timetable':
        return StudentMenuCardItem(
          icon: Icons.calendar_today_rounded,
          label: 'Emploi du temps',
          onTap: () {},
          backgroundColor: const Color(0xFFFFF3E0),
          iconColor: const Color(0xFFF57C00),
          titleColor: const Color(0xFFE65100),
        );
      case 'homework':
        return StudentMenuCardItem(
          icon: Icons.edit_note_rounded,
          label: 'Devoirs',
          onTap: () {},
          backgroundColor: const Color(0xFFF3E5F5),
          iconColor: const Color(0xFF7B1FA2),
          titleColor: const Color(0xFF4A148C),
        );
      case 'attendance':
        return StudentMenuCardItem(
          icon: Icons.person_off_rounded,
          label: 'Présence & Conduite',
          onTap: () {},
          backgroundColor: const Color(0xFFE0F2F1),
          iconColor: const Color(0xFF00796B),
          titleColor: const Color(0xFF004D40),
        );
      case 'accessControl':
        return StudentMenuCardItem(
          icon: Icons.fingerprint_rounded,
          label: 'Contrôle d\'accès',
          onTap: () {},
          backgroundColor: const Color(0xFFFCE4EC),
          iconColor: const Color(0xFFC2185B),
          titleColor: const Color(0xFF880E4F),
        );
      case 'sanctions':
        return StudentMenuCardItem(
          icon: Icons.warning_rounded,
          label: 'Sanctions',
          onTap: () {},
          backgroundColor: const Color(0xFFFFEBEE),
          iconColor: const Color(0xFFD32F2F),
          titleColor: const Color(0xFFB71C1C),
        );
      case 'messages':
        return StudentMenuCardItem(
          icon: Icons.message_rounded,
          label: 'Messages',
          onTap: () {},
          backgroundColor: const Color(0xFFE1F5FE),
          iconColor: const Color(0xFF0288D1),
          titleColor: const Color(0xFF01579B),
        );
      case 'fees':
        return StudentMenuCardItem(
          icon: Icons.payments_rounded,
          label: 'Scolarité & Paiements',
          onTap: () {},
          backgroundColor: const Color(0xFFF9FBE7),
          iconColor: const Color(0xFFFBC02D),
          titleColor: const Color(0xFFF57F17),
        );
      case 'difficulties':
        return StudentMenuCardItem(
          icon: Icons.psychology_rounded,
          label: 'Difficultés',
          onTap: () {},
          backgroundColor: const Color(0xFFF3E5F5),
          iconColor: const Color(0xFF9C27B0),
          titleColor: const Color(0xFF6A1B9A),
        );
      case 'events':
        return StudentMenuCardItem(
          icon: Icons.event_rounded,
          label: 'Événements',
          onTap: () {},
          backgroundColor: const Color(0xFFE8EAF6),
          iconColor: const Color(0xFF3F51B5),
          titleColor: const Color(0xFF283593),
        );
      case 'supplies':
        return StudentMenuCardItem(
          icon: Icons.inventory_2_rounded,
          label: 'Fournitures',
          onTap: () {},
          backgroundColor: const Color(0xFFEFEBE9),
          iconColor: const Color(0xFF795548),
          titleColor: const Color(0xFF4E342E),
        );
      case 'orders':
        return StudentMenuCardItem(
          icon: Icons.shopping_cart_rounded,
          label: 'Commandes',
          onTap: () {},
          backgroundColor: const Color(0xFFE0F7FA),
          iconColor: const Color(0xFF00ACC1),
          titleColor: const Color(0xFF00838F),
        );
      case 'accessLogs':
        return StudentMenuCardItem(
          icon: Icons.security_rounded,
          label: 'Logs d\'Accès',
          onTap: () {},
          backgroundColor: const Color(0xFFEEEEEE),
          iconColor: const Color(0xFF616161),
          titleColor: const Color(0xFF212121),
        );
      case 'suggestions':
        return StudentMenuCardItem(
          icon: Icons.lightbulb_rounded,
          label: 'Suggestions',
          onTap: () {},
          backgroundColor: const Color(0xFFFFF8E1),
          iconColor: const Color(0xFFFFB300),
          titleColor: const Color(0xFFFF6F00),
        );
      case 'reservations':
        return StudentMenuCardItem(
          icon: Icons.event_seat_rounded,
          label: 'Réservations',
          onTap: () {},
          backgroundColor: const Color(0xFFE8F5E8),
          iconColor: const Color(0xFF4CAF50),
          titleColor: const Color(0xFF2E7D32),
        );
      default:
        return StudentMenuCardItem(
          icon: Icons.help_rounded,
          label: 'Inconnu',
          onTap: () {},
        );
    }
  }

  void _showStudentMenuBottomSheet(String menuType, StudentMenuCardItem cardItem) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[900] : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header avec les couleurs de la carte
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardItem.backgroundColor ?? (isDark ? Colors.grey[800] : Colors.grey[50]),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    border: Border(
                      bottom: BorderSide(
                        color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: cardItem.backgroundColor?.withOpacity(0.3) ?? Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          cardItem.icon,
                          color: cardItem.iconColor ?? AppColors.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cardItem.label,
                              style: TextStyle(
                                fontSize: _textSizeService.getScaledFontSize(20),
                                fontWeight: FontWeight.bold,
                                color: cardItem.titleColor ?? (isDark ? Colors.white : Colors.black),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _getStudentMenuDescription(menuType),
                              style: TextStyle(
                                fontSize: _textSizeService.getScaledFontSize(14),
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(
                          Icons.close,
                          color: cardItem.titleColor ?? (isDark ? Colors.white : Colors.black),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: _buildStudentMenuContent(menuType),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _getStudentMenuDescription(String menuType) {
    switch (menuType) {
      case 'notes':
        return 'Consultez les notes et évaluations de votre enfant';
      case 'bulletins':
        return 'Accédez aux bulletins trimestriels et annuels';
      case 'timetable':
        return 'Consultez l\'emploi du temps et les horaires';
      case 'homework':
        return 'Suivez les devoirs et exercices à faire';
      case 'attendance':
        return 'Vérifiez la présence et la conduite';
      case 'accessControl':
        return 'Contrôlez les accès et les pointages';
      case 'sanctions':
        return 'Consultez les sanctions et avertissements';
      case 'messages':
        return 'Lisez les messages et communications';
      case 'fees':
        return 'Gérez les frais de scolarité et paiements';
      case 'difficulties':
        return 'Suivez les difficultés et le soutien';
      case 'events':
        return 'Participez aux événements et activités';
      case 'supplies':
        return 'Gérez les fournitures scolaires';
      case 'orders':
        return 'Suivez vos commandes et achats';
      case 'accessLogs':
        return 'Consultez les logs d\'accès et sécurité';
      case 'suggestions':
        return 'Envoyez vos suggestions et feedback';
      case 'reservations':
        return 'Gérez vos réservations et places';
      default:
        return 'En savoir plus...';
    }
  }

  Widget _buildStudentMenuContent(String menuType) {
    switch (menuType) {
      case 'notes':
        return _buildSimpleNotesTab();
      case 'bulletins':
        return _buildBulletinsTab();
      case 'timetable':
        return _buildSimpleTimetableTab();
      case 'homework':
        return _buildHomeworkTab();
      case 'attendance':
        return _buildAbsencesTab();
      case 'accessControl':
        return _buildSimpleAccessControlTab();
      case 'sanctions':
        return _buildSanctionsTab();
      case 'messages':
        return _buildSimpleMessagesTab();
      case 'fees':
        return _buildSimpleFeesTab();
      case 'difficulties':
        return _buildDifficultiesTab();
      case 'events':
        return _buildEventsTab();
      case 'supplies':
        return _buildSuppliesTab();
      case 'orders':
        return _buildOrdersTab();
      case 'accessLogs':
        return _buildSimpleAccessLogsTab();
      case 'suggestions':
        return _buildSimpleSuggestionsTab();
      case 'reservations':
        return _buildSimpleReservationsTab();
      default:
        return Container(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: Text(
              'Contenu en cours de développement...',
              style: TextStyle(
                color: _themeService.isDarkMode ? Colors.white70 : Colors.grey[600],
              ),
            ),
          ),
        );
    }
  }

  Widget _buildModernSliverAppBar() {
    final theme = Theme.of(context);
    final isDarkMode = _themeService.isDarkMode;
    
    return SliverAppBar(
      expandedHeight: 80,
      floating: false,
      pinned: true,
      backgroundColor: isDarkMode ? Colors.grey[900] : _kSurface,
      elevation: 0,
      forceElevated: false,
      surfaceTintColor: Colors.transparent,
      leading: Container(
        margin: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(color: _kShadow, blurRadius: 8, offset: Offset(0, 2)),
          ],
        ),
        child: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, size: 16, color: theme.iconTheme.color),
          onPressed: () {
            if (MainScreenWrapper.maybeOf(context) != null) {
              MainScreenWrapper.of(context).navigateToHome();
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
          decoration: BoxDecoration(
            color: _kCard,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(color: _kShadow, blurRadius: 8, offset: Offset(0, 2)),
            ],
          ),
          child: IconButton(
            icon: Icon(Icons.notifications_outlined, color: theme.iconTheme.color),
            onPressed: () {},
          ),
        ),
        Container(
          margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
          decoration: BoxDecoration(
            color: _kCard,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(color: _kShadow, blurRadius: 8, offset: Offset(0, 2)),
            ],
          ),
          child: IconButton(
            icon: Icon(Icons.more_vert, color: theme.iconTheme.color),
            onPressed: () {},
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        title: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.child.fullName,
              style: TextStyle(
                color: theme.textTheme.titleLarge?.color,
                fontWeight: FontWeight.w700,
                fontSize: _textSizeService.getScaledFontSize(20),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.child.grade,
              style: TextStyle(
                color: _kTextSecondary,
                fontSize: _textSizeService.getScaledFontSize(13),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        titlePadding: const EdgeInsets.only(left: 76, bottom: 16),
      ),
    );
  }

  Widget _buildModernProfileHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFFFF7A3C), _kOrange],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _kOrange.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.2),
                  border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
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
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.child.fullName,
                      style: TextStyle(
                        fontSize: _textSizeService.getScaledFontSize(20),
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.child.grade,
                      style: TextStyle(
                        fontSize: _textSizeService.getScaledFontSize(14),
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.child.establishment,
                      style: TextStyle(
                        fontSize: _textSizeService.getScaledFontSize(13),
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildModernStatusBadge('⭐ Excellent', Colors.white),
              const SizedBox(width: 8),
              _buildModernStatusBadge('✔ Assidu', Colors.white),
              const SizedBox(width: 8),
              _buildModernStatusBadge('📈 Progression', Colors.white),
            ],
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _showPaiementBottomSheet,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.payment_outlined,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Paiement en ligne',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: _textSizeService.getScaledFontSize(14),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white,
                    size: 12,
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

  Widget _buildModernStatusBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: _textSizeService.getScaledFontSize(11),
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  void _showPaiementBottomSheet() {
    final TextEditingController montantController = TextEditingController();
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              decoration: BoxDecoration(
                color: _kCard,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: const [
                  BoxShadow(
                    color: _kShadow,
                    blurRadius: 20,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: DraggableScrollableSheet(
                initialChildSize: 0.7,
                maxChildSize: 0.9,
                minChildSize: 0.5,
                expand: false,
                builder: (context, scrollController) {
                  return Column(
                    children: [
                      // Handle + header
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                        child: Column(
                          children: [
                            Center(
                              child: Container(
                                width: 36,
                                height: 4,
                                margin: const EdgeInsets.only(bottom: 18),
                                decoration: BoxDecoration(
                                  color: _kDivider,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [const Color(0xFFFF7A3C), _kOrange],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(
                                    Icons.payment,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Paiement en ligne',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: _kTextPrimary,
                                        letterSpacing: -0.4,
                                      ),
                                    ),
                                    Text(
                                      'Entrez le montant à payer pour ${widget.child.firstName}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: _kTextSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                IconButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  icon: const Icon(
                                    Icons.close,
                                    color: _kTextSecondary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const Divider(color: _kDivider, height: 1),
                          ],
                        ),
                      ),

                      // Form content
                      Expanded(
                        child: SingleChildScrollView(
                          controller: scrollController,
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              Text(
                                'Montant à payer (FCFA)',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: _kTextPrimary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                decoration: BoxDecoration(
                                  color: _kSurface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: _kDivider),
                                ),
                                child: TextField(
                                  controller: montantController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    hintText: 'Ex: 10000',
                                    prefixIcon: const Icon(Icons.attach_money, color: _kTextSecondary),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.all(16),
                                  ),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: _kTextPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              _buildModernPaymentButton(
                                label: isLoading ? '' : 'Procéder au paiement',
                                onTap: isLoading ? null : () => _effectuerPaiement(montantController.text, setState, () {
                                  setState(() {
                                    isLoading = true;
                                  });
                                }, () {
                                  setState(() {
                                    isLoading = false;
                                  });
                                }),
                                isLoading: isLoading,
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: _kOrangeLight.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: _kOrange.withOpacity(0.2)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.info_outline, color: _kOrange, size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Le paiement sera traité via notre partenaire WicPay',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: _kOrange,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
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

  Widget _buildModernPaymentButton({
    required String label,
    VoidCallback? onTap,
    bool isLoading = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [const Color(0xFFFF7A3C), _kOrange],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _kOrange.withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
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
                    const Icon(
                      Icons.payment_outlined,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildModernSummaryCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _kOrangeLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.analytics_outlined, color: _kOrange, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Statistiques',
                style: TextStyle(
                  fontSize: _textSizeService.getScaledFontSize(18),
                  fontWeight: FontWeight.w800,
                  color: _kTextPrimary,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildModernSummaryCard(
                      'Moyenne', 
                      _globalAverage != null 
                        ? '${_globalAverage!.trimesterAverage.toStringAsFixed(2)}'
                        : '--',
                      Colors.green, 
                      Icons.trending_up,
                      isLoading: _isLoadingNotes,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildModernSummaryCard(
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
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildModernSummaryCard('Présence', '95%', AppColors.success, Icons.check_circle)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildModernSummaryCard(
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
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildModernSummaryCard(String title, String value, Color color, IconData icon, {bool isLoading = false}) {
    final isDarkMode = _themeService.isDarkMode;
    
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: child,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[800] : _kCard,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.15),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: color.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const Spacer(),
                if (isLoading)
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  )
                else
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (isLoading)
              Container(
                height: 24,
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[700] : _kDivider,
                  borderRadius: BorderRadius.circular(6),
                ),
              )
            else
              Text(
                value,
                style: TextStyle(
                  fontSize: _textSizeService.getScaledFontSize(20),
                  fontWeight: FontWeight.w800,
                  color: color,
                  letterSpacing: -0.8,
                ),
              ),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: _textSizeService.getScaledFontSize(13),
                color: isDarkMode ? Colors.grey[400] : _kTextSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleTimetableTab() {
    final isDarkMode = _themeService.isDarkMode;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildInfoCard(
            '📅 Emploi du temps',
            'Consultez l\'emploi du temps de la semaine pour suivre les cours de votre enfant.',
            Colors.orange,
          ),
          const SizedBox(height: 20),
          _buildDynamicTimetable(),
        ],
      ),
    );
  }

  Widget _buildDynamicTimetable() {
    if (_isLoadingTimetable) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_timetableResponse == null || _timetableResponse!.data.isEmpty) {
      // Vérifier si le matricule est disponible
      final matricule = widget.child.matricule;
      if (matricule == null || matricule.isEmpty) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _themeService.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.red.withOpacity(0.3),
            ),
          ),
          child: Column(
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: Colors.red[400],
              ),
              const SizedBox(height: 12),
              Text(
                'Matricule non disponible',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.red[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Le matricule de l\'enfant n\'est pas configuré. Veuillez contacter l\'administration.',
                style: TextStyle(
                  fontSize: 14,
                  color: _themeService.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }
      
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _themeService.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _themeService.isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.schedule_outlined,
              size: 48,
              color: Colors.orange[400],
            ),
            const SizedBox(height: 12),
            Text(
              'Aucun emploi du temps disponible',
              style: TextStyle(
                fontSize: 16,
                color: _themeService.isDarkMode ? Colors.white70 : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _loadTimetableData(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Actualiser'),
            ),
          ],
        ),
      );
    }

    final coursesByDay = _timetableResponse!.coursesByDay;
    final days = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi'];
    
    return Column(
      children: days.map((day) {
        if (coursesByDay.containsKey(day) && coursesByDay[day]!.isNotEmpty) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildDynamicDaySchedule(day, coursesByDay[day]!),
          );
        }
        return const SizedBox.shrink();
      }).toList(),
    );
  }

  // CORRECTION : suppression du bloc addPostFrameCallback qui redéclenchait
  // inutilement le chargement et empêchait l'affichage au premier rendu.
  Widget _buildSimpleAccessControlTab() {
    final isDarkMode = _themeService.isDarkMode;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildInfoCard(
            '🔒 Contrôle d\'accès',
            'Consultez les pointages et le contrôle d\'accès de votre enfant.',
            Colors.purple,
          ),
          const SizedBox(height: 20),
          _buildDynamicAccessControl(),
        ],
      ),
    );
  }

  Widget _buildDynamicAccessControl() {
    if (_isLoadingAccessControl) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_accessEntries.isEmpty) {
      // Vérifier si le matricule est disponible
      final matricule = widget.child.matricule;
      if (matricule == null || matricule.isEmpty) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _themeService.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.red.withOpacity(0.3),
            ),
          ),
          child: Column(
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: Colors.red[400],
              ),
              const SizedBox(height: 12),
              Text(
                'Matricule non disponible',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.red[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Le matricule de l\'enfant n\'est pas configuré. Veuillez contacter l\'administration.',
                style: TextStyle(
                  fontSize: 14,
                  color: _themeService.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }
      
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _themeService.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _themeService.isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.fingerprint,
              size: 48,
              color: Colors.purple[400],
            ),
            const SizedBox(height: 12),
            Text(
              'Aucun pointage disponible',
              style: TextStyle(
                fontSize: 16,
                color: _themeService.isDarkMode ? Colors.white70 : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _loadAccessControlData(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
              ),
              child: const Text('Actualiser'),
            ),
          ],
        ),
      );
    }

    // Statistiques
    final totalEntries = _accessEntries.length;
    final entrees = _accessEntries.where((e) => e.isEntree).length;
    final sorties = _accessEntries.where((e) => e.isSortie).length;
    final statusOk = _accessEntries.where((e) => e.isStatusOk).length;

    return Column(
      children: [
        // Carte de statistiques
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _themeService.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _themeService.isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.analytics_outlined,
                    color: Colors.purple,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Statistiques de pointage',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: _themeService.isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem('Total', totalEntries.toString(), Colors.purple),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatItem('Entrées', entrees.toString(), Colors.green),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatItem('Sorties', sorties.toString(), Colors.orange),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem('OK', statusOk.toString(), Colors.green),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatItem('KO', (totalEntries - statusOk).toString(), Colors.red),
                  ),
                  const Expanded(child: SizedBox()),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Liste des pointages récents (limités à 5 pour le bottom sheet)
        ..._accessEntries.take(5).map((entry) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildAccessControlCard(entry),
        )).toList(),
        if (_accessEntries.length > 5)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '... et ${_accessEntries.length - 5} autres pointages',
              style: TextStyle(
                color: _themeService.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }

  Widget _buildSimpleFeesTab() {
    final isDarkMode = _themeService.isDarkMode;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildInfoCard(
            '💰 Scolarité & Paiements',
            'Consultez les échéances de scolarité et l\'état des paiements.',
            Colors.amber,
          ),
          const SizedBox(height: 20),
          _buildDynamicScolarite(),
        ],
      ),
    );
  }

  Widget _buildDynamicScolarite() {
    if (_isLoadingScolarite) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_scolariteEntries.isEmpty) {
      // Vérifier si le matricule est disponible
      final matricule = widget.child.matricule;
      if (matricule == null || matricule.isEmpty) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _themeService.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.red.withOpacity(0.3),
            ),
          ),
          child: Column(
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: Colors.red[400],
              ),
              const SizedBox(height: 12),
              Text(
                'Matricule non disponible',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.red[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Le matricule de l\'enfant n\'est pas configuré. Veuillez contacter l\'administration.',
                style: TextStyle(
                  fontSize: 14,
                  color: _themeService.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }
      
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _themeService.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _themeService.isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.school,
              size: 48,
              color: Colors.amber[400],
            ),
            const SizedBox(height: 12),
            Text(
              'Aucune échéance disponible',
              style: TextStyle(
                fontSize: 16,
                color: _themeService.isDarkMode ? Colors.white70 : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _loadScolariteData(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.white,
              ),
              child: const Text('Actualiser'),
            ),
          ],
        ),
      );
    }

    // Statistiques
    final totalMontant = _scolariteEntries.fold<int>(0, (sum, entry) => sum + entry.montant);
    final totalPaye = _scolariteEntries.fold<int>(0, (sum, entry) => sum + entry.paye);
    final totalRapayer = _scolariteEntries.fold<int>(0, (sum, entry) => sum + entry.rapayer);
    final paymentPercentage = totalMontant > 0 ? (totalPaye / totalMontant) * 100 : 0.0;
    final overdueCount = _scolariteEntries.where((e) => e.isOverdue).length;

    return Column(
      children: [
        // Carte de statistiques
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _themeService.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _themeService.isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.analytics_outlined,
                    color: Colors.amber,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Résumé de la scolarité',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: _themeService.isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem('Total', _formatAmount(totalMontant), Colors.amber),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatItem('Payé', _formatAmount(totalPaye), Colors.green),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatItem('Restant', _formatAmount(totalRapayer), Colors.red),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Barre de progression
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Progression: ${paymentPercentage.toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: _themeService.isDarkMode ? Colors.white : Colors.black,
                          fontSize: _textSizeService.getScaledFontSize(12),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (overdueCount > 0) ...[
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$overdueCount retard(s)',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: _textSizeService.getScaledFontSize(10),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: (_themeService.isDarkMode ? Colors.grey[600] : Colors.grey[300])!.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: paymentPercentage / 100,
                      child: Container(
                        decoration: BoxDecoration(
                          color: paymentPercentage == 100 ? Colors.green : Colors.amber,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Liste des échéances récentes (limitées à 5 pour le bottom sheet)
        ..._scolariteEntries.take(5).map((entry) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildScolariteCard(entry),
        )).toList(),
        if (_scolariteEntries.length > 5)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '... et ${_scolariteEntries.length - 5} autres échéances',
              style: TextStyle(
                color: _themeService.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }

  Widget _buildScolariteCard(StudentScolariteEntry entry) {
    final isDarkMode = _themeService.isDarkMode;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _themeService.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: entry.statusColor == 'green' 
              ? Colors.green.withOpacity(0.3)
              : entry.statusColor == 'orange'
                  ? Colors.orange.withOpacity(0.3)
                  : Colors.red.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showScolariteEntryDetails(entry),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header avec libellé et statut
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.libelle,
                        style: TextStyle(
                          color: _themeService.isDarkMode ? Colors.white : Colors.black,
                          fontSize: _textSizeService.getScaledFontSize(16),
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: entry.statusColor == 'green' 
                            ? Colors.green.withOpacity(0.1)
                            : entry.statusColor == 'orange'
                                ? Colors.orange.withOpacity(0.1)
                                : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        entry.formattedStatus,
                        style: TextStyle(
                          color: entry.statusColor == 'green' 
                              ? Colors.green
                              : entry.statusColor == 'orange'
                                  ? Colors.orange
                                  : Colors.red,
                          fontSize: _textSizeService.getScaledFontSize(12),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Montants
                Row(
                  children: [
                    Icon(
                      Icons.account_balance_wallet,
                      size: 16,
                      color: _themeService.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Montant: ${entry.formattedMontant}',
                      style: TextStyle(
                        color: _themeService.isDarkMode ? Colors.white : Colors.black,
                        fontSize: _textSizeService.getScaledFontSize(14),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 16,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Payé: ${entry.formattedPaye}',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: _textSizeService.getScaledFontSize(14),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      entry.rapayer > 0 ? Icons.warning : Icons.check_circle,
                      size: 16,
                      color: entry.rapayer > 0 ? Colors.red : Colors.green,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Restant: ${entry.formattedRapayer}',
                      style: TextStyle(
                        color: entry.rapayer > 0 ? Colors.red : Colors.green,
                        fontSize: _textSizeService.getScaledFontSize(14),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Date limite
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: _themeService.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Date limite: ${entry.formattedDateLimite}',
                      style: TextStyle(
                        color: _themeService.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        fontSize: _textSizeService.getScaledFontSize(14),
                      ),
                    ),
                    if (entry.isOverdue) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'EN RETARD',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: _textSizeService.getScaledFontSize(10),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showScolariteEntryDetails(StudentScolariteEntry entry) {
    final isDarkMode = _themeService.isDarkMode;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _themeService.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        title: Text(
          entry.libelle,
          style: TextStyle(
            color: _themeService.isDarkMode ? Colors.white : Colors.black,
            fontSize: _textSizeService.getScaledFontSize(18),
            fontWeight: FontWeight.w600,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Rubrique', entry.formattedRubrique),
              _buildDetailRow('Montant initial', _formatAmount(entry.montant0)),
              if (entry.remise > 0)
                _buildDetailRow('Remise', _formatAmount(entry.remise)),
              _buildDetailRow('Montant final', _formatAmount(entry.montant)),
              _buildDetailRow('Montant payé', _formatAmount(entry.paye)),
              _buildDetailRow('Restant à payer', _formatAmount(entry.rapayer)),
              _buildDetailRow('Date limite', entry.formattedDateLimite),
              _buildDetailRow('Statut', entry.formattedStatus),
              _buildDetailRow('Date d\'enregistrement', entry.formattedDateenreg),
              if (entry.isOverdue)
                _buildDetailRow('Retard', 'Oui - ${entry.daysUntilDeadline.abs()} jours', Colors.red),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Fermer',
              style: TextStyle(
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, [Color? color]) {
    final isDarkMode = _themeService.isDarkMode;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: _themeService.isDarkMode ? Colors.grey[400] : Colors.grey[600],
              fontSize: _textSizeService.getScaledFontSize(12),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: color ?? (_themeService.isDarkMode ? Colors.white : Colors.black),
              fontSize: _textSizeService.getScaledFontSize(14),
            ),
          ),
        ],
      ),
    );
  }

  String _formatAmount(int amount) {
    return '${amount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]} ',
        )} FCFA';
  }

  Widget _buildSimpleSuggestionsTab() {
    final isDarkMode = _themeService.isDarkMode;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildInfoCard(
            '💡 Suggestions',
            'Consultez et gérez les suggestions des parents pour améliorer l\'expérience scolaire.',
            Colors.purple,
          ),
          const SizedBox(height: 20),
          _buildDynamicSuggestions(),
        ],
      ),
    );
  }

  Widget _buildDynamicSuggestions() {
    if (_isLoadingSuggestions) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_suggestions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _themeService.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _themeService.isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.lightbulb_outline,
              size: 48,
              color: Colors.purple[400],
            ),
            const SizedBox(height: 12),
            Text(
              'Aucune suggestion disponible',
              style: TextStyle(
                fontSize: 16,
                color: _themeService.isDarkMode ? Colors.white70 : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _loadSuggestionsData(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
              ),
              child: const Text('Actualiser'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Statistiques
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _themeService.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _themeService.isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.analytics_outlined,
                    color: Colors.purple,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Statistiques des suggestions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: _themeService.isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem('Total', _suggestions.length.toString(), Colors.purple),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatItem('En attente', 
                      _suggestions.where((s) => s.status == SuggestionStatus.pending).length.toString(), 
                      Colors.orange),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatItem('Approuvées', 
                      _suggestions.where((s) => s.status == SuggestionStatus.approved).length.toString(), 
                      Colors.green),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Liste des suggestions récentes (limitées à 5 pour le bottom sheet)
        ..._suggestions.take(5).map((suggestion) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildSuggestionCard(suggestion),
        )).toList(),
        if (_suggestions.length > 5)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '... et ${_suggestions.length - 5} autres suggestions',
              style: TextStyle(
                color: _themeService.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }

  Widget _buildSuggestionCard(ParentSuggestion suggestion) {
    final isDarkMode = _themeService.isDarkMode;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _themeService.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getStatusColor(suggestion.status).withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showSuggestionDetails(suggestion),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header avec titre et statut
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        suggestion.title,
                        style: TextStyle(
                          color: _themeService.isDarkMode ? Colors.white : Colors.black,
                          fontSize: _textSizeService.getScaledFontSize(16),
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(suggestion.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        suggestion.status.displayName,
                        style: TextStyle(
                          color: _getStatusColor(suggestion.status),
                          fontSize: _textSizeService.getScaledFontSize(12),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Description
                Text(
                  suggestion.description,
                  style: TextStyle(
                    color: _themeService.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    fontSize: _textSizeService.getScaledFontSize(14),
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                // Métadonnées
                Row(
                  children: [
                    Icon(
                      Icons.person,
                      size: 16,
                      color: _themeService.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      suggestion.displayName,
                      style: TextStyle(
                        color: _themeService.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        fontSize: _textSizeService.getScaledFontSize(12),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: _themeService.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      suggestion.formattedCreatedAt,
                      style: TextStyle(
                        color: _themeService.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        fontSize: _textSizeService.getScaledFontSize(12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Catégorie et priorité
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getCategoryColor(suggestion.category).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        suggestion.category.displayName,
                        style: TextStyle(
                          color: _getCategoryColor(suggestion.category),
                          fontSize: _textSizeService.getScaledFontSize(11),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getPriorityColor(suggestion.priority).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        suggestion.priority.displayName,
                        style: TextStyle(
                          color: _getPriorityColor(suggestion.priority),
                          fontSize: _textSizeService.getScaledFontSize(11),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSuggestionDetails(ParentSuggestion suggestion) {
    final isDarkMode = _themeService.isDarkMode;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _themeService.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        title: Text(
          suggestion.title,
          style: TextStyle(
            color: _themeService.isDarkMode ? Colors.white : Colors.black,
            fontSize: _textSizeService.getScaledFontSize(18),
            fontWeight: FontWeight.w600,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                suggestion.description,
                style: TextStyle(
                  color: _themeService.isDarkMode ? Colors.white : Colors.black,
                  fontSize: _textSizeService.getScaledFontSize(14),
                ),
              ),
              const SizedBox(height: 16),
              _buildDetailRow('Auteur', suggestion.displayName),
              _buildDetailRow('Date', suggestion.formattedCreatedAt),
              _buildDetailRow('Catégorie', suggestion.category.displayName, _getCategoryColor(suggestion.category)),
              _buildDetailRow('Priorité', suggestion.priority.displayName, _getPriorityColor(suggestion.priority)),
              _buildDetailRow('Statut', suggestion.status.displayName, _getStatusColor(suggestion.status)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Fermer',
              style: TextStyle(
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleAccessLogsTab() {
    final isDarkMode = _themeService.isDarkMode;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildInfoCard(
            '📋 Logs d\'accès',
            'Consultez l\'historique des accès et entrées de votre enfant.',
            Colors.teal,
          ),
          const SizedBox(height: 20),
          _buildDynamicAccessLogs(),
        ],
      ),
    );
  }

  Widget _buildDynamicAccessLogs() {
    if (_isLoadingAccessLogs) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_accessLogs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _themeService.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _themeService.isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.history,
              size: 48,
              color: Colors.teal[400],
            ),
            const SizedBox(height: 12),
            Text(
              'Aucun log d\'accès disponible',
              style: TextStyle(
                fontSize: 16,
                color: _themeService.isDarkMode ? Colors.white70 : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _loadAccessLogsData(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
              ),
              child: const Text('Actualiser'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Statistiques
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _themeService.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _themeService.isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.analytics_outlined,
                    color: Colors.teal,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Statistiques des accès',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: _themeService.isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem('Total', _accessLogs.length.toString(), Colors.teal),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatItem('Entrées', 
                      _accessLogs.where((l) => l.accessType == AccessType.entry).length.toString(), 
                      Colors.green),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatItem('Sorties', 
                      _accessLogs.where((l) => l.accessType == AccessType.exit).length.toString(), 
                      Colors.orange),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Liste des logs récents (limités à 5 pour le bottom sheet)
        ..._accessLogs.take(5).map((log) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildAccessLogCard(log),
        )).toList(),
        if (_accessLogs.length > 5)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '... et ${_accessLogs.length - 5} autres logs',
              style: TextStyle(
                color: _themeService.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }

  Widget _buildAccessLogCard(AccessLog log) {
    final isDarkMode = _themeService.isDarkMode;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _themeService.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: log.accessType == AccessType.entry 
              ? Colors.green.withOpacity(0.3)
              : Colors.orange.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showAccessLogDetails(log),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header avec type et date
                Row(
                  children: [
                    Icon(
                      log.accessType == AccessType.entry ? Icons.login : Icons.logout,
                      color: log.accessType == AccessType.entry ? Colors.green : Colors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      log.accessType == AccessType.entry ? 'Entrée' : 'Sortie',
                      style: TextStyle(
                        color: log.accessType == AccessType.entry ? Colors.green : Colors.orange,
                        fontSize: _textSizeService.getScaledFontSize(16),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: (log.accessType == AccessType.entry ? Colors.green : Colors.orange).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        log.formattedTime,
                        style: TextStyle(
                          color: log.accessType == AccessType.entry ? Colors.green : Colors.orange,
                          fontSize: _textSizeService.getScaledFontSize(12),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Date et lieu
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: _themeService.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      log.formattedDate,
                      style: TextStyle(
                        color: _themeService.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        fontSize: _textSizeService.getScaledFontSize(14),
                      ),
                    ),
                  ],
                ),
                if (log.location?.isNotEmpty == true) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: _themeService.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        log.location!,
                        style: TextStyle(
                          color: _themeService.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                          fontSize: _textSizeService.getScaledFontSize(14),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAccessLogDetails(AccessLog log) {
    final isDarkMode = _themeService.isDarkMode;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _themeService.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        title: Text(
          log.accessType == AccessType.entry ? 'Détails de l\'entrée' : 'Détails de la sortie',
          style: TextStyle(
            color: _themeService.isDarkMode ? Colors.white : Colors.black,
            fontSize: _textSizeService.getScaledFontSize(18),
            fontWeight: FontWeight.w600,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Type', log.accessType == AccessType.entry ? 'Entrée' : 'Sortie'),
              _buildDetailRow('Date', log.formattedDate),
              _buildDetailRow('Heure', log.formattedTime),
              if (log.location?.isNotEmpty == true) _buildDetailRow('Lieu', log.location!),
              _buildDetailRow('Enfant', widget.child.fullName),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Fermer',
              style: TextStyle(
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleReservationsTab() {
    final isDarkMode = _themeService.isDarkMode;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildInfoCard(
            '🪑 Réservations',
            'Consultez et gérez les réservations de places pour votre enfant.',
            Colors.indigo,
          ),
          const SizedBox(height: 20),
          _buildDynamicReservations(),
        ],
      ),
    );
  }

  Widget _buildDynamicReservations() {
    if (_isLoadingReservations) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_reservations.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _themeService.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _themeService.isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.event_seat,
              size: 48,
              color: Colors.indigo[400],
            ),
            const SizedBox(height: 12),
            Text(
              'Aucune réservation disponible',
              style: TextStyle(
                fontSize: 16,
                color: _themeService.isDarkMode ? Colors.white70 : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _loadReservationsData(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
              ),
              child: const Text('Actualiser'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Statistiques
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _themeService.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _themeService.isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.analytics_outlined,
                    color: Colors.indigo,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Statistiques des réservations',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: _themeService.isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem('Total', _reservations.length.toString(), Colors.indigo),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatItem('Confirmées', 
                      _reservations.where((r) => r.status == ReservationStatus.confirmed).length.toString(), 
                      Colors.green),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatItem('En attente', 
                      _reservations.where((r) => r.status == ReservationStatus.pending).length.toString(), 
                      Colors.orange),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Liste des réservations récentes (limitées à 5 pour le bottom sheet)
        ..._reservations.take(5).map((reservation) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildReservationCard(reservation),
        )).toList(),
        if (_reservations.length > 5)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '... et ${_reservations.length - 5} autres réservations',
              style: TextStyle(
                color: _themeService.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }

  Widget _buildReservationCard(PlaceReservation reservation) {
    final isDarkMode = _themeService.isDarkMode;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _themeService.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getReservationStatusColor(reservation.status).withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showReservationDetails(reservation),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header avec lieu et statut
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        reservation.establishmentName,
                        style: TextStyle(
                          color: _themeService.isDarkMode ? Colors.white : Colors.black,
                          fontSize: _textSizeService.getScaledFontSize(16),
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getReservationStatusColor(reservation.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        reservation.status.displayName,
                        style: TextStyle(
                          color: _getReservationStatusColor(reservation.status),
                          fontSize: _textSizeService.getScaledFontSize(12),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Date et heure
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: _themeService.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      reservation.formattedCreatedAt,
                      style: TextStyle(
                        color: _themeService.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        fontSize: _textSizeService.getScaledFontSize(14),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: _themeService.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${reservation.createdAt.hour.toString().padLeft(2, '0')}:${reservation.createdAt.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        color: _themeService.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        fontSize: _textSizeService.getScaledFontSize(14),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Type de place
                Row(
                  children: [
                    Icon(
                      Icons.event_seat,
                      size: 16,
                      color: _themeService.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      reservation.type.displayName,
                      style: TextStyle(
                        color: _themeService.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        fontSize: _textSizeService.getScaledFontSize(14),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showReservationDetails(PlaceReservation reservation) {
    final isDarkMode = _themeService.isDarkMode;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _themeService.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        title: Text(
          reservation.establishmentName,
          style: TextStyle(
            color: _themeService.isDarkMode ? Colors.white : Colors.black,
            fontSize: _textSizeService.getScaledFontSize(18),
            fontWeight: FontWeight.w600,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Lieu', reservation.establishmentName),
              _buildDetailRow('Type', reservation.type.displayName),
              _buildDetailRow('Date', reservation.formattedCreatedAt),
              _buildDetailRow('Heure', '${reservation.createdAt.hour.toString().padLeft(2, '0')}:${reservation.createdAt.minute.toString().padLeft(2, '0')}'),
              _buildDetailRow('Statut', reservation.status.displayName, _getReservationStatusColor(reservation.status)),
              _buildDetailRow('Enfant', widget.child.fullName),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Fermer',
              style: TextStyle(
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Méthodes utilitaires pour les couleurs
  Color _getStatusColor(SuggestionStatus status) {
    switch (status) {
      case SuggestionStatus.pending:
        return Colors.orange;
      case SuggestionStatus.approved:
        return Colors.green;
      case SuggestionStatus.rejected:
        return Colors.red;
      case SuggestionStatus.underReview:
        return Colors.blue;
      case SuggestionStatus.implemented:
        return Colors.purple;
      case SuggestionStatus.closed:
        return Colors.grey;
    }
  }

  Color _getCategoryColor(SuggestionCategory category) {
    switch (category) {
      case SuggestionCategory.academic:
        return Colors.blue;
      case SuggestionCategory.infrastructure:
        return Colors.purple;
      case SuggestionCategory.security:
        return Colors.red;
      case SuggestionCategory.activities:
        return Colors.green;
      case SuggestionCategory.communication:
        return Colors.orange;
      case SuggestionCategory.nutrition:
        return Colors.brown;
      case SuggestionCategory.technology:
        return Colors.cyan;
      case SuggestionCategory.staff:
        return Colors.indigo;
      case SuggestionCategory.finance:
        return Colors.amber;
      case SuggestionCategory.general:
        return Colors.grey;
    }
  }

  Color _getPriorityColor(SuggestionPriority priority) {
    switch (priority) {
      case SuggestionPriority.low:
        return Colors.green;
      case SuggestionPriority.medium:
        return Colors.orange;
      case SuggestionPriority.high:
        return Colors.red;
      case SuggestionPriority.urgent:
        return Colors.purple;
    }
  }

  Color _getReservationStatusColor(ReservationStatus status) {
    switch (status) {
      case ReservationStatus.submitted:
        return Colors.lime;
      case ReservationStatus.draft:
        return Colors.grey;
      case ReservationStatus.pending:
        return Colors.orange;
      case ReservationStatus.confirmed:
        return Colors.green;
      case ReservationStatus.underReview:
        return Colors.blue;
      case ReservationStatus.waitlist:
        return Colors.purple;
      case ReservationStatus.rejected:
        return Colors.red;
      case ReservationStatus.cancelled:
        return Colors.brown;
      case ReservationStatus.completed:
        return Colors.teal;
    }
  }

  Widget _buildSimpleMessagesTab() {
    final isDarkMode = _themeService.isDarkMode;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildInfoCard(
            '💬 Messages',
            'Consultez les messages et communications pour votre enfant.',
            Colors.blue,
          ),
          const SizedBox(height: 20),
          _buildDynamicMessages(),
        ],
      ),
    );
  }

  Widget _buildDynamicMessages() {
    if (_isLoadingMessages) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_studentMessages.isEmpty) {
      // Vérifier si le matricule est disponible
      final matricule = widget.child.matricule;
      if (matricule == null || matricule.isEmpty) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _themeService.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.red.withOpacity(0.3),
            ),
          ),
          child: Column(
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: Colors.red[400],
              ),
              const SizedBox(height: 12),
              Text(
                'Matricule non disponible',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.red[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Le matricule de l\'enfant n\'est pas configuré. Veuillez contacter l\'administration.',
                style: TextStyle(
                  fontSize: 14,
                  color: _themeService.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }
      
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _themeService.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _themeService.isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.mail_outline,
              size: 48,
              color: Colors.blue[400],
            ),
            const SizedBox(height: 12),
            Text(
              'Aucun message disponible',
              style: TextStyle(
                fontSize: 16,
                color: _themeService.isDarkMode ? Colors.white70 : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _loadMessagesData(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Actualiser'),
            ),
          ],
        ),
      );
    }

    // Statistiques
    final totalMessages = _studentMessages.length;
    final unreadMessages = _studentMessages.where((m) => m.isUnread).length;
    final readMessages = totalMessages - unreadMessages;

    return Column(
      children: [
        // Carte de statistiques
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _themeService.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _themeService.isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.analytics_outlined,
                    color: Colors.blue,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Statistiques des messages',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: _themeService.isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem('Total', totalMessages.toString(), Colors.blue),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatItem('Non lus', unreadMessages.toString(), Colors.orange),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatItem('Lus', readMessages.toString(), Colors.green),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Liste des messages récents (limités à 5 pour le bottom sheet)
        ..._studentMessages.take(5).map((message) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildMessageCard(message),
        )).toList(),
        if (_studentMessages.length > 5)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '... et ${_studentMessages.length - 5} autres messages',
              style: TextStyle(
                color: _themeService.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }

  Widget _buildMessageCard(StudentMessage message) {
    final isDarkMode = _themeService.isDarkMode;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _themeService.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: message.isUnread 
              ? AppColors.primary.withOpacity(0.3)
              : _themeService.isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
          width: message.isUnread ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showMessageDetails(message),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        message.titre,
                        style: TextStyle(
                          color: _themeService.isDarkMode ? Colors.white : Colors.black,
                          fontSize: _textSizeService.getScaledFontSize(16),
                          fontWeight: message.isUnread 
                              ? FontWeight.w600 
                              : FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (message.isUnread)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Nouveau',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: _textSizeService.getScaledFontSize(10),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  message.description,
                  style: TextStyle(
                    color: _themeService.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    fontSize: _textSizeService.getScaledFontSize(14),
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: _themeService.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      message.formattedDate,
                      style: TextStyle(
                        color: _themeService.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        fontSize: _textSizeService.getScaledFontSize(12),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: message.isUnread 
                            ? Colors.orange.withOpacity(0.1)
                            : Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        message.formattedStatut,
                        style: TextStyle(
                          color: message.isUnread 
                              ? Colors.orange
                              : Colors.green,
                          fontSize: _textSizeService.getScaledFontSize(10),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showMessageDetails(StudentMessage message) {
    final isDarkMode = _themeService.isDarkMode;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _themeService.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        title: Text(
          message.titre,
          style: TextStyle(
            color: _themeService.isDarkMode ? Colors.white : Colors.black,
            fontSize: _textSizeService.getScaledFontSize(18),
            fontWeight: FontWeight.w600,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message.description,
                style: TextStyle(
                  color: _themeService.isDarkMode ? Colors.white : Colors.black,
                  fontSize: _textSizeService.getScaledFontSize(14),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: _themeService.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Envoyé le: ${message.formattedDate}',
                    style: TextStyle(
                      color: _themeService.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      fontSize: _textSizeService.getScaledFontSize(12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.mark_email_read,
                    size: 16,
                    color: _themeService.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Statut: ${message.formattedStatut}',
                    style: TextStyle(
                      color: _themeService.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      fontSize: _textSizeService.getScaledFontSize(12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Fermer',
              style: TextStyle(
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    final isDarkMode = _themeService.isDarkMode;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccessControlCard(AccessControlEntry entry) {
    final isDarkMode = _themeService.isDarkMode;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: entry.isStatusOk 
              ? Colors.green.withOpacity(0.2)
              : Colors.red.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: entry.isStatusOk 
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  entry.categoryIcon,
                  style: const TextStyle(fontSize: 20),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.formattedCategorie,
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ID: ${entry.pointageId}',
                      style: TextStyle(
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: entry.isStatusOk 
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: entry.isStatusOk 
                        ? Colors.green.withOpacity(0.3)
                        : Colors.red.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  entry.resultat,
                  style: TextStyle(
                    color: entry.isStatusOk ? Colors.green : Colors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 16,
                color: Colors.purple,
              ),
              const SizedBox(width: 6),
              Text(
                entry.formattedDate,
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 16),
              Icon(
                Icons.access_time,
                size: 16,
                color: Colors.purple,
              ),
              const SizedBox(width: 6),
              Text(
                entry.formattedTime,
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicDaySchedule(String day, List<StudentTimetableEntry> courses) {
    final isDarkMode = _themeService.isDarkMode;
    
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Text(
              day,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.orange[800],
              ),
            ),
          ),
          ...courses.map((course) => _buildDynamicCourseItem(course)).toList(),
        ],
      ),
    );
  }

  Widget _buildDynamicCourseItem(StudentTimetableEntry course) {
    final isDarkMode = _themeService.isDarkMode;
    final color = _getSubjectColor(course.matiere);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getSubjectIcon(course.matiere),
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course.matiere,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                Text(
                  course.formattedTime,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                if (course.professeur != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Prof: ${course.professeur}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode ? Colors.grey[500] : Colors.grey[500],
                    ),
                  ),
                ],
                if (course.salle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Salle: ${course.salle}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode ? Colors.grey[500] : Colors.grey[500],
                    ),
                  ),
                ],
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

  Future<void> _loadTimetableData() async {
    if (_isLoadingTimetable) return;
    
    final matricule = widget.child.matricule;
    print('🔄 Début du chargement de l\'emploi du temps pour: ${widget.child.fullName}');
    print('📋 Matricule: $matricule');
    
    if (matricule == null || matricule.isEmpty) {
      print('❌ Matricule non disponible pour l\'enfant: ${widget.child.fullName}');
      return;
    }
    
    print('✅ Matricule valide, début du chargement...');
    if (mounted) {
      setState(() {
        _isLoadingTimetable = true;
      });
    }

    try {
      print('📡 Appel du service StudentTimetableService...');
      
      // S'assurer que les données de l'école sont chargées
      if (!_schoolService.isSchoolDataLoaded) {
        print('🏫 Chargement des données de l\'école...');
        await _schoolService.loadSchoolData();
        print('✅ Données de l\'école chargées');
      }
      
      final response = await _timetableService.getTimetableForStudent(matricule);
      print('✅ Réponse reçue: ${response.data.length} créneaux');
      
      if (mounted) {
        setState(() {
          _timetableResponse = response;
          _isLoadingTimetable = false;
        });
        print('📊 Mise à jour de l\'UI terminée');
      }
    } catch (e) {
      print('❌ Erreur lors du chargement de l\'emploi du temps: $e');
      if (mounted) {
        setState(() {
          _isLoadingTimetable = false;
        });
      }
    }
  }

  Future<void> _loadAccessControlData() async {
    if (_isLoadingAccessControl) return;
    
    final matricule = widget.child.matricule ?? widget.child.id;
    print('🔄 Début du chargement du contrôle d\'accès pour: ${widget.child.fullName}');
    print('📋 Matricule: $matricule');
    
    if (matricule == null || matricule.isEmpty) {
      print('❌ Matricule non disponible pour l\'enfant: ${widget.child.fullName}');
      return;
    }
    
    print('✅ Matricule valide, début du chargement...');
    if (mounted) {
      setState(() {
        _isLoadingAccessControl = true;
      });
    }

    try {
      print('📡 Appel du service AccessControlService...');
      
      // S'assurer que les données de l'école sont chargées
      if (!_schoolService.isSchoolDataLoaded) {
        print('🏫 Chargement des données de l\'école...');
        await _schoolService.loadSchoolData();
        print('✅ Données de l\'école chargées');
      }
      
      final entries = await _accessControlService.getAccessControlEntriesForStudent(matricule);
      print('✅ Réponse reçue: ${entries.length} pointages');
      
      if (mounted) {
        setState(() {
          _accessEntries = entries;
          _isLoadingAccessControl = false;
        });
        print('📊 Mise à jour de l\'UI terminée');
      }
    } catch (e) {
      print('❌ Erreur lors du chargement du contrôle d\'accès: $e');
      if (mounted) {
        setState(() {
          _isLoadingAccessControl = false;
        });
      }
    }
  }

  Future<void> _loadMessagesData() async {
    if (_isLoadingMessages) return;
    
    final studentMatricule = widget.child.matricule ?? widget.child.id;
    print('🔄 Début du chargement des messages pour: ${widget.child.fullName}');
    print('📋 Matricule: $studentMatricule');
    
    if (studentMatricule == null || studentMatricule.isEmpty) {
      print('❌ Matricule non disponible pour l\'enfant: ${widget.child.fullName}');
      return;
    }
    
    print('✅ Matricule valide, début du chargement...');
    if (mounted) {
      setState(() {
        _isLoadingMessages = true;
      });
    }

    try {
      print('📡 Appel du service StudentMessageService...');
      final messages = await _messageService.getMessagesForStudent(studentMatricule);
      print('✅ Réponse reçue: ${messages.length} messages');
      
      if (mounted) {
        setState(() {
          _studentMessages = messages;
          _isLoadingMessages = false;
        });
        print('📊 Mise à jour de l\'UI terminée');
      }
    } catch (e) {
      print('❌ Erreur lors du chargement des messages: $e');
      if (mounted) {
        setState(() {
          _isLoadingMessages = false;
        });
      }
    }
  }

  Future<void> _loadScolariteData() async {
    if (_isLoadingScolarite) return;
    
    final studentMatricule = widget.child.matricule ?? widget.child.id;
    print('🔄 Début du chargement de la scolarité pour: ${widget.child.fullName}');
    print('📋 Matricule: $studentMatricule');
    
    if (studentMatricule == null || studentMatricule.isEmpty) {
      print('❌ Matricule non disponible pour l\'enfant: ${widget.child.fullName}');
      return;
    }
    
    print('✅ Matricule valide, début du chargement...');
    if (mounted) {
      setState(() {
        _isLoadingScolarite = true;
      });
    }

    try {
      print('📡 Appel du service StudentScolariteService...');
      final entries = await _scolariteService.getScolariteEntriesForStudent(studentMatricule);
      print('✅ Réponse reçue: ${entries.length} échéances');
      
      if (mounted) {
        setState(() {
          _scolariteEntries = entries;
          _isLoadingScolarite = false;
        });
        print('📊 Mise à jour de l\'UI terminée');
      }
    } catch (e) {
      print('❌ Erreur lors du chargement de la scolarité: $e');
      if (mounted) {
        setState(() {
          _isLoadingScolarite = false;
        });
      }
    }
  }

  Future<void> _loadSuggestionsData() async {
    if (_isLoadingSuggestions) return;
    
    print('🔄 Début du chargement des suggestions pour: ${widget.child.fullName}');
    
    if (mounted) {
      setState(() {
        _isLoadingSuggestions = true;
      });
    }

    try {
      print('📡 Appel du service ParentSuggestionService...');
      final suggestions = await _suggestionService.getRecentSuggestions(10);
      print('✅ Réponse reçue: ${suggestions.length} suggestions');
      
      if (mounted) {
        setState(() {
          _suggestions = suggestions;
          _isLoadingSuggestions = false;
        });
        print('📊 Mise à jour de l\'UI terminée');
      }
    } catch (e) {
      print('❌ Erreur lors du chargement des suggestions: $e');
      if (mounted) {
        setState(() {
          _isLoadingSuggestions = false;
        });
      }
    }
  }

  Future<void> _loadAccessLogsData() async {
    if (_isLoadingAccessLogs) return;
    
    final childId = widget.child.id;
    print('🔄 Début du chargement des logs d\'accès pour: ${widget.child.fullName}');
    print('📋 ID Enfant: $childId');
    
    if (childId == null || childId.isEmpty) {
      print('❌ ID enfant non disponible');
      return;
    }
    
    print('✅ ID valide, début du chargement...');
    if (mounted) {
      setState(() {
        _isLoadingAccessLogs = true;
      });
    }

    try {
      print('📡 Appel du service AccessLogService...');
      final logs = await _accessLogService.getAccessLogsForChild(childId);
      print('✅ Réponse reçue: ${logs.length} logs');
      
      if (mounted) {
        setState(() {
          _accessLogs = logs;
          _isLoadingAccessLogs = false;
        });
        print('📊 Mise à jour de l\'UI terminée');
      }
    } catch (e) {
      print('❌ Erreur lors du chargement des logs d\'accès: $e');
      if (mounted) {
        setState(() {
          _isLoadingAccessLogs = false;
        });
      }
    }
  }

  Future<void> _loadReservationsData() async {
    if (_isLoadingReservations) return;
    
    final childId = widget.child.id;
    print('🔄 Début du chargement des réservations pour: ${widget.child.fullName}');
    print('📋 ID Enfant: $childId');
    
    if (childId == null || childId.isEmpty) {
      print('❌ ID enfant non disponible');
      return;
    }
    
    print('✅ ID valide, début du chargement...');
    if (mounted) {
      setState(() {
        _isLoadingReservations = true;
      });
    }

    try {
      print('📡 Appel du service PlaceReservationService...');
      final reservations = await _reservationService.getRecentReservations(10);
      print('✅ Réponse reçue: ${reservations.length} réservations');
      
      if (mounted) {
        setState(() {
          _reservations = reservations;
          _isLoadingReservations = false;
        });
        print('📊 Mise à jour de l\'UI terminée');
      }
    } catch (e) {
      print('❌ Erreur lors du chargement des réservations: $e');
      if (mounted) {
        setState(() {
          _isLoadingReservations = false;
        });
      }
    }
  }

  Color _getSubjectColor(String subject) {
    final s = subject.toLowerCase();
    if (s.contains('math')) return Colors.blue;
    if (s.contains('fran')) return Colors.green;
    if (s.contains('histoir')) return Colors.orange;
    if (s.contains('phys') || s.contains('chim')) return Colors.purple;
    if (s.contains('angl')) return Colors.indigo;
    if (s.contains('sport') || s.contains('eps')) return Colors.red;
    if (s.contains('mus')) return Colors.amber;
    if (s.contains('art')) return Colors.pink;
    if (s.contains('svt')) return Colors.teal;
    if (s.contains('tech')) return Colors.cyan;
    return Colors.grey;
  }

  IconData _getSubjectIcon(String subject) {
    final s = subject.toLowerCase();
    if (s.contains('math')) return Icons.calculate_rounded;
    if (s.contains('fran')) return Icons.menu_book_rounded;
    if (s.contains('histoir')) return Icons.public_rounded;
    if (s.contains('phys') || s.contains('chim')) return Icons.science_rounded;
    if (s.contains('angl')) return Icons.language_rounded;
    if (s.contains('sport') || s.contains('eps')) return Icons.sports_soccer_rounded;
    if (s.contains('mus')) return Icons.music_note_rounded;
    if (s.contains('art')) return Icons.palette_rounded;
    if (s.contains('svt')) return Icons.biotech_rounded;
    if (s.contains('tech')) return Icons.computer_rounded;
    return Icons.school_rounded;
  }

  Widget _buildSimpleNotesTab() {
    final isDarkMode = _themeService.isDarkMode;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildInfoCard(
            '📊 Notes et évaluations',
            'Consultez les notes et évaluations de votre enfant pour suivre sa progression scolaire.',
            Colors.blue,
          ),
          const SizedBox(height: 20),
          _buildNotesList(),
        ],
      ),
    );
  }

  Widget _buildNotesList() {
    return Column(
      children: [
        _buildNoteCard(
          'Mathématiques',
          'Contrôle n°3 - Fractions',
          '15.5/20',
          'Très bien',
          Icons.calculate_rounded,
          Colors.green,
        ),
        const SizedBox(height: 12),
        _buildNoteCard(
          'Français',
          'Rédaction - Le voyage',
          '14/20',
          'Bien',
          Icons.menu_book_rounded,
          Colors.blue,
        ),
        const SizedBox(height: 12),
        _buildNoteCard(
          'Histoire-Géographie',
          'Test - La Révolution française',
          '16/20',
          'Très bien',
          Icons.public_rounded,
          Colors.orange,
        ),
        const SizedBox(height: 12),
        _buildNoteCard(
          'Sciences',
          'TP - Les écosystèmes',
          '13/20',
          'Assez bien',
          Icons.science_rounded,
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildNoteCard(
    String subject,
    String evaluation,
    String grade,
    String appreciation,
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
                  subject,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  evaluation,
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
                    const SizedBox(width: 8),
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
                        appreciation,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: color,
                        ),
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