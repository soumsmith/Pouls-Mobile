import 'package:flutter/material.dart';
import 'package:parents_responsable/config/app_colors.dart';
import '../models/child.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../widgets/custom_loader.dart';

// ─── MODÈLES POUR INSCRIPTION ────────────────────────────────────────────────────────
class Service {
  final String iddetail;
  final String service;
  final String? zoneId;
  final String designation;
  final String description;
  final int prix;
  final int prix2;
  final String? createdAt;
  final String? updatedAt;
  final String maitre;
  bool selectionnee;

  Service({
    required this.iddetail,
    required this.service,
    this.zoneId,
    required this.designation,
    required this.description,
    required this.prix,
    required this.prix2,
    this.createdAt,
    this.updatedAt,
    required this.maitre,
    this.selectionnee = false,
  });

  Echeance toEcheance() {
    return Echeance(
      echId: DateTime.now().millisecondsSinceEpoch,
      uid: iddetail,
      branche: "*",
      statut: "*",
      rubrique: service,
      pecheance: iddetail,
      montant: prix,
      montant2: prix2,
      dateLimite: DateTime.now().add(const Duration(days: 30)).toString().split(' ')[0], // Date par défaut
      libelle: designation,
      ordre: 0,
      rubriqueObligatoire: 1,
    );
  }

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      iddetail: json['iddetail'],
      service: json['service'],
      zoneId: json['zone_id'],
      designation: json['designation'],
      description: json['description'],
      prix: json['prix'],
      prix2: json['prix2'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      maitre: json['maitre'],
    );
  }
}

class Echeance {
  final int echId;
  final String uid;
  final String branche;
  final String statut;
  final String rubrique;
  final String pecheance;
  final int montant;
  final int montant2;
  final String dateLimite;
  final String libelle;
  final int ordre;
  final int rubriqueObligatoire;
  bool selectionnee;

  Echeance({
    required this.echId,
    required this.uid,
    required this.branche,
    required this.statut,
    required this.rubrique,
    required this.pecheance,
    required this.montant,
    required this.montant2,
    required this.dateLimite,
    required this.libelle,
    required this.ordre,
    required this.rubriqueObligatoire,
    this.selectionnee = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'ech_id': echId,
      'uid': uid,
      'branche': branche,
      'statut': statut,
      'rubrique': rubrique,
      'pecheance': pecheance,
      'montant': montant,
      'montant2': montant2,
      'datelimite': dateLimite,
      'libelle': libelle,
      'ordre': ordre,
      'rubrique_obligatoire': rubriqueObligatoire,
    };
  }

  factory Echeance.fromJson(Map<String, dynamic> json) {
    return Echeance(
      echId: json['ech_id'],
      uid: json['uid'],
      branche: json['branche'],
      statut: json['statut'],
      rubrique: json['rubrique'],
      pecheance: json['pecheance'],
      montant: json['montant'],
      montant2: json['montant2'],
      dateLimite: json['datelimite'],
      libelle: json['libelle'],
      ordre: json['ordre'],
      rubriqueObligatoire: json['rubrique_obligatoire'],
    );
  }
}

class InscriptionItem {
  final String id;
  final String service;
  final int montant;
  final bool reservation;
  final List<Echeance> echeancesSelectionnees;

  InscriptionItem({
    required this.id,
    required this.service,
    required this.montant,
    required this.reservation,
    required this.echeancesSelectionnees,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'service': service,
      'montant': montant,
      'reservation': reservation,
      'echeances_selectionnees': echeancesSelectionnees.map((e) => e.toJson()).toList(),
    };
  }
}

class InscriptionRequest {
  final List<InscriptionItem> ids;
  final Map<String, dynamic> engagement;
  final String type;
  final int separationFlux;
  final int systemeEducatif;

  InscriptionRequest({
    required this.ids,
    required this.engagement,
    required this.type,
    required this.separationFlux,
    required this.systemeEducatif,
  });

  Map<String, dynamic> toJson() {
    return {
      'ids': ids.map((item) => item.toJson()).toList(),
      'engagement': engagement,
      'type': type,
      'separation_flux': separationFlux,
      'systeme_educatif': systemeEducatif,
    };
  }
}

class InscriptionScreen extends StatefulWidget {
  final Child child;

  const InscriptionScreen({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  _InscriptionScreenState createState() => _InscriptionScreenState();
}

class _InscriptionScreenState extends State<InscriptionScreen> {
  // Controllers pour les champs du formulaire
  final TextEditingController brancheController = TextEditingController();
  final TextEditingController libelleController = TextEditingController();
  final TextEditingController montantController = TextEditingController();
  final TextEditingController montant2Controller = TextEditingController();
  final TextEditingController dateLimiteController = TextEditingController();
  final TextEditingController rubriqueController = TextEditingController();
  final TextEditingController statutController = TextEditingController();
  
  String selectedRubrique = 'INS'; // Valeur par défaut
  bool isObligatoire = true;
  bool isLoading = false;
  bool isLoadingServices = true;

  // Liste des échéances saisies par l'utilisateur
  List<Echeance> echeancesSaisies = [];
  List<Service> servicesDisponibles = [];
  String? matricule;
  String? ecoleCode;

  @override
  void initState() {
    super.initState();
    _loadServices();
    _loadChildInfo();
  }

  void _loadChildInfo() {
    // Récupérer le matricule et le code école depuis les infos de l'enfant
    setState(() {
      matricule = widget.child.matricule ?? "10307";
      ecoleCode = "gainhs";
    });
  }

  Future<void> _loadServices() async {
    try {
      final String url = "https://api2.vie-ecoles.com/api/preinscription/services?ecole=$ecoleCode";

      print('🔄 Chargement des services...');
      print('   URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print('📡 Réponse de l\'API:');
      print('   Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);
        final services = jsonData.map((json) => Service.fromJson(json)).toList();
        
        print('✅ Services chargés: ${services.length} items');
        for (var service in services) {
          print('   - ${service.designation} (${service.service}): ${service.prix} FCFA');
        }
        
        setState(() {
          servicesDisponibles = services;
          isLoadingServices = false;
        });
      } else {
        print('❌ Erreur HTTP ${response.statusCode}: ${response.body}');
        setState(() {
          isLoadingServices = false;
        });
      }
    } catch (e) {
      print('❌ Erreur lors du chargement des services: $e');
      setState(() {
        isLoadingServices = false;
      });
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  Future<void> _effectuerInscription() async {
    // Filtrer les échéances sélectionnées
    final echeancesSelectionnees = echeancesSaisies;
    
    if (echeancesSelectionnees.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner au moins une échéance'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // Créer la requête d'inscription
      final inscriptionRequest = InscriptionRequest(
        ids: [
          InscriptionItem(
            id: "SCO",
            service: "Scolarité",
            montant: echeancesSelectionnees.fold(0, (sum, e) => sum + e.montant),
            reservation: false,
            echeancesSelectionnees: echeancesSelectionnees,
          ),
        ],
        engagement: {},
        type: "préinscription",
        separationFlux: 0,
        systemeEducatif: 1,
      );

      // URL de l'API
      final String url = "https://api2.vie-ecoles.com/api/vie-ecoles/inscription-eleve/$matricule?ecole=$ecoleCode";

      print('🔄 Envoi de la requête d\'inscription...');
      print('   URL: $url');
      print('   Matricule: $matricule');
      print('   École: $ecoleCode');
      print('   Données: ${jsonEncode(inscriptionRequest.toJson())}');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(inscriptionRequest.toJson()),
      );

      print('📡 Réponse de l\'API:');
      print('   Status Code: ${response.statusCode}');
      print('   Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Inscription de ${widget.child.firstName} enregistrée avec succès!'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } else {
        // Gérer les erreurs de l'API
        String errorMessage = 'Erreur lors de l\'inscription';
        try {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData['message'] ?? errorData['error'] ?? errorMessage;
        } catch (e) {
          errorMessage = 'Erreur HTTP ${response.statusCode}: ${response.body}';
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Erreur lors de l\'inscription: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur réseau: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Widget _buildModernInscriptionButton({
    required String label,
    required VoidCallback? onTap,
    required bool isLoading,
  }) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: onTap != null 
              ? [const Color(0xFF3B82F6), const Color(0xFF60A5FA)]
              : [Colors.grey.shade400, Colors.grey.shade400],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          if (onTap != null)
            BoxShadow(
              color: const Color(0xFF3B82F6).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Calculer le montant total
    int montantTotal = echeancesSaisies
        .fold(0, (sum, e) => sum + e.montant);

    return Scaffold(
      //backgroundColor: AppColors.screenBackground,
      appBar: AppBar(
        backgroundColor: AppColors.screenCard,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.screenTextPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Nouvelle Inscription',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.screenTextPrimary,
            letterSpacing: -0.4,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.screenCard,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.screenShadow,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [const Color(0xFF3B82F6), const Color(0xFF60A5FA)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.app_registration,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Inscription pour ${widget.child.firstName}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.screenTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Ajoutez les frais d\'inscription pour l\'année scolaire',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.screenTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Services disponibles
            if (isLoadingServices) ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Column(
                    children: [
                      CircularProgressIndicator(color: Color(0xFF3B82F6)),
                      SizedBox(height: 16),
                      Text(
                        'Chargement des services...',
                        style: TextStyle(
                          color: AppColors.screenTextSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else if (servicesDisponibles.isNotEmpty) ...[
              // Header des services
              Row(
                children: [
                  const Text(
                    'Services disponibles',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.screenTextPrimary,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.3)),
                    ),
                    child: Text(
                      '${servicesDisponibles.where((s) => s.selectionnee).length} sélectionné(s)',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF3B82F6),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Filtre par type de service
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.screenSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.screenDivider),
                ),
                child: DropdownButton<String>(
                  value: 'Tous',
                  isExpanded: true,
                  underline: Container(),
                  items: const [
                    DropdownMenuItem(value: 'Tous', child: Text('Tous les services')),
                    DropdownMenuItem(value: 'CANTINE', child: Text('CANTINE')),
                    DropdownMenuItem(value: 'TRANS', child: Text('TRANSPORT')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      // Filtrer les services si nécessaire
                    });
                  },
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Liste des services
              ...servicesDisponibles.asMap().entries.map((entry) {
                final index = entry.key;
                final service = entry.value;
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppColors.screenSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: service.selectionnee 
                          ? const Color(0xFF3B82F6).withOpacity(0.3)
                          : AppColors.screenDivider,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // Checkbox
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              service.selectionnee = !service.selectionnee;
                            });
                          },
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: service.selectionnee 
                                  ? const Color(0xFF3B82F6)
                                  : Colors.transparent,
                              border: Border.all(
                                color: service.selectionnee 
                                    ? const Color(0xFF3B82F6)
                                    : AppColors.screenDivider,
                                width: 2,
                              ),
                            ),
                            child: service.selectionnee
                                ? const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 16,
                                  )
                                : null,
                          ),
                        ),
                        
                        const SizedBox(width: 12),
                        
                        // Contenu
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                service.designation,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.screenTextPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: service.service == 'CANTINE' 
                                          ? Colors.orange.withOpacity(0.1)
                                          : Colors.blue.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      service.service,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: service.service == 'CANTINE' 
                                            ? Colors.orange
                                            : Colors.blue,
                                      ),
                                    ),
                                  ),
                                  if (service.zoneId != null && service.zoneId!.isNotEmpty) ...[
                                    const SizedBox(width: 8),
                                    Icon(
                                      Icons.location_on,
                                      size: 12,
                                      color: AppColors.screenTextSecondary,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      'Zone: ${service.zoneId}',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: AppColors.screenTextSecondary,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        // Montant
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${service.prix} FCFA',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF3B82F6),
                              ),
                            ),
                            if (service.prix2 != service.prix)
                              Text(
                                '(${service.prix2} FCFA)',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.screenTextSecondary,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
              
              // Bouton pour ajouter les services sélectionnés
              if (servicesDisponibles.any((s) => s.selectionnee)) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        // Ajouter les services sélectionnés à la liste des échéances
                        for (var service in servicesDisponibles.where((s) => s.selectionnee)) {
                          echeancesSaisies.add(service.toEcheance());
                          service.selectionnee = false; // Désélectionner après ajout
                        }
                      });
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${echeancesSaisies.length} échéance(s) ajoutée(s)'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Ajouter les services sélectionnés',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
              
              const SizedBox(height: 24),
            ] else if (!isLoadingServices) ...[
              // Message si aucun service
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.screenSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.screenDivider),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.orange.withOpacity(0.7),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Aucun service disponible',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Utilisez le formulaire manuel ci-dessous',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.screenTextSecondary.withOpacity(0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
            ],
            
            // Séparateur
            if (servicesDisponibles.isNotEmpty || !isLoadingServices) ...[
              Container(
                height: 1,
                color: AppColors.screenDivider,
                margin: const EdgeInsets.symmetric(vertical: 24),
              ),
              
              // Titre du formulaire manuel
              const Text(
                'Ou ajouter manuellement',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.screenTextPrimary,
                ),
              ),
              
              const SizedBox(height: 16),
            ],
            
            // Formulaire d'ajout d'échéance
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.screenSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.screenDivider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ajouter une échéance manuellement',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.screenTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Libellé
                  const Text(
                    'Libellé',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.screenTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.screenCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.screenDivider),
                    ),
                    child: TextField(
                      controller: libelleController,
                      decoration: InputDecoration(
                        hintText: 'Ex: Frais d\'inscription',
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(12),
                      ),
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.screenTextPrimary,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Branche
                  const Text(
                    'Branche',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.screenTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.screenCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.screenDivider),
                    ),
                    child: TextField(
                      controller: brancheController,
                      decoration: InputDecoration(
                        hintText: 'Ex: 6EME EX',
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(12),
                      ),
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.screenTextPrimary,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Montants
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Montant (FCFA)',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.screenTextSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: AppColors.screenCard,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.screenDivider),
                              ),
                              child: TextField(
                                controller: montantController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  hintText: '50',
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.all(12),
                                ),
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.screenTextPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Montant 2 (FCFA)',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.screenTextSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: AppColors.screenCard,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.screenDivider),
                              ),
                              child: TextField(
                                controller: montant2Controller,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  hintText: '50',
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.all(12),
                                ),
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.screenTextPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Date limite
                  const Text(
                    'Date limite',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.screenTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.screenCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.screenDivider),
                    ),
                    child: TextField(
                      controller: dateLimiteController,
                      decoration: InputDecoration(
                        hintText: 'YYYY-MM-DD (Ex: 2025-08-05)',
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(12),
                      ),
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.screenTextPrimary,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Rubrique et obligatoire
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Rubrique',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.screenTextSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: AppColors.screenCard,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.screenDivider),
                              ),
                              child: DropdownButton<String>(
                                value: selectedRubrique,
                                isExpanded: true,
                                underline: Container(),
                                items: const [
                                  DropdownMenuItem(value: 'INS', child: Text('INS - Inscription')),
                                  DropdownMenuItem(value: 'ANX', child: Text('ANX - Annexes')),
                                  DropdownMenuItem(value: 'SCOL', child: Text('SCOL - Scolarité')),
                                  DropdownMenuItem(value: 'MAT', child: Text('MAT - Matériel')),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    selectedRubrique = value!;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Statut',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.screenTextSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: AppColors.screenCard,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.screenDivider),
                              ),
                              child: DropdownButton<String>(
                                value: statutController.text.isEmpty ? '*' : statutController.text,
                                isExpanded: true,
                                underline: Container(),
                                items: const [
                                  DropdownMenuItem(value: '*', child: Text('* - Tous')),
                                  DropdownMenuItem(value: 'PAY', child: Text('PAY - Payé')),
                                  DropdownMenuItem(value: 'IMP', child: Text('IMP - Impayé')),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    statutController.text = value!;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Checkbox obligatoire
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            isObligatoire = !isObligatoire;
                          });
                        },
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isObligatoire 
                                ? const Color(0xFF3B82F6)
                                : Colors.transparent,
                            border: Border.all(
                              color: isObligatoire 
                                  ? const Color(0xFF3B82F6)
                                  : AppColors.screenDivider,
                              width: 2,
                            ),
                          ),
                          child: isObligatoire
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 16,
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Frais obligatoire',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.screenTextPrimary,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Bouton d'ajout manuel
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (libelleController.text.isEmpty ||
                            brancheController.text.isEmpty ||
                            montantController.text.isEmpty ||
                            dateLimiteController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Veuillez remplir les champs obligatoires'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }
                        
                        final nouvelleEcheance = Echeance(
                          echId: DateTime.now().millisecondsSinceEpoch,
                          uid: DateTime.now().millisecondsSinceEpoch.toString(),
                          branche: brancheController.text,
                          statut: statutController.text.isEmpty ? '*' : statutController.text,
                          rubrique: selectedRubrique,
                          pecheance: DateTime.now().millisecondsSinceEpoch.toString(),
                          montant: int.tryParse(montantController.text) ?? 0,
                          montant2: int.tryParse(montant2Controller.text) ?? int.tryParse(montantController.text) ?? 0,
                          dateLimite: dateLimiteController.text,
                          libelle: libelleController.text,
                          ordre: echeancesSaisies.length,
                          rubriqueObligatoire: isObligatoire ? 1 : 0,
                        );
                        
                        setState(() {
                          echeancesSaisies.add(nouvelleEcheance);
                          // Vider les champs
                          libelleController.clear();
                          brancheController.clear();
                          montantController.clear();
                          montant2Controller.clear();
                          dateLimiteController.clear();
                          statutController.clear();
                        });
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Échéance ajoutée manuellement'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Ajouter manuellement',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Liste des échéances ajoutées
            if (echeancesSaisies.isNotEmpty) ...[
              Row(
                children: [
                  const Text(
                    'Échéances ajoutées',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.screenTextPrimary,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.3)),
                    ),
                    child: Text(
                      'Total: $montantTotal FCFA',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF3B82F6),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              ...echeancesSaisies.asMap().entries.map((entry) {
                final index = entry.key;
                final echeance = entry.value;
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppColors.screenSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF3B82F6).withOpacity(0.3),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // Contenu
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                echeance.libelle,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.screenTextPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    size: 14,
                                    color: AppColors.screenTextSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Limite: ${_formatDate(echeance.dateLimite)}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.screenTextSecondary,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: echeance.rubriqueObligatoire == 1 
                                          ? Colors.red.withOpacity(0.1)
                                          : Colors.green.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      echeance.rubriqueObligatoire == 1 ? 'Obligatoire' : 'Optionnel',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: echeance.rubriqueObligatoire == 1 
                                            ? Colors.red
                                            : Colors.green,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        // Montant et bouton supprimer
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${echeance.montant} FCFA',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF3B82F6),
                              ),
                            ),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  echeancesSaisies.removeAt(index);
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(
                                  Icons.delete_outline,
                                  size: 16,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
              
              const SizedBox(height: 24),
              
              // Bouton de soumission
              _buildModernInscriptionButton(
                label: isLoading ? '' : 'Confirmer l\'inscription',
                onTap: isLoading ? null : _effectuerInscription,
                isLoading: isLoading,
              ),
            ] else
              // Message si aucune échéance
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.screenSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.screenDivider),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 48,
                      color: AppColors.screenTextSecondary.withOpacity(0.5),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Aucune échéance ajoutée',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.screenTextSecondary.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ajoutez des frais d\'inscription pour continuer',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.screenTextSecondary.withOpacity(0.6),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            
            const SizedBox(height: 24),
            
            // Message informatif
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: const Color(0xFF3B82F6), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'L\'inscription sera confirmée après validation par l\'administration et paiement des frais sélectionnés.',
                      style: TextStyle(
                        fontSize: 12,
                        color: const Color(0xFF3B82F6),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
