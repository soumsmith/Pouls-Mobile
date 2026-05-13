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

class _SearchableDropdownState extends State<SearchableDropdown> with WidgetsBindingObserver {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final TextSizeService _textSizeService = TextSizeService();
  List<String> _filteredItems = [];
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.items;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _removeOverlay();
    _searchController.dispose();
    _searchFocusNode.dispose();
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
    setState(() {
      _isOpen = true;
    });
    
    // Ne pas automatiquement demander le focus pour permettre le scrolling
    // L'utilisateur pourra cliquer sur le champ de recherche si nécessaire
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (_searchController.text.isNotEmpty) {
      _searchController.clear();
    }
    _filteredItems = widget.items;
    _isOpen = false; // Modification directe sans setState
  }

  OverlayEntry _createOverlayEntry() {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    var size = renderBox.size;
    final renderObject = context.findRenderObject();
    final translation = renderObject?.getTransformTo(null).getTranslation();
    final globalOffset = translation != null ? Offset(translation.x, translation.y) : Offset.zero;
    
    // Récupérer la taille de l'écran et la hauteur du clavier
    final screenHeight = MediaQuery.of(context).size.height;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final availableHeight = screenHeight - keyboardHeight;
    
    // Calculer la position du dropdown
    final dropdownTop = globalOffset.dy + size.height + 5.0;
    final dropdownHeight = 300.0; // Hauteur maximale du dropdown
    
    // Déterminer si le dropdown doit apparaître au-dessus ou en-dessous
    final showAbove = dropdownTop + dropdownHeight > availableHeight;
    final offset = showAbove 
        ? Offset(0.0, -dropdownHeight - 5.0)  // Afficher au-dessus
        : Offset(0.0, size.height + 5.0);     // Afficher en-dessous

    return OverlayEntry(
      builder: (context) => GestureDetector(
        onTap: _removeOverlay,
        child: FocusScope(
          canRequestFocus: false, // Empêcher l'overlay de capturer le focus principal
          child: Stack(
            children: [
              // Zone transparente pour capturer les clics extérieurs
              Positioned.fill(
                child: Container(color: Colors.transparent),
              ),
              // Dropdown content
              Positioned(
                width: size.width,
                child: CompositedTransformFollower(
                  link: _layerLink,
                  showWhenUnlinked: false,
                  offset: offset,
                  child: GestureDetector(
                    onTap: () {}, // Empêcher la propagation du clic pour ne pas fermer le dropdown quand on clique à l'intérieur
                  child: AnimatedBuilder(
                    animation: _textSizeService,
                    builder: (context, child) {
                      return Material(
                        elevation: 8.0,
                        borderRadius: BorderRadius.circular(12),
                        color: AppColors.getSurfaceColor(widget.isDarkMode),
                        shadowColor: widget.isDarkMode ? Colors.black54 : AppColors.shadowLight,
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
                              // Champ de recherche
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: AppColors.getBorderColor(widget.isDarkMode),
                                    ),
                                  ),
                                ),
                                child: GestureDetector(
                                  onTap: () {
                                    // Ne demander le focus que si l'utilisateur clique explicitement
                                    _searchFocusNode.requestFocus();
                                  },
                                  child: TextField(
                                    controller: _searchController,
                                    focusNode: _searchFocusNode,
                                    onTap: () {
                                      // Permettre le focus quand on clique sur le champ
                                      _searchFocusNode.requestFocus();
                                    },
                                    enableInteractiveSelection: false,
                                    decoration: InputDecoration(
                                      hintText: 'Rechercher...',
                                      hintStyle: TextStyle(
                                        color: AppColors.getTextColor(widget.isDarkMode, type: TextType.secondary),
                                        fontSize: _textSizeService.getScaledFontSize(12),
                                      ),
                                      prefixIcon: Icon(
                                        Icons.search,
                                        color: AppColors.getTextColor(widget.isDarkMode, type: TextType.secondary),
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
                                        borderSide: BorderSide(
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
                              ),
                              // Liste des éléments
                              Flexible(
                                child: _filteredItems.isEmpty
                                    ? Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Text(
                                          'Aucun résultat',
                                          style: TextStyle(
                                            color: AppColors.getTextColor(widget.isDarkMode, type: TextType.secondary),
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
                                          final isSelected = item == widget.value;
                                          
                                          return InkWell(
                                            onTap: () {
                                              widget.onChanged(item);
                                              _removeOverlay();
                                            },
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
                                                    color: AppColors.getBorderColor(widget.isDarkMode).withOpacity(0.5),
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
                                                            : AppColors.getTextColor(widget.isDarkMode),
                                                        fontSize: _textSizeService.getScaledFontSize(12),
                                                        fontWeight: isSelected 
                                                          ? FontWeight.w600 
                                                          : FontWeight.normal,
                                                      ),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  if (isSelected)
                                                    Icon(
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
                  ),
                ),
              ),
            )],
          ),
        ),
      ),
    );
  }

  void _filterItems(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredItems = widget.items;
      } else {
        _filteredItems = widget.items
            .where((item) => item.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
    
    // Mettre à jour l'overlay
    _overlayEntry?.markNeedsBuild();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _textSizeService,
      builder: (context, child) {
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
                            color: AppColors.getTextColor(widget.isDarkMode, type: TextType.secondary),
                            fontSize: _textSizeService.getScaledFontSize(10),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.value,
                          style: TextStyle(
                            color: AppColors.getTextColor(widget.isDarkMode),
                            fontWeight: FontWeight.w500,
                            fontSize: _textSizeService.getScaledFontSize(12),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _isOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                    color: AppColors.getTextColor(widget.isDarkMode, type: TextType.secondary),
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
