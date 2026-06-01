import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import '../services/auth_service.dart';
import '../services/text_size_service.dart';
import 'bottom_sheets/bottom_sheet_header.dart';
import 'custom_text_field.dart';
import 'components/custom_button.dart';

typedef RecommendationSubmit = Future<void> Function(BuildContext context);

class RecommendationBottomSheet extends StatefulWidget {
  final Color accentColor;

  final TextEditingController recommenderNameController;
  final TextEditingController etablissementController;
  final TextEditingController paysRecommendController;
  final TextEditingController villeRecommendController;

  final TextEditingController parentNomController;
  final TextEditingController parentPrenomController;
  final TextEditingController parentTelephoneController;
  final TextEditingController parentEmailController;

  final TextEditingController ordreController;
  final TextEditingController adresseEtablissementController;

  final TextEditingController paysParentController;
  final TextEditingController villeParentController;
  final TextEditingController adresseParentController;

  final RecommendationSubmit onSubmit;

  final String title;
  final String subtitle;
  final IconData? icon;
  final String? imagePath;
  final Color? imageBackgroundColor;
  final double? imageBorderRadius;

  const RecommendationBottomSheet({
    super.key,
    required this.accentColor,
    required this.recommenderNameController,
    required this.etablissementController,
    required this.paysRecommendController,
    required this.villeRecommendController,
    required this.parentNomController,
    required this.parentPrenomController,
    required this.parentTelephoneController,
    required this.parentEmailController,
    required this.ordreController,
    required this.adresseEtablissementController,
    required this.paysParentController,
    required this.villeParentController,
    required this.adresseParentController,
    required this.onSubmit,
    this.title = 'Recommander un établissement',
    this.subtitle = 'Suggérez une école à la communauté',
    this.icon,
    this.imagePath,
    this.imageBackgroundColor,
    this.imageBorderRadius,
  });

  @override
  State<RecommendationBottomSheet> createState() => _RecommendationBottomSheetState();
}

class _RecommendationBottomSheetState extends State<RecommendationBottomSheet> {
  int _currentStep = 0;
  final int _totalSteps = 3;

  final List<String> _stepTitles = [
    'Établissement',
    'Parent',
    'Résumé',
  ];

  final List<IconData> _stepIcons = [
    Icons.business_rounded,
    Icons.person_rounded,
    Icons.summarize_rounded,
  ];

  @override
  void initState() {
    super.initState();
    
    // Pre-fill with logged-in user details if available and currently empty
    final currentUser = AuthService().getCurrentUser();
    if (currentUser != null) {
      if (widget.recommenderNameController.text.isEmpty) {
        widget.recommenderNameController.text = currentUser.fullName;
      }
      if (widget.parentNomController.text.isEmpty) {
        widget.parentNomController.text = currentUser.lastName;
      }
      if (widget.parentPrenomController.text.isEmpty) {
        widget.parentPrenomController.text = currentUser.firstName;
      }
      if (widget.parentTelephoneController.text.isEmpty) {
        widget.parentTelephoneController.text = currentUser.phone;
      }
      if (widget.parentEmailController.text.isEmpty && currentUser.email != null) {
        if (!currentUser.email!.contains('@parent.local')) {
          widget.parentEmailController.text = currentUser.email!;
        }
      }
    }

    widget.recommenderNameController.addListener(_onTextChanged);
    widget.etablissementController.addListener(_onTextChanged);
    widget.paysRecommendController.addListener(_onTextChanged);
    widget.villeRecommendController.addListener(_onTextChanged);
    widget.parentNomController.addListener(_onTextChanged);
    widget.parentPrenomController.addListener(_onTextChanged);
    widget.parentTelephoneController.addListener(_onTextChanged);
    widget.parentEmailController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.recommenderNameController.removeListener(_onTextChanged);
    widget.etablissementController.removeListener(_onTextChanged);
    widget.paysRecommendController.removeListener(_onTextChanged);
    widget.villeRecommendController.removeListener(_onTextChanged);
    widget.parentNomController.removeListener(_onTextChanged);
    widget.parentPrenomController.removeListener(_onTextChanged);
    widget.parentTelephoneController.removeListener(_onTextChanged);
    widget.parentEmailController.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    // Ne plus faire de setState global ici pour éviter que le clavier ne saute/scintille
    // lors du passage d'un champ à l'autre. Les boutons sont maintenant gérés par AnimatedBuilder.
  }

  bool _canNavigateToNext() {
    switch (_currentStep) {
      case 0:
        return widget.recommenderNameController.text.isNotEmpty &&
            widget.etablissementController.text.isNotEmpty &&
            widget.paysRecommendController.text.isNotEmpty &&
            widget.villeRecommendController.text.isNotEmpty;
      case 1:
        return widget.parentNomController.text.isNotEmpty &&
            widget.parentPrenomController.text.isNotEmpty &&
            widget.parentTelephoneController.text.isNotEmpty;
      case 2:
        return true;
      default:
        return true;
    }
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      if (_canNavigateToNext()) {
        setState(() => _currentStep++);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez remplir tous les champs requis'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      _submitForm();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  Future<void> _submitForm() async {
    if (widget.etablissementController.text.isEmpty ||
        widget.paysRecommendController.text.isEmpty ||
        widget.villeRecommendController.text.isEmpty ||
        widget.parentNomController.text.isEmpty ||
        widget.parentPrenomController.text.isEmpty ||
        widget.parentTelephoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez remplir tous les champs obligatoires'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    await widget.onSubmit(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
        height: screenHeight * 0.95,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1A) : AppColors.screenSurface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          BottomSheetHeader(
            icon: widget.icon ?? Icons.thumb_up_alt_rounded,
            imagePath: widget.imagePath,
            imageBackgroundColor: widget.imageBackgroundColor,
            imageBorderRadius: widget.imageBorderRadius,
            iconColor: widget.accentColor,
            title: widget.title,
            description: widget.subtitle,
            onClose: () => Navigator.of(context).pop(),
            titleColor: isDark ? Colors.white : AppColors.screenTextPrimary,
            descriptionColor: AppColors.screenTextSecondary,
            titleFontSize: TextSizeService().getScaledFontSize(18),
            iconSize: 22,
          ),

          // Progress Steps Indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: _buildProgressIndicator(),
          ),

          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  _buildCurrentStepContent(isDark),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Bottom Navigation Buttons
          Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              12,
              20,
              MediaQuery.of(context).padding.bottom + 16 + keyboardHeight,
            ),
            child: _buildNavigationButtons(),
          ),
        ],
      ),
    );
}

  Widget _buildProgressIndicator() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF222222) : AppColors.screenCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (_currentStep + 1) / _totalSteps,
              backgroundColor: isDark ? const Color(0xFF333333) : AppColors.screenDivider,
              valueColor: AlwaysStoppedAnimation(widget.accentColor),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(_totalSteps, (index) {
              final isCompleted = index < _currentStep;
              final isCurrent = index == _currentStep;
              final isClickable = index < _currentStep;

              return GestureDetector(
                onTap: isClickable
                    ? () => setState(() => _currentStep = index)
                    : null,
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: isCurrent ? 26 : 22,
                      height: isCurrent ? 26 : 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCompleted
                            ? Colors.green
                            : isCurrent
                            ? widget.accentColor
                            : isDark ? const Color(0xFF333333) : AppColors.screenDivider,
                      ),
                      child: Icon(
                        isCompleted ? Icons.check_rounded : _stepIcons[index],
                        color: (isCompleted || isCurrent)
                            ? Colors.white
                            : AppColors.screenTextSecondary,
                        size: isCurrent ? 13 : 11,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _stepTitles[index],
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: isCurrent
                            ? FontWeight.w700
                            : isCompleted
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: isCurrent
                            ? widget.accentColor
                            : isCompleted
                            ? Colors.green
                            : AppColors.screenTextSecondary,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStepContent(bool isDark) {
    switch (_currentStep) {
      case 0:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informations sur l\'établissement',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Votre nom',
              hint: 'Entrez votre nom complet',
              icon: Icons.person_rounded,
              controller: widget.recommenderNameController,
              iconColor: widget.accentColor,
              focusBorderColor: widget.accentColor,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: "Nom de l'établissement",
              hint: "Entrez le nom de l'école",
              icon: Icons.business_rounded,
              controller: widget.etablissementController,
              iconColor: widget.accentColor,
              focusBorderColor: widget.accentColor,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Pays',
              hint: 'Entrez le pays',
              icon: Icons.public_rounded,
              controller: widget.paysRecommendController,
              iconColor: widget.accentColor,
              focusBorderColor: widget.accentColor,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Ville',
              hint: 'Entrez la ville',
              icon: Icons.location_city_rounded,
              controller: widget.villeRecommendController,
              iconColor: widget.accentColor,
              focusBorderColor: widget.accentColor,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: "Adresse de l'établissement",
              hint: "Entrez l'adresse (optionnel)",
              icon: Icons.location_on_rounded,
              controller: widget.adresseEtablissementController,
              iconColor: widget.accentColor,
              focusBorderColor: widget.accentColor,
            ),
          ],
        );
      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informations du parent',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Nom du parent',
              hint: 'Entrez votre nom',
              icon: Icons.person_rounded,
              controller: widget.parentNomController,
              iconColor: widget.accentColor,
              focusBorderColor: widget.accentColor,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Prénom du parent',
              hint: 'Entrez votre prénom',
              icon: Icons.person_outline_rounded,
              controller: widget.parentPrenomController,
              iconColor: widget.accentColor,
              focusBorderColor: widget.accentColor,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Téléphone',
              hint: 'Entrez votre numéro de téléphone',
              icon: Icons.phone_rounded,
              controller: widget.parentTelephoneController,
              iconColor: widget.accentColor,
              focusBorderColor: widget.accentColor,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Email',
              hint: 'Entrez votre email',
              icon: Icons.email_rounded,
              controller: widget.parentEmailController,
              iconColor: widget.accentColor,
              focusBorderColor: widget.accentColor,
            ),
          ],
        );
      case 2:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Récapitulatif de votre recommandation',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 16),
            
            // Section Etablissement Card
            _buildRecapCard(
              title: 'Établissement',
              icon: Icons.business_rounded,
              isDark: isDark,
              details: [
                _buildRecapRow('Votre nom', widget.recommenderNameController.text),
                _buildRecapRow("Nom de l'école", widget.etablissementController.text),
                _buildRecapRow('Pays', widget.paysRecommendController.text),
                _buildRecapRow('Ville', widget.villeRecommendController.text),
                _buildRecapRow(
                  'Adresse',
                  widget.adresseEtablissementController.text.isNotEmpty
                      ? widget.adresseEtablissementController.text
                      : 'Non précisée',
                  isItalic: widget.adresseEtablissementController.text.isEmpty,
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Section Parent Card
            _buildRecapCard(
              title: 'Parent',
              icon: Icons.person_rounded,
              isDark: isDark,
              details: [
                _buildRecapRow('Nom complet', '${widget.parentPrenomController.text} ${widget.parentNomController.text}'),
                _buildRecapRow('Téléphone', widget.parentTelephoneController.text),
                _buildRecapRow(
                  'Email',
                  widget.parentEmailController.text.isNotEmpty
                      ? widget.parentEmailController.text
                      : 'Non précisé',
                  isItalic: widget.parentEmailController.text.isEmpty,
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Confirmation alert box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: widget.accentColor.withOpacity(0.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: widget.accentColor.withOpacity(0.15),
                  width: 1.0,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    color: widget.accentColor,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tout est correct ?',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Veuillez vérifier les informations ci-dessus avant de valider la recommandation.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.screenTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildRecapCard({
    required String title,
    required IconData icon,
    required bool isDark,
    required List<Widget> details,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF222222) : AppColors.screenCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF333333) : AppColors.screenDivider,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: widget.accentColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(height: 1, thickness: 1, color: isDark ? const Color(0xFF333333) : AppColors.screenDivider),
          const SizedBox(height: 12),
          ...details,
        ],
      ),
    );
  }

  Widget _buildRecapRow(String label, String value, {bool isItalic = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.screenTextSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : const Color(0xFF1A1A1A),
                fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLast = _currentStep == _totalSteps - 1;

    return AnimatedBuilder(
      animation: Listenable.merge([
        widget.recommenderNameController,
        widget.etablissementController,
        widget.paysRecommendController,
        widget.villeRecommendController,
        widget.parentNomController,
        widget.parentPrenomController,
        widget.parentTelephoneController,
        widget.parentEmailController,
      ]),
      builder: (context, _) {
        final canNext = _canNavigateToNext();
        return Row(
          children: [
            if (_currentStep > 0)
              CustomButton(
                text: 'Précédent',
                onPressed: _previousStep,
                color: isDark ? Colors.white60 : Colors.grey[700]!,
                isLight: true,
                icon: Icons.arrow_back_ios_new,
                width: 120,
                height: 40,
                fontSize: 12,
              ),
            const Spacer(),
            CustomButton(
              text: isLast ? 'Envoyer la recommandation' : 'Suivant',
              onPressed: canNext ? _nextStep : null,
              color: widget.accentColor,
              icon: isLast ? null : Icons.arrow_forward_rounded,
              iconOnRight: true,
              width: isLast ? 200 : 120,
              height: 40,
              fontSize: 12,
            ),
          ],
        );
      },
    );
  }
}
