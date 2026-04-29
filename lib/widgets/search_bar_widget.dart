import 'package:flutter/material.dart';
import 'dart:async';
import '../config/app_colors.dart';

class SearchBarWidget extends StatefulWidget {
  final bool isSearching;
  final TextEditingController searchController;
  final ValueChanged<String> onChanged;
  final VoidCallback? onClear;
  final String hintText;

  const SearchBarWidget({
    super.key,
    required this.isSearching,
    required this.searchController,
    required this.onChanged,
    this.onClear,
    this.hintText = 'Rechercher...',
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  Timer? _clearTimer;

  @override
  void dispose() {
    _clearTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: widget.isSearching ? 60 : 0,
      //color: AppColors.screenCardThemed(context),
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 6),
      child: widget.isSearching
          ? Container(
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.screenSurfaceThemed(context),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.screenCardThemed(context),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.screenOrange.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: widget.searchController,
                autofocus: true,
                onChanged: widget.onChanged,
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  hintStyle: TextStyle(color: AppColors.screenTextSecondaryThemed(context), fontSize: 14),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    size: 18,
                    color: AppColors.screenOrange,
                  ),
                  suffixIcon: widget.searchController.text.isNotEmpty
                      ? GestureDetector(
                          onTap: () {
                            _clearTimer?.cancel();
                            widget.searchController.clear();
                            widget.onClear?.call();
                          },
                          child: Icon(
                            Icons.cancel_rounded,
                            size: 18,
                            color: AppColors.screenTextSecondaryThemed(context),
                          ),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            )
          : null,
    );
  }
}
