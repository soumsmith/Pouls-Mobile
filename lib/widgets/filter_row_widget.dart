import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import '../config/app_dimensions.dart';

class FilterRowWidget extends StatelessWidget {
  final List<String> filters;
  final String? selectedFilter;
  final ValueChanged<String> onFilterSelected;
  final Color? selectedColor;
  final Gradient? selectedGradient;
  final Color? selectedTextColor;

  const FilterRowWidget({
    super.key,
    required this.filters,
    this.selectedFilter,
    required this.onFilterSelected,
    this.selectedColor,
    this.selectedGradient,
    this.selectedTextColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      //color: AppColors.screenCardThemed(context),
      padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: SizedBox(
        height: AppDimensions.getFilterContainerHeight(context),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: filters.length,
          separatorBuilder: (_, __) => SizedBox(width: AppDimensions.getFilterSpacing(context)),
          itemBuilder: (_, i) {
            final filter = filters[i];
            final isSelected = filter == selectedFilter;
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: Duration(milliseconds: 300 + i * 40),
              builder: (_, value, child) => Opacity(opacity: value, child: child),
              child: GestureDetector(
                onTap: () => onFilterSelected(filter),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.symmetric(
                    horizontal: AppDimensions.getFilterPadding(context),
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: isSelected ? (selectedGradient ?? AppColors.screenOrangeGradient) : null,
                    color: isSelected ? (selectedColor ?? null) : AppColors.screenSurfaceThemed(context),
                    borderRadius: BorderRadius.circular(AppDimensions.getFilterBorderRadius(context)),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: (selectedColor ?? AppColors.screenOrange).withOpacity(0.30),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : [],
                  ),
                  child: Text(
                    filter,
                    style: TextStyle(
                      fontSize: AppDimensions.getFilterFontSize(context),
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? (selectedTextColor ?? Colors.white) : AppColors.grey666Adaptive(context),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
