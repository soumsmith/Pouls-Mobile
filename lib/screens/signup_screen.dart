import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../widgets/custom_button.dart';
import '../config/app_colors.dart';
import '../config/app_dimensions.dart';
import '../widgets/back_button_widget.dart';
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
      final phone = _completePhoneNumber.isNotEmpty ? _completePhoneNumber : _phoneController.text.trim();
      
      final userData = {
        'name': _nameController.text.trim(),
        'prenoms': _prenomsController.text.trim(),
        'phone': phone,
        'password': _passwordController.text,
        'invitation_code': _invitationCodeController.text.trim(),
        'security_question': _selectedSecurityQuestion,
        'security_answer': _securityAnswerController.text.trim(),
      };

      // Log des données à envoyer
      print('📤 ENVOI DE LA REQUÊTE D\'INSCRIPTION');
      print('URL: https://api2.vie-ecoles.com/api/espace-parent/inscription');
      print('Méthode: POST');
      print('Headers: Content-Type: application/json, Accept: application/json');
      print('Données utilisateur: ${json.encode(userData)}');
      print('---');

      final response = await http.post(
        Uri.parse('https://api2.vie-ecoles.com/api/espace-parent/inscription'),
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Compte créé avec succès!'),
              backgroundColor: Colors.green,
            ),
          );
          
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
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
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
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de connexion: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isTablet = AppDimensions.isTablet(context) || AppDimensions.isLargeTablet(context);
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButtonWidget(
          useContainer: false,
          color: AppColors.getTextColor(isDark),
        ),
      ),
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
                    AppColors.pureWhite,
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
                      SizedBox(height: AppDimensions.getAdaptiveSpacing(context) * 0.5),
                      // Logo
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
                      SizedBox(height: AppDimensions.getAdaptiveSpacing(context) * 0.4),
                      Text(
                        'CRÉER UN COMPTE',
                        style: TextStyle(
                          fontSize: AppDimensions.getFormTitleFontSize(context),
                          fontWeight: FontWeight.w600,
                          color: AppColors.getTextColor(isDark),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Remplissez ce formulaire pour créer votre compte',
                        style: TextStyle(
                          fontSize: AppDimensions.getFormSubtitleFontSize(context),
                          color: AppColors.getTextColor(isDark, type: TextType.secondary),
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: AppDimensions.getFormFieldSpacing(context) * 0.3),
                      // Champ Nom
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
                        child: TextFormField(
                          controller: _nameController,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Veuillez entrer votre nom';
                            }
                            return null;
                          },
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: isTablet ? 18.0 : 16.0,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Nom *',
                            hintText: 'Votre nom',
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
                              vertical: isTablet ? 20.0 : 18.0,
                            ),
                            filled: true,
                            fillColor: Colors.transparent,
                          ),
                        ),
                      ),
                      SizedBox(height: AppDimensions.getFormFieldSpacing(context) * 0.3),
                      // Champ Prénoms
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
                        child: TextFormField(
                          controller: _prenomsController,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Veuillez entrer vos prénoms';
                            }
                            return null;
                          },
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: isTablet ? 18.0 : 16.0,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Prénoms *',
                            hintText: 'Vos prénoms',
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
                              vertical: isTablet ? 20.0 : 18.0,
                            ),
                            filled: true,
                            fillColor: Colors.transparent,
                          ),
                        ),
                      ),
                      SizedBox(height: AppDimensions.getFormFieldSpacing(context) * 0.3),
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
                            labelText: 'Numéro de téléphone *',
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
                      SizedBox(height: AppDimensions.getFormFieldSpacing(context) * 0.3),
                      // Champ Mot de passe
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
                        child: TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Veuillez entrer un mot de passe';
                            }
                            if (value.length < 6) {
                              return 'Le mot de passe doit contenir au moins 6 caractères';
                            }
                            return null;
                          },
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: isTablet ? 18.0 : 16.0,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Mot de passe *',
                            hintText: 'Votre mot de passe',
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
                              vertical: isTablet ? 20.0 : 18.0,
                            ),
                            filled: true,
                            fillColor: Colors.transparent,
                          ),
                        ),
                      ),
                      SizedBox(height: AppDimensions.getFormFieldSpacing(context) * 0.3),
                      // Champ Code d'invitation
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
                        child: TextFormField(
                          controller: _invitationCodeController,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: isTablet ? 18.0 : 16.0,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Code d\'invitation (optionnel)',
                            hintText: 'Entrez votre code d\'invitation',
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
                              vertical: isTablet ? 20.0 : 18.0,
                            ),
                            filled: true,
                            fillColor: Colors.transparent,
                          ),
                        ),
                      ),
                      SizedBox(height: AppDimensions.getFormFieldSpacing(context) * 0.3),
                      // Champ Question de sécurité
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
                        child: DropdownButtonFormField<String>(
                          value: _selectedSecurityQuestion,
                          decoration: InputDecoration(
                            labelText: 'Question de sécurité *',
                            labelStyle: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
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
                              vertical: isTablet ? 20.0 : 18.0,
                            ),
                            filled: true,
                            fillColor: Colors.transparent,
                          ),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: isTablet ? 18.0 : 16.0,
                          ),
                          dropdownColor: isDark ? AppColors.surfaceDark : Theme.of(context).colorScheme.surface,
                          items: _securityQuestions.map((String question) {
                            return DropdownMenuItem<String>(
                              value: question,
                              child: Text(
                                question,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurface,
                                  fontSize: isTablet ? 16.0 : 14.0,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedSecurityQuestion = newValue!;
                            });
                          },
                        ),
                      ),
                      SizedBox(height: AppDimensions.getFormFieldSpacing(context) * 0.3),
                      // Champ Réponse de sécurité
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
                        child: TextFormField(
                          controller: _securityAnswerController,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Veuillez répondre à la question de sécurité';
                            }
                            return null;
                          },
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: isTablet ? 18.0 : 16.0,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Réponse de sécurité *',
                            hintText: 'Votre réponse',
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
                              vertical: isTablet ? 20.0 : 18.0,
                            ),
                            filled: true,
                            fillColor: Colors.transparent,
                          ),
                        ),
                      ),
                      SizedBox(height: AppDimensions.getAdaptiveSpacing(context) * 0.4),
                      // Bouton créer le compte
                      CustomButton(
                        text: 'CRÉER LE COMPTE',
                        onPressed: _handleSignup,
                        isLoading: _isLoading,
                      ),
                      SizedBox(height: AppDimensions.getAdaptiveSpacing(context) * 0.75),
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
