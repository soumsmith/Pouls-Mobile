import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/auth_service.dart';
import '../services/mock_api_service.dart';
import '../models/child.dart';
import '../config/app_colors.dart';
import '../config/app_dimensions.dart';
import '../widgets/custom_sliver_app_bar.dart';
import '../widgets/bottom_sheets/rating_bottom_sheet.dart';
import '../services/avis_service.dart';

class RatingChildrenListScreen extends StatefulWidget {
  final Color actionColor;
  final String? imagePath;

  const RatingChildrenListScreen({
    super.key,
    required this.actionColor,
    this.imagePath,
  });

  @override
  State<RatingChildrenListScreen> createState() => _RatingChildrenListScreenState();
}

class _RatingChildrenListScreenState extends State<RatingChildrenListScreen> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _schools = [];
  bool _isLoading = true;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();

    _loadChildren();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadChildren() async {
    try {
      final user = AuthService.instance.getCurrentUser();
      final parentId = user?.id ?? 'parent1';
      final apiService = MockApiService();
      final children = await apiService.getChildrenForParent(parentId);
      if (!mounted) return;
      // Grouper par école pour enlever les doublons
      final Map<String, Map<String, dynamic>> uniqueSchools = {};
      for (final child in children) {
        // Fallback: si pas de code, utiliser le nom de l'établissement comme clé
        final schoolId = child.ecoleCode ?? child.paramEcole ?? child.establishment;
        final schoolName = child.establishment;
        
        if (!uniqueSchools.containsKey(schoolId)) {
          uniqueSchools[schoolId] = {
            'schoolId': schoolId,
            'schoolName': schoolName,
            'children': [child],
          };
        } else {
          uniqueSchools[schoolId]!['children'].add(child);
        }
      }

      setState(() {
        _schools = uniqueSchools.values.toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onSchoolTapped(String schoolId, String schoolName) {
    showRatingBottomSheet(
      context,
      schoolId: schoolId,
      schoolName: schoolName,
      schoolColor: widget.actionColor,
      imagePath: widget.imagePath,
      imageBackgroundColor: widget.actionColor.withOpacity(0.1),
      imageBorderRadius: AppDimensions.getImageBorderRadius(context),
      onRatingSubmitted: (rating, comment) async {
        // Obtenir le numéro de l'utilisateur connecté
        final user = AuthService.instance.getCurrentUser();
        final userNumero = user?.phone ?? '';

        // Appeler le service API pour soumettre l'avis
        await AvisService().submitAvis(userNumero, schoolId, rating, comment);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: (isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark).copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: AppColors.screenBg(context),
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: CustomScrollView(
            slivers: [
              CustomSliverAppBar(
                title: 'Donner un avis',
                isDark: false,
                surfaceTintColor: Colors.transparent,
                automaticallyImplyLeading: true,
                onBackTap: () => Navigator.pop(context),
                titleTextStyle: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  color: AppColors.screenTextPrimaryThemed(context),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                sliver: _isLoading
                    ? const SliverFillRemaining(
                        child: Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF0288D1),
                            strokeWidth: 2.5,
                          ),
                        ),
                      )
                    : _schools.isEmpty
                        ? SliverFillRemaining(child: _buildEmptyState())
                        : SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final school = _schools[index];
                                return Column(
                                  children: [
                                    _buildSchoolListItem(school),
                                    if (index < _schools.length - 1)
                                      Divider(
                                        height: 1,
                                        indent: 72,
                                        endIndent: 16,
                                        color: AppColors.screenDividerThemed(context),
                                      ),
                                  ],
                                );
                              },
                              childCount: _schools.length,
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSchoolListItem(Map<String, dynamic> schoolData) {
    final String schoolId = schoolData['schoolId'];
    final String schoolName = schoolData['schoolName'];
    final List<Child> enrolledChildren = schoolData['children'];

    return ListTile(
      onTap: () => _onSchoolTapped(schoolId, schoolName),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        radius: 28,
        backgroundColor: widget.actionColor.withOpacity(0.1),
        child: Icon(
          Icons.school_outlined,
          color: widget.actionColor,
          size: 28,
        ),
      ),
      title: Text(
        schoolName,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.screenTextPrimaryThemed(context),
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            enrolledChildren.length == 1
                ? '1 enfant inscrit'
                : '${enrolledChildren.length} enfants inscrits',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.screenTextSecondaryThemed(context),
            ),
          ),
        ],
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: AppColors.screenTextSecondaryThemed(context),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: widget.actionColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.child_care,
              size: 36,
              color: widget.actionColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun établissement',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.screenTextPrimaryThemed(context),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Ajoutez un enfant pour donner un avis sur son établissement',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.screenTextSecondaryThemed(context),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
