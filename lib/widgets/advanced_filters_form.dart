import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import 'searchable_dropdown.dart';
import 'components/custom_date_input.dart';
import 'components/custom_button.dart';

class AdvancedFiltersForm extends StatelessWidget {
  final bool isVisible;
  final TextEditingController countryController;
  final List<String> countriesList;
  final Map<String, String> paysMap;
  final Map<String, String> paysReverseMap;
  final TextEditingController categoryController;
  final List<String> categoriesList;
  final TextEditingController dateController;
  final VoidCallback onApply;
  final ValueChanged<String> onCountryChanged;
  final ValueChanged<String> onCategoryChanged;

  const AdvancedFiltersForm({
    super.key,
    required this.isVisible,
    required this.countryController,
    required this.countriesList,
    required this.paysMap,
    required this.paysReverseMap,
    required this.categoryController,
    required this.categoriesList,
    required this.dateController,
    required this.onApply,
    required this.onCountryChanged,
    required this.onCategoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: isVisible ? 165 : 0,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: isVisible
          ? SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: SearchableDropdown(
                          label: 'Pays',
                          value: paysReverseMap[countryController.text] ?? 'Tous',
                          items: countriesList,
                          isDarkMode: Theme.of(context).brightness == Brightness.dark,
                          onChanged: onCountryChanged,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SearchableDropdown(
                          label: 'Catégorie',
                          value: categoryController.text.isEmpty
                              ? 'Toutes'
                              : categoryController.text,
                          items: categoriesList,
                          isDarkMode: Theme.of(context).brightness == Brightness.dark,
                          onChanged: onCategoryChanged,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: CustomDateInput(
                          label: 'Date',
                          hint: 'JJ/MM/AAAA',
                          icon: Icons.calendar_today_rounded,
                          controller: dateController,
                          iconColor: AppColors.screenOrange,
                          focusBorderColor: AppColors.screenOrange,
                          inputFormatters: [DateInputFormatter()],
                        ),
                      ),
                      const SizedBox(width: 8),
                      CustomButton(
                        text: 'Appliquer',
                        color: AppColors.screenOrange,
                        borderRadius: 8,
                        width: 110,
                        height: 48,
                        fontSize: 13,
                        onPressed: onApply,
                      ),
                    ],
                  ),
                ],
              ),
            )
          : null,
    );
  }
}
