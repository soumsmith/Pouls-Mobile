import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import '../widgets/subtle_retry_button.dart';

/// Exemples d'utilisation du SubtleRetryButton avec différentes couleurs
class SubtleRetryButtonExamples extends StatelessWidget {
  const SubtleRetryButtonExamples({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SubtleRetryButton Examples'),
        backgroundColor: AppColors.screenSurface,
      ),
      backgroundColor: AppColors.screenSurface,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'SubtleRetryButton (fond transparent)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.screenTextPrimary,
              ),
            ),
            const SizedBox(height: 16),
            
            const Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                SubtleRetryButton(
                  onTap: _dummyAction,
                  color: AppColors.screenOrange,
                ),
                SubtleRetryButton(
                  onTap: _dummyAction,
                  color: Colors.green,
                ),
                SubtleRetryButton(
                  onTap: _dummyAction,
                  color: Colors.blue,
                ),
                SubtleRetryButton(
                  onTap: _dummyAction,
                  color: Colors.red,
                ),
                SubtleRetryButton(
                  onTap: _dummyAction,
                  color: Colors.purple,
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            const Text(
              'SubtleRetryButtonFilled (fond plein)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.screenTextPrimary,
              ),
            ),
            const SizedBox(height: 16),
            
            const Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                SubtleRetryButtonFilled(
                  onTap: _dummyAction,
                  color: AppColors.screenOrange,
                ),
                SubtleRetryButtonFilled(
                  onTap: _dummyAction,
                  color: Colors.green,
                ),
                SubtleRetryButtonFilled(
                  onTap: _dummyAction,
                  color: Colors.blue,
                ),
                SubtleRetryButtonFilled(
                  onTap: _dummyAction,
                  color: Colors.red,
                ),
                SubtleRetryButtonFilled(
                  onTap: _dummyAction,
                  color: Colors.purple,
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            const Text(
              'SubtleRetryButtonWithText (avec texte)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.screenTextPrimary,
              ),
            ),
            const SizedBox(height: 16),
            
            const Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                SubtleRetryButtonWithText(
                  onTap: _dummyAction,
                  color: AppColors.screenOrange,
                  text: 'Réessayer',
                ),
                SubtleRetryButtonWithText(
                  onTap: _dummyAction,
                  color: Colors.green,
                  text: 'Actualiser',
                ),
                SubtleRetryButtonWithText(
                  onTap: _dummyAction,
                  color: Colors.blue,
                  text: 'Recharger',
                ),
                SubtleRetryButtonWithText(
                  onTap: _dummyAction,
                  color: Colors.red,
                  text: 'Corriger',
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            const Text(
              'Tailles personnalisées',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.screenTextPrimary,
              ),
            ),
            const SizedBox(height: 16),
            
            const Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                SubtleRetryButton(
                  onTap: _dummyAction,
                  color: AppColors.screenOrange,
                  size: 32,
                  iconSize: 14,
                ),
                SubtleRetryButton(
                  onTap: _dummyAction,
                  color: AppColors.screenOrange,
                  size: 40,
                  iconSize: 18,
                ),
                SubtleRetryButton(
                  onTap: _dummyAction,
                  color: AppColors.screenOrange,
                  size: 48,
                  iconSize: 22,
                ),
                SubtleRetryButton(
                  onTap: _dummyAction,
                  color: AppColors.screenOrange,
                  size: 56,
                  iconSize: 26,
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            const Text(
              'Sans ombre',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.screenTextPrimary,
              ),
            ),
            const SizedBox(height: 16),
            
            const Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                SubtleRetryButton(
                  onTap: _dummyAction,
                  color: AppColors.screenOrange,
                  showShadow: false,
                ),
                SubtleRetryButtonFilled(
                  onTap: _dummyAction,
                  color: AppColors.screenOrange,
                  showShadow: false,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  static void _dummyAction() {
    // Action de démonstration
  }
}
