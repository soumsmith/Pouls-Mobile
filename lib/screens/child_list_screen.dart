import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:parents_responsable/screens/inscription_screen.dart'
    as inscription;
import 'package:parents_responsable/widgets/image_menu_card.dart';
import '../widgets/custom_loader.dart';
import '../models/child.dart';
import '../models/note.dart';
import '../models/timetable_entry.dart';
import '../models/message.dart';
import '../models/fee.dart';
import '../models/school_supply.dart';
import '../services/pouls_scolaire_api_service.dart';
import '../services/database_service.dart';
import '../services/order_service.dart';
import '../models/order.dart';
import '../services/auth_service.dart';
import '../services/text_size_service.dart';
import '../config/app_colors.dart';
import '../config/app_config.dart';
import '../config/app_dimensions.dart';
import '../services/theme_service.dart';
import '../widgets/main_screen_wrapper.dart';
import '../screens/notes_screen_json.dart';
import '../services/student_timetable_service.dart';
import '../models/student_timetable.dart';
import '../services/school_service.dart';
import 'messages_screen.dart';
import '../services/access_control_service.dart';
import '../models/access_control.dart';
import '../services/school_supply_service.dart';
import '../services/paiement_service.dart';
import '../services/student_message_service.dart';
import '../models/student_message.dart';
import '../services/student_scolarite_service.dart';
import '../models/student_scolarite.dart';
import '../widgets/custom_sliver_app_bar.dart';
import '../widgets/section_header_widget.dart';
import '../widgets/main_screen_wrapper.dart';
import '../models/parent_suggestion.dart';
import '../services/parent_suggestion_service.dart';
import '../services/access_log_service.dart';
import '../models/access_log.dart';
import '../models/place_reservation.dart';
import '../services/inscription_api_service.dart' as api_service;
import '../models/student_class_info.dart';
import '../models/group_message.dart';
import '../models/ecole.dart';
import '../services/group_message_service.dart';
import '../widgets/custom_loader.dart';
import '../widgets/searchable_dropdown.dart';
import '../services/ecole_eleve_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

// ─── MODÈLE POUR CARTE DE MENU D'ÉLÈVE ────────────────────────────────────────
class StudentMenuCardItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? backgroundColor;
  final Color? iconColor;
  final Color? titleColor;
  final Color? descriptionColor;
  final String? badge;

  const StudentMenuCardItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.backgroundColor,
    this.iconColor,
    this.titleColor,
    this.descriptionColor,
    this.badge,
  });
}

// ─── MODÈLES POUR INSCRIPTION ────────────────────────────────────────────────────────
class Service {
  final String iddetail;
  final String service;
  final String? zoneId;
  final String designation;
  final String description;
  final int prix;
  final int prix2;
  final String? createdAt;
  final String? updatedAt;
  final String maitre;
  bool selectionnee;

  Service({
    required this.iddetail,
    required this.service,
    this.zoneId,
    required this.designation,
    required this.description,
    required this.prix,
    required this.prix2,
    this.createdAt,
    this.updatedAt,
    required this.maitre,
    this.selectionnee = false,
  });

  Echeance toEcheance() {
    return Echeance(
      echId: DateTime.now().millisecondsSinceEpoch,
      uid: iddetail,
      branche: "*",
      statut: "*",
      rubrique: service,
      pecheance: iddetail,
      montant: prix,
      montant2: prix2,
      dateLimite: DateTime.now()
          .add(const Duration(days: 30))
          .toString()
          .split(' ')[0], // Date par défaut
      libelle: designation,
      ordre: 0,
      rubriqueObligatoire: 1,
    );
  }

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      iddetail: json['iddetail'],
      service: json['service'],
      zoneId: json['zone_id'],
      designation: json['designation'],
      description: json['description'],
      prix: json['prix'],
      prix2: json['prix2'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      maitre: json['maitre'],
    );
  }
}

class Echeance {
  final int echId;
  final String uid;
  final String branche;
  final String statut;
  final String rubrique;
  final String pecheance;
  final int montant;
  final int montant2;
  final String dateLimite;
  final String libelle;
  final int ordre;
  final int rubriqueObligatoire;
  bool selectionnee;

  Echeance({
    required this.echId,
    required this.uid,
    required this.branche,
    required this.statut,
    required this.rubrique,
    required this.pecheance,
    required this.montant,
    required this.montant2,
    required this.dateLimite,
    required this.libelle,
    required this.ordre,
    required this.rubriqueObligatoire,
    this.selectionnee = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'ech_id': echId,
      'uid': uid,
      'branche': branche,
      'statut': statut,
      'rubrique': rubrique,
      'pecheance': pecheance,
      'montant': montant,
      'montant2': montant2,
      'datelimite': dateLimite,
      'libelle': libelle,
      'ordre': ordre,
      'rubrique_obligatoire': rubriqueObligatoire,
    };
  }

  factory Echeance.fromJson(Map<String, dynamic> json) {
    return Echeance(
      echId: json['ech_id'],
      uid: json['uid'],
      branche: json['branche'],
      statut: json['statut'],
      rubrique: json['rubrique'],
      pecheance: json['pecheance'],
      montant: json['montant'],
      montant2: json['montant2'],
      dateLimite: json['datelimite'],
      libelle: json['libelle'],
      ordre: json['ordre'],
      rubriqueObligatoire: json['rubrique_obligatoire'],
    );
  }
}

class InscriptionItem {
  final String id;
  final String service;
  final int montant;
  final bool reservation;
  List<Echeance> echeancesSelectionnees;

  InscriptionItem({
    required this.id,
    required this.service,
    required this.montant,
    required this.reservation,
    required this.echeancesSelectionnees,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'service': service,
      'montant': montant,
      'reservation': reservation,
      'echeancesSelectionnees': echeancesSelectionnees
          .map((e) => e.toJson())
          .toList(),
    };
  }
}

class InscriptionRequest {
  final List<InscriptionItem> ids;
  final Map<String, dynamic> engagement;
  final String type;
  final int separationFlux;
  final int systemeEducatif;

  InscriptionRequest({
    required this.ids,
    required this.engagement,
    required this.type,
    required this.separationFlux,
    required this.systemeEducatif,
  });

  Map<String, dynamic> toJson() {
    return {
      'ids': ids.map((item) => item.toJson()).toList(),
      'engagement': engagement,
      'type': type,
      'separation_flux': separationFlux,
      'systeme_educatif': systemeEducatif,
    };
  }
}

// ─── DESIGN TOKENS (centralisés dans AppColors) ────────────────────────────────

/// Écran de détail d'un enfant avec menu cartes
class ChildListScreen extends StatefulWidget {
  final Child child;

  const ChildListScreen({super.key, required this.child});

  @override
  State<ChildListScreen> createState() => _ChildListScreenState();
}

class _ChildListScreenState extends State<ChildListScreen>
    with TickerProviderStateMixin
    implements MainScreenChild {
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
  final MockParentSuggestionService _suggestionService =
      MockParentSuggestionService();
  final MockAccessLogService _accessLogService = MockAccessLogService();

  // Variables pour la gestion des commandes
  List<Order> _orders = [];
  bool _isLoadingOrders = false;

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

  // Variables pour les demandes d'intégration
  List<Ecole> _ecoles = [];
  bool _isLoadingEcoles = false;
  int? _selectedEcoleId;
  String? _selectedEcoleName;
  bool _isLoadingIntegrationRequest = false;

  // Variables pour les notifications
  List<GroupMessage> _notifications = [];
  bool _isLoadingNotifications = false;
  bool _notificationsLoaded = false; // ✅ AJOUT ICI

  // Compter les notifications non lues
  int get unreadNotificationsCount =>
      _notifications.where((notification) => !notification.estLu).length;

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

  // Informations supplémentaires de la classe/école
  StudentClassInfo? _studentClassInfo;

  // Détails complets de l'élève
  Map<String, dynamic>? _eleveDetail;

  // État pour l'affichage des informations détaillées
  bool _showEleveDetails = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _loadData();
    _loadEcoles();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
      final suppliesResponse = await _schoolSupplyService.getSchoolSupplies(
        _matricule!,
      );

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
          SnackBar(
            content: Text('Erreur lors du chargement des fournitures: $e'),
          ),
        );
      }
    }
  }

  Future<void> _loadOrders() async {
    final authService = AuthService();
    final currentUser = authService.getCurrentUser();
    
    if (currentUser?.phone == null) {
      print('⚠️ Impossible de charger les commandes: téléphone utilisateur manquant');
      return;
    }

    setState(() {
      _isLoadingOrders = true;
    });

    try {
      print('📦 Chargement des commandes pour le téléphone: ${currentUser!.phone}');
      final orders = await OrderService().getUserOrders(currentUser!.phone);

      setState(() {
        _orders = orders;
        _isLoadingOrders = false;
      });

      print('✅ Commandes chargées: ${_orders.length} commandes');
    } catch (e) {
      print('❌ Erreur lors du chargement des commandes: $e');
      setState(() {
        _isLoadingOrders = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement des commandes: $e'),
          ),
        );
      }
    }
  }

  Future<void> _loadData() async {
    print(
      '📋 Début du chargement des données pour l\'enfant: ${widget.child.id}',
    );
    setState(() {
      _isLoading = true;
    });

    try {
      final apiService = MainScreenWrapper.of(context).apiService;

      // Étape 1: Charger les informations de l'enfant d'abord
      print('📂 Étape 1: Récupération des informations de l\'enfant...');
      await _loadChildInfo();

      // Étape 2: Charger les données de l'école si le code est disponible
      if (_ecoleCode != null && _ecoleCode!.isNotEmpty) {
        print('🏫 Étape 2: Chargement des données de l\'école...');
        print('🏷️ Code école de l\'élève: $_ecoleCode');
        print('👤 Élève: ${widget.child.firstName} ${widget.child.lastName}');
        print(
          '📡 [API] Appel à EcoleEleveService.getEcoleParametresForEleve()',
        );
        print(
          '🔗 [API] URL: ${AppConfig.VIE_ECOLES_API_BASE_URL}/vie-ecoles/parametre/ecole?ecole=$_ecoleCode',
        );

        try {
          final ecoleData = await EcoleEleveService.getEcoleParametresForEleve(
            _ecoleCode!,
          );
          print('✅ Données de l\'école chargées avec succès');
          print('📊 [API] Résumé des données reçues:');
          print('   - Nom: ${ecoleData.nom}');
          print('   - Ville: ${ecoleData.ville}');
          print('   - Statut: ${ecoleData.statut}');
          print('   - Année: ${ecoleData.annee}');
          print('   - Période: ${ecoleData.periode}');
          print('   - Effectif: ${ecoleData.effectif} élèves');
          print('📅 [API] Périodes d\'inscription:');
          print(
            '   - Préinscription: ${ecoleData.debutPreinscrit} au ${ecoleData.finPreinscrit}',
          );
          print(
            '   - Inscription: ${ecoleData.debutInscrit} au ${ecoleData.finInscrit}',
          );
          print(
            '   - Réservation: ${ecoleData.debutReservation} au ${ecoleData.finReservation}',
          );
        } catch (e) {
          print(
            '❌ [API] Erreur lors du chargement des données de l\'école: $e',
          );
          print(
            '⚠️ [API] Continuité du chargement malgré l\'erreur de l\'API école',
          );
          // Continuer le chargement même si l'école échoue
        }
      } else {
        print(
          '⚠️ Étape 2: Aucun code école disponible pour l\'élève ${widget.child.firstName} ${widget.child.lastName}',
        );
        print(
          '🔍 Recherche du code école dans les informations de l\'élève...',
        );
        print(
          '   - ecoleCode depuis widget.child.ecoleCode: ${widget.child.ecoleCode}',
        );
        print('   - _ecoleCode depuis base de données: $_ecoleCode');
      }

      // Étape 3: Charger les autres données (timetable, messages, fees)
      print('📊 Étape 3: Chargement des données de base...');
      final results = await Future.wait([
        apiService.getNotesForChild(widget.child.id),
        apiService.getTimetableForChild(widget.child.id),
        apiService.getMessages(
          MainScreenWrapper.of(context).currentUserId ?? 'parent1',
        ),
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

      // Étape 4: Plus de chargement des données de notes globales (API supprimée)
      print('📊 Étape 4: Chargement des notes désactivé');

      // Étape 5: Charger les informations détaillées de la classe/école
      print(
        '🏫 Étape 5: Chargement des informations détaillées de la classe/école...',
      );
      if (_studentClassInfo == null &&
          _matricule != null &&
          _anneeId != null &&
          _classeId != null) {
        await _loadStudentClassInfo();
      }
    } catch (e) {
      print('❌ Erreur lors du chargement des données: $e');
      print('Stack trace: ${StackTrace.current}');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  Future<void> _loadChildInfo() async {
    try {
      print(
        '📂 Récupération des informations de l\'enfant depuis la base de données...',
      );
      final childInfo = await DatabaseService.instance.getChildInfoById(
        widget.child.id,
      );

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
            final anneeScolaire = await _poulsApiService
                .getAnneeScolaireOuverte(_ecoleId!);
            setState(() {
              _anneeId = anneeScolaire.anneeOuverteCentraleId;
            });
            print('   📅 Année ID: $_anneeId');
          } catch (e) {
            print('❌ Erreur lors du chargement de l\'année scolaire: $e');
          }
        }

        // Charger les informations détaillées de la classe/école avec la nouvelle API
        if (_matricule != null && _anneeId != null && _classeId != null) {
          await _loadStudentClassInfo();
        }

        // Charger les détails complets de l'élève (après avoir récupéré le code école)
        if (_matricule != null) {
          if (_ecoleCode != null) {
            print('📋 Étape 6: Chargement des détails complets de l\'élève...');
            await _loadEleveDetail();
          } else {
            print(
              '⚠️ Étape 6: Détails de l\'élève non chargés - code école manquant',
            );
            print('   - Matricule: $_matricule');
            print('   - Code école: $_ecoleCode');
            print('   - Tentative de chargement après _loadStudentClassInfo()');
          }
        } else {
          print(
            '⚠️ Étape 6: Détails de l\'élève non chargés - matricule manquant',
          );
          print('   - Matricule: $_matricule');
        }
      } else {
        print('❌ Aucune information trouvée pour l\'enfant ${widget.child.id}');
      }
    } catch (e) {
      print('❌ Erreur lors du chargement des informations de l\'enfant: $e');
    }
  }

  Future<void> _loadStudentClassInfo() async {
    if (_matricule == null || _anneeId == null || _classeId == null) {
      print('⚠️ Informations manquantes pour charger les infos classe/école');
      return;
    }

    try {
      print('🏫 Chargement des informations détaillées de la classe/école...');
      final studentClassInfo = await _poulsApiService.getStudentClassInfo(
        _matricule!,
        _anneeId!,
        _classeId!,
      );

      setState(() {
        _studentClassInfo = studentClassInfo;
        // Extraire le code école depuis identifiantVieEcole
        if (_ecoleCode == null &&
            studentClassInfo.identifiantVieEcole.isNotEmpty) {
          _ecoleCode = studentClassInfo.identifiantVieEcole;
          print(
            '🏷️ Code école extrait depuis identifiantVieEcole: $_ecoleCode',
          );
        }
      });

      print('✅ Informations classe/école chargées:');
      print('   🏫 École: ${_studentClassInfo!.ecole.libelle}');
      print('   📚 Classe: ${_studentClassInfo!.classe.libelle}');
      print('   👤 Élève: ${_studentClassInfo!.eleve.fullName}');
      print('   🏷️ ID Vie École: ${_studentClassInfo!.identifiantVieEcole}');
      print('   🏷️ Code école utilisé: $_ecoleCode');
    } catch (e) {
      print('❌ Erreur lors du chargement des informations classe/école: $e');
      // Ne pas bloquer le processus si cette API échoue
    }
  }

  Future<void> _loadEleveDetail() async {
    print('');
    print('═══════════════════════════════════════════════════════════');
    print('🔄 CHARGEMENT DES DÉTAILS DE L\'ÉLÈVE');
    print('═══════════════════════════════════════════════════════════');
    print('👤 Élève: ${widget.child.fullName} (${widget.child.id})');
    print(
      '🎫 Matricule disponible: ${_matricule != null ? "✅ $_matricule" : "❌ NON"}',
    );
    print(
      '🏷️ Code école disponible: ${_ecoleCode != null ? "✅ $_ecoleCode" : "❌ NON"}',
    );

    if (_matricule == null || _ecoleCode == null) {
      print('⚠️ Informations manquantes pour charger les détails de l\'élève');
      print('   - Matricule: $_matricule');
      print('   - Code école: $_ecoleCode');
      print('═══════════════════════════════════════════════════════════');
      print('');
      return;
    }

    try {
      print('📡 Appel de l\'API EcoleEleveService.getEleveDetail()...');
      print('⏱️ Heure de début: ${DateTime.now().toIso8601String()}');

      final eleveDetail = await EcoleEleveService.getEleveDetail(
        _matricule!,
        _ecoleCode!,
      );

      print('⏱️ Heure de fin: ${DateTime.now().toIso8601String()}');
      print('✅ Détails de l\'élève reçus avec succès');
      print('📊 Résumé des données reçues:');
      print(
        '   - Nom complet: ${eleveDetail['nom']} ${eleveDetail['prenoms']}',
      );
      print('   - Matricule: ${eleveDetail['matricule']}');
      print('   - Niveau: ${eleveDetail['niveau']}');
      print('   - Filière: ${eleveDetail['filiere']}');
      print('   - Sexe: ${eleveDetail['sexe']}');
      print('   - Date de naissance: ${eleveDetail['datenaissance']}');
      print('   - Nombre de champs: ${eleveDetail.keys.length}');

      setState(() {
        _eleveDetail = eleveDetail;
      });

      print('✅ Détails de l\'élève chargés et stockés avec succès');
      print('═══════════════════════════════════════════════════════════');
      print('');
    } catch (e) {
      print('❌ Erreur lors du chargement des détails de l\'élève: $e');
      print(
        '⚠️ L\'application continuera de fonctionner sans les détails complets',
      );
      print('═══════════════════════════════════════════════════════════');
      print('');
      // Ne pas bloquer le processus si cette API échoue
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = _themeService.isDarkMode;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : AppColors.screenSurface,
      body: CustomScrollView(
        slivers: [
          _buildModernSliverAppBar(),
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  _buildModernProfileHeader(),
                  // const SizedBox(height: 20),
                  // _buildEleveDetailSection(),
                  const SizedBox(height: 16),
                  _buildModernSummaryCards(),
                  const SizedBox(height: 16),
                  _buildPaymentBannerCard(),
                  const SizedBox(height: 24),
                  const SizedBox(height: 150),
                ],
              ),
            ),
          ),
        ],
      ),
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
          backgroundColor: const Color(0xFFE8F5E9),
          iconColor: const Color(0xFF2E7D32),
        );
      case 'integrationRequests':
        return StudentMenuCardItem(
          icon: Icons.school_rounded,
          label: 'Demandes d\'intégration',
          onTap: () {},
          backgroundColor: const Color(0xFFE3F2FD),
          iconColor: const Color(0xFF1565C0),
        );
      default:
        return StudentMenuCardItem(
          icon: Icons.help_rounded,
          label: 'Inconnu',
          onTap: () {},
        );
    }
  }

  void _showStudentMenuBottomSheet(
    String menuType,
    StudentMenuCardItem cardItem,
  ) {
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
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
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
                    color:
                        cardItem.backgroundColor ??
                        (isDark ? Colors.grey[800] : Colors.grey[50]),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
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
                          color:
                              cardItem.backgroundColor?.withOpacity(0.3) ??
                              Colors.grey.withOpacity(0.1),
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
                                fontSize: _textSizeService.getScaledFontSize(
                                  20,
                                ),
                                fontWeight: FontWeight.bold,
                                color:
                                    cardItem.titleColor ??
                                    (isDark ? Colors.white : Colors.black),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _getStudentMenuDescription(menuType),
                              style: TextStyle(
                                fontSize: _textSizeService.getScaledFontSize(
                                  14,
                                ),
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(
                          Icons.close,
                          color:
                              cardItem.titleColor ??
                              (isDark ? Colors.white : Colors.black),
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: SingleChildScrollView(
                    //padding: const EdgeInsets.all(20),
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

  void _showNotificationsBottomSheet() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            // ✅ Déclencher le chargement UNE SEULE FOIS à l'intérieur du modal
            if (!_notificationsLoaded && !_isLoadingNotifications) {
              _isLoadingNotifications = true;
              final matricule = _matricule ?? widget.child.matricule;
              if (matricule != null && matricule.isNotEmpty) {
                GroupMessageService.getGroupMessages(matricule)
                    .then((notifications) {
                      if (mounted) {
                        setModalState(() {
                          _notifications = notifications;
                          _isLoadingNotifications = false;
                          _notificationsLoaded = true;
                        });
                        setState(() {
                          _notifications = notifications;
                          _isLoadingNotifications = false;
                          _notificationsLoaded = true;
                        });
                      }
                    })
                    .catchError((e) {
                      print('❌ Erreur notifications: $e');
                      if (mounted) {
                        setModalState(() {
                          _isLoadingNotifications = false;
                          _notificationsLoaded = true;
                        });
                        setState(() {
                          _isLoadingNotifications = false;
                          _notificationsLoaded = true;
                        });
                      }
                    });
              } else {
                _isLoadingNotifications = false;
                _notificationsLoaded = true;
              }
            }

            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[900] : Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
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
                  // Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F2FD),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
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
                            color: Colors.blue.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.notifications_rounded,
                            color: Color(0xFF1976D2),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Notifications',
                                style: TextStyle(
                                  fontSize: _textSizeService.getScaledFontSize(
                                    20,
                                  ),
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF0D47A1),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _isLoadingNotifications
                                    ? 'Chargement en cours...'
                                    : _notifications.isEmpty
                                    ? 'Aucun message disponible'
                                    : '${_notifications.length} message${_notifications.length > 1 ? 's' : ''}',
                                style: TextStyle(
                                  fontSize: _textSizeService.getScaledFontSize(
                                    14,
                                  ),
                                  color: isDark
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(
                            Icons.close,
                            color: Color(0xFF0D47A1),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Content
                  Expanded(
                    child: _isLoadingNotifications
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32),
                              child: CircularProgressIndicator(
                                color: Color(0xFF1976D2),
                              ),
                            ),
                          )
                        : _notifications.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.notifications_off_outlined,
                                    size: 64,
                                    color: isDark
                                        ? Colors.grey[600]
                                        : Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Aucune notification',
                                    style: TextStyle(
                                      fontSize: _textSizeService
                                          .getScaledFontSize(16),
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? Colors.grey[400]
                                          : Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Vous n\'avez pas encore reçu de messages',
                                    style: TextStyle(
                                      fontSize: _textSizeService
                                          .getScaledFontSize(14),
                                      color: isDark
                                          ? Colors.grey[600]
                                          : Colors.grey[400],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _notifications.length,
                            itemBuilder: (context, index) {
                              final notification = _notifications[index];
                              return _buildNotificationCard(
                                notification,
                                setModalState,
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildNotificationCard(
    GroupMessage notification,
    StateSetter setModalState,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: notification.estLu
            ? (isDark ? Colors.grey[800] : Colors.grey[50])
            : (isDark ? const Color(0xFF1E3A5F) : const Color(0xFFE3F2FD)),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: notification.estLu
              ? (isDark ? Colors.grey[700]! : Colors.grey[200]!)
              : (isDark ? const Color(0xFF1976D2) : const Color(0xFF1976D2)),
          width: notification.estLu ? 1 : 2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            if (!notification.estLu) {
              _markNotificationAsRead(notification.id, setModalState);
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            notification.titre,
                            style: TextStyle(
                              fontSize: _textSizeService.getScaledFontSize(16),
                              fontWeight: notification.estLu
                                  ? FontWeight.w500
                                  : FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            notification.expediteurDisplay,
                            style: TextStyle(
                              fontSize: _textSizeService.getScaledFontSize(12),
                              color: isDark
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!notification.estLu)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  notification.contenu,
                  style: TextStyle(
                    fontSize: _textSizeService.getScaledFontSize(14),
                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      notification.formattedDate,
                      style: TextStyle(
                        fontSize: _textSizeService.getScaledFontSize(11),
                        color: isDark ? Colors.grey[500] : Colors.grey[500],
                      ),
                    ),
                    if (!notification.estLu)
                      TextButton(
                        onPressed: () => _markNotificationAsRead(
                          notification.id,
                          setModalState,
                        ),
                        child: Text(
                          'Marquer comme lu',
                          style: TextStyle(
                            fontSize: _textSizeService.getScaledFontSize(12),
                            color: const Color(0xFF1976D2),
                            fontWeight: FontWeight.w500,
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

  Future<void> _markNotificationAsRead(
    String messageId,
    StateSetter setModalState,
  ) async {
    final matricule = _matricule ?? widget.child.matricule;
    if (matricule == null || matricule.isEmpty) {
      print('❌ Matricule non disponible pour marquer le message comme lu');
      return;
    }

    try {
      print('📝 Marquage du message $messageId comme lu...');
      final success = await GroupMessageService.markMessageAsRead(
        messageId,
        matricule,
      );

      if (success) {
        // Mettre à jour l'état local
        setModalState(() {
          final index = _notifications.indexWhere((n) => n.id == messageId);
          if (index != -1) {
            _notifications[index] = _notifications[index].copyWith(estLu: true);
          }
        });

        // Mettre à jour l'état du widget
        if (mounted) {
          setState(() {
            final index = _notifications.indexWhere((n) => n.id == messageId);
            if (index != -1) {
              _notifications[index] = _notifications[index].copyWith(
                estLu: true,
              );
            }
          });
        }

        print('✅ Message marqué comme lu avec succès');
      } else {
        print('❌ Échec du marquage du message comme lu');
      }
    } catch (e) {
      print('❌ Erreur lors du marquage du message: $e');
    }
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
      case 'integrationRequests':
        return 'Consultez vos demandes d\'intégration scolaire';
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
      case 'integrationRequests':
        return _buildIntegrationRequestsTab();
      default:
        return Container(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: Text(
              'Contenu en cours de développement...',
              style: TextStyle(
                color: _themeService.isDarkMode
                    ? Colors.white70
                    : Colors.grey[600],
              ),
            ),
          ),
        );
    }
  }

  Widget _buildModernSliverAppBar() {
    final isDarkMode = _themeService.isDarkMode;
    
    return CustomSliverAppBar(
      title: widget.child.fullName,
      isDark: isDarkMode,
      expandedHeight: 80,
      actions: [
        _buildNotificationButton(),
        _buildMoreButton(),
      ],
      titleTextStyle: TextStyle(
        fontSize: _textSizeService.getScaledFontSize(16),
        fontWeight: FontWeight.w700,
        color: isDarkMode ? Colors.white : Theme.of(context).textTheme.titleLarge?.color,
        letterSpacing: -0.5,
      ),
    );
  }

  Widget _buildNotificationButton() {
    final theme = Theme.of(context);
    final isDarkMode = _themeService.isDarkMode;
    
    return Container(
      margin: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF2A2A2A) : AppColors.screenCard,
        borderRadius: BorderRadius.circular(AppDimensions.getButtonBorderRadius(context)),
        boxShadow: const [
          BoxShadow(
            color: AppColors.screenShadow,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          IconButton(
            icon: Icon(
              Icons.notifications_outlined,
              color: theme.iconTheme.color,
            ),
            onPressed: () => _showNotificationsBottomSheet(),
          ),
          // Badge pour les notifications non lues
          if (unreadNotificationsCount > 0)
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                padding: EdgeInsets.all(AppDimensions.getBadgePadding(context)),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(AppDimensions.getBadgeBorderRadius(context)),
                  border: Border.all(color: AppColors.screenCard, width: 2),
                ),
                constraints: BoxConstraints(
                  minWidth: AppDimensions.getBadgeMinSize(context),
                  minHeight: AppDimensions.getBadgeMinSize(context),
                ),
                child: Text(
                  unreadNotificationsCount > 99
                      ? '99+'
                      : unreadNotificationsCount.toString(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: AppDimensions.getBadgeFontSize(context),
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMoreButton() {
    final theme = Theme.of(context);
    final isDarkMode = _themeService.isDarkMode;
    
    return Container(
      margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF2A2A2A) : AppColors.screenCard,
        borderRadius: BorderRadius.circular(AppDimensions.getButtonBorderRadius(context)),
        boxShadow: const [
          BoxShadow(
            color: AppColors.screenShadow,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(Icons.more_vert, color: theme.iconTheme.color),
        onPressed: () {},
      ),
    );
  }

  Widget _buildModernProfileHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: EdgeInsets.symmetric(horizontal: AppDimensions.getMainContainerPadding(context), vertical: 16),
      decoration: BoxDecoration(
        gradient: AppColors.screenOrangeGradient,
        borderRadius: BorderRadius.circular(AppDimensions.getMainContainerBorderRadius(context)),
        boxShadow: [
          BoxShadow(
            color: AppColors.screenOrange.withOpacity(0.3),
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
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 2,
                  ),
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
                    const SizedBox(height: 2),
                    Text(
                      widget.child.establishment,
                      style: TextStyle(
                        fontSize: _textSizeService.getScaledFontSize(13),
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          widget.child.grade,
                          style: TextStyle(
                            fontSize: _textSizeService.getScaledFontSize(14),
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (_eleveDetail != null) ...[
                          SizedBox(width: 8),
                          Text(
                            '|',
                            style: TextStyle(
                              fontSize: _textSizeService.getScaledFontSize(14),
                              color: Colors.white.withOpacity(0.5),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            _eleveDetail!['sexe']?.toString() ?? 'N/A',
                            style: TextStyle(
                              fontSize: _textSizeService.getScaledFontSize(14),
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            '|',
                            style: TextStyle(
                              fontSize: _textSizeService.getScaledFontSize(14),
                              color: Colors.white.withOpacity(0.5),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              _eleveDetail!['nationalite']?.toString() ?? 'N/A',
                              style: TextStyle(
                                fontSize: _textSizeService.getScaledFontSize(14),
                                color: Colors.white.withOpacity(0.9),
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ],
                    ),
                    
                  ],
                ),
              ),
            ],
          ),

          // Section des informations détaillées de l'élève
          if (_showEleveDetails && _eleveDetail != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: EdgeInsets.all(AppDimensions.getProfileDetailsPadding(context)),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(AppDimensions.getProfileDetailsBorderRadius(context)),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  // Titre Informations personnelles
                  _buildSectionTitle('Informations personnelles'),
                  SizedBox(height: AppDimensions.getProfileDetailsSpacing(context)),
                  
                  // Layout responsive pour les informations personnelles
                  if (AppDimensions.isMobile(context)) ...[
                    // Mobile : une seule colonne
                    _buildProfileDetailItem(
                      icon: Icons.badge,
                      label: 'Matricule',
                      value: _eleveDetail!['matricule']?.toString() ?? 'N/A',
                    ),
                    SizedBox(height: AppDimensions.getProfileDetailsSpacing(context)),
                    _buildProfileDetailItem(
                      icon: Icons.cake,
                      label: 'Né(e)',
                      value: _formatDate(
                        _eleveDetail!['datenaissance']?.toString() ?? 'N/A',
                      ),
                    ),
                    SizedBox(height: AppDimensions.getProfileDetailsSpacing(context)),
                    _buildProfileDetailItem(
                      icon: Icons.wc,
                      label: 'Sexe',
                      value: _eleveDetail!['sexe']?.toString() ?? 'N/A',
                    ),
                    SizedBox(height: AppDimensions.getProfileDetailsSpacing(context)),
                    _buildProfileDetailItem(
                      icon: Icons.location_on,
                      label: 'Lieu',
                      value: _eleveDetail!['lieun']?.toString() ?? 'N/A',
                    ),
                    SizedBox(height: AppDimensions.getProfileDetailsSpacing(context)),
                    _buildProfileDetailItem(
                      icon: Icons.phone,
                      label: 'Mobile',
                      value: _eleveDetail!['mobile']?.toString() ?? 'N/A',
                      isClickable: true,
                      onTap: () => _makePhoneCall(
                        _eleveDetail!['mobile']?.toString() ?? '',
                      ),
                    ),
                    SizedBox(height: AppDimensions.getProfileDetailsSpacing(context)),
                    _buildProfileDetailItem(
                      icon: Icons.flag,
                      label: 'Nationalité',
                      value: _eleveDetail!['nationalite']?.toString() ?? 'N/A',
                    ),
                  ] else ...[
                    // Tablettes : deux colonnes
                    Row(
                      children: [
                        _buildProfileDetailItem(
                          icon: Icons.badge,
                          label: 'Matricule',
                          value: _eleveDetail!['matricule']?.toString() ?? 'N/A',
                        ),
                        SizedBox(width: AppDimensions.getProfileDetailsSpacing(context)),
                        _buildProfileDetailItem(
                          icon: Icons.cake,
                          label: 'Né(e)',
                          value: _formatDate(
                            _eleveDetail!['datenaissance']?.toString() ?? 'N/A',
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppDimensions.getProfileDetailsSpacing(context)),
                    Row(
                      children: [
                        _buildProfileDetailItem(
                          icon: Icons.wc,
                          label: 'Sexe',
                          value: _eleveDetail!['sexe']?.toString() ?? 'N/A',
                        ),
                        SizedBox(width: AppDimensions.getProfileDetailsSpacing(context)),
                        _buildProfileDetailItem(
                          icon: Icons.location_on,
                          label: 'Lieu',
                          value: _eleveDetail!['lieun']?.toString() ?? 'N/A',
                        ),
                      ],
                    ),
                    SizedBox(height: AppDimensions.getProfileDetailsSpacing(context)),
                    Row(
                      children: [
                        _buildProfileDetailItem(
                          icon: Icons.phone,
                          label: 'Mobile',
                          value: _eleveDetail!['mobile']?.toString() ?? 'N/A',
                          isClickable: true,
                          onTap: () => _makePhoneCall(
                            _eleveDetail!['mobile']?.toString() ?? '',
                          ),
                        ),
                        SizedBox(width: AppDimensions.getProfileDetailsSpacing(context)),
                        _buildProfileDetailItem(
                          icon: Icons.flag,
                          label: 'Nationalité',
                          value: _eleveDetail!['nationalite']?.toString() ?? 'N/A',
                        ),
                      ],
                    ),
                  ],

                  SizedBox(height: AppDimensions.getProfileDetailsSpacing(context) * 1.5),

                  // Titre Informations scolaires
                  _buildSectionTitle('Informations scolaires'),
                  SizedBox(height: AppDimensions.getProfileDetailsSpacing(context)),

                  // Layout responsive pour les informations scolaires
                  if (AppDimensions.isMobile(context)) ...[
                    // Mobile : une seule colonne
                    _buildProfileDetailItem(
                      icon: Icons.grade,
                      label: 'Niveau',
                      value: _eleveDetail!['niveau']?.toString() ?? 'N/A',
                    ),
                    SizedBox(height: AppDimensions.getProfileDetailsSpacing(context)),
                    _buildProfileDetailItem(
                      icon: Icons.category,
                      label: 'Filière',
                      value: _eleveDetail!['filiere']?.toString() ?? 'N/A',
                    ),
                    SizedBox(height: AppDimensions.getProfileDetailsSpacing(context)),
                    // _buildProfileDetailItem(
                    //   icon: Icons.book,
                    //   label: 'Branche',
                    //   value: _eleveDetail!['branche']?.toString() ?? 'N/A',
                    // ),
                    SizedBox(height: AppDimensions.getProfileDetailsSpacing(context)),
                    _buildProfileDetailItem(
                      icon: Icons.auto_stories,
                      label: 'Série',
                      value: _eleveDetail!['serie']?.toString() ?? 'N/A',
                    ),
                    SizedBox(height: AppDimensions.getProfileDetailsSpacing(context)),
                    Row(
                      children: [
                        _buildProfileDetailItem(
                          icon: Icons.refresh,
                          label: 'Redoublant',
                          value: _eleveDetail!['redoublant']?.toString() ?? 'N/A',
                          valueColor:
                              _eleveDetail!['redoublant']
                                          ?.toString()
                                          .toLowerCase() ==
                                      'oui'
                                  ? Colors.orange
                                  : Colors.green,
                        ),
                        SizedBox(width: AppDimensions.getProfileDetailsSpacing(context)),
                        _buildProfileDetailItem(
                          icon: Icons.family_restroom,
                          label: 'Famille',
                          value: 'Voir détails',
                          isClickable: true,
                          onTap: () => _showFamilyBottomSheet(),
                        ),
                      ],
                    ),
                  ] else ...[
                    // Tablettes : deux colonnes
                    Row(
                      children: [
                        _buildProfileDetailItem(
                          icon: Icons.grade,
                          label: 'Niveau',
                          value: _eleveDetail!['niveau']?.toString() ?? 'N/A',
                        ),
                        SizedBox(width: AppDimensions.getProfileDetailsSpacing(context)),
                        _buildProfileDetailItem(
                          icon: Icons.category,
                          label: 'Filière',
                          value: _eleveDetail!['filiere']?.toString() ?? 'N/A',
                        ),
                      ],
                    ),
                    SizedBox(height: AppDimensions.getProfileDetailsSpacing(context)),
                    Row(
                      children: [
                        _buildProfileDetailItem(
                          icon: Icons.book,
                          label: 'Branche',
                          value: _eleveDetail!['branche']?.toString() ?? 'N/A',
                        ),
                        SizedBox(width: AppDimensions.getProfileDetailsSpacing(context)),
                        _buildProfileDetailItem(
                          icon: Icons.auto_stories,
                          label: 'Série',
                          value: _eleveDetail!['serie']?.toString() ?? 'N/A',
                        ),
                      ],
                    ),
                    SizedBox(height: AppDimensions.getProfileDetailsSpacing(context)),
                    Row(
                      children: [
                        _buildProfileDetailItem(
                          icon: Icons.refresh,
                          label: 'Redoublant',
                          value: _eleveDetail!['redoublant']?.toString() ?? 'N/A',
                          valueColor:
                              _eleveDetail!['redoublant']
                                          ?.toString()
                                          .toLowerCase() ==
                                      'oui'
                                  ? Colors.orange
                                  : Colors.green,
                        ),
                        SizedBox(width: AppDimensions.getProfileDetailsSpacing(context)),
                        _buildProfileDetailItem(
                          icon: Icons.family_restroom,
                          label: 'Famille',
                          value: 'Voir détails',
                          isClickable: true,
                          onTap: () => _showFamilyBottomSheet(),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildEleveDetailsButton(),
                SizedBox(width: AppDimensions.getDetailsButtonSpacing(context)),
                _buildFamilyDetailsButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFamilyDetailsButton() {
    return Align(
      alignment: Alignment.centerLeft,
      child: GestureDetector(
        onTap: () => _showFamilyBottomSheet(),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppDimensions.getDetailsButtonPaddingHorizontal(context),
            vertical: AppDimensions.getDetailsButtonPaddingVertical(context),
          ),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.25),
            borderRadius: BorderRadius.circular(AppDimensions.getDetailsButtonBorderRadius(context)),
            border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon(
              //   Icons.family_restroom,
              //   size: AppDimensions.getActionButtonSize(context) * 0.45,
              //   color: Colors.white.withOpacity(0.9),
              // ),
              // SizedBox(width: AppDimensions.getDetailsButtonSpacing(context) * 0.66),
              Text(
                'Infos Familles',
                style: TextStyle(
                  fontSize: AppDimensions.getDetailsButtonFontSize(context),
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(width: AppDimensions.getDetailsButtonSpacing(context) * 0.66),
              Icon(
                Icons.arrow_forward_ios,
                size: AppDimensions.getActionButtonSize(context) * 0.35,
                color: Colors.white.withOpacity(0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEleveDetailsButton() {
    return Align(
      alignment: Alignment.centerLeft,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _showEleveDetails = !_showEleveDetails;
          });
        },
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppDimensions.getDetailsButtonPaddingHorizontal(context),
            vertical: AppDimensions.getDetailsButtonPaddingVertical(context),
          ),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.25),
            borderRadius: BorderRadius.circular(AppDimensions.getDetailsButtonBorderRadius(context)),
            border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _showEleveDetails ? Icons.info : Icons.info_outline,
                size: AppDimensions.getActionButtonSize(context) * 0.45,
                color: Colors.white.withOpacity(0.9),
              ),
              SizedBox(width: AppDimensions.getDetailsButtonSpacing(context) * 0.66),
              Text(
                _showEleveDetails ? 'Moins d\'infos' : 'Plus d\'infos',
                style: TextStyle(
                  fontSize: AppDimensions.getDetailsButtonFontSize(context),
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(width: AppDimensions.getDetailsButtonSpacing(context) * 0.66),
              Icon(
                _showEleveDetails
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                size: AppDimensions.getActionButtonSize(context) * 0.35,
                color: Colors.white.withOpacity(0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileDetailItem({
    required IconData icon,
    required String label,
    required String value,
    bool isClickable = false,
    VoidCallback? onTap,
    Color? valueColor,
  }) {
    final defaultColor = valueColor ?? (Colors.white);

    return GestureDetector(
      onTap: isClickable && onTap != null ? onTap : null,
      child: Container(
        width: AppDimensions.getProfileDetailItemWidth(context),
        padding: EdgeInsets.symmetric(
          horizontal: AppDimensions.getProfileDetailsSpacing(context) * 0.5,
          vertical: AppDimensions.getProfileDetailsSpacing(context) * 0.25,
        ),
        decoration: BoxDecoration(
          color: isClickable
              ? Colors.white.withOpacity(0.25)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppDimensions.getProfileDetailsBorderRadius(context) * 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon, 
              size: AppDimensions.getActionButtonSize(context) * 0.35, 
              color: Colors.white.withOpacity(0.8)
            ),
            SizedBox(width: AppDimensions.getProfileDetailsSpacing(context) * 0.5),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: AppDimensions.getDetailsButtonFontSize(context) * 0.85,
                      color: Colors.white.withOpacity(0.7),
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: AppDimensions.getProfileDetailsSpacing(context) * 0.25),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: AppDimensions.getDetailsButtonFontSize(context) * 0.85,
                      color: defaultColor,
                      fontWeight: FontWeight.w600,
                      decoration: isClickable ? TextDecoration.underline : null,
                      decorationColor: Colors.white.withOpacity(0.5),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isClickable)
              Padding(
                padding: EdgeInsets.only(left: AppDimensions.getProfileDetailsSpacing(context) * 0.25),
                child: Icon(
                  Icons.call,
                  size: AppDimensions.getActionButtonSize(context) * 0.3,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: AppDimensions.getProfileDetailsPadding(context) * 0.5,
        vertical: AppDimensions.getProfileDetailsSpacing(context) * 0.5,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.getProfileDetailsBorderRadius(context) * 0.5),
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: AppDimensions.getDetailsButtonFontSize(context),
          color: Colors.white,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  void _showFamilyBottomSheet() {
    if (_eleveDetail == null) return;

    final eleve = _eleveDetail!;
    final isDarkMode = _themeService.isDarkMode;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey[900] : Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header du bottomSheet
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.family_restroom,
                        color: Colors.blue,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'Informations familiales',
                        style: TextStyle(
                          fontSize: _textSizeService.getScaledFontSize(18),
                          fontWeight: FontWeight.w700,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? Colors.grey[700]
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          Icons.close,
                          color: isDarkMode
                              ? Colors.grey[300]
                              : Colors.grey[600],
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Contenu familial
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Contact
                      _buildFamilySection(
                        title: 'Contact',
                        icon: Icons.contact_phone,
                        iconColor: Colors.green,
                        children: [
                          _buildFamilyItem(
                            icon: Icons.home,
                            label: 'Adresse',
                            value: eleve['adresse']?.toString() ?? 'N/A',
                          ),
                          _buildFamilyItem(
                            icon: Icons.phone,
                            label: 'Mobile',
                            value: eleve['mobile']?.toString() ?? 'N/A',
                            isClickable: true,
                            onTap: () => _makePhoneCall(
                              eleve['mobile']?.toString() ?? '',
                            ),
                          ),
                          if (eleve['mobile2']?.toString().isNotEmpty == true)
                            _buildFamilyItem(
                              icon: Icons.phone_android,
                              label: 'Mobile 2',
                              value: eleve['mobile2']?.toString() ?? 'N/A',
                              isClickable: true,
                              onTap: () => _makePhoneCall(
                                eleve['mobile2']?.toString() ?? '',
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Parents
                      _buildFamilySection(
                        title: 'Parents',
                        icon: Icons.people,
                        iconColor: Colors.purple,
                        children: [
                          _buildFamilyItem(
                            icon: Icons.person_outline,
                            label: 'Père',
                            value: eleve['pere']?.toString() ?? 'N/A',
                          ),
                          _buildFamilyItem(
                            icon: Icons.person_outline,
                            label: 'Mère',
                            value: eleve['mere']?.toString() ?? 'N/A',
                          ),
                          _buildFamilyItem(
                            icon: Icons.supervisor_account,
                            label: 'Tuteur',
                            value: eleve['tuteur']?.toString() ?? 'N/A',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFamilySection({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Widget> children,
  }) {
    final isDarkMode = _themeService.isDarkMode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: _textSizeService.getScaledFontSize(16),
                fontWeight: FontWeight.w700,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildFamilyItem({
    required IconData icon,
    required String label,
    required String value,
    bool isClickable = false,
    VoidCallback? onTap,
  }) {
    final isDarkMode = _themeService.isDarkMode;

    return GestureDetector(
      onTap: isClickable && onTap != null ? onTap : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isClickable
              ? (isDarkMode ? Colors.grey[700] : Colors.blue[50])
              : (isDarkMode ? Colors.grey[800] : Colors.grey[50]),
          borderRadius: BorderRadius.circular(12),
          border: isClickable
              ? Border.all(color: Colors.blue.withOpacity(0.2), width: 1)
              : Border.all(
                  color: isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
                  width: 1,
                ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isClickable
                    ? Colors.blue.withOpacity(0.15)
                    : (isDarkMode ? Colors.grey[700] : Colors.grey[200]),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 16,
                color: isClickable
                    ? Colors.blue
                    : (isDarkMode ? Colors.grey[400] : Colors.grey[600]),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: _textSizeService.getScaledFontSize(12),
                      fontWeight: FontWeight.w600,
                      color: isClickable
                          ? Colors.blue[700]
                          : (isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: _textSizeService.getScaledFontSize(14),
                      fontWeight: FontWeight.w600,
                      color: isClickable
                          ? Colors.blue[800]
                          : (isDarkMode ? Colors.white : Colors.black87),
                      decoration: isClickable ? TextDecoration.underline : null,
                      decorationColor: Colors.blue[400],
                    ),
                  ),
                ],
              ),
            ),
            if (isClickable)
              Icon(Icons.call, size: 16, color: Colors.blue[600]),
          ],
        ),
      ),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    if (phoneNumber.isEmpty || phoneNumber == 'N/A') return;

    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);

    // Utiliser url_launcher pour faire l'appel
    // Vous devrez ajouter le package url_launcher à pubspec.yaml
    print('📞 Appel du numéro: $phoneNumber');
    // await launchUrl(launchUri);
  }

  // ─── Helper : En-tête de section (barre colorée + titre) ──────────────────
  Widget _buildSectionHeader(String title, Color accentColor) {
    return SectionHeaderWidget(
      title: title,
      isDark: _themeService.isDarkMode,
      accentColor: accentColor,
    );
  }

  // ─── Helper : Rangée horizontale scrollable de ImageMenuCard ──────────────
  Widget _buildHorizontalCards(List<Widget> cards) {
    return SizedBox(
      height: 140,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 16, right: 4),
        children: cards,
      ),
    );
  }

  // ─── NOUVEAU _buildPaymentBannerCard() ─────────────────────────────────────
  Widget _buildPaymentBannerCard() {
    final isDark = _themeService.isDarkMode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ════════════════════════════════════════════════════════════════
        // SECTION 1 : Paiements & Inscription
        // ════════════════════════════════════════════════════════════════
        _buildSectionHeader('Paiements & Inscription', const Color(0xFF10B981)),
        _buildHorizontalCards([
          ImageMenuCard(
            index: 0,
            cardKey: 'paiement',
            title: 'Paiement en ligne',
            iconData: Icons.payments_rounded,
            isDark: isDark,
            color: const Color(0xFF10B981),
            backgroundColor: isDark
                ? const Color(0xFF0D2E20)
                : const Color(0xFFECFDF5),
            textColor: isDark
                ? const Color(0xFF6EE7B7)
                : const Color(0xFF065F46),
            actionText: 'Payer maintenant',
            actionTextColor: const Color(0xFF10B981),
            onTap: _showPaiementBottomSheet,
          ),
          ImageMenuCard(
            index: 1,
            cardKey: 'inscription',
            //title: 'Inscription',
            isDark: isDark,
            imagePath: 'assets/images/inscription.png',
            color: const Color(0xFF3B82F6),
            backgroundColor: isDark
                ? const Color(0xFF0D1B35)
                : const Color(0xFFEFF6FF),
            textColor: isDark
                ? const Color(0xFF93C5FD)
                : const Color(0xFF1E40AF),
            actionText: 'Gérer',
            actionTextColor: const Color(0xFF3B82F6),
            onTap: () {
              print('🎯 Navigation vers InscriptionWizardScreen');
              print('👤 Élève: ${widget.child.fullName}');
              print('🆔 UID de l\'élève: ${_eleveDetail?['uid']}');
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => inscription.InscriptionWizardScreen(
                    child: widget.child,
                    uid: _eleveDetail?['uid'],
                  ),
                ),
              );
            },
          ),
          ImageMenuCard(
            index: 2,
            cardKey: 'scolarite',
            title: 'Scolarité',
            iconData: Icons.account_balance_wallet_rounded,
            isDark: isDark,
            //imagePath: 'assets/images/intro_background.jpg',
            color: const Color(0xFFF59E0B),
            backgroundColor: isDark
                ? const Color(0xFF2D1E00)
                : const Color(0xFFFFFBEB),
            textColor: isDark
                ? const Color(0xFFFCD34D)
                : const Color(0xFF92400E),
            actionText: 'Voir échéances',
            actionTextColor: const Color(0xFFF59E0B),
            onTap: () async {
              if (_scolariteEntries.isEmpty && !_isLoadingScolarite) {
                await _loadScolariteData();
              }
              if (mounted) {
                _showStudentMenuBottomSheet(
                  'fees',
                  _getStudentMenuCardItem('fees'),
                );
              }
            },
          ),
          ImageMenuCard(
            index: 3,
            cardKey: 'integration_requests',
            title: 'Demandes d\'intégration',
            iconData: Icons.school_rounded,
            isDark: isDark,
            color: const Color(0xFF1565C0),
            backgroundColor: isDark
                ? const Color(0xFF0A2540)
                : const Color(0xFFE3F2FD),
            textColor: isDark
                ? const Color(0xFF64B5F6)
                : const Color(0xFF0D47A1),
            actionText: 'Consulter',
            actionTextColor: const Color(0xFF1565C0),
            onTap: () {
              if (mounted) {
                _showStudentMenuBottomSheet(
                  'integrationRequests',
                  _getStudentMenuCardItem('integrationRequests'),
                );
              }
            },
          ),
        ]),

        const SizedBox(height: 24),

        // ════════════════════════════════════════════════════════════════
        // SECTION 2 : Suivi scolaire
        // ════════════════════════════════════════════════════════════════
        _buildSectionHeader('Suivi scolaire', const Color(0xFF1976D2)),
        _buildHorizontalCards([
          ImageMenuCard(
            index: 0,
            cardKey: 'notes',
            title: 'Mes Notes',
            imagePath: 'assets/images/notes.jpg',
            iconData: Icons.bar_chart_rounded,
            isDark: isDark,
            color: const Color(0xFF1976D2),
            backgroundColor: isDark
                ? const Color(0xFF0D1A2E)
                : const Color(0xFFE3F2FD),
            textColor: isDark
                ? const Color(0xFF90CAF9)
                : const Color(0xFF0D47A1),
            actionText: 'Consulter',
            actionTextColor: const Color(0xFF1976D2),
            onTap: () {
              if (_matricule != null && _anneeId != null && _classeId != null) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => NotesScreenJson(
                      matricule: _matricule!,
                      anneeId: _anneeId!.toString(),
                      classeId: _classeId!.toString(),
                      anneeLibelle:
                          'Année scolaire ${DateTime.now().year}-${DateTime.now().year + 1}',
                    ),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Informations élève non disponibles'),
                  ),
                );
              }
            },
          ),
          ImageMenuCard(
            index: 1,
            cardKey: 'bulletins',
            title: 'Bulletins',
            iconData: Icons.description_rounded,
            isDark: isDark,
            color: const Color(0xFF2E7D32),
            backgroundColor: isDark
                ? const Color(0xFF0D2010)
                : const Color(0xFFE8F5E9),
            textColor: isDark
                ? const Color(0xFFA5D6A7)
                : const Color(0xFF1B5E20),
            actionText: 'Voir bulletins',
            actionTextColor: const Color(0xFF2E7D32),
            onTap: () => _showStudentMenuBottomSheet(
              'bulletins',
              _getStudentMenuCardItem('bulletins'),
            ),
          ),
          ImageMenuCard(
            index: 2,
            cardKey: 'timetable',
            title: 'Emploi du temps',
            imagePath: 'assets/images/emploi-du-temps.jpg',
            width: 200,
            iconData: Icons.calendar_today_rounded,
            isDark: isDark,
            color: const Color(0xFFF57C00),
            backgroundColor: isDark
                ? const Color(0xFF2D1600)
                : const Color(0xFFFFF3E0),
            textColor: isDark
                ? const Color(0xFFFFCC80)
                : const Color(0xFFE65100),
            actionText: 'Voir emploi',
            actionTextColor: const Color(0xFFF57C00),
            onTap: () async {
              if (_timetableResponse == null && !_isLoadingTimetable) {
                await _loadTimetableData();
              }
              if (mounted) {
                _showStudentMenuBottomSheet(
                  'timetable',
                  _getStudentMenuCardItem('timetable'),
                );
              }
            },
          ),
          ImageMenuCard(
            index: 3,
            cardKey: 'homework',
            title: 'Devoirs',
            iconData: Icons.edit_note_rounded,
            isDark: isDark,
            color: const Color(0xFF7B1FA2),
            backgroundColor: isDark
                ? const Color(0xFF1E0A2E)
                : const Color(0xFFF3E5F5),
            textColor: isDark
                ? const Color(0xFFCE93D8)
                : const Color(0xFF4A148C),
            actionText: 'Voir devoirs',
            actionTextColor: const Color(0xFF7B1FA2),
            onTap: () => _showStudentMenuBottomSheet(
              'homework',
              _getStudentMenuCardItem('homework'),
            ),
          ),
          ImageMenuCard(
            index: 4,
            cardKey: 'difficulties',
            title: 'Difficultés',
            iconData: Icons.psychology_rounded,
            isDark: isDark,
            color: const Color(0xFF9C27B0),
            backgroundColor: isDark
                ? const Color(0xFF1E0A2E)
                : const Color(0xFFF3E5F5),
            textColor: isDark
                ? const Color(0xFFCE93D8)
                : const Color(0xFF6A1B9A),
            actionText: 'Voir suivi',
            actionTextColor: const Color(0xFF9C27B0),
            onTap: () => _showStudentMenuBottomSheet(
              'difficulties',
              _getStudentMenuCardItem('difficulties'),
            ),
          ),
        ]),

        const SizedBox(height: 24),

        // ════════════════════════════════════════════════════════════════
        // SECTION 3 : Vie scolaire
        // ════════════════════════════════════════════════════════════════
        _buildSectionHeader('Vie scolaire', const Color(0xFF00796B)),
        _buildHorizontalCards([
          ImageMenuCard(
            index: 0,
            cardKey: 'attendance',
            title: 'Présence & Conduite',
            iconData: Icons.person_off_rounded,
            isDark: isDark,
            color: const Color(0xFF00796B),
            backgroundColor: isDark
                ? const Color(0xFF00201A)
                : const Color(0xFFE0F2F1),
            textColor: isDark
                ? const Color(0xFF80CBC4)
                : const Color(0xFF004D40),
            actionText: 'Voir présence',
            actionTextColor: const Color(0xFF00796B),
            onTap: () => _showStudentMenuBottomSheet(
              'attendance',
              _getStudentMenuCardItem('attendance'),
            ),
          ),
          ImageMenuCard(
            index: 1,
            cardKey: 'accessControl',
            title: 'Contrôle accès',
            iconData: Icons.fingerprint_rounded,
            isDark: isDark,
            color: const Color(0xFFC2185B),
            backgroundColor: isDark
                ? const Color(0xFF2E0618)
                : const Color(0xFFFCE4EC),
            textColor: isDark
                ? const Color(0xFFF48FB1)
                : const Color(0xFF880E4F),
            actionText: 'Voir accès',
            actionTextColor: const Color(0xFFC2185B),
            onTap: () async {
              if (_accessEntries.isEmpty && !_isLoadingAccessControl) {
                await _loadAccessControlData();
              }
              if (mounted) {
                _showStudentMenuBottomSheet(
                  'accessControl',
                  _getStudentMenuCardItem('accessControl'),
                );
              }
            },
          ),
          ImageMenuCard(
            index: 2,
            cardKey: 'sanctions',
            title: 'Sanctions',
            iconData: Icons.warning_rounded,
            isDark: isDark,
            color: const Color(0xFFD32F2F),
            backgroundColor: isDark
                ? const Color(0xFF2E0000)
                : const Color(0xFFFFEBEE),
            textColor: isDark
                ? const Color(0xFFEF9A9A)
                : const Color(0xFFB71C1C),
            actionText: 'Voir sanctions',
            actionTextColor: const Color(0xFFD32F2F),
            onTap: () => _showStudentMenuBottomSheet(
              'sanctions',
              _getStudentMenuCardItem('sanctions'),
            ),
          ),
          ImageMenuCard(
            index: 3,
            cardKey: 'school_events',
            title: 'Événements',
            iconData: Icons.event_rounded,
            isDark: isDark,
            color: const Color(0xFF3F51B5),
            backgroundColor: isDark
                ? const Color(0xFF0D1024)
                : const Color(0xFFE8EAF6),
            textColor: isDark
                ? const Color(0xFF9FA8DA)
                : const Color(0xFF283593),
            actionText: 'Voir events',
            actionTextColor: const Color(0xFF3F51B5),
            onTap: () => _showStudentMenuBottomSheet(
              'events',
              _getStudentMenuCardItem('events'),
            ),
          ),
        ]),

        const SizedBox(height: 24),

        // ════════════════════════════════════════════════════════════════
        // SECTION 4 : Communications
        // ════════════════════════════════════════════════════════════════
        _buildSectionHeader('Communications', const Color(0xFF0288D1)),
        _buildHorizontalCards([
          ImageMenuCard(
            index: 0,
            cardKey: 'communication',
            title: 'Messages',
            imagePath: 'assets/images/messages.jpg',
            iconData: Icons.message_rounded,
            isDark: isDark,
            //width: 165,
            color: const Color(0xFF0288D1),
            backgroundColor: isDark
                ? const Color(0xFF001A2E)
                : const Color(0xFFE1F5FE),
            textColor: isDark
                ? const Color(0xFF81D4FA)
                : const Color(0xFF01579B),
            actionText: 'Voir messages',
            actionTextColor: const Color(0xFF0288D1),
            onTap: () async {
              if (_studentMessages.isEmpty && !_isLoadingMessages) {
                await _loadMessagesData();
              }
              if (mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MessagesScreen(),
                  ),
                );
              }
            },
          ),
          ImageMenuCard(
            index: 1,
            cardKey: 'voir_les_avis',
            title: 'Suggestions',
            iconData: Icons.lightbulb_rounded,
            isDark: isDark,
            color: const Color(0xFFFFB300),
            backgroundColor: isDark
                ? const Color(0xFF2A1E00)
                : const Color(0xFFFFF8E1),
            textColor: isDark
                ? const Color(0xFFFFE082)
                : const Color(0xFFFF6F00),
            actionText: 'Voir suggestions',
            actionTextColor: const Color(0xFFFFB300),
            onTap: () async {
              if (_suggestions.isEmpty && !_isLoadingSuggestions) {
                await _loadSuggestionsData();
              }
              if (mounted) {
                _showStudentMenuBottomSheet(
                  'suggestions',
                  _getStudentMenuCardItem('suggestions'),
                );
              }
            },
          ),
        ]),

        const SizedBox(height: 24),

        // ════════════════════════════════════════════════════════════════
        // SECTION 5 : Services
        // ════════════════════════════════════════════════════════════════
        _buildSectionHeader('Services', const Color(0xFF795548)),
        _buildHorizontalCards([
          ImageMenuCard(
            index: 0,
            cardKey: 'niveaux',
            title: 'Fournitures',
            imagePath: 'assets/images/foutnitures-scolaire.jpg',
            height: 110,
            width: 110,
            iconData: Icons.inventory_2_rounded,
            isDark: isDark,
            color: const Color(0xFF795548),
            backgroundColor: isDark
                ? const Color(0xFF1A0E08)
                : const Color(0xFFEFEBE9),
            textColor: isDark
                ? const Color(0xFFBCAAA4)
                : const Color(0xFF4E342E),
            actionText: 'Voir liste',
            actionTextColor: const Color(0xFF795548),
            onTap: () => _showStudentMenuBottomSheet(
              'supplies',
              _getStudentMenuCardItem('supplies'),
            ),
          ),
          ImageMenuCard(
            index: 1,
            cardKey: 'consult_requests',
            //title: 'Commandes',
            imagePath: 'assets/images/mes-commandes.jpg',
            height: 110,
            width: 210,
            iconData: Icons.shopping_cart_rounded,
            isDark: isDark,
            color: const Color(0xFF00ACC1),
            backgroundColor: isDark
                ? const Color(0xFF00202A)
                : const Color(0xFFE0F7FA),
            textColor: isDark
                ? const Color(0xFF80DEEA)
                : const Color(0xFF00838F),
            actionText: 'Voir commandes',
            actionTextColor: const Color(0xFF00ACC1),
            onTap: () => _showStudentMenuBottomSheet(
              'orders',
              _getStudentMenuCardItem('orders'),
            ),
          ),
          ImageMenuCard(
            index: 2,
            cardKey: 'informations',
            title: 'Réservations',
            height: 110,
            width: 110,
            iconData: Icons.event_seat_rounded,
            isDark: isDark,
            color: const Color(0xFF4CAF50),
            backgroundColor: isDark
                ? const Color(0xFF0D2010)
                : const Color(0xFFE8F5E9),
            textColor: isDark
                ? const Color(0xFFA5D6A7)
                : const Color(0xFF2E7D32),
            actionText: 'Voir réservations',
            actionTextColor: const Color(0xFF4CAF50),
            onTap: () async {
              if (_reservations.isEmpty && !_isLoadingReservations) {
                await _loadReservationsData();
              }
              if (mounted) {
                _showStudentMenuBottomSheet(
                  'reservations',
                  _getStudentMenuCardItem('reservations'),
                );
              }
            },
          ),
          ImageMenuCard(
            index: 3,
            cardKey: 'niveaux',
            title: "Logs d'accès",
            iconData: Icons.security_rounded,
            isDark: isDark,
            color: const Color(0xFF616161),
            backgroundColor: isDark
                ? const Color(0xFF1A1A1A)
                : const Color(0xFFEEEEEE),
            textColor: isDark
                ? const Color(0xFFBDBDBD)
                : const Color(0xFF212121),
            actionText: 'Voir logs',
            actionTextColor: const Color(0xFF616161),
            onTap: () async {
              if (_accessLogs.isEmpty && !_isLoadingAccessLogs) {
                await _loadAccessLogsData();
              }
              if (mounted) {
                _showStudentMenuBottomSheet(
                  'accessLogs',
                  _getStudentMenuCardItem('accessLogs'),
                );
              }
            },
          ),
        ]),
      ],
    );
  }

  Widget _buildDefaultAvatar() {
    return const Icon(Icons.person, size: 30, color: Colors.white);
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
                color: AppColors.screenCard,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.screenShadow,
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
                                  color: AppColors.screenDivider,
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
                                      colors: [
                                        const Color(0xFFFF7A3C),
                                        AppColors.screenOrange,
                                      ],
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
                                        color: AppColors.screenTextPrimary,
                                        letterSpacing: -0.4,
                                      ),
                                    ),
                                    Text(
                                      'Entrez le montant à payer pour ${widget.child.firstName}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors.screenTextSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                IconButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  icon: const Icon(
                                    Icons.close,
                                    color: AppColors.screenTextSecondary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const Divider(
                              color: AppColors.screenDivider,
                              height: 1,
                            ),
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
                                  color: AppColors.screenTextPrimary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                decoration: BoxDecoration(
                                  color: AppColors.screenSurface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: AppColors.screenDivider,
                                  ),
                                ),
                                child: TextField(
                                  controller: montantController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    hintText: 'Ex: 10000',
                                    prefixIcon: const Icon(
                                      Icons.attach_money,
                                      color: AppColors.screenTextSecondary,
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.all(16),
                                  ),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: AppColors.screenTextPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              _buildModernPaymentButton(
                                label: isLoading ? '' : 'Procéder au paiement',
                                onTap: isLoading
                                    ? null
                                    : () => _effectuerPaiement(
                                        montantController.text,
                                        setState,
                                        () {
                                          setState(() {
                                            isLoading = true;
                                          });
                                        },
                                        () {
                                          setState(() {
                                            isLoading = false;
                                          });
                                        },
                                      ),
                                isLoading: isLoading,
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.screenOrangeLight
                                      .withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.screenOrange.withOpacity(
                                      0.2,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      color: AppColors.screenOrange,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Le paiement sera traité via notre partenaire WicPay',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.screenOrange,
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

  Future<List<Service>> _loadServices() async {
    try {
      const String ecoleCode = "gainhs";
      final String url =
          "${AppConfig.VIE_ECOLES_API_BASE_URL}/preinscription/services?ecole=$ecoleCode";

      print('🔄 Chargement des services...');
      print('   URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print('📡 Réponse de l\'API:');
      print('   Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);
        final services = jsonData
            .map((json) => Service.fromJson(json))
            .toList();

        print('✅ Services chargés: ${services.length} items');
        for (var service in services) {
          print(
            '   - ${service.designation} (${service.service}): ${service.prix} FCFA',
          );
        }

        return services;
      } else {
        print('❌ Erreur HTTP ${response.statusCode}: ${response.body}');
        return [];
      }
    } catch (e) {
      print('❌ Erreur lors du chargement des services: $e');
      return [];
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  Future<void> _effectuerInscription(
    List<Echeance> echeances,
    StateSetter setState,
    VoidCallback setLoading,
    VoidCallback setLoadingFalse,
  ) async {
    // Filtrer les échéances sélectionnées
    final echeancesSelectionnees = echeances
        .where((e) => e.selectionnee)
        .toList();

    if (echeancesSelectionnees.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner au moins une échéance'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Créer la requête d'inscription
      final inscriptionRequest = InscriptionRequest(
        ids: [
          InscriptionItem(
            id: "SCO",
            service: "Scolarité",
            montant: echeancesSelectionnees.fold(
              0,
              (sum, e) => sum + e.montant,
            ),
            reservation: false,
            echeancesSelectionnees: echeancesSelectionnees,
          ),
        ],
        engagement: {},
        type: "préinscription",
        separationFlux: 0,
        systemeEducatif: 1,
      );

      // URL de l'API
      final String matricule =
          _matricule ?? "10307"; // Valeur par défaut si null
      final String ecoleCode =
          _ecoleCode ?? "gainhs"; // Valeur par défaut si null
      final String url =
          "${AppConfig.VIE_ECOLES_API_BASE_URL}/vie-ecoles/inscription-eleve/$matricule?ecole=$ecoleCode";

      print('🔄 Envoi de la requête d\'inscription...');
      print('   URL: $url');
      print('   Matricule: $matricule');
      print('   École: $ecoleCode');
      print('   Données: ${jsonEncode(inscriptionRequest.toJson())}');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(inscriptionRequest.toJson()),
      );

      print('📡 Réponse de l\'API:');
      print('   Status Code: ${response.statusCode}');
      print('   Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Inscription de ${widget.child.firstName} enregistrée avec succès!',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } else {
        // Gérer les erreurs de l'API
        String errorMessage = 'Erreur lors de l\'inscription';
        try {
          final errorData = jsonDecode(response.body);
          errorMessage =
              errorData['message'] ?? errorData['error'] ?? errorMessage;
        } catch (e) {
          errorMessage = 'Erreur HTTP ${response.statusCode}: ${response.body}';
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Erreur lors de l\'inscription: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur réseau: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      setLoadingFalse();
    }
  }

  Widget _buildModernInscriptionButton({
    required String label,
    required VoidCallback? onTap,
    required bool isLoading,
  }) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: onTap != null
              ? [const Color(0xFF3B82F6), const Color(0xFF60A5FA)]
              : [Colors.grey.shade400, Colors.grey.shade300],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: onTap != null
            ? [
                BoxShadow(
                  color: const Color(0xFF3B82F6).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.3,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Future<void> _effectuerPaiement(
    String montantStr,
    StateSetter setState,
    VoidCallback setLoading,
    VoidCallback setLoadingFalse,
  ) async {
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
      print(
        '💳 Initialisation du paiement: $montant FCFA pour matricule $_matricule',
      );

      final paiementResponse = await _paiementService.initierPaiementEnLigne(
        _matricule!,
        montant,
      );

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
        final launched = await _paiementService.lancerUrlPaiement(
          paiementResponse.url,
        );
        if (!launched) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Impossible d\'ouvrir la page de paiement. Veuillez réessayer.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        // Afficher le message d'erreur de l'API
        throw Exception(paiementResponse.message);
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
            colors: [const Color(0xFFFF7A3C), AppColors.screenOrange],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.screenOrange.withOpacity(0.35),
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
                  child: CustomLoader(
                    message: '',
                    loaderColor: Colors.white,
                    size: 22,
                    showBackground: false,
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
                  color: AppColors.screenOrangeLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.analytics_outlined,
                  color: AppColors.screenOrange,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Statistiques',
                style: TextStyle(
                  fontSize: _textSizeService.getScaledFontSize(18),
                  fontWeight: FontWeight.w800,
                  color: AppColors.screenTextPrimary,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 120,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildModernSummaryCard(
                  'Moyenne',
                  _globalAverage != null
                      ? '${_globalAverage!.trimesterAverage.toStringAsFixed(2)}'
                      : '--',
                  Colors.green,
                  Icons.trending_up,
                  isLoading: _isLoadingNotes,
                ),
                const SizedBox(width: 12),
                _buildModernSummaryCard(
                  'Rang',
                  _globalAverage != null && _globalAverage!.trimesterRank > 0
                      ? '${_globalAverage!.trimesterRank}${_getOrdinalSuffix(_globalAverage!.trimesterRank)}'
                      : '--',
                  Colors.blue,
                  Icons.emoji_events,
                  isLoading: _isLoadingNotes,
                ),
                const SizedBox(width: 12),
                _buildModernSummaryCard(
                  'Présence',
                  '95%',
                  AppColors.success,
                  Icons.check_circle,
                ),
                const SizedBox(width: 12),
                _buildModernSummaryCard(
                  'Appréciation',
                  _globalAverage != null
                      ? _globalAverage!.trimesterMention
                      : '--',
                  AppColors.secondary,
                  Icons.star,
                  isLoading: _isLoadingNotes,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModernSummaryCard(
    String title,
    String value,
    Color color,
    IconData icon, {
    bool isLoading = false,
  }) {
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
      child: SizedBox(
        width: 140,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey[800] : AppColors.screenCard,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: color.withOpacity(0.1), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 18),
                  ),
                  const Spacer(),
                  if (isLoading)
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CustomLoader(
                        message: '',
                        loaderColor: color,
                        size: 14,
                        showBackground: false,
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
              const SizedBox(height: 8),
              if (isLoading)
                Container(
                  height: 18,
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? Colors.grey[700]
                        : AppColors.screenDivider,
                    borderRadius: BorderRadius.circular(4),
                  ),
                )
              else
                Text(
                  value,
                  style: TextStyle(
                    fontSize: _textSizeService.getScaledFontSize(16),
                    fontWeight: FontWeight.w800,
                    color: color,
                    letterSpacing: -0.8,
                  ),
                ),
              const SizedBox(height: 2),
              Text(
                title,
                style: TextStyle(
                  fontSize: _textSizeService.getScaledFontSize(11),
                  color: isDarkMode
                      ? Colors.grey[400]
                      : AppColors.screenTextSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSimpleTimetableTab() {
    final isDarkMode = _themeService.isDarkMode;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(0),
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
          child: CustomLoader(
            message: 'Chargement de l\'emploi du temps...',
            loaderColor: AppColors.screenOrange,
            showBackground: false,
          ),
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
            color: _themeService.isDarkMode
                ? const Color(0xFF1E1E1E)
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red.withOpacity(0.3)),
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
                  color: _themeService.isDarkMode
                      ? Colors.grey[400]
                      : Colors.grey[600],
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
          color: _themeService.isDarkMode
              ? const Color(0xFF1E1E1E)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _themeService.isDarkMode
                ? Colors.grey[700]!
                : Colors.grey[200]!,
          ),
        ),
        child: Column(
          children: [
            Icon(Icons.schedule_outlined, size: 48, color: Colors.orange[400]),
            const SizedBox(height: 12),
            Text(
              'Aucun emploi du temps disponible',
              style: TextStyle(
                fontSize: 16,
                color: _themeService.isDarkMode
                    ? Colors.white70
                    : Colors.grey[600],
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
          child: CustomLoader(
            message: 'Chargement du contrôle d\'accès...',
            loaderColor: AppColors.screenOrange,
            showBackground: false,
          ),
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
            color: _themeService.isDarkMode
                ? const Color(0xFF1E1E1E)
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red.withOpacity(0.3)),
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
                  color: _themeService.isDarkMode
                      ? Colors.grey[400]
                      : Colors.grey[600],
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
          color: _themeService.isDarkMode
              ? const Color(0xFF1E1E1E)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _themeService.isDarkMode
                ? Colors.grey[700]!
                : Colors.grey[200]!,
          ),
        ),
        child: Column(
          children: [
            Icon(Icons.fingerprint, size: 48, color: Colors.purple[400]),
            const SizedBox(height: 12),
            Text(
              'Aucun pointage disponible',
              style: TextStyle(
                fontSize: 16,
                color: _themeService.isDarkMode
                    ? Colors.white70
                    : Colors.grey[600],
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
            color: _themeService.isDarkMode
                ? const Color(0xFF1E1E1E)
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _themeService.isDarkMode
                  ? Colors.grey[700]!
                  : Colors.grey[200]!,
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
                      color: _themeService.isDarkMode
                          ? Colors.white
                          : Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      'Total',
                      totalEntries.toString(),
                      Colors.purple,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatItem(
                      'Entrées',
                      entrees.toString(),
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatItem(
                      'Sorties',
                      sorties.toString(),
                      Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      'OK',
                      statusOk.toString(),
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatItem(
                      'KO',
                      (totalEntries - statusOk).toString(),
                      Colors.red,
                    ),
                  ),
                  const Expanded(child: SizedBox()),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Liste des pointages récents (limités à 5 pour le bottom sheet)
        ..._accessEntries
            .take(5)
            .map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildAccessControlCard(entry),
              ),
            )
            .toList(),
        if (_accessEntries.length > 5)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '... et ${_accessEntries.length - 5} autres pointages',
              style: TextStyle(
                color: _themeService.isDarkMode
                    ? Colors.grey[400]
                    : Colors.grey[600],
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
      padding: const EdgeInsets.all(0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // _buildInfoCard(
          //   '💰 Scolarité & Paiements',
          //   'Consultez les échéances de scolarité et l\'état des paiements.',
          //   Colors.amber,
          // ),
          // const SizedBox(height: 20),
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
          child: CustomLoader(
            message: 'Chargement de la scolarité...',
            loaderColor: AppColors.screenOrange,
            showBackground: false,
          ),
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
            color: _themeService.isDarkMode
                ? const Color(0xFF1E1E1E)
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red.withOpacity(0.3)),
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
                  color: _themeService.isDarkMode
                      ? Colors.grey[400]
                      : Colors.grey[600],
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
          color: _themeService.isDarkMode
              ? const Color(0xFF1E1E1E)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _themeService.isDarkMode
                ? Colors.grey[700]!
                : Colors.grey[200]!,
          ),
        ),
        child: Column(
          children: [
            Icon(Icons.school, size: 48, color: Colors.amber[400]),
            const SizedBox(height: 12),
            Text(
              'Aucune échéance disponible',
              style: TextStyle(
                fontSize: 16,
                color: _themeService.isDarkMode
                    ? Colors.white70
                    : Colors.grey[600],
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
    final totalMontant = _scolariteEntries.fold<int>(
      0,
      (sum, entry) => sum + entry.montant,
    );
    final totalPaye = _scolariteEntries.fold<int>(
      0,
      (sum, entry) => sum + entry.paye,
    );
    final totalRapayer = _scolariteEntries.fold<int>(
      0,
      (sum, entry) => sum + entry.rapayer,
    );
    final paymentPercentage = totalMontant > 0
        ? (totalPaye / totalMontant) * 100
        : 0.0;
    final overdueCount = _scolariteEntries.where((e) => e.isOverdue).length;

    return Column(
      children: [
        // Carte de statistiques
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _themeService.isDarkMode
                ? const Color(0xFF1E1E1E)
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _themeService.isDarkMode
                  ? Colors.grey[700]!
                  : Colors.grey[200]!,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.analytics_outlined, color: Colors.amber, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    'Résumé de la scolarité',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: _themeService.isDarkMode
                          ? Colors.white
                          : Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      'Total',
                      _formatAmount(totalMontant),
                      Colors.amber,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatItem(
                      'Payé',
                      _formatAmount(totalPaye),
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatItem(
                      'Restant',
                      _formatAmount(totalRapayer),
                      Colors.red,
                    ),
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
                          color: _themeService.isDarkMode
                              ? Colors.white
                              : Colors.black,
                          fontSize: _textSizeService.getScaledFontSize(12),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (overdueCount > 0) ...[
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
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
                      color:
                          (_themeService.isDarkMode
                                  ? Colors.grey[600]
                                  : Colors.grey[300])!
                              .withOpacity(0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: paymentPercentage / 100,
                      child: Container(
                        decoration: BoxDecoration(
                          color: paymentPercentage == 100
                              ? Colors.green
                              : Colors.amber,
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
        // Liste de toutes les échéances
        ..._scolariteEntries
            .map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildScolariteCard(entry),
              ),
            )
            .toList(),
      ],
    );
  }

  Widget _buildScolariteCard(StudentScolariteEntry entry) {
    final isDarkMode = _themeService.isDarkMode;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _themeService.isDarkMode
            ? const Color(0xFF1E1E1E)
            : Colors.white,
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
                          color: _themeService.isDarkMode
                              ? Colors.white
                              : Colors.black,
                          fontSize: _textSizeService.getScaledFontSize(16),
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
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
                      color: _themeService.isDarkMode
                          ? Colors.grey[400]
                          : Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Montant: ${entry.formattedMontant}',
                      style: TextStyle(
                        color: _themeService.isDarkMode
                            ? Colors.white
                            : Colors.black,
                        fontSize: _textSizeService.getScaledFontSize(14),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Montant payé et montant restant
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check_circle, size: 16, color: Colors.green),
                        const SizedBox(width: 4),
                        Text(
                          'Payé: ${entry.formattedPaye}',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: _textSizeService.getScaledFontSize(14),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    // N'afficher le montant restant que s'il est supérieur à 0
                    if (entry.rapayer > 0) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            entry.rapayer > 0
                                ? Icons.warning
                                : Icons.check_circle,
                            size: 16,
                            color: entry.rapayer > 0
                                ? Colors.red
                                : Colors.green,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Restant: ${entry.formattedRapayer}',
                            style: TextStyle(
                              color: entry.rapayer > 0
                                  ? Colors.red
                                  : Colors.green,
                              fontSize: _textSizeService.getScaledFontSize(14),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                // Date limite
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: _themeService.isDarkMode
                          ? Colors.grey[400]
                          : Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Date limite: ${entry.formattedDateLimite}',
                      style: TextStyle(
                        color: _themeService.isDarkMode
                            ? Colors.grey[400]
                            : Colors.grey[600],
                        fontSize: _textSizeService.getScaledFontSize(14),
                      ),
                    ),
                    if (entry.isOverdue) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
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
        backgroundColor: _themeService.isDarkMode
            ? const Color(0xFF1E1E1E)
            : Colors.white,
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
              _buildDetailRow(
                'Date d\'enregistrement',
                entry.formattedDateenreg,
              ),
              if (entry.isOverdue)
                _buildDetailRow(
                  'Retard',
                  'Oui - ${entry.daysUntilDeadline.abs()} jours',
                  Colors.red,
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Fermer', style: TextStyle(color: AppColors.primary)),
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
              color: _themeService.isDarkMode
                  ? Colors.grey[400]
                  : Colors.grey[600],
              fontSize: _textSizeService.getScaledFontSize(12),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color:
                  color ??
                  (_themeService.isDarkMode ? Colors.white : Colors.black),
              fontSize: _textSizeService.getScaledFontSize(14),
            ),
          ),
        ],
      ),
    );
  }

  String _formatAmount(int amount) {
    return '${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')} FCFA';
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
          child: CustomLoader(
            message: 'Chargement des suggestions...',
            loaderColor: AppColors.screenOrange,
            showBackground: false,
          ),
        ),
      );
    }

    if (_suggestions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _themeService.isDarkMode
              ? const Color(0xFF1E1E1E)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _themeService.isDarkMode
                ? Colors.grey[700]!
                : Colors.grey[200]!,
          ),
        ),
        child: Column(
          children: [
            Icon(Icons.lightbulb_outline, size: 48, color: Colors.purple[400]),
            const SizedBox(height: 12),
            Text(
              'Aucune suggestion disponible',
              style: TextStyle(
                fontSize: 16,
                color: _themeService.isDarkMode
                    ? Colors.white70
                    : Colors.grey[600],
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
            color: _themeService.isDarkMode
                ? const Color(0xFF1E1E1E)
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _themeService.isDarkMode
                  ? Colors.grey[700]!
                  : Colors.grey[200]!,
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
                      color: _themeService.isDarkMode
                          ? Colors.white
                          : Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      'Total',
                      _suggestions.length.toString(),
                      Colors.purple,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatItem(
                      'En attente',
                      _suggestions
                          .where((s) => s.status == SuggestionStatus.pending)
                          .length
                          .toString(),
                      Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatItem(
                      'Approuvées',
                      _suggestions
                          .where((s) => s.status == SuggestionStatus.approved)
                          .length
                          .toString(),
                      Colors.green,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Liste des suggestions récentes (limitées à 5 pour le bottom sheet)
        ..._suggestions
            .take(5)
            .map(
              (suggestion) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildSuggestionCard(suggestion),
              ),
            )
            .toList(),
        if (_suggestions.length > 5)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '... et ${_suggestions.length - 5} autres suggestions',
              style: TextStyle(
                color: _themeService.isDarkMode
                    ? Colors.grey[400]
                    : Colors.grey[600],
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
        color: _themeService.isDarkMode
            ? const Color(0xFF1E1E1E)
            : Colors.white,
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
                          color: _themeService.isDarkMode
                              ? Colors.white
                              : Colors.black,
                          fontSize: _textSizeService.getScaledFontSize(16),
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(
                          suggestion.status,
                        ).withOpacity(0.1),
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
                    color: _themeService.isDarkMode
                        ? Colors.grey[400]
                        : Colors.grey[600],
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
                      color: _themeService.isDarkMode
                          ? Colors.grey[400]
                          : Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      suggestion.displayName,
                      style: TextStyle(
                        color: _themeService.isDarkMode
                            ? Colors.grey[400]
                            : Colors.grey[600],
                        fontSize: _textSizeService.getScaledFontSize(12),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: _themeService.isDarkMode
                          ? Colors.grey[400]
                          : Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      suggestion.formattedCreatedAt,
                      style: TextStyle(
                        color: _themeService.isDarkMode
                            ? Colors.grey[400]
                            : Colors.grey[600],
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getCategoryColor(
                          suggestion.category,
                        ).withOpacity(0.1),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getPriorityColor(
                          suggestion.priority,
                        ).withOpacity(0.1),
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
        backgroundColor: _themeService.isDarkMode
            ? const Color(0xFF1E1E1E)
            : Colors.white,
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
              _buildDetailRow(
                'Catégorie',
                suggestion.category.displayName,
                _getCategoryColor(suggestion.category),
              ),
              _buildDetailRow(
                'Priorité',
                suggestion.priority.displayName,
                _getPriorityColor(suggestion.priority),
              ),
              _buildDetailRow(
                'Statut',
                suggestion.status.displayName,
                _getStatusColor(suggestion.status),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Fermer', style: TextStyle(color: AppColors.primary)),
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
          child: CustomLoader(
            message: 'Chargement des logs d\'accès...',
            loaderColor: AppColors.screenOrange,
            showBackground: false,
          ),
        ),
      );
    }

    if (_accessLogs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _themeService.isDarkMode
              ? const Color(0xFF1E1E1E)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _themeService.isDarkMode
                ? Colors.grey[700]!
                : Colors.grey[200]!,
          ),
        ),
        child: Column(
          children: [
            Icon(Icons.history, size: 48, color: Colors.teal[400]),
            const SizedBox(height: 12),
            Text(
              'Aucun log d\'accès disponible',
              style: TextStyle(
                fontSize: 16,
                color: _themeService.isDarkMode
                    ? Colors.white70
                    : Colors.grey[600],
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
            color: _themeService.isDarkMode
                ? const Color(0xFF1E1E1E)
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _themeService.isDarkMode
                  ? Colors.grey[700]!
                  : Colors.grey[200]!,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.analytics_outlined, color: Colors.teal, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    'Statistiques des accès',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: _themeService.isDarkMode
                          ? Colors.white
                          : Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      'Total',
                      _accessLogs.length.toString(),
                      Colors.teal,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatItem(
                      'Entrées',
                      _accessLogs
                          .where((l) => l.accessType == AccessType.entry)
                          .length
                          .toString(),
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatItem(
                      'Sorties',
                      _accessLogs
                          .where((l) => l.accessType == AccessType.exit)
                          .length
                          .toString(),
                      Colors.orange,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Liste des logs récents (limités à 5 pour le bottom sheet)
        ..._accessLogs
            .take(5)
            .map(
              (log) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildAccessLogCard(log),
              ),
            )
            .toList(),
        if (_accessLogs.length > 5)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '... et ${_accessLogs.length - 5} autres logs',
              style: TextStyle(
                color: _themeService.isDarkMode
                    ? Colors.grey[400]
                    : Colors.grey[600],
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
        color: _themeService.isDarkMode
            ? const Color(0xFF1E1E1E)
            : Colors.white,
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
                      log.accessType == AccessType.entry
                          ? Icons.login
                          : Icons.logout,
                      color: log.accessType == AccessType.entry
                          ? Colors.green
                          : Colors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      log.accessType == AccessType.entry ? 'Entrée' : 'Sortie',
                      style: TextStyle(
                        color: log.accessType == AccessType.entry
                            ? Colors.green
                            : Colors.orange,
                        fontSize: _textSizeService.getScaledFontSize(16),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color:
                            (log.accessType == AccessType.entry
                                    ? Colors.green
                                    : Colors.orange)
                                .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        log.formattedTime,
                        style: TextStyle(
                          color: log.accessType == AccessType.entry
                              ? Colors.green
                              : Colors.orange,
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
                      color: _themeService.isDarkMode
                          ? Colors.grey[400]
                          : Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      log.formattedDate,
                      style: TextStyle(
                        color: _themeService.isDarkMode
                            ? Colors.grey[400]
                            : Colors.grey[600],
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
                        color: _themeService.isDarkMode
                            ? Colors.grey[400]
                            : Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        log.location!,
                        style: TextStyle(
                          color: _themeService.isDarkMode
                              ? Colors.grey[400]
                              : Colors.grey[600],
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
        backgroundColor: _themeService.isDarkMode
            ? const Color(0xFF1E1E1E)
            : Colors.white,
        title: Text(
          log.accessType == AccessType.entry
              ? 'Détails de l\'entrée'
              : 'Détails de la sortie',
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
              _buildDetailRow(
                'Type',
                log.accessType == AccessType.entry ? 'Entrée' : 'Sortie',
              ),
              _buildDetailRow('Date', log.formattedDate),
              _buildDetailRow('Heure', log.formattedTime),
              if (log.location?.isNotEmpty == true)
                _buildDetailRow('Lieu', log.location!),
              _buildDetailRow('Enfant', widget.child.fullName),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Fermer', style: TextStyle(color: AppColors.primary)),
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
          child: CustomLoader(
            message: 'Chargement des réservations...',
            loaderColor: AppColors.screenOrange,
            showBackground: false,
          ),
        ),
      );
    }

    if (_reservations.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _themeService.isDarkMode
              ? const Color(0xFF1E1E1E)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _themeService.isDarkMode
                ? Colors.grey[700]!
                : Colors.grey[200]!,
          ),
        ),
        child: Column(
          children: [
            Icon(Icons.event_seat, size: 48, color: Colors.indigo[400]),
            const SizedBox(height: 12),
            Text(
              'Aucune réservation disponible',
              style: TextStyle(
                fontSize: 16,
                color: _themeService.isDarkMode
                    ? Colors.white70
                    : Colors.grey[600],
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
            color: _themeService.isDarkMode
                ? const Color(0xFF1E1E1E)
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _themeService.isDarkMode
                  ? Colors.grey[700]!
                  : Colors.grey[200]!,
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
                      color: _themeService.isDarkMode
                          ? Colors.white
                          : Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      'Total',
                      _reservations.length.toString(),
                      Colors.indigo,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatItem(
                      'Confirmées',
                      _reservations
                          .where((r) => r.status == ReservationStatus.confirmed)
                          .length
                          .toString(),
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatItem(
                      'En attente',
                      _reservations
                          .where((r) => r.status == ReservationStatus.pending)
                          .length
                          .toString(),
                      Colors.orange,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Liste des réservations récentes (limitées à 5 pour le bottom sheet)
        ..._reservations
            .take(5)
            .map(
              (reservation) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildReservationCard(reservation),
              ),
            )
            .toList(),
        if (_reservations.length > 5)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '... et ${_reservations.length - 5} autres réservations',
              style: TextStyle(
                color: _themeService.isDarkMode
                    ? Colors.grey[400]
                    : Colors.grey[600],
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
        color: _themeService.isDarkMode
            ? const Color(0xFF1E1E1E)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getReservationStatusColor(
            reservation.status,
          ).withOpacity(0.3),
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
                          color: _themeService.isDarkMode
                              ? Colors.white
                              : Colors.black,
                          fontSize: _textSizeService.getScaledFontSize(16),
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getReservationStatusColor(
                          reservation.status,
                        ).withOpacity(0.1),
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
                      color: _themeService.isDarkMode
                          ? Colors.grey[400]
                          : Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      reservation.formattedCreatedAt,
                      style: TextStyle(
                        color: _themeService.isDarkMode
                            ? Colors.grey[400]
                            : Colors.grey[600],
                        fontSize: _textSizeService.getScaledFontSize(14),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: _themeService.isDarkMode
                          ? Colors.grey[400]
                          : Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${reservation.createdAt.hour.toString().padLeft(2, '0')}:${reservation.createdAt.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        color: _themeService.isDarkMode
                            ? Colors.grey[400]
                            : Colors.grey[600],
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
                      color: _themeService.isDarkMode
                          ? Colors.grey[400]
                          : Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      reservation.type.displayName,
                      style: TextStyle(
                        color: _themeService.isDarkMode
                            ? Colors.grey[400]
                            : Colors.grey[600],
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
        backgroundColor: _themeService.isDarkMode
            ? const Color(0xFF1E1E1E)
            : Colors.white,
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
              _buildDetailRow(
                'Heure',
                '${reservation.createdAt.hour.toString().padLeft(2, '0')}:${reservation.createdAt.minute.toString().padLeft(2, '0')}',
              ),
              _buildDetailRow(
                'Statut',
                reservation.status.displayName,
                _getReservationStatusColor(reservation.status),
              ),
              _buildDetailRow('Enfant', widget.child.fullName),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Fermer', style: TextStyle(color: AppColors.primary)),
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
      default:
        return Colors.grey;
    }
  }

  Widget _buildIntegrationRequestsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildInfoCard(
            '🎓 Demandes d\'intégration',
            'Consultez le statut de vos demandes d\'intégration scolaire.',
            Colors.blue,
          ),
          const SizedBox(height: 20),
          _buildIntegrationRequestsContent(),
        ],
      ),
    );
  }

  Widget _buildIntegrationRequestsContent() {
    return StatefulBuilder(
      builder: (context, setLocalState) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.screenCard,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: AppColors.screenShadow,
                blurRadius: 16,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3F2FD),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.school_rounded,
                        color: Color(0xFF1565C0),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Consultation demande',
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
              Center(
                child: Container(
                  width: 36,
                  height: 3,
                  margin: const EdgeInsets.only(top: 14, bottom: 4),
                  decoration: BoxDecoration(
                    color: AppColors.screenDivider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Column(
                  children: [
                    _buildEcoleFieldLocal(setLocalState), // ← version locale
                    const SizedBox(height: 14),
                    _buildMatriculeDisplay(),
                    const SizedBox(height: 12),
                    _buildInfoBanner(),
                    const SizedBox(height: 20),
                    _buildOrangeButton(
                      label: _isLoadingIntegrationRequest
                          ? 'Consultation en cours...'
                          : 'Consulter la demande',
                      onTap:
                          _selectedEcoleId != null &&
                              !_isLoadingIntegrationRequest
                          ? _consultIntegrationRequest
                          : null,
                      isLoading: _isLoadingIntegrationRequest,
                      icon: Icons.search_rounded,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEcoleFieldLocal(StateSetter setLocalState) {
    if (_isLoadingEcoles) {
      return _buildLoadingField('Chargement des écoles...');
    }
    if (_ecoles.isEmpty) {
      return _buildEmptyEcoleField();
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
              // met à jour le widget principal
              _selectedEcoleId = ecole.ecoleid;
              _selectedEcoleName = selected;
            });
            setLocalState(
              () {},
            ); // force le rebuild du bouton dans le StatefulBuilder
          },
          isDarkMode: _themeService.isDarkMode,
        ),
      ],
    );
  }

  Widget _buildEcoleField() {
    if (_isLoadingEcoles) {
      return _buildLoadingField('Chargement des écoles...');
    }
    if (_ecoles.isEmpty) {
      return Column(children: [_buildEmptyEcoleField()]);
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
            });
          },
          isDarkMode: _themeService.isDarkMode,
        ),
      ],
    );
  }

  Widget _buildMatriculeDisplay() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel('Matricule de l\'élève'),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: AppColors.screenSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.screenDivider),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                const Icon(
                  Icons.badge_outlined,
                  color: AppColors.screenOrange,
                  size: 18,
                ),
                const SizedBox(width: 12),
                Text(
                  widget.child.matricule ?? 'Non disponible',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.screenTextPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1565C0).withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Color(0xFF1565C0), size: 16),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Sélectionnez une école pour consulter le statut de la demande d\'intégration',
              style: TextStyle(
                color: Color(0xFF1565C0),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
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
          TextButton(
            onPressed: _loadEcoles,
            child: const Text(
              'Réessayer',
              style: TextStyle(color: AppColors.screenOrange),
            ),
          ),
        ],
      ),
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

  Widget _buildOrangeButton({
    required String label,
    required VoidCallback? onTap,
    required bool isLoading,
    IconData? icon,
    Color color = AppColors.screenOrange,
    Color shadowColor = AppColors.screenOrange,
  }) {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, shadowColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: shadowColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: isLoading
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Chargement...',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Future<void> _loadEcoles() async {
    setState(() {
      _isLoadingEcoles = true;
    });
    try {
      final ecoles = await _poulsApiService.getAllEcoles();
      setState(() {
        _ecoles = ecoles;
        _isLoadingEcoles = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingEcoles = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de chargement: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _consultIntegrationRequest() async {
    if (_selectedEcoleId == null || widget.child.matricule == null) return;

    setState(() {
      _isLoadingIntegrationRequest = true;
    });

    try {
      final ecole = _ecoles.firstWhere((e) => e.ecoleid == _selectedEcoleId);
      final ecoleCode = ecole.paramecole?.isNotEmpty == true
          ? ecole.paramecole!
          : ecole.ecolecode;
      final matricule = widget.child.matricule!;

      // Affichage de la requête API dans la console
      print('🔍 REQUÊTE API DEMANDE D\'INTÉGRATION');
      print(
        '📋 École sélectionnée: ${ecole.ecoleclibelle} (ID: ${ecole.ecoleid})',
      );
      print('📝 Code école pour API: $ecoleCode');
      print('🎫 Matricule de l\'élève: $matricule');

      final url =
          '${AppConfig.VIE_ECOLES_API_BASE_URL}/preinscription/demande-integration/consulte?ecole=$ecoleCode&matricule=$matricule';
      print('🌐 URL complète: $url');

      final response = await http.get(Uri.parse(url));

      print('📊 Réponse HTTP - Status: ${response.statusCode}');
      print('📄 Corps de la réponse: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Données parsées: $data');
        _showIntegrationResultDialog(data);
      } else {
        print('❌ Erreur HTTP ${response.statusCode}: ${response.body}');
        throw Exception('Erreur ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('💥 Exception lors de la consultation: ${e.toString()}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la consultation: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoadingIntegrationRequest = false;
      });
    }
  }

  void _showIntegrationResultDialog(Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.transparent,
        contentPadding: EdgeInsets.zero,
        content: Container(
          decoration: BoxDecoration(
            color: AppColors.screenCard,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: AppColors.screenShadow,
                blurRadius: 16,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3F2FD),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.search_rounded,
                        color: Color(0xFF1565C0),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Résultat de la demande',
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
              Center(
                child: Container(
                  width: 36,
                  height: 3,
                  margin: const EdgeInsets.only(top: 14, bottom: 4),
                  decoration: BoxDecoration(
                    color: AppColors.screenDivider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildResultItem(
                      'Statut',
                      data['statut']?.toString() ?? 'Non spécifié',
                    ),
                    const SizedBox(height: 12),
                    _buildResultItem(
                      'Message',
                      data['message']?.toString() ?? 'Aucun message',
                    ),
                    if (data['date'] != null) ...[
                      const SizedBox(height: 12),
                      _buildResultItem('Date', data['date'].toString()),
                    ],
                    const SizedBox(height: 20),
                    _buildOrangeButton(
                      label: 'Fermer',
                      onTap: () => Navigator.pop(context),
                      isLoading: false,
                      icon: Icons.close_rounded,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: _textSizeService.getScaledFontSize(12),
            fontWeight: FontWeight.w500,
            color: AppColors.screenTextSecondary,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: _textSizeService.getScaledFontSize(14),
            fontWeight: FontWeight.w600,
            color: AppColors.screenTextPrimary,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
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
          child: CustomLoader(
            message: 'Chargement des messages...',
            loaderColor: AppColors.screenOrange,
            showBackground: false,
          ),
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
            color: _themeService.isDarkMode
                ? const Color(0xFF1E1E1E)
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red.withOpacity(0.3)),
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
                  color: _themeService.isDarkMode
                      ? Colors.grey[400]
                      : Colors.grey[600],
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
          color: _themeService.isDarkMode
              ? const Color(0xFF1E1E1E)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _themeService.isDarkMode
                ? Colors.grey[700]!
                : Colors.grey[200]!,
          ),
        ),
        child: Column(
          children: [
            Icon(Icons.mail_outline, size: 48, color: Colors.blue[400]),
            const SizedBox(height: 12),
            Text(
              'Aucun message disponible',
              style: TextStyle(
                fontSize: 16,
                color: _themeService.isDarkMode
                    ? Colors.white70
                    : Colors.grey[600],
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
            color: _themeService.isDarkMode
                ? const Color(0xFF1E1E1E)
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _themeService.isDarkMode
                  ? Colors.grey[700]!
                  : Colors.grey[200]!,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.analytics_outlined, color: Colors.blue, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    'Statistiques des messages',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: _themeService.isDarkMode
                          ? Colors.white
                          : Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      'Total',
                      totalMessages.toString(),
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatItem(
                      'Non lus',
                      unreadMessages.toString(),
                      Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatItem(
                      'Lus',
                      readMessages.toString(),
                      Colors.green,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Liste des messages récents (limités à 5 pour le bottom sheet)
        ..._studentMessages
            .take(5)
            .map(
              (message) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildMessageCard(message),
              ),
            )
            .toList(),
        if (_studentMessages.length > 5)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '... et ${_studentMessages.length - 5} autres messages',
              style: TextStyle(
                color: _themeService.isDarkMode
                    ? Colors.grey[400]
                    : Colors.grey[600],
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
        color: _themeService.isDarkMode
            ? const Color(0xFF1E1E1E)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: message.isUnread
              ? AppColors.primary.withOpacity(0.3)
              : _themeService.isDarkMode
              ? Colors.grey[700]!
              : Colors.grey[200]!,
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
                          color: _themeService.isDarkMode
                              ? Colors.white
                              : Colors.black,
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
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
                    color: _themeService.isDarkMode
                        ? Colors.grey[400]
                        : Colors.grey[600],
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
                      color: _themeService.isDarkMode
                          ? Colors.grey[400]
                          : Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      message.formattedDate,
                      style: TextStyle(
                        color: _themeService.isDarkMode
                            ? Colors.grey[400]
                            : Colors.grey[600],
                        fontSize: _textSizeService.getScaledFontSize(12),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
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
        backgroundColor: _themeService.isDarkMode
            ? const Color(0xFF1E1E1E)
            : Colors.white,
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
                    color: _themeService.isDarkMode
                        ? Colors.grey[400]
                        : Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Envoyé le: ${message.formattedDate}',
                    style: TextStyle(
                      color: _themeService.isDarkMode
                          ? Colors.grey[400]
                          : Colors.grey[600],
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
                    color: _themeService.isDarkMode
                        ? Colors.grey[400]
                        : Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Statut: ${message.formattedStatut}',
                    style: TextStyle(
                      color: _themeService.isDarkMode
                          ? Colors.grey[400]
                          : Colors.grey[600],
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
            child: Text('Fermer', style: TextStyle(color: AppColors.primary)),
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
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
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
              Icon(Icons.calendar_today, size: 16, color: Colors.purple),
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
              Icon(Icons.access_time, size: 16, color: Colors.purple),
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

  Widget _buildDynamicDaySchedule(
    String day,
    List<StudentTimetableEntry> courses,
  ) {
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
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
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
    print(
      '🔄 Début du chargement de l\'emploi du temps pour: ${widget.child.fullName}',
    );
    print('📋 Matricule: $matricule');

    if (matricule == null || matricule.isEmpty) {
      print(
        '❌ Matricule non disponible pour l\'enfant: ${widget.child.fullName}',
      );
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

      final response = await _timetableService.getTimetableForStudent(
        matricule,
      );
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
    print(
      '🔄 Début du chargement du contrôle d\'accès pour: ${widget.child.fullName}',
    );
    print('📋 Matricule: $matricule');

    if (matricule == null || matricule.isEmpty) {
      print(
        '❌ Matricule non disponible pour l\'enfant: ${widget.child.fullName}',
      );
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

      final entries = await _accessControlService
          .getAccessControlEntriesForStudent(matricule);
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
      print(
        '❌ Matricule non disponible pour l\'enfant: ${widget.child.fullName}',
      );
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
      final messages = await _messageService.getMessagesForStudent(
        studentMatricule,
      );
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
    print(
      '🔄 Début du chargement de la scolarité pour: ${widget.child.fullName}',
    );
    print('📋 Matricule: $studentMatricule');

    if (studentMatricule == null || studentMatricule.isEmpty) {
      print(
        '❌ Matricule non disponible pour l\'enfant: ${widget.child.fullName}',
      );
      return;
    }

    print('✅ Matricule valide, début du chargement...');
    if (mounted) {
      setState(() {
        _isLoadingScolarite = true;
      });
    }

    try {
      // S'assurer que les données de l'école sont chargées
      if (!_schoolService.isSchoolDataLoaded) {
        print('🏫 Chargement des données de l\'école...');
        await _schoolService.loadSchoolData();
        print('✅ Données de l\'école chargées');
      }

      print('📡 Appel du service StudentScolariteService...');
      final entries = await _scolariteService.getScolariteEntriesForStudent(
        studentMatricule,
      );
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

    print(
      '🔄 Début du chargement des suggestions pour: ${widget.child.fullName}',
    );

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
    print(
      '🔄 Début du chargement des logs d\'accès pour: ${widget.child.fullName}',
    );
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

    final matricule = _matricule ?? widget.child.matricule;
    print(
      '🔄 Début du chargement des réservations pour: ${widget.child.fullName}',
    );
    print('📋 Matricule: $matricule');

    if (matricule == null || matricule.isEmpty) {
      print('❌ Matricule non disponible');
      return;
    }

    print('✅ Matricule valide, début du chargement...');
    if (mounted) {
      setState(() {
        _isLoadingReservations = true;
      });
    }

    try {
      print('📡 Appel du service fetchReservation...');
      final reservationStatus = await api_service
          .InscriptionApiService.fetchReservation(matricule: matricule);
      print(
        '✅ Réponse reçue: statut=${reservationStatus.status}, somme=${reservationStatus.sommeReservation}',
      );

      // Transformer la réponse en objets PlaceReservation pour compatibilité avec l'UI existante
      final reservations = <PlaceReservation>[];

      if (reservationStatus.status && reservationStatus.sommeReservation > 0) {
        // Créer une réservation fictive basée sur la réponse de l'API
        reservations.add(
          PlaceReservation(
            id: 'api_${DateTime.now().millisecondsSinceEpoch}',
            parentId: 'parent_${widget.child.id}',
            parentName: 'Parent de ${widget.child.fullName}',
            childId: widget.child.id ?? '',
            childName: widget.child.fullName,
            establishmentId: _ecoleCode ?? 'unknown',
            establishmentName:
                widget.child.establishment ?? 'Établissement inconnu',
            academicYear: '2024-2025', // Année académique par défaut
            grade: widget.child.grade ?? 'Classe inconnue',
            type: ReservationType.newAdmission,
            status: reservationStatus.status
                ? ReservationStatus.confirmed
                : ReservationStatus.pending,
            createdAt: DateTime.now(),
            reservationFee: reservationStatus.sommeReservation.toDouble(),
            depositAmount: reservationStatus.sommeReservation.toDouble(),
          ),
        );
      }

      if (mounted) {
        setState(() {
          _reservations = reservations;
          _isLoadingReservations = false;
        });
        print(
          '📊 Mise à jour de l\'UI terminée avec ${reservations.length} réservation(s)',
        );
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

  Future<void> _loadNotificationsData() async {
    if (_isLoadingNotifications) return;

    final matricule = _matricule ?? widget.child.matricule;
    if (matricule == null || matricule.isEmpty) {
      print('❌ Matricule non disponible');
      return;
    }

    if (mounted) {
      setState(() {
        _isLoadingNotifications = true;
      });
    }

    try {
      final notifications = await GroupMessageService.getGroupMessages(
        matricule,
      );
      if (mounted) {
        setState(() {
          _notifications = notifications;
          _isLoadingNotifications = false;
          _notificationsLoaded = true; // ✅ Marquer comme chargé
        });
      }
    } catch (e) {
      print('❌ Erreur lors du chargement des notifications: $e');
      if (mounted) {
        setState(() {
          _isLoadingNotifications = false;
          _notificationsLoaded =
              true; // ✅ Même en cas d'erreur, ne pas reboucler
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
    if (s.contains('sport') || s.contains('eps'))
      return Icons.sports_soccer_rounded;
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
        border: Border.all(color: color.withOpacity(0.15), width: 1),
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
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 16),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.15), width: 1),
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
            child: Icon(icon, color: color, size: 24),
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
        border: Border.all(color: color.withOpacity(0.15), width: 1),
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
        border: Border.all(color: color.withOpacity(0.15), width: 1),
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
            child: Icon(icon, color: color, size: 24),
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
                    Icon(Icons.calendar_today_rounded, size: 14, color: color),
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
                    Icon(Icons.access_time_rounded, size: 14, color: color),
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
              // TODO: Implémenter LibraryScreen quand disponible
              // Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LibraryScreen()));
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
                            color: AppColors.getTextColor(
                              _themeService.isDarkMode,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Achetez des fournitures et articles scolaires pour ${widget.child.firstName}',
                          style: TextStyle(
                            fontSize: _textSizeService.getScaledFontSize(14),
                            color: AppColors.getTextColor(
                              _themeService.isDarkMode,
                              type: TextType.secondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: AppColors.primary, size: 20),
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
          child: CustomLoader(
            message: 'Chargement des fournitures...',
            loaderColor: AppColors.screenOrange,
            showBackground: false,
          ),
        ),
      );
    }

    if (_schoolSupplies.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: _themeService.isDarkMode
              ? const Color(0xFF1E1E1E)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Aucune fourniture trouvée',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _themeService.isDarkMode
                    ? Colors.white70
                    : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Les fournitures scolaires seront affichées ici une fois disponibles.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: _themeService.isDarkMode
                    ? Colors.white54
                    : Colors.grey[500],
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
            entry.value
                .map((supply) => _buildSupplyItemFromApi(supply))
                .toList(),
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
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
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
              // TODO: Implémenter LibraryScreen quand disponible
              // Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LibraryScreen()));
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
    return FutureBuilder<List<Order>>(
      future: _loadOrdersFuture(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomLoader(
                    message: 'Chargement des commandes...',
                    backgroundColor: _themeService.isDarkMode 
                        ? Colors.grey[800] 
                        : Colors.white,
                    loaderColor: Colors.blue,
                    size: 40.0,
                  ),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Container(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: _themeService.isDarkMode 
                      ? Colors.red[400] 
                      : Colors.red[600],
                ),
                const SizedBox(height: 16),
                Text(
                  'Erreur de chargement',
                  style: TextStyle(
                    fontSize: _textSizeService.getScaledFontSize(16),
                    color: _themeService.isDarkMode 
                        ? Colors.red[400] 
                        : Colors.red[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Veuillez réessayer plus tard',
                  style: TextStyle(
                    fontSize: _textSizeService.getScaledFontSize(14),
                    color: _themeService.isDarkMode 
                        ? Colors.grey[400] 
                        : Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }

        final orders = snapshot.data ?? [];

        if (orders.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Icon(
                  Icons.shopping_cart_outlined,
                  size: 64,
                  color: _themeService.isDarkMode 
                      ? Colors.grey[600] 
                      : Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Aucune commande trouvée',
                  style: TextStyle(
                    fontSize: _textSizeService.getScaledFontSize(16),
                    color: _themeService.isDarkMode 
                        ? Colors.grey[400] 
                        : Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Vos commandes apparaîtront ici',
                  style: TextStyle(
                    fontSize: _textSizeService.getScaledFontSize(14),
                    color: _themeService.isDarkMode 
                        ? Colors.grey[500] 
                        : Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // _buildInfoCard(
              //   '🛒 Commandes',
              //   'Suivi de vos commandes de fournitures scolaires et services.',
              //   Colors.purple,
              // ),
              const SizedBox(height: 20),
              Column(
                children: orders.map((order) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildOrderCardFromOrder(order),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<List<Order>> _loadOrdersFuture() async {
    final authService = AuthService();
    final currentUser = authService.getCurrentUser();
    
    if (currentUser?.phone == null) {
      print('⚠️ Impossible de charger les commandes: téléphone utilisateur manquant');
      return [];
    }

    try {
      print('📦 Chargement des commandes pour le téléphone: ${currentUser!.phone}');
      final orders = await OrderService().getUserOrders(currentUser!.phone);

      // Mettre à jour la variable locale pour d'autres utilisations
      if (mounted) {
        setState(() {
          _orders = orders;
        });
      }

      print('✅ Commandes chargées: ${orders.length} commandes');
      return orders;
    } catch (e) {
      print('❌ Erreur lors du chargement des commandes: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement des commandes: $e'),
          ),
        );
      }
      
      return [];
    }
  }

  Widget _buildOrdersList() {
    if (_isLoadingOrders) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_orders.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 64,
              color: _themeService.isDarkMode 
                  ? Colors.grey[600] 
                  : Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune commande trouvée',
              style: TextStyle(
                fontSize: _textSizeService.getScaledFontSize(16),
                color: _themeService.isDarkMode 
                    ? Colors.grey[400] 
                    : Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Vos commandes apparaîtront ici',
              style: TextStyle(
                fontSize: _textSizeService.getScaledFontSize(14),
                color: _themeService.isDarkMode 
                    ? Colors.grey[500] 
                    : Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: _orders.map((order) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildOrderCardFromOrder(order),
        );
      }).toList(),
    );
  }

  Widget _buildOrderCardFromOrder(Order order) {
    final isDarkMode = _themeService.isDarkMode;
    
    // Déterminer l'icône et la couleur selon le statut
    IconData statusIcon;
    Color statusColor;
    
    switch (order.status) {
      case OrderStatus.pending:
        statusIcon = Icons.pending_outlined;
        statusColor = Colors.orange;
        break;
      case OrderStatus.confirmed:
        statusIcon = Icons.check_circle_outline;
        statusColor = Colors.blue;
        break;
      case OrderStatus.processing:
        statusIcon = Icons.sync;
        statusColor = Colors.purple;
        break;
      case OrderStatus.shipped:
        statusIcon = Icons.local_shipping_outlined;
        statusColor = Colors.indigo;
        break;
      case OrderStatus.delivered:
        statusIcon = Icons.check_circle;
        statusColor = Colors.green;
        break;
      case OrderStatus.cancelled:
        statusIcon = Icons.cancel_outlined;
        statusColor = Colors.red;
        break;
      case OrderStatus.refunded:
        statusIcon = Icons.refresh;
        statusColor = Colors.grey;
        break;
      default:
        statusIcon = Icons.shopping_cart_outlined;
        statusColor = Colors.blue;
    }

    // Formatter la date sans utiliser DateFormat pour éviter l'erreur de localisation
    final months = [
      'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'
    ];
    final formattedDate = '${order.createdAt.day} ${months[order.createdAt.month - 1]} ${order.createdAt.year}';

    // Formatter le montant en FCFA
    final formattedAmount = '${order.totalAmount.toStringAsFixed(2)} FCFA';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.15), width: 1),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withOpacity(0.3)
                : statusColor.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header avec numéro de commande et statut
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Icon(statusIcon, color: statusColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Commande #${order.id}',
                      style: TextStyle(
                        fontSize: _textSizeService.getScaledFontSize(16),
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      order.items.isNotEmpty 
                          ? '${order.items.length} article(s)'
                          : 'Aucun article',
                      style: TextStyle(
                        fontSize: _textSizeService.getScaledFontSize(14),
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          // Séparateur
          const SizedBox(height: 12),
          
          // Détails des produits
          if (order.items.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[800] : Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Détails des articles',
                    style: TextStyle(
                      fontSize: _textSizeService.getScaledFontSize(12),
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...order.items.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: statusColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.product.title ?? 'Produit sans nom',
                                style: TextStyle(
                                  fontSize: _textSizeService.getScaledFontSize(13),
                                  fontWeight: FontWeight.w500,
                                  color: isDarkMode ? Colors.white : Colors.black87,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Quantité: ${item.quantity} • ${item.product.price.toStringAsFixed(2)} FCFA',
                                style: TextStyle(
                                  fontSize: _textSizeService.getScaledFontSize(11),
                                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )).toList(),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          
          // Footer avec statut, date et montant
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      order.status.displayName,
                      style: TextStyle(
                        fontSize: _textSizeService.getScaledFontSize(11),
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formattedDate,
                    style: TextStyle(
                      fontSize: _textSizeService.getScaledFontSize(12),
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formattedAmount,
                    style: TextStyle(
                      fontSize: _textSizeService.getScaledFontSize(16),
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  if (order.metadata?['frais_livraison'] != null)
                    Text(
                      '+${(order.metadata!['frais_livraison'] as num).toStringAsFixed(2)} FCFA',
                      style: TextStyle(
                        fontSize: _textSizeService.getScaledFontSize(11),
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
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
        border: Border.all(color: color.withOpacity(0.15), width: 1),
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
                child: Icon(icon, color: color, size: 24),
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
        border: Border.all(color: color.withOpacity(0.15), width: 1),
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
            child: Icon(Icons.info_outline, color: color, size: 18),
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
                    color: isDarkMode
                        ? Colors.grey[300]
                        : const Color(0xFF6B7280),
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
                  color: isDarkMode
                      ? Colors.grey[400]
                      : const Color(0xFF6B7280),
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
                  color: isDarkMode
                      ? Colors.grey[400]
                      : const Color(0xFF6B7280),
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

  Widget _buildHomeworkItem(
    String subject,
    String task,
    String deadline,
    IconData icon,
    Color color,
  ) {
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
                    color: isDarkMode
                        ? Colors.grey[300]
                        : const Color(0xFF6B7280),
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
              Expanded(child: _buildBehaviorItem('Bon', '👍', Colors.blue)),
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
            child: Text(emoji, style: const TextStyle(fontSize: 24)),
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
