import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../config/app_colors.dart';
import '../config/app_dimensions.dart';
import '../widgets/custom_button.dart';
import 'signup_screen.dart';
import '../app.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

/// Écran de connexion
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  String _completePhoneNumber = '';

  @override
  void initState() {
    super.initState();
    _loadSavedPhone();
  }

  Future<void> _loadSavedPhone() async {
    final savedPhone = await AuthService.instance.getSavedPhone();
    if (savedPhone != null && mounted) {
      _phoneController.text = savedPhone;
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final phone = _completePhoneNumber.isNotEmpty ? _completePhoneNumber : _phoneController.text.trim();
    final result = await AuthService.instance.loginDirectly(phone);

    setState(() {
      _isLoading = false;
    });

    if (result == DirectLoginResult.success && mounted) {
      // Afficher une notification de connexion réussie
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              const Text('Connexion réussie !'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 1),
        ),
      );
      
      // Attendre 1 seconde avant de rediriger
      await Future.delayed(const Duration(seconds: 1));
      
      // Connexion réussie, naviguer vers l'écran principal
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const App()),
        );
      }
    } else if (result == DirectLoginResult.userNotFound && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Aucun parent lié à ce numéro de téléphone. Veuillez créer un compte.'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Créer un compte',
            textColor: Colors.white,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const SignupScreen(),
                ),
              );
            },
          ),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur lors de la connexion. Veuillez réessayer.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isTablet = AppDimensions.isTablet(context) || AppDimensions.isLargeTablet(context);
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [
                    AppColors.backgroundDark,
                    AppColors.surfaceDark,
                  ]
                : [
                    AppColors.white,
                    AppColors.primaryLight.withOpacity(0.05),
                  ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: AppDimensions.getResponsivePadding(context),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: AppDimensions.getLoginCardMaxWidth(context),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: AppDimensions.getAdaptiveSpacing(context) * 1.5),
                      // Logo minimaliste
                      Center(
                        child: Container(
                          padding: EdgeInsets.all(isTablet ? 24.0 : 16.0),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(isTablet ? 28.0 : 20.0),
                          ),
                          child: Image.asset(
                            'assets/images/logo-app.png',
                            width: AppDimensions.getAdaptiveIconSize(context),
                            height: AppDimensions.getAdaptiveIconSize(context),
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      SizedBox(height: AppDimensions.getAdaptiveSpacing(context)),
                      // Message d'accueil minimaliste
                      Text(
                        'Bienvenue !',
                        style: TextStyle(
                          fontSize: AppDimensions.getFormTitleFontSize(context),
                          fontWeight: FontWeight.w600,
                          color: AppColors.getTextColor(isDark),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Connectez-vous pour suivre le parcours\nscolaire de votre enfant',
                        style: TextStyle(
                          fontSize: AppDimensions.getFormSubtitleFontSize(context),
                          color: AppColors.getTextColor(isDark, type: TextType.secondary),
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: AppDimensions.getFormFieldSpacing(context)),
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.surfaceDark : Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(isTablet ? 20.0 : 16.0),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
                              blurRadius: isTablet ? 12.0 : 10.0,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: IntlPhoneField(
                          controller: _phoneController,
                          initialCountryCode: 'CI', // Côte d'Ivoire par défaut
                          onChanged: (phone) {
                            _completePhoneNumber = phone.completeNumber;
                          },
                          validator: (value) {
                            if (value == null || value.number.isEmpty) {
                              return 'Veuillez entrer votre numéro de téléphone';
                            }
                            return null;
                          },
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: isTablet ? 18.0 : 16.0,
                          ),
                          dropdownTextStyle: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: isTablet ? 18.0 : 16.0,
                          ),
                          flagsButtonPadding: EdgeInsets.symmetric(
                            horizontal: isTablet ? 12.0 : 8.0,
                            vertical: isTablet ? 16.0 : 12.0,
                          ),
                          showCountryFlag: true,
                          dropdownIcon: Icon(
                            Icons.arrow_drop_down,
                            color: Theme.of(context).colorScheme.onSurface,
                            size: isTablet ? 28.0 : 24.0,
                          ),
                          disableLengthCheck: false,
                          decoration: InputDecoration(
                            labelText: 'Numéro de téléphone',
                            hintText: 'XX XX XX XX',
                            labelStyle: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                              fontSize: isTablet ? 16.0 : 14.0,
                            ),
                            hintStyle: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                              fontSize: isTablet ? 16.0 : 14.0,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(isTablet ? 20.0 : 16.0),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(isTablet ? 20.0 : 16.0),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(isTablet ? 20.0 : 16.0),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: isTablet ? 20.0 : 16.0,
                              vertical: isTablet ? 16.0 : 12.0,
                            ),
                            filled: true,
                            fillColor: Colors.transparent,
                          ),
                        ),
                      ),
                      SizedBox(height: AppDimensions.getAdaptiveSpacing(context)),
                      // Bouton connexion minimaliste
                      CustomButton(
                        text: 'Connexion',
                        onPressed: _handleLogin,
                        isLoading: _isLoading,
                      ),
                      SizedBox(height: AppDimensions.getAdaptiveSpacing(context) * 0.75),
                      // Lien créer un compte
                      Center(
                        child: TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const SignupScreen(),
                              ),
                            );
                          },
                          child: Text(
                            'Créer un compte',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500,
                              fontSize: isTablet ? 16.0 : 14.0,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: AppDimensions.getAdaptiveSpacing(context) * 0.75),
                      // Info box minimaliste
                      Container(
                        padding: EdgeInsets.all(isTablet ? 16.0 : 12.0),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(isTablet ? 12.0 : 8.0),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: isTablet ? 20.0 : 16.0,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Après la première connexion, vos informations seront sauvegardées.',
                                style: TextStyle(
                                  fontSize: isTablet ? 14.0 : 12.0,
                                  color: AppColors.getTextColor(isDark, type: TextType.secondary),
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: AppDimensions.getAdaptiveSpacing(context) * 1.5),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
