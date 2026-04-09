import 'package:flutter/material.dart';
import '../models/child.dart';
import '../models/student_message.dart';
import '../services/student_message_service.dart';
import '../services/text_size_service.dart';
import '../services/auth_service.dart';
import '../config/app_colors.dart';
import '../services/text_size_service.dart' as text_service;
import '../widgets/snackbar.dart';

/// Écran de messagerie spécifique à un élève
class StudentMessagesScreen extends StatefulWidget {
  final Child child;

  const StudentMessagesScreen({
    super.key,
    required this.child,
  });

  @override
  State<StudentMessagesScreen> createState() => _StudentMessagesScreenState();
}

class _StudentMessagesScreenState extends State<StudentMessagesScreen>
    with TickerProviderStateMixin {
  List<StudentMessage> _messages = [];
  bool _isLoading = true;
  String? _errorMessage;
  final TextSizeService _textSizeService = TextSizeService();
  final StudentMessageService _messageService = StudentMessageService();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

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
    
    _loadMessages();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final studentMatricule = widget.child.matricule ?? widget.child.id;
      final currentUser = AuthService.instance.getCurrentUser();
      
      if (currentUser == null) {
        throw Exception('Aucun utilisateur connecté');
      }
      
      print('🔄 Chargement des messages pour l\'élève: ${widget.child.firstName} (matricule: $studentMatricule)');
      print('📋 Matricule: $studentMatricule');
      print('✅ Matricule valide, début du chargement...');
      print('📡 Appel du service StudentMessageService...');
      
      final messages = await _messageService.getMessagesForStudent(
        currentUser.phone,
        studentMatricule,
      );
      
      setState(() {
        _messages = messages;
        _isLoading = false;
      });
      
      print('✅ Messages chargés: ${messages.length}');
    } catch (e) {
      print('??? Erreur lors du chargement des messages: $e');
      
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
      
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshMessages() async {
    await _loadMessages();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Scaffold(
              backgroundColor: AppColors.getSurfaceColor(isDark),
              body: Stack(
                children: [
                  _buildBody(isDark),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody(bool isDark) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Chargement des messages...',
              style: TextStyle(
                color: AppColors.getTextColor(isDark),
                fontSize: _textSizeService.getScaledFontSize(16),
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Erreur de chargement',
              style: TextStyle(
                color: AppColors.getTextColor(isDark),
                fontSize: _textSizeService.getScaledFontSize(18),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.getTextColor(isDark, type: TextType.secondary),
                fontSize: _textSizeService.getScaledFontSize(14),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _refreshMessages,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.mail_outline,
              size: 64,
              color: AppColors.getTextColor(isDark, type: TextType.secondary),
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun message',
              style: TextStyle(
                color: AppColors.getTextColor(isDark),
                fontSize: _textSizeService.getScaledFontSize(18),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Il n\'y a aucun message pour ${widget.child.firstName}',
              style: TextStyle(
                color: AppColors.getTextColor(isDark, type: TextType.secondary),
                fontSize: _textSizeService.getScaledFontSize(14),
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _refreshMessages,
              icon: Icon(
                Icons.refresh,
                size: 16,
                color: AppColors.getTextColor(isDark),
              ),
              label: Text(
                'Actualiser',
                style: TextStyle(
                  color: AppColors.getTextColor(isDark),
                  fontSize: _textSizeService.getScaledFontSize(14),
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: AppColors.getTextColor(isDark, type: TextType.secondary),
                  width: 1,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                elevation: 0,
                backgroundColor: Colors.transparent,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshMessages,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _messages.length,
        itemBuilder: (context, index) {
          final message = _messages[index];
          return _buildMessageCard(message, isDark);
        },
      ),
    );
  }

  Widget _buildMessageCard(StudentMessage message, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.getSurfaceColor(isDark),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: message.isUnread 
              ? AppColors.primary.withOpacity(0.3)
              : AppColors.getBorderColor(isDark),
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
          onTap: () => _showMessageDetails(message, isDark),
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
                          color: AppColors.getTextColor(isDark),
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
                    color: AppColors.getTextColor(isDark, type: TextType.secondary),
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
                      color: AppColors.getTextColor(isDark, type: TextType.secondary),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      message.formattedDate,
                      style: TextStyle(
                        color: AppColors.getTextColor(isDark, type: TextType.secondary),
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

  void _showMessageDetails(StudentMessage message, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.getSurfaceColor(isDark),
        title: Text(
          message.titre,
          style: TextStyle(
            color: AppColors.getTextColor(isDark),
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
                  color: AppColors.getTextColor(isDark),
                  fontSize: _textSizeService.getScaledFontSize(14),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: AppColors.getTextColor(isDark, type: TextType.secondary),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Envoyé le: ${message.formattedDate}',
                    style: TextStyle(
                      color: AppColors.getTextColor(isDark, type: TextType.secondary),
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
                    color: AppColors.getTextColor(isDark, type: TextType.secondary),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Statut: ${message.formattedStatut}',
                    style: TextStyle(
                      color: AppColors.getTextColor(isDark, type: TextType.secondary),
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
}
