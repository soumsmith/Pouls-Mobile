import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../custom_text_field.dart';
import '../../config/app_colors.dart';

class CustomTextInput extends StatelessWidget {
  final String label;
  final String hint;
  final IconData icon;
  final TextEditingController controller;
  final Color? iconColor;
  final Color? focusBorderColor;
  final bool hasError;
  final bool required;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final bool readOnly;
  final int maxLines;

  const CustomTextInput({
    Key? key,
    required this.label,
    required this.hint,
    required this.icon,
    required this.controller,
    this.iconColor,
    this.focusBorderColor,
    this.hasError = false,
    this.required = false,
    this.keyboardType,
    this.inputFormatters,
    this.readOnly = false,
    this.maxLines = 1,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      label: label,
      hint: hint,
      icon: icon,
      controller: controller,
      iconColor: iconColor ?? AppColors.shopBlue,
      focusBorderColor: focusBorderColor ?? AppColors.shopBlue,
      hasError: hasError,
      required: required,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      readOnly: readOnly,
      maxLines: maxLines,
    );
  }
}
