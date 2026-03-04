import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

/// Service pour gérer dynamiquement les informations de l'école
class SchoolService {
  static final SchoolService _instance = SchoolService._internal();
  factory SchoolService() => _instance;
  SchoolService._internal();

  Map<String, dynamic>? _schoolData;
  final String _schoolDataKey = 'school_data';

  /// Getters pour accéder aux informations de l'école
  int? get schoolId => _schoolData?['id'];
  String? get schoolName => _schoolData?['libelle'];
  String? get schoolPhone => _schoolData?['tel'];
  String? get schoolSignatoryName => _schoolData?['nomSignataire'];
  String? get schoolVieEcoleId => _schoolData?['identifiantVieEcole'];
  String? get schoolCode => _schoolData?['code'];

  /// Vérifie si les données de l'école sont chargées
  bool get isSchoolDataLoaded => _schoolData != null;

  /// Charge les données de l'école depuis le JSON et les met en cache
  Future<void> loadSchoolData() async {
    print('');
    print('🔄 DÉBUT DU CHARGEMENT DES DONNÉES DE L\'ÉCOLE...');
    print('');
    
    try {
      // Charger depuis le fichier JSON
      print('📂 Lecture du fichier JSON: assets/services/jsonOptimise.json');
      final String jsonString = await rootBundle.loadString('assets/services/jsonOptimise.json');
      final Map<String, dynamic> data = json.decode(jsonString);
      
      print('✅ Fichier JSON lu avec succès');
      print('📊 Structure des données: ${data.keys.toList()}');
      
      final bulletin = data['bulletin'] as Map<String, dynamic>?;
      if (bulletin != null) {
        print('📋 Bulletin trouvé: ${bulletin.keys.toList()}');
        
        final classe = bulletin['classe'] as Map<String, dynamic>?;
        if (classe != null) {
          print('🏫 Classe trouvée: ${classe.keys.toList()}');
          
          final ecole = classe['ecole'] as Map<String, dynamic>?;
          if (ecole != null) {
            _schoolData = Map<String, dynamic>.from(ecole);
            
            print('');
            print('🎉 DONNÉES DE L\'ÉCOLE EXTRAITES AVEC SUCCÈS:');
            print('   📛 Nom: ${_schoolData!['libelle']}');
            print('   🆔 ID: ${_schoolData!['id']}');
            print('   🔢 Code: ${_schoolData!['code']}');
            print('   📞 Téléphone: ${_schoolData!['tel']}');
            print('   ✍️ Signataire: ${_schoolData!['nomSignataire']}');
            print('   🏷️ ID Vie École: ${_schoolData!['identifiantVieEcole']}');
            print('');
            
            // Sauvegarder en cache pour utilisation hors ligne
            await _cacheSchoolData();
            
            print('✅ Données de l\'école chargées et mises en cache: ${schoolName}');
            return;
          } else {
            print('❌ Données de l\'école non trouvées dans la classe');
          }
        } else {
          print('❌ Classe non trouvée dans le bulletin');
        }
      } else {
        print('❌ Bulletin non trouvé dans les données JSON');
      }
      
      print('⚠️ Données de l\'école non trouvées dans le JSON');
    } catch (e) {
      print('❌ Erreur lors du chargement des données de l\'école: $e');
      print('🔄 Tentative de chargement depuis le cache...');
      // Essayer de charger depuis le cache en cas d'erreur
      await _loadCachedSchoolData();
    }
    
    print('');
    print('🏁 FIN DU CHARGEMENT DES DONNÉES DE L\'ÉCOLE');
    print('');
  }

  /// Sauvegarde les données de l'école en cache
  Future<void> _cacheSchoolData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_schoolData != null) {
        await prefs.setString(_schoolDataKey, json.encode(_schoolData));
        print('✅ Données de l\'école mises en cache');
      }
    } catch (e) {
      print('❌ Erreur lors de la mise en cache des données de l\'école: $e');
    }
  }

  /// Charge les données de l'école depuis le cache
  Future<void> _loadCachedSchoolData() async {
    print('💾 TENTATIVE DE CHARGEMENT DEPUIS LE CACHE...');
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_schoolDataKey);
      
      if (cachedData != null) {
        _schoolData = json.decode(cachedData) as Map<String, dynamic>;
        print('✅ Données de l\'école chargées depuis le cache: ${schoolName}');
        print('   📛 Nom: ${_schoolData!['libelle']}');
        print('   🔢 Code: ${_schoolData!['code']}');
      } else {
        print('❌ Aucune donnée trouvée dans le cache');
      }
    } catch (e) {
      print('❌ Erreur lors du chargement du cache des données de l\'école: $e');
    }
  }

  /// Met à jour manuellement les données de l'école
  Future<void> updateSchoolData(Map<String, dynamic> newSchoolData) async {
    _schoolData = Map<String, dynamic>.from(newSchoolData);
    await _cacheSchoolData();
    print('✅ Données de l\'école mises à jour: ${schoolName}');
  }

  /// Réinitialise les données de l'école
  Future<void> clearSchoolData() async {
    _schoolData = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_schoolDataKey);
      print('✅ Données de l\'école effacées');
    } catch (e) {
      print('❌ Erreur lors de l\'effacement des données de l\'école: $e');
    }
  }

  /// Retourne toutes les données de l'école sous forme de Map
  Map<String, dynamic>? getSchoolData() {
    return _schoolData != null ? Map<String, dynamic>.from(_schoolData!) : null;
  }

  /// Vérifie si l'école correspond à un identifiant spécifique
  bool isSchool(String vieEcoleId) {
    return schoolVieEcoleId == vieEcoleId;
  }

  /// Génère une représentation textuelle des informations de l'école
  String getSchoolInfoString() {
    if (_schoolData == null) return 'École non définie';
    
    return '''${schoolName ?? 'Nom non défini'}
ID: ${schoolId ?? 'N/A'}
Code: ${schoolCode ?? 'N/A'}
Téléphone: ${schoolPhone ?? 'N/A'}
Signataire: ${schoolSignatoryName ?? 'N/A'}
ID Vie École: ${schoolVieEcoleId ?? 'N/A'}''';
  }

  /// Pour le débogage - affiche les informations actuelles
  void debugPrintSchoolInfo() {
    print('═══════════════════════════════════════════════════════════');
    print('🏫 INFORMATIONS DE L\'ÉCOLE');
    print('═══════════════════════════════════════════════════════════');
    print(getSchoolInfoString());
    print('═══════════════════════════════════════════════════════════');
  }
}
