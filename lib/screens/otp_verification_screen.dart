import 'dart:async';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../config/app_colors.dart';
import '../config/app_dimensions.dart';
import '../widgets/custom_button.dart';
import '../widgets/main_screen_wrapper.dart';
import '../widgets/back_button_widget.dart';
import '../screens/home_screen.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String phone;
  final bool isLogin;

  const OtpVerificationScreen({
    super.key,
    required this.phone,
    required this.isLogin,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(
    6,
    (index) => FocusNode(),
  );
  bool _isLoading = false;
  bool _canResend = false;
  int _resendCountdown = 60;
  Timer? _resendTimer;

  @override
  void initState() {
    super.initState();
    _startResendCountdown();
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _startResendCountdown() {
    _resendTimer?.cancel();
    
    setState(() {
      _canResend = false;
      _resendCountdown = 60;
    });

    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && _resendCountdown > 0) {
        setState(() {
          _resendCountdown--;
        });
      } else {
        timer.cancel();
        if (mounted) {
          setState(() {
            _canResend = true;
          });
        }
      }
    });
  }

  void _onOtpChanged(String value, int index) {
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index].unfocus();
      FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index].unfocus();
      FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
    }

    // Vérifier si tous les champs sont remplis
    if (_otpControllers.every((controller) => controller.text.isNotEmpty)) {
      _verifyOtp();
    }
  }

  Future<void> _verifyOtp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final otp = _otpControllers.map((controller) => controller.text).join('');
    
    print('🔍 Vérification OTP pour ${widget.phone} avec code: $otp');
    
    try {
      bool success = false;
      
      if (widget.isLogin) {
        // Utiliser AuthService pour la connexion
        success = await AuthService.instance.verifyOtpAndLogin(widget.phone, otp);
      } else {
        // Utiliser AuthService pour l'inscription
        // Pour l'instant, nous utilisons les mêmes infos par défaut
        success = await AuthService.instance.verifyOtpAndCreateAccount(
          phone: widget.phone,
          otp: otp,
          firstName: 'Parent',
          lastName: 'Utilisateur',
          email: '${widget.phone}@parent.local',
        );
      }
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (success) {
          print('✅ OTP vérifié avec succès');
          _navigateToApp();
        } else {
          print('❌ Échec de la vérification OTP');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Code OTP invalide. Veuillez réessayer.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Erreur lors de la vérification OTP: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _navigateToApp() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainScreenWrapper(child: HomeScreen())),
      (route) => false,
    );
  }

  Future<void> _resendOtp() async {
    if (!_canResend) return;

    setState(() {
      _isLoading = true;
    });

    // Simuler le renvoi d'OTP
    await Future.delayed(const Duration(seconds: 1));
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Code OTP renvoyé avec succès.'),
          backgroundColor: Colors.green,
        ),
      );

      _startResendCountdown();
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
                    AppColors.primary.withOpacity(0.05),
                    AppColors.primary.withOpacity(0.1),
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
                      SizedBox(height: AppDimensions.getAdaptiveSpacing(context) * 0.8),
                      // Logo
                      Center(
                        child: Container(
                          padding: EdgeInsets.all(isTablet ? 24.0 : 16.0),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(isTablet ? 28.0 : 20.0),
                          ),
                          child: Icon(
                            Icons.verified_user,
                            size: AppDimensions.getAdaptiveIconSize(context),
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      SizedBox(height: AppDimensions.getAdaptiveSpacing(context)),
                      Text(
                        'VÉRIFICATION',
                        style: TextStyle(
                          fontSize: AppDimensions.getFormTitleFontSize(context),
                          fontWeight: FontWeight.w600,
                          color: AppColors.getTextColor(isDark),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Entrez le code à 6 chiffres\nenvoyé au ${widget.phone}',
                        style: TextStyle(
                          fontSize: AppDimensions.getFormSubtitleFontSize(context),
                          color: AppColors.getTextColor(isDark, type: TextType.secondary),
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: AppDimensions.getFormFieldSpacing(context)),
                      // Champs OTP
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(
                          6,
                          (index) => SizedBox(
                            width: isTablet ? 60.0 : 50.0,
                            height: isTablet ? 60.0 : 50.0,
                            child: TextFormField(
                              controller: _otpControllers[index],
                              focusNode: _focusNodes[index],
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              maxLength: 1,
                              style: TextStyle(
                                fontSize: isTablet ? 24.0 : 20.0,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                              decoration: InputDecoration(
                                counterText: '',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(isTablet ? 16.0 : 12.0),
                                  borderSide: BorderSide(
                                    color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(isTablet ? 16.0 : 12.0),
                                  borderSide: BorderSide(
                                    color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(isTablet ? 16.0 : 12.0),
                                  borderSide: BorderSide(
                                    color: AppColors.primary,
                                    width: 2.0,
                                  ),
                                ),
                                filled: true,
                                fillColor: isDark 
                                    ? AppColors.surfaceDark 
                                    : Theme.of(context).colorScheme.surface,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: isTablet ? 16.0 : 12.0,
                                  vertical: isTablet ? 16.0 : 12.0,
                                ),
                              ),
                              onChanged: (value) {
                                if (value.length <= 1) {
                                  _onOtpChanged(value, index);
                                }
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return '';
                                }
                                return null;
                              },
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: AppDimensions.getFormFieldSpacing(context)),
                      // Bouton vérifier
                      CustomButton(
                        text: 'Vérifier le code',
                        onPressed: _verifyOtp,
                        isLoading: _isLoading,
                      ),
                      SizedBox(height: AppDimensions.getAdaptiveSpacing(context) * 0.75),
                      // Renvoyer le code
                      Center(
                        child: Column(
                          children: [
                            if (!_canResend)
                              Text(
                                'Renvoyer dans $_resendCountdown secondes',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                              )
                            else
                              TextButton(
                                onPressed: _resendOtp,
                                child: Text(
                                  'Renvoyer le code',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontSize: isTablet ? 16.0 : 14.0,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      SizedBox(height: AppDimensions.getAdaptiveSpacing(context) * 0.5),
                      // Info box - Mode développement
                      Container(
                        padding: EdgeInsets.all(isTablet ? 16.0 : 12.0),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(isTablet ? 12.0 : 8.0),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.info_outline, color: Colors.orange[700]),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Mode développement - SMS non envoyé',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: Colors.orange[900],
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Code OTP de test à utiliser : 123456',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.orange[800],
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'En production, le code sera envoyé par SMS à votre numéro.',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.orange[700],
                                    fontStyle: FontStyle.italic,
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
