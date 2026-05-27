import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/message_service.dart';
import '../services/auth_service.dart';
import '../services/mock_api_service.dart';
import '../models/conversation.dart';
import '../models/child.dart';
import '../config/app_colors.dart';
import '../config/app_dimensions.dart';
import '../services/text_size_service.dart';
import '../widgets/custom_sliver_app_bar.dart';
import '../widgets/snackbar.dart';

// ─── ENUM : types de pièce jointe ────────────────────────────────────────────
enum AttachmentType { none, image, audio, document }

// ─── Modèle local pour les messages affichés ────────────────────────────────
class _LocalMessage {
  final String body;
  final bool isMe;
  final DateTime time;
  final AttachmentType attachmentType;
  final bool isPending;
  final String? attachmentUrl;

  const _LocalMessage({
    required this.body,
    required this.isMe,
    required this.time,
    this.attachmentType = AttachmentType.none,
    this.isPending = false,
    this.attachmentUrl,
  });
}

/// Données de l'élève passées depuis le détail de l'élève
class StudentMessageArgs {
  final String studentName;
  final String studentMatricule;
  final String ecoleName;
  final String ecoleCode;

  const StudentMessageArgs({
    required this.studentName,
    required this.studentMatricule,
    required this.ecoleName,
    required this.ecoleCode,
  });
}

/// Écran de messagerie contextuel — style WhatsApp, pré-lié à un élève
class MessagesScreen extends StatefulWidget {
  final StudentMessageArgs? studentArgs;

  const MessagesScreen({super.key, this.studentArgs});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen>
    with SingleTickerProviderStateMixin {
  static const bool _enableAudioRecording = true;

  // ─── Conversations ──────────────────────────────────────────────────────
  List<Conversation> _conversations = [];
  List<_LocalMessage> _localMessages = [];
  List<Child> _children = [];

  bool _isLoading = true;
  bool _isLoadingChildren = true;
  final TextSizeService _textSizeService = TextSizeService();
  final MessageService _messageService = MessageService();
  final ScrollController _scrollController = ScrollController();

  // ─── Formulaire d'envoi ─────────────────────────────────────────────────
  final TextEditingController _messageController = TextEditingController();
  bool _isSending = false;
  bool _hasContent = false;

  // ─── Pièce jointe ───────────────────────────────────────────────────────
  AttachmentType _attachmentType = AttachmentType.none;
  File? _attachedFile;

  // ─── Enregistrement audio ───────────────────────────────────────────────
  AudioRecorder? _audioRecorder;
  bool _isRecording = false;
  Duration _recordDuration = Duration.zero;
  Timer? _recordTimer;
  String? _recordedPath;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  Timer? _refreshTimer;

  // ════════════════════════════════════════════════════════════════════════════
  //  GETTERS
  // ════════════════════════════════════════════════════════════════════════════

  StudentMessageArgs? get _args => widget.studentArgs;
  bool get _hasStudentContext => _args != null;

  // ════════════════════════════════════════════════════════════════════════════
  //  LIFECYCLE
  // ════════════════════════════════════════════════════════════════════════════

  @override
  void initState() {
    super.initState();
    _audioRecorder = AudioRecorder();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    _messageService.resetConversationId();

    if (!_hasStudentContext) {
      _loadChildren();
    } else {
      _loadConversations();
    }

    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted && _hasStudentContext) _loadConversations(silent: true);
    });

    _messageController.addListener(() {
      final has =
          _messageController.text.trim().isNotEmpty ||
          _attachedFile != null ||
          _recordedPath != null;
      if (has != _hasContent) setState(() => _hasContent = has);
    });

    _textSizeService.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    _recordTimer?.cancel();
    _audioRecorder?.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  DATA
  // ════════════════════════════════════════════════════════════════════════════

  Future<void> _loadChildren() async {
    setState(() => _isLoadingChildren = true);
    try {
      final user = AuthService.instance.getCurrentUser();
      if (user == null) throw Exception('Aucun utilisateur connecté');

      final parentId = user.id ?? 'parent1';
      print(
        '📱 MessagesScreen - Chargement des enfants pour parentId: $parentId',
      );

      final apiService = MockApiService();
      final children = await apiService.getChildrenForParent(parentId);

      print('📱 MessagesScreen - ${children.length} enfants trouvés');

      for (final child in children) {
        print('─────────────────────────────────────');
        print('  fullName    : ${child.fullName}');
        print('  matricule   : ${child.matricule}');
        print('  ecoleCode   : ${child.ecoleCode}');
        print('  paramEcole  : ${child.paramEcole}');
        print('  establishment: ${child.establishment}');
        print('  grade       : ${child.grade}');
      }
      print('─────────────────────────────────────');

      if (!mounted) return;

      setState(() {
        _children = List.from(children);
        _isLoadingChildren = false;
        _isLoading = false;
      });

      _fadeController.forward(from: 0);
    } catch (e) {
      print('❌ MessagesScreen - Erreur chargement enfants: $e');
      if (!mounted) return;
      setState(() {
        _isLoadingChildren = false;
        _isLoading = false;
      });
      _showError('Erreur chargement enfants: $e');
    }
  }

  Future<void> _loadConversations({bool silent = false}) async {
    if (!silent) setState(() => _isLoading = true);
    try {
      final currentUser = AuthService.instance.getCurrentUser();
      if (currentUser == null) throw Exception('Aucun utilisateur connecté');

      final result = await _messageService.getMessagesForStudent(
        currentUser.phone,
        _args?.studentMatricule ?? '',
      );

      if (!mounted) return;

      final messagesData = result['messages'] as List<dynamic>;
      final conversationId = result['conversationId'] as int?;

      if (conversationId != null) {
        await _messageService.markMessagesAsRead(
          numeroParent: currentUser.phone,
          conversationId: conversationId,
        );
      }

      final localMessages = messagesData.map((msg) {
        final isMe = msg['sender_type'] == 'parent';

        String? attachmentUrl;
        AttachmentType attachmentType = AttachmentType.none;
        final attachments = msg['attachments'] as List<dynamic>? ?? [];
        if (attachments.isNotEmpty) {
          attachmentUrl = attachments[0]['file_path']?.toString();
          final mime = attachments[0]['mime_type']?.toString() ?? '';
          final fileName =
              attachments[0]['file_name']?.toString().toLowerCase() ?? '';
          if (mime.startsWith('audio') ||
              mime.contains('octet-stream') ||
              fileName.endsWith('.m4a') ||
              fileName.endsWith('.webm') ||
              fileName.endsWith('.mp3') ||
              fileName.endsWith('.wav')) {
            attachmentType = AttachmentType.audio;
          } else if (mime.startsWith('image')) {
            attachmentType = AttachmentType.image;
          } else if (mime.startsWith('application/pdf') ||
              fileName.endsWith('.pdf')) {
            attachmentType = AttachmentType.document;
          }
        }

        return _LocalMessage(
          body: msg['body']?.toString() ?? '',
          isMe: isMe,
          time:
              DateTime.tryParse(msg['created_at']?.toString() ?? '') ??
              DateTime.now(),
          attachmentType: attachmentType,
          attachmentUrl: attachmentUrl,
        );
      }).toList();

      setState(() {
        _localMessages = localMessages.reversed.toList();
        _isLoading = false;
      });

      if (!silent) _fadeController.forward(from: 0);
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;

      if (e.toString().contains('404') ||
          e.toString().contains('Élève non trouvé')) {
        CartSnackBar.show(
          context,
          productName: 'Élève non trouvé',
          message: 'Vérifiez le matricule de l\'élève',
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        );
        setState(() => _isLoading = false);
        return;
      }

      setState(() => _isLoading = false);
      _showError('Erreur chargement: $e');
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  SNACKBARS
  // ════════════════════════════════════════════════════════════════════════════

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.red[400],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: MediaQuery.of(context).padding.bottom + 100,
        ),
      ),
    );
  }

  void _showSuccess(String msg) {
    if (!mounted) return;
    CartSnackBar.show(
      context,
      productName: msg,
      message: '',
      backgroundColor: Colors.green[500],
      duration: const Duration(seconds: 2),
    );
  }

  void _openImageViewer(String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _ImageViewerScreen(imageUrl: imageUrl),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  BUILD PRINCIPAL
  // ════════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDarkMode(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: (isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark).copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: AppColors.screenBg(context),
        body: CustomScrollView(
          slivers: [
            _buildCustomAppBar(),
            SliverFillRemaining(
              child: Column(
                children: [
                  Expanded(child: _buildConversationBody()),
                  if (_hasStudentContext) _buildComposeBar(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── CUSTOM APP BAR ─────────────────────────────────────────────────────
  Widget _buildCustomAppBar() {
    return CustomSliverAppBar(
      title: _hasStudentContext ? _args!.studentName : 'Messages',
      isDark: false,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: true,
      onBackTap: () => Navigator.pop(context),
      actions: _buildMessageActions(),
      titleTextStyle: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: AppColors.screenTextPrimaryThemed(context),
      ),
    );
  }

  List<Widget> _buildMessageActions() {
    return [
      GestureDetector(
        onTap: () => _loadConversations(),
        child: Container(
          width: 40,
          height: 40,
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: AppColors.screenCardThemed(context),
            borderRadius: BorderRadius.circular(20),
            boxShadow: AppDimensions.getSettingsCardShadow(context),
          ),
          child: Icon(
            Icons.refresh_outlined,
            color: AppColors.screenTextPrimaryThemed(context),
            size: 18,
          ),
        ),
      ),
      const SizedBox(width: 8),
    ];
  }

  // ─── CORPS CONVERSATION ───────────────────────────────────────────────────
  Widget _buildConversationBody() {
    if (!_hasStudentContext) {
      if (_isLoadingChildren) {
        return const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF0288D1),
            strokeWidth: 2.5,
          ),
        );
      }
      if (_children.isEmpty) return _buildEmptyChildrenList();
      return _buildChildrenList();
    }

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF0288D1),
          strokeWidth: 2.5,
        ),
      );
    }

    if (_localMessages.isEmpty) return _buildEmptyConversation();

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
        itemCount: _localMessages.length,
        itemBuilder: (context, i) {
          final m = _localMessages[i];
          return _buildBubble(
            body: m.body,
            isMe: m.isMe,
            time: _formatTime(m.time),
            isPending: m.isPending,
            attachmentType: m.attachmentType,
            attachmentUrl: m.attachmentUrl,
          );
        },
      ),
    );
  }

  Widget _buildEmptyConversation() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
               color: const Color(0xFF0288D1).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.chat_bubble_outline,
              size: 36,
              color: Color(0xFF0288D1),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun message',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.screenTextPrimaryThemed(context),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _hasStudentContext
                ? 'Envoyez un message à ${_args!.ecoleName}'
                : 'Démarrez une conversation',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.screenTextSecondaryThemed(context),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ─── LISTE DES ENFANTS ────────────────────────────────────────────────────
  Widget _buildChildrenList() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _children.length,
        separatorBuilder: (context, index) => Divider(
          height: 1,
          indent: 72,
          endIndent: 16,
          color: AppColors.screenDividerThemed(context),
        ),
        itemBuilder: (context, index) {
          final child = _children[index];
          return _buildChildListItem(child);
        },
      ),
    );
  }

  Widget _buildChildListItem(Child child) {
    final matricule = _resolveMatricule(child);
    final hasMatricule = matricule.isNotEmpty;

    return ListTile(
      onTap: () => _navigateToConversation(child),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        radius: 28,
        backgroundColor: const Color(0xFF0288D1).withOpacity(0.1),
        backgroundImage: child.photoUrl != null
            ? CachedNetworkImageProvider(child.photoUrl!)
            : null,
        child: child.photoUrl == null
            ? Text(
                child.firstName[0].toUpperCase(),
                style: const TextStyle(
                  color: Color(0xFF0288D1),
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              )
            : null,
      ),
      title: Text(
        child.fullName,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.screenTextPrimaryThemed(context),
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            child.establishment,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.screenTextSecondaryThemed(context),
            ),
          ),
          Text(
            'Classe: ${child.grade}',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.screenTextSecondaryThemed(context),
            ),
          ),
          if (!hasMatricule)
            Container(
               margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.12),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: Colors.orange.withOpacity(0.3),
                  width: 0.5,
                ),
              ),
              child: const Text(
                '⚠️ Matricule manquant',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.orange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: AppColors.screenTextSecondaryThemed(context),
      ),
    );
  }

  Widget _buildEmptyChildrenList() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF0288D1).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.child_care,
              size: 36,
              color: Color(0xFF0288D1),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun enfant',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.screenTextPrimaryThemed(context),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Ajoutez un enfant pour commencer à envoyer des messages',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.screenTextSecondaryThemed(context),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  RÉSOLUTION DU MATRICULE
  // ════════════════════════════════════════════════════════════════════════════

  String _resolveMatricule(Child child) {
    final candidates = [child.matricule];
    for (final candidate in candidates) {
      if (candidate != null && candidate.trim().isNotEmpty) {
        return candidate.trim();
      }
    }
    return '';
  }

  // ─── NAVIGATION VERS CONVERSATION ────────────────────────────────────────
  void _navigateToConversation(Child child) {
    print('🧒 Child sélectionné pour messagerie:');
    print('   fullName     : ${child.fullName}');
    print('   matricule    : ${child.matricule}');
    print('   ecoleCode    : ${child.ecoleCode}');
    print('   paramEcole   : ${child.paramEcole}');
    print('   establishment: ${child.establishment}');
    print('   grade        : ${child.grade}');

    final matricule = _resolveMatricule(child);
    final ecoleCode = child.ecoleCode ?? child.paramEcole ?? '';

    print('   ✅ matricule résolu: "$matricule"');
    print('   ✅ ecoleCode résolu: "$ecoleCode"');

    if (matricule.isEmpty) {
      print('   ❌ Matricule vide — navigation annulée');
      _showError(
        'Matricule de ${child.fullName} introuvable. '
        'Vérifiez les données de l\'enfant.',
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MessagesScreen(
          studentArgs: StudentMessageArgs(
            studentName: child.fullName,
            studentMatricule: matricule,
            ecoleName: child.establishment,
            ecoleCode: ecoleCode,
          ),
        ),
      ),
    );
  }

  // ─── BULLE DE MESSAGE ─────────────────────────────────────────────────────
  Widget _buildBubble({
    required String body,
    required bool isMe,
    required String time,
    bool isPending = false,
    AttachmentType attachmentType = AttachmentType.none,
    String? attachmentUrl,
  }) {
    final isDark = AppColors.isDarkMode(context);

    // Sent: Subtle transparent blue
    final Color bubbleColorMe = isDark
        ? const Color(0xFF0288D1).withOpacity(0.20)
        : const Color(0xFF0288D1).withOpacity(0.10);
    // Received: Subtle transparent green
    final Color bubbleColorOther = isDark
        ? const Color(0xFF4CAF50).withOpacity(0.20)
        : const Color(0xFF4CAF50).withOpacity(0.10);
        
    final Color bubbleBgColor = isMe ? bubbleColorMe : bubbleColorOther;
    
    // Text colors matching the tint
    final Color textColorMe = isDark 
        ? const Color(0xFFE1F5FE) 
        : const Color(0xFF01579B);
    final Color textColorOther = isDark 
        ? const Color(0xFFE8F5E8) 
        : const Color(0xFF1B5E20);
    final Color textColor = isMe ? textColorMe : textColorOther;

    // Time stamp colors matching the tint
    final Color timeColorMe = isDark 
        ? const Color(0xFFB3E5FC) 
        : const Color(0xFF0288D1).withOpacity(0.8);
    final Color timeColorOther = isDark 
        ? const Color(0xFFC8E6C9) 
        : const Color(0xFF4CAF50).withOpacity(0.8);
    final Color timeColor = isMe ? timeColorMe : timeColorOther;

    // Check if the body text is a placeholder (i.e. user has not associated a text to the attachment)
    final bool isPlaceholder = body == 'Note vocale' ||
        body == 'Image' ||
        body == 'Document';
    final bool showText = body.isNotEmpty && !isPlaceholder;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            Container(
              width: 28,
              height: 28,
              margin: const EdgeInsets.only(right: 6, bottom: 2),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF4CAF50).withOpacity(0.2)
                    : const Color(0xFFE8F5E8),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.school_outlined,
                size: 14,
                color: Color(0xFF4CAF50),
              ),
            ),
          ],
          Flexible(
            child: Opacity(
              opacity: isPending ? 0.65 : 1.0,
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: AppDimensions.isTablet(context) || AppDimensions.isSmallTablet(context) || AppDimensions.isLargeTablet(context) ? 400.0 : MediaQuery.sizeOf(context).width * 0.72,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: bubbleBgColor,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isMe ? 18 : 4),
                    bottomRight: Radius.circular(isMe ? 4 : 18),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: isMe
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    if (attachmentType == AttachmentType.audio &&
                        attachmentUrl != null) ...[
                      _AudioBubble(url: attachmentUrl, isMe: isMe),
                      if (showText) const SizedBox(height: 6),
                    ] else if (attachmentType == AttachmentType.document &&
                        attachmentUrl != null) ...[
                      GestureDetector(
                        onTap: () async {
                          final uri = Uri.parse(attachmentUrl);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(
                              uri,
                              mode: LaunchMode.externalApplication,
                            );
                          }
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.picture_as_pdf,
                              size: 14,
                              color: textColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Ouvrir le PDF',
                              style: TextStyle(
                                fontSize: 12,
                                color: textColor,
                                fontStyle: FontStyle.italic,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (showText) const SizedBox(height: 4),
                    ] else if (attachmentType == AttachmentType.image &&
                        attachmentUrl != null) ...[
                      GestureDetector(
                        onTap: () => _openImageViewer(attachmentUrl),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CachedNetworkImage(
                            imageUrl: attachmentUrl,
                            width: 200,
                            height: 150,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              width: 200,
                              height: 150,
                              color: textColor.withOpacity(0.1),
                              child: Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(textColor),
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              width: 200,
                              height: 150,
                              color: textColor.withOpacity(0.1),
                              child: Center(
                                child: Icon(
                                  Icons.broken_image,
                                  size: 32,
                                  color: textColor,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (showText) const SizedBox(height: 6),
                    ],
                    if (showText) ...[
                      Text(
                        body,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.4,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          time,
                          style: TextStyle(
                            fontSize: 10,
                            color: timeColor,
                          ),
                        ),
                        if (isPending && isMe) ...[
                          const SizedBox(width: 4),
                          SizedBox(
                            width: 10,
                            height: 10,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                timeColor,
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
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  BARRE DE COMPOSITION
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildComposeBar() {
    return Container(
      color: AppColors.screenSurfaceThemed(context),
      padding: EdgeInsets.fromLTRB(
        8,
        8,
        8,
        MediaQuery.of(context).padding.bottom + 8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_attachedFile != null || _recordedPath != null)
            _buildAttachmentPreview(),
          if (_isRecording) _buildRecordingIndicator(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: _showAttachmentMenu,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.screenActionBg(context),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Icon(
                    _attachedFile != null
                        ? (_attachmentType == AttachmentType.image
                              ? Icons.image
                              : Icons.attach_file)
                        : Icons.attach_file_outlined,
                    size: 20,
                    color: _attachedFile != null
                        ? const Color(0xFF0288D1)
                        : AppColors.screenTextSecondaryThemed(context),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(
                    minHeight: 44,
                    maxHeight: 120,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.grey100Adaptive(context),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppColors.screenBorder(context),
                      width: 0.5,
                    ),
                  ),
                  child: TextField(
                    controller: _messageController,
                    maxLines: null,
                    textInputAction: TextInputAction.newline,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.screenTextPrimaryThemed(context),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Message...',
                      hintStyle: TextStyle(
                        fontSize: 14,
                        color: AppColors.screenTextTertiary(context),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _hasContent
                  ? GestureDetector(
                      onTap: _isSending ? null : _sendMessage,
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
                        child: _isSending
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Icon(
                                Icons.send_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                      ),
                    )
                  : GestureDetector(
                      onLongPressStart: _enableAudioRecording
                          ? (_) => _startRecording()
                          : null,
                      onLongPressEnd: _enableAudioRecording
                          ? (_) => _stopRecording()
                          : null,
                      onLongPressCancel: _enableAudioRecording
                          ? _cancelRecording
                          : null,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: _isRecording
                              ? const Color(0xFFEF4444)
                              : const Color(0xFF0288D1),
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  (_isRecording
                                          ? const Color(0xFFEF4444)
                                          : const Color(0xFF0288D1))
                                      .withOpacity(0.35),
                              blurRadius: _isRecording ? 12 : 8,
                              spreadRadius: _isRecording ? 2 : 0,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Icon(
                          _isRecording ? Icons.stop_rounded : Icons.mic,
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

  // ─── APERÇU PIÈCE JOINTE ─────────────────────────────────────────────────
  Widget _buildAttachmentPreview() {
    final isRecordedAudio =
        _enableAudioRecording && _recordedPath != null && _attachedFile == null;
    final fileName = isRecordedAudio
        ? 'Note vocale (${_formatDuration(_recordDuration)})'
        : _attachedFile!.path.split('/').last;
    final isImg = _attachmentType == AttachmentType.image;

    final isDark = AppColors.isDarkMode(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF0288D1).withOpacity(0.15)
            : const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF0288D1).withOpacity(0.2),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          if (isImg && _attachedFile != null)
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                image: DecorationImage(
                  image: FileImage(_attachedFile!),
                  fit: BoxFit.cover,
                ),
              ),
            )
          else
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF0288D1).withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isRecordedAudio
                    ? Icons.mic
                    : isImg
                    ? Icons.image_outlined
                    : Icons.attach_file,
                size: 18,
                color: const Color(0xFF0288D1),
              ),
            ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  fileName,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF0288D1),
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (isImg && _attachedFile != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Image sélectionnée',
                    style: TextStyle(
                      fontSize: 11,
                      color: const Color(0xFF0288D1).withOpacity(0.7),
                    ),
                  ),
                ],
              ],
            ),
          ),
          GestureDetector(
            onTap: () => setState(() {
              _attachedFile = null;
              _attachmentType = AttachmentType.none;
              _recordedPath = null;
              _recordDuration = Duration.zero;
              _hasContent = _messageController.text.trim().isNotEmpty;
            }),
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.screenSurfaceThemed(context),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.close,
                size: 14,
                color: Color(0xFF0288D1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── INDICATEUR ENREGISTREMENT ────────────────────────────────────────────
  Widget _buildRecordingIndicator() {
    final isDark = AppColors.isDarkMode(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFFEF4444).withOpacity(0.15)
            : const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFEF4444).withOpacity(0.3),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.4, end: 1.0),
            duration: const Duration(milliseconds: 700),
            builder: (_, v, child) => Opacity(opacity: v, child: child),
            child: Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: Color(0xFFEF4444),
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Enregistrement en cours...',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFFEF4444),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            _formatDuration(_recordDuration),
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFFEF4444),
              fontWeight: FontWeight.w700,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _cancelRecording,
            child: const Text(
              'Annuler',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFFEF4444),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── SÉLECTION PIÈCE JOINTE ───────────────────────────────────────────────
  Future<void> _showAttachmentMenu() async {
    await _pickAnyFile();
  }

  Future<void> _pickAnyFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );
      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final fileName = file.path.toLowerCase();

        setState(() {
          _attachedFile = file;
          _recordedPath = null;
          _recordDuration = Duration.zero;
          _hasContent = true;

          if (fileName.endsWith('.jpg') ||
              fileName.endsWith('.jpeg') ||
              fileName.endsWith('.png') ||
              fileName.endsWith('.gif')) {
            _attachmentType = AttachmentType.image;
          } else if (fileName.endsWith('.webm') ||
              fileName.endsWith('.mp3') ||
              fileName.endsWith('.wav') ||
              fileName.endsWith('.m4a')) {
            _attachmentType = AttachmentType.audio;
          } else {
            _attachmentType = AttachmentType.none;
          }
        });
      }
    } catch (e) {
      _showError('Erreur: $e');
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  ENREGISTREMENT AUDIO
  // ════════════════════════════════════════════════════════════════════════════

  Future<void> _startRecording() async {
    try {
      final hasPermission = await _audioRecorder!.hasPermission();
      if (!hasPermission) {
        _showError('Permission micro refusée');
        return;
      }
      final dir = await getTemporaryDirectory();
      // On enregistre directement en M4A (AAC natif sur iOS et Android)
      final path =
          '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _audioRecorder!.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: path,
      );
      _recordDuration = Duration.zero;
      _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted)
          setState(() => _recordDuration += const Duration(seconds: 1));
      });
      setState(() => _isRecording = true);
    } catch (e) {
      _showError('Erreur micro: $e');
    }
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;
    _recordTimer?.cancel();
    final path = await _audioRecorder?.stop();
    if (path != null) {
      _recordedPath = path;
      _attachedFile = File(path);
      _attachmentType = AttachmentType.audio;
    }
    setState(() {
      _isRecording = false;
      _hasContent = true;
    });
  }

  void _cancelRecording() {
    if (!_isRecording) return;
    _recordTimer?.cancel();
    _audioRecorder?.stop();
    setState(() {
      _isRecording = false;
      _recordDuration = Duration.zero;
      _recordedPath = null;
      _hasContent =
          _messageController.text.trim().isNotEmpty || _attachedFile != null;
    });
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  ENVOI DU MESSAGE
  // ════════════════════════════════════════════════════════════════════════════

  Future<void> _sendMessage() async {
    final currentUser = AuthService.instance.getCurrentUser();
    if (currentUser == null) {
      _showError('Veuillez vous connecter');
      return;
    }
    if (!_hasStudentContext) {
      _showError('Contexte élève manquant');
      return;
    }

    final message = _messageController.text.trim();
    final bool hasAudio =
        _attachmentType == AttachmentType.audio && _attachedFile != null;
    final bool hasImage =
        _attachmentType == AttachmentType.image && _attachedFile != null;
    final bool hasFile = _attachedFile != null;

    if (message.isEmpty && !hasFile) {
      _showError('Écrivez un message ou joignez un fichier');
      return;
    }

    final optimisticBody = message.isNotEmpty
        ? message
        : (hasAudio
              ? 'Note vocale'
              : hasImage
              ? 'Image'
              : 'Document');

    final optimisticMsg = _LocalMessage(
      body: optimisticBody,
      isMe: true,
      time: DateTime.now(),
      attachmentType: hasAudio
          ? AttachmentType.audio
          : hasImage
          ? AttachmentType.image
          : AttachmentType.none,
      isPending: true,
    );

    final File? fileToSend = _attachedFile;

    setState(() {
      _localMessages = [..._localMessages, optimisticMsg];
      _isSending = true;
      _messageController.clear();
      _attachedFile = null;
      _attachmentType = AttachmentType.none;
      _recordedPath = null;
      _recordDuration = Duration.zero;
      _hasContent = false;
    });

    _scrollToBottom();

    try {
      final messageService = MessageService();
      Map<String, dynamic> result;

      if (hasAudio) {
        result = await messageService.sendVoiceMessage(
          userPhoneNumber: currentUser.phone,
          content: optimisticBody,
          subject: 'Message de la part de votre enfant',
          codeEcole: _args!.ecoleCode,
          matricule: _args!.studentMatricule,
          audioFile: fileToSend!,
        );
      } else if (hasImage) {
        result = await messageService.sendImageMessage(
          userPhoneNumber: currentUser.phone,
          content: optimisticBody,
          subject: 'Message de la part de votre enfant',
          codeEcole: _args!.ecoleCode,
          matricule: _args!.studentMatricule,
          imageFile: fileToSend!,
        );
      } else if (hasFile) {
        result = await messageService.sendFileMessage(
          userPhoneNumber: currentUser.phone,
          content: optimisticBody,
          subject: 'Message de la part de votre enfant',
          codeEcole: _args!.ecoleCode,
          matricule: _args!.studentMatricule,
          file: fileToSend!,
        );
      } else {
        result = await messageService.sendTextMessage(
          userPhoneNumber: currentUser.phone,
          content: message,
          subject: 'Message de la part de votre enfant',
          codeEcole: _args!.ecoleCode,
          matricule: _args!.studentMatricule,
        );
      }

      if (result['success'] == true) {
        await Future.delayed(const Duration(milliseconds: 600));
        await _loadConversations(silent: true);
        _showSuccess(result['message'] ?? 'Message envoyé !');
      } else {
        setState(() {
          _localMessages = _localMessages
              .where((m) => !identical(m, optimisticMsg))
              .toList();
        });
        _showError(result['message'] ?? 'Erreur lors de l\'envoi');
      }
    } catch (e) {
      setState(() {
        _localMessages = _localMessages
            .where((m) => !identical(m, optimisticMsg))
            .toList();
      });
      _showError('Erreur: $e');
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  // ─── FORMAT DATE ──────────────────────────────────────────────────────────
  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) {
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
    if (diff.inDays == 1) return 'Hier';
    if (diff.inDays < 7) return 'Il y a ${diff.inDays}j';
    return '${date.day}/${date.month}/${date.year}';
  }
}

// ─── ÉCRAN VISUALISATION IMAGE ────────────────────────────────────────────────
class _ImageViewerScreen extends StatelessWidget {
  final String imageUrl;

  const _ImageViewerScreen({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.contain,
            placeholder: (context, url) => const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            errorWidget: (context, url, error) => const Center(
              child: Icon(Icons.broken_image, size: 64, color: Colors.white54),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── WIDGET LECTEUR AUDIO ─────────────────────────────────────────────────────
//
// Stratégie de lecture selon le format reçu :
//   • .m4a / .mp3 / .wav / .webm → lecture directe via AudioPlayers
//
class _AudioBubble extends StatefulWidget {
  final String url;
  final bool isMe;

  const _AudioBubble({required this.url, required this.isMe});

  @override
  State<_AudioBubble> createState() => _AudioBubbleState();
}

class _AudioBubbleState extends State<_AudioBubble> {
  late AudioPlayer _player;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _total = Duration.zero;
  bool _isLoading = true;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  INITIALISATION DU LECTEUR
  // ════════════════════════════════════════════════════════════════════════════

  Future<void> _initializePlayer() async {
    try {
      _player = AudioPlayer();

      // Abonnements aux événements du lecteur
      _player.onDurationChanged.listen((d) {
        if (mounted) setState(() => _total = d);
      });
      _player.onPositionChanged.listen((p) {
        if (mounted) setState(() => _position = p);
      });
      _player.onPlayerStateChanged.listen((s) {
        if (mounted) setState(() => _isPlaying = s == PlayerState.playing);
      });
      _player.onPlayerComplete.listen((_) {
        if (mounted) {
          setState(() {
            _isPlaying = false;
            _position = Duration.zero;
          });
        }
      });

      if (widget.url.isEmpty) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      // ── Chargement de la source audio ───────────────────────────────────
      if (widget.url.startsWith('http://') || widget.url.startsWith('https://')) {
        // Source réseau (M4A, MP3, WebM distant, etc.)
        print('🌐 [AudioBubble] Chargement URL réseau: ${widget.url}');
        await _player.setSourceUrl(widget.url);
      } else {
        // Source locale (M4A enregistré)
        final file = File(widget.url);
        if (!await file.exists()) {
          print('❌ [AudioBubble] Fichier local introuvable: ${widget.url}');
          if (mounted) setState(() => _isLoading = false);
          return;
        }
        final size = await file.length();
        print('📁 [AudioBubble] Fichier local: ${widget.url} ($size bytes)');
        await _player.setSource(DeviceFileSource(widget.url));
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
          _isInitialized = true;
        });
      }
    } catch (e) {
      print('❌ [AudioBubble] Erreur init player: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  CONTRÔLES LECTURE
  // ════════════════════════════════════════════════════════════════════════════

  Future<void> _togglePlayback() async {
    if (!_isInitialized) return;
    if (_isPlaying) {
      await _player.pause();
    } else {
      // Rembobiner si lecture terminée
      if (_total > Duration.zero && _position >= _total) {
        await _player.seek(Duration.zero);
      }
      await _player.resume();
    }
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  BUILD
  // ════════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDarkMode(context);
    final Color colorMe = isDark ? const Color(0xFFE1F5FE) : const Color(0xFF01579B);
    final Color colorOther = isDark ? const Color(0xFFE8F5E8) : const Color(0xFF1B5E20);
    
    final color = widget.isMe ? colorMe : colorOther;
    final trackColor = color.withOpacity(0.25);

    // ── État : chargement initial ──────────────────────────────────────────
    if (_isLoading) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Chargement...',
            style: TextStyle(
              fontSize: 11,
              color: color.withOpacity(0.7),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      );
    }

    // ── État : erreur (non initialisé après chargement) ───────────────────
    if (!_isInitialized) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: Colors.red[300], size: 20),
          const SizedBox(width: 6),
          Text(
            'Audio indisponible',
            style: TextStyle(fontSize: 11, color: color.withOpacity(0.7)),
          ),
        ],
      );
    }

    // ── État : lecteur prêt ───────────────────────────────────────────────
    final double progress = (_total.inMilliseconds > 0)
        ? (_position.inMilliseconds / _total.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Bouton play/pause
        GestureDetector(
          onTap: _togglePlayback,
          child: Icon(
            _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
            color: color,
            size: 32,
          ),
        ),
        const SizedBox(width: 8),
        // Barre de progression + durée
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 100,
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: trackColor,
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${_formatDuration(_position)} / ${_formatDuration(_total)}',
              style: TextStyle(fontSize: 10, color: color.withOpacity(0.8)),
            ),
          ],
        ),
      ],
    );
  }
}
