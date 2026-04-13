import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../custom_text_field.dart';
import '../../config/app_colors.dart';

class CustomDateInput extends StatelessWidget {
  final String label;
  final String hint;
  final IconData icon;
  final TextEditingController controller;
  final Color? iconColor;
  final Color? focusBorderColor;
  final bool hasError;
  final List<TextInputFormatter>? inputFormatters;
  final bool required;

  const CustomDateInput({
    Key? key,
    required this.label,
    required this.hint,
    required this.icon,
    required this.controller,
    this.iconColor,
    this.focusBorderColor,
    this.hasError = false,
    this.inputFormatters,
    this.required = false,
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
      keyboardType: TextInputType.datetime,
      inputFormatters: inputFormatters,
    );
  }
}
