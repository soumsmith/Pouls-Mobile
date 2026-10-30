import 'package:flutter/material.dart';
import 'package:parents_responsable/utils/app_http.dart' as http;
import 'dart:convert';
import '../widgets/custom_button.dart';
import '../utils/notification_helper.dart';
import '../config/app_colors.dart';
import '../config/app_config.dart';
import '../config/app_dimensions.dart';
import '../widgets/back_button_widget.dart';
import '../widgets/custom_sliver_app_bar.dart';
import '../widgets/searchable_dropdown.dart';
import '../widgets/components/custom_text_input.dart';
import '../widgets/components/custom_select_input.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

/// Écran de création de compte avec formulaire téléphone
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();
  final _prenomsController = TextEditingController();
  final _passwordController = TextEditingController();
  final _invitationCodeController = TextEditingController();
  final _securityAnswerController = TextEditingController();
  bool _isLoading = false;
  String _completePhoneNumber = '';
  String _selectedSecurityQuestion = 'Quel est votre plat préféré ?';
  bool _acceptConditions = false;

  // Variable pour contrôler l'affichage du mot de passe
  bool _isPasswordVisible = false;

  final List<String> _securityQuestions = [
    'Quel est votre plat préféré ?',
    'Quel est le nom de votre premier animal de compagnie ?',
    'Quelle est votre couleur préférée ?',
    'Quel est votre film préféré ?',
    'Dans quelle ville êtes-vous né(e) ?',
  ];

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    _prenomsController.dispose();
    _passwordController.dispose();
    _invitationCodeController.dispose();
    _securityAnswerController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Extraire le numéro sans l'indicatif
      String phoneNumber;
      if (_completePhoneNumber.isNotEmpty) {
        // Retirer l'indicatif du pays (ex: +225) pour ne garder que le numéro
        phoneNumber = _phoneController.text.trim();
      } else {
        phoneNumber = _phoneController.text.trim();
      }

      final invitationCode = _invitationCodeController.text.trim();
      final userData = {
        'name': _nameController.text.trim(),
        'prenoms': _prenomsController.text.trim(),
        'phone': phoneNumber,
        'password': _passwordController.text,
        'invitation_code': invitationCode.isEmpty ? null : invitationCode,
        'security_question': _selectedSecurityQuestion,
        'security_answer': _securityAnswerController.text.trim(),
        'accept_conditions': true,
      };

      // Log des données à envoyer
      print('📤 ENVOI DE LA REQUÊTE D\'INSCRIPTION');
      print(
        'URL: ${AppConfig.VIE_ECOLES_API_BASE_URL}/espace-parent/inscription',
      );
      print('Méthode: POST');
      print(
        'Headers: Content-Type: application/json, Accept: application/json',
      );
      print('Données utilisateur: ${json.encode(userData)}');
      print('---');

      final response = await http.post(
        Uri.parse(
          '${AppConfig.VIE_ECOLES_API_BASE_URL}/espace-parent/inscription',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(userData),
      );

      // Log de la réponse
      print('📥 RÉPONSE REÇUE');
      print('Code statut: ${response.statusCode}');
      print('Headers: ${response.headers}');
      print('Corps de la réponse: ${response.body}');
      print('---');

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (response.statusCode == 200 || response.statusCode == 201) {
          print('✅ SUCCÈS: Compte créé avec succès');
          print('Redirection vers l\'écran de login...');
          print('---');
          NotificationHelper.showSuccess('Compte créé avec succès!');

          // Naviguer vers l'écran de connexion
          Navigator.of(context).pushReplacementNamed('/login');
        } else {
          print('❌ ERREUR: Échec de la création du compte');
          print('Statut: ${response.statusCode} - ${response.reasonPhrase}');

          String errorMessage = 'Erreur lors de la création du compte';
          try {
            final errorData = json.decode(response.body);
            if (errorData['message'] != null) {
              errorMessage = errorData['message'];
              print('Message d\'erreur API: $errorMessage');

              // Afficher les erreurs de validation spécifiques
              if (errorData['errors'] != null) {
                print('Erreurs de validation détaillées:');
                final errors = errorData['errors'] as Map<String, dynamic>;
                errors.forEach((field, messages) {
                  print('  - $field: $messages');
                });

                // Créer un message d'erreur plus spécifique
                if (errors['invitation_code'] != null) {
                  errorMessage = 'Le code d\'invitation est invalide';
                } else if (errors['phone'] != null) {
                  errorMessage = 'Le numéro de téléphone est invalide';
                } else if (errors['email'] != null) {
                  errorMessage = 'L\'email est invalide';
                } else if (errors['password'] != null) {
                  errorMessage = 'Le mot de passe est invalide';
                }
              }
            } else {
              print('Réponse brute: ${response.body}');
            }
          } catch (e) {
            print('Impossible de parser la réponse d\'erreur: $e');
            print('Réponse brute: ${response.body}');
          }

          NotificationHelper.show(
            message: errorMessage,
            type: NotificationType.error,
            duration: const Duration(seconds: 5),
          );
        }
      }
    } catch (e) {
      print('💥 ERREUR EXCEPTION: Erreur lors de la requête HTTP');
      print('Type d\'erreur: ${e.runtimeType}');
      print('Message d\'erreur: $e');
      print('Stack trace: ${StackTrace.current}');
      print('---');

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        NotificationHelper.showError('Erreur de connexion: ${e.toString()}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isTablet =
        AppDimensions.isTablet(context) || AppDimensions.isLargeTablet(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
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
        child: CustomScrollView(
          slivers: [
            // Utilisation de CustomSliverAppBar
            CustomSliverAppBar(
              title: '',
              automaticallyImplyLeading: true,
              onBackTap: () {
                // Gestion du retour personnalisée
                Navigator.of(context).pop();
              },
              pinned: true,
              floating: false,
              expandedHeight: 0,
              //backgroundColor: Colors.transparent,
            ),

            // Contenu principal
            SliverFillRemaining(
              hasScrollBody: false,
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
                            height:
                                AppDimensions.getAdaptiveSpacing(context) * 0.5,
                          ),
                          // Logo
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
                                width: AppDimensions.getAdaptiveIconSize(
                                  context,
                                ),
                                height: AppDimensions.getAdaptiveIconSize(
                                  context,
                                ),
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          SizedBox(
                            height:
                                AppDimensions.getAdaptiveSpacing(context) * 0.4,
                          ),
                          Text(
                            'CRÉER UN COMPTE',
                            style: TextStyle(
                              fontSize: AppDimensions.getFormTitleFontSize(
                                context,
                              ),
                              fontWeight: FontWeight.w600,
                              color: AppColors.getTextColor(isDark),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Remplissez ce formulaire pour créer votre compte',
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
                            height:
                                AppDimensions.getFormFieldSpacing(context) *
                                0.3,
                          ),
                          // Champ Nom
                          CustomTextInput(
                            label: 'Nom',
                            hint: 'Votre nom',
                            icon: Icons.person_outline,
                            controller: _nameController,
                            required: true,
                            focusBorderColor: AppColors.primary,
                          ),
                          SizedBox(
                            height:
                                AppDimensions.getFormFieldSpacing(context) *
                                0.3,
                          ),
                          // Champ Prénoms
                          CustomTextInput(
                            label: 'Prénoms',
                            hint: 'Vos prénoms',
                            icon: Icons.person_outline,
                            controller: _prenomsController,
                            required: true,
                            focusBorderColor: AppColors.primary,
                          ),
                          SizedBox(
                            height:
                                AppDimensions.getFormFieldSpacing(context) *
                                0.3,
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
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withOpacity(0.5),
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
                                      borderSide: const BorderSide(
                                        color: AppColors.primary,
                                        width: AppDimensions.inputFocusedBorderWidth,
                                      ),
                                    ),
                                    focusedErrorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: Colors.red,
                                        width: AppDimensions.inputFocusedBorderWidth,
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
                          SizedBox(
                            height:
                                AppDimensions.getFormFieldSpacing(context) *
                                0.3,
                          ),
                          // Champ Mot de passe avec bouton d'affichage/masquage
                          CustomTextInput(
                            label: 'Mot de passe',
                            hint: 'Votre mot de passe',
                            icon: Icons.lock_outline,
                            controller: _passwordController,
                            required: true,
                            obscureText: !_isPasswordVisible,
                            focusBorderColor: AppColors.primary,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.7),
                                size: isTablet ? 28.0 : 24.0,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              },
                            ),
                          ),
                          SizedBox(
                            height:
                                AppDimensions.getFormFieldSpacing(context) *
                                0.3,
                          ),
                          // Champ Code d'invitation
                          CustomTextInput(
                            label: 'Code d\'invitation (optionnel)',
                            hint: 'Entrez votre code d\'invitation',
                            icon: Icons.card_giftcard_outlined,
                            controller: _invitationCodeController,
                            focusBorderColor: AppColors.primary,
                          ),
                          SizedBox(
                            height:
                                AppDimensions.getFormFieldSpacing(context) *
                                0.3,
                          ),
                          // Champ Question de sécurité
                          CustomSelectInput(
                            label: 'Question de sécurité',
                            value: _selectedSecurityQuestion,
                            items: _securityQuestions,
                            isDarkMode: isDark,
                            required: true,
                            onChanged: (String newValue) {
                              setState(() {
                                _selectedSecurityQuestion = newValue;
                              });
                            },
                          ),
                          SizedBox(
                            height:
                                AppDimensions.getFormFieldSpacing(context) *
                                0.3,
                          ),
                          // Champ Réponse de sécurité
                          CustomTextInput(
                            label: 'Réponse de sécurité',
                            hint: 'Votre réponse',
                            icon: Icons.security_outlined,
                            controller: _securityAnswerController,
                            required: true,
                            focusBorderColor: AppColors.primary,
                          ),
                          SizedBox(
                            height:
                                AppDimensions.getAdaptiveSpacing(context) * 0.4,
                          ),
                          // Checkbox conditions
                          Row(
                            children: [
                              Checkbox(
                                value: _acceptConditions,
                                onChanged: (value) {
                                  setState(() {
                                    _acceptConditions = value ?? false;
                                  });
                                },
                                activeColor: Colors.green,
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _acceptConditions = !_acceptConditions;
                                    });
                                  },
                                  child: Text(
                                    "J'accepte les conditions d'utilisation",
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface,
                                      fontSize: isTablet ? 16.0 : 14.0,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(
                            height:
                                AppDimensions.getAdaptiveSpacing(context) * 0.4,
                          ),
                          // Bouton créer le compte
                          CustomButton(
                            text: 'CRÉER LE COMPTE',
                            onPressed: _acceptConditions ? _handleSignup : null,
                            isLoading: _isLoading,
                            backgroundColor: _acceptConditions
                                ? Colors.green
                                : Colors.grey,
                          ),
                          SizedBox(
                            height:
                                AppDimensions.getAdaptiveSpacing(context) *
                                0.75,
                          ),
                          SizedBox(
                            height:
                                AppDimensions.getAdaptiveSpacing(context) * 1.5,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
