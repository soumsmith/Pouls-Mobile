import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'screens/splash_screen.dart';
import 'screens/cart_screen.dart';
import 'screens/orders_screen.dart';
import 'screens/login_screen.dart';
import 'screens/inscription_screen.dart';
import 'models/child.dart';
import 'services/theme_service.dart';
import 'services/database_service.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser les services de l'application
  try {
    // Initialiser la base de données
    await DatabaseService.instance.database;
    print('✅ Base de données initialisée');

    // Charger la session sauvegardée
    await AuthService.instance.loadSavedSession();
    print('✅ Service d\'authentification initialisé');
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
              title: 'Parents Responsable',
              debugShowCheckedModeBanner: false,
              theme: _themeService.lightTheme,
              darkTheme: _themeService.darkTheme,
              themeMode: _themeService.isDarkMode
                  ? ThemeMode.dark
                  : ThemeMode.light,
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
