---
name: swipeable-data-table
description: Guide complet pour utiliser le composant SwipeableDataTable, un tableau de données dont les lignes peuvent être glissées (swipe) pour afficher des actions.
---

# 🚀 Guide du Composant : SwipeableDataTable

Ce guide vous explique de manière ultra-simple ce qu'est le composant `SwipeableDataTable` et comment l'utiliser dans votre application. C'est l'outil parfait pour afficher une liste d'éléments (comme des notes, des élèves, ou des factures) avec des boutons d'actions cachés !

## À quoi ça sert ? 🤔
La plupart du temps, dans une application mobile, on manque de place pour mettre un bouton "Modifier" et un bouton "Supprimer" sur chaque ligne d'un tableau.

Le **`SwipeableDataTable`** résout ce problème de manière très élégante :
- Il affiche vos données sous forme de **colonnes bien alignées**.
- L'utilisateur peut **"swiper" (glisser son doigt)** sur une ligne vers la gauche ou la droite.
- Ce geste fait apparaître des **actions secrètes** (comme Supprimer, Éditer, ou Valider).

---

## Étape 1 : Le Code du Composant (L'Implémentation)

Si ce composant n'existe pas encore dans votre projet, ou si vous voulez voir comment il fonctionne sous le capot, voici son code complet. Il utilise intelligemment le widget natif `Dismissible` de Flutter.

📁 **Chemin du fichier :** `lib/widgets/swipeable_data_table.dart`

```dart
import 'package:flutter/material.dart';
// N'oubliez pas votre fichier de couleurs !
// import '../config/app_colors.dart';

// =====================================================================
// 1. LES CLASSES DE DONNÉES (Pour configurer les lignes)
// =====================================================================

/// 🛠️ Représente un bouton d'action caché sous la ligne
class SwipeAction {
  final String label;      // Le texte en dessous de l'icône
  final IconData icon;     // L'icône (ex: Icons.delete)
  final Color color;       // La couleur de fond quand on glisse
  final VoidCallback onTap;// Ce qui se passe quand on clique/swipe

  SwipeAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

/// 📄 Représente une seule ligne de votre tableau
class SwipeableDataRow {
  // L'identifiant UNIQUE de cette ligne (très important pour que Flutter ne s'emmêle pas les pinceaux)
  final String id; 
  
  // Les widgets à afficher dans chaque colonne de cette ligne (ex: Text("15/20"), Text("Maths"))
  final List<Widget> cells; 
  
  // L'action qui apparaît si on glisse le doigt vers la DROITE 👉
  final SwipeAction? leftAction; 
  
  // L'action qui apparaît si on glisse le doigt vers la GAUCHE 👈
  final SwipeAction? rightAction; 
  
  // Ce qui se passe si on fait juste un tap normal sur la ligne
  final VoidCallback? onTap; 

  SwipeableDataRow({
    required this.id,
    required this.cells,
    this.leftAction,
    this.rightAction,
    this.onTap,
  });
}

// =====================================================================
// 2. LE WIDGET PRINCIPAL VISUEL
// =====================================================================

/// 📊 Un magnifique tableau avec des lignes glissantes
class SwipeableDataTable extends StatelessWidget {
  // Les titres des colonnes tout en haut (ex: ["Matière", "Note", "Date"])
  final List<String> headers;
  
  // Toutes nos lignes de données
  final List<SwipeableDataRow> rows;
  
  // Mode sombre ou clair
  final bool isDarkMode;
  
  // Astuce de pro : Permet de donner plus de largeur à certaines colonnes !
  // Ex: [2, 1, 1] signifie que la 1ère colonne sera 2 fois plus large que les autres.
  final List<int>? flexColumnWidths; 

  const SwipeableDataTable({
    super.key,
    required this.headers,
    required this.rows,
    required this.isDarkMode,
    this.flexColumnWidths,
  });

  @override
  Widget build(BuildContext context) {
    // Si on n'a pas précisé les tailles de colonnes, elles font toutes la même taille (flex = 1)
    final widths = flexColumnWidths ?? List.filled(headers.length, 1);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        
        // ─── L'EN-TÊTE DU TABLEAU (Gris avec bordures arrondies en haut) ───
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDarkMode ? AppColors.grey800 : Colors.grey[100],
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            border: Border.all(color: AppColors.getBorderColor(isDarkMode)),
          ),
          child: Row(
            // On génère autant de colonnes que de titres dans 'headers'
            children: List.generate(headers.length, (index) {
              return Expanded(
                flex: widths[index], // Applique la largeur relative
                child: Text(
                  headers[index],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.getTextColor(isDarkMode, type: TextType.secondary),
                  ),
                ),
              );
            }),
          ),
        ),

        // ─── LE CORPS DU TABLEAU (La liste des lignes) ───
        Container(
          decoration: BoxDecoration(
            color: AppColors.getSurfaceColor(isDarkMode),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
            border: Border(
              left: BorderSide(color: AppColors.getBorderColor(isDarkMode)),
              right: BorderSide(color: AppColors.getBorderColor(isDarkMode)),
              bottom: BorderSide(color: AppColors.getBorderColor(isDarkMode)),
            ),
          ),
          // S'il n'y a aucune donnée...
          child: rows.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    "Aucune donnée disponible",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.getTextColor(isDarkMode, type: TextType.secondary)),
                  ),
                )
              // Sinon, on affiche la liste !
              : ListView.separated(
                  padding: EdgeInsets.zero,
                  physics: const NeverScrollableScrollPhysics(), // Empêche de scroller cette liste à l'intérieur d'un grand ScrollView
                  shrinkWrap: true,
                  itemCount: rows.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    thickness: 1,
                    color: AppColors.getBorderColor(isDarkMode).withOpacity(0.5),
                  ),
                  itemBuilder: (context, index) {
                    final row = rows[index];
                    return _buildSwipeableRow(context, row, widths);
                  },
                ),
        ),
      ],
    );
  }

  // 🪄 FABRIQUE CHAQUE LIGNE MAGIQUE
  Widget _buildSwipeableRow(BuildContext context, SwipeableDataRow row, List<int> widths) {
    // Le widget "Dismissible" est l'outil de Flutter pour le swipe
    return Dismissible(
      key: ValueKey(row.id), // TRÈS IMPORTANT
      
      // On autorise le swipe seulement s'il y a une action de configurée
      direction: _getDismissDirection(row),
      
      // Ce qui s'affiche en fond quand on glisse vers la droite (Action de gauche)
      background: row.leftAction != null 
          ? _buildSwipeBackground(row.leftAction!, Alignment.centerLeft) 
          : const SizedBox(),
      
      // Ce qui s'affiche en fond quand on glisse vers la gauche (Action de droite)
      secondaryBackground: row.rightAction != null 
          ? _buildSwipeBackground(row.rightAction!, Alignment.centerRight) 
          : const SizedBox(),
      
      // Ce qu'il se passe quand on a swipé jusqu'au bout
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart && row.rightAction != null) {
          row.rightAction!.onTap(); // Exécute l'action de droite
        } else if (direction == DismissDirection.startToEnd && row.leftAction != null) {
          row.leftAction!.onTap(); // Exécute l'action de gauche
        }
        // Renvoie toujours "false" pour que la ligne revienne à sa place.
        // Si vous vouliez la faire disparaître avec une belle animation, il faudrait renvoyer "true", 
        // puis faire un setState() pour l'enlever de votre vraie liste de données.
        return false;
      },
      
      // L'apparence normale de la ligne
      child: InkWell(
        onTap: row.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            // On affiche le contenu de chaque cellule
            children: List.generate(row.cells.length, (index) {
              return Expanded(
                flex: widths[index],
                child: row.cells[index],
              );
            }),
          ),
        ),
      ),
    );
  }

  // Détermine dans quel(s) sens on a le droit de glisser
  DismissDirection _getDismissDirection(SwipeableDataRow row) {
    if (row.leftAction != null && row.rightAction != null) {
      return DismissDirection.horizontal; // Les deux sens !
    } else if (row.leftAction != null) {
      return DismissDirection.startToEnd; // Vers la droite
    } else if (row.rightAction != null) {
      return DismissDirection.endToStart; // Vers la gauche
    }
    return DismissDirection.none; // Bloqué
  }

  // Construit le beau carré de couleur caché avec l'icône
  Widget _buildSwipeBackground(SwipeAction action, Alignment alignment) {
    return Container(
      color: action.color,
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(action.icon, color: Colors.white),
          const SizedBox(height: 4),
          Text(
            action.label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## Étape 2 : Comment l'utiliser ? (L'Exemple Complet)

Admettons que vous vouliez afficher une liste de **notes d'élèves**. Vous voulez pouvoir "swiper" pour *Modifier* ou *Supprimer* une note. 

Voici comment construire votre tableau !

📝 **Exemple d'utilisation dans un écran :**

```dart
import 'package:flutter/material.dart';
// N'oubliez pas l'import de votre nouveau composant !
import '../widgets/swipeable_data_table.dart';
import '../config/app_colors.dart';

class MonEcranDeNotes extends StatefulWidget {
  @override
  _MonEcranDeNotesState createState() => _MonEcranDeNotesState();
}

class _MonEcranDeNotesState extends State<MonEcranDeNotes> {
  
  // Exemple de fausse donnée reçue d'une API
  final List<Map<String, dynamic>> mesNotesApi = [
    {"id": "n1", "matiere": "Mathématiques", "note": 15.5},
    {"id": "n2", "matiere": "Physique", "note": 12.0},
    {"id": "n3", "matiere": "SVT", "note": 08.5},
  ];

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // 1. On transforme nos données API en un format compréhensible par notre tableau
    // (Une liste de SwipeableDataRow)
    final List<SwipeableDataRow> lignesDuTableau = mesNotesApi.map((noteItem) {
      
      return SwipeableDataRow(
        id: noteItem['id'], // ID unique obligatoire
        
        // Ce qui s'affiche visuellement dans la ligne (Nos 2 colonnes)
        cells: [
          Text(noteItem['matiere'], style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(
            "\${noteItem['note']} / 20", 
            style: TextStyle(
              // On met en rouge si c'est sous la moyenne
              color: noteItem['note'] < 10 ? Colors.red : Colors.green,
            )
          ),
        ],
        
        // L'action quand on glisse vers la GAUCHE (Apparaît à droite)
        rightAction: SwipeAction(
          label: "Supprimer",
          icon: Icons.delete,
          color: Colors.red,
          onTap: () {
            print("Suppression de la note en \${noteItem['matiere']}");
            // Ici vous feriez un appel API et un setState pour retirer l'élément
          },
        ),

        // L'action quand on glisse vers la DROITE (Apparaît à gauche)
        leftAction: SwipeAction(
          label: "Modifier",
          icon: Icons.edit,
          color: Colors.orange,
          onTap: () {
            print("Ouverture de l'écran de modification pour \${noteItem['matiere']}");
          },
        ),
      );

    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text("Relevé de notes")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              
              // 2. ON AFFICHE LE TABLEAU MAGIQUE !
              SwipeableDataTable(
                isDarkMode: isDarkMode,
                headers: ["Matière", "Note obtenue"], // Les titres des colonnes
                rows: lignesDuTableau, // Les lignes qu'on vient de fabriquer
                flexColumnWidths: [2, 1], // ASTUCE : La matière prend 2x plus de place que la note
              ),

            ],
          ),
        ),
      ),
    );
  }
}
```

**Bravo 🎉 ! Vous avez maintenant un magnifique tableau de données moderne, clair, et plein d'interactions sans surcharger l'écran !**
