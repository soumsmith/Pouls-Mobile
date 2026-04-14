import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:parents_responsable/config/app_colors.dart';
import 'package:parents_responsable/config/app_dimensions.dart';
import 'package:parents_responsable/widgets/custom_form_button.dart';
import 'package:parents_responsable/widgets/custom_loader.dart';
import 'package:parents_responsable/widgets/custom_text_field.dart';
import 'package:parents_responsable/widgets/image_menu_card.dart';
import 'package:parents_responsable/widgets/image_menu_card_external_title.dart';
import 'package:parents_responsable/widgets/establishment_action_cards.dart';
import 'package:parents_responsable/widgets/bottom_nav.dart';
import 'package:parents_responsable/widgets/bottom_sheet_menu.dart';
import 'dart:developer' as developer;
import '../models/ecole.dart';
import '../models/ecole_detail.dart';
import '../models/blog.dart';
import '../models/event.dart';
import '../models/avis.dart';
import 'coulisse_excellence_screen.dart';
import '../models/fee.dart';
import '../models/scolarite.dart';
import '../models/niveau.dart';
import '../models/user.dart';
import '../models/child.dart';
import '../models/message.dart';
import '../models/conversation.dart';
import '../models/group_message.dart';
import '../models/order.dart';
import '../models/cart_item.dart';
import '../models/product.dart';
import '../models/student_class_info.dart';
import '../models/student_scolarite.dart';
import '../models/student_message.dart';
import '../models/student_timetable.dart';
import '../models/timetable_entry.dart';
import '../models/parent_suggestion.dart';
import '../models/lieu_livraison.dart';
import '../models/school_supply.dart';
import '../models/place_reservation.dart';
import '../models/classe.dart';
import '../models/matiere.dart';
import '../models/eleve.dart';
import '../models/periode.dart';
import '../models/note.dart';
import '../models/note_api.dart';
import '../models/note_classe_dto.dart';
import '../models/annee_scolaire.dart';
import '../models/access_control.dart';
import '../models/access_log.dart';
import '../services/text_size_service.dart';
import '../services/ecole_api_service.dart';
import '../services/theme_service.dart';
import '../services/blog_service.dart';
import '../services/events_service.dart';
import '../services/avis_service.dart';
import '../services/scolarite_service.dart';
import '../services/niveau_service.dart';
import '../services/recommendation_service.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/testimonial_service.dart';
import '../widgets/custom_snackbar.dart';
import '../services/integration_request_service.dart';
import '../widgets/main_screen_wrapper.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/share_button.dart';
import '../widgets/bottom_sheets/sponsorship_bottom_sheet.dart';
import '../widgets/bottom_sheets/integration_bottom_sheet.dart';
import '../widgets/bottom_sheets/rating_bottom_sheet.dart';
import '../widgets/bottom_sheets/bottom_sheet_header.dart';
import '../widgets/section_header_widget.dart';
import '../widgets/custom_sliver_app_bar.dart';
import '../widgets/components/section_row.dart';
import '../widgets/bottom_fade_gradient.dart';
import '../utils/image_helper.dart';
import '../config/app_typography.dart';
import 'all_events_screen.dart';
import '../services/group_message_service.dart';
import '../services/echeance_service.dart';
import '../models/echeance_notification.dart';

// ── Date Input Formatter ───────────────────────────────────────────────────────
class _DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Si l'utilisateur supprime du texte, permettre la suppression naturelle
    if (newValue.text.length < oldValue.text.length) {
      // Permettre la suppression sans reformater
      String text = newValue.text.replaceAll(RegExp(r'[^0-9/]'), '');

      // Si on supprime après un séparateur, supprimer aussi le séparateur
      if (oldValue.selection.baseOffset > 0 &&
          oldValue.text.length > newValue.text.length) {
        int deletedIndex = newValue.selection.baseOffset;
        if (deletedIndex > 0 && deletedIndex <= text.length) {
          // Vérifier si on a supprimé juste après un séparateur
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

    // Supprimer tous les caractères non numériques sauf les séparateurs
    String text = newValue.text.replaceAll(RegExp(r'[^0-9/]'), '');

    // Si l'utilisateur tape un tiret, le convertir en slash
    if (newValue.text.contains('-') && !newValue.text.contains('/')) {
      text = text.replaceAll('-', '/');
    }

    // Limiter à 10 caractères (DD/MM/YYYY)
    if (text.length > 10) {
      text = text.substring(0, 10);
    }

    // Insertion automatique des séparateurs
    if (text.length >= 2 && !text.contains('/')) {
      // Après 2 chiffres, ajouter le premier séparateur
      text = text.substring(0, 2) + '/' + text.substring(2);
    }

    if (text.length >= 5 && text.indexOf('/', text.indexOf('/') + 1) == -1) {
      // Après 5 caractères (DD/MM), ajouter le deuxième séparateur
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

    // Validation basique des nombres
    List<String> parts = text.split('/');
    if (parts.length >= 3) {
      // Validation du jour (max 31)
      if (parts[0].length == 2 && int.tryParse(parts[0]) != null) {
        int day = int.parse(parts[0]);
        if (day > 31) {
          parts[0] = '31';
        }
      }

      // Validation du mois (max 12)
      if (parts[1].length == 2 && int.tryParse(parts[1]) != null) {
        int month = int.parse(parts[1]);
        if (month > 12) {
          parts[1] = '12';
        }
      }

      text = parts.join('/');
    }

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

// ─── Action card definition ──────────────────────────────────────────────────
class _ActionDef {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  const _ActionDef({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
  });
}

const _kActions = <String, _ActionDef>{
  'integration': _ActionDef(
    icon: Icons.person_add_alt_1_rounded,
    label: 'Intégrer',
    subtitle: 'Inscrire',
    color: Color(0xFFF59E0B),
  ),
  'rating': _ActionDef(
    icon: Icons.star_rate_rounded,
    label: 'Noter',
    subtitle: 'Évaluer',
    color: Color(0xFF10B981),
  ),
  'informations': _ActionDef(
    icon: Icons.info_rounded,
    label: 'Informations',
    subtitle: 'Détails',
    color: Color(0xFF3B82F6),
  ),
  'communication': _ActionDef(
    icon: Icons.chat_rounded,
    label: 'Communication',
    subtitle: 'Annonces',
    color: Color(0xFF10B981),
  ),
  'niveaux': _ActionDef(
    icon: Icons.layers_rounded,
    label: 'Niveaux',
    subtitle: 'Classes',
    color: Color(0xFFF59E0B),
  ),
  'school_events': _ActionDef(
    icon: Icons.event_rounded,
    label: 'Événements',
    subtitle: 'Calendrier',
    color: Color(0xFF8B5CF6),
  ),
  'scolarite': _ActionDef(
    icon: Icons.school_rounded,
    label: 'Scolarité',
    subtitle: 'Frais',
    color: Color(0xFFEF4444),
  ),
  'voir_les_avis': _ActionDef(
    icon: Icons.grade_rounded,
    label: 'Avis & commentaire',
    subtitle: 'Donner un avis',
    color: Color(0xFFF59E0B),
  ),
  'consult_requests': _ActionDef(
    icon: Icons.search_rounded,
    label: 'Mes demandes',
    subtitle: 'Consulter',
    color: Color(0xFF06B6D4),
  ),
  'galeries': _ActionDef(
    icon: Icons.photo_library_rounded,
    label: 'Galeries',
    subtitle: 'Photos',
    color: Color(0xFF00796B),
  ),
  'coulisses': _ActionDef(
    icon: Icons.star_rounded,
    label: 'Coulisses',
    subtitle: 'Excellence',
    color: Color(0xFFD32F2F),
  ),
  'visites': _ActionDef(
    icon: Icons.location_on_rounded,
    label: 'Visites',
    subtitle: 'Guidées',
    color: Color(0xFF3F51B5),
  ),
};

/// Écran de détail d'un établissement
class EstablishmentDetailScreen extends StatefulWidget
    implements MainScreenChild {
  final Ecole ecole;
  const EstablishmentDetailScreen({super.key, required this.ecole});

  @override
  State<EstablishmentDetailScreen> createState() =>
      _EstablishmentDetailScreenState();
}

class _EstablishmentDetailScreenState extends State<EstablishmentDetailScreen>
    with TickerProviderStateMixin
    implements MainScreenChild {
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  final ThemeService _themeService = ThemeService();
  final TextSizeService _textSizeService = TextSizeService();

  EcoleDetail? _ecoleDetail;
  EcoleData? _ecoleParametres;
  Future<ScolariteResponse>? _scolariteFuture;

  final _avisNotifier = ValueNotifier<int>(0);
  final _eventsNotifier = ValueNotifier<int>(0);

  List<Map<String, dynamic>> _blogs = [];
  List<Map<String, dynamic>> _schoolEvents = [];
  List<Map<String, dynamic>> _avis = [];
  bool _isLoadingBlogs = false;
  bool _isLoadingEvents = false;
  bool _isLoadingAvis = false;
  bool _isLoadingMoreEvents = false;
  bool _hasMoreEvents = true;
  int _currentEventsPage = 1;
  int _eventsPerPage =
      4; // Valeur par défaut, sera mise à jour dans initState()
  bool _isInfoCardExpanded =
      false; // État pour gérer l'expansion de la carte d'infos
  double _scrollPosition = 0.0; // Position de scroll actuelle
  static const double _collapseThreshold =
      300.0; // Seuil de scroll avant repliement (200px)
  String? _blogsError;
  String? _eventsError;
  String? _avisError;
  final BlogService _blogService = BlogService();
  final EventsService _eventsService = EventsService();
  final AvisService _avisService = AvisService();

  // form state
  String _selectedSexe = 'M';
  String _selectedStatutAff = 'Affecté';
  String _searchQuery = '';
  String? _expandedBranche;
  late TextEditingController _searchController;

  // Variables pour les notifications
  List<GroupMessage> _notifications = [];
  bool _isLoadingNotifications = false;
  bool _notificationsLoaded = false;
  
  // Variables pour les notifications d'échéance
  EcheanceNotification? _echeanceNotification;
  bool _isLoadingEcheance = false;
  bool _echeanceLoaded = false;

  final TextEditingController _nationaliteController = TextEditingController();
  final TextEditingController _adresseController = TextEditingController();
  final TextEditingController _contact1Controller = TextEditingController();
  final TextEditingController _contact2Controller = TextEditingController();
  final TextEditingController _nomPereController = TextEditingController();
  final TextEditingController _nomMereController = TextEditingController();
  final TextEditingController _nomTuteurController = TextEditingController();
  final TextEditingController _niveauAntController = TextEditingController();
  final TextEditingController _ecoleAntController = TextEditingController();
  final TextEditingController _moyenneAntController = TextEditingController();
  final TextEditingController _rangAntController = TextEditingController();
  final TextEditingController _decisionAntController = TextEditingController();
  final TextEditingController _motifController = TextEditingController();
  final TextEditingController _filiereController = TextEditingController();
  final TextEditingController _ratingController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _requestedClassController =
      TextEditingController();
  final TextEditingController _parentEmailController = TextEditingController();
  final TextEditingController _parentPhoneController = TextEditingController();
  final TextEditingController _schoolNameController = TextEditingController();
  final TextEditingController _schoolAddressController =
      TextEditingController();
  final TextEditingController _schoolTypeController = TextEditingController();
  final TextEditingController _schoolCityController = TextEditingController();
  final TextEditingController _recommenderNameController =
      TextEditingController();
  final TextEditingController _commentsController = TextEditingController();
  // Recommendation controllers
  final TextEditingController _parentNomController = TextEditingController();
  final TextEditingController _parentPrenomController = TextEditingController();
  final TextEditingController _parentTelephoneController =
      TextEditingController();
  final TextEditingController _recommandationEmailController =
      TextEditingController();
  final TextEditingController _parentPaysController = TextEditingController();
  final TextEditingController _parentVilleController = TextEditingController();
  final TextEditingController _parentAdresseController =
      TextEditingController();
  final TextEditingController _etablissementController =
      TextEditingController();
  final TextEditingController _paysController = TextEditingController();
  final TextEditingController _villeController = TextEditingController();
  final TextEditingController _ordreController = TextEditingController();
  final TextEditingController _adresseEtablissementController =
      TextEditingController();

  // Recommendation error states
  bool _parentNomError = false;
  bool _parentPrenomError = false;
  bool _parentTelephoneError = false;
  bool _recommandationEmailError = false;
  // File upload variables
  String? _bulletinFile;
  String? _certificatVaccinationFile;
  String? _certificatScolariteFile;
  String? _extraitNaissanceFile;
  String? _cniParentFile;

  // Validation error states

  // ── helpers ────────────────────────────────────────────────────────────────
  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'primaire':
        return const Color(0xFF3B82F6);
      case 'collège':
        return const Color(0xFF8B5CF6);
      case 'lycée':
        return const Color(0xFF10B981);
      case 'privé':
        return const Color(0xFFF59E0B);
      case 'public':
        return const Color(0xFF6366F1);
      default:
        return const Color(0xFFEF4444);
    }
  }

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _loadEcoleDetail();
    _loadEcoleParametres();
    _loadBlogsAndAvisOnly();
    _loadNotifications(); // Charger les notifications au démarrage
    _fadeController.forward();
    _scolariteFuture = ScolariteService.getScolaritesByEcole(
      widget.ecole.parametreCode,
    );

    // Initialize search controller
    _searchController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize responsive pagination after MediaQuery is available
    _eventsPerPage = AppDimensions.getEventsPerPage(context);
  }

  void _clearErrorIfNotEmpty(String text, VoidCallback clearError) {
    if (text.isNotEmpty) clearError();
  }

  Future<void> _loadEcoleDetail() async {
    try {
      final detail = await EcoleApiService.getEcoleDetail(
        widget.ecole.parametreCode,
      );
      setState(() => _ecoleDetail = detail);
    } catch (e) {
      debugPrint('Erreur lors du chargement des détails: $e');
    }
  }

  Future<void> _loadEcoleParametres() async {
    try {
      final parametres = await EcoleApiService.getEcoleParametres(
        widget.ecole.parametreCode ?? '',
      );
      setState(() => _ecoleParametres = parametres);
    } catch (e) {
      debugPrint('Erreur lors du chargement des paramètres: $e');
    }
  }

  // Charger les notifications (messages et échéances)
  Future<void> _loadNotifications() async {
    print('=== DÉBUT DU CHARGEMENT DES NOTIFICATIONS DANS L\'ÉCRAN DE DÉTAIL ===');
    
    // Récupérer les matricules des enfants de l'utilisateur
    final authService = AuthService();
    final currentUser = authService.getCurrentUser();
    
    print('Utilisateur connecté: ${currentUser != null}');
    if (currentUser != null) {
      print('ID utilisateur: ${currentUser.id}');
      print('Nom utilisateur: ${currentUser.fullName}');
    }
    
    if (currentUser == null) {
      print('ERREUR: Utilisateur non connecté pour charger les notifications');
      return;
    }

    // Récupérer les matricules depuis la base de données
    print('Récupération des matricules depuis la base de données...');
    final databaseService = DatabaseService.instance;
    final childrenInfo = await databaseService.getChildrenInfoByParent(currentUser.id);
    
    print('Nombre d\'enfants trouvés: ${childrenInfo.length}');
    for (final child in childrenInfo) {
      print('  - Enfant: ${child['prenom']} ${child['nom']}, Matricule: ${child['matricule']}');
    }
    
    // Extraire les matricules non null
    final matricules = childrenInfo
        .map((info) => info['matricule'] as String?)
        .where((matricule) => matricule != null && matricule.isNotEmpty)
        .cast<String>()
        .toList();
    
    print('Matricules valides trouvés: $matricules');
    
    if (matricules.isEmpty) {
      print('ERREUR: Aucun matricule trouvé pour charger les notifications');
      return;
    }

    // Utiliser le premier matricule trouvé (on pourrait étendre pour gérer plusieurs enfants)
    final matricule = matricules.first;
    print('MATRICULE SÉLECTIONNÉ: $matricule');
    print('DÉMARRAGE DES APIS DE NOTIFICATION...');

    // Charger les messages de groupe
    print('=== APPEL API MESSAGES DE GROUPE ===');
    try {
      print('Début du chargement des messages de groupe pour: $matricule');
      setState(() => _isLoadingNotifications = true);
      final notifications = await GroupMessageService.getGroupMessages(matricule);
      if (mounted) {
        setState(() {
          _notifications = notifications;
          _isLoadingNotifications = false;
          _notificationsLoaded = true;
        });
      }
      print('SUCCÈS: Messages de groupe chargés: ${notifications.length}');
      for (final notif in notifications) {
        print('  - Message: ${notif.titre}, Lu: ${notif.estLu}');
      }
    } catch (e) {
      print('ERREUR lors du chargement des messages: $e');
      if (mounted) {
        setState(() {
          _isLoadingNotifications = false;
          _notificationsLoaded = true;
        });
      }
    }

    // Charger les notifications d'échéance
    print('=== APPEL API ÉCHÉANCES ===');
    try {
      print('Début du chargement des notifications d\'échéance pour: $matricule');
      setState(() => _isLoadingEcheance = true);
      final echeanceNotification = await EcheanceService.getEcheanceNotification(matricule);
      if (mounted) {
        setState(() {
          _echeanceNotification = echeanceNotification;
          _isLoadingEcheance = false;
          _echeanceLoaded = true;
        });
      }
      print('SUCCÈS: Notification d\'échéance chargée');
      print('  - Statut: ${echeanceNotification.status}');
      print('  - Message: ${echeanceNotification.message}');
      print('  - Impayée: ${echeanceNotification.hasUnpaidFees}');
    } catch (e) {
      print('ERREUR lors du chargement des échéances: $e');
      if (mounted) {
        setState(() {
          _isLoadingEcheance = false;
          _echeanceLoaded = true;
        });
      }
    }
    
    print('=== FIN DU CHARGEMENT DES NOTIFICATIONS ===');
    print('Notifications chargées: ${_notifications.length}');
    print('Échéance chargée: ${_echeanceNotification != null}');
    print('Total notifications: ${_notifications.length + (_echeanceNotification?.hasUnpaidFees == true ? 1 : 0)}');
  }

  Future<void> _loadEventsOnly() async {
    final nom = widget.ecole.parametreNom ?? '';
    if (nom.isEmpty) return;

    setState(() {
      _isLoadingEvents = true;
      _eventsError = null;
      _schoolEvents.clear();
      _currentEventsPage = 1;
      _hasMoreEvents = true;
    });
    _eventsNotifier.value++;

    try {
      final events = await _eventsService.getEventsForUI(
        nomEtablissement: nom,
        page: _currentEventsPage,
        perPage: _eventsPerPage,
      );
      if (!mounted) return;
      setState(() {
        _schoolEvents = events;
        _isLoadingEvents = false;
        // Check if there are more pages
        _hasMoreEvents = events.length >= _eventsPerPage;
      });
      _eventsNotifier.value++;
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _eventsError = e.toString();
        _isLoadingEvents = false;
      });
      _eventsNotifier.value++;
    }
  }

  Future<void> _loadMoreEvents() async {
    final nom = widget.ecole.parametreNom ?? '';
    if (nom.isEmpty || !_hasMoreEvents) return;

    setState(() {
      _isLoadingMoreEvents = true;
    });
    _eventsNotifier.value++;

    try {
      _currentEventsPage++;
      final newEvents = await _eventsService.getEventsForUI(
        nomEtablissement: nom,
        page: _currentEventsPage,
        perPage: _eventsPerPage,
      );
      if (!mounted) return;
      setState(() {
        _schoolEvents.addAll(newEvents);
        _isLoadingMoreEvents = false;
        // Check if there are more pages
        _hasMoreEvents = newEvents.length >= _eventsPerPage;
      });
      _eventsNotifier.value++;
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingMoreEvents = false;
        // Revert page number on error
        _currentEventsPage--;
      });
      _eventsNotifier.value++;
    }
  }

  Future<void> _loadAvisOnly() async {
    final code = widget.ecole.parametreCode ?? '';
    if (code.isEmpty || !mounted) return;

    setState(() {
      _isLoadingAvis = true;
      _avisError = null;
    });
    _avisNotifier.value++; // notifier le bottom sheet

    try {
      final avis = await _avisService.getAvisForUI(code);
      if (!mounted) return;
      setState(() {
        _avis = avis;
        _isLoadingAvis = false;
      });
      _avisNotifier.value++; // notifier le bottom sheet
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _avisError = e.toString();
        _isLoadingAvis = false;
      });
      _avisNotifier.value++; // notifier le bottom sheet
    }
  }

  Future<void> _loadBlogsAndAvisOnly() async {
    final nom = widget.ecole.parametreNom ?? '';
    final code = widget.ecole.parametreCode ?? '';
    if (nom.isEmpty || code.isEmpty) return;
    setState(() {
      _isLoadingBlogs = true;
      _isLoadingAvis = true;
    });
    try {
      final results = await Future.wait([
        _blogService.getBlogsForUI('grand', code).catchError((e) {
          setState(() {
            _blogsError = e.toString();
            _isLoadingBlogs = false;
          });
          throw e;
        }),
        _avisService.getAvisForUI(code).catchError((e) {
          setState(() {
            _avisError = e.toString();
            _isLoadingAvis = false;
          });
          throw e;
        }),
      ]);
      setState(() {
        if (_blogsError == null) {
          _blogs = results[0] as List<Map<String, dynamic>>;
          _isLoadingBlogs = false;
        }
        if (_avisError == null) {
          _avis = results[1] as List<Map<String, dynamic>>;
          _isLoadingAvis = false;
        }
      });
    } catch (_) {}
  }

  Future<void> _loadBlogsEventsAndAvis() async {
    final nom = widget.ecole.parametreNom ?? '';
    final code = widget.ecole.parametreCode ?? '';
    if (nom.isEmpty || code.isEmpty) return;
    setState(() {
      _isLoadingBlogs = true;
      _isLoadingEvents = true;
      _isLoadingAvis = true;
    });
    try {
      final results = await Future.wait([
        _blogService.getBlogsForUI('grand', code).catchError((e) {
          setState(() {
            _blogsError = e.toString();
            _isLoadingBlogs = false;
          });
          throw e;
        }),
        _eventsService.getEventsForUI(nomEtablissement: nom).catchError((e) {
          setState(() {
            _eventsError = e.toString();
            _isLoadingEvents = false;
          });
          throw e;
        }),
        _avisService.getAvisForUI(code).catchError((e) {
          setState(() {
            _avisError = e.toString();
            _isLoadingAvis = false;
          });
          throw e;
        }),
      ]);
      setState(() {
        if (_blogsError == null) {
          _blogs = results[0] as List<Map<String, dynamic>>;
          _isLoadingBlogs = false;
        }
        if (_eventsError == null) {
          _schoolEvents = results[1] as List<Map<String, dynamic>>;
          _isLoadingEvents = false;
        }
        if (_avisError == null) {
          _avis = results[2] as List<Map<String, dynamic>>;
          _isLoadingAvis = false;
        }
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _avisNotifier.dispose();
    _eventsNotifier.dispose();
    _fadeController.dispose();
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
    _ratingController.dispose();
    _commentController.dispose();
    // Recommendation controllers
    _parentNomController.dispose();
    _parentPrenomController.dispose();
    _parentTelephoneController.dispose();
    _recommandationEmailController.dispose();
    _parentPaysController.dispose();
    _parentVilleController.dispose();
    _parentAdresseController.dispose();
    _etablissementController.dispose();
    _paysController.dispose();
    _villeController.dispose();
    _ordreController.dispose();
    _adresseEtablissementController.dispose();
    // Search controller
    _searchController.dispose();
    super.dispose();
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  BUILD
  // ══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: AnimatedBuilder(
        animation: Listenable.merge([_themeService, _textSizeService]),
        builder: (context, _) {
          final isDark = _themeService.isDarkMode;
          return ScaffoldMessenger(
            key: _scaffoldMessengerKey,
            child: Scaffold(
              backgroundColor: isDark
                  ? const Color(0xFF0F0F0F)
                  : AppColors.screenSurface,
              body: Stack(
                children: [
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: NotificationListener<ScrollNotification>(
                      onNotification: (scrollNotification) {
                        if (scrollNotification is ScrollUpdateNotification) {
                          // Mettre à jour la position de scroll
                          _scrollPosition +=
                              scrollNotification.scrollDelta ?? 0;

                          // Replier la carte si elle est étendue et que le scroll dépasse le seuil
                          if (_isInfoCardExpanded &&
                              _scrollPosition.abs() > _collapseThreshold) {
                            setState(() {
                              _isInfoCardExpanded = false;
                            });
                          }
                        }
                        return false;
                      },
                      child: CustomScrollView(
                        slivers: [
                          _buildSliverAppBar(isDark),
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.only(
                                bottom: 100,
                              ), // Espace pour la bottom nav
                              child: _buildContent(isDark),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Bottom fade gradient effect
                  const BottomFadeGradient(),
                  // Bottom navigation
                  Positioned(
                    bottom: -15,
                    left: 0,
                    right: 0,
                    child: SafeArea(
                      top: false,
                      child: BottomNav(
                        currentIndex:
                            999, // Index hors limites pour ne rien sélectionner
                        onTap: (index) {
                          if (index == 3) {
                            // Menu "Plus" - afficher le menu bottom sheet
                            showMenuBottomSheet(context);
                          } else {
                            // Pour les autres onglets, simplement revenir à l'écran précédent
                            Navigator.of(context).pop();
                          }
                        },
                      ),
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

  // ── AppBar ─────────────────────────────────────────────────────────────────
  Widget _buildSliverAppBar(bool isDark) {
    return CustomSliverAppBar(
      title: 'Détails de l\'établissement',
      isDark: isDark,
      actions: [
        AppBarAction(
          icon: Icons.favorite_border,
          onTap: () {
            _showActionBottomSheet(
              'voir_les_avis',
              _kActions['voir_les_avis']!,
            );
          },
          tooltip: 'Avis et notes',
        ).buildWidget(isDark),
        AppBarAction(
          icon: Icons.share,
          onTap: () {},
          tooltip: 'Partager',
        ).buildWidget(isDark),
        const SizedBox(width: 4),
      ],
    );
  }

  // ── Main content ───────────────────────────────────────────────────────────
  Widget _buildContent(bool isDark) {
    return Column(
      children: [
        const SizedBox(height: 8),
        _buildEstablishmentHeader(isDark),
        const SizedBox(height: 10),
        // _buildSectionHeader('Actions rapides', isDark),
        // const SizedBox(height: 24),
        // Padding(
        //   padding: const EdgeInsets.symmetric(horizontal: 16),
        //   child: _buildActionButtons(isDark),
        // ),
        // const SizedBox(height: 24),
        _buildMenuCards(isDark),
        const SizedBox(height: 102),
      ],
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return SectionHeaderWidget(title: title, isDark: isDark);
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  NOUVEAU _buildEstablishmentHeader — REDESIGN "HERO IMMERSIF"
  //  À coller en remplacement de l'ancien dans EstablishmentDetailScreen
  // ══════════════════════════════════════════════════════════════════════════
  //
  //  INSTRUCTIONS D'INTÉGRATION :
  //  1. Remplace toute la méthode _buildEstablishmentHeader(bool isDark) par ce code.
  //  2. La méthode _buildInfoRow existante peut être CONSERVÉE (utilisée ailleurs).
  //  3. Les helpers _formatDate et _formatCurrency sont déjà dans ton fichier — pas de doublon.
  //  4. Ajoute les méthodes privées auxiliaires (_buildStatChip, _buildInfoPillRow,
  //     _buildPeriodCard) à la fin de la classe, avant la fermeture `}`.
  //
  // ══════════════════════════════════════════════════════════════════════════

  // ── MÉTHODE PRINCIPALE (remplace l'ancienne) ─────────────────────────────
  Widget _buildEstablishmentHeader(bool isDark) {
    // ── Données depuis l'API ────────────────────────────────────────────────
    final imageUrl = _ecoleDetail?.image ?? widget.ecole.displayImage;
    final establishmentName =
        _ecoleDetail?.data.nom ?? widget.ecole.parametreNom ?? 'École';
    final establishmentType = widget.ecole.typePrincipal ?? 'Primaire';
    final slogan = _ecoleDetail?.data.slogan ?? '';
    final address =
        _ecoleDetail?.data.adresse ??
        widget.ecole.adresse ??
        'Adresse non disponible';
    final phone = _ecoleDetail?.data.telephone ?? widget.ecole.telephone ?? '';

    // Paramètres école
    final effectif = _ecoleParametres?.effectif;
    final nbrannee = _ecoleParametres?.nbrannee;
    final programmelangue = _ecoleParametres?.programmelangue;
    final statut = _ecoleParametres?.statut;
    final annee = _ecoleParametres?.annee;
    final debutReservation = _ecoleParametres?.debutReservation;
    final finReservation = _ecoleParametres?.finReservation;
    final montantReservation = _ecoleParametres?.montantReservation;
    final debutPreinscrit = _ecoleParametres?.debutPreinscrit;
    final finPreinscrit = _ecoleParametres?.finPreinscrit;
    final debutInscrit = _ecoleParametres?.debutInscrit;
    final finInscrit = _ecoleParametres?.finInscrit;
    final logo = _ecoleParametres?.logo;

    // Couleur de type
    final typeColor = _getTypeColor(establishmentType);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(
          offset: Offset(0, 24 * (1 - v)),
          child: child,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── HERO CARD ───────────────────────────────────────────────────
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            height: 190,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(
                AppDimensions.getHeroCardBorderRadius(context),
              ),
              boxShadow: AppDimensions.getMainShadow(context),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(
                AppDimensions.getHeroCardBorderRadius(context),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // ── Image de fond ──────────────────────────────────────
                  ImageHelper.buildNetworkImage(
                    imageUrl: imageUrl,
                    placeholder: establishmentName,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                  ),

                  // ── Dégradé overlay ────────────────────────────────────
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.35),
                          Colors.black.withValues(alpha: 0.75),
                          Colors.black.withValues(alpha: 0.88),
                        ],
                        stops: const [0.0, 0.3, 0.55, 0.78, 1.0],
                      ),
                    ),
                  ),

                  // ── Badge type (haut-gauche) ───────────────────────────
                  Positioned(
                    top: 16,
                    left: 16,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.getMediumCardBorderRadius(context),
                      ),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(
                              AppDimensions.getMediumCardBorderRadius(context),
                            ),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.28),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF4ADE80),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                establishmentType.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ── Badge statut (haut-droite) ─────────────────────────
                  Positioned(
                    top: 16,
                    right: 16,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.getMediumCardBorderRadius(context),
                      ),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF4ADE80,
                            ).withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(
                              AppDimensions.getMediumCardBorderRadius(context),
                            ),
                            border: Border.all(
                              color: const Color(
                                0xFF4ADE80,
                              ).withValues(alpha: 0.4),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            '● ${statut ?? 'ACTIF'}',
                            style: const TextStyle(
                              color: Color(0xFF4ADE80),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ── Contenu bas de carte ───────────────────────────────
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Logo + Nom
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              // Logo flottant
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(
                                    AppDimensions.getMediumCardBorderRadius(
                                      context,
                                    ),
                                  ),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.3,
                                      ),
                                      blurRadius: 16,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                    AppDimensions.getMediumCardBorderRadius(
                                      context,
                                    ),
                                  ),
                                  child: logo != null && logo!.isNotEmpty
                                      ? Image.network(
                                          logo!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              _buildLogoFallback(
                                                establishmentName,
                                                typeColor,
                                              ),
                                        )
                                      : _buildLogoFallback(
                                          establishmentName,
                                          typeColor,
                                        ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Nom + slogan
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      establishmentName,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 17,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.4,
                                        height: 1.2,
                                        shadows: [
                                          Shadow(
                                            color: Colors.black38,
                                            blurRadius: 8,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (slogan.isNotEmpty) ...[
                                      const SizedBox(height: 3),
                                      Text(
                                        '"$slogan"',
                                        style: TextStyle(
                                          color: Colors.white.withValues(
                                            alpha: 0.72,
                                          ),
                                          fontSize: 11,
                                          fontStyle: FontStyle.italic,
                                          letterSpacing: 0.1,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // ── Stats chips ──────────────────────────────────
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                /*if (effectif != null)
                                  _buildStatChip(
                                    icon: Icons.people_rounded,
                                    value: '$effectif',
                                    label: 'Élèves',
                                  ),*/
                                if (nbrannee != null)
                                  _buildStatChip(
                                    icon: Icons.layers_rounded,
                                    value: '$nbrannee niveaux',
                                    label: 'Scolarité',
                                  ),
                                if (annee != null)
                                  _buildStatChip(
                                    icon: Icons.schedule_rounded,
                                    value: annee!,
                                    label: 'Année',
                                  ),
                                _buildStatChip(
                                  icon: Icons.star_rounded,
                                  value: '4.8 / 5',
                                  label: 'Note',
                                  valueColor: const Color(0xFFFBBF24),
                                  iconColor: const Color(0xFFFBBF24),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── INFO PILLS CARD (flottant sous le hero) ─────────────────────
          Transform.translate(
            offset: const Offset(0, -14),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(
                  AppDimensions.getLargeCardBorderRadius(context),
                ),
                boxShadow: AppDimensions.getLightShadow(context),
              ),
              child: Column(
                children: [
                  // Téléphone (toujours visible par défaut)
                  if (phone.isNotEmpty)
                    _buildInfoPillRow(
                      icon: Icons.phone_rounded,
                      iconColor: const Color(0xFF22C55E),
                      iconBgColor: const Color(0xFFF0FDF4),
                      label: 'Téléphone',
                      value: phone,
                      isDark: isDark,
                      isFirst: true,
                      trailingWidget: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Bouton Appeler
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FDF4),
                              border: Border.all(
                                color: const Color(0xFFBBF7D0),
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(
                                AppDimensions.getSmallCardBorderRadius(context),
                              ),
                            ),
                            child: const Text(
                              'Appeler',
                              style: TextStyle(
                                color: Color(0xFF16A34A),
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          // Bouton Voir + / Voir -
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                if (_isInfoCardExpanded) {
                                  _isInfoCardExpanded = false; // Fermer
                                } else {
                                  _isInfoCardExpanded = true; // Ouvrir
                                  _scrollPosition =
                                      0.0; // Réinitialiser la position de scroll
                                }
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: _isInfoCardExpanded
                                    ? const Color(
                                        0xFFFEE2E2,
                                      ) // Rouge clair quand ouvert
                                    : (isDark
                                          ? const Color(0xFF2A2A2A)
                                          : const Color(0xFFF3F4F6)),
                                border: Border.all(
                                  color: _isInfoCardExpanded
                                      ? const Color(
                                          0xFFFCA5A5,
                                        ) // Bordure rouge quand ouvert
                                      : (isDark
                                            ? const Color(0xFF4A4A4A)
                                            : const Color(0xFFD1D5DB)),
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(
                                  AppDimensions.getSmallCardBorderRadius(
                                    context,
                                  ),
                                ),
                              ),
                              child: Text(
                                _isInfoCardExpanded ? 'Voir -' : 'Voir +',
                                style: TextStyle(
                                  color: _isInfoCardExpanded
                                      ? const Color(
                                          0xFFDC2626,
                                        ) // Texte rouge quand ouvert
                                      : const Color(0xFF6B7280),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (_isInfoCardExpanded)
                    // Contenu additionnel visible
                    Column(
                      children: [
                        // Adresse
                        _buildInfoPillRow(
                          icon: Icons.location_on_rounded,
                          iconColor: const Color(0xFF3B82F6),
                          iconBgColor: const Color(0xFFEFF6FF),
                          label: 'Adresse',
                          value: address,
                          isDark: isDark,
                        ),

                        // Langue (si dispo)
                        if (programmelangue != null &&
                            programmelangue!.isNotEmpty)
                          _buildInfoPillRow(
                            icon: Icons.language_rounded,
                            iconColor: const Color(0xFFA855F7),
                            iconBgColor: const Color(0xFFFAF5FF),
                            label: 'Langue & Programme',
                            value: programmelangue!,
                            isDark: isDark,
                          ),

                        // Pré-inscription
                        if (debutPreinscrit != null && finPreinscrit != null)
                          _buildInfoPillRow(
                            icon: Icons.schedule_rounded,
                            iconColor: const Color(0xFFF97316),
                            iconBgColor: const Color(0xFFFFF7ED),
                            label: 'Pré-inscription',
                            value:
                                '${_formatDate(debutPreinscrit!)} -> ${_formatDate(finPreinscrit!)}',
                            isDark: isDark,
                          ),

                        // Période d'inscription
                        if (debutInscrit != null && finInscrit != null)
                          _buildInfoPillRow(
                            icon: Icons.edit_calendar_rounded,
                            iconColor: const Color(0xFFF97316),
                            iconBgColor: const Color(0xFFFFF7ED),
                            label: "Période d'inscription",
                            value:
                                '${_formatDate(debutInscrit!)} -> ${_formatDate(finInscrit!)}',
                            isDark: isDark,
                            trailingWidget: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF7ED),
                                border: Border.all(
                                  color: const Color(0xFFFED7AA),
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(
                                  AppDimensions.getSmallCardBorderRadius(
                                    context,
                                  ),
                                ),
                              ),
                              child: const Text(
                                "S'inscrire",
                                style: TextStyle(
                                  color: Color(0xFFEA580C),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),

                        // Réservation
                        if (montantReservation != null &&
                            montantReservation! > 0)
                          _buildInfoPillRow(
                            icon: Icons.event_seat_rounded,
                            iconColor: const Color(0xFF3B82F6),
                            iconBgColor: const Color(0xFFEFF6FF),
                            label: 'Réservation',
                            value:
                                '${_formatDate(debutReservation!)} -> ${_formatDate(finReservation!)}',
                            isDark: isDark,
                            trailingWidget: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                border: Border.all(
                                  color: const Color(0xFFBFDBFE),
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(
                                  AppDimensions.getSmallCardBorderRadius(
                                    context,
                                  ),
                                ),
                              ),
                              child: Text(
                                'Montant autorisé = ${montantReservation!.toStringAsFixed(0)} XOF',
                                style: const TextStyle(
                                  color: Color(0xFF1E40AF),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
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
    );
  }

  // ── Logo fallback ────────────────────────────────────────────────────────
  Widget _buildLogoFallback(String name, Color color) {
    final initials = name
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
      ),
    );
  }

  // ── Stat chip (glassmorphism) ────────────────────────────────────────────
  Widget _buildStatChip({
    required IconData icon,
    required String value,
    required String label,
    Color valueColor = Colors.white,
    Color iconColor = Colors.white,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 7),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(
          AppDimensions.getBadgeBorderRadius(context),
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor.withValues(alpha: 0.9), size: 13),
          const SizedBox(width: 5),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: valueColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.3,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Info pill row ────────────────────────────────────────────────────────
  Widget _buildInfoPillRow({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String label,
    required String value,
    required bool isDark,
    Widget? trailingWidget,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: isDark
                      ? iconColor.withValues(alpha: 0.15)
                      : iconBgColor,
                  borderRadius: BorderRadius.circular(
                    AppDimensions.getIconContainerBorderRadius(context),
                  ),
                ),
                child: Icon(icon, color: iconColor, size: 14),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: isDark
                            ? Colors.white38
                            : const Color(0xFFA0AEC0),
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF1A202C),
                        height: 1.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (trailingWidget != null) trailingWidget,
            ],
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : const Color(0xFFF0F4F8),
            indent: 14,
            endIndent: 14,
          ),
      ],
    );
  }

  // ── Period card ──────────────────────────────────────────────────────────

  /// Vérifie si une période d'inscription est active
  bool _isPeriodActive(String? debut, String? fin) {
    if (debut == null || fin == null) return false;
    try {
      final debutDate = DateTime.parse(debut);
      final finDate = DateTime.parse(fin);
      final now = DateTime.now();
      return now.isAfter(debutDate) && now.isBefore(finDate);
    } catch (e) {
      return false;
    }
  }

  Widget _buildPeriodCard({
    required String title,
    required String value,
    required Color dotColor,
    required Color titleColor,
    required bool isDark,
    bool enableShadow = true, // Paramètre pour activer/désactiver l'ombre
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(
          AppDimensions.getMediumCardBorderRadius(context),
        ),
        boxShadow: AppDimensions.getLightShadow(context, enabled: enableShadow),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                    color: titleColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : const Color(0xFF4A5568),
              height: 1.4,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ── Header card ────────────────────────────────────────────────────────────
  Widget _buildEstablishmentHeader_(bool isDark) {
    final imageUrl = _ecoleDetail?.image ?? widget.ecole.displayImage;
    final establishmentName =
        _ecoleDetail?.data.nom ?? widget.ecole.parametreNom ?? 'École';
    final establishmentType = widget.ecole.typePrincipal ?? 'Primaire';
    final motto =
        _ecoleDetail?.data.slogan ??
        'L\'excellence notre priorité'; // Currently unused but kept for potential future use
    final address =
        _ecoleDetail?.data.adresse ??
        widget.ecole.adresse ??
        'Adresse non disponible';
    final phone =
        _ecoleDetail?.data.telephone ??
        widget.ecole.telephone ??
        'Téléphone non disponible';
    final email =
        _ecoleDetail?.data.email ??
        'Email non disponible'; // Currently unused but kept for potential future use

    // Récupérer les informations depuis l'API des paramètres
    final effectif = _ecoleParametres?.effectif;
    final effectifmoyclasse = _ecoleParametres?.effectifmoyclasse;
    final nbrannee = _ecoleParametres?.nbrannee;
    final programmelangue = _ecoleParametres?.programmelangue;
    final statut = _ecoleParametres?.statut;
    final periode = _ecoleParametres?.periode;
    final typeperiode = _ecoleParametres?.typeperiode;
    final annee = _ecoleParametres?.annee;
    final testEntree = _ecoleParametres?.testEntree;
    final debutReservation = _ecoleParametres?.debutReservation;
    final finReservation = _ecoleParametres?.finReservation;
    final montantReservation = _ecoleParametres?.montantReservation;
    final debutPreinscrit = _ecoleParametres?.debutPreinscrit;
    final finPreinscrit = _ecoleParametres?.finPreinscrit;
    final debutInscrit = _ecoleParametres?.debutInscrit;
    final finInscrit = _ecoleParametres?.finInscrit;
    final telephone = _ecoleParametres?.telephone;
    final logo = _ecoleParametres?.logo;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      builder: (context, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(
          offset: Offset(0, 20 * (1 - v)),
          child: child,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(
            AppDimensions.getLargeCardBorderRadius(context),
          ),
          boxShadow: AppDimensions.getMainShadow(context),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(
            AppDimensions.getLargeCardBorderRadius(context),
          ),
          child: SizedBox(
            height: 320, // Augmenté à 320px pour accommoder plus d'informations
            child: Stack(
              children: [
                // Image de fond avec dégradé
                Positioned.fill(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ImageHelper.buildNetworkImage(
                        imageUrl: imageUrl,
                        placeholder: establishmentName,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                      ),
                      // Dégradé overlay pour améliorer la lisibilité
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.3),
                              Colors.black.withValues(alpha: 0.7),
                            ],
                            stops: const [0.0, 0.4, 0.7, 1.0],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Contenu superposé
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Spacer(),

                        // Badge du type d'établissement
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(
                              AppDimensions.getMediumCardBorderRadius(context),
                            ),
                            boxShadow: AppDimensions.getCustomShadow(
                              context: context,
                              alpha: 0.3,
                              blurRadius: 8,
                              offset: 2,
                            ),
                          ),
                          child: Text(
                            establishmentType.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Carte d'informations avec fond semi-transparent et défilement
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(
                              alpha: isDark ? 0.9 : 0.9,
                            ),
                            borderRadius: BorderRadius.circular(
                              AppDimensions.getSmallCardBorderRadius(context),
                            ),
                          ),
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Nom de l'établissement
                                Text(
                                  establishmentName,
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),

                                const SizedBox(height: 4),

                                _buildInfoRow(
                                  context: context,
                                  icon: Icons.location_on_rounded,
                                  text: address,
                                  color: AppColors.primary,
                                ),

                                const SizedBox(height: 2),

                                // Statut si disponible
                                if (statut != null)
                                  _buildInfoRow(
                                    context: context,
                                    icon: Icons.business_rounded,
                                    text: 'Statut: $statut',
                                    color: Colors.blue,
                                  ),

                                // Effectif si disponible
                                if (effectif != null)
                                  _buildInfoRow(
                                    context: context,
                                    icon: Icons.people_rounded,
                                    text: '$effectif élèves',
                                    color: AppColors.primary,
                                  ),

                                // Effectif moyen par classe si disponible
                                if (effectifmoyclasse != null)
                                  _buildInfoRow(
                                    context: context,
                                    icon: Icons.groups_rounded,
                                    text: 'Moyenne/classe: $effectifmoyclasse',
                                    color: Colors.purple,
                                  ),

                                // Nombre d'années si disponible
                                if (nbrannee != null)
                                  _buildInfoRow(
                                    context: context,
                                    icon: Icons.school_rounded,
                                    text: 'Nombre d\'années: $nbrannee',
                                    color: Colors.indigo,
                                  ),

                                // Langues si disponible
                                if (programmelangue != null)
                                  _buildInfoRow(
                                    context: context,
                                    icon: Icons.language_rounded,
                                    text: 'Langues: $programmelangue',
                                    color: Colors.teal,
                                  ),

                                // Téléphone si disponible
                                if (telephone != null && telephone!.isNotEmpty)
                                  _buildInfoRow(
                                    context: context,
                                    icon: Icons.phone_rounded,
                                    text: telephone!,
                                    color: Colors.green,
                                  ),

                                // Période si disponible
                                if (periode != null)
                                  _buildInfoRow(
                                    context: context,
                                    icon: Icons.date_range_rounded,
                                    text: 'Période: $periode',
                                    color: Colors.orange,
                                  ),

                                // Type période si disponible
                                if (typeperiode != null)
                                  _buildInfoRow(
                                    context: context,
                                    icon: Icons.category_rounded,
                                    text: 'Type période: $typeperiode',
                                    color: Colors.brown,
                                  ),

                                // Année si disponible
                                if (annee != null)
                                  _buildInfoRow(
                                    context: context,
                                    icon: Icons.event_note_rounded,
                                    text: 'Année: $annee',
                                    color: Colors.red,
                                  ),

                                // Test d'entrée si disponible
                                if (testEntree != null && testEntree! > 0)
                                  _buildInfoRow(
                                    context: context,
                                    icon: Icons.quiz_rounded,
                                    text: 'Test d\'entrée: Requis',
                                    color: Colors.deepOrange,
                                  ),

                                // Réservation si disponible
                                if (debutReservation != null &&
                                    finReservation != null) ...[
                                  const SizedBox(height: 2),
                                  _buildInfoRow(
                                    context: context,
                                    icon: Icons.bookmark_rounded,
                                    text:
                                        'Réservation: ${_formatDate(debutReservation!)} - ${_formatDate(finReservation!)}',
                                    color: Colors.purple,
                                  ),
                                ],

                                // Frais de réservation si disponible
                                if (montantReservation != null &&
                                    montantReservation! > 0)
                                  _buildInfoRow(
                                    context: context,
                                    icon: Icons.payments_rounded,
                                    text:
                                        'Frais réservation: ${_formatCurrency(montantReservation!)}',
                                    color: Colors.green,
                                  ),

                                // Périodes d'inscription si disponibles
                                if (debutPreinscrit != null &&
                                    finPreinscrit != null) ...[
                                  const SizedBox(height: 2),
                                  _buildInfoRow(
                                    context: context,
                                    icon: Icons.calendar_today_rounded,
                                    text:
                                        'Pré-inscription: ${_formatDate(debutPreinscrit)} - ${_formatDate(finPreinscrit)}',
                                    color: Colors.orange,
                                  ),
                                ],

                                if (debutInscrit != null &&
                                    finInscrit != null) ...[
                                  const SizedBox(height: 2),
                                  _buildInfoRow(
                                    context: context,
                                    icon: Icons.edit_calendar_rounded,
                                    text:
                                        'Inscription: ${_formatDate(debutInscrit)} - ${_formatDate(finInscrit)}',
                                    color: Colors.green,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Info Row (from establishment_header_card) ─────────────────────────────
  Widget _buildInfoRow({
    required BuildContext context,
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(
              AppDimensions.getSmallCardBorderRadius(context),
            ),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white70
                  : Colors.black87,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ── Date Formatter ─────────────────────────────────────────────────────────
  String _formatDate(String dateString) {
    try {
      final dateTime = DateTime.parse(dateString);
      return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
    } catch (e) {
      return dateString;
    }
  }

  // ── Currency Formatter ─────────────────────────────────────────────────────
  String _formatCurrency(int amount) {
    return '${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')} FCFA';
  }

  // ── Build Info Card ───────────────────────────────────────────────────────
  Widget _buildInfoCard(
    IconData icon,
    String text,
    bool isDark,
    String label, {
    bool fullWidth = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(
          AppDimensions.getSmallCardBorderRadius(context),
        ),
        border: Border.all(
          color: isDark ? const Color(0xFF3A3A3A) : Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: AppColors.screenOrange,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 6),
          // Contenu
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.screenOrangeLight,
                  borderRadius: BorderRadius.circular(
                    AppDimensions.getSmallCardBorderRadius(context),
                  ),
                ),
                child: Icon(icon, size: 14, color: AppColors.screenOrange),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  text,
                  maxLines: fullWidth ? 2 : 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white70 : Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Hero Placeholder with Enhanced Design ───────────────────────────────
  Widget _heroPlaceholder(Color color) => Container(
    height: 220,
    width: double.infinity,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          color.withOpacity(0.8),
          color.withOpacity(0.6),
          color.withOpacity(0.4),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: Stack(
      children: [
        // Pattern décoratif
        Positioned.fill(
          child: CustomPaint(painter: _PatternPainter(color.withOpacity(0.1))),
        ),
        // Icône centrale
        Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(
                AppDimensions.getLargeCardBorderRadius(context),
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.school_rounded,
              size: 40,
              color: Colors.white,
            ),
          ),
        ),
      ],
    ),
  );

  // ── Modern Info Cards ─────────────────────────────────────────────────────
  Widget _infoCardModern(
    IconData icon,
    String text,
    bool isDark,
    String label, {
    bool fullWidth = false,
    bool enableShadow = true, // Paramètre pour activer/désactiver l'ombre
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
        borderRadius: BorderRadius.circular(
          AppDimensions.getMediumCardBorderRadius(context),
        ),
        border: Border.all(
          color: isDark
              ? const Color(0xFF3A3A3A)
              : Colors.grey.withOpacity(0.15),
          width: 1,
        ),
        boxShadow: AppDimensions.getCustomShadow(
          context: context,
          alpha: isDark ? 0.2 : 0.06,
          blurRadius: 12,
          offset: 4,
          enabled: enableShadow,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.screenOrange,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 8),
          // Contenu
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.screenOrangeLight,
                  borderRadius: BorderRadius.circular(
                    AppDimensions.getBadgeBorderRadius(context),
                  ),
                ),
                child: Icon(icon, size: 16, color: AppColors.screenOrange),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  maxLines: fullWidth ? 2 : 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white70 : Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Remplace _infoRow par cette version plus soignée
  Widget _infoRowModern(IconData icon, String text, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : AppColors.screenSurface,
        borderRadius: BorderRadius.circular(
          AppDimensions.getBadgeBorderRadius(context),
        ),
        border: Border.all(
          color: isDark ? const Color(0xFF3A3A3A) : AppColors.screenDivider,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.screenOrangeLight,
              borderRadius: BorderRadius.circular(
                AppDimensions.getSmallCardBorderRadius(context),
              ),
            ),
            child: Icon(icon, size: 14, color: AppColors.screenOrange),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white70 : AppColors.screenTextSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholderCover(Color color) => Container(
    height: 160,
    width: double.infinity,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [color, color.withOpacity(0.6)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: const Icon(Icons.school_rounded, size: 56, color: Colors.white54),
  );

  Widget _infoRow(IconData icon, String text, bool isDark) => Row(
    children: [
      Icon(icon, size: 14, color: AppColors.screenOrange),
      const SizedBox(width: 6),
      Expanded(
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white60 : AppColors.screenTextSecondary,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    ],
  );

  // ── Action buttons (quick actions) ─────────────────────────────────────────
  Widget _buildActionButtons(bool isDark) {
    final actions = ['informations'];
    return SizedBox(
      height: AppDimensions.getHorizontalMenuCardHeight(context),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 0),
        itemCount: actions.length,
        itemBuilder: (context, i) {
          final def = _kActions[actions[i]]!;
          return ImageMenuCard(
            index: i,
            cardKey: actions[i],
            title: def.label,
            iconData: def.icon,
            isDark: isDark,
            width: AppDimensions.getHorizontalMenuCardWidth(context),
            height: AppDimensions.getHorizontalMenuCardHeight(context),
            color: def.color,
            onTap: () => _showActionBottomSheet(actions[i], def),
            actionText: def.subtitle,
            actionTextColor: def.color,
            backgroundColor: def.color.withOpacity(0.1),
            textColor: isDark ? Colors.white : AppColors.screenTextPrimary,
          );
        },
      ),
    );
  }

  // ── Menu cards (3 sections thématiques) ────────────────────────────────────────────
  Widget _buildMenuCards(bool isDark) {
    // Section École (pédagogique)
    final ecoleActions = [
      EstablishmentAction(
        key: 'informations',
        title: 'Informations de l\'école',
        subtitle: 'Détails',
        imagePath: 'assets/images/ecole.jpg',
        color: _kActions['informations']!.color,
        actionText: 'Voir',
        onTap: () =>
            _showActionBottomSheet('informations', _kActions['informations']!),
      ),
      EstablishmentAction(
        key: 'niveaux',
        title: 'Nos niveaux scolaires',
        subtitle: 'Classes',
        imagePath: 'assets/images/niveau-scolaire.jpg',
        color: _kActions['niveaux']!.color,
        actionText: 'Voir',
        onTap: () => _showActionBottomSheet('niveaux', _kActions['niveaux']!),
      ),
      EstablishmentAction(
        key: 'consult_requests',
        title: 'Mes demandes',
        subtitle: 'Consulter',
        imagePath: 'assets/images/mes-demande.jpg',
        color: _kActions['consult_requests']!.color,
        actionText: 'Consulter',
        onTap: () => _showActionBottomSheet(
          'consult_requests',
          _kActions['consult_requests']!,
        ),
      ),
      EstablishmentAction(
        key: 'scolarite',
        title: 'Scolarité',
        subtitle: 'Frais',
        imagePath: 'assets/images/scolarite.jpg',
        color: _kActions['scolarite']!.color,
        actionText: 'Voir',
        onTap: () =>
            _showActionBottomSheet('scolarite', _kActions['scolarite']!),
      ),
    ];

    // Section Vie école (opérationnel)
    final vieEcoleActions = [
      EstablishmentAction(
        key: 'school_events',
        title: 'Événements scolaires',
        subtitle: 'Calendrier',
        imagePath: 'assets/images/school-event.jpg',
        color: _kActions['school_events']!.color,
        actionText: 'Voir',
        onTap: () => _showActionBottomSheet(
          'school_events',
          _kActions['school_events']!,
        ),
      ),
      EstablishmentAction(
        key: 'communication',
        title: 'Notre actualités',
        subtitle: 'Annonces',
        imagePath: 'assets/images/actualite-2.jpg',
        color: _kActions['communication']!.color,
        actionText: 'Voir',
        onTap: () => _showActionBottomSheet(
          'communication',
          _kActions['communication']!,
        ),
      ),
    ];

    // Section Communauté
    final communityActions = [
      EstablishmentAction(
        key: 'galeries',
        title: 'Galeries Écoles',
        subtitle: 'Découvrez nos galeries photos',
        imagePath: 'assets/images/messages.jpg',
        color: const Color(0xFF00796B),
        actionText: 'Voir galeries',
        onTap: () =>
            _showActionBottomSheet('galeries', _getActionDef('galeries')),
      ),
      EstablishmentAction(
        key: 'coulisses',
        title: 'Coulisses Excellence',
        subtitle: 'Les coulisses de notre excellence',
        iconData: Icons.star_rounded,
        color: const Color(0xFFD32F2F),
        actionText: 'Voir coulisses',
        onTap: () =>
            _showActionBottomSheet('coulisses', _getActionDef('coulisses')),
      ),
      EstablishmentAction(
        key: 'visites',
        title: 'Visites Guidées',
        subtitle: 'Explorez nos installations',
        iconData: Icons.location_on_rounded,
        color: const Color(0xFF3F51B5),
        actionText: 'Voir visites',
        onTap: () =>
            _showActionBottomSheet('visites', _getActionDef('visites')),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section École
        SectionRow(title: 'École'),
        const SizedBox(height: 8),
        EstablishmentActionSection(
          actions: ecoleActions,
          isDark: isDark,
          useExternalTitle: true,
          cardWidth: AppDimensions.getHorizontalMenuCardWidth(context) -20,
        ),
        const SizedBox(height: 8),

        // Section Vie école
        SectionRow(title: 'Vie école'),
        const SizedBox(height: 8),
        EstablishmentActionSection(
          actions: vieEcoleActions,
          isDark: isDark,
          useExternalTitle: true,
          cardWidth: AppDimensions.getHorizontalMenuCardWidth(context),
        ),
        const SizedBox(height: 10),

        // Section Communauté
        SectionRow(title: 'Communauté'),
        const SizedBox(height: 8),
        EstablishmentCommunitySection(
          actions: communityActions,
          isDark: isDark,
        ),
      ],
    );
  }

  String _getSchoolLocation() {
    // Essayer de récupérer la ville depuis les détails de l'école
    String? location = _ecoleDetail?.data.ville;

    // Si pas trouvé, essayer depuis l'adresse
    if (location == null || location.isEmpty) {
      final address = _ecoleDetail?.data.adresse ?? widget.ecole.adresse ?? '';
      // Extraire la ville de l'adresse (généralement à la fin)
      final parts = address.split(',');
      if (parts.isNotEmpty) {
        location = parts.last.trim();
      }
    }

    // Valeur par défaut si toujours pas trouvé
    if (location == null || location.isEmpty) {
      location = 'Côte d\'Ivoire';
    }

    return location.toUpperCase();
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  BOTTOM SHEET
  // ══════════════════════════════════════════════════════════════════════════
  _ActionDef _getActionDef(String actionKey) {
    return _kActions[actionKey] ?? _kActions['informations']!;
  }

  void _showActionBottomSheet(String actionType, _ActionDef def) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Déclencher le chargement si nécessaire
    if (actionType == 'voir_les_avis' && !_isLoadingAvis) {
      _loadAvisOnly();
    }
    if (actionType == 'school_events' &&
        !_isLoadingEvents &&
        _schoolEvents.isEmpty &&
        _eventsError == null) {
      _loadEventsOnly();
    }

    // Cas spécial : coulisses navigue directement vers l'écran TikTok
    if (actionType == 'coulisses') {
      final ecoleId = widget.ecole.id ?? 'gainhs';
      final ecoleNom = widget.ecole.parametreNom ?? 'Établissement';

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) =>
              CoulisseExcellenceScreen(ecoleId: ecoleId, ecoleNom: ecoleNom),
        ),
      );
      return;
    }

    // ── Bottom sheet générique pour tous les autres cas ──
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ValueListenableBuilder<int>(
        valueListenable: _avisNotifier,
        builder: (context, _, __) => ValueListenableBuilder<int>(
          valueListenable: _eventsNotifier,
          builder: (context, _, __) {
            return Container(
              constraints: BoxConstraints(
                minHeight: 100,
                maxHeight: MediaQuery.of(context).size.height * 0.9,
              ),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A1A1A) : AppColors.screenCard,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                boxShadow: AppDimensions.getCustomShadow(
                  context: context,
                  alpha: 0.12,
                  blurRadius: 24,
                  offset: -6,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                              borderRadius: BorderRadius.circular(
                                AppDimensions.getIconContainerBorderRadius(
                                  context,
                                ),
                              ),
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
                                color: def.color.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(
                                  AppDimensions.getMediumCardBorderRadius(
                                    context,
                                  ),
                                ),
                              ),
                              child: Icon(def.icon, color: def.color, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    def.label,
                                    style: TextStyle(
                                      fontSize: _textSizeService
                                          .getScaledFontSize(18),
                                      fontWeight: FontWeight.w800,
                                      color: isDark
                                          ? Colors.white
                                          : AppColors.screenTextPrimary,
                                      letterSpacing: -0.4,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    softWrap: false,
                                  ),
                                  Text(
                                    def.subtitle,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.screenTextSecondary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    softWrap: false,
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
                                  borderRadius: BorderRadius.circular(
                                    AppDimensions.getBadgeBorderRadius(context),
                                  ),
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
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                      child: _buildActionContent(actionType),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  Coulisses Excellence Content
  Widget _buildCoulissesContent() {
    // Récupérer l'ID de l'école
    final ecoleId = widget.ecole.id ?? 'gainhs'; // Valeur par défaut si null
    final ecoleNom = widget.ecole.parametreNom ?? 'Établissement';

    // Naviguer immédiatement vers l'écran TikTok-style
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) =>
              CoulisseExcellenceScreen(ecoleId: ecoleId, ecoleNom: ecoleNom),
        ),
      );
    });

    // Afficher un indicateur de chargement pendant la navigation
    return const Center(child: CircularProgressIndicator());
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  ACTION CONTENT ROUTER
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildActionContent(String actionType) {
    switch (actionType) {
      case 'rating':
        return _buildRatingForm();
      case 'recommend':
        return _buildRecommendationForm();
      case 'share':
        return _buildShareForm();
      case 'consult_requests':
        return _buildConsultRequestsContent();
      case 'informations':
        return _buildInformationsContent();
      case 'communication':
        return _buildCommunicationTab();
      case 'niveaux':
        return _buildLevelsTab();
      case 'school_events':
        return _buildEventsTab();
      case 'scolarite':
        return _buildScolariteTab();
      case 'voir_les_avis':
        return _buildRatingForm();
      case 'coulisses':
        return _buildCoulissesContent();
      default:
        return const Center(child: Text('Contenu non disponible'));
    }
  }

  // ── Recommendation form ────────────────────────────────────────────────────
  Widget _buildRecommendationForm() {
    final actionColor = _kActions['recommend']!.color;

    // Pré-remplir les données de l'établissement pour la soumission (non affichées)
    _etablissementController.text = widget.ecole.parametreNom ?? '';
    _paysController.text = 'Côte d\'Ivoire';
    _villeController.text = 'Abidjan';
    _ordreController.text = 'Primaire, collège';
    _adresseEtablissementController.text = 'Adjamé';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _formSectionCard(
          title: 'Vos informations',
          icon: Icons.person_rounded,
          children: [
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    label: 'Nom',
                    hint: 'Votre nom',
                    icon: Icons.person_rounded,
                    controller: _parentNomController,
                    required: true,
                    hasError: _parentNomError,
                    iconColor: actionColor,
                    focusBorderColor: actionColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomTextField(
                    label: 'Prénom',
                    hint: 'Votre prénom',
                    icon: Icons.person_outline_rounded,
                    controller: _parentPrenomController,
                    required: true,
                    hasError: _parentPrenomError,
                    iconColor: actionColor,
                    focusBorderColor: actionColor,
                  ),
                ),
              ],
            ),
            CustomTextField(
              label: 'Téléphone',
              hint: 'Votre numéro',
              icon: Icons.phone_rounded,
              controller: _parentTelephoneController,
              keyboardType: TextInputType.phone,
              required: true,
              hasError: _parentTelephoneError,
              iconColor: actionColor,
              focusBorderColor: actionColor,
            ),
            CustomTextField(
              label: 'Email',
              hint: 'Votre adresse email',
              icon: Icons.email_rounded,
              controller: _recommandationEmailController,
              keyboardType: TextInputType.emailAddress,
              required: true,
              hasError: _recommandationEmailError,
              iconColor: actionColor,
              focusBorderColor: actionColor,
            ),
            CustomTextField(
              label: 'Pays',
              hint: 'Votre pays',
              icon: Icons.public_rounded,
              controller: _parentPaysController,
              iconColor: actionColor,
              focusBorderColor: actionColor,
            ),
            CustomTextField(
              label: 'Ville',
              hint: 'Votre ville',
              icon: Icons.location_city_rounded,
              controller: _parentVilleController,
              iconColor: actionColor,
              focusBorderColor: actionColor,
            ),
            CustomTextField(
              label: 'Adresse',
              hint: 'Votre adresse',
              icon: Icons.home_rounded,
              controller: _parentAdresseController,
              iconColor: actionColor,
              focusBorderColor: actionColor,
            ),
          ],
        ),
        CustomFormButton(
          text: 'Envoyer la recommandation',
          color: AppColors.screenOrange,
          icon: Icons.recommend_rounded,
          onPressed: () async {
            // Validation AVANT d'afficher le loader
            if (_etablissementController.text.isEmpty ||
                _parentNomController.text.isEmpty ||
                _parentPrenomController.text.isEmpty ||
                _parentTelephoneController.text.isEmpty ||
                _recommandationEmailController.text.isEmpty) {
              CustomSnackBar.warning(
                context,
                'Veuillez remplir tous les champs obligatoires',
              );
              return;
            }

            showDialog(
              context: context,
              barrierDismissible: false,
              barrierColor: Colors.transparent,
              builder: (_) => CustomLoader(
                message: 'Envoi en cours...',
                loaderColor: AppColors.screenOrange,
                size: 56.0,
                showBackground: true,
                backgroundColor: Colors.white.withOpacity(0.9),
              ),
            );

            try {
              final result = await RecommendationService.submitRecommendation(
                etablissement: _etablissementController.text,
                pays: _paysController.text,
                ville: _villeController.text,
                ordre: _ordreController.text,
                adresseEtablissement: _adresseEtablissementController.text,
                nomParent: _parentNomController.text,
                prenomParent: _parentPrenomController.text,
                telephone: _parentTelephoneController.text,
                email: _recommandationEmailController.text,
                paysParent: _parentPaysController.text,
                villeParent: _parentVilleController.text,
                adresseParent: _parentAdresseController.text,
              );

              Navigator.of(context).pop(); // ferme le loader

              if (result['success'] == true) {
                _parentNomController.clear();
                _parentPrenomController.clear();
                _parentTelephoneController.clear();
                _recommandationEmailController.clear();
                Navigator.of(context).pop(); // ferme le bottom sheet
                await Future.delayed(const Duration(milliseconds: 300));
                _scaffoldMessengerKey.currentState?.showSnackBar(
                  SnackBar(
                    content: const Text('Recommandation envoyée avec succès!'),
                    backgroundColor: Colors.green[500],
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.getSmallCardBorderRadius(context),
                      ),
                    ),
                    margin: const EdgeInsets.all(16),
                  ),
                );
              } else {
                _scaffoldMessengerKey.currentState?.showSnackBar(
                  SnackBar(
                    content: Text(
                      result['message'] ?? 'Erreur lors de l\'envoi',
                    ),
                    backgroundColor: Colors.red[400],
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.getSmallCardBorderRadius(context),
                      ),
                    ),
                    margin: const EdgeInsets.all(16),
                  ),
                );
              }
            } catch (e) {
              Navigator.of(context).pop(); // ferme le loader
              _scaffoldMessengerKey.currentState?.showSnackBar(
                SnackBar(
                  content: Text('Erreur: $e'),
                  backgroundColor: Colors.red[400],
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      AppDimensions.getSmallCardBorderRadius(context),
                    ),
                  ),
                  margin: const EdgeInsets.all(16),
                ),
              );
            }
          },
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // ── Share form ─────────────────────────────────────────────────────────────
  Widget _buildShareForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.screenCard,
            borderRadius: BorderRadius.circular(
              AppDimensions.getLargeCardBorderRadius(context),
            ),
            boxShadow: const [
              BoxShadow(
                color: AppColors.screenShadow,
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.ecole.parametreNom ?? 'École',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.screenTextPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.ecole.adresse ?? '',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.screenTextSecondary,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildShareOption(
                    Icons.message,
                    'WhatsApp',
                    const Color(0xFF25D366),
                  ),
                  _buildShareOption(
                    Icons.email,
                    'Email',
                    const Color(0xFF4285F4),
                  ),
                  _buildShareOption(
                    Icons.link,
                    'Copier',
                    const Color(0xFF6366F1),
                  ),
                  _buildShareOption(
                    Icons.share,
                    'Réseaux',
                    AppColors.screenOrange,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildShareOption(IconData icon, String label, Color color) {
    return GestureDetector(
      onTap: () {},
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(
                AppDimensions.getMediumCardBorderRadius(context),
              ),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.screenTextSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  MENU CONTENT TABS  (Communication, Niveaux, Events, Scolarité, Notes)
  // ══════════════════════════════════════════════════════════════════════════

  // ── Communication tab ─────────────────────────────────────────────────────
  Widget _buildCommunicationTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Communication et Actualités',
          style: TextStyle(
            fontSize: _textSizeService.getScaledFontSize(20),
            fontWeight: FontWeight.bold,
            color: AppColors.screenTextPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Dernières communications de ${widget.ecole.parametreNom}',
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.screenTextSecondary,
          ),
        ),
        const SizedBox(height: 20),
        if (_isLoadingBlogs)
          const Center(
            child: CustomLoader(
              message: 'Chargement des communications...',
              loaderColor: AppColors.screenOrange,
              size: 56.0,
              showBackground: false,
            ),
          )
        else if (_blogsError != null)
          _buildTabError(_blogsError!, _loadBlogsEventsAndAvis)
        else if (_blogs.isEmpty)
          _buildTabEmpty(
            Icons.article_outlined,
            'Aucune communication',
            'Aucune communication disponible pour le moment.',
          )
        else
          ..._blogs.map((blog) => _buildBlogCard(blog)).toList(),
      ],
    );
  }

  Widget _buildBlogCard(Map<String, dynamic> blog) {
    final Color color = blog['color'] as Color? ?? AppColors.screenOrange;
    final String? imageUrl = blog['image'] as String?;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.screenCard,
        borderRadius: BorderRadius.circular(
          AppDimensions.getLargeCardBorderRadius(context),
        ),
        boxShadow: AppDimensions.getMainShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imageUrl != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              child: Image.network(
                imageUrl,
                width: double.infinity,
                height: 180,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: double.infinity,
                    height: 180,
                    color: isDark
                        ? const Color(0xFF2A2A2A)
                        : AppColors.screenCard,
                    child: Center(
                      child: Icon(
                        Icons.image_not_supported,
                        color: isDark
                            ? Colors.white54
                            : AppColors.screenTextSecondary,
                        size: 40,
                      ),
                    ),
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    width: double.infinity,
                    height: 180,
                    color: isDark
                        ? const Color(0xFF2A2A2A)
                        : AppColors.screenCard,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.screenOrange,
                        strokeWidth: 2,
                      ),
                    ),
                  );
                },
              ),
            )
          else
            Container(
              height: 100,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                gradient: LinearGradient(
                  colors: [color.withOpacity(0.8), color.withOpacity(0.4)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Icon(
                  blog['icon'] as IconData? ?? Icons.article,
                  size: 40,
                  color: Colors.white70,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(
                          AppDimensions.getSmallCardBorderRadius(context),
                        ),
                      ),
                      child: Text(
                        blog['type'] as String? ?? 'Actualité',
                        style: TextStyle(
                          fontSize: 10,
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      blog['date'] as String? ?? '',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.screenTextSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  blog['title'] as String? ?? 'Sans titre',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.screenTextPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  blog['content'] as String? ?? '',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.screenTextSecondary,
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(
                      Icons.person_outline,
                      size: 14,
                      color: AppColors.screenTextSecondary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        blog['auteur'] as String? ?? 'Administration',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.screenTextSecondary,
                        ),
                      ),
                    ),
                    if ((blog['establishment'] as String?)?.isNotEmpty ==
                        true) ...[
                      const Icon(
                        Icons.location_on_outlined,
                        size: 13,
                        color: AppColors.screenTextSecondary,
                      ),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          blog['establishment'] as String? ?? '',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.screenTextSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
    );
  }

  // ── Levels tab ─────────────────────────────────────────────────────────────
  Widget _buildLevelsTab() {
    final ecoleCode = widget.ecole.parametreCode ?? '';
    return FutureBuilder<List<Niveau>>(
      future: NiveauService.getNiveauxByEcole(ecoleCode),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CustomLoader(
              message: 'Chargement des niveaux...',
              loaderColor: AppColors.screenOrange,
              size: 56.0,
              showBackground: false,
            ),
          );
        }
        if (snapshot.hasError) {
          return _buildTabError(
            snapshot.error.toString(),
            () => setState(() {}),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildTabEmpty(
            Icons.school_outlined,
            'Aucun niveau disponible',
            'Cette école n\'a pas de niveaux configurés',
          );
        }
        final niveaux = snapshot.data!;
        final Map<String, Map<String, List<Niveau>>> grouped = {};
        for (final n in niveaux) {
          final filiere = (n.filiere?.isNotEmpty == true)
              ? n.filiere!
              : 'AUTRE';
          final niveauLabel = (n.niveau?.isNotEmpty == true)
              ? n.niveau!
              : n.nom ?? '?';
          grouped.putIfAbsent(filiere, () => {});
          grouped[filiere]!.putIfAbsent(niveauLabel, () => []);
          grouped[filiere]![niveauLabel]!.add(n);
        }
        final sortedFilieres = grouped.keys.toList()..sort();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Niveaux d\'enseignement',
              style: TextStyle(
                fontSize: _textSizeService.getScaledFontSize(20),
                fontWeight: FontWeight.bold,
                color: AppColors.screenTextPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${niveaux.length} classe${niveaux.length > 1 ? 's' : ''} disponible${niveaux.length > 1 ? 's' : ''}',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.screenTextSecondary,
              ),
            ),
            const SizedBox(height: 20),
            ...sortedFilieres.map((filiere) {
              final niveauxMap = grouped[filiere]!;
              final sortedNiveauKeys = niveauxMap.keys.toList()
                ..sort((a, b) {
                  final oA = niveauxMap[a]!
                      .map((e) => e.ordre ?? 99)
                      .reduce((x, y) => x < y ? x : y);
                  final oB = niveauxMap[b]!
                      .map((e) => e.ordre ?? 99)
                      .reduce((x, y) => x < y ? x : y);
                  return oA.compareTo(oB);
                });
              return _buildFiliereSection(
                filiere,
                sortedNiveauKeys,
                niveauxMap,
              );
            }).toList(),
          ],
        );
      },
    );
  }

  Widget _buildFiliereSection(
    String filiere,
    List<String> sortedNiveauKeys,
    Map<String, List<Niveau>> niveauxMap,
  ) {
    final color = _getFiliereColor(filiere);
    final totalClasses = niveauxMap.values.fold(0, (s, l) => s + l.length);
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: AppColors.screenCard,
        borderRadius: BorderRadius.circular(
          AppDimensions.getLargeCardBorderRadius(context),
        ),
        boxShadow: AppDimensions.getMainShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(
                      AppDimensions.getSmallCardBorderRadius(context),
                    ),
                  ),
                  child: Icon(
                    _getFiliereIcon(filiere),
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getFiliereLabel(filiere),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                      Text(
                        '$totalClasses classe${totalClasses > 1 ? 's' : ''} · ${sortedNiveauKeys.length} niveau${sortedNiveauKeys.length > 1 ? 'x' : ''}',
                        style: TextStyle(
                          fontSize: 12,
                          color: color.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(
                      AppDimensions.getLargeCardBorderRadius(context),
                    ),
                  ),
                  child: Text(
                    filiere,
                    style: TextStyle(
                      fontSize: 11,
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: sortedNiveauKeys.map((nl) {
                final classes = niveauxMap[nl]!
                  ..sort((a, b) => (a.ordre ?? 0).compareTo(b.ordre ?? 0));
                return _buildNiveauGroup(nl, classes, color);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNiveauGroup(
    String niveauLabel,
    List<Niveau> classes,
    Color color,
  ) {
    if (classes.length == 1) return _buildSingleClassTile(classes.first, color);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 14,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(
                      AppDimensions.getIconContainerBorderRadius(context),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  niveauLabel,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(
                      AppDimensions.getIconContainerBorderRadius(context),
                    ),
                  ),
                  child: Text(
                    '${classes.length} séries',
                    style: TextStyle(
                      fontSize: 10,
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: classes.map((c) => _buildClassChip(c, color)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSingleClassTile(Niveau niveau, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(
          AppDimensions.getSmallCardBorderRadius(context),
        ),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(
                AppDimensions.getBadgeBorderRadius(context),
              ),
            ),
            child: Center(
              child: Text(
                (niveau.nom ?? '?').substring(
                  0,
                  (niveau.nom?.length ?? 0).clamp(0, 2),
                ),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  niveau.nom ?? 'Classe',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.screenTextPrimary,
                  ),
                ),
                if (niveau.niveau != null && niveau.niveau!.isNotEmpty)
                  Text(
                    'Niveau : ${niveau.niveau}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.screenTextSecondary,
                    ),
                  ),
              ],
            ),
          ),
          if (niveau.code != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(
                  AppDimensions.getIconContainerBorderRadius(context),
                ),
              ),
              child: Text(
                niveau.code!,
                style: TextStyle(
                  fontSize: 10,
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildClassChip(Niveau niveau, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(
          AppDimensions.getBadgeBorderRadius(context),
        ),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            niveau.nom ?? '?',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          if (niveau.serie != null && niveau.serie!.isNotEmpty)
            Text(
              'Série ${niveau.serie}',
              style: TextStyle(fontSize: 10, color: color.withOpacity(0.7)),
            ),
        ],
      ),
    );
  }

  Color _getFiliereColor(String f) {
    switch (f.toUpperCase()) {
      case 'PRIMAIRE':
        return const Color(0xFF3B82F6);
      case 'GENERAL':
        return const Color(0xFF8B5CF6);
      case 'TECHNIQUE':
        return const Color(0xFF10B981);
      case 'PROFESSIONNEL':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF6366F1);
    }
  }

  IconData _getFiliereIcon(String f) {
    switch (f.toUpperCase()) {
      case 'PRIMAIRE':
        return Icons.child_care_rounded;
      case 'GENERAL':
        return Icons.menu_book_rounded;
      case 'TECHNIQUE':
        return Icons.precision_manufacturing_rounded;
      case 'PROFESSIONNEL':
        return Icons.work_rounded;
      default:
        return Icons.school_rounded;
    }
  }

  String _getFiliereLabel(String f) {
    switch (f.toUpperCase()) {
      case 'PRIMAIRE':
        return 'Enseignement Primaire';
      case 'GENERAL':
        return 'Enseignement Général';
      case 'TECHNIQUE':
        return 'Enseignement Technique';
      case 'PROFESSIONNEL':
        return 'Enseignement Professionnel';
      default:
        return f;
    }
  }

  // ── Events tab ─────────────────────────────────────────────────────────────
  Widget _buildEventsTab() {
    // Ne plus recharger automatiquement les événements ici
    // Ils sont maintenant chargés uniquement lors du clic sur le bouton

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Événements scolaires',
          style: TextStyle(
            fontSize: _textSizeService.getScaledFontSize(20),
            fontWeight: FontWeight.bold,
            color: AppColors.screenTextPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Découvrez les événements de ${widget.ecole.parametreNom}',
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.screenTextSecondary,
          ),
        ),
        const SizedBox(height: 20),
        if (_isLoadingEvents)
          const Center(
            child: CustomLoader(
              message: 'Chargement des événements...',
              loaderColor: AppColors.screenOrange,
              size: 56.0,
              showBackground: false,
            ),
          )
        else if (_eventsError != null)
          _buildTabError(_eventsError!, _loadBlogsEventsAndAvis)
        else if (_schoolEvents.isEmpty)
          _buildTabEmpty(
            Icons.event_outlined,
            'Aucun événement',
            'Aucun événement disponible pour le moment.',
          )
        else
          Column(
            children: [
              // Liste des événements
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _schoolEvents.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, i) => _buildEventCard(_schoolEvents[i]),
              ),

              // Bouton "Voir plus" ou indicateur de fin
              if (_hasMoreEvents && !_isLoadingMoreEvents)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: GestureDetector(
                      onTap: _loadMoreEvents,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.screenOrange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(
                            AppDimensions.getMediumCardBorderRadius(context),
                          ),
                          border: Border.all(
                            color: AppColors.screenOrange.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.expand_more,
                              color: AppColors.screenOrange,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Voir plus',
                              style: TextStyle(
                                color: AppColors.screenOrange,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

              // Indicateur de chargement
              if (_isLoadingMoreEvents)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: CustomLoader(
                      message: 'Chargement...',
                      loaderColor: AppColors.screenOrange,
                      size: 32.0,
                      showBackground: false,
                    ),
                  ),
                ),

              // Indicateur de fin de liste
              if (!_hasMoreEvents && _schoolEvents.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Text(
                      'Fin des événements',
                      style: TextStyle(
                        color: AppColors.screenTextSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
    final Color color = event['color'] as Color? ?? AppColors.screenOrange;
    final String? imageUrl = event['image'] as String?;
    final bool isAvailable = event['available'] as bool? ?? true;
    final String title = event['title'] as String? ?? '';
    final String subtitle =
        event['subtitle'] as String? ?? event['establishment'] as String? ?? '';
    final String price = event['price'] as String? ?? 'Gratuit';
    final String date = event['date'] as String? ?? '';

    return Container(
      margin: EdgeInsets.only(
        bottom: AppDimensions.getEventCardSpacing(context),
      ),
      decoration: BoxDecoration(
        color: AppColors.screenCard,
        borderRadius: BorderRadius.circular(
          AppDimensions.getLargeCardBorderRadius(context),
        ),
        boxShadow: AppDimensions.getMainShadow(context),
      ),
      child: Padding(
        padding: EdgeInsets.all(AppDimensions.getEventCardPadding(context)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image (taille responsive) ───────────────────
            ClipRRect(
              borderRadius: BorderRadius.circular(
                AppDimensions.getMediumCardBorderRadius(context),
              ),
              child: Container(
                width: AppDimensions.getEventImageSize(context),
                height: AppDimensions.getEventImageSize(context),
                color: const Color(0xFFF5F5F5),
                child: Stack(
                  children: [
                    imageUrl != null
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            width: AppDimensions.getEventImageSize(context),
                            height: AppDimensions.getEventImageSize(context),
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.image_not_supported_outlined,
                              color: Color(0xFFCCCCCC),
                              size: 30,
                            ),
                          )
                        : Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  color.withOpacity(0.85),
                                  color.withOpacity(0.45),
                                ],
                              ),
                            ),
                            child: Icon(
                              event['icon'] as IconData? ?? Icons.event_rounded,
                              color: Colors.white.withOpacity(0.9),
                              size: 30,
                            ),
                          ),

                    // Badge COMPLET
                    if (!isAvailable)
                      Positioned(
                        top: 4,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444),
                              borderRadius: BorderRadius.circular(
                                AppDimensions.getIconContainerBorderRadius(
                                  context,
                                ),
                              ),
                            ),
                            child: const Text(
                              'COMPLET',
                              style: TextStyle(
                                fontSize: 7,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 14),

            // ── Infos (droite) ────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: AppDimensions.getEventTitleFontSize(
                              context,
                            ),
                            fontWeight: FontWeight.w700,
                            color: AppColors.screenTextPrimary,
                            letterSpacing: -0.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Icône info
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(
                            AppDimensions.getSmallCardBorderRadius(context),
                          ),
                        ),
                        child: Icon(
                          Icons.info_outline_rounded,
                          size: 14,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: AppDimensions.getEventSubtitleFontSize(context),
                      color: AppColors.screenTextSecondary,
                      fontWeight: FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text(
                        price,
                        style: TextStyle(
                          fontSize: AppDimensions.getEventTitleFontSize(
                            context,
                          ),
                          color: isAvailable
                              ? color
                              : AppColors.screenTextSecondary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      // Badge date
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(
                            AppDimensions.getIconContainerBorderRadius(context),
                          ),
                        ),
                        child: Text(
                          date,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTicketPurchaseDialog(Map<String, dynamic> event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            AppDimensions.getLargeCardBorderRadius(context),
          ),
        ),
        title: Text(
          'Achat de ticket\n${event['title']}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Date: ${event['date']}'),
            Text('Lieu: ${event['location'] ?? event['establishment']}'),
            Text('Prix: ${event['price']}'),
            const SizedBox(height: 16),
            const Text(
              'Nombre de tickets :',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton(
                  onPressed: () {},
                  icon: const Icon(
                    Icons.remove_circle_outline,
                    color: AppColors.screenOrange,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.screenOrange),
                    borderRadius: BorderRadius.circular(
                      AppDimensions.getSmallCardBorderRadius(context),
                    ),
                  ),
                  child: const Text(
                    '1',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(
                    Icons.add_circle_outline,
                    color: AppColors.screenOrange,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Annuler',
              style: TextStyle(color: AppColors.screenTextSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Ticket acheté avec succès!'),
                  backgroundColor: Colors.green[500],
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      AppDimensions.getSmallCardBorderRadius(context),
                    ),
                  ),
                  margin: const EdgeInsets.all(16),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.screenOrange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  AppDimensions.getSmallCardBorderRadius(context),
                ),
              ),
            ),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  // ── Scolarité tab ──────────────────────────────────────────────────────────
  Widget _buildScolariteTab() {
    if (_scolariteFuture == null) {
      return const Center(
        child: CustomLoader(
          message: 'Chargement de la scolarité...',
          loaderColor: AppColors.screenOrange,
          size: 56.0,
          showBackground: false,
        ),
      );
    }

    return FutureBuilder<ScolariteResponse>(
      future: _scolariteFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CustomLoader(
              message: 'Chargement de la scolarité...',
              loaderColor: AppColors.screenOrange,
              size: 56.0,
              showBackground: false,
            ),
          );
        }
        if (snapshot.hasError) {
          return _buildTabError(snapshot.error.toString(), () {
            setState(() {
              _scolariteFuture = ScolariteService.getScolaritesByEcole(
                widget.ecole.parametreCode ?? '',
              );
            });
          });
        }
        if (!snapshot.hasData || snapshot.data!.data.isEmpty) {
          return _buildTabEmpty(
            Icons.account_balance_wallet_outlined,
            'Aucun frais de scolarité',
            'Cette école n\'a pas de frais configurés',
          );
        }
        final scolarites = ScolariteService.filtrerEtTrierScolarites(
          snapshot.data!.data,
        );
        final scolaritesParBranche = ScolariteService.grouperParBranche(
          scolarites,
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Frais de scolarité',
              style: TextStyle(
                fontSize: _textSizeService.getScaledFontSize(20),
                fontWeight: FontWeight.bold,
                color: AppColors.screenTextPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Frais par branche et statut',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.screenTextSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: AppColors.screenSurface,
                borderRadius: BorderRadius.circular(
                  AppDimensions.getSmallCardBorderRadius(context),
                ),
                border: Border.all(color: AppColors.screenDivider),
              ),
              child: TextField(
                controller: _searchController,
                focusNode: FocusNode(),
                autofocus: false,
                textInputAction: TextInputAction.search,
                onChanged: (v) {
                  setState(() => _searchQuery = v.toLowerCase());
                },
                decoration: InputDecoration(
                  hintText: 'Rechercher un niveau...',
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppColors.screenOrange,
                    size: 20,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            setState(() => _searchQuery = '');
                            _searchController.clear();
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  hintStyle: const TextStyle(
                    color: Color(0xFFBBBBBB),
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ...scolaritesParBranche.entries
                .where(
                  (e) =>
                      _searchQuery.isEmpty ||
                      e.key.toLowerCase().contains(_searchQuery),
                )
                .map(
                  (e) => StatefulBuilder(
                    builder: (context, setState) {
                      String? expandedBranche = _expandedBranche;
                      return _buildBrancheSection(
                        e.key,
                        e.value,
                        setState,
                        expandedBranche,
                        (newValue) {
                          setState(() => expandedBranche = newValue);
                          setState(() => _expandedBranche = newValue);
                        },
                      );
                    },
                  ),
                )
                .toList(),
          ],
        );
      },
    );
  }

  Widget _buildBrancheSection(
    String branche,
    List<Scolarite> scolarites,
    StateSetter setState,
    String? expandedBranche,
    Function(String?) onExpandedChanged,
  ) {
    final scolaritesParStatut = ScolariteService.separerParStatut(scolarites);
    final affectes = scolaritesParStatut['AFF'] ?? [];
    final nonAffectes = scolaritesParStatut['NAFF'] ?? [];
    final totaux = ScolariteService.calculerTotauxParStatut(scolarites);
    final isExpanded = expandedBranche == branche;
    return GestureDetector(
      onTap: () => onExpandedChanged(isExpanded ? null : branche),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(
            AppDimensions.getLargeCardBorderRadius(context),
          ),
          boxShadow: AppDimensions.getMainShadow(context),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(
                            AppDimensions.getSmallCardBorderRadius(context),
                          ),
                          // border: Border.all(
                          //   color: Colors.grey.withOpacity(0.3),
                          //   width: 1,
                          // ),
                        ),
                        child: Icon(
                          Icons.school_rounded,
                          color: Colors.grey[600],
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              branche,
                              style: TextStyle(
                                fontSize: _textSizeService.getScaledFontSize(
                                  16,
                                ),
                                fontWeight: FontWeight.w700,
                                color: AppColors.screenOrange,
                              ),
                            ),
                            Text(
                              '${scolarites.length} frais',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.screenTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      AnimatedRotation(
                        turns: isExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 300),
                        child: Icon(
                          Icons.expand_more,
                          color: Colors.grey[600],
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(
                        AppDimensions.getBadgeBorderRadius(context),
                      ),
                      border: Border.all(color: Colors.grey.withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildTotalItem(
                          'Affectés',
                          totaux['AFF'] ?? 0,
                          const Color(0xFF3B82F6),
                          Icons.check_circle_rounded,
                        ),
                        Container(
                          width: 1,
                          height: 30,
                          color: AppColors.screenDivider,
                        ),
                        _buildTotalItem(
                          'Non Affectés',
                          totaux['NAFF'] ?? 0,
                          const Color(0xFFEF4444),
                          Icons.remove_circle_rounded,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeInOut,
              child: isExpanded
                  ? Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (affectes.isNotEmpty) ...[
                            _buildStatutSection(
                              title: 'Montants affectés',
                              scolarites: affectes,
                              color: const Color(0xFF3B82F6),
                              isAffecte: true,
                              totalMontant: totaux['AFF'] ?? 0,
                            ),
                            const SizedBox(height: 16),
                          ],
                          if (nonAffectes.isNotEmpty)
                            _buildStatutSection(
                              title: 'Montants non affectés',
                              scolarites: nonAffectes,
                              color: const Color(0xFFEF4444),
                              isAffecte: false,
                              totalMontant: totaux['NAFF'] ?? 0,
                            ),
                        ],
                      ),
                    )
                  : const SizedBox(width: double.infinity, height: 0),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalItem(
    String label,
    int montant,
    Color color,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: color.withOpacity(0.8),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          ScolariteService.formaterMontant(montant),
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildStatutSection({
    required String title,
    required List<Scolarite> scolarites,
    required Color color,
    required bool isAffecte,
    required int totalMontant,
  }) {
    final scolaritesParRubrique = ScolariteService.separerParRubrique(
      scolarites,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(
              AppDimensions.getBadgeBorderRadius(context),
            ),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(
                    AppDimensions.getIconContainerBorderRadius(context),
                  ),
                ),
                child: Text(
                  ScolariteService.formaterMontant(totalMontant),
                  style: TextStyle(
                    fontSize: 10,
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        ...scolaritesParRubrique.entries.map((entry) {
          if (entry.value.isEmpty) return const SizedBox.shrink();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 6),
                child: Text(
                  entry.key == 'INS' ? 'Inscription' : 'Scolarité',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.screenTextSecondary,
                  ),
                ),
              ),
              ...entry.value.map((s) => _buildScolariteCard(s, color)).toList(),
              const SizedBox(height: 8),
            ],
          );
        }).toList(),
      ],
    );
  }

  Widget _buildScolariteCard(Scolarite scolarite, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6, left: 8, right: 8),
      decoration: BoxDecoration(
        color: AppColors.screenSurface,
        borderRadius: BorderRadius.circular(
          AppDimensions.getBadgeBorderRadius(context),
        ),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(
              AppDimensions.getSmallCardBorderRadius(context),
            ),
          ),
          child: Icon(
            scolarite.rubrique == 'INS'
                ? Icons.how_to_reg_rounded
                : Icons.menu_book_rounded,
            color: color,
            size: 16,
          ),
        ),
        title: Text(
          ScolariteService.formaterMontant(scolarite.totalMontant ?? 0),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppColors.screenTextPrimary,
          ),
        ),
        subtitle: Text(
          'Date limite: ${scolarite.dateLimiteFormatee}',
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.screenTextSecondary,
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(
              AppDimensions.getIconContainerBorderRadius(context),
            ),
          ),
          child: Text(
            ScolariteService.getStatutLibelle(scolarite.statut),
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  // ── Widget pour afficher les étoiles de rating ───────────────────────────────────
  Widget _buildStarRating(int rating, Color color, [double size = 20]) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star : Icons.star_border,
          size: size,
          color: index < rating ? color : color.withOpacity(0.3),
        );
      }),
    );
  }

  Widget _buildAvisCard(Map<String, dynamic> avi) {
    final Color color = avi['color'] as Color? ?? AppColors.screenOrange;
    final int statut = avi['statut'] as int? ?? 0;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.screenCard,
        borderRadius: BorderRadius.circular(
          AppDimensions.getLargeCardBorderRadius(context),
        ),
        boxShadow: AppDimensions.getMainShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(
                      AppDimensions.getMediumCardBorderRadius(context),
                    ),
                  ),
                  child: Icon(
                    avi['icon'] as IconData? ?? Icons.person_rounded,
                    color: color,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              avi['auteur'] as String? ?? '',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.screenTextPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        avi['date'] as String? ?? '',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.screenTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildStarRating(statut, color),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(0, 0, 24, 0),
                        child: Text(
                          avi['content'] as String? ?? '',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.screenTextPrimary,
                            height: 1.5,
                          ),
                        ),
                      ),
                      if (avi['image'] != null &&
                          (avi['image'] as String).isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(
                              AppDimensions.getSmallCardBorderRadius(context),
                            ),
                            child: Image.network(
                              avi['image'] as String,
                              width: double.infinity,
                              height: 180,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: double.infinity,
                                  height: 180,
                                  color: isDark
                                      ? const Color(0xFF2A2A2A)
                                      : AppColors.screenCard,
                                  child: Center(
                                    child: Icon(
                                      Icons.image_not_supported,
                                      color: isDark
                                          ? Colors.white54
                                          : AppColors.screenTextSecondary,
                                      size: 40,
                                    ),
                                  ),
                                );
                              },
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Container(
                                      width: double.infinity,
                                      height: 180,
                                      color: isDark
                                          ? const Color(0xFF2A2A2A)
                                          : AppColors.screenCard,
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          color: AppColors.screenOrange,
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    );
                                  },
                            ),
                          ),
                        ),
                      // Padding(
                      //   padding: const EdgeInsets.all(16),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Convert date format (JJ/MM/AAAA to AAAA-MM-JJ) ───────────────────────
  String _convertDateFormat(String inputDate) {
    if (inputDate.isEmpty) return '';

    // Remove any spaces and validate format
    final cleanedDate = inputDate.replaceAll(' ', '');
    final dateRegex = RegExp(r'^(\d{2})/(\d{2})/(\d{4})$');

    if (!dateRegex.hasMatch(cleanedDate)) {
      return inputDate; // Return original if format is invalid
    }

    final match = dateRegex.firstMatch(cleanedDate)!;
    final day = match.group(1)!;
    final month = match.group(2)!;
    final year = match.group(3)!;

    return '$year-$month-$day';
  }

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
            borderRadius: BorderRadius.circular(
              AppDimensions.getHeroCardBorderRadius(context),
            ),
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
              // Icône succès
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
                  boxShadow: AppDimensions.getCustomShadow(
                    context: context,
                    alpha: 0.3,
                    blurRadius: 16,
                    offset: 6,
                  ),
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 36,
                ),
              ),
              const SizedBox(height: 20),

              // Titre
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

              // Sous-titre
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

              // Numéro de suivi
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FF),
                  borderRadius: BorderRadius.circular(
                    AppDimensions.getMediumCardBorderRadius(context),
                  ),
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
                            borderRadius: BorderRadius.circular(
                              AppDimensions.getSmallCardBorderRadius(context),
                            ),
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
                    Text(
                      demandeUid,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.screenOrange,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Bouton
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
                      borderRadius: BorderRadius.circular(
                        AppDimensions.getMediumCardBorderRadius(context),
                      ),
                    ),
                  ),
                  child: const Text(
                    'OK, j\'ai compris',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Tab helpers ────────────────────────────────────────────────────────────
  Widget _buildTabError(String error, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.error_outline_rounded, size: 56, color: Colors.red[300]),
            const SizedBox(height: 12),
            const Text(
              'Erreur de chargement',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.screenTextPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              error,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.screenTextSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.screenOrange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    AppDimensions.getSmallCardBorderRadius(context),
                  ),
                ),
              ),
              child: const Text(
                'Réessayer',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabEmpty(IconData icon, String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.screenOrangeLight,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: AppColors.screenOrange),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.screenTextPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.screenTextSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  FORMS
  // ══════════════════════════════════════════════════════════════════════════

  // ── Shared form field helpers ─────────────────────────────────────────────
  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      children: [
        Icon(Icons.circle, size: 6, color: AppColors.screenOrange),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.screenTextPrimary,
            letterSpacing: -0.2,
          ),
        ),
      ],
    ),
  );

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
          value: value,
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
            hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFBBBBBB)),
            prefixIcon: Icon(icon, color: AppColors.screenOrange, size: 18),
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
                  child: Icon(icon, color: AppColors.screenOrange, size: 18),
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

  void _showFilePickerMessage(String fileType) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sélection de fichier pour: $fileType'),
        backgroundColor: AppColors.screenOrange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            AppDimensions.getSmallCardBorderRadius(context),
          ),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ── Rating form (Style WhatsApp) ────────────────────────────────────────────────────// Rating form - utilise le widget externalisé RatingBottomSheet
  Widget _buildRatingForm() {
    return RatingBottomSheet(
      schoolId: widget.ecole.id ?? '',
      schoolName: widget.ecole.parametreNom ?? 'Établissement',
      schoolColor: _getSchoolColor(),
      onRatingSubmitted: (rating, comment) async {
        // Logique de soumission d'avis - à adapter selon votre API
        await _submitRating(rating, comment);
      },
    );
  }

  // Helper pour obtenir la couleur de l'école
  Color _getSchoolColor() {
    // Adapter selon votre logique de couleur
    switch (widget.ecole.type?.toLowerCase()) {
      case 'primaire':
        return AppColors.screenOrange;
      case 'collège':
      case 'college':
        return AppColors.screenBlue;
      case 'lycée':
        return AppColors.screenPurple;
      default:
        return AppColors.screenOrange;
    }
  }

  // Soumission d'avis - à implémenter selon votre API
  Future<void> _submitRating(String rating, String comment) async {
    try {
      // Implémenter votre logique d'envoi d'avis ici
      // Exemple: await RatingService.submitRating(widget.ecole.id, rating, comment);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Avis envoyé avec succès!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l\'envoi: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ── Bulle d'avis (style WhatsApp) ───────────────────────────────────────────────────
  Widget _buildAvisBubble(Map<String, dynamic> avis) {
    final String auteur = avis['auteur'] ?? 'Anonyme';
    final String contenu = avis['content'] ?? '';
    final int note = avis['statut'] ?? 0;
    final String date = avis['date'] ?? '';
    final Color color = avis['color'] as Color? ?? AppColors.screenOrange;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar de l'école (toujours à gauche)
          Container(
            width: 32,
            height: 32,
            margin: const EdgeInsets.only(right: 8, bottom: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.school_outlined, size: 16, color: color),
          ),
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(4),
                  bottomRight: Radius.circular(18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // En-tête avec nom et étoiles
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          auteur,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0288D1),
                          ),
                        ),
                      ),
                      _buildStarRating(note, const Color(0xFFF59E0B), 16),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Contenu du message
                  Text(
                    contenu,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: AppColors.screenTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Date
                  Text(
                    _formatAvisDate(date),
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.screenTextSecondary,
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

  // ── Barre de composition (style WhatsApp) ───────────────────────────────────────────
  Widget _buildComposeAvisBar() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(
        8,
        8,
        8,
        MediaQuery.of(context).padding.bottom + 8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Sélection des étoiles
          StatefulBuilder(
            builder: (context, setState) {
              final currentRating = int.tryParse(_ratingController.text) ?? 0;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Text(
                      'Votre note:',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.screenTextSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 12),
                    ...List.generate(5, (index) {
                      return GestureDetector(
                        onTap: () => setState(() {
                          _ratingController.text = (index + 1).toString();
                        }),
                        child: Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Icon(
                            index < currentRating
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            size: 24,
                            color: index < currentRating
                                ? const Color(0xFFF59E0B)
                                : const Color(0xFFDDDDDD),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              );
            },
          ),
          // Barre de texte et envoi
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Champ de texte
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(
                    minHeight: 44,
                    maxHeight: 100,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: const Color(0xFFE8E8E8),
                      width: 0.5,
                    ),
                  ),
                  child: TextField(
                    controller: _commentController,
                    maxLines: null,
                    textInputAction: TextInputAction.newline,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.screenTextPrimary,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Votre avis...',
                      hintStyle: TextStyle(
                        fontSize: 14,
                        color: Color(0xFFBBBBBB),
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Bouton d'envoi
              GestureDetector(
                onTap: _sendAvis,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0288D1),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0288D1).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.send_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Vue d'erreur ────────────────────────────────────────────────────────────────
  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
            const SizedBox(height: 16),
            const Text(
              'Erreur de chargement',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.screenTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _avisError!,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.screenTextSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadAvisOnly,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0288D1),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Formatage de date pour avis ───────────────────────────────────────────────────
  String _formatAvisDate(String dateString) {
    try {
      if (dateString.isEmpty) return '';
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inDays == 0) {
        return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      }
      if (diff.inDays == 1) return 'Hier';
      if (diff.inDays < 7) return 'Il y a ${diff.inDays}j';
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  // ── Envoi d'avis ───────────────────────────────────────────────────────────────────
  Future<void> _sendAvis() async {
    final rating = _ratingController.text.trim();
    final comment = _commentController.text.trim();

    if (rating.isEmpty || comment.isEmpty) {
      _showAvisError('Veuillez donner une note et écrire un commentaire');
      return;
    }

    final currentUser = AuthService().getCurrentUser();
    if (currentUser == null || currentUser.phone.isEmpty) {
      _showAvisError('Utilisateur non connecté');
      return;
    }

    // Ajout optimiste
    final optimisticAvis = {
      'auteur': currentUser.fullName,
      'content': comment,
      'statut': int.parse(rating),
      'date': DateTime.now().toIso8601String(),
      'color': const Color(0xFF0288D1),
    };

    setState(() {
      _avis = [optimisticAvis, ..._avis];
      _ratingController.clear();
      _commentController.clear();
    });

    try {
      final result = await TestimonialService.submitTestimonial(
        codeecole: widget.ecole.parametreCode ?? '',
        note: rating,
        contenu: comment,
        userNumero: currentUser.phone,
      );

      if (result['success'] != true) {
        // Retirer l'avis optimiste en cas d'erreur
        setState(() {
          _avis = _avis.where((a) => a != optimisticAvis).toList();
        });
        _showAvisError(result['message'] ?? 'Erreur lors de l\'envoi');
      } else {
        _showAvisSuccess('Avis envoyé avec succès !');
        // Recharger les avis pour avoir les données à jour
        await _loadAvisOnly();
      }
    } catch (e) {
      // Retirer l'avis optimiste en cas d'exception
      setState(() {
        _avis = _avis.where((a) => a != optimisticAvis).toList();
      });
      _showAvisError('Erreur: $e');
    }
  }

  void _showAvisError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.red[400],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: MediaQuery.of(context).padding.bottom + 80,
        ),
      ),
    );
  }

  void _showAvisSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.green[500],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: MediaQuery.of(context).padding.bottom + 80,
        ),
      ),
    );
  }

  // ── Informations content ───────────────────────────────────────────────────
  Widget _buildInformationsContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSimplifiedOverviewSection(),
        const SizedBox(height: 16),
        _buildContactInfoSection(),
        const SizedBox(height: 16),
        _buildAcademicInfoSection(),
        const SizedBox(height: 20),
      ],
    );
  }

  // ── Overview section ────────────────────────────────────────────────────────
  Widget _buildSimplifiedOverviewSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.screenOrange.withOpacity(0.08),
            AppColors.screenOrange.withOpacity(0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(
          AppDimensions.getLargeCardBorderRadius(context),
        ),
        border: Border.all(color: AppColors.screenOrange.withOpacity(0.15)),
        boxShadow: AppDimensions.getLightShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.screenOrange,
                  borderRadius: BorderRadius.circular(
                    AppDimensions.getSmallCardBorderRadius(context),
                  ),
                ),
                child: const Icon(
                  Icons.school_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Aperçu',
                      style: TextStyle(
                        fontSize: _textSizeService.getScaledFontSize(18),
                        fontWeight: FontWeight.bold,
                        color: AppColors.screenOrange,
                      ),
                    ),
                    Text(
                      widget.ecole.parametreNom ?? 'Établissement',
                      style: TextStyle(
                        fontSize: _textSizeService.getScaledFontSize(13),
                        color: AppColors.screenTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Type',
                  widget.ecole.typePrincipal,
                  Icons.category_rounded,
                  _getTypeColor(widget.ecole.typePrincipal),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Statut',
                  widget.ecole.statut ?? 'Actif',
                  Icons.verified_rounded,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.screenCard,
              borderRadius: BorderRadius.circular(
                AppDimensions.getSmallCardBorderRadius(context),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Description',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.screenTextPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.ecole.parametreNom ?? 'Aucune description disponible',
                  style: TextStyle(
                    fontSize: _textSizeService.getScaledFontSize(13),
                    color: AppColors.screenTextSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.screenCard,
        borderRadius: BorderRadius.circular(
          AppDimensions.getSmallCardBorderRadius(context),
        ),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: AppDimensions.getLightShadow(context),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(
                AppDimensions.getSmallCardBorderRadius(context),
              ),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: _textSizeService.getScaledFontSize(9),
                    color: color.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: _textSizeService.getScaledFontSize(11),
                    fontWeight: FontWeight.bold,
                    color: AppColors.screenTextPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Contact section ────────────────────────────────────────────────────────
  Widget _buildContactSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF3B82F6).withOpacity(0.08),
            const Color(0xFF3B82F6).withOpacity(0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(
          AppDimensions.getLargeCardBorderRadius(context),
        ),
        border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.15)),
        boxShadow: AppDimensions.getLightShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6),
                  borderRadius: BorderRadius.circular(
                    AppDimensions.getSmallCardBorderRadius(context),
                  ),
                ),
                child: const Icon(
                  Icons.contact_phone_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Contact',
                      style: TextStyle(
                        fontSize: _textSizeService.getScaledFontSize(18),
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF3B82F6),
                      ),
                    ),
                    Text(
                      'Informations de contact',
                      style: TextStyle(
                        fontSize: _textSizeService.getScaledFontSize(13),
                        color: AppColors.screenTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildContactInfoCard(
            'Adresse',
            '${widget.ecole.adresse ?? 'Non disponible'}, ${widget.ecole.ville ?? ''}, ${widget.ecole.pays ?? ''}',
            Icons.location_on_rounded,
            const Color(0xFF3B82F6),
          ),
          const SizedBox(height: 8),
          if (widget.ecole.telephone?.isNotEmpty == true) ...[
            _buildContactInfoCard(
              'Téléphone',
              widget.ecole.telephone!,
              Icons.phone_rounded,
              Colors.green,
            ),
            const SizedBox(height: 8),
          ],
          FutureBuilder<EcoleDetail>(
            future: EcoleApiService.getEcoleDetail(
              widget.ecole.parametreCode ?? '',
            ),
            builder: (_, snap) {
              if (!snap.hasData) return const SizedBox.shrink();
              final d = snap.data!.data;
              return Column(
                children: [
                  if (d.email?.isNotEmpty == true) ...[
                    _buildContactInfoCard(
                      'Email',
                      d.email!,
                      Icons.email_rounded,
                      Colors.orange,
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (d.site?.isNotEmpty == true)
                    _buildContactInfoCard(
                      'Site web',
                      d.site!,
                      Icons.web_rounded,
                      Colors.purple,
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfoCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.screenCard,
        borderRadius: BorderRadius.circular(
          AppDimensions.getBadgeBorderRadius(context),
        ),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(
                AppDimensions.getSmallCardBorderRadius(context),
              ),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: _textSizeService.getScaledFontSize(11),
                    fontWeight: FontWeight.w600,
                    color: AppColors.screenTextSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: _textSizeService.getScaledFontSize(12),
                    color: AppColors.screenTextPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Info section ───────────────────────────────────────────────────────────
  Widget _buildInfoSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green.withOpacity(0.08),
            Colors.green.withOpacity(0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(
          AppDimensions.getLargeCardBorderRadius(context),
        ),
        border: Border.all(color: Colors.green.withOpacity(0.15)),
        boxShadow: AppDimensions.getLightShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(
                    AppDimensions.getSmallCardBorderRadius(context),
                  ),
                ),
                child: const Icon(
                  Icons.info_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Informations',
                      style: TextStyle(
                        fontSize: _textSizeService.getScaledFontSize(18),
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    Text(
                      'Détails administratifs',
                      style: TextStyle(
                        fontSize: _textSizeService.getScaledFontSize(13),
                        color: AppColors.screenTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoDetailCard(
            'Code établissement',
            widget.ecole.parametreCode ?? 'Non disponible',
            Icons.code_rounded,
            const Color(0xFF3B82F6),
          ),
          const SizedBox(height: 8),
          _buildInfoDetailCard(
            'Ville',
            widget.ecole.ville ?? 'Non spécifiée',
            Icons.location_city_rounded,
            Colors.orange,
          ),
          const SizedBox(height: 8),
          _buildInfoDetailCard(
            'Pays',
            widget.ecole.pays ?? 'Non spécifié',
            Icons.public_rounded,
            Colors.purple,
          ),
          const SizedBox(height: 8),
          if (widget.ecole.filiereNom.isNotEmpty)
            _buildInfoDetailCard(
              'Filières',
              widget.ecole.filiereNom.join(', '),
              Icons.school_rounded,
              const Color(0xFF10B981),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoDetailCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.screenCard,
        borderRadius: BorderRadius.circular(
          AppDimensions.getBadgeBorderRadius(context),
        ),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(
                AppDimensions.getSmallCardBorderRadius(context),
              ),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: _textSizeService.getScaledFontSize(11),
                    fontWeight: FontWeight.w600,
                    color: AppColors.screenTextSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: _textSizeService.getScaledFontSize(12),
                    color: AppColors.screenTextPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Detailed info from API (logo, infos académiques, infra, rubriques) ─────
  Widget _buildDetailedInfoSection() {
    return FutureBuilder<EcoleDetail>(
      future: EcoleApiService.getEcoleDetail(widget.ecole.parametreCode ?? ''),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CustomLoader(
              message: 'Chargement des informations...',
              loaderColor: AppColors.screenOrange,
              size: 56.0,
              showBackground: false,
            ),
          );
        }
        if (snapshot.hasError || !snapshot.hasData)
          return const SizedBox.shrink();
        final detail = snapshot.data!;
        final data = detail.data;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero logo card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.screenCard,
                borderRadius: BorderRadius.circular(
                  AppDimensions.getLargeCardBorderRadius(context),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.screenShadow,
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  if (data.logo != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.getMediumCardBorderRadius(context),
                      ),
                      child: Image.network(
                        data.logo!,
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 64,
                          height: 64,
                          color: AppColors.screenSurface,
                          child: const Icon(
                            Icons.school_rounded,
                            color: AppColors.screenTextSecondary,
                          ),
                        ),
                      ),
                    )
                  else
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.screenOrangeLight,
                        borderRadius: BorderRadius.circular(
                          AppDimensions.getMediumCardBorderRadius(context),
                        ),
                      ),
                      child: const Icon(
                        Icons.school_rounded,
                        color: AppColors.screenOrange,
                        size: 30,
                      ),
                    ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data.nom,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.screenTextPrimary,
                          ),
                          maxLines: 2,
                        ),
                        if (data.slogan != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            data.slogan!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.screenOrange,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _infoCard('Informations principales', [
              // _infoDetailRow('Code', data.code),
              _infoDetailRow('Type', data.type),
              _infoDetailRow('Statut', data.statut),
              _infoDetailRow('Période', data.periode),
              _infoDetailRow('Année', data.annee),
            ]),
            _infoCard('Informations académiques', [
              _infoDetailRow('Directeur rentrée', data.dren),
              _infoDetailRow(
                'Nbre d\'années',
                data.nbrannee?.toString() ?? 'N/A',
              ),
              _infoDetailRow('Mode inscription', data.modeinsc.toString()),
              _infoDetailRow(
                'Statut inscription',
                data.inscriptionsatatus.toString(),
              ),
              if (detail.client.effectif != null)
                _infoDetailRow('Effectif', '${detail.client.effectif} élèves'),
            ]),
            if (data.montantReservation != null && data.montantReservation! > 0)
              _infoCard('Réservations', [
                _infoDetailRow('Montant', '${data.montantReservation} FCFA'),
                _infoDetailRow('Début', data.debutReservation ?? 'N/A'),
                _infoDetailRow('Fin', data.finReservation ?? 'N/A'),
              ]),
            if (detail.infrastructures.isNotEmpty)
              _infoCard(
                'Infrastructure & services',
                detail.infrastructures
                    .map(
                      (i) => _infoDetailRow(
                        i['nom']?.toString() ?? 'Service',
                        i['description']?.toString() ?? 'Disponible',
                      ),
                    )
                    .toList(),
              ),
            if (detail.rubriques.isNotEmpty)
              _infoCard(
                'Rubriques',
                detail.rubriques
                    .map(
                      (r) => _infoDetailRow(
                        r['nom']?.toString() ?? 'Rubrique',
                        r['description']?.toString() ?? 'Disponible',
                      ),
                    )
                    .toList(),
              ),
          ],
        );
      },
    );
  }

  Widget _infoCard(String title, List<Widget> rows) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 16,
                  decoration: BoxDecoration(
                    color: AppColors.screenOrange,
                    borderRadius: BorderRadius.circular(
                      AppDimensions.getIconContainerBorderRadius(context),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.screenTextPrimary,
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            child: Divider(color: AppColors.screenDivider, height: 1),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Column(children: rows),
          ),
        ],
      ),
    );
  }

  Widget _infoDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.screenTextSecondary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.screenTextPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── CONSULT REQUESTS CONTENT ───────────────────────────────────────────────
  Widget _buildConsultRequestsContent() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final actionColor = _kActions['consult_requests']!.color;
    final TextEditingController _matriculeController = TextEditingController();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          /*Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF06B6D4), Color(0xFF0891B2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppDimensions.getLargeCardBorderRadius(context)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.search_rounded,
                  color: Colors.white,
                  size: 32,
                ),
                const SizedBox(height: 12),
                Text(
                  'Consulter mes demandes',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Vérifiez le statut de votre demande d\'intégration',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),*/

          // Instructions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : AppColors.screenCard,
              borderRadius: BorderRadius.circular(
                AppDimensions.getMediumCardBorderRadius(context),
              ),
              border: Border.all(
                color: isDark ? Colors.white24 : AppColors.screenDivider,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.screenOrange,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Comment faire ?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? Colors.white
                            : AppColors.screenTextPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildInstructionStep(
                  '1.',
                  'Entrez votre matricule dans le champ ci-dessous',
                  isDark,
                ),
                _buildInstructionStep(
                  '2.',
                  'Cliquez sur "Consulter" pour vérifier votre demande',
                  isDark,
                ),
                _buildInstructionStep(
                  '3.',
                  'Le résultat s\'affichera instantanément',
                  isDark,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Matricule input
          Text(
            'Votre matricule',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : AppColors.screenTextPrimary,
            ),
          ),
          const SizedBox(height: 8),
          CustomTextField(
            label: 'Matricule',
            hint: 'Ex: 1234RTFGHJ',
            icon: Icons.badge_rounded,
            controller: _matriculeController,
            keyboardType: TextInputType.text,
            iconColor: actionColor,
            focusBorderColor: actionColor,
          ),
          const SizedBox(height: 20),

          // Consult button
          CustomFormButton(
            text: 'Consulter ma demande',
            icon: Icons.star_rounded,
            onPressed: () => _submitConsultRequest(_matriculeController.text),
            color: actionColor,
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionStep(String number, String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: const Color(0xFF06B6D4),
              borderRadius: BorderRadius.circular(
                AppDimensions.getSmallCardBorderRadius(context),
              ),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white70 : AppColors.screenTextSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitConsultRequest(String matricule) async {
    if (matricule.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer un matricule'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show loader
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const CustomLoader(
        message: 'Consultation en cours...',
        loaderColor: Color(0xFF06B6D4),
      ),
    );

    try {
      final result = await IntegrationRequestService.consultIntegrationRequest(
        ecoleCode: widget.ecole.parametreCode ?? 'gainhs',
        matricule: matricule,
      );

      // Close loader
      Navigator.of(context).pop();

      if (result['success'] == true) {
        _showIntegrationResultDialog(result['data']);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? 'Erreur lors de la consultation'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Close loader
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showIntegrationResultDialog(Map<String, dynamic> data) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(
              AppDimensions.getLargeCardBorderRadius(context),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: data['statut'] == 2 ? Colors.green : Colors.orange,
                  borderRadius: BorderRadius.circular(
                    AppDimensions.getHeroCardBorderRadius(context),
                  ),
                ),
                child: Icon(
                  data['statut'] == 2
                      ? Icons.check_rounded
                      : Icons.info_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(height: 20),
              // Title
              const Text(
                'Résultat de votre demande',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 16),
              // Message
              Text(
                data['message'] ?? 'Aucun message disponible',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF8A8A9A),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              // Close button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF06B6D4),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.getSmallCardBorderRadius(context),
                      ),
                    ),
                  ),
                  child: const Text(
                    'OK',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
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

  //  Simplified contact info section
  Widget _buildContactInfoSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF3B82F6).withOpacity(0.08),
            const Color(0xFF3B82F6).withOpacity(0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(
          AppDimensions.getLargeCardBorderRadius(context),
        ),
        border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.15)),
        boxShadow: AppDimensions.getLightShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6),
                  borderRadius: BorderRadius.circular(
                    AppDimensions.getSmallCardBorderRadius(context),
                  ),
                ),
                child: const Icon(
                  Icons.contact_phone_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Contact',
                      style: TextStyle(
                        fontSize: _textSizeService.getScaledFontSize(18),
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF3B82F6),
                      ),
                    ),
                    Text(
                      'Informations de contact',
                      style: TextStyle(
                        fontSize: _textSizeService.getScaledFontSize(13),
                        color: AppColors.screenTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildContactInfoCard(
            'Adresse',
            '${widget.ecole.adresse ?? 'Non disponible'}, ${widget.ecole.ville ?? ''}, ${widget.ecole.pays ?? ''}',
            Icons.location_on_rounded,
            const Color(0xFF3B82F6),
          ),
          const SizedBox(height: 8),
          if (widget.ecole.telephone?.isNotEmpty == true) ...[
            _buildContactInfoCard(
              'Téléphone',
              widget.ecole.telephone!,
              Icons.phone_rounded,
              Colors.green,
            ),
            const SizedBox(height: 8),
          ],
          FutureBuilder<EcoleDetail>(
            future: EcoleApiService.getEcoleDetail(
              widget.ecole.parametreCode ?? '',
            ),
            builder: (_, snap) {
              if (!snap.hasData) return const SizedBox.shrink();
              final d = snap.data!.data;
              return Column(
                children: [
                  if (d.email?.isNotEmpty == true) ...[
                    _buildContactInfoCard(
                      'Email',
                      d.email!,
                      Icons.email_rounded,
                      Colors.orange,
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (d.site?.isNotEmpty == true)
                    _buildContactInfoCard(
                      'Site web',
                      d.site!,
                      Icons.web_rounded,
                      Colors.purple,
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  //  Academic info section
  Widget _buildAcademicInfoSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green.withOpacity(0.08),
            Colors.green.withOpacity(0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(
          AppDimensions.getLargeCardBorderRadius(context),
        ),
        border: Border.all(color: Colors.green.withOpacity(0.15)),
        boxShadow: AppDimensions.getLightShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(
                    AppDimensions.getSmallCardBorderRadius(context),
                  ),
                ),
                child: const Icon(
                  Icons.school_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Informations académiques',
                      style: TextStyle(
                        fontSize: _textSizeService.getScaledFontSize(18),
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    Text(
                      'Détails de l\'établissement',
                      style: TextStyle(
                        fontSize: _textSizeService.getScaledFontSize(13),
                        color: AppColors.screenTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // const SizedBox(height: 16),
          // _buildInfoDetailCard(
          //   'Type',
          //   widget.ecole.typePrincipal,
          //   Icons.category_rounded,
          //   Colors.orange,
          // ),
          // const SizedBox(height: 8),
          // _buildInfoDetailCard(
          //   'Statut',
          //   widget.ecole.statut ?? 'Actif',
          //   Icons.verified_rounded,
          //   Colors.purple,
          // ),
          const SizedBox(height: 8),
          if (widget.ecole.filiereNom.isNotEmpty)
            _buildInfoDetailCard(
              'Filières',
              widget.ecole.filiereNom.join(', '),
              Icons.school_rounded,
              const Color(0xFF10B981),
            ),
        ],
      ),
    );
  }
}

class _CustomTabBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  _CustomTabBarDelegate(this.child);
  @override
  double get minExtent => 58.0;
  @override
  double get maxExtent => 58.0;
  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => child;
  @override
  bool shouldRebuild(_CustomTabBarDelegate old) => false;
}

// ── Pattern Painter Class ───────────────────────────────────────────────
class _PatternPainter extends CustomPainter {
  final Color color;

  _PatternPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0;

    // Dessiner des cercles décoratifs
    for (int i = 0; i < 5; i++) {
      final offset = Offset(size.width * (0.2 + i * 0.15), size.height * 0.3);
      canvas.drawCircle(offset, 8, paint);
    }

    // Dessiner des lignes décoratives
    for (int i = 0; i < 3; i++) {
      final startY = size.height * (0.6 + i * 0.1);
      canvas.drawLine(
        Offset(size.width * 0.1, startY),
        Offset(size.width * 0.9, startY),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
