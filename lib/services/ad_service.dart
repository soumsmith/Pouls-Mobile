import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/ad_model.dart';

class AdService {
  static const String _apiUrl = 'https://api-africa.vie-ecoles.com/api/africa/publicites-list';

  Future<List<AdModel>> fetchAds({String? format, String? page}) async {
    final Stopwatch stopwatch = Stopwatch()..start();
    debugPrint('📢 [AdService] Appel API publicités: $_apiUrl (format: ${format ?? "tous"}, page: ${page ?? "toutes"})');
    try {
      final response = await http.get(Uri.parse(_apiUrl));
      stopwatch.stop();

      debugPrint('📡 [AdService] Statut HTTP: ${response.statusCode} (${stopwatch.elapsedMilliseconds} ms)');

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        debugPrint('📋 [AdService] ${jsonList.length} publicité(s) reçue(s) de l\'API');
        
        List<AdModel> allAds = jsonList.map((json) => AdModel.fromJson(json)).toList();
        
        // Filtrer les publicités actives
        var activeAds = allAds.where((ad) => ad.isActive).toList();

        // Filtrage par format (ex: 'paysage', 'portrait')
        if (format != null && format.trim().isNotEmpty) {
          final targetFormat = format.trim().toLowerCase();
          activeAds = activeAds.where((ad) => ad.format.trim().toLowerCase() == targetFormat).toList();
        }

        // Filtrage par page (ex: 'accueil', 'actualite')
        if (page != null && page.trim().isNotEmpty) {
          final targetPage = page.trim().toLowerCase();
          activeAds = activeAds.where((ad) => ad.page.trim().toLowerCase() == targetPage).toList();
        }

        debugPrint('✅ [AdService] ${activeAds.length} publicité(s) retenue(s) (format: ${format ?? "tous"}, page: ${page ?? "toutes"})');
        return activeAds;
      } else {
        debugPrint('❌ [AdService] Échec du chargement des pubs (Status code: ${response.statusCode}, Body: ${response.body})');
        throw Exception('Failed to load ads (Status code: ${response.statusCode})');
      }
    } catch (e, stackTrace) {
      if (stopwatch.isRunning) stopwatch.stop();
      debugPrint('❌ [AdService] Erreur lors de la récupération des publicités: $e');
      debugPrint('🔍 [AdService] StackTrace: $stackTrace');
      return [];
    }
  }
}
