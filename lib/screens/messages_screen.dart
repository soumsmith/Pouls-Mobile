import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/database_service.dart';
import '../services/message_service.dart';
import '../services/ecoles_api_service.dart';
import '../services/auth_service.dart';
import '../models/ecole.dart';
import '../config/app_colors.dart';
import '../config/app_typography.dart';
import '../services/text_size_service.dart';
import '../widgets/custom_search_bar.dart';
import '../widgets/searchable_dropdown.dart';

/// Écran de messagerie - Affiche uniquement les notifications FCM reçues
class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;
  final TextSizeService _textSizeService = TextSizeService();
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'Tous';
  bool _isSearching = false;

  final List<String> _filters = ['Tous', 'Non lus', 'Lus'];

  // Controllers pour le formulaire d'envoi
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _recipientController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _matriculeController = TextEditingController();

  // Variables pour les pièces jointes
  File? _attachedFile;
  String? _fileType; // 'image' ou 'audio'
  bool _isSending = false;

  // Variables pour l'école
  List<Ecole> _ecoles = [];
  String? _selectedEcoleName;
  String? _selectedEcoleCode;
  bool _isLoadingEcoles = false;
  final EcolesApiService _ecolesApiService = EcolesApiService();

  // Variables pour les destinataires
  final List<String> _destinataires = [
    'Direction',
    'Secrétariat',
    'Surveillance générale',
    'Professeur de mathématiques',
    'Professeur de français',
    'Professeur d\'histoire-géographie',
    'Professeur de physique-chimie',
    'Professeur de SVT',
    'Professeur d\'anglais',
    'Professeur d\'espagnol',
    'Professeur d\'allemand',
    'Professeur de philosophie',
    'Professeur d\'EPS',
    'Professeur de musique',
    'Professeur d\'arts plastiques',
    'Censeur',
    'Surveillant',
    'Conseiller principal d\'éducation',
    'Infirmière scolaire',
    'Assistante sociale',
    'Bibliothécaire',
    'Administrateur',
    'Personnel de cantine',
    'Personnel d\'entretien',
    'Autre',
  ];
  String? _selectedDestinataire;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _loadEcoles();
    _loadUserInfo();
    _searchController.addListener(_filterNotifications);
    _textSizeService.addListener(_onTextSizeChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterNotifications);
    _searchController.dispose();
    _textSizeService.removeListener(_onTextSizeChanged);
    _subjectController.dispose();
    _messageController.dispose();
    _recipientController.dispose();
    _phoneNumberController.dispose();
    _matriculeController.dispose();
    super.dispose();
  }

  void _onTextSizeChanged() {
    setState(() {});
  }

  /// Charge les informations de l'utilisateur connecté
  void _loadUserInfo() {
    final currentUser = AuthService.instance.getCurrentUser();
    if (currentUser != null) {
      setState(() {
        // Pré-remplir les champs avec les informations de l'utilisateur
        _phoneNumberController.text = currentUser.phone;
        // Le nom complet de l'utilisateur comme expéditeur
        _recipientController.text = currentUser.fullName;
      });
      print('👤 Infos utilisateur chargées: ${currentUser.fullName} (${currentUser.phone})');
    } else {
      print('⚠️ Aucun utilisateur connecté trouvé');
    }
  }

  Future<void> _loadEcoles() async {
    print('🔄 _loadEcoles appelé - _isLoadingEcoles: $_isLoadingEcoles, _ecoles.length: ${_ecoles.length}');
    
    if (_isLoadingEcoles) {
      print('⚠️ Chargement déjà en cours, annulation');
      return;
    }

    setState(() {
      _isLoadingEcoles = true;
    });

    try {
      final ecoles = await _ecolesApiService.getAllEcoles();
      print('🔄 setState appelé avec ${ecoles.length} écoles');
      setState(() {
        _ecoles = ecoles;
        _isLoadingEcoles = false;
      });
    } catch (e) {
      print('❌ Erreur lors du chargement des écoles: $e');
      setState(() {
        _isLoadingEcoles = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredItems {
    var items = _notifications;

    if (_selectedFilter != 'Tous') {
      if (_selectedFilter == 'Non lus') {
        items = items.where((item) => !(item['isRead'] as bool)).toList();
      } else if (_selectedFilter == 'Lus') {
        items = items.where((item) => (item['isRead'] as bool)).toList();
      }
    }

    if (_searchController.text.isNotEmpty) {
      final searchQuery = _searchController.text.toLowerCase();
      items = items.where((item) =>
        (item['title'] as String).toLowerCase().contains(searchQuery) ||
        (item['body'] as String).toLowerCase().contains(searchQuery) ||
        (item['sender'] as String).toLowerCase().contains(searchQuery)
      ).toList();
    }

    return items;
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final parentId = 'parent1';
      final databaseService = DatabaseService.instance;
      final notifications = await databaseService.getNotificationsByParent(parentId);

      if (notifications.isEmpty) {
        await _addDemoNotifications(parentId);
        final updatedNotifications = await databaseService.getNotificationsByParent(parentId);
        setState(() {
          _notifications = updatedNotifications;
          _isLoading = false;
        });
      } else {
        setState(() {
          _notifications = notifications;
          _isLoading = false;
        });
      }
    } catch (e) {
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

  Future<void> _addDemoNotifications(String parentId) async {
    final databaseService = DatabaseService.instance;
    final now = DateTime.now();

    final demoNotifications = [
      {
        'id': 'demo_1',
        'title': 'Réunion parents-professeurs',
        'body': 'Une réunion parents-professeurs est programmée pour le vendredi 28 février à 18h. Merci de confirmer votre présence.',
        'timestamp': now.subtract(const Duration(hours: 2)).millisecondsSinceEpoch,
        'sender': 'Direction de l\'établissement',
        'isRead': false,
      },
      {
        'id': 'demo_2',
        'title': 'Note de mathématiques',
        'body': 'Votre enfant a obtenu 15/20 au dernier contrôle de mathématiques. Félicitations !',
        'timestamp': now.subtract(const Duration(days: 1)).millisecondsSinceEpoch,
        'sender': 'M. Dubois - Professeur de mathématiques',
        'isRead': false,
      },
      {
        'id': 'demo_3',
        'title': 'Sortie scolaire',
        'body': 'Une sortie au musée est organisée le mercredi prochain. N\'oubliez pas d\'envoyer l\'autorisation signée.',
        'timestamp': now.subtract(const Duration(days: 2)).millisecondsSinceEpoch,
        'sender': 'Mme Martin - Professeur d\'histoire',
        'isRead': true,
      },
      {
        'id': 'demo_4',
        'title': 'Cantine du jour',
        'body': 'Menu du jour : Poulet rôti, haricots verts, fromage et fruit de saison.',
        'timestamp': now.subtract(const Duration(days: 3)).millisecondsSinceEpoch,
        'sender': 'Service de cantine',
        'isRead': true,
      },
    ];

    for (final notification in demoNotifications) {
      await databaseService.saveNotification(
        id: notification['id'] as String,
        title: notification['title'] as String,
        body: notification['body'] as String,
        timestamp: DateTime.fromMillisecondsSinceEpoch(notification['timestamp'] as int),
        sender: notification['sender'] as String,
        parentId: parentId,
      );
    }
  }

  Future<void> _markAllAsRead() async {
    final parentId = 'parent1';

    try {
      final databaseService = DatabaseService.instance;
      await databaseService.markAllNotificationsAsRead(parentId);

      setState(() {
        for (var notification in _notifications) {
          notification['isRead'] = true;
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tous les messages ont été marqués comme lus')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  void _filterNotifications() {
    setState(() {});
  }

  // ─── Méthodes utilitaires pour le formulaire ────────────────────────────────

  Widget _buildLabel(String text, bool isDark) {
    return Text(
      text,
      style: TextStyle(
        fontSize: _textSizeService.getScaledFontSize(16),
        fontWeight: FontWeight.w600,
        color: AppColors.getTextColor(isDark),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint,
    bool isDark, {
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: isDark ? Colors.grey[800] : Colors.grey[50],
      ),
      style: TextStyle(
        color: AppColors.getTextColor(isDark),
        fontSize: _textSizeService.getScaledFontSize(16),
      ),
    );
  }

  /// Dropdown corrigé : reçoit la valeur sélectionnée et un callback
  /// pour que le StatefulBuilder du BottomSheet puisse se rebuilder correctement.
  Widget _buildEcoleDropdownFixed(
    bool isDark,
    String? selectedValue,
    void Function(String name, String code) onSelected,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[600]! : Colors.grey[300]!,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: selectedValue,
          hint: _isLoadingEcoles
              ? Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Chargement des écoles...',
                      style: TextStyle(
                        color: AppColors.getTextColor(isDark),
                        fontSize: _textSizeService.getScaledFontSize(14),
                      ),
                    ),
                  ],
                )
              : Text(
                  'Sélectionner une école...',
                  style: TextStyle(
                    color: AppColors.getTextColor(isDark, type: TextType.secondary),
                    fontSize: _textSizeService.getScaledFontSize(14),
                  ),
                ),
          items: _ecoles.map((ecole) {
            return DropdownMenuItem<String>(
              value: ecole.parametreNom,
              child: Text(
                ecole.parametreNom,
                style: TextStyle(
                  color: AppColors.getTextColor(isDark),
                  fontSize: _textSizeService.getScaledFontSize(14),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: _isLoadingEcoles
              ? null
              : (String? newValue) {
                  if (newValue != null) {
                    final ecole = _ecoles.firstWhere(
                      (e) => e.parametreNom == newValue,
                    );
                    onSelected(newValue, ecole.parametreCode);
                  }
                },
          dropdownColor: isDark ? Colors.grey[800] : Colors.grey[50],
          icon: Icon(
            Icons.arrow_drop_down,
            color: AppColors.getTextColor(isDark, type: TextType.secondary),
          ),
        ),
      ),
    );
  }

  // ─── BottomSheet principal ────────────────────────────────────────────────────

  void _showComposeMessageBottomSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    print('📋 _showComposeMessageBottomSheet appelé');

    // Variables locales au BottomSheet pour forcer son rebuild indépendamment
    String? localSelectedEcoleName = _selectedEcoleName;
    String? localSelectedEcoleCode = _selectedEcoleCode;
    String? localSelectedDestinataire = _selectedDestinataire;
    
    print('📋 Variables locales initialisées - Écoles: ${_ecoles.length}, isLoading: $_isLoadingEcoles');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
            decoration: BoxDecoration(
              color: AppColors.getSurfaceColor(isDark),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Header ──────────────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: Icon(
                            Icons.close,
                            color: AppColors.getTextColor(isDark),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Nouveau message',
                            style: TextStyle(
                              fontSize: _textSizeService.getScaledFontSize(20),
                              fontWeight: FontWeight.w600,
                              color: AppColors.getTextColor(isDark),
                            ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: _isSending ? null : _sendMessage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isSending
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text('Envoyer'),
                        ),
                      ],
                    ),
                  ),

                  // ── Formulaire ───────────────────────────────────────────────
                  Padding(
                    padding: EdgeInsets.only(
                      left: 20,
                      right: 20,
                      top: 20,
                      bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Destinataire
                        _buildLabel('Votre nom', isDark),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey[700] : Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.person, color: AppColors.getTextColor(isDark)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  AuthService.instance.getCurrentUser()?.fullName ?? 'Non connecté',
                                  style: TextStyle(
                                    color: AppColors.getTextColor(isDark),
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // École — avec SearchableDropdown
                        _buildLabel('École', isDark),
                        const SizedBox(height: 8),
                        if (_isLoadingEcoles)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.grey[700] : Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Row(
                              children: [
                                const CircularProgressIndicator(),
                                const SizedBox(width: 8),
                                Text(
                                  'Chargement des écoles...',
                                  style: TextStyle(
                                    color: AppColors.getTextColor(isDark),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else if (_ecoles.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.grey[700] : Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Text(
                              'Aucune école disponible',
                              style: TextStyle(
                                color: AppColors.getTextColor(isDark),
                              ),
                            ),
                          )
                        else
                          SearchableDropdown(
                            key: ValueKey('ecole_dropdown_${_ecoles.length}'),
                            label: 'École *',
                            value: localSelectedEcoleName ?? 'Sélectionner une école...',
                            items: _ecoles.map((ecole) => ecole.ecoleclibelle).toList(),
                            onChanged: (String selectedEcoleName) {
                              print('🎯 École sélectionnée: $selectedEcoleName');
                              final selectedEcole = _ecoles.firstWhere(
                                (ecole) => ecole.ecoleclibelle == selectedEcoleName,
                              );
                              // Rebuild du BottomSheet
                              setModalState(() {
                                localSelectedEcoleName = selectedEcoleName;
                                localSelectedEcoleCode = selectedEcole.ecolecode;
                              });
                              // Sync avec le state parent (pour _sendMessage)
                              setState(() {
                                _selectedEcoleName = selectedEcoleName;
                                _selectedEcoleCode = selectedEcole.ecolecode;
                              });
                            },
                            isDarkMode: isDark,
                          ),
                        const SizedBox(height: 20),

                        // Numéro de téléphone
                        _buildLabel('Votre numéro de téléphone', isDark),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey[700] : Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.phone, color: AppColors.getTextColor(isDark)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  AuthService.instance.getCurrentUser()?.phone ?? 'Non connecté',
                                  style: TextStyle(
                                    color: AppColors.getTextColor(isDark),
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Destinataire du message
                        _buildLabel('Destinataire du message', isDark),
                        const SizedBox(height: 8),
                        SearchableDropdown(
                          key: ValueKey('destinataire_dropdown_${_selectedDestinataire}'),
                          label: 'Destinataire *',
                          value: localSelectedDestinataire ?? 'Sélectionner un destinataire...',
                          items: _destinataires,
                          onChanged: (String selectedDestinataire) {
                            print('🎯 Destinataire sélectionné: $selectedDestinataire');
                            // Rebuild du BottomSheet
                            setModalState(() {
                              localSelectedDestinataire = selectedDestinataire;
                            });
                            // Sync avec le state parent (pour _sendMessage)
                            setState(() {
                              _selectedDestinataire = selectedDestinataire;
                              _recipientController.text = selectedDestinataire;
                            });
                          },
                          isDarkMode: isDark,
                        ),
                        const SizedBox(height: 20),

                        // Matricule
                        _buildLabel('Matricule', isDark),
                        const SizedBox(height: 8),
                        _buildTextField(
                          _matriculeController,
                          'Ex: 67894F',
                          isDark,
                        ),
                        const SizedBox(height: 20),

                        // Sujet
                        _buildLabel('Sujet', isDark),
                        const SizedBox(height: 8),
                        _buildTextField(
                          _subjectController,
                          'Sujet du message',
                          isDark,
                        ),
                        const SizedBox(height: 20),

                        // Message
                        _buildLabel('Message', isDark),
                        const SizedBox(height: 8),
                        _buildTextField(
                          _messageController,
                          'Tapez votre message ici...',
                          isDark,
                          maxLines: 8,
                        ),
                        const SizedBox(height: 20),

                        // Pièce jointe
                        _buildLabel('Pièce jointe', isDark),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _pickImage,
                                icon: const Icon(Icons.image),
                                label: const Text('Image'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _fileType == 'image' ? AppColors.primary : null,
                                  foregroundColor: _fileType == 'image' ? Colors.white : null,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _pickAudio,
                                icon: const Icon(Icons.mic),
                                label: const Text('Audio'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _fileType == 'audio' ? AppColors.primary : null,
                                  foregroundColor: _fileType == 'audio' ? Colors.white : null,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_attachedFile != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.grey[700] : Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _fileType == 'image' ? Icons.image : Icons.mic,
                                  size: 20,
                                  color: AppColors.getTextColor(isDark),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _attachedFile!.path.split('/').last,
                                    style: TextStyle(
                                      fontSize: _textSizeService.getScaledFontSize(12),
                                      color: AppColors.getTextColor(isDark),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                IconButton(
                                  onPressed: _removeAttachment,
                                  icon: const Icon(Icons.close, size: 20),
                                  color: Colors.red,
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),

                        // Messages rapides
                        _buildLabel('Messages rapides', isDark),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildQuickMessage('Demande de rendez-vous'),
                            _buildQuickMessage('Absence de mon enfant'),
                            _buildQuickMessage('Question sur les devoirs'),
                            _buildQuickMessage('Information médicale'),
                            _buildQuickMessage('Demande de document'),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
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

  Widget _buildQuickMessage(String message) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        _subjectController.text = message;
        _messageController.text = 'Je vous contacte concernant: $message';
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[700] : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          message,
          style: TextStyle(
            fontSize: _textSizeService.getScaledFontSize(12),
            color: AppColors.getTextColor(isDark),
          ),
        ),
      ),
    );
  }

  void _sendMessage() async {
    print('🚀 _sendMessage appelé');

    // Récupérer l'utilisateur connecté
    final currentUser = AuthService.instance.getCurrentUser();
    if (currentUser == null) {
      print('❌ Aucun utilisateur connecté');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez vous connecter pour envoyer un message'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_subjectController.text.trim().isEmpty ||
        _messageController.text.trim().isEmpty ||
        _selectedEcoleName == null ||
        _matriculeController.text.trim().isEmpty) {
      print('❌ Validation échouée - champs vides');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez remplir tous les champs obligatoires'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    print('✅ Validation réussie');
    print('📝 Sujet: ${_subjectController.text.trim()}');
    print('📝 Message: ${_messageController.text.trim()}');
    print('� Utilisateur: ${currentUser.fullName} (${currentUser.phone})');
    print('🏫 École: $_selectedEcoleName ($_selectedEcoleCode)');
    print('🆔 Matricule: ${_matriculeController.text.trim()}');
    print('📎 Fichier attaché: ${_attachedFile != null ? 'Oui (${_fileType})' : 'Non'}');

    setState(() {
      _isSending = true;
    });

    try {
      print('📡 Appel du service MessageService...');
      final messageService = MessageService();
      final userPhoneNumber = currentUser.phone; // Utiliser le téléphone de l'utilisateur connecté
      final codeEcole = _selectedEcoleCode ?? 'gainhs';
      final matricule = _matriculeController.text.trim();

      print('📞 Numéro: $userPhoneNumber');
      print('🏫 École: $codeEcole');
      print('🆔 Matricule: $matricule');

      Map<String, dynamic> result;

      if (_attachedFile != null) {
        if (_fileType == 'image') {
          print('🖼️ Envoi message avec image...');
          result = await messageService.sendImageMessage(
            userPhoneNumber: userPhoneNumber,
            content: _messageController.text.trim(),
            subject: _subjectController.text.trim(),
            codeEcole: codeEcole,
            matricule: matricule,
            imageFile: _attachedFile!,
          );
        } else if (_fileType == 'audio') {
          print('🎤 Envoi message avec audio...');
          result = await messageService.sendVoiceMessage(
            userPhoneNumber: userPhoneNumber,
            content: _messageController.text.trim(),
            subject: _subjectController.text.trim(),
            codeEcole: codeEcole,
            matricule: matricule,
            audioFile: _attachedFile!,
          );
        } else {
          print('❌ Type de fichier non supporté: $_fileType');
          result = {'success': false, 'message': 'Type de fichier non supporté'};
        }
      } else {
        print('📄 Envoi message texte simple...');
        result = await messageService.sendTextMessage(
          userPhoneNumber: userPhoneNumber,
          content: _messageController.text.trim(),
          subject: _subjectController.text.trim(),
          codeEcole: codeEcole,
          matricule: matricule,
        );
      }

      print('📥 Résultat reçu: $result');

      if (result['success'] == true) {
        print('✅ Message envoyé avec succès');

        final newMessage = {
          'id': 'sent_${DateTime.now().millisecondsSinceEpoch}',
          'title': _subjectController.text,
          'body': _messageController.text,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'sender': '${currentUser.fullName} → ${_recipientController.text.trim().isEmpty ? 'Destinataire' : _recipientController.text}',
          'isRead': true,
        };

        setState(() {
          _notifications.insert(0, newMessage);
        });

        _subjectController.clear();
        _messageController.clear();
        _recipientController.clear();
        _phoneNumberController.clear();
        _matriculeController.clear();
        setState(() {
          _selectedEcoleName = null;
          _selectedEcoleCode = null;
        });
        _removeAttachment();

        if (mounted) Navigator.of(context).pop();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Message envoyé avec succès'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        print('❌ Erreur lors de l\'envoi: ${result['message']}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Erreur lors de l\'envoi'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('💥 Exception capturée: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      print('🏁 Fin du processus d\'envoi');
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'gif'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _attachedFile = File(result.files.single.path!);
          _fileType = 'image';
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la sélection de l\'image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pickAudio() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['webm', 'mp3', 'wav', 'm4a'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _attachedFile = File(result.files.single.path!);
          _fileType = 'audio';
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la sélection du fichier audio: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _removeAttachment() {
    setState(() {
      _attachedFile = null;
      _fileType = null;
    });
  }

  // ─── Build principal ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.getPureBackground(isDark),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    _notifications.sort((a, b) {
      final dateA = DateTime.fromMillisecondsSinceEpoch(a['timestamp'] as int);
      final dateB = DateTime.fromMillisecondsSinceEpoch(b['timestamp'] as int);
      return dateB.compareTo(dateA);
    });

    final filteredItems = _filteredItems;

    return Scaffold(
      extendBody: true,
      backgroundColor: AppColors.getPureBackground(isDark),
      appBar: AppBar(
        backgroundColor: AppColors.getPureAppBarBackground(isDark),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Center(
          child: Text(
            'Messages',
            style: AppTypography.appBarTitle.copyWith(
              color: Theme.of(context).textTheme.titleLarge?.color,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: Theme.of(context).iconTheme.color),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                }
              });
            },
          ),
          if (_notifications.any((n) => !(n['isRead'] as bool)))
            IconButton(
              icon: Icon(
                Icons.mark_email_read_outlined,
                color: Theme.of(context).iconTheme.color,
              ),
              onPressed: _markAllAsRead,
              tooltip: 'Marquer tout comme lu',
            ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: FloatingActionButton(
          onPressed: _showComposeMessageBottomSheet,
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          child: const Icon(Icons.edit),
        ),
      ),
      body: Column(
        children: [
          // Barre de recherche animée
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            height: _isSearching ? 56 : 0,
            margin: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: _isSearching ? 8 : 0,
            ),
            child: _isSearching
                ? CustomSearchBar(
                    hintText: 'Rechercher un message...',
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {});
                    },
                    onClear: () {
                      setState(() {
                        _isSearching = false;
                        _searchController.clear();
                      });
                    },
                    autoFocus: true,
                  )
                : null,
          ),

          // Filtres
          Container(
            height: 35,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              itemBuilder: (context, index) {
                final filter = _filters[index];
                final isSelected = filter == _selectedFilter;
                final theme = Theme.of(context);
                final isDark = theme.brightness == Brightness.dark;

                return GestureDetector(
                  onTap: () => setState(() => _selectedFilter = filter),
                  child: Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: isSelected ? AppColors.primaryGradient : null,
                      color: !isSelected ? AppColors.getSurfaceColor(isDark) : null,
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
                    child: Text(
                      filter,
                      style: AppTypography.overline.copyWith(
                        color: isSelected
                            ? Colors.white
                            : AppColors.getTextColor(isDark),
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Compteur de résultats
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Text(
                  '${filteredItems.length} message${filteredItems.length > 1 ? 's' : ''}',
                  style: TextStyle(
                    fontSize: AppTypography.labelMedium,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Liste des messages
          if (filteredItems.isEmpty)
            Expanded(child: _buildEmptyState())
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: filteredItems.length,
                itemBuilder: (context, index) {
                  final notification = filteredItems[index];
                  final isLast = index == filteredItems.length - 1;
                  return _buildTimelineItem(notification, isLast);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.primary.withOpacity(0.15)
                  : AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(40),
            ),
            child: Icon(
              Icons.mail_outline,
              size: 40,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Aucun message',
            style: TextStyle(
              fontSize: _textSizeService.getScaledFontSize(18),
              fontWeight: FontWeight.w600,
              color: AppColors.getTextColor(isDark, type: TextType.secondary),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Les messages apparaîtront ici',
            style: TextStyle(
              fontSize: _textSizeService.getScaledFontSize(14),
              color: AppColors.getTextColor(isDark, type: TextType.secondary)
                  .withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(Map<String, dynamic> notification, bool isLast) {
    final isRead = notification['isRead'] as bool? ?? false;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ligne de timeline
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: isRead
                        ? (isDark ? Colors.grey[600] : Colors.grey[400])
                        : AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isRead
                          ? (isDark ? Colors.grey[500]! : Colors.grey[300]!)
                          : AppColors.primary.withOpacity(0.3),
                      width: 3,
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isRead
                            ? (isDark ? Colors.grey[600] : Colors.grey[400])
                            : AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: isDark ? Colors.grey[700] : Colors.grey[300],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildMessageTimelineCard(notification),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageTimelineCard(Map<String, dynamic> notification) {
    final title = notification['title'] as String? ?? 'Notification';
    final body = notification['body'] as String? ?? '';
    final timestamp = DateTime.fromMillisecondsSinceEpoch(
        notification['timestamp'] as int);
    final isRead = notification['isRead'] as bool? ?? false;
    final sender = notification['sender'] as String? ??
        'Direction de l\'établissement';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: AppColors.getSurfaceColor(isDark),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.2)
                : Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showNotificationDetail(notification),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: _textSizeService.getScaledFontSize(16),
                          fontWeight: FontWeight.w700,
                          color: isRead
                              ? AppColors.getTextColor(isDark,
                                  type: TextType.secondary)
                              : AppColors.getTextColor(isDark,
                                  type: TextType.primary),
                        ),
                      ),
                    ),
                    if (!isRead)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  body,
                  style: TextStyle(
                    fontSize: _textSizeService.getScaledFontSize(14),
                    color: AppColors.getTextColor(isDark,
                        type: TextType.secondary),
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.primary.withOpacity(0.08)
                        : Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.schedule_outlined,
                            size: 16,
                            color: AppColors.getTextColor(isDark,
                                type: TextType.secondary),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatDate(timestamp),
                            style: TextStyle(
                              fontSize: _textSizeService.getScaledFontSize(12),
                              color: AppColors.getTextColor(isDark,
                                  type: TextType.secondary),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: 16,
                            color: AppColors.getTextColor(isDark,
                                type: TextType.secondary),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              sender,
                              style: TextStyle(
                                fontSize:
                                    _textSizeService.getScaledFontSize(12),
                                color: AppColors.getTextColor(isDark,
                                    type: TextType.secondary),
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
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
        ),
      ),
    );
  }

  void _showNotificationDetail(Map<String, dynamic> notification) async {
    final title = notification['title'] as String? ?? 'Notification';
    final body = notification['body'] as String? ?? '';
    final timestamp = DateTime.fromMillisecondsSinceEpoch(
        notification['timestamp'] as int);
    final sender = notification['sender'] as String? ??
        'Direction de l\'établissement';
    final data = notification['data'] as Map<String, dynamic>?;
    final notificationId = notification['id'] as String;
    final isRead = notification['isRead'] as bool? ?? false;

    if (!isRead) {
      try {
        final databaseService = DatabaseService.instance;
        await databaseService.markNotificationAsRead(notificationId);
        setState(() {
          notification['isRead'] = true;
        });
      } catch (e) {
        print('❌ Erreur lors du marquage: $e');
      }
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'De: $sender',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              Text(
                'Date: ${_formatDate(timestamp)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 16),
              Text(body),
              if (data != null && data.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  'Détails:',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                ...data.entries.map((entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '${entry.key}: ${entry.value}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                )),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Aujourd\'hui';
    } else if (difference.inDays == 1) {
      return 'Hier';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} jours';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}