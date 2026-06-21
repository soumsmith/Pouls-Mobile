---
name: searchable-dropdown
description: Guide pour comprendre et utiliser le composant SearchableDropdown, une liste déroulante avec barre de recherche intégrée.
---

# 🚀 Guide du Composant : SearchableDropdown

Ce guide vous explique de manière ultra-simple ce qu'est le composant `SearchableDropdown` et comment l'utiliser dans votre application. C'est idéal quand vous avez de grandes listes de choix !

## À quoi ça sert ? 🤔
Une liste déroulante classique (un `DropdownButton` dans Flutter) c'est très bien, mais quand il y a beaucoup d'options (ex: une liste de centaines de pays, de villes ou de catégories), c'est l'enfer pour l'utilisateur de scroller pour trouver ce qu'il cherche.

Le **`SearchableDropdown`** résout ce problème en ajoutant une **barre de recherche** directement à l'intérieur de la liste ! 
- L'utilisateur tape ce qu'il cherche.
- La liste se filtre toute seule en temps réel.
- Le menu s'affiche intelligemment par-dessus le reste de l'écran grâce à un système appelé `Overlay` (donc pas de soucis de mise en page cassée).

---

## Étape 1 : Le Code du Composant (L'Implémentation)

Le code est divisé en deux parties :
1. Le bouton principal sur lequel l'utilisateur clique sur la page (`SearchableDropdown`).
2. Le menu flottant avec la barre de recherche qui s'affiche au-dessus quand on a cliqué (`_DropdownOverlayContent`).

📁 **Chemin du fichier :** `lib/widgets/searchable_dropdown.dart`

```dart
import 'package:flutter/material.dart';

// --- VOS FICHIERS DE CONFIGURATION ---
// import '../services/text_size_service.dart';
// import '../config/app_colors.dart';
// import '../config/app_typography.dart';
// import '../config/app_dimensions.dart';

// =====================================================================
// 1. LE BOUTON PRINCIPAL (Celui qu'on voit sur la page au repos)
// =====================================================================

/// Widget Dropdown avec recherche intégrée
class SearchableDropdown extends StatefulWidget {
  final String label;            // Le petit texte descriptif au-dessus (ex: "Sélectionnez un pays")
  final String value;            // La valeur actuellement sélectionnée
  final List<String> items;      // La liste de tous les choix possibles
  final Function(String) onChanged; // La fonction appelée quand on choisit un élément
  final bool isDarkMode;         // Gérer le thème sombre/clair
  final bool autoFocusSearch;    // Ouvrir le clavier automatiquement quand le menu s'ouvre ?

  const SearchableDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.isDarkMode,
    this.autoFocusSearch = true, // Par défaut, on ouvre le clavier directement pour faire gagner du temps
  });

  @override
  State<SearchableDropdown> createState() => _SearchableDropdownState();
}

class _SearchableDropdownState extends State<SearchableDropdown> with WidgetsBindingObserver {
  // Cette variable va contenir notre menu déroulant "flottant" (l'Overlay)
  OverlayEntry? _overlayEntry;
  // Ceci permet d'attacher "magnétiquement" le menu flottant juste en dessous de notre bouton
  final LayerLink _layerLink = LayerLink();
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    // On écoute les changements du téléphone (ex: quand le clavier système apparaît/disparaît)
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _removeOverlay(isDisposing: true);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // 🔘 Ouvre ou ferme le menu au clic
  void _toggleDropdown() {
    if (_isOpen) {
      _removeOverlay();
    } else {
      _showOverlay();
    }
  }

  // 🟢 AFFICHER LE MENU FLOTTANT
  void _showOverlay() {
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _isOpen = true);
  }

  // 🔴 FERMER LE MENU FLOTTANT
  void _removeOverlay({bool isDisposing = false}) {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted && !isDisposing) setState(() => _isOpen = false);
  }

  // 🛠️ CRÉATION DU MENU FLOTTANT (L'Overlay)
  OverlayEntry _createOverlayEntry() {
    // On calcule la position et la taille exacte de notre bouton pour placer le menu juste en dessous !
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = Offset(0.0, size.height + 5.0); // 5 pixels de décalage en dessous du bouton

    return OverlayEntry(
      builder: (context) => GestureDetector(
        // Si on clique n'importe où ailleurs sur l'écran transparent, ça ferme le menu
        onTap: _removeOverlay,
        behavior: HitTestBehavior.translucent,
        child: Stack(
          children: [
            Positioned(
              width: size.width, // Le menu fait exactement la même largeur que le bouton
              child: CompositedTransformFollower(
                link: _layerLink, // On l'attache à notre LayerLink défini plus bas
                showWhenUnlinked: false,
                offset: offset,
                child: GestureDetector(
                  // Empêche la fermeture du menu si on clique spécifiquement à l'intérieur du menu
                  onTap: () {},
                  child: _DropdownOverlayContent(
                    items: widget.items,
                    selectedValue: widget.value,
                    isDarkMode: widget.isDarkMode,
                    autoFocusSearch: widget.autoFocusSearch,
                    onSelected: (item) {
                      // Quand on clique sur un choix, on envoie la nouvelle donnée et on ferme le menu !
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
        // "CompositedTransformTarget" est le "point d'ancrage" pour notre menu flottant
        return CompositedTransformTarget(
          link: _layerLink,
          child: GestureDetector(
            onTap: _toggleDropdown, // Quand on clique sur la boîte (le bouton)
            child: Container(
              // LE DESIGN DE LA BOÎTE (Bordures, couleurs...)
              decoration: BoxDecoration(
                color: AppColors.getSurfaceColor(widget.isDarkMode),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  // Bordure orange si ouvert, sinon bordure grise classique
                  color: _isOpen ? AppColors.inputFocusedBorder : AppColors.getBorderColor(widget.isDarkMode),
                  width: _isOpen ? AppDimensions.inputFocusedBorderWidth : 1,
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
                        // Le petit texte "Label" au-dessus
                        Text(
                          widget.label,
                          style: TextStyle(
                            color: AppColors.getTextColor(widget.isDarkMode, type: TextType.secondary),
                            fontSize: textSizeService.getScaledFontSize(10),
                          ),
                        ),
                        const SizedBox(height: 4),
                        // La valeur actuellement choisie (en texte plus grand)
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
                  // La petite flèche à droite qui monte ou qui descend
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

// =====================================================================
// 2. LE CONTENU FLOTTANT (La barre de recherche et la liste des choix)
// =====================================================================
// On fait une classe à part pour que quand on tape du texte et qu'on "setState"
// pour filtrer la liste, ça ne recharge pas toute la page mais JUSTE la liste !

class _DropdownOverlayContent extends StatefulWidget {
  final List<String> items;
  final String selectedValue;
  final bool isDarkMode;
  final ValueChanged<String> onSelected;
  final bool autoFocusSearch;

  const _DropdownOverlayContent({
    required this.items,
    required this.selectedValue,
    required this.isDarkMode,
    required this.onSelected,
    this.autoFocusSearch = true,
  });

  @override
  State<_DropdownOverlayContent> createState() => _DropdownOverlayContentState();
}

class _DropdownOverlayContentState extends State<_DropdownOverlayContent> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final TextSizeService _textSizeService = TextSizeService();
  
  // La liste des éléments actuellement visibles (ceux qui correspondent à la recherche)
  late List<String> _filteredItems;

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.items; // Au début, rien n'est tapé, on affiche TOUT.
    
    // Si on veut, on ouvre le clavier automatiquement
    if (widget.autoFocusSearch) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _searchFocusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  // 🔎 LA FONCTION DE RECHERCHE MAGIQUE
  void _filterItems(String query) {
    setState(() {
      _filteredItems = query.isEmpty
          ? widget.items // Si on efface la recherche, on remet tout
          : widget.items.where(
              // On cherche sans faire attention aux majuscules/minuscules
              (item) => item.toLowerCase().contains(query.toLowerCase()),
            ).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _textSizeService,
      builder: (context, _) {
        // La "boîte" flottante avec son ombre
        return Material(
          elevation: 8.0,
          borderRadius: BorderRadius.circular(12),
          color: AppColors.getSurfaceColor(widget.isDarkMode),
          shadowColor: widget.isDarkMode ? Colors.black54 : AppColors.shadowLight,
          child: Container(
            constraints: const BoxConstraints(maxHeight: 300), // La liste ne fera jamais plus de 300 pixels de haut
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.getBorderColor(widget.isDarkMode)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                
                // ── 1. LA BARRE DE RECHERCHE ──────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppColors.getBorderColor(widget.isDarkMode))),
                  ),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    autofocus: widget.autoFocusSearch,
                    decoration: InputDecoration(
                      hintText: 'Rechercher...',
                      prefixIcon: Icon(Icons.search, size: 18),
                      // ... (design simplifié du TextField)
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      isDense: true,
                    ),
                    onChanged: _filterItems, // À CHAQUE LETTRE TAPÉE, ON FILTRE !
                  ),
                ),

                // ── 2. LA LISTE DES RÉSULTATS ──────────────────────────
                Flexible(
                  child: _filteredItems.isEmpty
                      ? Padding( // SI RIEN N'A ÉTÉ TROUVÉ
                          padding: const EdgeInsets.all(16),
                          child: Text('Aucun résultat', textAlign: TextAlign.center),
                        )
                      : ListView.builder( // SI ON A DES RÉSULTATS
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: _filteredItems.length,
                          itemBuilder: (context, index) {
                            final item = _filteredItems[index];
                            final isSelected = item == widget.selectedValue;

                            return InkWell(
                              onTap: () => widget.onSelected(item), // Au clic, on valide le choix !
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                // Si c'est l'élément déjà choisi, on lui met un petit fond de couleur
                                color: isSelected ? AppColors.primary.withOpacity(0.1) : null,
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item,
                                        style: TextStyle(
                                          color: isSelected ? AppColors.primary : AppColors.getTextColor(widget.isDarkMode),
                                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                    // On met une petite encoche (✓) à côté de l'élément sélectionné
                                    if (isSelected)
                                      const Icon(Icons.check, color: AppColors.primary, size: 16),
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
```

---

## Étape 2 : Le Modèle et le Service (Appel API)

Dans une vraie application, la liste de choix vient d'une base de données ou d'une API sur internet. Voici comment préparer le terrain avec un **Modèle** (la structure des données) et un **Service** (l'appel réseau).

📝 **1. Le Modèle (`country_model.dart`) :**
```dart
class CountryModel {
  final int id;
  final String name;

  CountryModel({
    required this.id,
    required this.name,
  });

  // Pour transformer le JSON (qui vient d'internet) en un objet Flutter
  factory CountryModel.fromJson(Map<String, dynamic> json) {
    return CountryModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Inconnu',
    );
  }
}
```

📝 **2. Le Service API (`country_service.dart`) :**
```dart
import 'dart:convert';
import 'package:http/http.dart' as http;
// import 'country_model.dart';

class CountryService {
  // L'URL de votre vraie API internet
  static const String apiUrl = "https://votre-api.com/countries";

  /// Fonction qui télécharge la liste des pays depuis l'API
  Future<List<CountryModel>> fetchCountries() async {
    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        // 1. On décode le JSON brut reçu d'internet
        final List<dynamic> jsonData = json.decode(response.body);
        
        // 2. On transforme chaque élément JSON en un bel objet "CountryModel"
        return jsonData.map((data) => CountryModel.fromJson(data)).toList();
      } else {
        throw Exception("Erreur lors du chargement des pays");
      }
    } catch (e) {
      print("Erreur réseau : $e");
      // S'il y a une erreur réseau (ex: pas de connexion), on renvoie une liste vide
      return []; 
    }
  }
}
```

---

## Étape 3 : Comment l'utiliser ? (L'Exemple Complet)

Voici comment combiner notre widget `SearchableDropdown` avec notre `CountryService` pour avoir un écran 100% dynamique et connecté à internet.

📝 **Exemple d'utilisation dans un écran :**

```dart
import 'package:flutter/material.dart';
// import '../widgets/searchable_dropdown.dart';
// import '../services/country_service.dart';
// import '../models/country_model.dart';

class MonEcranFormulaire extends StatefulWidget {
  @override
  _MonEcranFormulaireState createState() => _MonEcranFormulaireState();
}

class _MonEcranFormulaireState extends State<MonEcranFormulaire> {
  // 1. Nos variables pour stocker les données de l'API
  List<CountryModel> listePays = []; // La vraie liste d'objets (avec ID)
  List<String> nomsDesPays = [];     // Juste les noms en texte (pour le Dropdown)
  
  // 2. État du chargement
  bool isLoading = true;
  String paysChoisi = "Sélectionnez un pays";

  @override
  void initState() {
    super.initState();
    // Au lancement de l'écran, on télécharge les données depuis internet
    _chargerLesPays();
  }

  Future<void> _chargerLesPays() async {
    final service = CountryService();
    final paysRecuperes = await service.fetchCountries();

    setState(() {
      listePays = paysRecuperes;
      // On extrait juste les noms ("name") pour les donner à notre composant Dropdown
      nomsDesPays = paysRecuperes.map((pays) => pays.name).toList();
      isLoading = false; // Le chargement est terminé !
    });
  }

  @override
  Widget build(BuildContext context) {
    // Variable pour savoir si on est en mode sombre ou clair
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text("Choisir un pays")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            
            // Si c'est en train de charger, on affiche une petite roue qui tourne
            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else
              // NOTRE SUPER DROPDOWN MAGIQUE
              SearchableDropdown(
                label: "Pays de résidence",
                value: paysChoisi,
                items: nomsDesPays, // On lui donne la liste des noms qu'on a téléchargée
                isDarkMode: isDarkMode,
                
                // Quand l'utilisateur clique sur un pays dans la liste
                onChanged: (nouvelleValeur) {
                  setState(() {
                    paysChoisi = nouvelleValeur;
                  });

                  // BONUS : Si on veut retrouver l'ID du pays choisi pour l'envoyer au serveur
                  final selectedCountryObj = listePays.firstWhere(
                    (pays) => pays.name == nouvelleValeur,
                    orElse: () => CountryModel(id: 0, name: "Inconnu"),
                  );
                  print("ID du pays sélectionné : \${selectedCountryObj.id}");
                },
              ),

          ],
        ),
      ),
    );
  }
}
```

**Bravo 🎉 ! Vous savez désormais comment lier des données venues d'internet avec votre fantastique liste déroulante !**
