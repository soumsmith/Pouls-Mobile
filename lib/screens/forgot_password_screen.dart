import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/custom_sliver_app_bar.dart';
import '../services/auth_service.dart';
import '../config/app_colors.dart';
import '../config/app_dimensions.dart';
import '../widgets/custom_button.dart';

enum ForgotPasswordStep { phone, securityQuestion, resetPassword }

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  ForgotPasswordStep _currentStep = ForgotPasswordStep.phone;
  final _formKey = GlobalKey<FormState>();
  
  final _phoneController = TextEditingController();
  String _completePhoneNumber = '';
  
  String _securityQuestion = '';
  final _answerController = TextEditingController();
  
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _answerController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _handlePhoneSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    String phoneNumber = _completePhoneNumber.isNotEmpty 
        ? _phoneController.text.trim() 
        : _phoneController.text.trim();

    final question = await AuthService.instance.getSecurityQuestion(phoneNumber);

    setState(() => _isLoading = false);

    if (question != null && question.isNotEmpty) {
      setState(() {
        _securityQuestion = question;
        _currentStep = ForgotPasswordStep.securityQuestion;
      });
    } else {
      _showError('Aucun compte trouvé avec ce numéro ou aucune question secrète configurée.');
    }
  }

  Future<void> _handleAnswerSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    
    String phoneNumber = _completePhoneNumber.isNotEmpty 
        ? _phoneController.text.trim() 
        : _phoneController.text.trim();
        
    final isCorrect = await AuthService.instance.verifySecurityAnswer(
      phoneNumber, 
      _answerController.text.trim()
    );

    setState(() => _isLoading = false);

    if (isCorrect) {
      setState(() {
        _currentStep = ForgotPasswordStep.resetPassword;
      });
    } else {
      _showError('Réponse incorrecte. Veuillez réessayer.');
    }
  }

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      _showError('Les mots de passe ne correspondent pas.');
      return;
    }

    setState(() => _isLoading = true);
    
    String phoneNumber = _completePhoneNumber.isNotEmpty 
        ? _phoneController.text.trim() 
        : _phoneController.text.trim();

    final success = await AuthService.instance.resetPassword(
      phoneNumber,
      _passwordController.text,
      _confirmPasswordController.text,
    );

    setState(() => _isLoading = false);

    if (success) {
      _showSuccess('Mot de passe réinitialisé avec succès !');
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        Navigator.of(context).pop(); // Retour à l'écran de connexion
      }
    } else {
      _showError('Erreur lors de la réinitialisation du mot de passe.');
    }
  }

  Widget _buildContactSection(bool isDark, bool isTablet) {
    return Column(
      children: [
        SizedBox(height: AppDimensions.getAdaptiveSpacing(context)),
        Text(
          "Besoin d'aide ?",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.getTextColor(isDark, type: TextType.secondary),
            fontSize: isTablet ? 16.0 : 14.0,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.green),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              icon: const Icon(Icons.phone, color: Colors.green),
              onPressed: () async {
                final Uri url = Uri.parse('tel:+2250555082174');
                if (await canLaunchUrl(url)) {
                  await launchUrl(url);
                }
              },
              label: Text(
                "Appeler",
                style: TextStyle(
                  color: Colors.green,
                  fontSize: isTablet ? 16.0 : 14.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 16),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.green),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              icon: const Icon(Icons.email, color: Colors.green),
              onPressed: () => _showEmailBottomSheet(context, isDark, isTablet),
              label: Text(
                "Envoyer un mail",
                style: TextStyle(
                  color: Colors.green,
                  fontSize: isTablet ? 16.0 : 14.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPhoneStep(bool isDark, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Entrez votre numéro de téléphone pour récupérer votre compte.',
          style: TextStyle(
            color: AppColors.getTextColor(isDark, type: TextType.secondary),
            fontSize: isTablet ? 16.0 : 14.0,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: AppDimensions.getAdaptiveSpacing(context)),
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
            initialCountryCode: 'CI',
            onChanged: (phone) {
              _completePhoneNumber = phone.completeNumber;
            },
            validator: (value) {
              if (value == null || value.number.isEmpty) {
                return 'Veuillez entrer votre numéro';
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
            dropdownIcon: Icon(
              Icons.arrow_drop_down,
              color: Theme.of(context).colorScheme.onSurface,
              size: isTablet ? 28.0 : 24.0,
            ),
            decoration: InputDecoration(
              labelText: 'Numéro de téléphone',
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
                vertical: isTablet ? 16.0 : 12.0,
              ),
              filled: true,
              fillColor: Colors.transparent,
            ),
          ),
        ),
        SizedBox(height: AppDimensions.getAdaptiveSpacing(context)),
        CustomButton(
          text: 'Continuer',
          backgroundColor: Colors.green,
          onPressed: _handlePhoneSubmit,
          isLoading: _isLoading,
        ),
        _buildContactSection(isDark, isTablet),
      ],
    );
  }

  Widget _buildSecurityQuestionStep(bool isDark, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: EdgeInsets.all(isTablet ? 20.0 : 16.0),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(isTablet ? 16.0 : 12.0),
          ),
          child: Column(
            children: [
              Icon(Icons.security, color: AppColors.primary, size: 32),
              const SizedBox(height: 12),
              Text(
                'Question de sécurité',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.getTextColor(isDark),
                  fontSize: isTablet ? 18.0 : 16.0,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _securityQuestion,
                style: TextStyle(
                  color: AppColors.getTextColor(isDark, type: TextType.secondary),
                  fontSize: isTablet ? 16.0 : 14.0,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        SizedBox(height: AppDimensions.getAdaptiveSpacing(context)),
        TextFormField(
          controller: _answerController,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Veuillez entrer votre réponse';
            }
            return null;
          },
          decoration: InputDecoration(
            labelText: 'Votre réponse',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(isTablet ? 20.0 : 16.0),
            ),
          ),
        ),
        SizedBox(height: AppDimensions.getAdaptiveSpacing(context)),
        CustomButton(
          text: 'Vérifier',
          backgroundColor: Colors.green,
          onPressed: _handleAnswerSubmit,
          isLoading: _isLoading,
        ),
        _buildContactSection(isDark, isTablet),
      ],
    );
  }

  Widget _buildResetPasswordStep(bool isDark, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Veuillez entrer un mot de passe';
            }
            if (value.length < 6) {
              return 'Le mot de passe doit contenir au moins 6 caractères';
            }
            return null;
          },
          decoration: InputDecoration(
            labelText: 'Nouveau mot de passe',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(isTablet ? 20.0 : 16.0),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Le mot de passe doit contenir au moins 6 caractères',
            style: TextStyle(
              color: AppColors.getTextColor(isDark, type: TextType.secondary),
              fontSize: isTablet ? 14.0 : 12.0,
            ),
          ),
        ),
        SizedBox(height: AppDimensions.getAdaptiveSpacing(context)),
        TextFormField(
          controller: _confirmPasswordController,
          obscureText: _obscureConfirmPassword,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Veuillez confirmer le mot de passe';
            }
            if (value != _passwordController.text) {
              return 'Les mots de passe ne correspondent pas';
            }
            return null;
          },
          decoration: InputDecoration(
            labelText: 'Confirmer le mot de passe',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(isTablet ? 20.0 : 16.0),
            ),
          ),
        ),
        SizedBox(height: AppDimensions.getAdaptiveSpacing(context)),
        CustomButton(
          text: 'Réinitialiser le mot de passe',
          backgroundColor: Colors.green,
          onPressed: _handleResetPassword,
          isLoading: _isLoading,
        ),
      ],
    );
  }


    void _showEmailBottomSheet(BuildContext context, bool isDark, bool isTablet) {
    final emailController = TextEditingController();
    final subjectController = TextEditingController();
    final bodyController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24.0,
            right: 24.0,
            top: 24.0,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Envoyer un mail',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.getTextColor(isDark),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Votre adresse e-mail',
                  labelStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: subjectController,
                decoration: InputDecoration(
                  labelText: 'Sujet',
                  labelStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: bodyController,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: 'Message',
                  labelStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 20),
              CustomButton(
                text: 'Envoyer',
                backgroundColor: Colors.green,
                onPressed: () async {
                  final String subject = Uri.encodeComponent(subjectController.text);
                  final String userEmail = emailController.text.trim();
                  final String rawBody = userEmail.isNotEmpty 
                      ? "De : $userEmail\n\n${bodyController.text}" 
                      : bodyController.text;
                  final String body = Uri.encodeComponent(rawBody);
                  final Uri url = Uri.parse('mailto:contacts@groupegain.com?subject=$subject&body=$body');
                  
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url);
                    if (context.mounted) Navigator.pop(context);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Impossible d\'ouvrir le client de messagerie.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isTablet = AppDimensions.isTablet(context) || AppDimensions.isLargeTablet(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
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
        child: CustomScrollView(
          slivers: [
            CustomSliverAppBar(
              title: 'Mot de passe oublié',
              automaticallyImplyLeading: true,
              onBackTap: () {
                Navigator.of(context).pop();
              },
              pinned: true,
              floating: false,
              expandedHeight: 0,
            ),
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
                          SizedBox(height: AppDimensions.getAdaptiveSpacing(context) * 1.5),
                          if (_currentStep == ForgotPasswordStep.phone)
                            _buildPhoneStep(isDark, isTablet)
                          else if (_currentStep == ForgotPasswordStep.securityQuestion)
                            _buildSecurityQuestionStep(isDark, isTablet)
                          else if (_currentStep == ForgotPasswordStep.resetPassword)
                            _buildResetPasswordStep(isDark, isTablet),
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
