import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import '../services/country_service.dart';
import 'bottom_sheets/bottom_sheet_header.dart';

/// Petit chip (drapeau + nom du pays) affiché sur les écrans de connexion
/// et d'inscription, permettant de choisir le serveur d'API à utiliser
/// pour toute la session (voir [CountryService]).
class CountrySelectorChip extends StatefulWidget {
  const CountrySelectorChip({super.key});

  @override
  State<CountrySelectorChip> createState() => _CountrySelectorChipState();
}

class _CountrySelectorChipState extends State<CountrySelectorChip> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final country = CountryService.instance.selectedCountry;

    return GestureDetector(
      onTap: () => _showCountryPicker(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? Colors.white24 : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(country.flag, style: const TextStyle(fontSize: 15)),
            const SizedBox(width: 6),
            Text(
              country.name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ],
        ),
      ),
    );
  }

  void _showCountryPicker(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              BottomSheetHeader(
                icon: Icons.public_outlined,
                iconColor: AppColors.screenOrange,
                title: 'Choisissez votre pays',
                description: 'Détermine le serveur utilisé par l\'application',
                onClose: () => Navigator.of(sheetContext).pop(),
              ),
              ...CountryService.supportedCountries.map((c) {
                final isSelected =
                    c.code == CountryService.instance.selectedCountry.code;
                return ListTile(
                  leading: Text(c.flag, style: const TextStyle(fontSize: 24)),
                  title: Text(
                    c.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle, color: AppColors.screenOrange)
                      : null,
                  onTap: () async {
                    await CountryService.instance.setCountry(c.code);
                    if (sheetContext.mounted) Navigator.of(sheetContext).pop();
                    if (mounted) setState(() {});
                  },
                );
              }),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
