import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'widgets/main_screen_wrapper.dart';

/// Widget principal de l'application
class App extends StatelessWidget {
  final Widget? initialExtraScreen;

  const App({super.key, this.initialExtraScreen});

  @override
  Widget build(BuildContext context) {
    return MainScreenWrapper(
      child: const HomeScreen(),
      initialExtraScreen: initialExtraScreen,
    );
  }
}
