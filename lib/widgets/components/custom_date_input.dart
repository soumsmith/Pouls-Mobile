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

class DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.length < oldValue.text.length) {
      String text = newValue.text.replaceAll(RegExp(r'[^0-9/]'), '');
      if (oldValue.selection.baseOffset > 0 &&
          oldValue.text.length > newValue.text.length) {
        int deletedIndex = newValue.selection.baseOffset;
        if (deletedIndex > 0 && deletedIndex <= text.length) {
          if (deletedIndex > 0 && text[deletedIndex - 1] == '/') {
            text = text.substring(0, deletedIndex - 1) +
                (deletedIndex < text.length ? text.substring(deletedIndex) : '');
          }
        }
      }
      return TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    }

    String text = newValue.text.replaceAll(RegExp(r'[^0-9/]'), '');
    if (newValue.text.contains('-') && !newValue.text.contains('/')) {
      text = text.replaceAll('-', '/');
    }
    if (text.length > 10) text = text.substring(0, 10);

    if (text.length >= 2 && !text.contains('/')) {
      text = text.substring(0, 2) + '/' + text.substring(2);
    }
    if (text.length >= 5 && text.indexOf('/', text.indexOf('/') + 1) == -1) {
      int firstSlash = text.indexOf('/');
      if (firstSlash != -1) {
        String day = text.substring(0, firstSlash);
        String monthYear = text.substring(firstSlash + 1);
        if (monthYear.length >= 2) {
          text = day + '/' + monthYear.substring(0, 2) + '/' + monthYear.substring(2);
        }
      }
    }

    List<String> parts = text.split('/');
    if (parts.length >= 3) {
      if (parts[0].length == 2 && int.tryParse(parts[0]) != null) {
        if (int.parse(parts[0]) > 31) parts[0] = '31';
      }
      if (parts[1].length == 2 && int.tryParse(parts[1]) != null) {
        if (int.parse(parts[1]) > 12) parts[1] = '12';
      }
      if (parts[2].length == 4 && int.tryParse(parts[2]) != null) {
        int currentYear = DateTime.now().year;
        if (int.parse(parts[2]) > currentYear) {
          parts[2] = currentYear.toString();
        }
      }
      text = parts.join('/');
    }

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
