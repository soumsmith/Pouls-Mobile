import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/custom_sliver_app_bar.dart';
import '../services/auth_service.dart';
import '../config/app_colors.dart';
import '../config/app_dimensions.dart';
import '../widgets/custom_button.dart';
import '../widgets/components/custom_text_input.dart';

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
            ElevatedButton.icon(
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
              icon: Icon(
                Icons.phone,
                color: isDark ? Colors.white : Colors.black,
                size: isTablet ? 22.0 : 18.0,
              ),
              onPressed: () async {
                final Uri url = Uri.parse('tel:+2250555082174');
                if (await canLaunchUrl(url)) {
                  await launchUrl(url);
                }
              },
              label: Text(
                "Appeler",
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontSize: isTablet ? 16.0 : 14.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton.icon(
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
              icon: Icon(
                Icons.email,
                color: isDark ? Colors.white : Colors.black,
                size: isTablet ? 22.0 : 18.0,
              ),
              onPressed: () => _showEmailBottomSheet(context, isDark, isTablet),
              label: Text(
                "Envoyer un mail",
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
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
                color: isDark ? AppColors.surfaceDark : Colors.white,
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
                    return 'Veuillez entrer votre numéro';
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
                    borderSide: BorderSide(
                      color: AppColors.primary,
                      width: AppDimensions.inputFocusedBorderWidth,
                    ),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
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
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : const Color(0xFFF2F4F7),
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
        CustomTextInput(
          label: 'Votre réponse',
          hint: 'Entrez votre réponse',
          icon: Icons.security_outlined,
          controller: _answerController,
          required: true,
          focusBorderColor: AppColors.primary,
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
        CustomTextInput(
          label: 'Nouveau mot de passe',
          hint: 'Votre nouveau mot de passe',
          icon: Icons.lock_outline,
          controller: _passwordController,
          required: true,
          obscureText: _obscurePassword,
          focusBorderColor: AppColors.primary,
          suffixIcon: IconButton(
            icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
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
        CustomTextInput(
          label: 'Confirmer le mot de passe',
          hint: 'Confirmez le mot de passe',
          icon: Icons.lock_outline,
          controller: _confirmPasswordController,
          required: true,
          obscureText: _obscureConfirmPassword,
          focusBorderColor: AppColors.primary,
          suffixIcon: IconButton(
            icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility),
            onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
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
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: isDark ? const Color(0xFF444444) : const Color(0xFFCFD4DC),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: isDark ? const Color(0xFF444444) : const Color(0xFFCFD4DC),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: Colors.green,
                      width: 1.5,
                    ),
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
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: isDark ? const Color(0xFF444444) : const Color(0xFFCFD4DC),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: isDark ? const Color(0xFF444444) : const Color(0xFFCFD4DC),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: Colors.green,
                      width: 1.5,
                    ),
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
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: isDark ? const Color(0xFF444444) : const Color(0xFFCFD4DC),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: isDark ? const Color(0xFF444444) : const Color(0xFFCFD4DC),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: Colors.green,
                      width: 1.5,
                    ),
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
      backgroundColor: isDark ? AppColors.backgroundDark : Colors.white,
      body: Container(
        decoration: BoxDecoration(
          color: isDark ? null : Colors.white,
          gradient: isDark
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.backgroundDark,
                    AppColors.surfaceDark,
                  ],
                )
              : null,
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
