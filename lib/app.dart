import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'widgets/main_screen_wrapper.dart';

/// Widget principal de l'application
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return const MainScreenWrapper(child: HomeScreen());
  }
}
