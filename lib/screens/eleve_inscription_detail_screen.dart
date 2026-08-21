import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import '../models/child.dart';
import '../widgets/components/custom_button.dart';
import '../utils/auth_guard.dart';
import 'inscription_screen.dart' as inscription;

/// Écran de confirmation affiché après avoir retrouvé un élève par matricule
/// (flux "Inscription en ligne") — montre l'ensemble des informations reçues
/// de l'API avant de lancer le wizard d'inscription.
class EleveInscriptionDetailScreen extends StatelessWidget {
  final Map<String, dynamic> eleveDetail;
  final String ecoleNom;
  final String? ecoleCode;
  final String? paramEcole;

  const EleveInscriptionDetailScreen({
    super.key,
    required this.eleveDetail,
    required this.ecoleNom,
    this.ecoleCode,
    this.paramEcole,
  });

  String _s(String key) {
    final value = eleveDetail[key];
    if (value == null) return '';
    final str = value.toString().trim();
    return str;
  }

  String _valueOr(String key, [String fallback = 'Non renseigné']) {
    final v = _s(key);
    return v.isEmpty ? fallback : v;
  }

  String get _fullName {
    final nom = _s('nom');
    final prenoms = _s('prenoms');
    final full = '$prenoms $nom'.trim();
    return full.isEmpty ? 'Élève' : full;
  }

  String get _sexeLabel {
    final sexe = _s('sexe').toUpperCase();
    if (sexe == 'M') return 'Masculin';
    if (sexe == 'F') return 'Féminin';
    return _valueOr('sexe');
  }

  String get _dateNaissanceLabel {
    final raw = _s('datenaissance');
    if (raw.isEmpty) return 'Non renseignée';
    try {
      final date = DateTime.parse(raw);
      const mois = [
        'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
        'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
      ];
      return '${date.day} ${mois[date.month - 1]} ${date.year}';
    } catch (_) {
      return raw;
    }
  }

  void _startInscription(BuildContext context) {
    final child = Child(
      id: _s('id_eleve').isNotEmpty ? _s('id_eleve') : _s('uid'),
      firstName: _valueOr('prenoms', ''),
      lastName: _valueOr('nom', ''),
      establishment: ecoleNom,
      grade: _s('branche').isNotEmpty ? _s('branche') : _s('niveau'),
      parentId: '',
      matricule: _s('matricule'),
      ecoleCode: ecoleCode,
      paramEcole: paramEcole,
    );

    AuthGuard.ensureLoggedIn(
      context,
      reason: 'Connectez-vous pour vous inscrire',
      onAuthenticated: () {
        Navigator.of(context, rootNavigator: true).push(
          MaterialPageRoute(
            builder: (context) => inscription.InscriptionWizardScreen(
              child: child,
              uid: _s('uid').isNotEmpty ? _s('uid') : null,
              eleveDetail: eleveDetail,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final photo = _s('photo');

    return Scaffold(
      backgroundColor: AppColors.screenSurfaceThemed(context),
      appBar: AppBar(
        backgroundColor: AppColors.screenSurfaceThemed(context),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(
          color: AppColors.screenTextPrimaryThemed(context),
        ),
        title: Text(
          'Élève trouvé',
          style: TextStyle(
            color: AppColors.screenTextPrimaryThemed(context),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 48,
                          backgroundColor: AppColors.screenOrange.withOpacity(0.12),
                          backgroundImage: photo.isNotEmpty ? NetworkImage(photo) : null,
                          child: photo.isEmpty
                              ? Icon(
                                  Icons.person_rounded,
                                  size: 48,
                                  color: AppColors.screenOrange,
                                )
                              : null,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          _fullName,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.screenTextPrimaryThemed(context),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          ecoleNom,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.screenTextSecondaryThemed(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  _buildSection(
                    context,
                    title: 'Scolarité',
                    icon: Icons.school_outlined,
                    rows: [
                      _InfoRow('Matricule', _valueOr('matricule')),
                      _InfoRow('Niveau', _valueOr('niveau')),
                      _InfoRow('Filière', _valueOr('filiere')),
                      _InfoRow('Branche', _valueOr('branche')),
                      _InfoRow('Statut', _valueOr('statut')),
                      _InfoRow('Redoublant', _valueOr('redoublant')),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSection(
                    context,
                    title: 'Identité',
                    icon: Icons.badge_outlined,
                    rows: [
                      _InfoRow('Sexe', _sexeLabel),
                      _InfoRow('Date de naissance', _dateNaissanceLabel),
                      _InfoRow('Lieu de naissance', _valueOr('lieun')),
                      _InfoRow('Nationalité', _valueOr('nationalite')),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSection(
                    context,
                    title: 'Contact',
                    icon: Icons.call_outlined,
                    rows: [
                      _InfoRow('Adresse', _valueOr('adresse')),
                      _InfoRow('Téléphone', _valueOr('mobile')),
                      if (_s('mobile2').isNotEmpty)
                        _InfoRow('Téléphone 2', _valueOr('mobile2')),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSection(
                    context,
                    title: 'Famille',
                    icon: Icons.family_restroom_outlined,
                    rows: [
                      _InfoRow('Père', _valueOr('pere')),
                      _InfoRow('Mère', _valueOr('mere')),
                      _InfoRow('Tuteur', _valueOr('tuteur')),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: BoxDecoration(
                color: AppColors.screenSurfaceThemed(context),
                boxShadow: [
                  BoxShadow(
                    color: (isDark ? Colors.black : Colors.black12).withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: CustomButton(
                text: 'Commencer',
                onPressed: () => _startInscription(context),
                color: AppColors.screenOrange,
                icon: Icons.arrow_forward_rounded,
                iconOnRight: true,
                height: 54,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<_InfoRow> rows,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.screenCardThemed(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.screenDividerThemed(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.screenOrange),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.screenTextPrimaryThemed(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...rows.map((row) => _buildRow(context, row)),
        ],
      ),
    );
  }

  Widget _buildRow(BuildContext context, _InfoRow row) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              row.label,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.screenTextSecondaryThemed(context),
              ),
            ),
          ),
          Expanded(
            child: Text(
              row.value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.screenTextPrimaryThemed(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);
}
