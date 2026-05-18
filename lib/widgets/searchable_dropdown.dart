import 'package:flutter/material.dart';
import '../services/text_size_service.dart';
import '../config/app_colors.dart';
import '../config/app_typography.dart';

/// Widget Dropdown avec recherche intégrée
class SearchableDropdown extends StatefulWidget {
  final String label;
  final String value;
  final List<String> items;
  final Function(String) onChanged;
  final bool isDarkMode;

  const SearchableDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.isDarkMode,
  });

  @override
  State<SearchableDropdown> createState() => _SearchableDropdownState();
}

class _SearchableDropdownState extends State<SearchableDropdown>
    with WidgetsBindingObserver {
  // Plus de _searchController, _searchFocusNode, ni _filteredItems ici
  // Ils sont désormais dans _DropdownOverlayContent
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _removeOverlay();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _toggleDropdown() {
    if (_isOpen) {
      _removeOverlay();
    } else {
      _showOverlay();
    }
  }

  void _showOverlay() {
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _isOpen = true);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted) setState(() => _isOpen = false);
  }

  OverlayEntry _createOverlayEntry() {
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final translation = renderBox.getTransformTo(null).getTranslation();
    final globalOffset = Offset(translation.x, translation.y);

    final screenHeight = MediaQuery.of(context).size.height;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final availableHeight = screenHeight - keyboardHeight;

    const dropdownHeight = 300.0;
    // UX Choice: Always display the dropdown downward to prevent overlapping issues in bottom sheets
    final offset = Offset(0.0, size.height + 5.0);

    return OverlayEntry(
      builder: (context) => GestureDetector(
        onTap: _removeOverlay,
        behavior: HitTestBehavior.translucent,
        child: Stack(
          children: [
            Positioned(
              width: size.width,
              child: CompositedTransformFollower(
                link: _layerLink,
                showWhenUnlinked: false,
                offset: offset,
                child: GestureDetector(
                  // Bloque la propagation du tap vers le GestureDetector parent
                  // pour ne pas fermer le dropdown quand on clique à l'intérieur
                  onTap: () {},
                  child: _DropdownOverlayContent(
                    items: widget.items,
                    selectedValue: widget.value,
                    isDarkMode: widget.isDarkMode,
                    onSelected: (item) {
                      widget.onChanged(item);
                      _removeOverlay();
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textSizeService = TextSizeService();
    return AnimatedBuilder(
      animation: textSizeService,
      builder: (context, _) {
        return CompositedTransformTarget(
          link: _layerLink,
          child: GestureDetector(
            onTap: _toggleDropdown,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.getSurfaceColor(widget.isDarkMode),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _isOpen
                      ? AppColors.primary
                      : AppColors.getBorderColor(widget.isDarkMode),
                  width: _isOpen ? 1.5 : 1,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.label,
                          style: TextStyle(
                            color: AppColors.getTextColor(
                              widget.isDarkMode,
                              type: TextType.secondary,
                            ),
                            fontSize: textSizeService.getScaledFontSize(10),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.value,
                          style: TextStyle(
                            color: AppColors.getTextColor(widget.isDarkMode),
                            fontWeight: FontWeight.w500,
                            fontSize: textSizeService.getScaledFontSize(12),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _isOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                    color: AppColors.getTextColor(
                      widget.isDarkMode,
                      type: TextType.secondary,
                    ),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widget dédié pour le contenu de l'overlay.
// Il possède son propre State → le TextField ne perd plus jamais le focus
// lors du filtrage, car setState() ne touche que cet arbre de widgets.
// ─────────────────────────────────────────────────────────────────────────────
class _DropdownOverlayContent extends StatefulWidget {
  final List<String> items;
  final String selectedValue;
  final bool isDarkMode;
  final ValueChanged<String> onSelected;

  const _DropdownOverlayContent({
    required this.items,
    required this.selectedValue,
    required this.isDarkMode,
    required this.onSelected,
  });

  @override
  State<_DropdownOverlayContent> createState() =>
      _DropdownOverlayContentState();
}

class _DropdownOverlayContentState extends State<_DropdownOverlayContent> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final TextSizeService _textSizeService = TextSizeService();
  late List<String> _filteredItems;

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.items;
  }

  @override
  void didUpdateWidget(_DropdownOverlayContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.items != oldWidget.items) {
      setState(() {
        _filteredItems = widget.items;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _filterItems(String query) {
    // setState ici ne touche que _DropdownOverlayContent
    // → le TextField conserve son focus et son curseur
    setState(() {
      _filteredItems = query.isEmpty
          ? widget.items
          : widget.items
                .where(
                  (item) => item.toLowerCase().contains(query.toLowerCase()),
                )
                .toList();
    });
    // Plus besoin de markNeedsBuild() sur l'OverlayEntry
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _textSizeService,
      builder: (context, _) {
        return Material(
          elevation: 8.0,
          borderRadius: BorderRadius.circular(12),
          color: AppColors.getSurfaceColor(widget.isDarkMode),
          shadowColor: widget.isDarkMode
              ? Colors.black54
              : AppColors.shadowLight,
          child: Container(
            constraints: const BoxConstraints(maxHeight: 300),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.getBorderColor(widget.isDarkMode),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Champ de recherche ──────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: AppColors.getBorderColor(widget.isDarkMode),
                      ),
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    autofocus: false,
                    enableInteractiveSelection: true,
                    decoration: InputDecoration(
                      hintText: 'Rechercher...',
                      hintStyle: TextStyle(
                        color: AppColors.getTextColor(
                          widget.isDarkMode,
                          type: TextType.secondary,
                        ),
                        fontSize: _textSizeService.getScaledFontSize(12),
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: AppColors.getTextColor(
                          widget.isDarkMode,
                          type: TextType.secondary,
                        ),
                        size: 18,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: AppColors.getBorderColor(widget.isDarkMode),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: AppColors.getBorderColor(widget.isDarkMode),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 1.5,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      isDense: true,
                    ),
                    style: TextStyle(
                      color: AppColors.getTextColor(widget.isDarkMode),
                      fontSize: _textSizeService.getScaledFontSize(12),
                    ),
                    onChanged: _filterItems,
                  ),
                ),

                // ── Liste des éléments filtrés ──────────────────────────
                Flexible(
                  child: _filteredItems.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'Aucun résultat',
                            style: TextStyle(
                              color: AppColors.getTextColor(
                                widget.isDarkMode,
                                type: TextType.secondary,
                              ),
                              fontSize: _textSizeService.getScaledFontSize(12),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: _filteredItems.length,
                          itemBuilder: (context, index) {
                            final item = _filteredItems[index];
                            final isSelected = item == widget.selectedValue;

                            return InkWell(
                              onTap: () => widget.onSelected(item),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primary.toSurface()
                                      : null,
                                  border: Border(
                                    bottom: BorderSide(
                                      color: AppColors.getBorderColor(
                                        widget.isDarkMode,
                                      ).withOpacity(0.5),
                                      width: 0.5,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item,
                                        style: TextStyle(
                                          color: isSelected
                                              ? AppColors.primary
                                              : AppColors.getTextColor(
                                                  widget.isDarkMode,
                                                ),
                                          fontSize: _textSizeService
                                              .getScaledFontSize(12),
                                          fontWeight: isSelected
                                              ? FontWeight.w600
                                              : FontWeight.normal,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (isSelected)
                                      const Icon(
                                        Icons.check,
                                        color: AppColors.primary,
                                        size: 16,
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
