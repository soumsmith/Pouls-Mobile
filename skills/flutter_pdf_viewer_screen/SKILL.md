---
name: flutter-pdf-viewer-screen
description: Guide étape par étape pour intégrer un visualiseur de PDF robuste (via URL, local, assets) connecté à une API dans Flutter.
---

# 🚀 Guide d'intégration : Écran de Visualisation PDF

Ce guide vous accompagne de A à Z pour intégrer un lecteur PDF performant dans votre application Flutter. Même si vous êtes débutant (ou "nul" en code 😉), il vous suffit de suivre ces étapes dans l'ordre !

Ce lecteur corrige les problèmes fréquents :
- Il ne **clignote pas** lorsque l'on change de page.
- Il détecte tout seul s'il lit un fichier local, une ressource (`assets`) ou un lien internet (`http`).
- Il inclut un bouton pour partager/télécharger le PDF.

---

## Étape 1 : Ajouter les dépendances

Pour commencer, nous avons besoin de trois paquets externes. Ouvrez votre fichier `pubspec.yaml` (à la racine de votre projet) et ajoutez ces lignes sous `dependencies:` :

```yaml
dependencies:
  flutter:
    sdk: flutter
  # ... vos autres dépendances ...
  share_plus: ^7.2.2
  syncfusion_flutter_pdfviewer: ^27.1.48
  syncfusion_flutter_core: ^27.1.48
```
*N'oubliez pas d'exécuter `flutter pub get` dans votre terminal après avoir sauvegardé.*

---

## Étape 2 : Créer le Modèle de Données (Le Model)

Nous allons créer une classe qui va représenter notre document PDF tel qu'il nous est envoyé par le serveur (l'API).

📁 **Créez le fichier :** `lib/models/pdf_document_model.dart`  
📝 **Copiez-collez ce code :**

```dart
class PdfDocumentModel {
  final String id;
  final String title;
  final String url;

  PdfDocumentModel({
    required this.id,
    required this.title,
    required this.url,
  });

  // Cette méthode prend les données brutes (JSON) de l'API et les transforme en un objet Dart facile à manipuler.
  factory PdfDocumentModel.fromJson(Map<String, dynamic> json) {
    return PdfDocumentModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? 'Document sans titre',
      url: json['url'] ?? '',
    );
  }
}
```

---

## Étape 3 : Créer le Service (L'Appel API)

Maintenant, nous devons créer une fonction qui va interroger notre serveur internet pour récupérer les informations du PDF.

📁 **Créez le fichier :** `lib/services/pdf_service.dart`  
📝 **Copiez-collez ce code :**

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/pdf_document_model.dart'; // Importez le modèle créé à l'étape 2

class PdfService {
  // Remplacez par l'URL de votre propre API
  static const String baseUrl = 'https://votre-api.com/api';

  // Fonction pour récupérer les détails du PDF via son ID
  Future<PdfDocumentModel?> fetchPdfDetails(String documentId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/documents/$documentId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          // Décommentez et ajoutez votre token si l'API est sécurisée :
          // 'Authorization': 'Bearer VOTRE_TOKEN', 
        },
      );

      // Si le serveur répond avec un code 200 (Succès)
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Transforme la réponse JSON en un bel objet PdfDocumentModel
        return PdfDocumentModel.fromJson(data['data'] ?? data);
      } else {
        throw Exception('Erreur serveur: ${response.statusCode}');
      }
    } catch (e) {
      print('Erreur lors de la récupération du PDF: $e');
      return null;
    }
  }
}
```

---

## Étape 4 : Créer l'Écran Visuel (L'Interface Utilisateur)

C'est ici qu'est la magie ! Nous allons créer l'écran qui affiche réellement le PDF à l'utilisateur.
*Note : Le code contient en commentaire vos composants personnalisés (ex: `AppColors`, `CustomSliverAppBar`). Vous pourrez les décommenter plus tard quand vous voudrez personnaliser le design !*

📁 **Créez le fichier :** `lib/screens/pdf_viewer_screen.dart`  
📝 **Copiez-collez ce code :**

```dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:syncfusion_flutter_core/theme.dart';

// ------------------------------------------------------------------
// ASTUCE : Décommentez ces lignes si vous utilisez vos propres couleurs et widgets !
// import '../config/app_colors.dart';
// import '../widgets/custom_sliver_app_bar.dart';
// import '../widgets/custom_loader.dart';
// ------------------------------------------------------------------

class PDFViewerScreen extends StatefulWidget {
  // Le lien vers le document (Internet, local, ou assets)
  final String pdfUrl; 
  // Le titre affiché en haut de l'écran
  final String title;

  const PDFViewerScreen({super.key, required this.pdfUrl, required this.title});

  @override
  State<PDFViewerScreen> createState() => _PDFViewerScreenState();
}

class _PDFViewerScreenState extends State<PDFViewerScreen> {
  // Indique à l'écran s'il faut afficher la roue de chargement
  bool isLoading = true;
  // Stocke le texte de l'erreur en cas de problème
  String? errorMessage;
  // Nombre total de pages du document
  int totalPages = 0;
  
  // Cette "clé" permet de contrôler le lecteur PDF en arrière-plan
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();

  // Ce "notifier" sert à afficher le numéro de la page en direct sans faire clignoter tout l'écran !
  late final ValueNotifier<int> _pageNotifier = ValueNotifier(0);

  // ⚠️ TRÈS IMPORTANT : Le widget PDF est préparé UNE SEULE FOIS ici ("late final").
  // C'est le secret pour que l'écran soit ultra fluide et ne recharge pas au scroll !
  late final Widget _pdfWidget = widget.pdfUrl.startsWith('assets/')
      // Si l'URL commence par "assets/", on le lit depuis l'application
      ? SfPdfViewer.asset(
          widget.pdfUrl,
          key: _pdfViewerKey,
          onDocumentLoaded: _onDocumentLoaded,
          onDocumentLoadFailed: _onDocumentLoadFailed,
          onPageChanged: _onPageChanged,
          canShowScrollHead: true,
          canShowScrollStatus: true,
          enableDoubleTapZooming: true,
          pageLayoutMode: PdfPageLayoutMode.continuous,
        )
      // Si l'URL commence par "http", on le télécharge depuis internet
      : widget.pdfUrl.startsWith('http')
          ? SfPdfViewer.network(
              widget.pdfUrl,
              key: _pdfViewerKey,
              onDocumentLoaded: _onDocumentLoaded,
              onDocumentLoadFailed: _onDocumentLoadFailed,
              onPageChanged: _onPageChanged,
              canShowScrollHead: true,
              canShowScrollStatus: true,
              enableDoubleTapZooming: true,
              pageLayoutMode: PdfPageLayoutMode.continuous,
            )
          // Sinon, c'est un fichier stocké physiquement dans le téléphone
          : SfPdfViewer.file(
              File(widget.pdfUrl),
              key: _pdfViewerKey,
              onDocumentLoaded: _onDocumentLoaded,
              onDocumentLoadFailed: _onDocumentLoadFailed,
              onPageChanged: _onPageChanged,
              canShowScrollHead: true,
              canShowScrollStatus: true,
              enableDoubleTapZooming: true,
              pageLayoutMode: PdfPageLayoutMode.continuous,
            );

  // Fonction appelée quand le PDF a fini de se charger avec succès
  void _onDocumentLoaded(PdfDocumentLoadedDetails details) {
    if (!mounted) return;
    setState(() {
      totalPages = details.document.pages.count;
      isLoading = false; // On cache le cercle de chargement
    });
  }

  // Fonction appelée s'il y a un problème réseau ou si le fichier n'existe pas
  void _onDocumentLoadFailed(PdfDocumentLoadFailedDetails details) {
    if (!mounted) return;
    setState(() {
      errorMessage = details.description; 
      isLoading = false;
    });
  }

  // Fonction appelée chaque fois qu'on change de page en scrollant vers le bas
  void _onPageChanged(PdfPageChangedDetails details) {
    // Met à jour le numéro de page sans rafraîchir tout l'écran
    _pageNotifier.value = details.newPageNumber;
  }

  @override
  void dispose() {
    _pageNotifier.dispose(); // On nettoie la mémoire quand on quitte l'écran
    super.dispose();
  }

  // Ce bouton permet de partager le document à un ami
  void _downloadPdf() async {
    // Si c'est un fichier local physique
    if (!widget.pdfUrl.startsWith('http') && !widget.pdfUrl.startsWith('assets/')) {
      final file = File(widget.pdfUrl);
      if (await file.exists()) {
        await Share.shareXFiles([XFile(file.path)], text: widget.title);
      }
    } else {
      // Si c'est un lien internet
      Share.share(widget.pdfUrl, subject: widget.title);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ASTUCE : Utilisez "AppColors.screenBg(context)" pour la couleur de fond
      backgroundColor: Colors.white, 
      
      // La barre supérieure (App Bar)
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.white, // ASTUCE : AppColors.screenBg(context)
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined, color: Colors.black),
            onPressed: _downloadPdf,
            tooltip: 'Partager',
          ),
          const SizedBox(width: 8),
        ],
      ),
      
      // ASTUCE : Si vous préférez un CustomScrollView avec votre CustomSliverAppBar :
      // body: CustomScrollView( slivers: [ CustomSliverAppBar(...), SliverFillRemaining(...) ] ),
      
      body: Container(
        color: Colors.white, // ASTUCE : AppColors.screenBg(context)
        // S'il y a une erreur on affiche le message rouge, sinon on affiche le PDF
        child: errorMessage != null
            ? _buildErrorState()
            : Stack(
                children: [
                  // 1. Le lecteur PDF au fond
                  SfPdfViewerTheme(
                    data: SfPdfViewerThemeData(
                      backgroundColor: Colors.white, // ASTUCE : AppColors.screenBg(context)
                    ),
                    child: _pdfWidget,
                  ),

                  // 2. Le cercle de chargement par-dessus tant que ça charge
                  if (isLoading)
                    Container(
                      color: Colors.white, // ASTUCE : AppColors.screenBg(context)
                      child: const Center(
                        // ASTUCE : Remplacez par CustomLoader() si vous en avez un !
                        child: CircularProgressIndicator(color: Colors.orange), // ASTUCE : AppColors.screenOrange
                      ),
                    ),

                  // 3. Le petit badge du numéro de page en bas à droite
                  if (!isLoading && totalPages > 0)
                    Positioned(
                      bottom: 16,
                      right: 16,
                      child: ValueListenableBuilder<int>(
                        valueListenable: _pageNotifier,
                        builder: (context, page, _) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              // Affiche la page actuelle (page + 1) sur le total
                              '${page + 1} / $totalPages',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
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
  }

  // Le design affiché si le fichier n'a pas pu être chargé (ex: Pas d'internet)
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 80, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Erreur de chargement',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage ?? 'Impossible de charger le fichier PDF',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(), // Permet de quitter l'écran
              // ASTUCE : Utilisez AppColors.screenOrange
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text('Retour', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## Étape 5 : L'utiliser ! (Ouvrir un PDF)

Vous pouvez maintenant utiliser ce lecteur depuis n'importe où dans votre application !
Ajoutez ce code à un bouton (ou à l'ouverture d'un écran) pour qu'il télécharge le document depuis l'API puis l'affiche.

📝 **Exemple d'utilisation dans un autre écran :**

```dart
import 'package:flutter/material.dart';
import '../services/pdf_service.dart';
import '../screens/pdf_viewer_screen.dart';

// Fonction magique à appeler lors du clic sur le bouton "Ouvrir PDF"
void _openMyDocument(BuildContext context, String documentId) async {
  
  // 1. On affiche un petit message pendant qu'on parle au serveur (API)
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Préparation du document...')),
  );

  // 2. On appelle notre Service créé à l'Étape 3
  final pdfService = PdfService();
  final document = await pdfService.fetchPdfDetails(documentId);

  // 3. Si l'API nous a renvoyé le document
  if (document != null && document.url.isNotEmpty) {
    // On l'ouvre dans notre bel écran (Étape 4) !
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PDFViewerScreen(
          pdfUrl: document.url,
          title: document.title,
        ),
      ),
    );
  } else {
    // 4. Si la requête échoue, on prévient l'utilisateur
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Impossible de récupérer le document.')),
    );
  }
}
```

**Bravo 🎉 ! Vous venez d'intégrer un visualiseur de PDF complet, robuste et connecté à une API !**
