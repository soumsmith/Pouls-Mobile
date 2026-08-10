import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'screens/cart_screen.dart';
import 'screens/orders_screen.dart';
import 'screens/login_screen.dart';
import 'screens/inscription_screen.dart';
import 'screens/deep_link_resolver_screen.dart';
import 'models/child.dart';
import 'services/theme_service.dart';
import 'services/database_service.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'services/onesignal_service.dart';
import 'services/connectivity_service.dart';
import 'services/deep_link_service.dart';
import 'utils/notification_helper.dart';

// NavigatorKey global pour accéder au contexte depuis n'importe quel écran
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Services essentiels au premier rendu (état de connexion, deep link
  // éventuel) : on les attend avant runApp(), mais SEULEMENT eux — avant,
  // OneSignal/notifications locales/connectivité étaient aussi awaited ici,
  // ce qui pouvait cumuler plusieurs secondes d'écran blanc (avant même le
  // premier frame Flutter) puisque aucun de ces 3 services n'est nécessaire
  // pour afficher le splash screen ni pour résoudre un deep link.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialisé');

    await DatabaseService.instance.database;
    print('✅ Base de données initialisée');

    // Recharger la session sauvegardée si elle existe (mode invité sinon)
    await AuthService.instance.loadSavedSession();
    print(
      '✅ Service d\'authentification initialisé (session persistante)',
    );

    // Initialiser le service de Deep Linking (doit être prêt avant que
    // MyApp ne s'abonne, pour capturer un éventuel lien de démarrage à froid)
    await DeepLinkService().init();
    print('✅ Deep Link Service initialisé');
  } catch (e) {
    print('⚠️ Erreur lors de l\'initialisation des services essentiels: $e');
    // Continuer même si l'initialisation échoue
  }

  runApp(const MyApp());

  // Services non bloquants pour le premier rendu : lancés en arrière-plan
  // pendant que le splash screen s'affiche déjà, au lieu de retarder
  // runApp() et donc le tout premier frame de l'app.
  unawaited(_initBackgroundServices());
}

Future<void> _initBackgroundServices() async {
  try {
    await OneSignalService().init();
    print('✅ OneSignal Push Notifications initialisé');
  } catch (e) {
    print('⚠️ Erreur init OneSignal: $e');
  }
  try {
    await NotificationService().init();
    print('✅ Service de notifications initialisé');
  } catch (e) {
    print('⚠️ Erreur init NotificationService: $e');
  }
  try {
    await ConnectivityService().init();
    print('✅ Service de connectivité initialisé');
  } catch (e) {
    print('⚠️ Erreur init ConnectivityService: $e');
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final ThemeService _themeService = ThemeService();
  StreamSubscription<DeepLinkData>? _deepLinkSubscription;

  @override
  void initState() {
    super.initState();
    _themeService.loadTheme();
    _listenDeepLinks();
  }

  /// Écoute les deep links entrants et navigue vers l'écran vidéo.
  void _listenDeepLinks() {
    _deepLinkSubscription = DeepLinkService().onLinkReceived.listen(
      (DeepLinkData data) {
        print('📱 [MyApp] Deep Link reçu: $data');
        _pushDeepLinkResolver(data);
      },
    );
    print('✅ [MyApp] Abonné à DeepLinkService().onLinkReceived.');

    // Traite maintenant le lien de démarrage à froid éventuellement capturé
    // par DeepLinkService.init() (appelé avant runApp, donc avant que ce
    // listener n'existe) — sans ça, ce lien serait silencieusement perdu.
    DeepLinkService().consumePendingInitialLink();
  }

  void _pushDeepLinkResolver(DeepLinkData data, {int attempt = 1}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final navigator = navigatorKey.currentState;
      if (navigator == null) {
        print(
          '⚠️ [MyApp] Navigator pas encore prêt (tentative $attempt) pour '
          'deep link $data — nouvel essai dans 300ms.',
        );
        if (attempt < 10) {
          Future.delayed(const Duration(milliseconds: 300), () {
            _pushDeepLinkResolver(data, attempt: attempt + 1);
          });
        } else {
          print(
            '❌ [MyApp] Navigator toujours indisponible après $attempt '
            'tentatives, abandon pour $data.',
          );
        }
        return;
      }
      print('📱 [MyApp] Navigation vers DeepLinkResolverScreen pour $data');
      // pushReplacement (et non push) : au cold start, SplashScreen est
      // encore la route active à ce moment-là. Si on empilait par-dessus
      // avec push, SplashScreen resterait monté "en dessous" avec sa propre
      // navigation différée (Future.delayed vers App()) toujours active ;
      // une fois ce délai écoulé, Navigator.of(context).pushReplacement
      // depuis SplashScreen remplace la route ACTUELLEMENT AU SOMMET du
      // Navigator racine (donc l'écran vidéo, pas SplashScreen lui-même) et
      // ramène l'utilisateur à l'accueil en pleine lecture. pushReplacement
      // ici retire SplashScreen de la pile, ce qui neutralise ce timer
      // (ses callbacks sont déjà protégés par des vérifications `mounted`).
      navigator.pushReplacement(
        MaterialPageRoute(
          builder: (context) => DeepLinkResolverScreen(deepLinkData: data),
        ),
      );
    });
  }

  @override
  void dispose() {
    _deepLinkSubscription?.cancel();
    DeepLinkService().dispose();
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
