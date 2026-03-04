import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product.dart';

class ProduitService {
  static const String baseUrl = 'https://api2.vie-ecoles.com/api';
  
  Future<List<Product>> getProduits({int page = 1}) async {
    print('');
    print('═══════════════════════════════════════════════════════════');
    print('🛍️ CHARGEMENT DES PRODUITS');
    print('═══════════════════════════════════════════════════════════');
    print('📄 Page: $page');
    
    final url = '$baseUrl/produits/list?page=$page';
    print('🔗 URL: $url');
    print('📡 Envoi de la requête...');
    
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

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
        
        return productsData.map((productData) => Product.fromApiMap(productData)).toList();
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
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

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
      throw Exception('Erreur lors de la récupération des détails du produit: $e');
    }
  }
}
