import 'package:flutter/material.dart';

import '../config/app_colors.dart';
import 'custom_text_field.dart';

typedef RecommendationSubmit = Future<void> Function(BuildContext context);

class RecommendationBottomSheet extends StatelessWidget {
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
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
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
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.screenDivider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.recommend_rounded,
                    size: 24,
                    color: accentColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color:
                              isDark ? Colors.white : const Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? Colors.grey[400]
                              : const Color(0xFF666666),
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF2A2A2A)
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      size: 20,
                      color: isDark ? Colors.white54 : const Color(0xFF666666),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  CustomTextField(
                    label: 'Votre nom',
                    hint: 'Entrez votre nom complet',
                    icon: Icons.person_rounded,
                    controller: recommenderNameController,
                    iconColor: accentColor,
                    focusBorderColor: accentColor,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: "Nom de l'établissement",
                    hint: "Entrez le nom de l'école",
                    icon: Icons.business_rounded,
                    controller: etablissementController,
                    iconColor: accentColor,
                    focusBorderColor: accentColor,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: 'Pays',
                    hint: 'Entrez le pays',
                    icon: Icons.public_rounded,
                    controller: paysRecommendController,
                    iconColor: accentColor,
                    focusBorderColor: accentColor,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: 'Ville',
                    hint: 'Entrez la ville',
                    icon: Icons.location_city_rounded,
                    controller: villeRecommendController,
                    iconColor: accentColor,
                    focusBorderColor: accentColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Informations du parent',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: 'Nom du parent',
                    hint: 'Entrez votre nom',
                    icon: Icons.person_rounded,
                    controller: parentNomController,
                    iconColor: accentColor,
                    focusBorderColor: accentColor,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: 'Prénom du parent',
                    hint: 'Entrez votre prénom',
                    icon: Icons.person_outline_rounded,
                    controller: parentPrenomController,
                    iconColor: accentColor,
                    focusBorderColor: accentColor,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: 'Téléphone',
                    hint: 'Entrez votre numéro de téléphone',
                    icon: Icons.phone_rounded,
                    controller: parentTelephoneController,
                    iconColor: accentColor,
                    focusBorderColor: accentColor,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: 'Email',
                    hint: 'Entrez votre email',
                    icon: Icons.email_rounded,
                    controller: parentEmailController,
                    iconColor: accentColor,
                    focusBorderColor: accentColor,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: "Adresse de l'établissement",
                    hint: "Entrez l'adresse (optionnel)",
                    icon: Icons.location_on_rounded,
                    controller: adresseEtablissementController,
                    iconColor: accentColor,
                    focusBorderColor: accentColor,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (etablissementController.text.isEmpty ||
                            paysRecommendController.text.isEmpty ||
                            villeRecommendController.text.isEmpty ||
                            parentNomController.text.isEmpty ||
                            parentPrenomController.text.isEmpty ||
                            parentTelephoneController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Veuillez remplir tous les champs obligatoires',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        await onSubmit(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Envoyer la recommandation',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
