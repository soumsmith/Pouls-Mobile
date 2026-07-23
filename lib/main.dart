import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'screens/cart_screen.dart';
import 'screens/orders_screen.dart';
import 'screens/login_screen.dart';
import 'screens/inscription_screen.dart';
import 'models/child.dart';
import 'services/theme_service.dart';
import 'services/database_service.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'services/onesignal_service.dart';
import 'services/connectivity_service.dart';
import 'utils/notification_helper.dart';

// NavigatorKey global pour accéder au contexte depuis n'importe quel écran
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser les services de l'application
  try {
    // Initialiser Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialisé');

    // Initialiser la base de données
    await DatabaseService.instance.database;
    print('✅ Base de données initialisée');

    // Déconnecter l'utilisateur à chaque démarrage (pas de session persistante)
    await AuthService.instance.logout();
    print(
      '✅ Service d\'authentification initialisé (session effacée au démarrage)',
    );

    // Initialiser OneSignal Push Notifications
    await OneSignalService().init();
    print('✅ OneSignal Push Notifications initialisé');

    // Initialiser les notifications locales
    await NotificationService().init();
    print('✅ Service de notifications initialisé');

    // Initialiser le service de connectivité
    await ConnectivityService().init();
    print('✅ Service de connectivité initialisé');
  } catch (e) {
    print('⚠️ Erreur lors de l\'initialisation des services: $e');
    // Continuer même si l'initialisation échoue
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final ThemeService _themeService = ThemeService();

  @override
  void initState() {
    super.initState();
    _themeService.loadTheme();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _themeService,
      builder: (context, child) {
        return ScreenUtilInit(
          designSize: const Size(375, 812),
          minTextAdapt: true,
          splitScreenMode: true,
          builder: (context, child) {
            return MaterialApp(
              navigatorKey: navigatorKey,
              scaffoldMessengerKey: scaffoldMessengerKey,
              title: 'Parents Responsable',
              debugShowCheckedModeBanner: false,
              theme: _themeService.lightTheme,
              darkTheme: _themeService.darkTheme,
              themeMode: _themeService.isDarkMode
                  ? ThemeMode.dark
                  : ThemeMode.light,
              builder: (context, child) => child ?? const SizedBox.shrink(),
              home: const SplashScreen(),
              // home: InscriptionWizardScreen(
              //   child: Child(
              //     id: '1',
              //     firstName: 'Test',
              //     lastName: 'Enfant',
              //     establishment: 'École Test',
              //     grade: 'Classe Test',
              //     parentId: 'parent1',
              //     matricule: '10307',
              //   ),
              // ),
              routes: {
                '/login': (context) => const LoginScreen(),
                '/cart': (context) => const CartScreen(),
                '/orders': (context) => const OrdersScreen(),
              },
            );
          },
        );
      },
    );
  }
}
