import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/cart_item.dart';

class OrderService {
  static const String baseUrl = 'https://api2.vie-ecoles.com/api';
  
  Future<Map<String, dynamic>> createOrder({
    required List<CartItem> items,
    required String nom,
    required String telephone,
    required String adresse,
    String? email,
    String? ville,
    String? pays,
    required String commune,
    required String typeLivraison,
    required double prixLivraison,
    String? ecole,
    String? eleveId,
  }) async {
    print('');
    print('═══════════════════════════════════════════════════════════');
    print('� CRÉATION DE COMMANDE');
    print('═══════════════════════════════════════════════════════════');
    print('👤 Client: $nom');
    print('📞 Téléphone: $telephone');
    print('📦 Articles: ${items.length}');
    print('🏫 École: ${ecole ?? "Non spécifiée"}');
    print('🆔 Élève ID: ${eleveId ?? "Non spécifié"}');
    print('� Type livraison: $typeLivraison');
    print('💰 Prix livraison: $prixLivraison');
    
    final url = '$baseUrl/vie-ecoles/commander';
    print('🔗 URL: $url');
    
    final orderData = {
      'typeLivraison': typeLivraison,
      'commune_nom': commune,
      'prix_livraison': prixLivraison,
      'telephone': telephone,
      'eleve_id': eleveId ?? '',
      'ecole': ecole ?? 'non_defini',
      'source': 'mobile_app',
      'montantTotal': items.fold<double>(0, (sum, item) => sum + (item.product.price * item.quantity)) + prixLivraison,
      'produits': items.map((item) => {
        'produit_uid': item.product.id,
        'quantite': item.quantity,
      }).toList(),
    };

    print('� Données de la commande:');
    print('   - Montant total: ${orderData['montantTotal']}');
    print('   - Commune: ${orderData['commune_nom']}');
    print('   - Produits: ${(orderData['produits'] as List?)?.length ?? 0} article(s)');
    print('📡 Envoi de la requête POST...');

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(orderData),
      ).timeout(const Duration(seconds: 30));

      print('� Réponse reçue:');
      print('   - Status Code: ${response.statusCode}');
      print('   - Content-Type: ${response.headers['content-type']}');
      print('   - Body length: ${response.body.length} caractères');
      print('   - Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> data = json.decode(response.body);
        print('✅ Commande créée avec succès');
        print('═══════════════════════════════════════════════════════════');
        print('');
        return data;
      } else {
        print('❌ Erreur HTTP ${response.statusCode}');
        print('❌ Corps de la réponse: ${response.body}');
        print('═══════════════════════════════════════════════════════════');
        print('');
        throw Exception('Erreur HTTP: ${response.statusCode}');
      }
    } catch (e) {
      print('💥 Exception lors de la création de la commande: $e');
      print('═══════════════════════════════════════════════════════════');
      print('');
      throw Exception('Erreur lors de la création de la commande: $e');
    }
  }
}
