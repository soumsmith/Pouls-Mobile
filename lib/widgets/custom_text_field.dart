import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/app_colors.dart';

class CustomTextField extends StatelessWidget {
  final String label;
  final String hint;
  final IconData icon;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final bool required;
  final int maxLines;
  final bool hasError;
  final List<TextInputFormatter>? inputFormatters;
  final Color? iconColor;
  final Color? focusBorderColor;
  final bool readOnly;

  const CustomTextField({
    Key? key,
    required this.label,
    required this.hint,
    required this.icon,
    required this.controller,
    this.keyboardType,
    this.required = false,
    this.maxLines = 1,
    this.hasError = false,
    this.inputFormatters,
    this.iconColor,
    this.focusBorderColor,
    this.readOnly = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final labelColor = isDark ? Colors.white70 : AppColors.screenTextSecondary;
    final textColor = isDark ? Colors.white : AppColors.screenTextPrimary;
    final hintColor = isDark ? Colors.white38 : const Color(0xFFBBBBBB);
    final textFillColor = isDark ? const Color(0xFF1E1E1E) : AppColors.screenSurface;
    final borderColor = isDark ? const Color(0xFF333333) : AppColors.screenDivider;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label, 
              style: TextStyle(
                fontSize: 12, 
                fontWeight: FontWeight.w600, 
                color: labelColor,
              ),
            ),
            if (required) const Text(' *', style: TextStyle(color: AppColors.screenOrange, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType ?? TextInputType.text,
          maxLines: maxLines,
          inputFormatters: inputFormatters,
          readOnly: readOnly,
          style: TextStyle(
            fontSize: 14, 
            color: textColor, 
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              fontSize: 13, 
              color: hintColor,
            ),
            prefixIcon: Icon(
              icon, 
              color: hasError ? Colors.red : Colors.grey, 
              size: 18,
            ),
            filled: true,
            fillColor: textFillColor,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12), 
              borderSide: BorderSide(color: hasError ? Colors.red : borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12), 
              borderSide: BorderSide(color: hasError ? Colors.red : borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12), 
              borderSide: BorderSide(
                color: hasError ? Colors.red : (focusBorderColor ?? AppColors.screenOrange), 
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
