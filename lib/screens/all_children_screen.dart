import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../services/text_size_service.dart';
import '../services/mock_api_service.dart';
import '../models/child.dart';
import '../config/app_colors.dart';
import '../config/app_dimensions.dart';
import '../widgets/custom_sliver_app_bar.dart';
import 'child_list_screen.dart';

class AllChildrenScreen extends StatefulWidget {
  const AllChildrenScreen({super.key});

  @override
  State<AllChildrenScreen> createState() => _AllChildrenScreenState();
}

class _AllChildrenScreenState extends State<AllChildrenScreen>
    with SingleTickerProviderStateMixin {
  List<Child> _children = [];
  List<Child> _filteredChildren = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  final TextSizeService _textSizeService = TextSizeService();

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
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Load children data
  Future<void> _loadChildren() async {
    try {
      final user = AuthService.instance.getCurrentUser();
      final parentId = user?.id ?? 'parent1';
      final apiService = MockApiService();
      final children = await apiService.getChildrenForParent(parentId);
      if (!mounted) return;
      setState(() {
        _children = List.from(children);
        _filteredChildren = List.from(children);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Handle search
  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _filteredChildren = List.from(_children);
      } else {
        _filteredChildren = _children.where((child) {
          return child.firstName.toLowerCase().contains(query) ||
              child.lastName.toLowerCase().contains(query) ||
              child.establishment.toLowerCase().contains(query) ||
              child.grade.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  // ─── BUILD ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: AppColors.screenSurfaceThemed(context),
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: CustomScrollView(
            slivers: [
              CustomSliverAppBar(
                title: 'Tous les Enfants',
                actions: [
                  IconButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Search bar
                    _buildSearchBar(),
                    const SizedBox(height: 12),
                    // Children grid
                    if (_isLoading)
                      const Center(child: CircularProgressIndicator())
                    else if (_filteredChildren.isEmpty)
                      _buildEmptyState()
                    else
                      _buildChildrenGrid(),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Search bar
  Widget _buildSearchBar() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.screenCardThemed(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.screenBorder(context), width: 1),
      ),
      child: TextField(
        controller: _searchController,
        style: TextStyle(
          color: AppColors.screenTextPrimaryThemed(context),
          fontSize: _textSizeService.getScaledFontSize(16),
        ),
        decoration: InputDecoration(
          hintText: 'Rechercher un enfant...',
          hintStyle: TextStyle(
            color: AppColors.screenTextSecondaryThemed(context),
            fontSize: _textSizeService.getScaledFontSize(16),
          ),
          prefixIcon: Icon(
            Icons.search,
            color: AppColors.screenTextSecondaryThemed(context),
            size: 20,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  // Empty state
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.child_care_outlined,
            size: 64,
            color: AppColors.screenTextSecondaryThemed(context),
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun enfant trouvé',
            style: TextStyle(
              color: AppColors.screenTextSecondaryThemed(context),
              fontSize: _textSizeService.getScaledFontSize(18),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Essayez de modifier votre recherche',
            style: TextStyle(
              color: AppColors.screenTextSecondaryThemed(context),
              fontSize: _textSizeService.getScaledFontSize(14),
            ),
          ),
        ],
      ),
    );
  }

  // Children grid
  Widget _buildChildrenGrid() {
    return GridView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: _filteredChildren.length,
      itemBuilder: (context, index) {
        final child = _filteredChildren[index];
        return _buildChildCard(child, index);
      },
    );
  }

  // Child card
  Widget _buildChildCard(Child child, int index) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ChildListScreen(
              child: child,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.screenCardThemed(context),
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppDimensions.getSettingsCardShadow(context),
          border: Border.all(
            color: AppColors.screenBorder(context).withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Avatar
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.screenSurfaceThemed(context),
                border: Border.all(
                  color: AppColors.screenOrange.withOpacity(0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.screenOrange.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: child.photoUrl != null && child.photoUrl!.isNotEmpty
                  ? ClipOval(
                      child: Image.network(
                        child.photoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _defaultChildIcon(child),
                      ),
                    )
                  : _defaultChildIcon(child),
            ),
            const SizedBox(height: 12),
            // Name
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                child.fullName,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.screenTextPrimaryThemed(context),
                  fontSize: _textSizeService.getScaledFontSize(15),
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 4),
            // School
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                child.establishment,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.screenTextSecondaryThemed(context),
                  fontSize: _textSizeService.getScaledFontSize(12),
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 12),
            // Grade Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.screenOrange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                child.grade,
                style: TextStyle(
                  color: AppColors.screenOrange,
                  fontSize: _textSizeService.getScaledFontSize(11),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Default child icon
  Widget _defaultChildIcon(Child child) {
    final initial = child.firstName.isNotEmpty ? child.firstName[0].toUpperCase() : '';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDark ? Colors.grey[800] : Colors.grey[200],
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          color: isDark ? Colors.white70 : Colors.grey[600],
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
