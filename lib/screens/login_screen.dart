import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../config/app_colors.dart';
import '../config/app_dimensions.dart';
import '../widgets/custom_button.dart';
import 'signup_screen.dart';
import '../app.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import '../widgets/components/custom_text_input.dart';
import 'forgot_password_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/notification_helper.dart';

/// Écran de connexion
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String _completePhoneNumber = '';
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadSavedPhone();
  }

  Future<void> _loadSavedPhone() async {
    final prefs = await SharedPreferences.getInstance();
    final rememberMe = prefs.getBool('remember_me_checked') ?? false;

    if (rememberMe && mounted) {
      setState(() {
        _rememberMe = true;
        final savedPhone = prefs.getString('remembered_phone');
        final savedPassword = prefs.getString('remembered_password');

        if (savedPhone != null) _phoneController.text = savedPhone;
        if (savedPassword != null) _passwordController.text = savedPassword;
      });
    } else {
      // Pour compatibilité avec l'ancien système si l'utilisateur n'avait pas coché
      final savedPhone = await AuthService.instance.getSavedPhone();
      if (savedPhone != null && mounted) {
        _phoneController.text = savedPhone;
      }
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      NotificationHelper.showError('Veuillez renseigner tous les champs requis.');
      return;
    }

    if (_phoneController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      NotificationHelper.showError('Veuillez renseigner tous les champs requis.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Extraire le numéro sans l'indicatif
    String phoneNumber;
    if (_completePhoneNumber.isNotEmpty) {
      // Retirer l'indicatif du pays (ex: +225) pour ne garder que le numéro
      phoneNumber = _phoneController.text.trim();
    } else {
      phoneNumber = _phoneController.text.trim();
    }

    final password = _passwordController.text.trim();

    final result = await AuthService.instance.loginDirectly(
      phoneNumber,
      password,
    );

    setState(() {
      _isLoading = false;
    });

    if (result == DirectLoginResult.success && mounted) {
      // Gestion "Se souvenir de moi"
      final prefs = await SharedPreferences.getInstance();
      if (_rememberMe) {
        await prefs.setBool('remember_me_checked', true);
        await prefs.setString('remembered_phone', phoneNumber);
        await prefs.setString('remembered_password', password);
      } else {
        await prefs.setBool('remember_me_checked', false);
        await prefs.remove('remembered_phone');
        await prefs.remove('remembered_password');
      }

      // Afficher une notification de connexion réussie
      NotificationHelper.showSuccess('Connexion réussie !');

      // Attendre 1 seconde avant de rediriger
      await Future.delayed(const Duration(seconds: 1));

      // Connexion réussie, naviguer vers l'écran principal
      if (mounted) {
        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (_) => const App()));
      }
    } else if (result == DirectLoginResult.userNotFound && mounted) {
      NotificationHelper.show(
        message: 'Aucun parent lié à ce numéro de téléphone. Veuillez créer un compte.',
        type: NotificationType.warning,
        duration: const Duration(seconds: 5),
        actionText: 'Créer un compte',
        onActionPressed: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const SignupScreen()));
        },
      );
    } else if (result == DirectLoginResult.connectionError) {
      // Ne rien faire, l'ApiExceptionHandler a déjà affiché une notification de connexion au haut de l'écran
    } else if (mounted) {
      NotificationHelper.showError('Erreur lors de la connexion. Veuillez réessayer.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isTablet =
        AppDimensions.isTablet(context) || AppDimensions.isLargeTablet(context);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : Colors.white,
      body: Container(
        decoration: BoxDecoration(
          color: isDark ? null : Colors.white,
          gradient: isDark
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.backgroundDark, AppColors.surfaceDark],
                )
              : null,
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
                      SizedBox(
                        height: AppDimensions.getAdaptiveSpacing(context) * 1.5,
                      ),
                      // Logo minimaliste
                      Center(
                        child: Container(
                          padding: EdgeInsets.all(isTablet ? 24.0 : 16.0),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.surfaceDark
                                : Colors.white,
                            borderRadius: BorderRadius.circular(
                              isTablet ? 28.0 : 20.0,
                            ),
                            boxShadow: AppDimensions.getSettingsCardShadow(
                              context,
                            ),
                          ),
                          child: Image.asset(
                            'assets/images/logo-app.png',
                            width: AppDimensions.getAdaptiveIconSize(context),
                            height: AppDimensions.getAdaptiveIconSize(context),
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: AppDimensions.getAdaptiveSpacing(context),
                      ),
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
                          fontSize: AppDimensions.getFormSubtitleFontSize(
                            context,
                          ),
                          color: AppColors.getTextColor(
                            isDark,
                            type: TextType.secondary,
                          ),
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(
                        height: AppDimensions.getFormFieldSpacing(context),
                      ),
                      // Champ Téléphone
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Numéro de téléphone',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? Colors.white70
                                      : AppColors.screenTextSecondary,
                                ),
                              ),
                              const Text(
                                ' *',
                                style: TextStyle(
                                  color: AppColors.screenOrange,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Container(
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.surfaceDark
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: IntlPhoneField(
                              controller: _phoneController,
                              initialCountryCode: 'CI',
                              cursorColor: AppColors.primary,
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
                                fontSize: 14,
                              ),
                              dropdownTextStyle: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: 14,
                              ),
                              flagsButtonPadding: const EdgeInsets.symmetric(
                                horizontal: 8.0,
                                vertical: 12.0,
                              ),
                              showCountryFlag: true,
                              dropdownIcon: Icon(
                                Icons.arrow_drop_down,
                                color: Theme.of(context).colorScheme.onSurface,
                                size: 20,
                              ),
                              disableLengthCheck: false,
                              decoration: InputDecoration(
                                hintText: 'XX XX XX XX',
                                hintStyle: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(0.5),
                                  fontSize: 13,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: isDark
                                        ? const Color(0xFF444444)
                                        : const Color(0xFFCFD4DC),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: isDark
                                        ? const Color(0xFF444444)
                                        : const Color(0xFFCFD4DC),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: AppColors.primary,
                                    width:
                                        AppDimensions.inputFocusedBorderWidth,
                                  ),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.red,
                                    width:
                                        AppDimensions.inputFocusedBorderWidth,
                                  ),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Colors.red,
                                    width: 1.0,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 14,
                                ),
                                filled: true,
                                fillColor: Colors.transparent,
                              ),
                            ),
                          ),
                        ],
                      ),
                      // SizedBox(
                      //   height: AppDimensions.getAdaptiveSpacing(context),
                      // ),
                      // Champ mot de passe
                      CustomTextInput(
                        label: 'Mot de passe',
                        hint: 'Votre mot de passe',
                        icon: Icons.lock_outline,
                        controller: _passwordController,
                        required: true,
                        obscureText: _obscurePassword,
                        focusBorderColor: AppColors.primary,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.7),
                            size: isTablet ? 24.0 : 20.0,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      SizedBox(
                        height: AppDimensions.getAdaptiveSpacing(context),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _rememberMe = !_rememberMe;
                              });
                            },
                            behavior: HitTestBehavior.opaque,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  curve: Curves.easeInOut,
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    color: _rememberMe
                                        ? AppColors.primary
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: _rememberMe
                                          ? AppColors.primary
                                          : (isDark
                                                ? Colors.grey[700]!
                                                : Colors.grey[400]!),
                                      width: 1.5,
                                    ),
                                    boxShadow: _rememberMe
                                        ? [
                                            BoxShadow(
                                              color: AppColors.primary
                                                  .withOpacity(0.3),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: _rememberMe
                                      ? const Icon(
                                          Icons.check,
                                          size: 16,
                                          color: Colors.white,
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Se souvenir de moi',
                                  style: TextStyle(
                                    fontSize: isTablet ? 14.0 : 13.0,
                                    color: AppColors.getTextColor(isDark),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const ForgotPasswordScreen(),
                                ),
                              );
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'Mot de passe oublié ?',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w500,
                                fontSize: isTablet ? 14.0 : 13.0,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: AppDimensions.getAdaptiveSpacing(context),
                      ),
                      // Bouton connexion minimaliste
                      CustomButton(
                        text: 'Connexion',
                        backgroundColor: Colors.green,
                        onPressed: _handleLogin,
                        isLoading: _isLoading,
                      ),
                      SizedBox(
                        height:
                            AppDimensions.getAdaptiveSpacing(context) * 0.75,
                      ),
                      // Bouton créer un compte (style besoin d'aide)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            shadowColor: Colors.transparent,
                            backgroundColor: isDark
                                ? Colors.white.withOpacity(0.08)
                                : const Color(0xFFF2F4F7),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30.0),
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: isTablet ? 22.0 : 18.0,
                              vertical: isTablet ? 14.0 : 12.0,
                            ),
                          ),
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
                              color: isDark ? Colors.white : Colors.black,
                              fontSize: isTablet ? 16.0 : 14.0,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        height:
                            AppDimensions.getAdaptiveSpacing(context) * 0.75,
                      ),
                      // Message de sécurité rassurant (sans fond, centré)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.shield_outlined,
                            size: isTablet ? 18.0 : 15.0,
                            color: AppColors.getTextColor(
                              isDark,
                              type: TextType.secondary,
                            ).withOpacity(0.8),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Connexion sécurisée et données protégées',
                            style: TextStyle(
                              fontSize: isTablet ? 13.0 : 12.0,
                              color: AppColors.getTextColor(
                                isDark,
                                type: TextType.secondary,
                              ),
                              fontWeight: FontWeight.w400,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                      SizedBox(
                        height: AppDimensions.getAdaptiveSpacing(context) * 1.5,
                      ),
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
