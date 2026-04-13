import 'package:flutter/material.dart';
import 'package:parents_responsable/config/app_colors.dart';
import '../searchable_dropdown.dart';
import '../../services/text_size_service.dart';
import '../../config/app_colors.dart';

class CustomSelectInput extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final Function(String) onChanged;
  final bool isDarkMode;
  final bool required;

  const CustomSelectInput({
    Key? key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.isDarkMode,
    this.required = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.screenTextSecondary,
              ),
            ),
            if (required) 
              const Text(
                ' *', 
                style: TextStyle(
                  color: AppColors.screenOrange, 
                  fontSize: 12, 
                  fontWeight: FontWeight.bold
                )
              ),
          ],
        ),
        const SizedBox(height: 6),
        SearchableDropdown(
          label: label,
          value: value,
          items: items,
          onChanged: onChanged,
          isDarkMode: isDarkMode,
        ),
      ],
    );
  }
}
