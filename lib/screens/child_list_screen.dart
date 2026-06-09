import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:parents_responsable/screens/inscription_screen.dart'
    as inscription;
import 'package:parents_responsable/widgets/image_menu_card.dart';
import 'package:parents_responsable/widgets/main_screen_wrapper.dart';
import '../services/student_scolarite_service.dart';
import '../widgets/bottom_sheets/school_event_bottom_sheet.dart';
import '../widgets/image_menu_card_external_title.dart';
import '../widgets/school_life_item_card.dart';
import '../widgets/custom_loader.dart';
import '../widgets/custom_button.dart';
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
import '../services/message_service.dart';
import '../services/mock_api_service.dart';
import '../services/remote_api_service.dart';
import '../services/text_size_service.dart';
import '../config/app_colors.dart';
import '../config/app_config.dart';
import '../config/app_dimensions.dart';
import '../services/theme_service.dart';
import '../screens/notes_screen_json.dart';
import '../services/student_timetable_service.dart';
import '../services/extra_scolaire_service.dart';
import '../models/student_timetable.dart';
import '../services/school_service.dart';
import '../widgets/payment_bottom_sheet.dart';
import '../widgets/paiement_historique_bottom_sheet.dart';
import '../widgets/bottom_sheets/bottom_sheet_header.dart';
import '../widgets/bottom_sheets/scolarite_bottom_sheet.dart';
import 'messages_screen.dart';
import '../services/access_control_service.dart';
import '../models/access_control.dart';
import '../widgets/bottom_fade_gradient.dart';
import '../widgets/bottom_sheets/child_kits_bottom_sheet.dart';
import '../widgets/components/bottom_spacer.dart';
import '../services/notes_api_service.dart';
import '../widgets/searchable_dropdown.dart';
import '../services/school_supply_service.dart';
import '../services/paiement_service.dart';
import '../models/student_message.dart';
import '../models/student_scolarite.dart';
import '../widgets/bottom_sheets/enhanced_scolarite_bottom_sheet.dart';
import '../widgets/bottom_sheets/my_reservations_bottom_sheet.dart';
import '../widgets/components/custom_date_input.dart';
import 'my_tickets_screen.dart';
import '../widgets/custom_sliver_app_bar.dart';
import '../widgets/section_header_widget.dart';
import '../widgets/components/section_row.dart';
import '../widgets/snackbar.dart';
import '../widgets/establishment_action_cards.dart' hide SchoolLifeItemCard;
import '../models/parent_suggestion.dart';
import '../services/parent_suggestion_service.dart';
import '../services/access_log_service.dart';
import '../widgets/filter_row_widget.dart';
import '../widgets/search_bar_widget.dart';
import '../services/echeance_service.dart';
import '../models/echeance_notification.dart';
import '../models/access_log.dart';
import '../models/place_reservation.dart';
import '../services/inscription_api_service.dart' as api_service;
import '../models/student_class_info.dart';
import '../models/group_message.dart';
import '../models/ecole.dart';
import '../services/group_message_service.dart';
import '../widgets/custom_loader.dart';
import '../services/ecole_eleve_service.dart';
import '../services/statistiques_presence_service.dart';
import '../services/gestion_presence_eleve_service.dart';
import '../models/gestion_presence_eleve_entry.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../widgets/subtle_retry_button.dart';
import '../widgets/bottom_sheets/integration_request_bottom_sheet.dart';
import '../widgets/custom_text_field.dart';
import '../services/bulletin_api_service.dart';
import 'pdf_viewer_screen.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

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
  bool _didInitialLoad = false;

  // Données de l'école récupérées directement depuis l'API spécifique à l'élève
  dynamic _apiEcoleData;

  final ThemeService _themeService = ThemeService();
  final TextSizeService _textSizeService = TextSizeService();
  final SchoolSupplyService _schoolSupplyService = SchoolSupplyService();
  final PaiementService _paiementService = PaiementService();
  final StudentTimetableService _timetableService = StudentTimetableService();
  final SchoolService _schoolService = SchoolService();
  final AccessControlService _accessControlService = AccessControlService();
  final MessageService _messageService = MessageService();
  final StudentScolariteService _scolariteService = StudentScolariteService();
  final MockParentSuggestionService _suggestionService =
      MockParentSuggestionService();
  final MockAccessLogService _accessLogService = MockAccessLogService();

  // Variables pour la gestion des commandes
  List<Order> _orders = [];
  Future<List<Order>>? _ordersFuture;
  bool _isLoadingOrders = false;

  // Variables pour l'emploi du temps dynamique
  StudentTimetableResponse? _timetableResponse;
  bool _isLoadingTimetable = false;
  StateSetter? _timetableModalSetState;
  String? _selectedTimetableDay;
  String? _expandedCourseKey;
  bool _timetableHasError = false;
  bool _isTimetableSheetOpen = false;
  StateSetter? _ordersModalSetState;
  String? _expandedOrderId;
  String _ordersStatusFilter = 'Tous';
  bool _isOrdersSearching = false;
  final TextEditingController _ordersSearchController = TextEditingController();

  // Variables pour le contrôle d'accès
  List<AccessControlEntry> _accessEntries = [];
  bool _isLoadingAccessControl = false;
  bool _isAccessControlBottomSheetOpen = false;
  StateSetter? _accessControlModalSetState;
  bool _accessControlLoaded = false;
  DateTime _selectedAccessDateDebut = DateTime.now().subtract(
    const Duration(days: 30),
  );
  DateTime _selectedAccessDateFin = DateTime.now();
  final TextEditingController _accessDateDebutController =
      TextEditingController();
  final TextEditingController _accessDateFinController =
      TextEditingController();

  // Variables pour les messages
  List<StudentMessage> _studentMessages = [];
  bool _isLoadingMessages = false;

  // Variables pour les scolarités
  List<StudentScolariteEntry> _scolariteEntries = [];
  bool _isLoadingScolarite = false;

  // Variables pour les suggestions
  List<ParentSuggestion> _suggestions = [];
  bool _isLoadingSuggestions = false;

  // Variables pour les statistiques de notes
  final NotesApiService _notesApiService = NotesApiService();
  String? _appreciation;
  double? _moyFr;
  double? _moyGeneral;
  bool _isLoadingNotes = false;

  // Variables pour les logs d'accès
  List<AccessLog> _accessLogs = [];
  bool _isLoadingAccessLogs = false;

  // Variables pour les réservations
  List<PlaceReservation> _reservations = [];
  bool _isLoadingReservations = false;

  // Variables pour les statistiques de présence
  StatistiquesPresence? _presenceStats;
  bool _isLoadingPresenceStats = false;

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
  Set<String> _expandedNotificationIds =
      <String>{}; // IDs des notifications étendues

  // Variables pour les notifications d'échéance
  EcheanceNotification? _echeanceNotification;
  bool _isLoadingEcheance = false;
  bool _echeanceLoaded = false;

  // Compter les notifications non lues
  int get unreadNotificationsCount =>
      _notifications.where((notification) => !notification.estLu).length;

  // Compter le total des notifications (messages + échéances)
  int get totalNotificationsCount {
    int count = _notifications
        .where((notification) => !notification.estLu)
        .length;
    if (_echeanceNotification?.hasUnpaidFees == true) {
      count += 1;
    }
    return count;
  }

  // Variables pour les données de notes globales
  GlobalAverage? _globalAverage;
  final PoulsScolaireApiService _poulsApiService = PoulsScolaireApiService();
  final BulletinApiService _bulletinApiService = BulletinApiService();

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

  // Données des bulletins
  List<dynamic>? _bulletins;
  bool _isLoadingBulletins = false;

  // Filtres pour Bulletins
  List<dynamic> _bulletinsSchoolYears = [];
  List<String> _bulletinsAvailableYears = [];
  bool _isLoadingBulletinsYears = false;
  bool _isBulletinsFilterExpanded = false;
  String? _expandedBulletinId;
  StateSetter? _bulletinsModalSetState;

  void _showSnackBarDeferred(SnackBar snackBar) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    });
  }

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
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeInOut,
          ),
        );

    _animationController.forward();

    // Init _accessDateDebutController
    final String initDateDebutStr =
        '${_selectedAccessDateDebut.day.toString().padLeft(2, '0')}/'
        '${_selectedAccessDateDebut.month.toString().padLeft(2, '0')}/'
        '${_selectedAccessDateDebut.year}';
    _accessDateDebutController.text = initDateDebutStr;

    _accessDateDebutController.addListener(() {
      final text = _accessDateDebutController.text;
      if (text.length == 10) {
        final parts = text.split('/');
        if (parts.length == 3) {
          final day = int.tryParse(parts[0]);
          final month = int.tryParse(parts[1]);
          final year = int.tryParse(parts[2]);
          if (day != null && month != null && year != null) {
            final parsedDate = DateTime(year, month, day);
            if (parsedDate != _selectedAccessDateDebut) {
              setState(() {
                _selectedAccessDateDebut = parsedDate;
              });
              _accessControlModalSetState?.call(() {});
              _loadAccessControlData(_accessControlModalSetState);
            }
          }
        }
      }
    });

    // Init _accessDateFinController
    final String initDateFinStr =
        '${_selectedAccessDateFin.day.toString().padLeft(2, '0')}/'
        '${_selectedAccessDateFin.month.toString().padLeft(2, '0')}/'
        '${_selectedAccessDateFin.year}';
    _accessDateFinController.text = initDateFinStr;

    _accessDateFinController.addListener(() {
      final text = _accessDateFinController.text;
      if (text.length == 10) {
        final parts = text.split('/');
        if (parts.length == 3) {
          final day = int.tryParse(parts[0]);
          final month = int.tryParse(parts[1]);
          final year = int.tryParse(parts[2]);
          if (day != null && month != null && year != null) {
            final parsedDate = DateTime(year, month, day);
            if (parsedDate != _selectedAccessDateFin) {
              setState(() {
                _selectedAccessDateFin = parsedDate;
              });
              _accessControlModalSetState?.call(() {});
              _loadAccessControlData(_accessControlModalSetState);
            }
          }
        }
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didInitialLoad) {
      _didInitialLoad = true;
      _loadData();
      _loadNotifications(); // Charger les notifications automatiquement
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _accessDateDebutController.dispose();
    _accessDateFinController.dispose();
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
      print('🔄 _isLoadingSupplies mis à false: $_isLoadingSupplies');

      // Si c'est une erreur 404 avec "Aucune fourniture scolaire trouvée", ne pas afficher d'erreur
      // car l'UI affiche déjà "Aucune fourniture trouvée"
      final errorString = e.toString();
      if (!errorString.contains('404') ||
          !errorString.contains('Aucune fourniture scolaire trouvée')) {
        if (mounted) {
          _showSnackBarDeferred(
            SnackBar(
              content: Text('Erreur lors du chargement des fournitures: $e'),
            ),
          );
        }
      }
    }
  }

  Future<void> _loadOrders() async {
    final authService = AuthService();
    final currentUser = authService.getCurrentUser();

    if (currentUser?.phone == null) {
      print(
        '⚠️ Impossible de charger les commandes: téléphone utilisateur manquant',
      );
      return;
    }

    setState(() {
      _isLoadingOrders = true;
    });

    try {
      print(
        '📦 Chargement des commandes pour le téléphone: ${currentUser!.phone}',
      );
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
        _showSnackBarDeferred(
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
      final wrapper = MainScreenWrapper.maybeOf(context);
      final apiService =
          wrapper?.apiService ??
          (AppConfig.MOCK_MODE ? MockApiService() : RemoteApiService());

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
          _apiEcoleData = ecoleData;
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
      // Exécuter séquentiellement avec un léger délai pour éviter l'erreur 429 (Too Many Attempts)
      final notesResult = await apiService.getNotesForChild(widget.child.id);
      await Future.delayed(const Duration(milliseconds: 200));

      final timetableResult = await apiService.getTimetableForChild(
        widget.child.id,
      );
      await Future.delayed(const Duration(milliseconds: 200));

      final messagesResult = await apiService.getMessages(
        wrapper?.currentUserId ??
            AuthService.instance.getCurrentUser()?.id ??
            'parent1',
      );
      await Future.delayed(const Duration(milliseconds: 200));

      final feesResult = await apiService.getFeesForChild(widget.child.id);
      await Future.delayed(const Duration(milliseconds: 200));

      setState(() {
        _notes = notesResult;
        _timetable = timetableResult;
        _messages = messagesResult;
        _fees = feesResult;
        _isLoading = false;
      });

      print('✅ Données de base chargées');
      print('   📝 Notes: ${_notes.length}');
      print('   📅 Timetable: ${_timetable.length}');
      print('   💬 Messages: ${_messages.length}');
      print('   💰 Fees: ${_fees.length}');

      // Étape 4: Charger les données de statistiques de notes
      print('Étape 4: Chargement des données de statistiques de notes...');
      await _loadNotesStatistics();

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
        _showSnackBarDeferred(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  // Charger les notifications (messages et échéances) automatiquement
  Future<void> _loadNotifications() async {
    print(
      '=== DÉBUT DU CHARGEMENT AUTOMATIQUE DES NOTIFICATIONS (CHILD LIST) ===',
    );

    // Utiliser le matricule déjà disponible dans _matricule
    final matricule = _matricule ?? widget.child.matricule;

    print('Matricule disponible pour les notifications: $matricule');

    if (matricule == null || matricule.isEmpty) {
      print('ERREUR: Matricule non disponible pour charger les notifications');
      return;
    }

    print('MATRICULE UTILISÉ: $matricule');
    print('DÉMARRAGE AUTOMATIQUE DES APIS DE NOTIFICATION...');

    // Charger les messages de groupe
    final groupMessageUrl =
        '${AppConfig.VIE_ECOLES_API_BASE_URL}/vie-ecoles/liste-messages-groupe/$matricule?per_page=20&page=1';
    print('=== APPEL API MESSAGES DE GROUPE (AUTOMATIQUE) ===');
    print('URL requête messages de groupe: $groupMessageUrl');
    try {
      print(
        'Début du chargement automatique des messages de groupe pour: $matricule',
      );
      setState(() => _isLoadingNotifications = true);
      final notifications = await GroupMessageService.getGroupMessages(
        matricule,
      );
      if (mounted) {
        setState(() {
          _notifications = notifications;
          _isLoadingNotifications = false;
          _notificationsLoaded = true;
        });
      }
      print(
        'SUCCÈS AUTO: Messages de groupe chargés automatiquement: ${notifications.length}',
      );
      for (final notif in notifications.take(3)) {
        // Limiter l'affichage des logs
        print('  - Message: ${notif.titre}, Lu: ${notif.estLu}');
      }
      if (notifications.length > 3) {
        print('  - ... et ${notifications.length - 3} autres messages');
      }
    } catch (e) {
      print('ERREUR lors du chargement automatique des messages: $e');
      if (mounted) {
        setState(() {
          _isLoadingNotifications = false;
          _notificationsLoaded = true;
        });
      }
    }

    final echeanceUrl =
        '${AppConfig.VIE_ECOLES_API_BASE_URL}/vie-ecoles/echeance-notification/$matricule';
    // Charger les notifications d'échéance
    print('=== APPEL API ÉCHÉANCES (AUTOMATIQUE) ===');
    print('URL requête échéance: $echeanceUrl');
    try {
      print(
        'Début du chargement automatique des notifications d\'échéance pour: $matricule',
      );
      setState(() => _isLoadingEcheance = true);
      final echeanceNotification =
          await EcheanceService.getEcheanceNotification(matricule);
      if (mounted) {
        setState(() {
          _echeanceNotification = echeanceNotification;
          _isLoadingEcheance = false;
          _echeanceLoaded = true;
        });
      }
      print('SUCCÈS AUTO: Notification d\'échéance chargée automatiquement');
      print('  - Statut: ${echeanceNotification.status}');
      final messagePreview = echeanceNotification.message.length > 100
          ? '${echeanceNotification.message.substring(0, 100)}...'
          : echeanceNotification.message;
      print('  - Message: $messagePreview');
      print('  - Impayée: ${echeanceNotification.hasUnpaidFees}');
    } catch (e) {
      print('ERREUR lors du chargement automatique des échéances: $e');
      if (mounted) {
        setState(() {
          _isLoadingEcheance = false;
          _echeanceLoaded = true;
        });
      }
    }

    print('=== FIN DU CHARGEMENT AUTOMATIQUE DES NOTIFICATIONS ===');
    print('Notifications chargées automatiquement: ${_notifications.length}');
    print('Échéance chargée automatiquement: ${_echeanceNotification != null}');
    print(
      'Total notifications automatiques: ${_notifications.length + (_echeanceNotification?.hasUnpaidFees == true ? 1 : 0)}',
    );
    print(
      'Badge du bouton notification sera mis à jour avec: ${totalNotificationsCount}',
    );
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

        print(' Informations de l\'enfant récupérées:');
        print('   École ID: $_ecoleId');
        print('   École Code (depuis childInfo): $_ecoleCode');
        print('   Classe ID: $_classeId');
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
        // Prioriser identifiantVieEcole sur childInfo['ecoleCode']
        if (studentClassInfo.identifiantVieEcole.isNotEmpty) {
          _ecoleCode = studentClassInfo.identifiantVieEcole;
          print('Code école extrait depuis identifiantVieEcole: $_ecoleCode');
          print(
            'MISE À JOUR: _ecoleCode changé de "${widget.child.ecoleCode}" à "$_ecoleCode"',
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

      // Charger les statistiques de présence après les détails de l'élève
      await _loadPresenceStats();
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

  Future<void> _loadPresenceStats() async {
    if (_matricule == null || _ecoleCode == null) {
      print(
        '⚠️ Informations manquantes pour charger les statistiques de présence',
      );
      return;
    }

    setState(() {
      _isLoadingPresenceStats = true;
    });

    try {
      print('📡 Chargement des statistiques de présence...');
      final stats = await StatistiquesPresenceService.getStatistiquesPresence(
        _matricule!,
        _ecoleCode!,
      );

      setState(() {
        _presenceStats = stats;
        _isLoadingPresenceStats = false;
      });

      print('✅ Statistiques de présence chargées: $stats');
    } catch (e) {
      print('❌ Erreur lors du chargement des statistiques de présence: $e');
      setState(() {
        _isLoadingPresenceStats = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = _themeService.isDarkMode;

    return Scaffold(
      backgroundColor: AppColors.screenBg(context),
      body: Stack(
        children: [
          CustomScrollView(
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
                      const SizedBox(height: 24),
                      _buildSectionHeader('Statistique', AppColors.primary),
                      _buildSummaryCardsGrid(),
                      const SizedBox(height: 8),
                      _buildPaymentBannerCard(),
                      const SizedBox(height: 24),
                      const BottomSpacer(),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Gradient fade at bottom
          BottomFadeGradient(endColor: AppColors.screenSurfaceThemed(context)),
        ],
      ),
    );
  }

  // ─── MÉTHODES DE BOTTOM SHEETS DIRECTES ────────────────────────────────────

  void _showNotesBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      constraints: BoxConstraints(
        maxWidth: AppDimensions.getBottomSheetMaxWidth(context),
      ),
      builder: (context) => Container(
        height: MediaQuery.sizeOf(context).height * 0.8,
        decoration: BoxDecoration(
          color: _themeService.isDarkMode ? Colors.grey[900] : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            BottomSheetHeader(
              icon: Icons.bar_chart_rounded,
              imagePath: 'assets/images/icons/mes_notes.png',
              imageBorderRadius: AppDimensions.getImageBorderRadius(context),
              iconColor: const Color(0xFF1976D2),
              title: 'Mes Notes',
              description: 'Consultez les notes et évaluations de votre enfant',
              onClose: () => Navigator.of(context).pop(),
            ),
            Expanded(child: _buildSimpleNotesTab()),
          ],
        ),
      ),
    );
  }

  void _showBulletinsBottomSheet() {
    // Reset pour permettre un rechargement propre à chaque ouverture
    _bulletins = null;
    _isLoadingBulletins = false;
    bool hasAttemptedLoad = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          _bulletinsModalSetState = setModalState;

          // Déclencher le chargement une seule fois
          if (!hasAttemptedLoad) {
            hasAttemptedLoad = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _loadBulletins(setModalState);
              _loadBulletinsSchoolYears(setModalState);
            });
          }

          return Container(
            height: MediaQuery.sizeOf(context).height * 0.8,
            decoration: BoxDecoration(
              color: _themeService.isDarkMode ? Colors.grey[900] : Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                BottomSheetHeader(
                  icon: Icons.description_rounded,
                  imagePath: 'assets/images/icons/mes_bulletins.png',
                  imageBorderRadius: AppDimensions.getImageBorderRadius(
                    context,
                  ),
                  iconColor: const Color(0xFF2E7D32),
                  title: 'Bulletins',
                  description: 'Accédez aux bulletins trimestriels et annuels',
                  onClose: () => Navigator.of(context).pop(),
                ),
                // Filtre des années
                _buildBulletinsFiltersSection(setModalState),
                // ↓ CLEF DU FIX : utilisation simple de l'état
                Expanded(
                  child: Builder(
                    builder: (context) {
                      print(
                        '🔍 DEBUG Builder: _isLoadingBulletins=$_isLoadingBulletins, _bulletins=${_bulletins?.length}',
                      );

                      if (_isLoadingBulletins) {
                        return _buildBulletinsLoadingState();
                      } else if (_bulletins == null || _bulletins!.isEmpty) {
                        return _buildBulletinsEmptyState();
                      } else {
                        return SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          child: _buildBulletinsList(),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    ).whenComplete(() {
      _bulletinsModalSetState = null;
    });
  }

  void _showTimetableBottomSheet() {
    final now = DateTime.now();
    final weekday = now.weekday;
    String todayStr = 'Lundi';
    if (weekday == 2)
      todayStr = 'Mardi';
    else if (weekday == 3)
      todayStr = 'Mercredi';
    else if (weekday == 4)
      todayStr = 'Jeudi';
    else if (weekday == 5)
      todayStr = 'Vendredi';
    else if (weekday == 6)
      todayStr = 'Samedi';
    else if (weekday == 7)
      todayStr = 'Dimanche';

    _selectedTimetableDay = todayStr;
    _isTimetableSheetOpen = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          _timetableModalSetState = setModalState;

          if (_timetableResponse == null &&
              !_isLoadingTimetable &&
              !_timetableHasError) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_timetableResponse == null &&
                  !_isLoadingTimetable &&
                  !_timetableHasError) {
                _loadTimetableData();
              }
            });
          }

          return Container(
            height: MediaQuery.sizeOf(context).height * 0.8,
            decoration: BoxDecoration(
              color: _themeService.isDarkMode ? Colors.grey[900] : Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                BottomSheetHeader(
                  icon: Icons.calendar_today_rounded,
                  imagePath: 'assets/images/icons/emploi_du_temps.png',
                  imageBorderRadius: AppDimensions.getImageBorderRadius(
                    context,
                  ),
                  iconColor: const Color(0xFFF57C00),
                  title: 'Emploi du temps',
                  description: 'Consultez l\'emploi du temps et les horaires',
                  onClose: () => Navigator.of(context).pop(),
                ),
                Expanded(child: _buildSimpleTimetableTab()),
              ],
            ),
          );
        },
      ),
    ).whenComplete(() {
      _timetableModalSetState = null;
      _isTimetableSheetOpen = false;
    });
  }

  void _showHomeworkBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      constraints: BoxConstraints(
        maxWidth: AppDimensions.getBottomSheetMaxWidth(context),
      ),
      builder: (context) => Container(
        height: MediaQuery.sizeOf(context).height * 0.8,
        decoration: BoxDecoration(
          color: _themeService.isDarkMode ? Colors.grey[900] : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            BottomSheetHeader(
              icon: Icons.edit_note_rounded,
              imagePath: 'assets/images/icons/devoirs.png',
              imageBorderRadius: AppDimensions.getImageBorderRadius(context),
              iconColor: const Color(0xFF7B1FA2),
              title: 'Devoirs',
              description: 'Suivez les devoirs et exercices à faire',
              onClose: () => Navigator.of(context).pop(),
            ),
            Expanded(child: _buildHomeworkTab()),
          ],
        ),
      ),
    );
  }

  void _showProgressionBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      constraints: BoxConstraints(
        maxWidth: AppDimensions.getBottomSheetMaxWidth(context),
      ),
      builder: (context) => Container(
        height: MediaQuery.sizeOf(context).height * 0.8,
        decoration: BoxDecoration(
          color: _themeService.isDarkMode ? Colors.grey[900] : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            BottomSheetHeader(
              icon: Icons.trending_up_rounded,
              imageBorderRadius: AppDimensions.getImageBorderRadius(context),
              iconColor: const Color(0xFF1976D2),
              title: 'Progression',
              description: 'Suivi de la progression',
              onClose: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: _buildComingSoonContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showHomeworkProgramBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      constraints: BoxConstraints(
        maxWidth: AppDimensions.getBottomSheetMaxWidth(context),
      ),
      builder: (context) => Container(
        height: MediaQuery.sizeOf(context).height * 0.8,
        decoration: BoxDecoration(
          color: _themeService.isDarkMode ? Colors.grey[900] : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            BottomSheetHeader(
              icon: Icons.assignment_rounded,
              imageBorderRadius: AppDimensions.getImageBorderRadius(context),
              iconColor: const Color(0xFF2E7D32),
              title: 'Programme de devoirs',
              description: 'Planning des devoirs',
              onClose: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: _buildComingSoonContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAttendanceBottomSheet() {
    _hasLoadedPresence = false;
    _hasLoadedStatistiques = false;

    // Prepopulate date filters (last month to today)
    final now = DateTime.now();
    _filterStartDate = DateTime(now.year, now.month - 1, now.day);
    _filterEndDate = DateTime(now.year, now.month, now.day);
    _filterStartDateController.text = "${_filterStartDate!.day.toString().padLeft(2, '0')}/${_filterStartDate!.month.toString().padLeft(2, '0')}/${_filterStartDate!.year}";
    _filterEndDateController.text = "${_filterEndDate!.day.toString().padLeft(2, '0')}/${_filterEndDate!.month.toString().padLeft(2, '0')}/${_filterEndDate!.year}";
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          _presenceModalSetState = setModalState;
          _presenceStatsModalSetState = setModalState;

          if (!_hasLoadedPresence && !_isLoadingPresence) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!_hasLoadedPresence && !_isLoadingPresence) {
                _loadPresenceData(setModalState);
              }
            });
          }

          final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
          final screenHeight = MediaQuery.sizeOf(context).height;
          final isDarkMode = _themeService.isDarkMode;
          final double sheetHeight = keyboardHeight > 0
              ? screenHeight * 0.95
              : screenHeight * 0.8;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: sheetHeight,
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[900] : Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.only(bottom: keyboardHeight),
              child: Column(
                children: [
                  BottomSheetHeader(
                    icon: Icons.person_off_rounded,
                    imagePath: 'assets/images/icons/presence_conduite.png',
                    imageBorderRadius: AppDimensions.getImageBorderRadius(
                      context,
                    ),
                    iconColor: const Color(0xFF00796B),
                    title: 'Présence',
                    description: 'Vérifiez la présence et la conduite',
                    onClose: () => Navigator.of(context).pop(),
                  ),
                  Expanded(child: _buildAbsencesTab()),
                ],
              ),
            ),
          );
        },
      ),
    ).whenComplete(() {
      _presenceModalSetState = null;
      _presenceStatsModalSetState = null;
    });
  }

  void _showAccessControlBottomSheet() {
    if (_isAccessControlBottomSheetOpen) return;
    _isAccessControlBottomSheetOpen = true;
    _accessControlLoaded = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          _accessControlModalSetState = setModalState;

          if (!_accessControlLoaded && !_isLoadingAccessControl) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!_accessControlLoaded && !_isLoadingAccessControl) {
                _loadAccessControlData(setModalState);
              }
            });
          }

          return Container(
            height: MediaQuery.sizeOf(context).height * 0.8,
            decoration: BoxDecoration(
              color: _themeService.isDarkMode ? Colors.grey[900] : Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                BottomSheetHeader(
                  icon: Icons.fingerprint_rounded,
                  imagePath: 'assets/images/icons/controle_acces.png',
                  imageBorderRadius: AppDimensions.getImageBorderRadius(
                    context,
                  ),
                  iconColor: const Color(0xFFC2185B),
                  title: 'Contrôle d\'accès',
                  description: 'Contrôlez les accès et les pointages',
                  onClose: () {
                    _isAccessControlBottomSheetOpen = false;
                    Navigator.of(context).pop();
                  },
                ),
                Expanded(child: _buildSimpleAccessControlTab()),
              ],
            ),
          );
        },
      ),
    ).whenComplete(() {
      _isAccessControlBottomSheetOpen = false;
      _accessControlModalSetState = null;
    });
  }

  void _showExtraScolaireBottomSheet() {
    final isDark = _themeService.isDarkMode;
    final schoolCode = _ecoleCode ?? widget.child.ecoleCode ?? '';
    final matricule = _matricule ?? widget.child.matricule ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return _ExtraScolaireSheetContent(
            isDark: isDark,
            schoolCode: schoolCode,
            matricule: matricule,
            childName: widget.child.fullName,
            textSizeService: _textSizeService,
            imagePath: 'assets/images/icons/services_scolaires.png',
            imageBorderRadius: AppDimensions.getImageBorderRadius(context),
          );
        },
      ),
    );
  }

  void _showSanctionsBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      constraints: BoxConstraints(
        maxWidth: AppDimensions.getBottomSheetMaxWidth(context),
      ),
      builder: (context) => Container(
        height: MediaQuery.sizeOf(context).height * 0.8,
        decoration: BoxDecoration(
          color: _themeService.isDarkMode ? Colors.grey[900] : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            BottomSheetHeader(
              icon: Icons.warning_rounded,
              imagePath: 'assets/images/icons/sanctions.png',
              imageBorderRadius: AppDimensions.getImageBorderRadius(context),
              iconColor: const Color(0xFFD32F2F),
              title: 'Sanctions',
              description: 'Consultez les sanctions et avertissements',
              onClose: () => Navigator.of(context).pop(),
            ),
            Expanded(child: _buildSanctionsTab()),
          ],
        ),
      ),
    );
  }

  void _showMessagesBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      constraints: BoxConstraints(
        maxWidth: AppDimensions.getBottomSheetMaxWidth(context),
      ),
      builder: (context) => Container(
        height: MediaQuery.sizeOf(context).height * 0.8,
        decoration: BoxDecoration(
          color: _themeService.isDarkMode ? Colors.grey[900] : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            BottomSheetHeader(
              icon: Icons.message_rounded,
              imagePath: 'assets/images/icons/messages.png',
              imageBorderRadius: AppDimensions.getImageBorderRadius(context),
              iconColor: const Color(0xFF0288D1),
              title: 'Messages',
              description: 'Lisez les messages et communications',
              onClose: () => Navigator.of(context).pop(),
            ),
            Expanded(child: _buildSimpleMessagesTab()),
          ],
        ),
      ),
    );
  }

  void _showDifficultiesBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      constraints: BoxConstraints(
        maxWidth: AppDimensions.getBottomSheetMaxWidth(context),
      ),
      builder: (context) => Container(
        height: MediaQuery.sizeOf(context).height * 0.8,
        decoration: BoxDecoration(
          color: _themeService.isDarkMode ? Colors.grey[900] : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            BottomSheetHeader(
              icon: Icons.psychology_rounded,
              imagePath: 'assets/images/icons/performance_scolaire.png',
              imageBorderRadius: AppDimensions.getImageBorderRadius(context),
              iconColor: const Color(0xFF9C27B0),
              title: 'Difficultés',
              description: 'Suivez les difficultés et le soutien',
              onClose: () => Navigator.of(context).pop(),
            ),
            Expanded(child: _buildDifficultiesTab()),
          ],
        ),
      ),
    );
  }

  void _showEventsBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      constraints: BoxConstraints(
        maxWidth: AppDimensions.getBottomSheetMaxWidth(context),
      ),
      builder: (context) => Container(
        height: MediaQuery.sizeOf(context).height * 0.8,
        decoration: BoxDecoration(
          color: _themeService.isDarkMode ? Colors.grey[900] : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            BottomSheetHeader(
              icon: Icons.event_rounded,
              imagePath: 'assets/images/icons/evenements_scolaires.png',
              imageBorderRadius: AppDimensions.getImageBorderRadius(context),
              iconColor: const Color(0xFF3F51B5),
              title: 'Événements',
              description: 'Participez aux événements et activités',
              onClose: () => Navigator.of(context).pop(),
            ),
            Expanded(child: _buildEventsTab()),
          ],
        ),
      ),
    );
  }

  void _showSuppliesBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        bool isLoading = true;
        List<SchoolSupply> supplies = [];
        bool didLoad = false;

        Future<void> loadSupplies(StateSetter modalSetState) async {
          if (_matricule == null) {
            modalSetState(() {
              isLoading = false;
              supplies = [];
            });
            return;
          }

          modalSetState(() {
            isLoading = true;
            supplies = [];
          });

          try {
            print(
              '📚 Chargement des fournitures pour le matricule: $_matricule',
            );
            final suppliesResponse = await _schoolSupplyService
                .getSchoolSupplies(_matricule!);

            modalSetState(() {
              supplies = suppliesResponse.data;
              isLoading = false;
            });

            print('✅ Fournitures chargées: ${supplies.length} items');
          } catch (e) {
            print('❌ Erreur lors du chargement des fournitures: $e');
            modalSetState(() {
              isLoading = false;
              supplies = [];
            });
          }
        }

        return StatefulBuilder(
          builder: (context, modalSetState) {
            if (!didLoad) {
              didLoad = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                loadSupplies(modalSetState);
              });
            }

            return Container(
              height: MediaQuery.sizeOf(context).height * 0.8,
              decoration: BoxDecoration(
                color: _themeService.isDarkMode
                    ? Colors.grey[900]
                    : Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  BottomSheetHeader(
                    icon: Icons.inventory_2_rounded,
                    imagePath: 'assets/images/icons/fournitures.png',
                    imageBorderRadius: AppDimensions.getImageBorderRadius(
                      context,
                    ),
                    iconColor: const Color(0xFF795548),
                    title: 'Fournitures',
                    description: 'Gérez les fournitures scolaires',
                    onClose: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Builder(
                        builder: (context) {
                          if (isLoading) {
                            return const Center(
                              child: CustomLoader(
                                message: 'Chargement des fournitures...',
                                loaderColor: AppColors.screenOrange,
                                showBackground: false,
                              ),
                            );
                          }

                          if (supplies.isEmpty) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
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
                              ),
                            );
                          }

                          return ListView.builder(
                            itemCount: supplies.length,
                            itemBuilder: (context, index) {
                              return _buildSupplyItemFromApi(supplies[index]);
                            },
                          );
                        },
                      ),
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

  void _showOrdersBottomSheet() {
    _expandedOrderId = null;
    _ordersStatusFilter = 'Tous';
    _isOrdersSearching = false;
    _ordersSearchController.clear();
    _ordersFuture = _loadOrdersFuture();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          _ordersModalSetState = setModalState;
          return Container(
            height: MediaQuery.sizeOf(context).height * 0.8,
            decoration: BoxDecoration(
              color: _themeService.isDarkMode ? Colors.grey[900] : Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                BottomSheetHeader(
                  icon: Icons.shopping_cart_rounded,
                  imagePath: 'assets/images/icons/mes_commandes.png',
                  imageBorderRadius: AppDimensions.getImageBorderRadius(
                    context,
                  ),
                  iconColor: const Color(0xFF00ACC1),
                  title: 'Commandes',
                  description: 'Suivez vos commandes et achats',
                  onClose: () => Navigator.of(context).pop(),
                ),
                Expanded(child: _buildOrdersTab(setModalState)),
              ],
            ),
          );
        },
      ),
    ).whenComplete(() {
      _ordersModalSetState = null;
    });
  }

  void _showAccessLogsBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      constraints: BoxConstraints(
        maxWidth: AppDimensions.getBottomSheetMaxWidth(context),
      ),
      builder: (context) => Container(
        height: MediaQuery.sizeOf(context).height * 0.8,
        decoration: BoxDecoration(
          color: _themeService.isDarkMode ? Colors.grey[900] : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            BottomSheetHeader(
              icon: Icons.security_rounded,
              imageBorderRadius: AppDimensions.getImageBorderRadius(context),
              iconColor: const Color(0xFF9C27B0),
              title: 'Logs d\'accès',
              description: 'Consultez les logs d\'accès et sécurité',
              onClose: () => Navigator.of(context).pop(),
            ),
            Expanded(child: _buildSimpleAccessLogsTab()),
          ],
        ),
      ),
    );
  }

  void _showSuggestionsBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      constraints: BoxConstraints(
        maxWidth: AppDimensions.getBottomSheetMaxWidth(context),
      ),
      builder: (context) => Container(
        height: MediaQuery.sizeOf(context).height * 0.8,
        decoration: BoxDecoration(
          color: _themeService.isDarkMode ? Colors.grey[900] : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            BottomSheetHeader(
              icon: Icons.lightbulb_rounded,
              imagePath: 'assets/images/icons/suggestions.png',
              imageBorderRadius: AppDimensions.getImageBorderRadius(context),
              iconColor: const Color(0xFFFFB300),
              title: 'Suggestions',
              description: 'Envoyez vos suggestions et feedback',
              onClose: () => Navigator.of(context).pop(),
            ),
            Expanded(child: _buildComingSoonContent()),
          ],
        ),
      ),
    );
  }

  void _showReservationsBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      constraints: BoxConstraints(
        maxWidth: AppDimensions.getBottomSheetMaxWidth(context),
      ),
      builder: (context) => Container(
        height: MediaQuery.sizeOf(context).height * 0.8,
        decoration: BoxDecoration(
          color: _themeService.isDarkMode ? Colors.grey[900] : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            BottomSheetHeader(
              icon: Icons.event_seat_rounded,
              imagePath: 'assets/images/icons/reservation_en_ligne.png',
              imageBorderRadius: AppDimensions.getImageBorderRadius(context),
              iconColor: const Color(0xFF2E7D32),
              title: 'Réservations',
              description: 'Gérez vos réservations et places',
              onClose: () => Navigator.of(context).pop(),
            ),
            // Statistiques de présence
            Expanded(child: _buildSimpleReservationsTab()),
          ],
        ),
      ),
    );
  }

  void _showFeesBottomSheet() {
    showFeesBottomSheet(
      context,
      childName: widget.child.fullName,
      childMatricule: widget.child.matricule,
      scolariteEntries: _scolariteEntries,
      isLoading: _isLoadingScolarite,
      errorMessage: null, // Pas de variable d'erreur dédiée pour l'instant
      onRefresh: _loadScolariteData,
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
            // ✅ Déclencher le chargement des deux types de notifications UNE SEULE FOIS
            if ((!_notificationsLoaded && !_isLoadingNotifications) ||
                (!_echeanceLoaded && !_isLoadingEcheance)) {
              // Afficher le loader après le cycle de build pour éviter l'erreur setState()
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  CustomLoaderOverlay.show(
                    context,
                    message: 'Chargement des notifications...',
                    loaderColor: AppColors.screenOrange,
                    showBackground: false,
                  );
                }
              });

              final matricule = _matricule ?? widget.child.matricule;
              if (matricule != null && matricule.isNotEmpty) {
                // Charger les messages de groupe
                if (!_notificationsLoaded && !_isLoadingNotifications) {
                  _isLoadingNotifications = true;
                  final messagesUrl =
                      '${AppConfig.VIE_ECOLES_API_BASE_URL}/vie-ecoles/liste-messages-groupe/$matricule?per_page=20&page=1';
                  print(
                    'URL requête messages de groupe (affichage notifications): $messagesUrl',
                  );
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
                          // Cacher le loader si les deux chargements sont terminés
                          if (_echeanceLoaded) {
                            CustomLoaderOverlay.hide();
                          }
                        }
                      })
                      .catchError((e) {
                        print('❌ Erreur notifications messages: $e');
                        if (mounted) {
                          setModalState(() {
                            _isLoadingNotifications = false;
                            _notificationsLoaded = true;
                          });
                          setState(() {
                            _isLoadingNotifications = false;
                            _notificationsLoaded = true;
                          });
                          // Cacher le loader si les deux chargements sont terminés
                          if (_echeanceLoaded) {
                            CustomLoaderOverlay.hide();
                          }
                        }
                      });
                }

                // Charger les notifications d'échéance
                if (!_echeanceLoaded && !_isLoadingEcheance) {
                  _isLoadingEcheance = true;
                  EcheanceService.getEcheanceNotification(matricule)
                      .then((echeanceNotification) {
                        if (mounted) {
                          setModalState(() {
                            _echeanceNotification = echeanceNotification;
                            _isLoadingEcheance = false;
                            _echeanceLoaded = true;
                          });
                          setState(() {
                            _echeanceNotification = echeanceNotification;
                            _isLoadingEcheance = false;
                            _echeanceLoaded = true;
                          });
                          // Cacher le loader si les deux chargements sont terminés
                          if (_notificationsLoaded) {
                            CustomLoaderOverlay.hide();
                          }
                        }
                      })
                      .catchError((e) {
                        print('❌ Erreur notifications échéance: $e');
                        if (mounted) {
                          setModalState(() {
                            _isLoadingEcheance = false;
                            _echeanceLoaded = true;
                          });
                          setState(() {
                            _isLoadingEcheance = false;
                            _echeanceLoaded = true;
                          });
                          // Cacher le loader si les deux chargements sont terminés
                          if (_notificationsLoaded) {
                            CustomLoaderOverlay.hide();
                          }
                        }
                      });
                }
              } else {
                CustomLoaderOverlay.hide();
                _isLoadingNotifications = false;
                _notificationsLoaded = true;
                _isLoadingEcheance = false;
                _echeanceLoaded = true;
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
                boxShadow: AppDimensions.getBottomSheetShadow(context),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  BottomSheetHeader(
                    icon: Icons.notifications_rounded,
                    imagePath: 'assets/images/icons/notifications.png',
                    imageBorderRadius: AppDimensions.getImageBorderRadius(
                      context,
                    ),
                    iconColor: const Color(0xFF1976D2),
                    title: 'Notifications',
                    description: (_isLoadingNotifications || _isLoadingEcheance)
                        ? 'Chargement en cours...'
                        : '${totalNotificationsCount} notification${totalNotificationsCount > 1 ? 's' : ''}',
                    onClose: () => Navigator.of(context).pop(),
                    //backgroundColor: const Color(0xFFE3F2FD),
                    titleColor: const Color(0xFF0D47A1),
                    descriptionColor: isDark
                        ? Colors.grey[400]
                        : Colors.grey[600],
                    iconSize: 24,
                    titleFontSize: _textSizeService.getScaledFontSize(14),
                    descriptionFontSize: _textSizeService.getScaledFontSize(10),
                    titleFontWeight: FontWeight.w600,
                  ),

                  // Content
                  Expanded(
                    child: (_isLoadingNotifications || _isLoadingEcheance)
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        const Color(
                                          0xFF1976D2,
                                        ).withOpacity(0.2),
                                        const Color(
                                          0xFF42A5F5,
                                        ).withOpacity(0.2),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const CircularProgressIndicator(
                                    color: Color(0xFF1976D2),
                                    strokeWidth: 3,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Chargement...',
                                  style: TextStyle(
                                    fontSize: _textSizeService
                                        .getScaledFontSize(14),
                                    color: isDark
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Section Échéances
                                if (_echeanceNotification != null) ...[
                                  _buildEcheanceSection(
                                    _echeanceNotification!,
                                    isDark,
                                  ),
                                  const SizedBox(height: 24),
                                ],

                                // Section Messages
                                _buildMessagesSection(isDark, setModalState),
                              ],
                            ),
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
    final isDark = _themeService.isDarkMode;
    final unreadBlue = const Color(0xFF378ADD);
    final isExpanded = _expandedNotificationIds.contains(notification.id);

    return GestureDetector(
      onTap: () {
        // Toggle expansion
        if (isExpanded) {
          _expandedNotificationIds.remove(notification.id);
        } else {
          _expandedNotificationIds.add(notification.id);
        }

        // Update both modal and main widget state
        setModalState(() {});
        setState(() {});

        // Mark as read if not already read
        if (!notification.estLu) {
          _markNotificationAsReadWithAPI(notification, setModalState);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8, left: 4, right: 4),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: AppDimensions.getBottomSheetShadow(context),
          border: isExpanded
              ? Border.all(
                  color: isDark
                      ? const Color(0x22FFFFFF)
                      : const Color(0x18000000),
                  width: 0.5,
                )
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              if (!notification.estLu)
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(width: 3, color: unreadBlue),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Dot indicateur
                    Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: notification.estLu
                              ? Colors.transparent
                              : unreadBlue,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Contenu
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Titre + heure
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  notification.titre,
                                  style: TextStyle(
                                    fontSize: _textSizeService
                                        .getScaledFontSize(14),
                                    fontWeight: notification.estLu
                                        ? FontWeight.w400
                                        : FontWeight.w500,
                                    color: notification.estLu
                                        ? (isDark
                                              ? Colors.white54
                                              : const Color(0xFF6B6B6B))
                                        : (isDark
                                              ? Colors.white
                                              : const Color(0xFF111111)),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                notification.formattedDate,
                                style: TextStyle(
                                  fontSize: _textSizeService.getScaledFontSize(
                                    11,
                                  ),
                                  color: isDark
                                      ? Colors.white30
                                      : const Color(0xFFAAAAAA),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),

                          // Expéditeur
                          Text(
                            notification.expediteurDisplay,
                            style: TextStyle(
                              fontSize: _textSizeService.getScaledFontSize(12),
                              color: isDark
                                  ? Colors.white38
                                  : const Color(0xFF999999),
                            ),
                          ),
                          const SizedBox(height: 6),

                          // Corps du message
                          Text(
                            notification.contenu,
                            style: TextStyle(
                              fontSize: _textSizeService.getScaledFontSize(13),
                              color: isDark
                                  ? Colors.white60
                                  : const Color(0xFF555555),
                              height: 1.5,
                            ),
                            maxLines: isExpanded ? null : 2,
                            overflow: isExpanded
                                ? TextOverflow.visible
                                : TextOverflow.ellipsis,
                          ),

                          if (notification.hasAttachment) ...[
                            const SizedBox(height: 10),
                            _buildNotificationAttachmentWidget(notification),
                          ],

                          // Action "Marquer comme lu" / "Lu"
                          const SizedBox(height: 8),
                          if (!notification.estLu) ...[
                            GestureDetector(
                              onTap: () => _markNotificationAsReadWithAPI(
                                notification,
                                setModalState,
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(0xFF1976D2).withOpacity(0.1),
                                      const Color(0xFF42A5F5).withOpacity(0.05),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: const Color(
                                      0xFF1976D2,
                                    ).withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.check_circle_outline,
                                      size: 12,
                                      color: const Color(0xFF1976D2),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Marquer comme lu',
                                      style: TextStyle(
                                        fontSize: _textSizeService
                                            .getScaledFontSize(11),
                                        color: const Color(0xFF1976D2),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ] else ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.grey[700]
                                    : Colors.grey[200],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    size: 12,
                                    color: isDark
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Lu',
                                    style: TextStyle(
                                      fontSize: _textSizeService
                                          .getScaledFontSize(11),
                                      color: isDark
                                          ? Colors.grey[400]
                                          : Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
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

  Widget _buildNotificationAttachmentWidget(GroupMessage notification) {
    final attachmentUrl = notification.attachmentUrl;
    if (attachmentUrl == null || attachmentUrl.isEmpty) {
      return const SizedBox.shrink();
    }

    final isDark = _themeService.isDarkMode;
    final isImage =
        notification.attachmentKind == GroupMessageAttachmentType.image;
    final isAudio =
        notification.attachmentKind == GroupMessageAttachmentType.audio;
    final isDocument =
        notification.attachmentKind == GroupMessageAttachmentType.document;
    final displayName =
        notification.attachmentName ?? attachmentUrl.split('/').last;

    if (isImage) {
      return GestureDetector(
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: EdgeInsets.zero,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(color: Colors.black87),
                  ),
                  InteractiveViewer(
                    child: Center(
                      child: Image.network(
                        attachmentUrl,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  Positioned(
                    top: 40,
                    right: 20,
                    child: IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 30,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            attachmentUrl,
            width: double.infinity,
            height: 140,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return Container(
                width: double.infinity,
                height: 140,
                color: isDark
                    ? const Color(0xFF2A2A2A)
                    : const Color(0xFFF5F5F5),
                child: Center(
                  child: CircularProgressIndicator(
                    value: progress.expectedTotalBytes != null
                        ? progress.cumulativeBytesLoaded /
                              (progress.expectedTotalBytes ?? 1)
                        : null,
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: double.infinity,
                height: 140,
                color: isDark
                    ? const Color(0xFF2A2A2A)
                    : const Color(0xFFF5F5F5),
                child: Center(
                  child: Icon(
                    Icons.broken_image,
                    size: 32,
                    color: isDark ? Colors.white38 : const Color(0xFF999999),
                  ),
                ),
              );
            },
          ),
        ),
      );
    }

    final icon = isAudio
        ? Icons.audiotrack_outlined
        : (isDocument
              ? Icons.picture_as_pdf_outlined
              : Icons.attach_file_outlined);
    final label = isAudio
        ? 'Pièce jointe audio'
        : (isDocument ? 'Pièce jointe document' : 'Pièce jointe');

    return GestureDetector(
      onTap: () async {
        final uri = Uri.parse(attachmentUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0x10FFFFFF) : const Color(0xFFF2F6FF),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? const Color(0x22FFFFFF) : const Color(0x1F1976D2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isAudio
                  ? const Color(0xFF1976D2)
                  : (isDocument
                        ? const Color(0xFF8A2BE2)
                        : const Color(0xFF1976D2)),
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: _textSizeService.getScaledFontSize(12),
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF111111),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    displayName,
                    style: TextStyle(
                      fontSize: _textSizeService.getScaledFontSize(11),
                      color: isDark ? Colors.white54 : const Color(0xFF555555),
                      height: 1.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.open_in_new,
              size: 18,
              color: isDark ? Colors.white54 : const Color(0xFF1976D2),
            ),
          ],
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
        CartSnackBar.showOverlay(
          context,
          productName: 'Notification',
          message: 'marquée comme lue',
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 2),
        );
      } else {
        print('❌ Échec du marquage du message comme lu');
      }
    } catch (e) {
      print('❌ Erreur lors du marquage du message: $e');
    }
  }

  Future<void> _markNotificationAsReadWithAPI(
    GroupMessage notification,
    StateSetter setModalState,
  ) async {
    if (notification.conversationId != null) {
      // Utiliser la nouvelle API POST si conversation_id est disponible
      final currentUser = AuthService.instance.getCurrentUser();
      final numeroParent =
          currentUser?.phone ??
          '0707074647'; // Valeur par défaut si non disponible

      try {
        print(
          '📝 Marquage de la conversation ${notification.conversationId} comme lue...',
        );
        print('📞 Numéro parent utilisé: $numeroParent');
        final messageService = MessageService();
        final success = await messageService.markMessagesAsRead(
          numeroParent: numeroParent,
          conversationId: notification.conversationId!,
        );

        if (success) {
          // Mettre à jour l'état local
          setModalState(() {
            final index = _notifications.indexWhere(
              (n) => n.id == notification.id,
            );
            if (index != -1) {
              _notifications[index] = _notifications[index].copyWith(
                estLu: true,
              );
            }
          });

          // Mettre à jour l'état du widget
          if (mounted) {
            setState(() {
              final index = _notifications.indexWhere(
                (n) => n.id == notification.id,
              );
              if (index != -1) {
                _notifications[index] = _notifications[index].copyWith(
                  estLu: true,
                );
              }
            });
          }

          print('✅ Conversation marquée comme lue avec succès');
          CartSnackBar.show(
            context,
            productName: 'Notification',
            message: 'marquée comme lue',
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
          );
        } else {
          print('❌ Échec du marquage de la conversation comme lue');
        }
      } catch (e) {
        print('❌ Erreur lors du marquage de la conversation: $e');
      }
    } else {
      // Utiliser l'ancienne API PUT si conversation_id n'est pas disponible
      await _markNotificationAsRead(notification.id, setModalState);
    }
  }

  Future<void> _markEcheanceAsRead(EcheanceNotification echeance) async {
    if (echeance.conversationId == null) {
      print(
        '❌ conversation_id non disponible pour marquer l\'échéance comme lue',
      );
      return;
    }

    // Récupérer le numéro du parent connecté
    final currentUser = AuthService.instance.getCurrentUser();
    final numeroParent =
        currentUser?.phone ??
        '0707074647'; // Valeur par défaut si non disponible

    try {
      print(
        '📝 Marquage de l\'échéance conversation ${echeance.conversationId} comme lue...',
      );
      print('📞 Numéro parent utilisé: $numeroParent');
      final messageService = MessageService();
      final success = await messageService.markMessagesAsRead(
        numeroParent: numeroParent,
        conversationId: echeance.conversationId!,
      );

      if (success) {
        // Mettre à jour l'état local
        setState(() {
          _echeanceNotification = EcheanceNotification(
            data: echeance.data,
            status: echeance.status,
            message: echeance.message,
            conversationId: echeance.conversationId,
            estLu: true,
          );
        });

        print('✅ Échéance marquée comme lue avec succès');
      } else {
        print('❌ Échec du marquage de l\'échéance comme lue');
      }
    } catch (e) {
      print('❌ Erreur lors du marquage de l\'échéance: $e');
    }
  }

  Widget _buildModernSliverAppBar() {
    final isDarkMode = _themeService.isDarkMode;

    return CustomSliverAppBar(
      title: widget.child.fullName,
      isDark: isDarkMode,
      expandedHeight: 70,
      actions: [_buildNotificationButton(), _buildMoreButton()], //,
      titleTextStyle: TextStyle(
        fontSize: _textSizeService.getScaledFontSize(16),
        fontWeight: FontWeight.w700,
        color: isDarkMode
            ? Colors.white
            : Theme.of(context).textTheme.titleLarge?.color,
        letterSpacing: -0.5,
      ),
    );
  }

  Widget _buildNotificationButton() {
    final theme = Theme.of(context);
    final isDarkMode = _themeService.isDarkMode;

    return GestureDetector(
      onTap: () async {
        await _refreshNotificationData();
        _showNotificationsBottomSheet();
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 40,
            height: 40,
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? const Color(0xFF2A2A2A)
                  : AppColors.screenCard,
              borderRadius: BorderRadius.circular(
                AppDimensions.getSmallCardBorderRadius(context),
              ),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.screenShadow,
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.notifications_outlined,
              size: 18,
              color: theme.iconTheme.color,
            ),
          ),
          // Badge pour les notifications totales (messages + échéances)
          if (totalNotificationsCount > 0)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(
                    AppDimensions.getSmallCardBorderRadius(context),
                  ),
                  border: Border.all(color: AppColors.screenCard, width: 1.5),
                ),
                child: Text(
                  totalNotificationsCount > 99
                      ? '99+'
                      : totalNotificationsCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
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

    return PopupMenuButton<String>(
      offset: const Offset(0, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.transparent,
      elevation: 0,
      onSelected: (value) {
        if (value == 'remove_child') {
          _showRemoveChildConfirmation();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          value: 'remove_child',
          padding: EdgeInsets.zero,
          child: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppDimensions.getSettingsCardShadow(context),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.person_remove_rounded,
                    color: Colors.red,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Retirer cet enfant',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
      child: Container(
        width: 40,
        height: 40,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF2A2A2A) : AppColors.screenCard,
          borderRadius: BorderRadius.circular(
            AppDimensions.getSmallCardBorderRadius(context),
          ),
          boxShadow: const [
            BoxShadow(
              color: AppColors.screenShadow,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Icon(Icons.more_vert, size: 18, color: theme.iconTheme.color),
      ),
    );
  }

  Widget _buildModernProfileHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      padding: EdgeInsets.symmetric(
        horizontal: AppDimensions.getMainContainerPadding(context),
        vertical: 16,
      ),
      decoration: BoxDecoration(
        gradient: AppColors.screenOrangeGradient,
        borderRadius: BorderRadius.circular(
          AppDimensions.getMainContainerBorderRadius(context),
        ),
        /*boxShadow: [
          BoxShadow(
            color: AppColors.screenOrange.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],*/
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
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
                        ],
                        const Spacer(),
                        _PulseAnimatedButton(onTap: _showFamilyBottomSheet),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
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
          borderRadius: BorderRadius.circular(
            AppDimensions.getProfileDetailsBorderRadius(context) * 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: AppDimensions.getActionButtonSize(context) * 0.35,
              color: Colors.white.withOpacity(0.8),
            ),
            SizedBox(
              width: AppDimensions.getProfileDetailsSpacing(context) * 0.5,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize:
                          AppDimensions.getDetailsButtonFontSize(context) *
                          0.85,
                      color: Colors.white.withOpacity(0.7),
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(
                    height:
                        AppDimensions.getProfileDetailsSpacing(context) * 0.25,
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize:
                          AppDimensions.getDetailsButtonFontSize(context) *
                          0.85,
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
                padding: EdgeInsets.only(
                  left: AppDimensions.getProfileDetailsSpacing(context) * 0.25,
                ),
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
        borderRadius: BorderRadius.circular(
          AppDimensions.getProfileDetailsBorderRadius(context) * 0.5,
        ),
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
    final eleve =
        _eleveDetail ??
        {
          'matricule': widget.child.matricule ?? '',
          'prenom': widget.child.firstName,
          'nom': widget.child.lastName,
          'niveau': widget.child.grade,
        };
    final isDarkMode = _themeService.isDarkMode;
    final draggableController = DraggableScrollableController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        controller: draggableController,
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
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
              BottomSheetHeader(
                icon: Icons.info_outline,
                title: 'Informations complètes',
                description: 'Détails complets sur l\'élève et sa scolarité',
                iconColor: Colors.blue,
                onClose: () => Navigator.of(context).pop(),
                draggableController: draggableController,
              ),

              // Contenu complet
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // QR Code d'identification - affiché en premier et centré
                      Center(
                        child: _buildFamilySection(
                          title: 'QR Code d\'identification',
                          icon: Icons.qr_code_2_rounded,
                          iconColor: Colors.purple,
                          children: [
                            Center(
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 10,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    QrImageView(
                                      data: _generateStudentQRData(eleve),
                                      version: QrVersions.auto,
                                      size: 150.0,
                                      backgroundColor: Colors.white,
                                      foregroundColor: Colors.black,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Matricule: ${eleve['matricule']?.toString() ?? 'N/A'}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${eleve['prenom']?.toString() ?? ''} ${eleve['nom']?.toString() ?? ''}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Informations personnelles
                      _buildFamilySection(
                        title: 'Informations personnelles',
                        icon: Icons.person,
                        iconColor: Colors.blue,
                        children: [
                          _buildFamilyItem(
                            icon: Icons.badge,
                            label: 'Matricule',
                            value: eleve['matricule']?.toString() ?? 'N/A',
                          ),
                          _buildFamilyItem(
                            icon: Icons.cake,
                            label: 'Né(e)',
                            value: _formatDate(
                              eleve['datenaissance']?.toString() ?? 'N/A',
                            ),
                          ),
                          _buildFamilyItem(
                            icon: Icons.wc,
                            label: 'Sexe',
                            value: eleve['sexe']?.toString() ?? 'N/A',
                          ),
                          _buildFamilyItem(
                            icon: Icons.location_on,
                            label: 'Lieu',
                            value: eleve['lieun']?.toString() ?? 'N/A',
                          ),
                          _buildFamilyItem(
                            icon: Icons.flag,
                            label: 'Nationalité',
                            value: eleve['nationalite']?.toString() ?? 'N/A',
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Informations scolaires
                      _buildFamilySection(
                        title: 'Informations scolaires',
                        icon: Icons.school,
                        iconColor: Colors.orange,
                        children: [
                          _buildFamilyItem(
                            icon: Icons.grade,
                            label: 'Niveau',
                            value: eleve['niveau']?.toString() ?? 'N/A',
                          ),
                          _buildFamilyItem(
                            icon: Icons.category,
                            label: 'Filière',
                            value: eleve['filiere']?.toString() ?? 'N/A',
                          ),
                          _buildFamilyItem(
                            icon: Icons.auto_stories,
                            label: 'Série',
                            value: eleve['serie']?.toString() ?? 'N/A',
                          ),
                          _buildFamilyItem(
                            icon: Icons.refresh,
                            label: 'Redoublant',
                            value: eleve['redoublant']?.toString() ?? 'N/A',
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

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

                      const SizedBox(height: 24),

                      // Bouton pour retirer l'enfant
                      _buildRemoveChildSection(),
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

  // ─── MÉTHODES DE SUPPRESSION D'ENFANT ─────────────────────────────────────

  void _showRemoveChildConfirmation({bool fromChildInfos = false}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      constraints: BoxConstraints(
        maxWidth: AppDimensions.getBottomSheetMaxWidth(context),
      ),
      builder: (context) => Container(
        margin: const EdgeInsets.only(top: 100),
        decoration: BoxDecoration(
          color: _themeService.isDarkMode ? Colors.grey[900] : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: AppDimensions.getBottomSheetShadow(context),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Stack(
              alignment: Alignment.center,
              children: [
                Column(
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      width: 48,
                      height: 4,
                      decoration: BoxDecoration(
                        color: _themeService.isDarkMode ? Colors.grey[700] : Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.warning_rounded,
                          color: Colors.red,
                          size: 36,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Retirer cet enfant',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.red,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Cette action est irréversible',
                      style: TextStyle(
                        fontSize: 15,
                        color: _themeService.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Content
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
              child: Column(
                children: [
                  Text(
                    'Êtes-vous sûr de vouloir retirer cet enfant de votre liste ?',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _themeService.isDarkMode ? Colors.white : Colors.grey[800],
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  
                  // Child Info Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _themeService.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _themeService.isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.15),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.orange.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: const Icon(
                            Icons.person_outline_rounded,
                            color: Colors.orange,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.child.fullName,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: _themeService.isDarkMode ? Colors.white : Colors.black87,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _themeService.isDarkMode ? Colors.grey[800] : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  widget.child.grade,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: _themeService.isDarkMode ? Colors.grey[300] : Colors.grey[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Warning Banner
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.red.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: Colors.red[400],
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Toutes les données associées à cet enfant seront définitivement supprimées.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.red,
                              fontWeight: FontWeight.w500,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Actions
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      onPressed: () => Navigator.of(context).pop(),
                      text: 'Annuler',
                      backgroundColor: Colors.transparent,
                      textColor: _themeService.isDarkMode
                          ? Colors.grey[400]!
                          : Colors.grey[600]!,
                      border: BorderSide(
                        color: _themeService.isDarkMode
                            ? Colors.grey[600]!
                            : Colors.grey[400]!,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomButton(
                      onPressed: () {
                        Navigator.of(
                          context,
                        ).pop(); // Fermer le bottom sheet de confirmation
                        Navigator.of(
                          context,
                        ).pop(); // Fermer le bottom sheet d'informations
                        _removeChild();
                      },
                      text: 'Retirer',
                      backgroundColor: Colors.red,
                      textColor: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ],
              ),
            ),
            const BottomSpacer(height: 60),
          ],
        ),
      ),
    );
  }

  Future<void> _removeChild() async {
    try {
      // Afficher un indicateur de chargement
      if (mounted) {
        setState(() {
          _isLoading = true;
        });
      }

      // Supprimer l'enfant de la base de données
      await DatabaseService.instance.deleteChild(widget.child.id);

      // Afficher un message de succès
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Enfant retiré avec succès'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }

      // Naviguer vers l'écran précédent et rafraîchir la liste
      if (mounted) {
        final wrapper = MainScreenWrapper.maybeOf(context);

        if (wrapper != null) {
          wrapper.goBackToPreviousTab();
          wrapper.refreshCurrentUser();
        } else if (Navigator.canPop(context)) {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      // Afficher un message d'erreur
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du retrait: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Génère les données pour le QR code d'identification de l'élève
  String _generateStudentQRData(Map<String, dynamic> eleve) {
    final matricule = eleve['matricule']?.toString() ?? '';
    final prenom = eleve['prenom']?.toString() ?? '';
    final nom = eleve['nom']?.toString() ?? '';
    final niveau = eleve['niveau']?.toString() ?? '';
    final datenaissance = eleve['datenaissance']?.toString() ?? '';

    // Créer un format JSON structuré pour le QR code
    final qrData = {
      'type': 'student_identification',
      'matricule': matricule,
      'nom_complet': '$prenom $nom',
      'prenom': prenom,
      'nom': nom,
      'niveau': niveau,
      'date_naissance': datenaissance,
      'ecole': 'École de l\'élève',
      'timestamp': DateTime.now().toIso8601String(),
    };

    return jsonEncode(qrData);
  }

  Widget _buildFamilySection({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Widget> children,
  }) {
    final validChildren = children
        .where((child) => child is! SizedBox)
        .toList();
    if (validChildren.isEmpty) return const SizedBox.shrink();

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
        ...validChildren,
      ],
    );
  }

  Widget _buildRemoveChildSection() {
    final isDarkMode = _themeService.isDarkMode;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.person_remove,
                  color: Colors.red,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Gestion de l\'enfant',
                  style: TextStyle(
                    fontSize: _textSizeService.getScaledFontSize(16),
                    fontWeight: FontWeight.w700,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: CustomButton(
              onPressed: () => _showRemoveChildConfirmation(fromChildInfos: true),
              icon: Icons.delete_forever,
              text: 'Retirer cet enfant',
              backgroundColor: Colors.red,
              textColor: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFamilyItem({
    required IconData icon,
    required String label,
    required String value,
    bool isClickable = false,
    VoidCallback? onTap,
  }) {
    final val = value.trim().toLowerCase();
    if (val.isEmpty || val == 'n/a' || val == 'null' || val == '-') {
      return const SizedBox.shrink();
    }

    final isDarkMode = _themeService.isDarkMode;

    return GestureDetector(
      onTap: isClickable && onTap != null ? onTap : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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

  // ─── Helper : En-tête de section (barre colorée + titre)
  Widget _buildSectionHeader(
    String title,
    Color accentColor, {
    EdgeInsets? padding,
    bool showLeftIndicator = true,
    bool showBottomDivider = false,
    Color? dividerColor,
    double? dividerHeight,
  }) {
    return SectionHeaderWidget(
      title: title,
      isDark: _themeService.isDarkMode,
      accentColor: accentColor,
      padding: padding, // on passe le padding custom
      showLeftIndicator: showLeftIndicator,
      showBottomDivider: showBottomDivider,
      dividerColor: dividerColor,
      dividerHeight: dividerHeight,
    );
  }

  // ─── CARD BUILDER (wrapper ImageMenuCardExternalTitle) ─────────────────────
  Widget _buildCard({
    required int index,
    required String cardKey,
    required String title,
    required String imagePath,
    required Color color,
    required Color backgroundColor,
    required Color textColor,
    required String actionText,
    required VoidCallback onTap,
    bool enableInnerBorder = false,
    bool enableOuterBorder = false,
    Color? innerBorderColor,
    double imageBorderRadius = 14,
    double width = 100,
    double height = 100,
    double doubleBorderGap = 1.0,
    bool centerTitle = false,
    bool allowLineBreak = false,
  }) {
    final isDark = _themeService.isDarkMode;
    return ImageMenuCardExternalTitle(
      index: index,
      cardKey: cardKey,
      title: title,
      width: width,
      height: null, // Force l'image à être un carré (hauteur = largeur)
      imageFlex: 2,
      imagePath: imagePath,
      isDark: isDark,
      titleFontSize: AppDimensions.getScaledSize(context, 11.0),
      imageBorderRadius:
          width / 2, // Moitié de la largeur pour un cercle parfait
      doubleBorderGap: doubleBorderGap,
      color: color,
      textColor: isDark ? Colors.white : textColor,
      actionText: actionText,
      onTap: onTap,
      enableInnerBorder: enableInnerBorder,
      enableOuterBorder: enableOuterBorder,
      innerBorderColor: innerBorderColor,
      centerTitle: centerTitle,
      allowLineBreak: allowLineBreak,
    );
  }

  // ─── Helper : Rangée horizontale scrollable de ImageMenuCard ──────────────
  Widget _buildHorizontalCards(List<Widget> cards) {
    return SizedBox(
      height: 120,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 16, right: 24),
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
        SectionRow(title: 'Paiements & Inscription'),
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal:
                AppDimensions.getPaymentBannerCardSpacing(context) * 0.8,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Builder(
                builder: (context) {
                  final isTablet =
                      AppDimensions.isSmallTablet(context) ||
                      AppDimensions.isTablet(context) ||
                      AppDimensions.isLargeTablet(context);
                  final crossAxisCount = isTablet ? 6 : 4;

                  final List<Widget> cards = [
                    _buildCard(
                      index: 0,
                      cardKey: 'reservations',
                      title: 'Réservation\nen ligne',
                      imagePath: 'assets/images/icons/reservation_en_ligne.png',
                      color: AppColors.cardLightGrey,
                      backgroundColor: const Color(0xFFF8FCFF),
                      textColor: const Color(0xFF333333),
                      actionText: '',
                      enableInnerBorder: false,
                      enableOuterBorder: false,
                      innerBorderColor: const Color(0xFF93C5FD),
                      imageBorderRadius: AppDimensions.getImageBorderRadius(
                        context,
                      ),
                      width: AppDimensions.getSquareCardWidthSize(context),
                      height: AppDimensions.getSquareCardHeightSize(context),
                      centerTitle: true,
                      allowLineBreak: true,
                      onTap: _showReservationPaiementBottomSheet,
                    ),
                    _buildCard(
                      index: 6,
                      cardKey: 'mes_reservations',
                      title: 'Mes\nréservations',
                      imagePath: 'assets/images/icons/consulter_demande.png',
                      color: AppColors.cardLightGrey,
                      backgroundColor: const Color(0xFFF0FDF4),
                      textColor: const Color(0xFF333333),
                      actionText: '',
                      enableInnerBorder: false,
                      enableOuterBorder: false,
                      innerBorderColor: const Color(0xFF86EFAC),
                      imageBorderRadius: AppDimensions.getImageBorderRadius(
                        context,
                      ),
                      width: AppDimensions.getSquareCardWidthSize(context),
                      height: AppDimensions.getSquareCardHeightSize(context),
                      centerTitle: true,
                      allowLineBreak: true,
                      onTap: () {
                        MyReservationsBottomSheet.show(
                          context: context,
                          childName: widget.child.firstName,
                          matricule: widget.child.matricule ?? _matricule ?? '',
                          imagePath:
                              'assets/images/icons/consulter_demande.png',
                          imageBorderRadius: AppDimensions.getImageBorderRadius(
                            context,
                          ),
                        );
                      },
                    ),
                    _buildCard(
                      index: 3,
                      cardKey: 'paiement',
                      title: 'Paiement\nscolarité',
                      imagePath: 'assets/images/icons/paiement_scolarite.png',
                      color: AppColors.cardLightGrey,
                      backgroundColor: const Color(0xFFE8F5E9),
                      textColor: const Color(0xFF333333),
                      actionText: '',
                      enableInnerBorder: false,
                      allowLineBreak: true,
                      enableOuterBorder: false,
                      innerBorderColor: const Color(0xFF81C784),
                      imageBorderRadius: AppDimensions.getImageBorderRadius(
                        context,
                      ),
                      width: AppDimensions.getSquareCardWidthSize(context),
                      height: AppDimensions.getSquareCardHeightSize(context),
                      centerTitle: true,
                      onTap: _showScolaritePaiementBottomSheet,
                    ),
                    _buildCard(
                      index: 1,
                      cardKey: 'historique_paiements',
                      title: 'Historique \n paiement',
                      imagePath: 'assets/images/icons/historique_paiement.png',
                      backgroundColor: const Color.fromARGB(255, 253, 253, 253),
                      textColor: const Color(0xFF333333),
                      actionText: '',
                      allowLineBreak: true,
                      enableInnerBorder: false,
                      enableOuterBorder: false,
                      color: AppColors.cardLightGrey,
                      innerBorderColor: const Color.fromARGB(
                        255,
                        253,
                        253,
                        253,
                      ),
                      imageBorderRadius: AppDimensions.getImageBorderRadius(
                        context,
                      ),
                      width: AppDimensions.getSquareCardWidthSize(context),
                      height: AppDimensions.getSquareCardHeightSize(context),
                      centerTitle: true,
                      onTap: _showHistoriquePaiementsBottomSheet,
                    ),
                    _buildCard(
                      index: 2,
                      cardKey: 'inscription',
                      title: 'Inscription \n en ligne',
                      imagePath: 'assets/images/icons/inscription_en_ligne.png',
                      color: AppColors.cardLightGrey,
                      backgroundColor: const Color(0xFFF7FEFC),
                      textColor: const Color(0xFF333333),
                      actionText: '',
                      enableInnerBorder: false,
                      enableOuterBorder: false,
                      allowLineBreak: true,
                      innerBorderColor: const Color(0xFF6EE7B7),
                      imageBorderRadius: AppDimensions.getImageBorderRadius(
                        context,
                      ),
                      width: AppDimensions.getSquareCardWidthSize(context),
                      height: AppDimensions.getSquareCardHeightSize(context),
                      centerTitle: true,
                      onTap: () {
                        final updatedChild =
                            _ecoleCode != null && _ecoleCode!.isNotEmpty
                            ? widget.child.copyWith(ecoleCode: _ecoleCode)
                            : widget.child;

                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                inscription.InscriptionWizardScreen(
                                  child: updatedChild,
                                  uid: _eleveDetail?['uid'],
                                  eleveDetail: _eleveDetail,
                                ),
                          ),
                        );
                      },
                    ),

                    _buildCard(
                      index: 4,
                      cardKey: 'scolarite',
                      title: 'Échéancier\n Scolarité',
                      imagePath: 'assets/images/icons/echeancier_scolarite.png',
                      color: AppColors.cardLightGrey,
                      backgroundColor: const Color(0xFFFFFEF7),
                      textColor: const Color(0xFF333333),
                      actionText: '',
                      allowLineBreak: true,
                      enableInnerBorder: false,
                      enableOuterBorder: false,
                      innerBorderColor: const Color.fromARGB(255, 72, 71, 70),
                      imageBorderRadius: AppDimensions.getImageBorderRadius(
                        context,
                      ),
                      width: AppDimensions.getSquareCardWidthSize(context),
                      height: AppDimensions.getSquareCardHeightSize(context),
                      centerTitle: true,
                      onTap: () async {
                        if (_scolariteEntries.isEmpty && !_isLoadingScolarite) {
                          await _loadScolariteData();
                        }
                        if (mounted) {
                          showEnhancedScolariteBottomSheet(
                            context,
                            childName: widget.child.fullName,
                            childMatricule: widget.child.matricule,
                            scolariteEntries: _scolariteEntries,
                            isLoading: _isLoadingScolarite,
                            onRefresh: _loadScolariteData,
                            title: 'Scolarité',
                            description:
                                'Consultez les informations de scolarité',
                            primaryColor: const Color(0xFFF59E0B),
                            backgroundColor: const Color(0xFFFFFEF7),
                            imagePath:
                                'assets/images/icons/echeancier_scolarite.png',
                            imageBorderRadius:
                                AppDimensions.getImageBorderRadius(context),
                            iconColor: const Color(0xFFD97706),
                            iconData: Icons.school_rounded,
                          );
                        }
                      },
                    ),
                    _buildCard(
                      index: 5,
                      cardKey: 'integration_requests',
                      title: 'Demandes\n intégration',
                      imagePath: 'assets/images/icons/demande_integration.png',
                      color: AppColors.cardLightGrey,
                      backgroundColor: const Color(0xFFFCFAFF),
                      textColor: const Color(0xFF333333),
                      actionText: '',
                      enableInnerBorder: false,
                      enableOuterBorder: false,
                      allowLineBreak: true,
                      innerBorderColor: const Color(0xFFC4B5FD),
                      imageBorderRadius: AppDimensions.getImageBorderRadius(
                        context,
                      ),
                      width: AppDimensions.getSquareCardWidthSize(context),
                      height: AppDimensions.getSquareCardHeightSize(context),
                      centerTitle: true,
                      onTap: () => IntegrationRequestBottomSheet.show(
                        context,
                        matricule: widget.child.matricule,
                        childFullName: widget.child.fullName,
                        imagePath:
                            'assets/images/icons/demande_integration.png',
                        imageBorderRadius: AppDimensions.getImageBorderRadius(
                          context,
                        ),
                      ),
                    ),
                  ];

                  List<Widget> rows = [];
                  for (int i = 0; i < cards.length; i += crossAxisCount) {
                    List<Widget> rowChildren = [];
                    for (int j = 0; j < crossAxisCount; j++) {
                      if (i + j < cards.length) {
                        rowChildren.add(
                          Expanded(child: Center(child: cards[i + j])),
                        );
                      } else {
                        rowChildren.add(const Expanded(child: SizedBox()));
                      }
                    }
                    rows.add(
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: rowChildren,
                      ),
                    );
                    if (i + crossAxisCount < cards.length) {
                      rows.add(const SizedBox(height: 10));
                    }
                  }

                  return Column(children: rows);
                },
              ),
            ],
          ),
        ),

        // ════════════════════════════════════════════════════════════════
        // SECTION 2 : Suivi scolaire
        // ════════════════════════════════════════════════════════════════
        SectionRow(title: 'Vie scolaire'),
        EstablishmentActionSection(
          actions: [
            EstablishmentAction(
              key: 'access_control',
              title: 'Contrôle d\'accès',
              subtitle: 'Voir accès',
              imagePath: 'assets/images/icons/controle_acces.png',
              iconData: Icons.fingerprint_rounded,
              color: const Color(0xFFC2185B),
              actionText: 'Voir accès',
              onTap: () {
                _showAccessControlBottomSheet();
                if (!_accessControlLoaded && !_isLoadingAccessControl) {
                  _loadAccessControlData();
                }
              },
            ),
            EstablishmentAction(
              key: 'services_extras',
              title: 'Services scolaires',
              subtitle: 'Suivre',
              imagePath: 'assets/images/icons/services_scolaires.png',
              iconData: Icons.playlist_add_check_rounded,
              color: const Color(0xFF7B1FA2),
              actionText: 'Suivre',
              onTap: () {
                _showExtraScolaireBottomSheet();
              },
            ),
            EstablishmentAction(
              key: 'events',
              title: 'Événements',
              subtitle: 'Voir events',
              imagePath: 'assets/images/icons/evenements_scolaires.png',
              iconData: Icons.event_rounded,
              color: const Color(0xFF3F51B5),
              actionText: 'Voir events',
              onTap: () {
                final schoolCode = _ecoleCode ?? widget.child.ecoleCode;
                if (schoolCode != null && schoolCode.isNotEmpty) {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => SchoolEventBottomSheet(
                      schoolCode: schoolCode,
                      schoolName: widget.child.establishment,
                      imagePath: 'assets/images/icons/evenements_scolaires.png',
                      imageBorderRadius: AppDimensions.getImageBorderRadius(
                        context,
                      ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Code établissement introuvable'),
                    ),
                  );
                }
              },
            ),
          ],
          isDark: isDark,
          useExternalTitle: true,
          cardWidth: AppDimensions.getSquareCardWidthSize(context),
          cardHeight: AppDimensions.getSquareCardHeightSize(context) + 30,
        ),

        // ════════════════════════════════════════════════════════════════
        // SECTION 3 : Vie scolaire
        // ════════════════════════════════════════════════════════════════
        SectionRow(title: 'Suivi scolaire'),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final crossAxisCount = screenWidth > 600 ? 2 : 1;

            Widget buildCard(Map<String, Object?> item) {
              return SchoolLifeItemCard(
                title: item['title'] as String,
                subtitle: item['subtitle'] as String,
                imagePath: item['imagePath'] as String?,
                iconData: item['iconData'] as IconData?,
                isDark: isDark,
                mediaWidth: screenWidth > 600 ? 100 : 70,
                mediaHeight: screenWidth > 600 ? 100 : 70,
                showActionButton: false,
                mediaBorderRadius: screenWidth > 600 ? 14 : 20,
                color: item['color'] as Color,
                buttonText: item['buttonText'] as String,
                onTap: () {
                  if (item['key'] == 'notes') {
                    if (_matricule != null &&
                        _anneeId != null &&
                        _classeId != null) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => NotesScreenJson(
                            matricule: _matricule!,
                            anneeId: _anneeId!.toString(),
                            classeId: _classeId!.toString(),
                            anneeLibelle:
                                'Année scolaire ${DateTime.now().year}-${DateTime.now().year + 1}',
                            ecoleId: _ecoleId?.toString(),
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
                  } else if (item['key'] == 'timetable') {
                    _showTimetableBottomSheet();
                  } else {
                    switch (item['key'] as String) {
                      case 'bulletins':
                        _showBulletinsBottomSheet();
                        break;
                      case 'homework':
                        _showHomeworkBottomSheet();
                        break;
                      case 'attendance':
                        _showAttendanceBottomSheet();
                        break;
                      case 'sanctions':
                        _showSanctionsBottomSheet();
                        break;
                      case 'messages':
                        _showMessagesBottomSheet();
                        break;
                      case 'difficulties':
                        _showDifficultiesBottomSheet();
                        break;
                      case 'homework_program':
                        _showHomeworkProgramBottomSheet();
                        break;
                      case 'progression':
                        _showProgressionBottomSheet();
                        break;
                      case 'supplies':
                        _showSuppliesBottomSheet();
                        break;
                      case 'orders':
                        _showOrdersBottomSheet();
                        break;
                      case 'accessLogs':
                        _showAccessLogsBottomSheet();
                        break;
                      case 'suggestions':
                        _showSuggestionsBottomSheet();
                        break;
                      case 'reservations':
                        _showReservationsBottomSheet();
                        break;
                      default:
                        break;
                    }
                  }
                },
              );
            }

            Widget buildGroupContainer(List<Map<String, Object?>> items) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                margin: const EdgeInsets.only(bottom: 16),
                child: Card(
                  elevation: 0,
                  color: isDark
                      ? const Color(0xFF1E1E1E)
                      : const Color(0xFFF5F7FA),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: crossAxisCount == 1
                        ? Column(
                            children: items.asMap().entries.expand((entry) {
                              final isLast = entry.key == items.length - 1;
                              return [
                                buildCard(entry.value),
                                if (!isLast)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                    child: Divider(
                                      height: 1,
                                      thickness: 1,
                                      color:
                                          (isDark ? Colors.white : Colors.black)
                                              .withOpacity(0.08),
                                    ),
                                  ),
                              ];
                            }).toList(),
                          )
                        : GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 30,
                                  mainAxisSpacing: 16,
                                  childAspectRatio: 3.5,
                                ),
                            itemCount: items.length,
                            itemBuilder: (context, index) =>
                                buildCard(items[index]),
                          ),
                  ),
                ),
              );
            }

            final group1Items = [
              {
                'overtitle': 'ÉVALUATIONS',
                'title': 'Mes Notes',
                'subtitle':
                    'Consultez les moyennes et évaluations de votre enfant.',
                'imagePath': 'assets/images/icons/mes-notes.png',
                'color': const Color(0xFF1976D2),
                'key': 'notes',
              },
              {
                'overtitle': 'BILAN TRIMESTRIEL',
                'title': 'Mes bulletins',
                'subtitle': 'Accédez aux bulletins de l\'année en cours.',
                'imagePath': 'assets/images/icons/bulletin-scolaire.png',
                'color': const Color(0xFF4CAF50),
                'key': 'bulletins',
              },
            ];

            final group3Items = [
              {
                'title': 'Devoirs',
                'subtitle': 'Travail à la maison',
                'imagePath': 'assets/images/icons/devoirs.png',
                'iconData': Icons.edit_note_rounded,
                'color': const Color(0xFF7B1FA2),
                'buttonText': 'Voir devoirs',
                'key': 'homework',
              },
              {
                'title': 'Performance scolaire',
                'subtitle': 'Amélioration de resultats',
                'imagePath': 'assets/images/icons/performance_scolaire.png',
                'iconData': Icons.psychology_rounded,
                'color': const Color(0xFF9C27B0),
                'buttonText': 'Voir difficultés',
                'key': 'difficulties',
              },
              {
                'title': 'Programme de devoirs',
                'subtitle': 'Planning des devoirs',
                'imagePath': null,
                'iconData': Icons.assignment_rounded,
                'color': const Color(0xFF2E7D32),
                'buttonText': 'Voir programme',
                'key': 'homework_program',
              },
              {
                'title': 'Progression',
                'subtitle': 'Suivi de la progression',
                'imagePath': null,
                'iconData': Icons.trending_up_rounded,
                'color': const Color(0xFF1976D2),
                'buttonText': 'Voir progression',
                'key': 'progression',
              },
            ];

            final cardWidth = screenWidth > 600 ? 340.0 : screenWidth * 0.75;
            final cardHeight =
                cardWidth *
                0.55; // Augmentation du ratio pour une carte d'image plus haute
            final containerHeight =
                cardHeight +
                75.0; // Espace supplémentaire pour le texte sous l'image

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: containerHeight,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: group1Items.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 16),
                    itemBuilder: (context, index) {
                      final item = group1Items[index];
                      return ImageMenuCardExternalTitle(
                        index: index,
                        cardKey: item['key'] as String,
                        overtitle: item['overtitle'] as String,
                        title: item['title'] as String,
                        subtitle: item['subtitle'] as String,
                        imagePath: item['imagePath'] as String?,
                        width: cardWidth,
                        height:
                            null, // null permet à Column de prendre la hauteur de l'image + texte
                        imageHeight: cardHeight,
                        imageBorderRadius: 16.0,
                        enableInnerBorder: true,
                        enableOuterBorder: true,
                        innerBorderWidth: 0.5, // Très petit contour
                        outerBorderWidth: 0.5,
                        innerBorderColor: (item['color'] as Color).withOpacity(
                          0.3,
                        ),
                        color: item['color'] as Color,
                        onTap: () {
                          if (item['key'] == 'notes') {
                            if (_matricule != null &&
                                _anneeId != null &&
                                _classeId != null) {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => NotesScreenJson(
                                    matricule: _matricule!,
                                    anneeId: _anneeId!.toString(),
                                    classeId: _classeId!.toString(),
                                    anneeLibelle:
                                        'Année scolaire ${DateTime.now().year}-${DateTime.now().year + 1}',
                                    ecoleId: _ecoleId?.toString(),
                                  ),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Informations élève non disponibles',
                                  ),
                                ),
                              );
                            }
                          } else if (item['key'] == 'bulletins') {
                            _showBulletinsBottomSheet();
                          }
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                EstablishmentActionSection(
                  actions: [
                    EstablishmentAction(
                      key: 'timetable',
                      title: 'Emploi du temps',
                      subtitle: 'Planning des cours',
                      imagePath: 'assets/images/icons/emploi_du_temps.png',
                      iconData: null,
                      color: const Color(0xFFF57C00),
                      actionText: 'Voir emploi',
                      onTap: () {
                        _showTimetableBottomSheet();
                      },
                    ),
                    EstablishmentAction(
                      key: 'attendance',
                      title: 'Présence & Conduite',
                      subtitle: 'Suivi des absences et retards',
                      imagePath: 'assets/images/icons/presence_conduite.png',
                      iconData: null,
                      color: const Color(0xFF00796B),
                      actionText: 'Voir présence',
                      onTap: () {
                        _showAttendanceBottomSheet();
                      },
                    ),
                    EstablishmentAction(
                      key: 'sanctions',
                      title: 'Sanctions',
                      subtitle: 'Rapports de comportement',
                      imagePath: 'assets/images/icons/sanctions.png',
                      iconData: Icons.warning_rounded,
                      color: const Color(0xFFD32F2F),
                      actionText: 'Voir sanctions',
                      onTap: () {
                        _showSanctionsBottomSheet();
                      },
                    ),
                  ],
                  isDark: isDark,
                  useExternalTitle: true,
                  cardWidth: AppDimensions.getSquareCardWidthSize(context),
                  cardHeight:
                      AppDimensions.getSquareCardHeightSize(context) + 30,
                ),
                const SizedBox(height: 16),
                buildGroupContainer(group3Items),
              ],
            );
          },
        ),

        const SizedBox(height: 0),

        // ════════════════════════════════════════════════════════════════
        // SECTION 4 : Communications
        // ════════════════════════════════════════════════════════════════
        const SizedBox(height: 16),
        SectionRow(title: 'Communications'),
        const SizedBox(height: 16),
        EstablishmentActionSection(
          actions: [
            EstablishmentAction(
              key: 'communication',
              title: 'Messages',
              subtitle: 'Voir messages',
              imagePath: 'assets/images/icons/messages.png',
              iconData: Icons.message_rounded,
              color: const Color(0xFF0288D1),
              actionText: 'Voir messages',
              onTap: () async {
                if (_studentMessages.isEmpty && !_isLoadingMessages) {
                  await _loadMessagesData();
                }
                if (mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MessagesScreen(
                        studentArgs: StudentMessageArgs(
                          studentName: widget.child.fullName,
                          studentMatricule:
                              _matricule ?? widget.child.matricule ?? '',
                          ecoleName:
                              _studentClassInfo?.ecole.libelle ??
                              widget.child.establishment,
                          ecoleCode: _ecoleCode ?? widget.child.ecoleCode ?? '',
                        ),
                      ),
                    ),
                  );
                }
              },
            ),
            EstablishmentAction(
              key: 'notifications',
              title: 'Notifications',
              subtitle: 'Voir alertes',
              imagePath: 'assets/images/icons/notifications.png',
              iconData: Icons.notifications_active_rounded,
              color: const Color(0xFFE53935),
              actionText: 'Voir notifications',
              onTap: () {
                if (mounted) {
                  _showNotificationsBottomSheet();
                }
              },
            ),
            EstablishmentAction(
              key: 'voir_les_avis',
              title: 'Suggestions',
              subtitle: 'Voir suggestions',
              iconData: Icons.lightbulb_rounded,
              imagePath: 'assets/images/icons/suggestions.png',
              color: const Color(0xFFFFB300),
              actionText: 'Voir suggestions',
              onTap: () async {
                if (_suggestions.isEmpty && !_isLoadingSuggestions) {
                  await _loadSuggestionsData();
                }
                if (mounted) {
                  _showSuggestionsBottomSheet();
                }
              },
            ),
          ],
          isDark: isDark,
          useExternalTitle: true,
          cardWidth: AppDimensions.getSquareCardWidthSize(context),
          cardHeight: AppDimensions.getSquareCardHeightSize(context) + 30,
        ),
        // ════════════════════════════════════════════════════════════════
        // SECTION 5 : Services
        // ════════════════════════════════════════════════════════════════
        SectionRow(title: 'Services'),
        EstablishmentActionSection(
          actions: [
            EstablishmentAction(
              key: 'niveaux',
              title: 'Fournitures',
              subtitle: 'Voir liste',
              imagePath: 'assets/images/icons/fournitures.png',
              iconData: Icons.inventory_2_rounded,
              color: const Color(0xFF795548),
              actionText: 'Voir liste',
              onTap: () => _showSuppliesBottomSheet(),
            ),
            EstablishmentAction(
              key: 'kits_scolaires',
              title: 'Kits Scolaires',
              subtitle: 'Voir les kits',
              imagePath: 'assets/images/icons/fournitures.png', // Or another icon
              iconData: Icons.backpack_rounded,
              color: const Color(0xFF673AB7), // Violet color matching kits_bottom_sheet
              actionText: 'Voir kits',
              onTap: () {
                if (_ecoleCode == null) return;
                showChildKitsBottomSheet(
                  context,
                  schoolId: _ecoleCode!,
                  niveau: widget.child.grade,
                  childName: widget.child.firstName,
                );
              },
            ),
            EstablishmentAction(
              key: 'consult_requests',
              title: 'Commandes',
              subtitle: 'Voir commandes',
              imagePath: 'assets/images/icons/mes_commandes.png',
              iconData: Icons.shopping_cart_rounded,
              color: const Color(0xFF00ACC1),
              actionText: 'Voir commandes',
              onTap: () => _showOrdersBottomSheet(),
            ),
            EstablishmentAction(
              key: 'tickets',
              title: 'Tickets',
              subtitle: 'Voir tickets',
              imagePath: 'assets/images/icons/tickets.png',
              iconData: Icons.confirmation_number_rounded,
              color: const Color(0xFFE91E63),
              actionText: 'Voir tickets',
              onTap: () {
                MainScreenWrapper.of(
                  context,
                ).navigateToExtraScreen(const MyTicketsScreen());
              },
            ),
            EstablishmentAction(
              key: 'tuteur_adom',
              title: 'Tuteur Adom',
              subtitle: 'Voir tuteur',
              imagePath: 'assets/images/icons/tuteur_adom.png',
              iconData: Icons.person_search_rounded,
              color: const Color(0xFF9C27B0),
              actionText: 'Voir tuteur',
              onTap: () async {
                final Uri url = Uri.parse('http://46.105.52.105:3002/');
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Impossible d\'ouvrir le lien'),
                      ),
                    );
                  }
                }
              },
            ),
          ],
          isDark: isDark,
          useExternalTitle: true,
          cardWidth: AppDimensions.getSquareCardWidthSize(context),
          cardHeight: AppDimensions.getSquareCardHeightSize(context) + 30,
        ),
      ],
    );
  }

  Widget _buildDefaultAvatar() {
    return const Icon(Icons.person, size: 30, color: Colors.white);
  }

  void _showReservationPaiementBottomSheet() {
    final schoolData = _schoolService.getSchoolData();

    // On passe les données immédiates s'il y en a
    final finReservation =
        _apiEcoleData?.finReservation ??
        schoolData?['fin_reservation']?.toString();
    final debutReservation =
        _apiEcoleData?.debutReservation ??
        schoolData?['debut_reservation']?.toString();
    final montantReservation =
        _apiEcoleData?.montantReservation ?? schoolData?['montant_reservation'];

    PaymentBottomSheet.show(
      context: context,
      childName: widget.child.firstName,
      matricule: _matricule,
      imagePath: 'assets/images/icons/reservation_en_ligne.png',
      imageBorderRadius: AppDimensions.getImageBorderRadius(context),
      debutReservation: debutReservation,
      finReservation: finReservation,
      montantReservation: montantReservation,
      loadReservationData: () async {
        // Si les données ne sont pas chargées, on les charge ici pour afficher le loader du bottom sheet
        if (_apiEcoleData == null) {
          if (_ecoleCode == null &&
              _matricule != null &&
              _anneeId != null &&
              _classeId != null) {
            await _loadStudentClassInfo();
          }

          if (_ecoleCode != null) {
            try {
              final ecoleData =
                  await EcoleEleveService.getEcoleParametresForEleve(
                    _ecoleCode!,
                  );
              if (mounted) {
                setState(() {
                  _apiEcoleData = ecoleData;
                });
              }
            } catch (e) {
              print('Erreur lors du chargement des paramètres de l\'école: $e');
            }
          }
        }

        final finalSchoolData = _schoolService.getSchoolData();
        return {
          'debutReservation':
              _apiEcoleData?.debutReservation ??
              finalSchoolData?['debut_reservation']?.toString(),
          'finReservation':
              _apiEcoleData?.finReservation ??
              finalSchoolData?['fin_reservation']?.toString(),
          'montantReservation':
              _apiEcoleData?.montantReservation ??
              finalSchoolData?['montant_reservation'],
        };
      },
      title: 'Réservation en ligne',
      description:
          'Réservez la place de ${widget.child.firstName} pour l\'année prochaine',
      icon: Icons.event_available,
      onPayment: (montant, matricule) async {
        // Créer des fonctions factices pour setState et setLoading
        void dummySetState(VoidCallback fn) {}
        void dummySetLoading() {}
        void dummySetLoadingFalse() {}

        await _effectuerPaiement(
          montant,
          dummySetState,
          dummySetLoading,
          dummySetLoadingFalse,
        );

        return const PaymentResult.online();
      },
    );
  }

  void _showScolaritePaiementBottomSheet() {
    PaymentBottomSheet.show(
      context: context,
      childName: widget.child.firstName,
      matricule: _matricule,
      title: 'Paiement de scolarité',
      description: 'Réglez la scolarité de ${widget.child.firstName}',
      icon: Icons.account_balance_wallet,
      imagePath: 'assets/images/icons/paiement_scolarite.png',
      imageBorderRadius: AppDimensions.getImageBorderRadius(context),
      // On ne passe pas debutReservation ni finReservation pour désactiver la vérification
      onPayment: (montant, matricule) async {
        // Créer des fonctions factices pour setState et setLoading
        void dummySetState(VoidCallback fn) {}
        void dummySetLoading() {}
        void dummySetLoadingFalse() {}

        await _effectuerPaiement(
          montant,
          dummySetState,
          dummySetLoading,
          dummySetLoadingFalse,
        );

        return const PaymentResult.online();
      },
    );
  }

  void _showHistoriquePaiementsBottomSheet() {
    final matricule = widget.child.matricule ?? _matricule;
    final ecoleCode =
        widget.child.ecoleCode ?? widget.child.paramEcole ?? _ecoleCode;

    if (matricule == null || matricule.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Matricule de l\'élève non disponible'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (ecoleCode == null || ecoleCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Code école non disponible'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    PaiementHistoriqueBottomSheet.show(
      context: context,
      childName: widget.child.fullName,
      matricule: matricule,
      ecoleCode: ecoleCode,
      imagePath: 'assets/images/icons/historique_paiement.png',
      imageBorderRadius: AppDimensions.getImageBorderRadius(context),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  Future<void> _effectuerPaiement(
    String montantStr,
    StateSetter setState,
    VoidCallback setLoading,
    VoidCallback setLoadingFalse,
  ) async {
    if (montantStr.isEmpty) {
      CartSnackBar.showOverlay(
        context,
        productName: 'Montant requis',
        message: 'Veuillez entrer un montant',
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      );
      return;
    }

    final montant = int.tryParse(montantStr);
    if (montant == null || montant <= 0) {
      CartSnackBar.showOverlay(
        context,
        productName: 'Montant invalide',
        message: 'Veuillez entrer un montant valide',
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      );
      return;
    }

    if (_matricule == null) {
      CartSnackBar.showOverlay(
        context,
        productName: 'Informations manquantes',
        message: 'Informations élève non disponibles',
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      );
      return;
    }

    // Afficher le loader au-dessus de la bottom sheet
    CustomLoaderOverlay.show(
      context,
      message: 'Traitement du paiement...',
      loaderColor: AppColors.screenOrange,
      showBackground: false,
    );

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

        // Rediriger vers l'URL de paiement
        final launched = await _paiementService.lancerUrlPaiement(
          paiementResponse.url,
        );
        if (launched) {
          // Afficher la modale de vérification (polling)
          final uidToCheck =
              _eleveDetail?['uid']?.toString() ?? _matricule ?? '';
          _showPaymentVerificationLoader(uidToCheck);
        } else {
          CartSnackBar.showOverlay(
            context,
            productName: 'Erreur d\'ouverture',
            message:
                'Impossible d\'ouvrir la page de paiement. Veuillez réessayer.',
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 4),
          );
        }
      } else {
        // Afficher le message d'erreur de l'API
        throw Exception(paiementResponse.message);
      }
    } catch (e) {
      print('❌ Erreur lors du paiement: $e');
      CartSnackBar.showOverlay(
        context,
        productName: 'Erreur de paiement',
        message: 'Erreur lors du paiement: $e',
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      );
    } finally {
      CustomLoaderOverlay.hide();
    }
  }

  void _showPaymentVerificationLoader(String uidEleve) {
    if (uidEleve.isEmpty) return;

    Timer? timer;
    bool isChecking = false;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return PopScope(
          canPop: false,
          child: Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF141414) : Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomLoader(
                    message: 'Attente de la confirmation du paiement...',
                    loaderColor: const Color(0xFFFF7A3C),
                    showBackground: false,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Veuillez finaliser le paiement sur la page sécurisée. L\'application vérifie actuellement le statut de votre transaction.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ).then((_) {
      timer?.cancel(); // Sécurité pour s'assurer que le timer est bien tué
    });

    int attempts = 0;
    const int maxAttempts = 120; // 120 * 2s = 240s (4 minutes)

    // Lancement du polling toutes les 2 secondes
    timer = Timer.periodic(const Duration(seconds: 2), (t) async {
      if (isChecking || !mounted) return;

      attempts++;
      if (attempts >= maxAttempts) {
        t.cancel();
        if (mounted) {
          Navigator.of(context).pop(); // Fermer la modale
          CartSnackBar.showOverlay(
            context,
            productName: 'Délai dépassé',
            message:
                'L\'opération a échoué suite à une longue attente. Veuillez vérifier et réessayer.',
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 4),
          );
        }
        return;
      }

      isChecking = true;

      try {
        final success = await api_service
            .InscriptionApiService.checkPaiementStatus(uidEleve);
        if (success && mounted) {
          t.cancel();
          // Fermer le loader
          Navigator.of(context).pop();
          // Afficher le succès
          CartSnackBar.showOverlay(
            context,
            productName: 'Paiement validé',
            message:
                'Le paiement de la scolarité pour ${widget.child.firstName} a été enregistré avec succès !',
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          );
        }
      } catch (e) {
        // En cas d'erreur de vérification, on laisse tourner
      } finally {
        isChecking = false;
      }
    });
  }

  Widget _buildSummaryCardsGrid() {
    final cards = _buildAvailableSummaryCards();
    if (cards.isEmpty) return const SizedBox.shrink();

    final screenWidth = MediaQuery.sizeOf(context).width;
    final isTablet = screenWidth > 600;
    // Padding: 8*2 (Container) + 4*2 (ListView) = 24
    // Gaps: (cards.length - 1) * 10
    final double cardWidth = isTablet
        ? (screenWidth - 24 - (cards.length - 1) * 10) / cards.length
        : 90.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: SizedBox(
        height: 86,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: isTablet
              ? const NeverScrollableScrollPhysics()
              : const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 4),
          itemCount: cards.length,
          itemBuilder: (context, index) {
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: Duration(milliseconds: 350 + (index * 80)),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) => Transform.translate(
                offset: Offset(0, 8 * (1 - value)),
                child: Opacity(opacity: value, child: child),
              ),
              child: Container(
                width: cardWidth,
                margin: EdgeInsets.only(
                  right: index < cards.length - 1 ? 10.0 : 0.0,
                ),
                child: cards[index],
              ),
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildAvailableSummaryCards() {
    List<Widget> cards = [];

    // Carte Moyenne
    if (_moyGeneral != null) {
      cards.add(
        _buildEnhancedSummaryCard(
          'Moy. Annuelle',
          '${_moyGeneral!.toStringAsFixed(2)}',
          Colors.green,
          Icons.trending_up,
          subtitle: 'Générale',
          isLoading: _isLoadingNotes,
          gradient: _getGradientForColor(Colors.green),
        ),
      );
    }

    // Carte Rang
    if (_globalAverage != null && _globalAverage!.trimesterRank > 0) {
      cards.add(
        _buildEnhancedSummaryCard(
          'Rang',
          '${_globalAverage!.trimesterRank}${_getOrdinalSuffix(_globalAverage!.trimesterRank)}',
          Colors.blue,
          Icons.emoji_events,
          subtitle: 'Classement',
          isLoading: _isLoadingNotes,
          gradient: _getGradientForColor(Colors.blue),
        ),
      );
    }

    // Carte Présence
    if (_eleveDetail != null && _eleveDetail!['pt_in_jour'] != null) {
      final isPresent = _eleveDetail!['pt_in_jour'] == 1;
      cards.add(
        _buildEnhancedSummaryCard(
          'Nbre Absent',
          isPresent ? 'Présent' : 'Absent',
          isPresent ? AppColors.success : AppColors.error,
          isPresent ? Icons.check_circle : Icons.cancel,
          subtitle: "Aujourd'hui",
          gradient: _getGradientForColor(
            isPresent ? AppColors.success : AppColors.error,
          ),
        ),
      );
    }

    // Carte Appréciation
    if (_appreciation != null && _appreciation!.isNotEmpty) {
      cards.add(
        _buildEnhancedSummaryCard(
          'Appréciation',
          _appreciation!,
          AppColors.secondary,
          Icons.star,
          subtitle: 'Générale',
          isLoading: _isLoadingNotes,
          gradient: _getGradientForColor(AppColors.secondary),
          maxLines: 2,
        ),
      );
    }

    // Carte Scolarité
    if (_eleveDetail != null && _eleveDetail!['msolde'] != null) {
      final solde = _eleveDetail!['msolde'] as int;
      cards.add(
        _buildEnhancedSummaryCard(
          'Scolarité',
          '${solde.toString()}F',
          solde > 0 ? Colors.orange : AppColors.success,
          Icons.account_balance_wallet,
          subtitle: solde > 0 ? 'À payer' : 'Réglée',
          gradient: _getGradientForColor(
            solde > 0 ? Colors.orange : AppColors.success,
          ),
        ),
      );
    }

    // Carte Redoublant
    if (_eleveDetail != null && _eleveDetail!['redoublant'] != null) {
      final isRedoublant = _eleveDetail!['redoublant'] == 'OUI';
      cards.add(
        _buildEnhancedSummaryCard(
          'Redoublant',
          isRedoublant ? 'OUI' : 'NON',
          isRedoublant ? Colors.red : AppColors.success,
          Icons.refresh,
          subtitle: 'Statut',
          gradient: _getGradientForColor(
            isRedoublant ? Colors.red : AppColors.success,
          ),
        ),
      );
    }

    return cards;
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
        width: AppDimensions.getSummaryCardWidth(context) + 500,
        height: AppDimensions.getSummaryCardHeight(context),
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
                    width: 24,
                    height: 24,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(icon, color: color, size: 14),
                  ),
                  const Spacer(),
                ],
              ),
              const SizedBox(height: 6),
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
                    fontSize: _textSizeService.getScaledFontSize(14),
                    fontWeight: FontWeight.w800,
                    color: color,
                    letterSpacing: -0.8,
                  ),
                ),
              const SizedBox(height: 2),
              Text(
                title,
                style: TextStyle(
                  fontSize: _textSizeService.getScaledFontSize(9),
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
        children: [_buildDynamicTimetable()],
      ),
    );
  }

  Widget _buildDynamicTimetable() {
    final isDarkMode = _themeService.isDarkMode;

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

    if (_timetableHasError) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppDimensions.getSettingsCardShadow(context),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, size: 48, color: Colors.orange[400]),
            const SizedBox(height: 16),
            Text(
              'Erreur de chargement',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Impossible de récupérer l\'emploi du temps. Veuillez réessayer.',
              style: TextStyle(
                fontSize: 13,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: () => _loadTimetableData(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF57C00),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Réessayer',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
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
    final availableDays = days
        .where(
          (day) =>
              coursesByDay.containsKey(day) && coursesByDay[day]!.isNotEmpty,
        )
        .toList();

    if (availableDays.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.schedule_outlined, size: 48, color: Colors.orange[400]),
            const SizedBox(height: 12),
            Text(
              'Aucun cours programmé',
              style: TextStyle(
                fontSize: 16,
                color: _themeService.isDarkMode
                    ? Colors.white70
                    : Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    if (_selectedTimetableDay == null ||
        !availableDays.contains(_selectedTimetableDay)) {
      _selectedTimetableDay = availableDays.first;
    }

    final selectedCourses = coursesByDay[_selectedTimetableDay] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHorizontalTimeline(availableDays, coursesByDay),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildDynamicDaySchedule(
            _selectedTimetableDay!,
            selectedCourses,
          ),
        ),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildHorizontalTimeline(
    List<String> availableDays,
    Map<String, List<StudentTimetableEntry>> coursesByDay,
  ) {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: availableDays.length,
        itemBuilder: (context, index) {
          final day = availableDays[index];
          final coursesCount = coursesByDay[day]?.length ?? 0;
          final isSelected = _selectedTimetableDay == day;

          return GestureDetector(
            onTap: () {
              if (_timetableModalSetState != null) {
                _timetableModalSetState!(() {
                  _selectedTimetableDay = day;
                });
              }
            },
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(
                        colors: [Color(0xFFFF9800), Color(0xFFF57C00)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isSelected
                    ? null
                    : (_themeService.isDarkMode
                          ? const Color(0xFF1E1E1E)
                          : Colors.white),
                borderRadius: BorderRadius.circular(16),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFFF57C00).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : AppDimensions.getSettingsCardShadow(context),
                border: Border.all(
                  color: isSelected
                      ? Colors.transparent
                      : (_themeService.isDarkMode
                            ? Colors.grey[800]!
                            : Colors.grey[300]!),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 16,
                    color: isSelected
                        ? Colors.white.withOpacity(0.9)
                        : (_themeService.isDarkMode
                              ? Colors.grey[400]
                              : Colors.grey[500]),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    day,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: isSelected
                          ? Colors.white
                          : (_themeService.isDarkMode
                                ? Colors.grey[300]
                                : Colors.grey[700]),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // CORRECTION : suppression du bloc addPostFrameCallback qui redéclenchait
  // inutilement le chargement et empêchait l'affichage au premier rendu.
  Widget _buildSimpleAccessControlTab() {
    final isDarkMode = _themeService.isDarkMode;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildAccessDateSelector(),
          Expanded(child: _buildDynamicAccessControl()),
        ],
      ),
    );
  }

  Widget _buildAccessDateSelector() {
    final isDark = _themeService.isDarkMode;

    // Helper pour obtenir le nom du mois
    String getMonthName(int month) {
      const months = [
        '',
        'Janvier',
        'Février',
        'Mars',
        'Avril',
        'Mai',
        'Juin',
        'Juillet',
        'Août',
        'Septembre',
        'Octobre',
        'Novembre',
        'Décembre',
      ];
      return months[month];
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        children: [
          Expanded(
            child: CustomDateInput(
              label: 'Date de début',
              hint: 'JJ/MM/AAAA',
              icon: Icons.edit_calendar_rounded,
              controller: _accessDateDebutController,
              inputFormatters: [DateInputFormatter()],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: CustomDateInput(
              label: 'Date de fin',
              hint: 'JJ/MM/AAAA',
              icon: Icons.edit_calendar_rounded,
              controller: _accessDateFinController,
              inputFormatters: [DateInputFormatter()],
            ),
          ),
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

      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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

  Widget _buildSimpleSuggestionsTab() {
    final isDarkMode = _themeService.isDarkMode;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [const SizedBox(height: 20), _buildDynamicSuggestions()],
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
        boxShadow: AppDimensions.getSettingsCardShadow(context),
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
        children: [const SizedBox(height: 20), _buildDynamicAccessLogs()],
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
        boxShadow: AppDimensions.getSettingsCardShadow(context),
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

  Widget _buildPresenceStatsSection() {
    final isDarkMode = _themeService.isDarkMode;
    final stats = _presenceStats!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.grey[50],
        border: Border(
          bottom: BorderSide(
            color: isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Résumé mensuel',
            style: TextStyle(
              fontSize: _textSizeService.getScaledFontSize(14),
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white70 : Colors.grey[700],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatCircle(stats.totalPresent, 'Présences', Colors.green),
              _buildStatCircle(stats.totalAbsent, 'Absences', Colors.red),
              _buildStatCircle(
                '${stats.tauxPresence.toStringAsFixed(1)}%',
                'Taux',
                Colors.blue,
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (stats.totalAbsent == '0')
            Row(
              children: [
                Icon(Icons.check_circle, size: 16, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Aucune absence enregistrée ce mois-ci',
                  style: TextStyle(
                    fontSize: _textSizeService.getScaledFontSize(12),
                    color: Colors.green,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildStatCircle(String value, String label, Color color) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
          child: Center(
            child: Text(
              value,
              style: TextStyle(
                fontSize: _textSizeService.getScaledFontSize(18),
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: _textSizeService.getScaledFontSize(12),
            color: _themeService.isDarkMode ? Colors.white70 : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildSimpleReservationsTab() {
    final isDarkMode = _themeService.isDarkMode;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [_buildDynamicReservations()],
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
      return SizedBox(
        height: MediaQuery.of(context).size.height * 0.5,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
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
        boxShadow: AppDimensions.getSettingsCardShadow(context),
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

  // Widget _buildResultItem(String label, String value) {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Text(
  //         label,
  //         style: TextStyle(
  //           fontSize: _textSizeService.getScaledFontSize(12),
  //           fontWeight: FontWeight.w500,
  //           color: AppColors.screenTextSecondary,
  //           letterSpacing: -0.2,
  //         ),
  //       ),
  //       const SizedBox(height: 4),
  //       Text(
  //         value,
  //         style: TextStyle(
  //           fontSize: _textSizeService.getScaledFontSize(14),
  //           fontWeight: FontWeight.w600,
  //           color: AppColors.screenTextPrimary,
  //           letterSpacing: -0.3,
  //         ),
  //       ),
  //     ],
  //   );
  // }

  Widget _buildSimpleMessagesTab() {
    final isDarkMode = _themeService.isDarkMode;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [_buildDynamicMessages()],
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
        boxShadow: AppDimensions.getSettingsCardShadow(context),
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
        boxShadow: AppDimensions.getSettingsCardShadow(context),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: courses
          .map((course) => _buildDynamicCourseItem(course))
          .toList(),
    );
  }

  Widget _buildDynamicCourseItem(StudentTimetableEntry course) {
    final isDarkMode = _themeService.isDarkMode;
    final color = _getSubjectColor(course.matiere);
    final courseKey = '${course.matiere}_${course.formattedTime}';
    final isExpanded = _expandedCourseKey == courseKey;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: isExpanded
            ? color.withOpacity(isDarkMode ? 0.15 : 0.05)
            : (isDarkMode ? const Color(0xFF1E1E1E) : Colors.white),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isExpanded ? color.withOpacity(0.5) : Colors.transparent,
          width: isExpanded ? 1.5 : 1,
        ),
        boxShadow: AppDimensions.getSettingsCardShadow(context),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          onTap: () {
            if (_timetableModalSetState != null) {
              _timetableModalSetState!(() {
                _expandedCourseKey = isExpanded ? null : courseKey;
              });
            }
          },
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Visual color bar
                    Container(
                      width: 4,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Subject and Time
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            course.matiere,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                size: 13,
                                color: isDarkMode
                                    ? Colors.grey[500]
                                    : Colors.grey[500],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                course.formattedTime,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDarkMode
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Dropdown chevron
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 22,
                        color: isDarkMode ? Colors.grey[500] : Colors.grey[400],
                      ),
                    ),
                  ],
                ),
              ),
              // Expanded details area
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                child: isExpanded
                    ? Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Column(
                          children: [
                            Divider(
                              color: isDarkMode
                                  ? Colors.grey[800]
                                  : Colors.grey[200],
                              height: 1,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                // Professor column
                                Expanded(
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: isDarkMode
                                              ? Colors.grey[850]
                                              : Colors.grey[100],
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.person_outline_rounded,
                                          size: 14,
                                          color: color,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Enseignant',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: isDarkMode
                                                    ? Colors.grey[500]
                                                    : Colors.grey[500],
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            const SizedBox(height: 1),
                                            Text(
                                              course.professeur ??
                                                  'Non assigné',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: isDarkMode
                                                    ? Colors.grey[300]
                                                    : Colors.black87,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Classroom column
                                Expanded(
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: isDarkMode
                                              ? Colors.grey[850]
                                              : Colors.grey[100],
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.room_outlined,
                                          size: 14,
                                          color: color,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Salle',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: isDarkMode
                                                    ? Colors.grey[500]
                                                    : Colors.grey[500],
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            const SizedBox(height: 1),
                                            Text(
                                              course.salle ?? 'N/A',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: isDarkMode
                                                    ? Colors.grey[300]
                                                    : Colors.black87,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _loadTimetableData([StateSetter? setModalState]) async {
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

    void updateState(VoidCallback fn) {
      if (_isTimetableSheetOpen && _timetableModalSetState != null) {
        try {
          _timetableModalSetState!(fn);
        } catch (e) {
          print('⚠️ Suppressed setState after dispose for timetable modal: $e');
        }
      }
      if (mounted) {
        setState(fn);
      }
    }

    print('✅ Matricule valide, début du chargement...');
    updateState(() {
      _isLoadingTimetable = true;
      _timetableHasError = false;
    });

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

      updateState(() {
        _timetableResponse = response;
        _isLoadingTimetable = false;
        _timetableHasError = false;
      });
      print('📊 Mise à jour de l\'UI terminée');
    } catch (e) {
      print('❌ Erreur lors du chargement de l\'emploi du temps: $e');
      updateState(() {
        _isLoadingTimetable = false;
        _timetableHasError = true;
      });
    }
  }

  Future<void> _loadAccessControlData([StateSetter? setModalState]) async {
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
    setModalState?.call(() {});
    _accessControlModalSetState?.call(() {});

    try {
      print('📡 Appel du service AccessControlService...');

      // S'assurer que les données de l'école sont chargées
      if (!_schoolService.isSchoolDataLoaded) {
        print('🏫 Chargement des données de l\'école...');
        await _schoolService.loadSchoolData();
        print('✅ Données de l\'école chargées');
      }

      final dateDebutStr =
          '${_selectedAccessDateDebut.year}-${_selectedAccessDateDebut.month.toString().padLeft(2, '0')}-${_selectedAccessDateDebut.day.toString().padLeft(2, '0')}';
      final dateFinStr =
          '${_selectedAccessDateFin.year}-${_selectedAccessDateFin.month.toString().padLeft(2, '0')}-${_selectedAccessDateFin.day.toString().padLeft(2, '0')}';
      final entries = await _accessControlService
          .getAccessControlEntriesForStudent(
            matricule,
            dateDebut: dateDebutStr,
            dateFin: dateFinStr,
          );
      print('✅ Réponse reçue: ${entries.length} pointages');

      if (mounted) {
        setState(() {
          _accessEntries = entries;
          _isLoadingAccessControl = false;
          _accessControlLoaded = true;
        });
        print('📊 Mise à jour de l\'UI terminée');
      }
      setModalState?.call(() {});
      _accessControlModalSetState?.call(() {});
    } catch (e) {
      print('❌ Erreur lors du chargement du contrôle d\'accès: $e');
      if (mounted) {
        setState(() {
          _isLoadingAccessControl = false;
          _accessControlLoaded = true;
        });
      }
      setModalState?.call(() {});
      _accessControlModalSetState?.call(() {});
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

      final currentUser = AuthService.instance.getCurrentUser();
      if (currentUser == null) {
        throw Exception('Aucun utilisateur connecté');
      }

      final messages = await _messageService.getStudentNotifications(
        currentUser.phone,
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
      print('??? Erreur lors du chargement des messages: $e');

      // Vérifier si l'erreur est un 404 (élève non trouvé)
      if (e.toString().contains('404') ||
          e.toString().contains('Élève non trouvé')) {
        // Afficher une notification snackbar pour l'erreur 404
        CartSnackBar.show(
          context,
          productName: 'Élève non trouvé',
          message: 'Vérifiez le matricule de l\'élève',
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        );
      }

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
        // Afficher une notification d'erreur au-dessus de la bottom sheet
        CartSnackBar.showOverlay(
          context,
          productName: 'Erreur de chargement',
          message: 'Impossible de charger les échéances de scolarité',
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        );
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

  Future<void> _loadNotesStatistics() async {
    if (_isLoadingNotes) return;

    final matricule = _matricule ?? widget.child.matricule;
    if (matricule == null || matricule.isEmpty) {
      print(' Matricule non disponible pour les statistiques de notes');
      return;
    }

    if (_anneeId == null || _classeId == null) {
      print(
        ' Informations année/classe non disponibles pour les statistiques de notes',
      );
      return;
    }

    if (mounted) {
      setState(() {
        _isLoadingNotes = true;
      });
    }

    try {
      print(' Chargement des statistiques de notes pour: $matricule');

      // Utiliser la période 1 par défaut
      final periode = '1';

      final apiData = await _notesApiService.getNotesForStudent(
        matricule: matricule,
        anneeId: _anneeId!.toString(),
        classeId: _classeId!.toString(),
        periode: periode,
      );

      if (apiData != null) {
        print(' Données de statistiques de notes reçues');

        // Extraire les données de la réponse API
        final appreciation = apiData['appreciation'] as String?;
        final moyFr = apiData['moyFr'] as double?;
        final moyGeneral = apiData['moyGeneral'] as double?;

        if (mounted) {
          setState(() {
            _appreciation = appreciation;
            _moyFr = moyFr;
            _moyGeneral = moyGeneral;
            _isLoadingNotes = false;
          });
        }

        print(' Statistiques mises à jour:');
        print('   - Appreciation: $appreciation');
        print('   - Moyenne Français: $moyFr');
        print('   - Moyenne Générale: $moyGeneral');
      } else {
        print(' Erreur lors du chargement des statistiques de notes');
        if (mounted) {
          setState(() {
            _isLoadingNotes = false;
          });
        }
      }
    } catch (e) {
      print(' Exception lors du chargement des statistiques de notes: $e');
      if (mounted) {
        setState(() {
          _isLoadingNotes = false;
        });
      }
    }
  }

  Future<void> _loadNotificationsData({bool force = false}) async {
    if (_isLoadingNotifications && !force) return;

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

  Future<void> _loadEcheanceData({bool force = false}) async {
    if (_isLoadingEcheance && !force) return;

    final matricule = _matricule ?? widget.child.matricule;
    if (matricule == null || matricule.isEmpty) {
      print('❌ Matricule non disponible pour charger l\'échéance');
      return;
    }

    if (mounted) {
      setState(() {
        _isLoadingEcheance = true;
      });
    }

    try {
      final echeanceNotification =
          await EcheanceService.getEcheanceNotification(matricule);
      if (mounted) {
        setState(() {
          _echeanceNotification = echeanceNotification;
          _isLoadingEcheance = false;
          _echeanceLoaded = true;
        });
      }
    } catch (e) {
      print('❌ Erreur lors du chargement de l\'échéance: $e');
      if (mounted) {
        setState(() {
          _isLoadingEcheance = false;
          _echeanceLoaded = true;
        });
      }
    }
  }

  Future<void> _refreshNotificationData() async {
    final matricule = _matricule ?? widget.child.matricule;
    if (matricule == null || matricule.isEmpty) {
      print('❌ Matricule non disponible pour actualiser les notifications');
      return;
    }

    if (mounted) {
      setState(() {
        _isLoadingNotifications = true;
        _isLoadingEcheance = true;
        _notificationsLoaded = false;
        _echeanceLoaded = false;
      });
    }

    print('🔄 Actualisation des notifications suite au clic sur le bouton');

    await _loadNotificationsData(force: true);
    await _loadEcheanceData(force: true);
  }

  Color _getSubjectColor(String subject) {
    final s = subject.toLowerCase();
    if (s.contains('math')) return Colors.blue;
    if (s.contains('fran')) return Colors.green;
    if (s.contains('arab') || s.contains('aqidah') || s.contains('fiq'))
      return Colors.brown;
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
    if (s.contains('arab')) return Icons.translate_rounded;
    if (s.contains('aqidah') || s.contains('fiq'))
      return Icons.menu_book_rounded;
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
        children: [_buildNotesList()],
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

  Future<void> _loadBulletins([StateSetter? setModalState]) async {
    if (_isLoadingBulletins) return;

    final matricule = _matricule ?? widget.child.matricule;
    if (matricule == null || matricule.isEmpty) return;
    if (_anneeId == null || _classeId == null) return;

    final effectiveModalSetState = setModalState ?? _bulletinsModalSetState;

    void updateState(VoidCallback fn) {
      print(
        '🔧 DEBUG: updateState appelé - setModalState: ${effectiveModalSetState != null}, mounted: $mounted',
      );
      if (effectiveModalSetState != null) {
        print('🔧 DEBUG: Appel de setModalState');
        effectiveModalSetState(fn);
      }
      if (mounted) {
        print('🔧 DEBUG: Appel de setState');
        setState(fn);
      }
    }

    updateState(() => _isLoadingBulletins = true);

    try {
      final bulletins = await _bulletinApiService.getBulletinsForStudent(
        annee: _anneeId.toString(),
        classe: _classeId.toString(),
        matricule: matricule,
      );
      print('🔧 DEBUG: Mise à jour de l état après réception des données');
      updateState(() {
        _bulletins = bulletins;
        _isLoadingBulletins = false;
      });
      print(
        '🔧 DEBUG: État mis à jour - _isLoadingBulletins: $_isLoadingBulletins, _bulletins: ${_bulletins?.length}',
      );
    } catch (e) {
      updateState(() {
        _bulletins = []; // Set to empty to avoid infinite loop
        _isLoadingBulletins = false;
      });
      print('❌ Erreur lors du chargement des bulletins: $e');
    }
  }

  Future<void> _loadBulletinsSchoolYears([StateSetter? setModalState]) async {
    if (_bulletinsSchoolYears.isNotEmpty) return;

    final ecole = _ecoleId?.toString() ?? '38';

    void updateState(VoidCallback fn) {
      if (setModalState != null) setModalState(fn);
      if (mounted) setState(fn);
    }

    updateState(() => _isLoadingBulletinsYears = true);

    try {
      final years = await _notesApiService.getSchoolYears(ecoleId: ecole);
      updateState(() {
        if (years != null && years.isNotEmpty) {
          _bulletinsSchoolYears = years;
          _bulletinsAvailableYears = years
              .map<String>(
                (y) =>
                    (y['customLibelle'] ?? y['libelle'] ?? 'Année').toString(),
              )
              .toList();
        }
        _isLoadingBulletinsYears = false;
      });
    } catch (e) {
      updateState(() => _isLoadingBulletinsYears = false);
      print('❌ Erreur _loadBulletinsSchoolYears: $e');
    }
  }

  void _onBulletinYearChanged(String label, [StateSetter? setModalState]) {
    final year = _bulletinsSchoolYears.firstWhere(
      (y) => (y['customLibelle'] ?? y['libelle']) == label,
      orElse: () => null,
    );
    if (year != null && _anneeId.toString() != year['id'].toString()) {
      void updateState(VoidCallback fn) {
        if (setModalState != null) setModalState(fn);
        if (mounted) setState(fn);
      }

      updateState(() {
        _anneeId = int.tryParse(year['id'].toString());
        // Collapse the filter automatically when a year is selected
        _isBulletinsFilterExpanded = false;
      });
      _loadBulletins(setModalState);
    }
  }

  Widget _buildBulletinsFiltersSection(StateSetter setModalState) {
    if (_bulletinsSchoolYears.isEmpty && !_isLoadingBulletinsYears)
      return const SizedBox.shrink();

    String currentYearLabel = 'Année scolaire';
    final currentYear = _bulletinsSchoolYears.firstWhere(
      (y) => y['id'].toString() == _anneeId?.toString(),
      orElse: () => null,
    );
    if (currentYear != null) {
      currentYearLabel =
          currentYear['customLibelle'] ??
          currentYear['libelle'] ??
          'Année scolaire';
    }

    return GestureDetector(
      onTap: () {
        setModalState(() {
          _isBulletinsFilterExpanded = !_isBulletinsFilterExpanded;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.screenCardThemed(context),
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppDimensions.getSettingsCardShadow(context),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.screenOrange.withOpacity(0.1),
                    AppColors.screenOrange.withOpacity(0.05),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: _isBulletinsFilterExpanded
                    ? const BorderRadius.vertical(top: Radius.circular(20))
                    : BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.screenOrange,
                          AppColors.screenOrangeDark,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.screenOrange.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      _isBulletinsFilterExpanded
                          ? Icons.filter_list
                          : Icons.tune,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Filtres",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.screenOrange,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _isBulletinsFilterExpanded
                              ? 'Réduire'
                              : 'Étendre pour filtrer par année',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.screenTextSecondaryThemed(context),
                            letterSpacing: 0.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _isBulletinsFilterExpanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.screenOrange.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        color: AppColors.screenOrange,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Expanded Content
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: _isBulletinsFilterExpanded
                  ? Container(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today_rounded,
                                size: 16,
                                color: AppColors.screenTextPrimaryThemed(
                                  context,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Année Scolaire',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.screenTextPrimaryThemed(
                                    context,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (_isLoadingBulletinsYears)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(8.0),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          else
                            SearchableDropdown(
                              label: "Sélectionner l'année",
                              value: currentYearLabel,
                              items: _bulletinsAvailableYears,
                              isDarkMode:
                                  Theme.of(context).brightness ==
                                  Brightness.dark,
                              onChanged: (val) =>
                                  _onBulletinYearChanged(val, setModalState),
                            ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBulletinsTab() {
    // Les bulletins sont maintenant chargés directement dans _showBulletinsBottomSheet()

    // Debug logs pour diagnostiquer le problème
    print('🔍 DEBUG _buildBulletinsTab:');
    print('   _isLoadingBulletins: $_isLoadingBulletins');
    print('   _bulletins: $_bulletins');
    print('   _bulletins?.length: ${_bulletins?.length}');
    print('   _bulletins == null: ${_bulletins == null}');
    print('   _bulletins?.isEmpty: ${_bulletins?.isEmpty}');

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          if (_isLoadingBulletins) ...[
            (() {
              print('🔍 DEBUG: Affichage du loader');
              return _buildBulletinsLoadingState();
            })(),
          ] else if (_bulletins == null || _bulletins!.isEmpty) ...[
            (() {
              print('🔍 DEBUG: Affichage de l\'état vide');
              return _buildBulletinsEmptyState();
            })(),
          ] else ...[
            (() {
              print('🔍 DEBUG: Affichage de la liste des bulletins');
              return _buildBulletinsList();
            })(),
          ],
        ],
      ),
    );
  }

  Widget _buildBulletinsLoadingState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          CustomLoader(
            message: 'Chargement des bulletins...',
            loaderColor: AppColors.screenOrange,
            backgroundColor: Colors.transparent,
            showBackground: false,
          ),
        ],
      ),
    );
  }

  Widget _buildBulletinsEmptyState() {
    final isDarkMode = _themeService.isDarkMode;

    // Check if it's likely a network error based on the empty state with no years loaded
    final isNetworkError = _bulletinsSchoolYears.isEmpty;

    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: isDarkMode
                  ? (isNetworkError
                        ? const Color(0xFF8B0000)
                        : const Color(0xFF8B4513))
                  : (isNetworkError
                        ? Colors.red[100]
                        : AppColors.screenOrangeLight),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isNetworkError
                  ? Icons.wifi_off_rounded
                  : Icons.description_outlined,
              size: 40,
              color: isNetworkError ? Colors.red : AppColors.screenOrange,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isNetworkError
                ? 'Erreur de connexion'
                : 'Aucun bulletin disponible',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isNetworkError
                ? 'Impossible de se connecter au serveur.\nVeuillez vérifier votre connexion internet.'
                : 'Les bulletins ne sont pas encore disponibles pour cette période scolaire.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          SubtleRetryButtonWithText(
            onTap: () {
              setState(() {
                _bulletins = null;
              });
              _loadBulletins();
              _loadBulletinsSchoolYears();
            },
            color: isNetworkError ? Colors.red : AppColors.screenOrange,
          ),
        ],
      ),
    );
  }

  Widget _buildBulletinsList() {
    if (_bulletins == null || _bulletins!.isEmpty) {
      return const SizedBox.shrink();
    }

    // Trier les bulletins par période (du plus récent au plus ancien)
    final sortedBulletins = List<Map<String, dynamic>>.from(
      _bulletins!.map((item) => item as Map<String, dynamic>),
    )..sort((a, b) => (b['periodeId'] as int).compareTo(a['periodeId'] as int));

    return Column(
      children: sortedBulletins.map((bulletin) {
        final periode = bulletin['libellePeriode'] as String? ?? 'Période';
        final annee = bulletin['anneeLibelle'] as String? ?? 'Année scolaire';
        final moyenne = bulletin['moyGeneral'] as double? ?? 0.0;
        final dateCreation = bulletin['dateCreation'] as String? ?? '';

        // Formater la date
        String formattedDate = '';
        if (dateCreation.isNotEmpty) {
          try {
            final dateTime = DateTime.parse(dateCreation);
            formattedDate =
                'Publié le ${dateTime.day} ${_getMonthName(dateTime.month)} ${dateTime.year}';
          } catch (e) {
            formattedDate = 'Publié récemment';
          }
        }

        // Déterminer la couleur en fonction de la moyenne
        Color color = _getBulletinColor(moyenne);

        return Column(
          children: [
            _buildBulletinCard(
              'Bulletin $periode',
              annee,
              'Moyenne générale: ${moyenne.toStringAsFixed(2)}/20',
              formattedDate,
              Icons.description_rounded,
              color,
              bulletin,
            ),
            if (bulletin != sortedBulletins.last) const SizedBox(height: 12),
          ],
        );
      }).toList(),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'janvier',
      'février',
      'mars',
      'avril',
      'mai',
      'juin',
      'juillet',
      'août',
      'septembre',
      'octobre',
      'novembre',
      'décembre',
    ];
    return month >= 1 && month <= 12 ? months[month - 1] : 'mois';
  }

  Color _getBulletinColor(double moyenne) {
    if (moyenne >= 16) return const Color(0xFF10B981); // Vert
    if (moyenne >= 14) return const Color(0xFF3B82F6); // Bleu
    if (moyenne >= 12) return const Color(0xFFF59E0B); // Orange
    return const Color(0xFFEF4444); // Rouge
  }

  Widget _buildBulletinCard(
    String title,
    String subtitle,
    String grade,
    String date,
    IconData icon,
    Color color,
    Map<String, dynamic> bulletinData,
  ) {
    final isDarkMode = _themeService.isDarkMode;
    final bulletinId = bulletinData['id'] as String? ?? '';
    final isExpanded = _expandedBulletinId == bulletinId;

    final nextExpandedId = isExpanded ? null : bulletinId;

    void toggleExpanded() {
      final modalSetState = _bulletinsModalSetState;
      if (modalSetState != null) {
        modalSetState(() {
          _expandedBulletinId = nextExpandedId;
        });
      }
      if (mounted) {
        setState(() {
          _expandedBulletinId = nextExpandedId;
        });
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isExpanded 
            ? Border.all(color: color.withOpacity(0.15), width: 1)
            : null,
        boxShadow: AppDimensions.getSettingsCardShadow(context),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: toggleExpanded,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 16,
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
                                color: isDarkMode
                                    ? Colors.white
                                    : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              subtitle,
                              style: TextStyle(
                                fontSize: 14,
                                color: isDarkMode
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
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
                                Expanded(
                                  child: Text(
                                    date,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDarkMode
                                          ? Colors.grey[400]
                                          : Colors.grey[500],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  isExpanded
                                      ? Icons.keyboard_arrow_up_rounded
                                      : Icons.keyboard_arrow_down_rounded,
                                  size: 20,
                                  color: isDarkMode
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Expanded section with action buttons
            if (isExpanded)
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Divider(height: 1),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildActionButton(
                              'Consulter',
                              Icons.visibility_outlined,
                              const Color(0xFFFF7A3C),
                              () => _viewBulletin(bulletinData),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildActionButton(
                              'Télécharger',
                              Icons.download_outlined,
                              const Color(0xFF10B981),
                              () => _downloadBulletin(bulletinData),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildActionButton(
                              'Partager',
                              Icons.share_outlined,
                              const Color(0xFF3B82F6),
                              () => _shareBulletin(bulletinData),
                            ),
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
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withOpacity(0.15), width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 15),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── BULLETIN ACTIONS ───────────────────────────────────────────────────────

  Future<void> _viewBulletin(Map<String, dynamic> bulletinData) async {
    try {
      final pdfUrl = _buildBulletinPdfUrl(bulletinData);
      final periode = bulletinData['libellePeriode'] as String? ?? 'Bulletin';

      print('🌐 Ouverture du PDF: $pdfUrl');

      // Navigate to PDF viewer screen
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) =>
              PDFViewerScreen(pdfUrl: pdfUrl, title: 'Bulletin $periode'),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'ouverture du bulletin: $e'),
          ),
        );
      }
    }
  }

  Future<void> _downloadBulletin(Map<String, dynamic> bulletinData) async {
    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Téléchargement en cours...')),
        );
      }

      final pdfUrl = _buildBulletinPdfUrl(bulletinData);
      final periode = bulletinData['libellePeriode'] as String? ?? 'Bulletin';
      final annee = bulletinData['anneeLibelle'] as String? ?? 'Annee';
      final nom = bulletinData['nom'] as String? ?? '';
      final prenoms = bulletinData['prenoms'] as String? ?? '';

      // Download PDF
      final uri = Uri.parse(pdfUrl);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        // Get directory for saving depending on platform
        Directory? directory;
        try {
          if (Platform.isAndroid) {
            directory =
                await getExternalStorageDirectory() ??
                await getApplicationDocumentsDirectory();
          } else {
            directory = await getApplicationDocumentsDirectory();
          }
        } catch (e) {
          directory = await getApplicationDocumentsDirectory();
        }

        final documentsPath = directory.path;
        final cleanNom = nom.trim().replaceAll(' ', '_');
        final cleanPrenoms = prenoms.trim().replaceAll(' ', '_');
        final cleanPeriode = periode.trim().replaceAll(' ', '_');
        final cleanAnnee = annee.trim().replaceAll('/', '-');

        final fileName =
            'Bulletin_${cleanPeriode}_${cleanPrenoms}_${cleanNom}_$cleanAnnee.pdf';
        final filePath = '$documentsPath/$fileName';

        // Save file locally
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        if (mounted) {
          // On iOS, open native share/save sheet to allow user to "Save to Files" (Enregistrer dans Fichiers)
          if (Platform.isIOS) {
            await Share.shareXFiles([
              XFile(filePath),
            ], subject: 'Bulletin $periode - $prenoms $nom');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Option de sauvegarde affichée avec succès'),
              ),
            );
          } else {
            // On Android, save to storage and offer a share/open callback
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Bulletin enregistré avec succès :\n$fileName'),
                duration: const Duration(seconds: 4),
                action: SnackBarAction(
                  label: 'Partager le fichier',
                  onPressed: () async {
                    await Share.shareXFiles([
                      XFile(filePath),
                    ], subject: 'Bulletin $periode - $prenoms $nom');
                  },
                ),
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Erreur lors du téléchargement: ${response.statusCode}',
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du téléchargement: $e')),
        );
      }
    }
  }

  Future<void> _shareBulletin(Map<String, dynamic> bulletinData) async {
    try {
      final pdfUrl = _buildBulletinPdfUrl(bulletinData);
      final periode = bulletinData['libellePeriode'] as String? ?? 'Bulletin';
      final annee = bulletinData['anneeLibelle'] as String? ?? 'Année';
      final nom = bulletinData['nom'] as String? ?? '';
      final prenoms = bulletinData['prenoms'] as String? ?? '';

      // Share PDF URL
      final shareText = 'Bulletin $periode de $prenoms $nom - $annee\n$pdfUrl';

      await Share.share(
        shareText,
        subject: 'Bulletin $periode - $prenoms $nom',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur lors du partage: $e')));
      }
    }
  }

  String _buildBulletinPdfUrl(Map<String, dynamic> bulletinData) {
    final ecoleId = _ecoleId?.toString() ?? '';
    final periode = bulletinData['libellePeriode'] as String? ?? '';
    final anneeLibelle = bulletinData['anneeLibelle'] as String? ?? '';
    final classeId = bulletinData['classeId']?.toString() ?? '';
    final matricule = bulletinData['matricule'] as String? ?? '';

    // Encode URL components
    final encodedPeriode = Uri.encodeComponent(periode);
    final encodedAnneeLibelle = Uri.encodeComponent(anneeLibelle);

    return '${AppConfig.POULS_SCOLAIRE_API_URL}/imprimer-bulletin-list/spider-bulletin-matricule/$ecoleId/$encodedPeriode/$encodedAnneeLibelle/$classeId/$matricule/false/2/false/true/true/false/false/true/false/false/false/false';
  }

  Widget _buildDifficultiesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [_buildDifficultiesList()],
      ),
    );
  }

  Widget _buildComingSoonContent() {
    final isDarkMode = _themeService.isDarkMode;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1565C0).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.hourglass_empty_rounded,
              size: 48,
              color: Color(0xFF1565C0),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Contenu bientôt disponible',
            style: TextStyle(
              fontSize: _textSizeService.getScaledFontSize(18),
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : const Color(0xFF1F2937),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Cette fonctionnalité est en cours de développement et sera disponible très prochainement.',
            style: TextStyle(
              fontSize: _textSizeService.getScaledFontSize(14),
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultiesList() {
    return _buildComingSoonContent();
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
        children: [_buildEventsList()],
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
                    // fontWeight: FontWeight.w600,
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
    return Padding(
      padding: const EdgeInsets.all(16),
      child: _buildSuppliesList(),
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
      return Expanded(
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
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
          ),
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

  Widget _buildOrdersStatVerticalDivider(bool isDark) {
    return Container(
      width: 1,
      height: 36,
      color: AppColors.screenDividerThemed(context).withOpacity(0.5),
    );
  }

  Widget _buildOrdersStatItem(
    String title,
    String value,
    bool isDark,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.screenTextPrimaryThemed(context),
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.screenTextSecondaryThemed(context),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersStatsHeader(List<Order> rawOrders) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Calculate stats
    final int totalCount = rawOrders.length;
    final double totalSum = rawOrders.fold<double>(
      0.0,
      (sum, order) => sum + order.totalAmount,
    );
    final int pendingCount = rawOrders
        .where((order) => order.status == OrderStatus.pending)
        .length;
    final int validatedCount = rawOrders
        .where(
          (order) =>
              order.status == OrderStatus.confirmed ||
              order.status == OrderStatus.processing ||
              order.status == OrderStatus.shipped ||
              order.status == OrderStatus.delivered,
        )
        .length;

    String sumStr = "";
    if (totalSum >= 1000) {
      final double kValue = totalSum / 1000;
      sumStr = "${kValue.toStringAsFixed(kValue % 1 == 0 ? 0 : 1)}k";
    } else {
      sumStr = totalSum.toStringAsFixed(0);
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.screenCardThemed(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.screenDividerThemed(context).withOpacity(0.5),
          width: 1,
        ),
        boxShadow: AppDimensions.getBottomSheetShadow(context),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildOrdersStatItem(
            'Total',
            totalCount.toString(),
            isDark,
            Icons.shopping_bag_outlined,
            AppColors.shopBlue,
          ),
          _buildOrdersStatVerticalDivider(isDark),
          _buildOrdersStatItem(
            'Somme',
            '$sumStr F',
            isDark,
            Icons.monetization_on_outlined,
            AppColors.shopGreen,
          ),
          _buildOrdersStatVerticalDivider(isDark),
          _buildOrdersStatItem(
            'En attente',
            pendingCount.toString(),
            isDark,
            Icons.hourglass_empty_rounded,
            Colors.orange[700]!,
          ),
          _buildOrdersStatVerticalDivider(isDark),
          _buildOrdersStatItem(
            'Validées',
            validatedCount.toString(),
            isDark,
            Icons.check_circle_outline_rounded,
            Colors.green[600]!,
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersTab(StateSetter setModalState) {
    return FutureBuilder<List<Order>>(
      future: _ordersFuture ??= _loadOrdersFuture(),
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

        final rawOrders = snapshot.data ?? [];

        final filteredByStatus = rawOrders.where((order) {
          if (_ordersStatusFilter == 'Tous') return true;
          if (_ordersStatusFilter == 'En attente') {
            return order.status == OrderStatus.pending;
          }
          if (_ordersStatusFilter == 'En cours') {
            return order.status == OrderStatus.confirmed ||
                order.status == OrderStatus.processing ||
                order.status == OrderStatus.shipped;
          }
          if (_ordersStatusFilter == 'Livrées') {
            return order.status == OrderStatus.delivered;
          }
          if (_ordersStatusFilter == 'Annulées') {
            return order.status == OrderStatus.cancelled ||
                order.status == OrderStatus.refunded;
          }
          return true;
        }).toList();

        final orders = filteredByStatus.where((order) {
          if (_ordersSearchController.text.isEmpty) return true;
          final q = _ordersSearchController.text.toLowerCase();
          return order.id.toLowerCase().contains(q);
        }).toList();

        Widget content;

        if (orders.isEmpty) {
          content = Container(
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
        } else {
          content = Column(
            children: orders.map((order) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildOrderCardFromOrder(order),
              );
            }).toList(),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilterRowWidget(
                filters: const [
                  'Tous',
                  'En attente',
                  'En cours',
                  'Livrées',
                  'Annulées',
                ],
                selectedFilter: _ordersStatusFilter,
                onFilterSelected: (String filter) {
                  setModalState(() {
                    _ordersStatusFilter = filter;
                  });
                },
              ),
              _buildOrdersStatsHeader(rawOrders),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: SearchBarWidget(
                  isSearching: true,
                  searchController: _ordersSearchController,
                  onChanged: (val) {
                    setModalState(() {});
                  },
                  onClear: () {
                    setModalState(() {
                      _ordersSearchController.clear();
                    });
                  },
                  hintText: 'Rechercher une commande...',
                ),
              ),
              Padding(padding: const EdgeInsets.all(16), child: content),
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
      print(
        '⚠️ Impossible de charger les commandes: téléphone utilisateur manquant',
      );
      return [];
    }

    try {
      print(
        '📦 Chargement des commandes pour le téléphone: ${currentUser!.phone}',
      );
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
    final isExpanded = _expandedOrderId == order.id;

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

    // Formatter la date
    final months = [
      'janvier',
      'février',
      'mars',
      'avril',
      'mai',
      'juin',
      'juillet',
      'août',
      'septembre',
      'octobre',
      'novembre',
      'décembre',
    ];
    final formattedDate =
        '${order.createdAt.day} ${months[order.createdAt.month - 1]} ${order.createdAt.year}';

    // Formatter le montant en FCFA
    final formattedAmount = '${order.totalAmount.toStringAsFixed(2)} FCFA';

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isExpanded ? statusColor.withOpacity(0.4) : Colors.transparent,
          width: isExpanded ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withOpacity(0.2)
                : statusColor.withOpacity(0.04),
            blurRadius: isExpanded ? 12 : 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          onTap: () {
            if (_ordersModalSetState != null) {
              _ordersModalSetState!(() {
                _expandedOrderId = isExpanded ? null : order.id;
              });
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(statusIcon, color: statusColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Commande #${order.id.length > 8 ? order.id.substring(0, 8) : order.id}',
                            style: TextStyle(
                              fontSize: _textSizeService.getScaledFontSize(15),
                              fontWeight: FontWeight.w700,
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$formattedDate • ${order.items.length} article${order.items.length > 1 ? "s" : ""}',
                            style: TextStyle(
                              fontSize: _textSizeService.getScaledFontSize(12),
                              color: isDarkMode
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          formattedAmount,
                          style: TextStyle(
                            fontSize: _textSizeService.getScaledFontSize(14),
                            fontWeight: FontWeight.w800,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            order.status.displayName,
                            style: TextStyle(
                              fontSize: _textSizeService.getScaledFontSize(10),
                              fontWeight: FontWeight.w700,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 20,
                        color: isDarkMode ? Colors.grey[500] : Colors.grey[400],
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                child: isExpanded
                    ? Container(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Divider(
                              color: isDarkMode
                                  ? Colors.grey[800]
                                  : Colors.grey[200],
                              height: 1,
                            ),
                            const SizedBox(height: 12),

                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDarkMode
                                    ? Colors.grey[850]
                                    : Colors.grey[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDarkMode
                                      ? Colors.grey[800]!
                                      : Colors.grey[200]!,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Détails des articles',
                                    style: TextStyle(
                                      fontSize: _textSizeService
                                          .getScaledFontSize(12),
                                      fontWeight: FontWeight.w700,
                                      color: isDarkMode
                                          ? Colors.grey[300]
                                          : Colors.grey[700],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ...order.items
                                      .map(
                                        (item) => Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 10,
                                          ),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Container(
                                                margin: const EdgeInsets.only(
                                                  top: 5,
                                                ),
                                                width: 5,
                                                height: 5,
                                                decoration: BoxDecoration(
                                                  color: statusColor,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      item.product.title ??
                                                          'Produit sans nom',
                                                      style: TextStyle(
                                                        fontSize: _textSizeService
                                                            .getScaledFontSize(
                                                              13,
                                                            ),
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: isDarkMode
                                                            ? Colors.white
                                                            : Colors.black87,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      'Quantité: ${item.quantity} • ${item.product.price.toStringAsFixed(2)} FCFA',
                                                      style: TextStyle(
                                                        fontSize: _textSizeService
                                                            .getScaledFontSize(
                                                              11,
                                                            ),
                                                        color: isDarkMode
                                                            ? Colors.grey[400]
                                                            : Colors.grey[600],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                      .toList(),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Sous-total :',
                                  style: TextStyle(
                                    fontSize: _textSizeService
                                        .getScaledFontSize(12),
                                    color: isDarkMode
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                                  ),
                                ),
                                Text(
                                  '${(order.totalAmount - (order.metadata?["frais_livraison"] as num? ?? 0)).toStringAsFixed(2)} FCFA',
                                  style: TextStyle(
                                    fontSize: _textSizeService
                                        .getScaledFontSize(12),
                                    fontWeight: FontWeight.w500,
                                    color: isDarkMode
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            if (order.metadata?["frais_livraison"] != null) ...[
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Frais de livraison :',
                                    style: TextStyle(
                                      fontSize: _textSizeService
                                          .getScaledFontSize(12),
                                      color: isDarkMode
                                          ? Colors.grey[400]
                                          : Colors.grey[600],
                                    ),
                                  ),
                                  Text(
                                    '+${(order.metadata!["frais_livraison"] as num).toStringAsFixed(2)} FCFA',
                                    style: TextStyle(
                                      fontSize: _textSizeService
                                          .getScaledFontSize(12),
                                      fontWeight: FontWeight.w500,
                                      color: isDarkMode
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 8),
                            Divider(
                              color: isDarkMode
                                  ? Colors.grey[800]
                                  : Colors.grey[200],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total Général :',
                                  style: TextStyle(
                                    fontSize: _textSizeService
                                        .getScaledFontSize(13),
                                    fontWeight: FontWeight.w700,
                                    color: isDarkMode
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                ),
                                Text(
                                  formattedAmount,
                                  style: TextStyle(
                                    fontSize: _textSizeService
                                        .getScaledFontSize(15),
                                    fontWeight: FontWeight.w800,
                                    color: statusColor,
                                  ),
                                ),
                              ],
                            ),
                            if (order.status == OrderStatus.pending) ...[
                              const SizedBox(height: 16),
                              _OrderCardCancelButton(
                                order: order,
                                onCancelled: () {
                                  if (mounted) {
                                    setState(() {
                                      _ordersFuture = _loadOrdersFuture();
                                    });
                                  }
                                  if (_ordersModalSetState != null) {
                                    _ordersModalSetState!(() {});
                                  }
                                },
                              ),
                            ],
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
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
        boxShadow: AppDimensions.getSettingsCardShadow(context),
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
        children: [_buildHomeworkContent()],
      ),
    );
  }

  Widget _buildHomeworkContent() {
    return _buildComingSoonContent();
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildPresenceFilters(),
          const SizedBox(height: 12),
          _buildAttendanceSummary(),
          const SizedBox(height: 20),
          _buildAbsencesList(),
        ],
      ),
    );
  }

  Widget _buildPresenceActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      child: Row(
        children: [
          if (_filterStartDateController.text.isNotEmpty ||
              _filterEndDateController.text.isNotEmpty ||
              _filterType != null) ...[
            Expanded(
              flex: 1,
              child: ElevatedButton.icon(
                onPressed: () {
                  final effectiveModalSetState = _presenceModalSetState;
                  if (effectiveModalSetState != null && mounted) {
                    effectiveModalSetState(() {
                      _filterStartDateController.clear();
                      _filterEndDateController.clear();
                      _filterStartDate = null;
                      _filterEndDate = null;
                      _filterType = null;
                    });
                  }
                  if (mounted) {
                    setState(() {
                      _filterStartDateController.clear();
                      _filterEndDateController.clear();
                      _filterStartDate = null;
                      _filterEndDate = null;
                      _filterType = null;
                    });
                  }
                },
                icon: const Icon(Icons.clear_rounded, size: 20),
                label: const Text('Effacer', style: TextStyle(fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: () => _loadPresenceData(),
              icon: _isLoadingPresence
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.search_rounded, size: 20),
              label: Text(
                _isLoadingPresence ? 'Recherche...' : 'Rechercher',
                style: const TextStyle(fontSize: 13),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 2,
                shadowColor: const Color(0xFF1565C0).withOpacity(0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceSummary() {
    // Charger les statistiques si pas encore chargées
    if (!_hasLoadedStatistiques && !_isLoadingStatistiques) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_hasLoadedStatistiques && !_isLoadingStatistiques) {
          _loadStatistiquesPresence(_presenceStatsModalSetState);
        }
      });
    }

    final isDarkMode = _themeService.isDarkMode;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E2A) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: _isLoadingStatistiques
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Statistiques de présence',
                  style: TextStyle(
                    fontSize: _textSizeService.getScaledFontSize(16),
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : const Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 24),
                const Center(
                  child: CustomLoader(
                    message: 'Chargement des statistiques...',
                    loaderColor: Color(0xFF1565C0),
                    size: 40.0,
                    showBackground: false,
                  ),
                ),
              ],
            )
          : _statistiquesPresence != null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Statistiques de présence',
                      style: TextStyle(
                        fontSize: _textSizeService.getScaledFontSize(15),
                        fontWeight: FontWeight.bold,
                        color: isDarkMode
                            ? Colors.white
                            : const Color(0xFF1F2937),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color:
                            (_statistiquesPresence!.tauxPresence >= 95
                                    ? const Color(0xFF10B981)
                                    : _statistiquesPresence!.tauxPresence >= 90
                                    ? const Color(0xFFF59E0B)
                                    : const Color(0xFFEF4444))
                                .withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_statistiquesPresence!.tauxPresence.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: _textSizeService.getScaledFontSize(13),
                          fontWeight: FontWeight.bold,
                          color: _statistiquesPresence!.tauxPresence >= 95
                              ? const Color(0xFF10B981)
                              : _statistiquesPresence!.tauxPresence >= 90
                              ? const Color(0xFFF59E0B)
                              : const Color(0xFFEF4444),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMinimalStatItem(
                      'Présences',
                      _statistiquesPresence!.totalPresent,
                      Icons.check_circle_rounded,
                      const Color(0xFF10B981),
                      isDarkMode,
                    ),
                    Container(
                      width: 1,
                      height: 30,
                      color: isDarkMode ? Colors.grey[800] : Colors.grey[300],
                    ),
                    _buildMinimalStatItem(
                      'Absences',
                      _statistiquesPresence!.totalAbsent,
                      Icons.cancel_rounded,
                      const Color(0xFFEF4444),
                      isDarkMode,
                    ),
                    Container(
                      width: 1,
                      height: 30,
                      color: isDarkMode ? Colors.grey[800] : Colors.grey[300],
                    ),
                    _buildMinimalStatItem(
                      'Total',
                      _statistiquesPresence!.totalSeances.toString(),
                      Icons.calendar_today_rounded,
                      const Color(0xFF3B82F6),
                      isDarkMode,
                    ),
                  ],
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Statistiques de présence',
                  style: TextStyle(
                    fontSize: _textSizeService.getScaledFontSize(16),
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : const Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Impossible de charger les statistiques',
                        style: TextStyle(
                          fontSize: _textSizeService.getScaledFontSize(14),
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () => _loadStatistiquesPresence(
                          _presenceStatsModalSetState,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1565C0),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildMinimalStatItem(
    String title,
    String value,
    IconData icon,
    Color color,
    bool isDarkMode,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: _textSizeService.getScaledFontSize(11),
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: _textSizeService.getScaledFontSize(16),
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : const Color(0xFF1F2937),
          ),
        ),
      ],
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

  List<GestionPresenceEleveEntry> _presenceEntries = [];
  List<GestionPresenceEleveEntry> _filteredPresenceEntries = [];
  bool _isLoadingPresence = false;
  bool _hasLoadedPresence = false;
  StateSetter? _presenceModalSetState;
  StatistiquesPresence? _statistiquesPresence;
  bool _isLoadingStatistiques = false;
  bool _hasLoadedStatistiques = false;
  StateSetter? _presenceStatsModalSetState;

  // Filtres pour la liste des absences
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;
  final TextEditingController _filterStartDateController =
      TextEditingController();
  final TextEditingController _filterEndDateController =
      TextEditingController();
  int? _filterType; // null = tous, 0 = absent, 1 = présent
  bool _isFilterExpanded = false;

  DateTime? _parseDateString(String text) {
    if (text.length == 10) {
      try {
        final parts = text.split('/');
        return DateTime(
          int.parse(parts[2]),
          int.parse(parts[1]),
          int.parse(parts[0]),
        );
      } catch (_) {}
    }
    return null;
  }

  Widget _buildAbsencesList() {
    // Appliquer les filtres
    _applyPresenceFilters();
    final isDarkMode = _themeService.isDarkMode;

    return Column(
      children: [
        // Liste des entrées de présence
        if (_filteredPresenceEntries.isNotEmpty) ...[
          const SizedBox(height: 8),
          ...List.generate(_filteredPresenceEntries.length, (index) {
            final entry = _filteredPresenceEntries[index];
            final isPresent = (entry.presence ?? 0) == 1;
            final debutDate = _tryParseApiDate(entry.debut);
            final timeStr = debutDate != null
                ? '${debutDate.day.toString().padLeft(2, '0')}/${debutDate.month.toString().padLeft(2, '0')} à ${debutDate.hour.toString().padLeft(2, '0')}:${debutDate.minute.toString().padLeft(2, '0')}'
                : entry.debut ?? '';

            final statusColor = isPresent
                ? const Color(0xFF10B981)
                : const Color(0xFFEF4444);
            final statusBgColor = isPresent
                ? (isDarkMode
                      ? const Color(0xFF0F3720)
                      : const Color(0xFFD1FAE5))
                : (isDarkMode
                      ? const Color(0xFF3C1818)
                      : const Color(0xFFFEE2E2));
            final itemBgColor = isDarkMode
                ? const Color(0xFF1E1E2A)
                : Colors.white;

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: itemBgColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppDimensions.getSettingsCardShadow(context),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Badge Status
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusBgColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isPresent ? 'Présent' : 'Absent',
                          style: TextStyle(
                            fontSize: _textSizeService.getScaledFontSize(11),
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ),
                      // Subject Name
                      Expanded(
                        child: Text(
                          entry.matiere ?? 'Matière inconnue',
                          style: TextStyle(
                            fontSize: _textSizeService.getScaledFontSize(14),
                            fontWeight: FontWeight.bold,
                            color: isDarkMode
                                ? Colors.white
                                : const Color(0xFF1F2937),
                          ),
                          textAlign: TextAlign.end,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      // Time
                      Icon(
                        Icons.access_time_rounded,
                        size: 14,
                        color: isDarkMode ? Colors.white38 : Colors.grey[500],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        timeStr,
                        style: TextStyle(
                          fontSize: _textSizeService.getScaledFontSize(12),
                          color: isDarkMode ? Colors.white70 : Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      // Professor name
                      if (entry.nomProf != null &&
                          entry.prenomProf != null) ...[
                        Icon(
                          Icons.person_outline_rounded,
                          size: 14,
                          color: isDarkMode ? Colors.white38 : Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${entry.prenomProf} ${entry.nomProf}',
                          style: TextStyle(
                            fontSize: _textSizeService.getScaledFontSize(12),
                            color: isDarkMode
                                ? Colors.white70
                                : Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            );
          }),
        ],

        // Message si aucune donnée
        if (!_isLoadingPresence && _presenceEntries.isEmpty)
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF1E1E2A) : Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 12),
                Text(
                  'Aucune donnée de présence disponible',
                  style: TextStyle(
                    fontSize: _textSizeService.getScaledFontSize(14),
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.white70 : Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          
        const BottomSpacer(),
      ],
    );
  }

  DateTime? _tryParseApiDate(String? value) {
    if (value == null || value.isEmpty) return null;
    return DateTime.tryParse(value.replaceFirst(' ', 'T'));
  }

  Future<void> _loadPresenceData([StateSetter? setModalState]) async {
    if (_matricule == null || _ecoleCode == null) {
      print('⚠️ Informations manquantes pour charger les données de présence');
      return;
    }

    final effectiveModalSetState = setModalState ?? _presenceModalSetState;

    void updateState(VoidCallback fn) {
      if (effectiveModalSetState != null) {
        effectiveModalSetState(fn);
      }
      if (mounted) {
        setState(fn);
      }
    }

    updateState(() => _isLoadingPresence = true);

    try {
      String? dateParam;
      if (_filterStartDate != null) {
        dateParam =
            '${_filterStartDate!.year}-${_filterStartDate!.month.toString().padLeft(2, '0')}-${_filterStartDate!.day.toString().padLeft(2, '0')}';
      }
      String? dateEndParam;
      if (_filterEndDate != null) {
        dateEndParam =
            '${_filterEndDate!.year}-${_filterEndDate!.month.toString().padLeft(2, '0')}-${_filterEndDate!.day.toString().padLeft(2, '0')}';
      }
      String? typeParam;
      if (_filterType != null) {
        typeParam = _filterType.toString();
      }

      print(
        '📡 Chargement présence/absence: matricule=$_matricule, ecole=$_ecoleCode, dateDebut=$dateParam, dateFin=$dateEndParam, type=$typeParam',
      );
      final entries = await GestionPresenceEleveService.getGestionPresenceEleve(
        _matricule!,
        _ecoleCode!,
        dateDebut: dateParam,
        dateFin: dateEndParam,
        type: typeParam,
      );

      updateState(() {
        _presenceEntries = entries;
        _isLoadingPresence = false;
        _hasLoadedPresence = true;
      });

      print('✅ ${entries.length} entrée(s) de présence/absence chargée(s)');
    } catch (e) {
      print('❌ Erreur lors du chargement des données de présence: $e');
      updateState(() {
        _isLoadingPresence = false;
        _hasLoadedPresence = true;
      });
    }
  }

  Future<void> _loadStatistiquesPresence([StateSetter? setModalState]) async {
    if (_matricule == null || _ecoleCode == null) {
      print(
        '⚠️ Informations manquantes pour charger les statistiques de présence',
      );
      return;
    }

    final effectiveModalSetState = setModalState ?? _presenceModalSetState;

    void updateState(VoidCallback fn) {
      if (effectiveModalSetState != null) {
        effectiveModalSetState(fn);
      }
      if (mounted) {
        setState(fn);
      }
    }

    updateState(() => _isLoadingStatistiques = true);

    try {
      final statistiques =
          await StatistiquesPresenceService.getStatistiquesPresence(
            _matricule!,
            _ecoleCode!,
          );

      updateState(() {
        _statistiquesPresence = statistiques;
        _isLoadingStatistiques = false;
        _hasLoadedStatistiques = true;
      });

      if (statistiques != null) {
        print(
          '✅ Statistiques présence: ${statistiques!.tauxPresence}% présence, ${statistiques!.totalAbsent} absences',
        );
      }
    } catch (e) {
      print('❌ Erreur lors du chargement des statistiques de présence: $e');
      if (mounted) {
        updateState(() {
          _isLoadingStatistiques = false;
          _hasLoadedStatistiques = true;
        });
      }
    }
  }

  void _applyPresenceFilters() {
    _filterStartDate = _parseDateString(_filterStartDateController.text);
    _filterEndDate = _parseDateString(_filterEndDateController.text);

    _filteredPresenceEntries = _presenceEntries.where((entry) {
      // Filtre par type
      if (_filterType != null) {
        final isPresent = (entry.presence ?? 0) == 1;
        if (_filterType == 0 && isPresent)
          return false; // Filtre absent seulement
        if (_filterType == 1 && !isPresent)
          return false; // Filtre présent seulement
      }

      // Filtre par date
      if (_filterStartDate != null) {
        final entryDate = DateTime.tryParse(entry.debut ?? '');
        if (entryDate != null && entryDate.isBefore(_filterStartDate!)) {
          return false;
        }
      }

      if (_filterEndDate != null) {
        final entryDate = DateTime.tryParse(entry.debut ?? '');
        if (entryDate != null && entryDate.isAfter(_filterEndDate!)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  Widget _buildPresenceFilters() {
    final isDarkMode = _themeService.isDarkMode;

    return Container(
      margin: const EdgeInsets.all(12), // Réduit de 16 à 12
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              final effectiveModalSetState = _presenceModalSetState;
              if (effectiveModalSetState != null && mounted) {
                effectiveModalSetState(() {
                  _isFilterExpanded = !_isFilterExpanded;
                });
              } else if (mounted) {
                setState(() {
                  _isFilterExpanded = !_isFilterExpanded;
                });
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.filter_list,
                        size: 20,
                        color: isDarkMode ? Colors.white70 : Colors.grey[700],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Filtres',
                        style: TextStyle(
                          fontSize: _textSizeService.getScaledFontSize(16),
                          fontWeight: FontWeight.w600,
                          color: isDarkMode ? Colors.white70 : Colors.grey[700],
                        ),
                      ),
                      // Indicateur si des filtres sont actifs
                      if (_filterStartDate != null ||
                          _filterEndDate != null ||
                          _filterType != null)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Color(0xFF1565C0),
                            shape: BoxShape.circle,
                          ),
                          child: const SizedBox(width: 4, height: 4),
                        ),
                    ],
                  ),
                  Icon(
                    _isFilterExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: isDarkMode ? Colors.white70 : Colors.grey[700],
                  ),
                ],
              ),
            ),
          ),
          if (_isFilterExpanded) ...[
            Divider(
              height: 1,
              color: isDarkMode ? Colors.grey[700] : Colors.grey[200],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Filtre par type
                  Text(
                    'Type',
                    style: TextStyle(
                      fontSize: _textSizeService.getScaledFontSize(14),
                      fontWeight: FontWeight.w500,
                      color: isDarkMode ? Colors.white70 : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 6), // Réduit de 8 à 6
                  Wrap(
                    spacing: 6, // Réduit de 8 à 6
                    children: [
                      _buildFilterChip('Tous', null),
                      _buildFilterChip('Absences', 0),
                      _buildFilterChip('Présences', 1),
                    ],
                  ),

                  const SizedBox(height: 12), // Réduit de 16 à 12
                  // Filtre par date
                  Text(
                    'Période (facultatif)',
                    style: TextStyle(
                      fontSize: _textSizeService.getScaledFontSize(14),
                      fontWeight: FontWeight.w500,
                      color: isDarkMode ? Colors.white70 : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 6), // Réduit de 8 à 6
                  Row(
                    children: [
                      Expanded(
                        child: CustomDateInput(
                          label: 'Date début',
                          hint: 'JJ/MM/AAAA',
                          icon: Icons.calendar_today,
                          controller: _filterStartDateController,
                          inputFormatters: [DateInputFormatter()],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: CustomDateInput(
                          label: 'Date fin',
                          hint: 'JJ/MM/AAAA',
                          icon: Icons.calendar_today,
                          controller: _filterEndDateController,
                          inputFormatters: [DateInputFormatter()],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildPresenceActionButtons(),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, int? value) {
    final isDarkMode = _themeService.isDarkMode;
    final isSelected = _filterType == value;

    return GestureDetector(
      onTap: () {
        final effectiveModalSetState = _presenceModalSetState;
        if (effectiveModalSetState != null && mounted) {
          effectiveModalSetState(() {
            _filterType = isSelected ? null : value;
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDarkMode ? Colors.blue[300] : Colors.blue[600])
              : (isDarkMode ? Colors.grey[700] : Colors.grey[200]),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: _textSizeService.getScaledFontSize(12),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : (isDarkMode ? Colors.white70 : Colors.grey[600]),
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate
          ? _filterStartDate ?? DateTime.now()
          : _filterEndDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      final effectiveModalSetState = _presenceModalSetState;
      if (effectiveModalSetState != null && mounted) {
        effectiveModalSetState(() {
          if (isStartDate) {
            _filterStartDate = picked;
          } else {
            _filterEndDate = picked;
          }
        });
      }
    }
  }

  Widget _buildSanctionsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [const SizedBox(height: 20), _buildSanctionsList()],
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
    return _buildComingSoonContent();
  }

  // Section pour les notifications d'échéance
  Widget _buildEcheanceSection(EcheanceNotification echeance, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header de la section
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: echeance.hasUnpaidFees
                        ? [
                            Colors.red.withOpacity(0.2),
                            Colors.red.withOpacity(0.1),
                          ]
                        : [
                            Colors.green.withOpacity(0.2),
                            Colors.green.withOpacity(0.1),
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  echeance.hasUnpaidFees
                      ? Icons.warning_amber_rounded
                      : Icons.check_circle_rounded,
                  color: echeance.hasUnpaidFees ? Colors.red : Colors.green,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Échéances',
                style: TextStyle(
                  fontSize: _textSizeService.getScaledFontSize(16),
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                  letterSpacing: -0.3,
                ),
              ),
              if (echeance.hasUnpaidFees) ...[
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.red.withOpacity(0.9),
                        Colors.red.withOpacity(0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Text(
                    'Non réglé',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Carte d'échéance
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: echeance.hasUnpaidFees
                  ? [
                      isDark
                          ? Colors.red.withOpacity(0.15)
                          : Colors.red.withOpacity(0.08),
                      isDark
                          ? Colors.red.withOpacity(0.05)
                          : Colors.red.withOpacity(0.02),
                    ]
                  : [
                      isDark
                          ? Colors.green.withOpacity(0.15)
                          : Colors.green.withOpacity(0.08),
                      isDark
                          ? Colors.green.withOpacity(0.05)
                          : Colors.green.withOpacity(0.02),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: echeance.hasUnpaidFees
                  ? (isDark
                        ? Colors.red.withOpacity(0.4)
                        : Colors.red.withOpacity(0.2))
                  : (isDark
                        ? Colors.green.withOpacity(0.4)
                        : Colors.green.withOpacity(0.2)),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: (echeance.hasUnpaidFees ? Colors.red : Colors.green)
                    .withOpacity(0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color:
                          (echeance.hasUnpaidFees ? Colors.red : Colors.green)
                              .withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      echeance.hasUnpaidFees
                          ? Icons.money_off_rounded
                          : Icons.attach_money_rounded,
                      color: echeance.hasUnpaidFees ? Colors.red : Colors.green,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      echeance.hasUnpaidFees
                          ? 'Échéances en retard'
                          : 'Situation régulière',
                      style: TextStyle(
                        fontSize: _textSizeService.getScaledFontSize(15),
                        fontWeight: FontWeight.w600,
                        color: echeance.hasUnpaidFees
                            ? Colors.red
                            : Colors.green,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[800] : Colors.grey[50],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      echeance.formattedMessage,
                      style: TextStyle(
                        fontSize: _textSizeService.getScaledFontSize(13),
                        color: isDark
                            ? Colors.grey[300]
                            : const Color(0xFF4A4A4A),
                        height: 1.5,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    if (echeance.conversationId != null && !echeance.estLu) ...[
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () => _markEcheanceAsRead(echeance),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF1976D2).withOpacity(0.1),
                                const Color(0xFF42A5F5).withOpacity(0.05),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: const Color(0xFF1976D2).withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                size: 14,
                                color: const Color(0xFF1976D2),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Marquer comme lu',
                                style: TextStyle(
                                  fontSize: _textSizeService.getScaledFontSize(
                                    11,
                                  ),
                                  color: const Color(0xFF1976D2),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    if (echeance.estLu) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[700] : Colors.grey[200],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 14,
                              color: isDark
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Lu',
                              style: TextStyle(
                                fontSize: _textSizeService.getScaledFontSize(
                                  11,
                                ),
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Section pour les messages de groupe
  Widget _buildMessagesSection(bool isDark, StateSetter setModalState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header de la section
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF1976D2).withOpacity(0.2),
                      const Color(0xFF42A5F5).withOpacity(0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.message_rounded,
                  color: Color(0xFF1976D2),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Messages',
                style: TextStyle(
                  fontSize: _textSizeService.getScaledFontSize(16),
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                  letterSpacing: -0.3,
                ),
              ),
              if (_notifications.isNotEmpty) ...[
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF1976D2).withOpacity(0.9),
                        const Color(0xFF42A5F5).withOpacity(0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1976D2).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    '${_notifications.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Liste des messages
        if (_notifications.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [
                        Colors.grey[800]!.withOpacity(0.5),
                        Colors.grey[900]!.withOpacity(0.3),
                      ]
                    : [
                        Colors.grey[50] ?? const Color(0xFFFAFAFA),
                        Colors.grey[100] ?? const Color(0xFFF5F5F5),
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.grey[700]! : const Color(0xFFE5E5E5),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [
                              Colors.grey[700]!.withOpacity(0.3),
                              Colors.grey[600]!.withOpacity(0.2),
                            ]
                          : [
                              Colors.grey[300] ?? const Color(0xFFE0E0E0),
                              Colors.grey[200] ?? const Color(0xFFEEEEEE),
                            ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.message_outlined,
                    size: 32,
                    color: isDark ? Colors.grey[500] : Colors.grey[400],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Aucun message',
                  style: TextStyle(
                    fontSize: _textSizeService.getScaledFontSize(15),
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.grey[400] : const Color(0xFF4A4A4A),
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Vous n\'avez pas encore reçu de messages',
                  style: TextStyle(
                    fontSize: _textSizeService.getScaledFontSize(13),
                    color: isDark ? Colors.grey[500] : Colors.grey[500],
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          ..._notifications.map(
            (notification) =>
                _buildNotificationCard(notification, setModalState),
          ),
      ],
    );
  }

  LinearGradient _getGradientForColor(Color baseColor) {
    return LinearGradient(
      colors: [baseColor.withOpacity(0.8), baseColor],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  Widget _buildEnhancedSummaryCard(
    String title,
    String value,
    Color color,
    IconData icon, {
    String? subtitle,
    bool isLoading = false,
    LinearGradient? gradient,
    int maxLines = 1,
  }) {
    final isDark = _themeService.isDarkMode;
    // Couleurs subtiles basées sur la couleur de la carte
    final bgColor = isDark ? color.withOpacity(0.12) : color.withOpacity(0.07);
    final borderColor = color.withOpacity(isDark ? 0.25 : 0.18);
    final iconBg = color.withOpacity(isDark ? 0.25 : 0.15);
    final valueColor = isDark
        ? Colors.white.withOpacity(0.92)
        : const Color(0xFF1A1A2E);
    final titleColor = isDark
        ? Colors.white.withOpacity(0.5)
        : const Color(0xFF6B7280);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[900] : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icône avec fond coloré subtil
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(icon, color: color, size: 13),
              ),
              const SizedBox(height: 6),
              // Valeur principale
              if (isLoading)
                Container(
                  height: 14,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                )
              else
                Flexible(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: _textSizeService.getScaledFontSize(13),
                      fontWeight: FontWeight.w700,
                      color: valueColor,
                      letterSpacing: -0.3,
                      height: 1.1,
                    ),
                    maxLines: maxLines,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              // Titre
              Text(
                title,
                style: TextStyle(
                  fontSize: _textSizeService.getScaledFontSize(9),
                  color: titleColor,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExtraScolaireSheetContent extends StatefulWidget {
  final bool isDark;
  final String schoolCode;
  final String matricule;
  final String childName;
  final TextSizeService textSizeService;
  final String? imagePath;
  final Color? imageBackgroundColor;
  final double? imageBorderRadius;

  const _ExtraScolaireSheetContent({
    required this.isDark,
    required this.schoolCode,
    required this.matricule,
    required this.childName,
    required this.textSizeService,
    this.imagePath,
    this.imageBackgroundColor,
    this.imageBorderRadius,
  });

  @override
  State<_ExtraScolaireSheetContent> createState() =>
      _ExtraScolaireSheetContentState();
}

class _ExtraScolaireSheetContentState
    extends State<_ExtraScolaireSheetContent> {
  bool _isLoadingServices = true;
  bool _isLoadingActivities = false;
  List<dynamic> _services = [];
  String? _selectedServiceUid;
  List<dynamic> _activities = [];
  Map<String, dynamic>? _serviceDetails;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoadingServices = true);
    final rawServices = await ExtraScolaireService.getSubscribedServices(
      matricule: widget.matricule,
      ecoleCode: widget.schoolCode,
    );

    final services = rawServices.map((service) {
      if (service is Map<String, dynamic>) {
        final serviceUid =
            service['service_uid']?.toString() ??
            service['service']?.toString() ??
            '';
        final rubrique = service['rubrique']?.toString() ?? '';

        String titre = service['titre']?.toString() ?? '';
        if (titre.isEmpty && rubrique.isNotEmpty) {
          final clean = rubrique.trim().toUpperCase();
          if (clean == 'CANT') {
            titre = 'Cantine';
          } else if (clean == 'TRANS') {
            titre = 'Transport';
          } else if (clean == 'GARD') {
            titre = 'Garderie';
          } else if (clean == 'ETUD') {
            titre = 'Étude';
          } else {
            titre = clean[0] + clean.substring(1).toLowerCase();
          }
        }
        if (titre.isEmpty) {
          titre = 'Service';
        }

        final status = service['statut']?.toString() ?? 'Actif';
        final debut = service['debut']?.toString() ?? '';
        final fin = service['fin']?.toString() ?? '';
        final abonnementDate = service['abonnement_date']?.toString() ?? '';

        return {
          'service_uid': serviceUid,
          'titre': titre,
          'statut': status,
          'debut': debut,
          'fin': fin,
          'abonnement_date': abonnementDate,
          ...service,
        };
      }
      return service;
    }).toList();

    if (mounted) {
      setState(() {
        _services = services;
        _isLoadingServices = false;
        if (services.isNotEmpty) {
          final firstService = services.first;
          final serviceUid = firstService['service_uid']?.toString() ?? '';
          if (serviceUid.isNotEmpty) {
            _selectedServiceUid = serviceUid;
            _loadActivities(serviceUid);
          }
        }
      });
    }
  }

  Future<void> _loadActivities(String serviceUid) async {
    setState(() => _isLoadingActivities = true);
    final activities = await ExtraScolaireService.getServiceActivities(
      serviceUid: serviceUid,
      matricule: widget.matricule,
      ecoleCode: widget.schoolCode,
    );
    if (mounted) {
      setState(() {
        _activities = activities['activities'] as List<dynamic>? ?? [];
        _serviceDetails = activities['details'] as Map<String, dynamic>?;
        _isLoadingActivities = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeBg = widget.isDark ? const Color(0xFF0A0A0A) : Colors.white;
    final themeHeaderColor = widget.isDark
        ? Colors.white
        : const Color(0xFF1F2937);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: themeBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(widget.isDark ? 0.4 : 0.08),
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Column(
        children: [
          BottomSheetHeader(
            icon: Icons.playlist_add_check_rounded,
            imagePath: widget.imagePath,
            imageBackgroundColor: widget.imageBackgroundColor,
            imageBorderRadius: widget.imageBorderRadius,
            iconColor: const Color(0xFF7B1FA2),
            title: 'Services scolaires',
            description: 'Suivi de ${widget.childName}',
            onClose: () => Navigator.of(context).pop(),
          ),
          const Divider(height: 1, thickness: 1),

          // Content
          Expanded(
            child: _isLoadingServices
                ? const Center(
                    child: CustomLoader(
                      message: 'Chargement des services...',
                      loaderColor: Color(0xFF7B1FA2),
                      showBackground: false,
                    ),
                  )
                : _services.isEmpty
                ? _buildEmptyServicesState()
                : Column(
                    children: [
                      _buildServicesTabs(),
                      Expanded(
                        child: _isLoadingActivities
                            ? const Center(
                                child: CustomLoader(
                                  message: 'Chargement du suivi quotidien...',
                                  loaderColor: Color(0xFF7B1FA2),
                                  showBackground: false,
                                ),
                              )
                            : _buildActivitiesSection(),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyServicesState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: widget.isDark
                    ? const Color(0xFF1E0A2E)
                    : const Color(0xFFF3E5F5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.assignment_late_outlined,
                size: 42,
                color: Color(0xFF7B1FA2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Aucun abonnement actif',
              style: TextStyle(
                fontSize: widget.textSizeService.getScaledFontSize(18),
                fontWeight: FontWeight.bold,
                color: widget.isDark ? Colors.white : const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Votre enfant n\'est abonné à aucun service extra-scolaire (Cantine, Transport, etc.) pour l\'année scolaire courante.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: widget.textSizeService.getScaledFontSize(13),
                color: AppColors.screenTextSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServicesTabs() {
    return Container(
      height: 44,
      margin: const EdgeInsets.symmetric(vertical: 14),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _services.length,
        itemBuilder: (context, index) {
          final service = _services[index];
          final String title = service['titre']?.toString() ?? 'Service';
          final String serviceUid = service['service_uid']?.toString() ?? '';
          final bool isSelected = _selectedServiceUid == serviceUid;

          IconData icon = Icons.star_rounded;
          Color color = const Color(0xFF7B1FA2);
          if (title.toLowerCase().contains('cantine')) {
            icon = Icons.restaurant_rounded;
            color = const Color(0xFFE65100);
          } else if (title.toLowerCase().contains('transport') ||
              title.toLowerCase().contains('bus')) {
            icon = Icons.directions_bus_rounded;
            color = const Color(0xFF0288D1);
          }

          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: InkWell(
              onTap: () {
                if (serviceUid.isNotEmpty &&
                    _selectedServiceUid != serviceUid) {
                  setState(() {
                    _selectedServiceUid = serviceUid;
                  });
                  _loadActivities(serviceUid);
                }
              },
              borderRadius: BorderRadius.circular(14),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withOpacity(widget.isDark ? 0.25 : 0.12)
                      : widget.isDark
                      ? Colors.grey[900]
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? color
                        : widget.isDark
                        ? Colors.grey[800]!
                        : Colors.grey[200]!,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 16,
                      color: isSelected ? color : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: widget.textSizeService.getScaledFontSize(13),
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.w600,
                        color: isSelected
                            ? (widget.isDark ? Colors.white : color)
                            : (widget.isDark
                                  ? Colors.grey[400]
                                  : Colors.grey[700]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActivitiesSection() {
    final activeService = _services.firstWhere(
      (s) => s['service_uid']?.toString() == _selectedServiceUid,
      orElse: () => null,
    );

    final String serviceTitle =
        activeService?['titre']?.toString() ?? 'Service';
    final String status = activeService?['statut']?.toString() ?? 'Actif';
    final String debut = activeService?['debut']?.toString() ?? '';
    final String fin = activeService?['fin']?.toString() ?? '';

    Color serviceColor = const Color(0xFF7B1FA2);
    if (serviceTitle.toLowerCase().contains('cantine')) {
      serviceColor = const Color(0xFFE65100);
    } else if (serviceTitle.toLowerCase().contains('transport') ||
        serviceTitle.toLowerCase().contains('bus')) {
      serviceColor = const Color(0xFF0288D1);
    }

    return Column(
      children: [
        // Service Summary Card
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: widget.isDark ? const Color(0xFF1E1E1E) : Colors.grey[50],
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.isDark ? Colors.grey[800]! : Colors.grey[200]!,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    serviceTitle,
                    style: TextStyle(
                      fontSize: widget.textSizeService.getScaledFontSize(15),
                      fontWeight: FontWeight.w700,
                      color: widget.isDark
                          ? Colors.white
                          : const Color(0xFF1F2937),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(
                        widget.isDark ? 0.2 : 0.1,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              if (debut.isNotEmpty ||
                  fin.isNotEmpty ||
                  (activeService?['abonnement_date']?.toString() ?? '')
                      .isNotEmpty) ...[
                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 12,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      debut.isNotEmpty || fin.isNotEmpty
                          ? 'Période d\'abonnement : $debut - $fin'
                          : 'Abonné le : ${_formatAbonnementDate(activeService?['abonnement_date']?.toString() ?? '')}',
                      style: TextStyle(
                        fontSize: widget.textSizeService.getScaledFontSize(11),
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
              if (_serviceDetails != null) ...[
                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 12),
                if ((_serviceDetails!['trajet']?.toString() ?? '')
                    .isNotEmpty) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.alt_route_rounded,
                        size: 14,
                        color: serviceColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Trajet',
                              style: TextStyle(
                                fontSize: widget.textSizeService
                                    .getScaledFontSize(10),
                                color: Colors.grey[500],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _serviceDetails!['trajet'].toString(),
                              style: TextStyle(
                                fontSize: widget.textSizeService
                                    .getScaledFontSize(12),
                                color: widget.isDark
                                    ? Colors.white
                                    : const Color(0xFF1F2937),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
                if ((_serviceDetails!['point_arret']?.toString() ?? '')
                    .isNotEmpty) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.pin_drop_rounded,
                        size: 14,
                        color: Colors.red[400],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Point d\'arrêt',
                              style: TextStyle(
                                fontSize: widget.textSizeService
                                    .getScaledFontSize(10),
                                color: Colors.grey[500],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _serviceDetails!['point_arret'].toString(),
                              style: TextStyle(
                                fontSize: widget.textSizeService
                                    .getScaledFontSize(12),
                                color: widget.isDark
                                    ? Colors.white
                                    : const Color(0xFF1F2937),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
                if ((_serviceDetails!['description']?.toString() ?? '')
                        .isNotEmpty &&
                    _serviceDetails!['description']?.toString() !=
                        _serviceDetails!['point_arret']?.toString() &&
                    _serviceDetails!['description']?.toString() !=
                        _serviceDetails!['trajet']?.toString()) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 14,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Description',
                              style: TextStyle(
                                fontSize: widget.textSizeService
                                    .getScaledFontSize(10),
                                color: Colors.grey[500],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _serviceDetails!['description'].toString(),
                              style: TextStyle(
                                fontSize: widget.textSizeService
                                    .getScaledFontSize(12),
                                color: widget.isDark
                                    ? Colors.grey[300]
                                    : const Color(0xFF4B5563),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
                if (_serviceDetails!['prix'] != null &&
                    _serviceDetails!['prix'] is num &&
                    _serviceDetails!['prix'] > 0) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.payments_rounded,
                        size: 14,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tarif',
                              style: TextStyle(
                                fontSize: widget.textSizeService
                                    .getScaledFontSize(10),
                                color: Colors.grey[500],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${_serviceDetails!['prix']} FCFA',
                              style: TextStyle(
                                fontSize: widget.textSizeService
                                    .getScaledFontSize(12),
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Timeline Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Text(
                'Suivi quotidien',
                style: TextStyle(
                  fontSize: widget.textSizeService.getScaledFontSize(14),
                  fontWeight: FontWeight.bold,
                  color: widget.isDark ? Colors.white : const Color(0xFF374151),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Timeline Content
        Expanded(
          child: _activities.isEmpty
              ? _buildEmptyActivitiesState(serviceTitle)
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  itemCount: _activities.length,
                  itemBuilder: (context, index) {
                    return _buildTimelineStep(
                      activity: _activities[index],
                      isLast: index == _activities.length - 1,
                      serviceColor: serviceColor,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyActivitiesState(String serviceTitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none_rounded,
              size: 38,
              color: widget.isDark ? Colors.grey[600] : Colors.grey[400],
            ),
            const SizedBox(height: 12),
            Text(
              'Aucune activité aujourd\'hui',
              style: TextStyle(
                fontSize: widget.textSizeService.getScaledFontSize(14),
                fontWeight: FontWeight.bold,
                color: widget.isDark ? Colors.grey[400] : Colors.grey[700],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Les données quotidiennes pour le service ${serviceTitle} s\'afficheront ici dès qu\'une activité sera enregistrée.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: widget.textSizeService.getScaledFontSize(12),
                color: Colors.grey,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineStep({
    required dynamic activity,
    required bool isLast,
    required Color serviceColor,
  }) {
    final String time = activity['heure']?.toString() ?? '--:--';
    final String date = activity['date']?.toString() ?? '';
    final String details = activity['details']?.toString() ?? '';
    final String statut = activity['statut']?.toString() ?? '';
    final String description = activity['description']?.toString() ?? '';

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator (Time + line)
          SizedBox(
            width: 55,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  time,
                  style: TextStyle(
                    fontSize: widget.textSizeService.getScaledFontSize(13),
                    fontWeight: FontWeight.bold,
                    color: serviceColor,
                  ),
                ),
                if (date.isNotEmpty)
                  Text(
                    date,
                    style: const TextStyle(
                      fontSize: 8,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),

          // Node indicator (dots & line)
          Column(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: serviceColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: serviceColor, width: 2),
                ),
                child: Center(
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: serviceColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: serviceColor.withOpacity(0.3),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),

          // Card contents
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: widget.isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: widget.isDark
                        ? Colors.grey[800]!
                        : Colors.grey[200]!,
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(
                        widget.isDark ? 0.1 : 0.02,
                      ),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            description,
                            style: TextStyle(
                              fontSize: widget.textSizeService
                                  .getScaledFontSize(13),
                              fontWeight: FontWeight.bold,
                              color: widget.isDark
                                  ? Colors.white
                                  : const Color(0xFF374151),
                            ),
                          ),
                        ),
                        if (statut.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: serviceColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              statut,
                              style: TextStyle(
                                fontSize: 9,
                                color: serviceColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (details.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        details,
                        style: TextStyle(
                          fontSize: widget.textSizeService.getScaledFontSize(
                            12,
                          ),
                          color: widget.isDark
                              ? const Color(0xFFCCCCCC)
                              : const Color(0xFF4B5563),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatAbonnementDate(String dateStr) {
    try {
      if (dateStr.isEmpty) return '';
      final parts = dateStr.split(' ');
      final datePart = parts.first;
      final dateSegments = datePart.split('-');
      if (dateSegments.length == 3) {
        final year = dateSegments[0];
        final month = dateSegments[1];
        final day = dateSegments[2];
        return '$day/$month/$year';
      }
      return datePart;
    } catch (_) {
      return dateStr;
    }
  }
}

/// Bouton animé avec effet pulse pour attirer l'attention de l'utilisateur
class _PulseAnimatedButton extends StatefulWidget {
  final VoidCallback onTap;

  const _PulseAnimatedButton({required this.onTap});

  @override
  State<_PulseAnimatedButton> createState() => _PulseAnimatedButtonState();
}

class _PulseAnimatedButtonState extends State<_PulseAnimatedButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _scaleAnim = Tween<double>(
      begin: 1.0,
      end: 1.06,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _glowAnim = Tween<double>(
      begin: 0.0,
      end: 0.25,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnim.value,
          child: GestureDetector(
            onTap: widget.onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(_glowAnim.value + 0.1),
                    blurRadius: 16,
                    spreadRadius: 2,
                    offset: Offset.zero,
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.10),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Plus d\'infos',
                    style: TextStyle(
                      fontSize: 12,
                      color: const Color(0xFFFF6B2C),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.1,
                    ),
                  ),
                  const SizedBox(width: 5),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 10,
                    color: Color(0xFFFF6B2C),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _OrderCardCancelButton extends StatefulWidget {
  final Order order;
  final VoidCallback onCancelled;

  const _OrderCardCancelButton({
    required this.order,
    required this.onCancelled,
  });

  @override
  State<_OrderCardCancelButton> createState() => _OrderCardCancelButtonState();
}

class _OrderCardCancelButtonState extends State<_OrderCardCancelButton> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _isLoading ? null : _cancel,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFFFFF0F0),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.withOpacity(0.2), width: 1.5),
        ),
        child: Center(
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.cancel_outlined, size: 16, color: Colors.red),
                    SizedBox(width: 8),
                    Text(
                      'Annuler la commande',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Future<void> _cancel() async {
    final TextEditingController reasonController = TextEditingController();
    String selectedReason = "Changement d'avis";
    final List<String> commonReasons = [
      "Changement d'avis",
      "Erreur d'article / quantité",
      "Achat accidentel",
      "Délai de livraison trop long",
      "Autre raison (saisir ci-dessous)",
    ];

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: const [
                  Icon(Icons.cancel_outlined, color: Colors.red, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'Annuler la commande',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Veuillez sélectionner le motif d\'annulation de votre commande :',
                      style: TextStyle(fontSize: 13, height: 1.4),
                    ),
                    const SizedBox(height: 14),
                    ...commonReasons.map((reason) {
                      final isSelected = selectedReason == reason;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.red[500]!.withOpacity(
                                  isDark ? 0.15 : 0.05,
                                )
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? Colors.red[400]!
                                : (isDark
                                      ? Colors.grey[800]!
                                      : Colors.grey[200]!),
                            width: 1.2,
                          ),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            setDialogState(() {
                              selectedReason = reason;
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isSelected
                                      ? Icons.radio_button_checked
                                      : Icons.radio_button_off,
                                  color: isSelected ? Colors.red : Colors.grey,
                                  size: 18,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    reason,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: isSelected
                                          ? (isDark
                                                ? Colors.red[300]
                                                : Colors.red[700])
                                          : (isDark
                                                ? Colors.grey[300]
                                                : Colors.grey[800]),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                    if (selectedReason ==
                        "Autre raison (saisir ci-dessous)") ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: reasonController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Saisissez votre motif ici...',
                          hintStyle: const TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                          contentPadding: const EdgeInsets.all(12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: isDark
                                  ? Colors.grey[800]!
                                  : Colors.grey[300]!,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.red),
                          ),
                        ),
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text(
                    'Retour',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                  child: const Text(
                    'Confirmer',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true) return;

    final String finalReason =
        selectedReason == "Autre raison (saisir ci-dessous)"
        ? (reasonController.text.trim().isNotEmpty
              ? reasonController.text.trim()
              : "Autre motif")
        : selectedReason;

    setState(() => _isLoading = true);
    try {
      final success = await OrderService().cancelOrder(
        widget.order.id,
        reason: finalReason,
      );
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Commande annulée avec succès',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.green[500],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
        widget.onCancelled();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Échec de l\'annulation de la commande',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.red[400],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erreur: $e',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red[400],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
