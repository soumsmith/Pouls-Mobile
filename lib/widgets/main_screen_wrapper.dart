import 'dart:async';
import 'package:flutter/material.dart';
import '../widgets/bottom_nav.dart';
import '../screens/home_screen.dart';
import '../widgets/bottom_sheet_menu.dart';
import '../screens/establishment_screen.dart';
import '../screens/child_list_screen.dart';
import '../screens/shop_screen.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../config/app_config.dart';
import '../config/app_colors.dart';
import '../services/api_service.dart';
import '../services/mock_api_service.dart';
import '../services/remote_api_service.dart';
import '../services/text_size_service.dart';

/// Wrapper principal qui contient le BottomNav et gère la navigation
class MainScreenWrapper extends StatefulWidget {
  final Widget? child;
  final int initialIndex;

  const MainScreenWrapper({super.key, this.child, this.initialIndex = 0});

  @override
  State<MainScreenWrapper> createState() => _MainScreenWrapperState();

  /// Récupère l'instance de MainScreenWrapper depuis le contexte
  static _MainScreenWrapperState of(BuildContext context) {
    return context.findAncestorStateOfType<_MainScreenWrapperState>()!;
  }

  /// Récupère l'instance de MainScreenWrapper depuis le contexte (peut retourner null)
  static _MainScreenWrapperState? maybeOf(BuildContext context) {
    return context.findAncestorStateOfType<_MainScreenWrapperState>();
  }
}

class _MainScreenWrapperState extends State<MainScreenWrapper> {
  late int _currentIndex;
  late ApiService _apiService;
  String? _currentUserId;
  StreamSubscription<Map<String, dynamic>>? _notificationSubscription;
  Widget? _currentChildDetailScreen;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _apiService = AppConfig.MOCK_MODE ? MockApiService() : RemoteApiService();
    final user = AuthService.instance.getCurrentUser();
    _currentUserId = user?.id;
    _setupNotificationListener();
  }

  void _setupNotificationListener() {
    try {
      _notificationSubscription = NotificationService().notificationStream
          .listen((notificationData) => _handleNotification(notificationData));
    } catch (e) {
      print('⚠️ NotificationService non disponible: $e');
    }
  }

  void _handleNotification(Map<String, dynamic> data) {
    final title = data['title'] as String? ?? 'Notification';
    final body = data['body'] as String? ?? '';
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.getSurfaceColor(isDark),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.getTextColor(isDark),
                ),
              ),
              Text(
                body,
                style: TextStyle(
                  color: AppColors.getTextColor(
                    isDark,
                    type: TextType.secondary,
                  ),
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).padding.bottom + 80, // Espace pour la bottom nav
            top: 16,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          action: SnackBarAction(
            label: 'Fermer',
            textColor: AppColors.primary,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }

  ApiService get apiService => _apiService;
  String? get currentUserId => _currentUserId;

  /// Met à jour l'utilisateur actuel (utile après reconnexion)
  void refreshCurrentUser() {
    final user = AuthService.instance.getCurrentUser();
    _currentUserId = user?.id;
  }

  /// Met à jour l'index de l'onglet actif (utilisé par les menus externes)
  void updateCurrentIndex(int index) {
    setState(() {
      _currentIndex = index;
      _currentChildDetailScreen = null;
    });
  }

  /// Navigue vers l'écran de détail d'un enfant
  void navigateToChildDetail(dynamic child) {
    setState(() {
      _currentChildDetailScreen = ChildListScreen(child: child);
      _currentIndex = -1; // Désactive tous les onglets du bottom nav
    });
  }

  /// Retourne à l'écran principal
  void navigateToHome() {
    setState(() {
      _currentIndex = 0; // Retour à l'onglet Accueil
      _currentChildDetailScreen = null;
    });
  }

  void _onTabTapped(int index) {
    if (index == 3) {
      showMenuBottomSheet(context);
    } else {
      setState(() {
        _currentIndex = index;
        _currentChildDetailScreen =
            null; // Retour à l'écran principal si on change d'onglet
      });
    }
  }

  Widget _getCurrentScreen() {
    if (_currentChildDetailScreen != null) {
      return _currentChildDetailScreen!;
    }

    switch (_currentIndex) {
      case 0:
        return const HomeScreen();
      case 1:
        return const LibraryScreen();
      case 2:
        return const EstablishmentScreen();
      default:
        return const HomeScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          if (widget.child != null && widget.child is MainScreenChild)
            widget.child!
          else
            _getCurrentScreen(),
          // Bottom navigation with SafeArea to handle system padding
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              top: false,
              child: BottomNav(
                currentIndex: _currentIndex,
                onTap: _onTabTapped,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Interface pour les écrans qui peuvent être affichés dans le MainScreenWrapper
abstract class MainScreenChild {
  const MainScreenChild();
}

/// Écran placeholder pour les notes
class NotesPlaceholderScreen extends StatelessWidget
    implements MainScreenChild {
  const NotesPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Notes',
          style: TextStyle(color: AppColors.getTextColor(isDark)),
        ),
        backgroundColor: AppColors.getSurfaceColor(isDark),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: 100, // Padding pour le dock flottant
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.grade,
                size: 64,
                color: AppColors.getTextColor(isDark, type: TextType.secondary),
              ),
              const SizedBox(height: 16),
              Text(
                'Sélectionnez un enfant depuis l\'écran d\'accueil',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.getTextColor(isDark),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
