import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import '../services/message_service.dart';
import '../services/auth_service.dart';
import '../services/message_api_service.dart';
import '../models/ecole.dart';
import '../models/conversation.dart';
import '../config/app_colors.dart';
import '../services/text_size_service.dart';
import '../widgets/custom_sliver_app_bar.dart';
import '../widgets/snackbar.dart';

// ─── ENUM : types de pièce jointe ────────────────────────────────────────────
enum AttachmentType { none, image, audio }

// ─── Modèle local pour les messages affichés ────────────────────────────────
class _LocalMessage {
  final String body;
  final bool isMe;
  final DateTime time;
  final AttachmentType attachmentType;
  final bool isPending; // true = envoi optimiste, pas encore confirmé

  const _LocalMessage({
    required this.body,
    required this.isMe,
    required this.time,
    this.attachmentType = AttachmentType.none,
    this.isPending = false,
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
  /// Arguments optionnels. Si null → mode liste générale (non utilisé ici).
  final StudentMessageArgs? studentArgs;

  const MessagesScreen({super.key, this.studentArgs});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen>
    with SingleTickerProviderStateMixin {
  // ─── Conversations ──────────────────────────────────────────────────────
  List<Conversation> _conversations = [];

  /// Liste locale de messages fusionnés (API + optimistes)
  List<_LocalMessage> _localMessages = [];

  bool _isLoading = true;
  final TextSizeService _textSizeService = TextSizeService();
  final MessageApiService _messageApiService = MessageApiService();
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

  // ════════════════════════════════════════════════════════════════════════════
  //  GETTERS de contexte élève
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
    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _loadConversations();
    _messageController.addListener(() {
      final has = _messageController.text.trim().isNotEmpty ||
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
    super.dispose();
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  DATA
  // ════════════════════════════════════════════════════════════════════════════

  /// Convertit les conversations API en liste plate de _LocalMessage
  List<_LocalMessage> _conversationsToLocalMessages(
      List<Conversation> conversations) {
    final currentUser = AuthService.instance.getCurrentUser();
    final messages = <_LocalMessage>[];

    for (final conv in conversations) {
      for (final msg in conv.messages) {
        final isMe = currentUser != null &&
            (msg.senderPseudo
                    .toLowerCase()
                    .contains(currentUser.fullName.toLowerCase()) ||
                (currentUser.phone.isNotEmpty &&
                    msg.senderPseudo
                        .toLowerCase()
                        .contains(currentUser.phone.toLowerCase())));
        messages.add(_LocalMessage(
          body: msg.body,
          isMe: isMe,
          time: conv.lastMessageAt,
        ));
      }
    }
    return messages;
  }

  Future<void> _loadConversations({bool silent = false}) async {
    if (!silent) setState(() => _isLoading = true);
    try {
      final currentUser = AuthService.instance.getCurrentUser();
      if (currentUser == null) {
        throw Exception('Aucun utilisateur connecté');
      }

      final conversations = await _messageApiService.getMessagesForStudent(
        currentUser.phone,
        _args?.studentMatricule ?? '',
      );

      if (!mounted) return;

      setState(() {
        _conversations = conversations;
        // Remplacer les messages locaux par ceux de l'API
        // (supprime les messages "pending" confirmés)
        _localMessages = _conversationsToLocalMessages(conversations);
        _isLoading = false;
      });

      if (!silent) {
        _fadeController.forward(from: 0);
      }
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      
      // Vérifier si l'erreur est un 404 (élève non trouvé)
      if (e.toString().contains('404') || e.toString().contains('Élève non trouvé')) {
        // Afficher une notification snackbar pour l'erreur 404
        CartSnackBar.show(
          context,
          productName: 'Élève non trouvé',
          message: 'Vérifiez le matricule de l\'élève',
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        );
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(color: Colors.white)),
      backgroundColor: Colors.red[400],
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).padding.bottom + 80,
      ),
    ));
  }

  void _showSuccess(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(color: Colors.white)),
      backgroundColor: Colors.green[500],
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).padding.bottom + 80,
      ),
    ));
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  BUILD PRINCIPAL
  // ════════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light
          .copyWith(statusBarColor: const Color(0xFF0288D1)),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: CustomScrollView(
          slivers: [
            _buildCustomAppBar(),
            SliverFillRemaining(
              child: Column(
                children: [
                  Expanded(child: _buildConversationBody()),
                  _buildComposeBar(),
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
      titleTextStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
    );
  }

  // ─── ACTIONS PERSONNALISÉES ────────────────────────────────────────────────
  List<Widget> _buildMessageActions() {
    return [
      GestureDetector(
        onTap: () => _loadConversations(),
        child: Container(
          width: 40,
          height: 40,
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(
            Icons.refresh_outlined,
            color: Colors.white,
            size: 18,
          ),
        ),
      ),
      const SizedBox(width: 8),
    ];
  }

  // ─── CORPS CONVERSATION ───────────────────────────────────────────────────
  Widget _buildConversationBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
            color: Color(0xFF0288D1), strokeWidth: 2.5),
      );
    }

    if (_localMessages.isEmpty) {
      return _buildEmptyConversation();
    }

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
            child: const Icon(Icons.chat_bubble_outline,
                size: 36, color: Color(0xFF0288D1)),
          ),
          const SizedBox(height: 16),
          const Text(
            'Aucun message',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.screenTextPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _hasStudentContext
                ? 'Envoyez un message à ${_args!.ecoleName}'
                : 'Démarrez une conversation',
            style: const TextStyle(
                fontSize: 13, color: AppColors.screenTextSecondary),
            textAlign: TextAlign.center,
          ),
        ],
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
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            Container(
              width: 28,
              height: 28,
              margin: const EdgeInsets.only(right: 6, bottom: 2),
              decoration: const BoxDecoration(
                color: Color(0xFFB3E5FC),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.school_outlined,
                  size: 14, color: Color(0xFF0288D1)),
            ),
          ],
          Flexible(
            child: Opacity(
              // Messages en attente légèrement transparents
              opacity: isPending ? 0.65 : 1.0,
              child: Container(
                constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.72),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isMe ? const Color(0xFF0288D1) : Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isMe ? 18 : 4),
                    bottomRight: Radius.circular(isMe ? 4 : 18),
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
                  crossAxisAlignment:
                      isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    // Icône si pièce jointe
                    if (attachmentType != AttachmentType.none) ...[
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            attachmentType == AttachmentType.audio
                                ? Icons.mic
                                : Icons.image_outlined,
                            size: 14,
                            color: isMe
                                ? Colors.white.withOpacity(0.85)
                                : const Color(0xFF0288D1),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            attachmentType == AttachmentType.audio
                                ? 'Note vocale'
                                : 'Image',
                            style: TextStyle(
                              fontSize: 12,
                              color: isMe
                                  ? Colors.white.withOpacity(0.85)
                                  : const Color(0xFF0288D1),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                    ],
                    Text(
                      body,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color: isMe
                            ? Colors.white
                            : AppColors.screenTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          time,
                          style: TextStyle(
                            fontSize: 10,
                            color: isMe
                                ? Colors.white.withOpacity(0.65)
                                : AppColors.screenTextSecondary,
                          ),
                        ),
                        // Indicateur d'envoi en cours
                        if (isPending && isMe) ...[
                          const SizedBox(width: 4),
                          SizedBox(
                            width: 10,
                            height: 10,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white.withOpacity(0.65),
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
          // Aperçu pièce jointe
          if (_attachedFile != null || _recordedPath != null)
            _buildAttachmentPreview(),
          // Indicateur enregistrement
          if (_isRecording) _buildRecordingIndicator(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Bouton pièce jointe
              GestureDetector(
                onTap: _showAttachmentMenu,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F0F0),
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
                        : AppColors.screenTextSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Champ de texte
              Expanded(
                child: Container(
                  constraints:
                      const BoxConstraints(minHeight: 44, maxHeight: 120),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                        color: const Color(0xFFE8E8E8), width: 0.5),
                  ),
                  child: TextField(
                    controller: _messageController,
                    maxLines: null,
                    textInputAction: TextInputAction.newline,
                    style: const TextStyle(
                        fontSize: 14, color: AppColors.screenTextPrimary),
                    decoration: const InputDecoration(
                      hintText: 'Message...',
                      hintStyle:
                          TextStyle(fontSize: 14, color: Color(0xFFBBBBBB)),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Envoyer OU Micro
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
                              color:
                                  const Color(0xFF0288D1).withOpacity(0.3),
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
                                      Colors.white),
                                ),
                              )
                            : const Icon(Icons.send_rounded,
                                color: Colors.white, size: 20),
                      ),
                    )
                  : GestureDetector(
                      onLongPressStart: (_) => _startRecording(),
                      onLongPressEnd: (_) => _stopRecording(),
                      onLongPressCancel: _cancelRecording,
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
                              color: (_isRecording
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
    final isRecordedAudio = _recordedPath != null && _attachedFile == null;
    final fileName = isRecordedAudio
        ? 'Note vocale (${_formatDuration(_recordDuration)})'
        : _attachedFile!.path.split('/').last;
    final isImg = _attachmentType == AttachmentType.image;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: const Color(0xFF0288D1).withOpacity(0.2), width: 0.5),
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
                      fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
                if (isImg && _attachedFile != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Image sélectionnée',
                    style: TextStyle(
                        fontSize: 11,
                        color: const Color(0xFF0288D1).withOpacity(0.7)),
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
                  color: Colors.white, borderRadius: BorderRadius.circular(8)),
              child:
                  const Icon(Icons.close, size: 14, color: Color(0xFF0288D1)),
            ),
          ),
        ],
      ),
    );
  }

  // ─── INDICATEUR ENREGISTREMENT ────────────────────────────────────────────
  Widget _buildRecordingIndicator() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: const Color(0xFFEF4444).withOpacity(0.3), width: 0.5),
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
                  color: Color(0xFFEF4444), shape: BoxShape.circle),
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Enregistrement en cours...',
              style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFFEF4444),
                  fontWeight: FontWeight.w600),
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
                  fontWeight: FontWeight.w600),
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
      final path =
          '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _audioRecorder!
          .start(const RecordConfig(encoder: AudioEncoder.aacLc), path: path);
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
  //  ENVOI DU MESSAGE — avec ajout optimiste immédiat
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

    if (message.isEmpty && !hasAudio && !hasImage) {
      _showError('Écrivez un message ou joignez un fichier');
      return;
    }

    // ── 1. Ajout optimiste immédiat ──────────────────────────────────────────
    final optimisticBody = message.isNotEmpty
        ? message
        : (hasAudio ? 'Note vocale' : 'Image');

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

    setState(() {
      _localMessages = [..._localMessages, optimisticMsg];
      _isSending = true;
      // Réinitialiser la barre de composition immédiatement
      _messageController.clear();
      _attachedFile = null;
      _attachmentType = AttachmentType.none;
      _recordedPath = null;
      _recordDuration = Duration.zero;
      _hasContent = false;
    });

    _scrollToBottom();

    // ── 2. Envoi API ─────────────────────────────────────────────────────────
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
          audioFile: _attachedFile!, // déjà capturé avant le setState
        );
      } else if (hasImage) {
        result = await messageService.sendImageMessage(
          userPhoneNumber: currentUser.phone,
          content: optimisticBody,
          subject: 'Message de la part de votre enfant',
          codeEcole: _args!.ecoleCode,
          matricule: _args!.studentMatricule,
          imageFile: _attachedFile!,
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

      // ── 3a. Succès : rechargement silencieux ─────────────────────────────
      if (result['success'] == true) {
        // Légère pause pour que l'API indexe le message avant rechargement
        await Future.delayed(const Duration(milliseconds: 600));
        await _loadConversations(silent: true);
        _showSuccess(result['message'] ?? 'Message envoyé !');
      } else {
        // ── 3b. Échec : retirer le message optimiste et afficher l'erreur ──
        setState(() {
          _localMessages = _localMessages
              .where((m) => !identical(m, optimisticMsg))
              .toList();
        });
        _showError(result['message'] ?? 'Erreur lors de l\'envoi');
      }
    } catch (e) {
      // ── 3c. Exception : retirer le message optimiste ─────────────────────
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