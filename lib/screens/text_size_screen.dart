import 'package:flutter/material.dart';
import '../services/text_size_service.dart';
import '../config/app_colors.dart';
import '../widgets/back_button_widget.dart';

class TextSizeScreen extends StatefulWidget {
  const TextSizeScreen({super.key});

  @override
  State<TextSizeScreen> createState() => _TextSizeScreenState();
}

class _TextSizeScreenState extends State<TextSizeScreen> {
  final TextSizeService _textSizeService = TextSizeService();
  TextSize _selectedTextSize = TextSize.moyen;

  @override
  void initState() {
    super.initState();
    _selectedTextSize = _textSizeService.currentTextSize;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.getPureBackground(isDark),
      appBar: AppBar(
        backgroundColor: AppColors.getPureAppBarBackground(isDark),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: const BackButtonWidget(),
        title: Text(
          'Taille du texte',
          style: TextStyle(
            color: AppColors.getTextColor(isDark),
            fontSize: _textSizeService.getScaledFontSize(20),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section d'aperçu
            _buildPreviewSection(isDark),
            const SizedBox(height: 32),
            
            // Section de sélection
            _buildSelectionSection(isDark),
            const SizedBox(height: 32),
            
            // Bouton d'application
            _buildApplyButton(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewSection(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.getSurfaceColor(isDark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.getBorderColor(isDark),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark 
                ? AppColors.black.withOpacity(0.2)
                : AppColors.shadowLight,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Aperçu',
            style: TextStyle(
              fontSize: _textSizeService.getScaledFontSize(18),
              fontWeight: FontWeight.w600,
              color: AppColors.getTextColor(isDark),
            ),
          ),
          const SizedBox(height: 16),
          
          // Exemples de texte avec différentes tailles
          _buildTextExample(
            'Titre principal',
            TextStyle(
              fontSize: _textSizeService.getScaledFontSize(24),
              fontWeight: FontWeight.bold,
              color: AppColors.getTextColor(isDark),
            ),
          ),
          const SizedBox(height: 12),
          
          _buildTextExample(
            'Sous-titre ou texte important',
            TextStyle(
              fontSize: _textSizeService.getScaledFontSize(18),
              fontWeight: FontWeight.w600,
              color: AppColors.getTextColor(isDark),
            ),
          ),
          const SizedBox(height: 12),
          
          _buildTextExample(
            'Texte normal pour le contenu principal des articles et des descriptions. Ce texte montre comment apparaît le contenu habituel de l\'application.',
            TextStyle(
              fontSize: _textSizeService.getScaledFontSize(16),
              color: AppColors.getTextColor(isDark),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          
          _buildTextExample(
            'Texte secondaire pour les légendes et informations supplémentaires.',
            TextStyle(
              fontSize: _textSizeService.getScaledFontSize(14),
              color: AppColors.getTextColor(isDark, type: TextType.secondary),
            ),
          ),
          const SizedBox(height: 12),
          
          _buildTextExample(
            'Petit texte pour les annotations et détails.',
            TextStyle(
              fontSize: _textSizeService.getScaledFontSize(12),
              color: AppColors.getTextColor(isDark, type: TextType.tertiary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextExample(String text, TextStyle style) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: style),
    );
  }

  Widget _buildSelectionSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choisir la taille',
          style: TextStyle(
            fontSize: _textSizeService.getScaledFontSize(18),
            fontWeight: FontWeight.w600,
            color: AppColors.getTextColor(isDark),
          ),
        ),
        const SizedBox(height: 16),
        
        Container(
          decoration: BoxDecoration(
            color: AppColors.getSurfaceColor(isDark),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.getBorderColor(isDark),
            ),
            boxShadow: [
              BoxShadow(
                color: isDark 
                    ? AppColors.black.withOpacity(0.2)
                    : AppColors.shadowLight,
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: TextSize.values.map((textSize) {
              final isSelected = _selectedTextSize == textSize;
              final isCurrent = _textSizeService.currentTextSize == textSize;
              
              return _buildTextSizeOption(
                textSize,
                isSelected,
                isCurrent,
                isDark,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildTextSizeOption(
    TextSize textSize,
    bool isSelected,
    bool isCurrent,
    bool isDark,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedTextSize = textSize;
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isSelected 
                ? AppColors.primary.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              // Radio button
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.getBorderColor(isDark),
                    width: 2,
                  ),
                  color: isSelected ? AppColors.primary : Colors.transparent,
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check,
                        size: 16,
                        color: AppColors.white,
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              
              // Texte
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          textSize.label,
                          style: TextStyle(
                            fontSize: _textSizeService.getScaledFontSize(16),
                            fontWeight: FontWeight.w600,
                            color: AppColors.getTextColor(isDark),
                          ),
                        ),
                        if (isCurrent) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.success,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Actuel',
                              style: TextStyle(
                                fontSize: _textSizeService.getScaledFontSize(10),
                                color: AppColors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getTextSizeDescription(textSize),
                      style: TextStyle(
                        fontSize: _textSizeService.getScaledFontSize(14),
                        color: AppColors.getTextColor(isDark, type: TextType.secondary),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Aperçu du texte
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.getSurfaceColor(isDark),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.getBorderColor(isDark),
                  ),
                ),
                child: Text(
                  'Aa',
                  style: TextStyle(
                    fontSize: 16 * textSize.scale,
                    fontWeight: FontWeight.bold,
                    color: AppColors.getTextColor(isDark),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getTextSizeDescription(TextSize textSize) {
    switch (textSize) {
      case TextSize.petit:
        return 'Idéal pour économiser de l\'espace';
      case TextSize.moyen:
        return 'Taille standard recommandée';
      case TextSize.grand:
        return 'Plus confortable pour la lecture';
      case TextSize.tresGrand:
        return 'Maximum de lisibilité';
    }
  }

  Widget _buildApplyButton(bool isDark) {
    final isChanged = _selectedTextSize != _textSizeService.currentTextSize;
    
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: isChanged ? AppColors.primaryGradient : null,
        color: isChanged ? null : AppColors.grey300,
        boxShadow: isChanged ? [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ] : null,
      ),
      child: ElevatedButton(
        onPressed: isChanged
            ? () async {
                await _textSizeService.setTextSize(_selectedTextSize);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Taille du texte appliquée: ${_selectedTextSize.label}',
                        style: TextStyle(
                          fontSize: _selectedTextSize.scale * 14,
                        ),
                      ),
                      backgroundColor: AppColors.success,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                  Navigator.of(context).pop();
                }
              }
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          'Appliquer les changements',
          style: TextStyle(
            color: isChanged ? AppColors.white : AppColors.grey600,
            fontSize: _textSizeService.getScaledFontSize(16),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
