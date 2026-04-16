import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/gallery_image.dart';

/// Service pour la gestion des galeries d'images des écoles
class GalleryService {
  static const String _baseUrl = 'https://api2.vie-ecoles.com/api/ecoles/imagegaleries';

  /// Récupère la liste des images de la galerie pour une école
  /// 
  /// Endpoint: GET /api/ecoles/imagegaleries/{ecoleCode}
  /// Response: [
  ///   {
  ///     "image": "https://s3.eu-west-1.amazonaws.com/groupegain/galerie/1760720289_GHS Cantine.png"
  ///   },
  ///   ...
  /// ]
  static Future<List<GalleryImage>> getGalleryImages(String ecoleCode) async {
    try {
      print('=== CHARGEMENT DES IMAGES GALERIE ===');
      print('École Code: $ecoleCode');
      print('URL: $_baseUrl/$ecoleCode');
      
      final url = Uri.parse('$_baseUrl/$ecoleCode');
      final response = await http.get(url).timeout(AppConfig.API_TIMEOUT);

      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body) as List<dynamic>;
        
        final images = jsonData
            .map((json) => GalleryImage.fromJson(json as Map<String, dynamic>))
            .toList();

        print('Images récupérées avec succès: ${images.length}');
        for (final image in images) {
          print('  - ${image.id}: ${image.imageUrl}');
        }

        return images;
      } else {
        print('Erreur HTTP: ${response.statusCode}');
        throw Exception('Erreur lors du chargement des images: ${response.statusCode}');
      }
    } catch (e) {
      print('Exception dans getGalleryImages: $e');
      throw Exception('Impossible de charger les images de la galerie: $e');
    }
  }

  /// Vérifie si une URL d'image est valide
  static Future<bool> isImageUrlValid(String imageUrl) async {
    try {
      final response = await http.head(Uri.parse(imageUrl)).timeout(
        const Duration(seconds: 5),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Erreur lors de la validation de l\'image: $e');
      return false;
    }
  }

  /// Génère une miniature (placeholder) pour les images qui ne se chargent pas
  static String generatePlaceholderUrl(String originalUrl) {
    // Pour l'instant, retourne l'URL originale
    // Plus tard, on pourrait générer une vraie miniature
    return originalUrl;
  }
}
