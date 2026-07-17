import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:parents_responsable/utils/app_http.dart' as http;
import '../models/integration_condition.dart';
import '../widgets/custom_sliver_app_bar.dart';
import '../widgets/components/custom_error_state.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/app_config.dart';

class IntegrationConditionsScreen extends StatefulWidget {
  final String ecoleSigle;

  const IntegrationConditionsScreen({
    super.key,
    required this.ecoleSigle,
  });

  @override
  State<IntegrationConditionsScreen> createState() => _IntegrationConditionsScreenState();
}

class _IntegrationConditionsScreenState extends State<IntegrationConditionsScreen> {
  bool _isLoading = true;
  List<IntegrationCondition> _conditions = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchConditions();
  }

  Future<void> _fetchConditions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final url = Uri.parse(
          '${AppConfig.VIE_ECOLES_API_BASE_URL}/vie-ecoles/condition-integrations?ecole=${widget.ecoleSigle}');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == true && data['data'] != null) {
          final List<dynamic> list = data['data'];
          setState(() {
            _conditions = list.map((e) => IntegrationCondition.fromJson(e)).toList();
            _isLoading = false;
          });
        } else {
          setState(() {
            _error = "Données non disponibles.";
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _error = "Erreur serveur (${response.statusCode})";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        final errorStr = e.toString().toLowerCase();
        if (errorStr.contains('socketexception') || 
            errorStr.contains('clientexception') || 
            errorStr.contains('failed host lookup') ||
            errorStr.contains('connection refused')) {
          _error = "Impossible de se connecter au serveur. Veuillez vérifier votre connexion internet et réessayer.";
        } else {
          _error = "Une erreur est survenue. Veuillez réessayer ultérieurement.";
        }
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      body: CustomScrollView(
        slivers: [
          CustomSliverAppBar(
            title: 'Conditions d\'intégration',
            isDark: isDark,
          ),
          if (_isLoading)
            SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            )
          else if (_error != null)
            SliverFillRemaining(
              child: CustomErrorState(
                title: 'Erreur',
                message: _error!,
                icon: Icons.error_outline,
                retryText: 'Réessayer',
                onRetry: _fetchConditions,
              ),
            )
          else if (_conditions.isEmpty)
            SliverFillRemaining(
              child: CustomErrorState(
                title: 'Aucune condition',
                message: 'Aucune condition d\'intégration disponible pour cette école.',
                icon: Icons.info_outline,
                retryText: 'Retour',
                onRetry: () => Navigator.pop(context),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(16.0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final condition = _conditions[index];
                    return _buildConditionCard(condition, isDark);
                  },
                  childCount: _conditions.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildConditionCard(IntegrationCondition condition, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (condition.backgroundImage.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              child: CachedNetworkImage(
                imageUrl: condition.backgroundImage,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: 180,
                  color: Colors.grey.withOpacity(0.1),
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 180,
                  color: Colors.grey.withOpacity(0.1),
                  child: const Icon(Icons.image_not_supported),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  condition.nom,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  condition.description,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
