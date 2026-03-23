import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product.dart';
import '../config/app_config.dart';

class ProduitService {
  static String get baseUrl => AppConfig.VIE_ECOLES_API_BASE_URL;

  Future<List<Product>> getProduits({
    int page = 1,
    int perPage = 10,
    String? pays,
    String? ville,
    String? quartier,
    String? nomEtablissement,
    String? nomProduit,
    String? type,
  }) async {
    print('');
    print('═══════════════════════════════════════════════════════════');
    print('🛍️ CHARGEMENT DES PRODUITS');
    print('═══════════════════════════════════════════════════════════');
    print('📄 Page: $page');
    print('📄 Per page: $perPage');
    print('🔍 Filtres:');
    if (pays != null) print('   - Pays: $pays');
    if (ville != null) print('   - Ville: $ville');
    if (quartier != null) print('   - Quartier: $quartier');
    if (nomEtablissement != null)
      print('   - Nom établissement: $nomEtablissement');
    if (nomProduit != null) print('   - Nom produit: $nomProduit');
    if (type != null) print('   - Type: $type');

    // Construction des paramètres de requête
    final Map<String, String> queryParams = {
      'page': page.toString(),
      'per_page': perPage.toString(),
    };

    if (pays != null && pays.isNotEmpty) queryParams['pays'] = pays;
    if (ville != null && ville.isNotEmpty) queryParams['ville'] = ville;
    if (quartier != null && quartier.isNotEmpty)
      queryParams['quartier'] = quartier;
    if (nomEtablissement != null && nomEtablissement.isNotEmpty)
      queryParams['nomEtablissement'] = nomEtablissement;
    if (nomProduit != null && nomProduit.isNotEmpty)
      queryParams['nomProduit'] = nomProduit;
    if (type != null && type.isNotEmpty) queryParams['type'] = type;

    final uri = Uri.parse(
      '$baseUrl/produits/list',
    ).replace(queryParameters: queryParams);
    final url = uri.toString();
    print('🔗 URL: $url');
    print('📡 Envoi de la requête...');

    try {
      final response = await http
          .get(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 30));

      print('📥 Réponse reçue:');
      print('   - Status Code: ${response.statusCode}');
      print('   - Content-Type: ${response.headers['content-type']}');
      print('   - Body length: ${response.body.length} caractères');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> productsData = data['data'] ?? [];
        print('✅ ${productsData.length} produit(s) récupéré(s)');
        print('═══════════════════════════════════════════════════════════');
        print('');

        return productsData
            .map((productData) => Product.fromApiMap(productData))
            .toList();
      } else {
        print('❌ Erreur HTTP ${response.statusCode}');
        print('❌ Corps de la réponse: ${response.body}');
        print('═══════════════════════════════════════════════════════════');
        print('');
        throw Exception('Erreur HTTP: ${response.statusCode}');
      }
    } catch (e) {
      print('💥 Exception lors de la récupération des produits: $e');
      print('═══════════════════════════════════════════════════════════');
      print('');
      throw Exception('Erreur lors de la récupération des produits: $e');
    }
  }

  Future<Product> getProduitDetail(String produitUid) async {
    print('');
    print('═══════════════════════════════════════════════════════════');
    print('📦 DÉTAILS DU PRODUIT');
    print('═══════════════════════════════════════════════════════════');
    print('🆔 UID du produit: $produitUid');

    final url = '$baseUrl/vie-ecoles/produit/detail/$produitUid';
    print('🔗 URL: $url');
    print('📡 Envoi de la requête...');

    try {
      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 30));

      print('📥 Réponse reçue:');
      print('   - Status Code: ${response.statusCode}');
      print('   - Content-Type: ${response.headers['content-type']}');
      print('   - Body length: ${response.body.length} caractères');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['status'] == true && data['data'] != null) {
          print('✅ Détails du produit récupérés avec succès');
          print('═══════════════════════════════════════════════════════════');
          print('');
          return Product.fromApiDetailMap(data['data']);
        } else {
          print('❌ Produit non trouvé ou statut invalide');
          print('❌ Status: ${data['status']}');
          print('❌ Data: ${data['data']}');
          print('═══════════════════════════════════════════════════════════');
          print('');
          throw Exception('Produit non trouvé');
        }
      } else {
        print('❌ Erreur HTTP ${response.statusCode}');
        print('❌ Corps de la réponse: ${response.body}');
        print('═══════════════════════════════════════════════════════════');
        print('');
        throw Exception('Erreur HTTP: ${response.statusCode}');
      }
    } catch (e) {
      print('💥 Exception lors de la récupération des détails du produit: $e');
      print('═══════════════════════════════════════════════════════════');
      print('');
      throw Exception(
        'Erreur lors de la récupération des détails du produit: $e',
      );
    }
  }
}
