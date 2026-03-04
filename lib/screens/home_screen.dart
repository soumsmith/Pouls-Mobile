import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../models/child.dart';
import '../services/database_service.dart';
import '../services/pouls_scolaire_api_service.dart';
import '../services/text_size_service.dart';
import '../widgets/main_screen_wrapper.dart';
import '../config/app_colors.dart';
import '../config/app_dimensions.dart';
import 'add_child_screen.dart';

/// Écran d'accueil avec liste des enfants
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Child> _children = [];
  bool _isLoading = true;
  String? _error;
  final TextSizeService _textSizeService = TextSizeService();

  @override
  void initState() {
    super.initState();
    _loadChildren();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadChildren();
    });
  }

  Future<void> _loadChildren() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      MainScreenWrapper.of(context).refreshCurrentUser();

      final parentId = MainScreenWrapper.of(context).currentUserId ?? 'parent1';

      final apiService = MainScreenWrapper.of(context).apiService;
      final children = await apiService.getChildrenForParent(parentId);

      final poulsApiService = PoulsScolaireApiService();
      for (final child in children) {
        if ((child.photoUrl == null || child.photoUrl!.isEmpty) &&
            child.id.isNotEmpty) {
          try {
            final childInfo =
                await DatabaseService.instance.getChildInfoById(child.id);
            if (childInfo != null) {
              final ecoleId = childInfo['ecoleId'] as int?;
              final matricule = childInfo['matricule'] as String?;

              if (ecoleId != null && matricule != null) {
                final anneeScolaire =
                    await poulsApiService.getAnneeScolaireOuverte(ecoleId);
                final anneeId = anneeScolaire.anneeOuverteCentraleId;

                final eleve = await poulsApiService.findEleveByMatricule(
                  ecoleId,
                  anneeId,
                  matricule,
                );

                if (eleve != null &&
                    eleve.urlPhoto != null &&
                    eleve.urlPhoto!.isNotEmpty) {
                  await DatabaseService.instance
                      .updateChildPhoto(child.id, eleve.urlPhoto);
                  final updatedChild = Child(
                    id: child.id,
                    firstName: child.firstName,
                    lastName: child.lastName,
                    establishment: child.establishment,
                    grade: child.grade,
                    photoUrl: eleve.urlPhoto,
                    parentId: child.parentId,
                  );
                  final index = children.indexOf(child);
                  if (index >= 0) {
                    children[index] = updatedChild;
                  }
                  print(
                      '✅ Photo mise à jour pour ${child.fullName}: ${eleve.urlPhoto}');
                }
              }
            }
          } catch (e) {
            print(
                '⚠️ Erreur lors de la mise à jour de la photo pour ${child.fullName}: $e');
          }
        }
      }

      setState(() {
        _children = children;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  /// Affiche le menu contextuel de partage
  void _showShareMenu() {
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    
    showMenu(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromLTWH(
          MediaQuery.of(context).size.width - 16, // Position à droite
          kToolbarHeight + 50, // Descendu de 20px pour éviter de couvrir les boutons
          0,
          0,
        ),
        Offset.zero & overlay.size,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 0,
      color: Theme.of(context).brightness == Brightness.dark ? null : Colors.white,
      items: [
        PopupMenuItem(
          value: 'mail',
          child: Row(
            children: [
              Icon(Icons.email, color: Colors.red, size: 20),
              SizedBox(width: 12),
              Text('Partager par mail'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'whatsapp',
          child: Row(
            children: [
              Icon(Icons.message, color: Colors.green, size: 20),
              SizedBox(width: 12),
              Text('Partager par WhatsApp'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'facebook',
          child: Row(
            children: [
              Icon(Icons.facebook, color: Colors.blue, size: 20),
              SizedBox(width: 12),
              Text('Partager sur Facebook'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'other',
          child: Row(
            children: [
              Icon(Icons.share, color: Colors.grey, size: 20),
              SizedBox(width: 12),
              Text('Autres options'),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value != null) {
        _handleShareAction(value);
      }
    });
  }

  /// Gère l'action de partage sélectionnée
  void _handleShareAction(String action) async {
    final String appUrl = 'https://play.google.com/store/apps/details?id=com.pouls.ecole';
    final String shareText = 'Découvrez Pouls École, l\'application qui vous permet de suivre le parcours scolaire de vos enfants en temps réel !';
    
    switch (action) {
      case 'mail':
        final Uri emailUri = Uri(
          scheme: 'mailto',
          query: 'subject=${Uri.encodeComponent('Découvrez Pouls École')}&body=${Uri.encodeComponent('$shareText\n\nTéléchargez l\'application ici : $appUrl')}',
        );
        if (await canLaunchUrl(emailUri)) {
          await launchUrl(emailUri);
        }
        break;
        
      case 'whatsapp':
        final Uri whatsappUri = Uri(
          scheme: 'https',
          host: 'wa.me',
          path: '',
          queryParameters: {
            'text': '$shareText\n\nTéléchargez l\'application ici : $appUrl',
          },
        );
        if (await canLaunchUrl(whatsappUri)) {
          await launchUrl(whatsappUri);
        }
        break;
        
      case 'facebook':
        final Uri facebookUri = Uri(
          scheme: 'https',
          host: 'www.facebook.com',
          path: 'sharer/sharer.php',
          queryParameters: {
            'u': appUrl,
            'quote': shareText,
          },
        );
        if (await canLaunchUrl(facebookUri)) {
          await launchUrl(facebookUri);
        }
        break;
        
      case 'other':
        await Share.share(
          '$shareText\n\nTéléchargez l\'application ici : $appUrl',
          subject: 'Découvrez Pouls École',
        );
        break;
    }
  }

  /// Carte de statistique réutilisable
  Widget _buildStatCard({
    required IconData icon,
    required Color color,
    required String value,
    required String label,
    required bool isDark,
    required bool isTablet,
  }) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 16.0 : 12.0),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(isTablet ? 16.0 : 12.0),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(isTablet ? 8.0 : 6.0),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(isTablet ? 8.0 : 6.0),
            ),
            child: Icon(icon, color: Colors.white, size: isTablet ? 20.0 : 16.0),
          ),
          SizedBox(height: isTablet ? 12.0 : 8.0),
          Text(
            value,
            style: TextStyle(
              fontSize: _textSizeService.getScaledFontSize(isTablet ? 24.0 : 20.0),
              fontWeight: FontWeight.w700,
              color: AppColors.getTextColor(isDark),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: _textSizeService.getScaledFontSize(9),
              color: AppColors.getTextColor(isDark, type: TextType.secondary),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isTablet = AppDimensions.isTablet(context) ||
        AppDimensions.isLargeTablet(context);

    return AnimatedBuilder(
      animation: _textSizeService,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: AppColors.getPureBackground(isDark),
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            title: Text(
              'Pouls École',
              style: TextStyle(
                color: AppColors.getTextColor(isDark),
                fontSize: _textSizeService.getScaledFontSize(20),
                fontWeight: FontWeight.w600,
              ),
            ),
            automaticallyImplyLeading: false,
            elevation: 0,
            backgroundColor: AppColors.getPureAppBarBackground(isDark),
            surfaceTintColor: Colors.transparent,
            foregroundColor: AppColors.getTextColor(isDark),
            actions: [
              IconButton(
                onPressed: _showShareMenu,
                icon: Container(
                  padding: EdgeInsets.all(isTablet ? 10.0 : 8.0),
                  decoration: BoxDecoration(
                    color: AppColors.primary.toSurface(),
                    borderRadius: BorderRadius.circular(isTablet ? 14.0 : 12.0),
                  ),
                  child: Icon(
                    Icons.share_outlined,
                    color: AppColors.primary,
                    size: isTablet ? 24.0 : 20.0,
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  // TODO: Notifications
                },
                icon: Container(
                  padding: EdgeInsets.all(isTablet ? 10.0 : 8.0),
                  decoration: BoxDecoration(
                    color: AppColors.primary.toSurface(),
                    borderRadius: BorderRadius.circular(isTablet ? 14.0 : 12.0),
                  ),
                  child: Icon(
                    Icons.notifications_outlined,
                    color: AppColors.primary,
                    size: isTablet ? 24.0 : 20.0,
                  ),
                ),
              ),
              SizedBox(width: isTablet ? 12.0 : 8.0),
            ],
          ),
          // floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          // floatingActionButton: Container(
          //   margin: const EdgeInsets.only(bottom: 80), // Positionne le FAB juste au-dessus du dock
          //   decoration: BoxDecoration(
          //     gradient: AppColors.primaryGradient,
          //     borderRadius: BorderRadius.circular(16),
          //     boxShadow: [
          //       BoxShadow(
          //         color: AppColors.primary.withOpacity(0.3),
          //         blurRadius: 20,
          //         offset: const Offset(0, 8),
          //       ),
          //     ],
          //   ),
          //   child: FloatingActionButton(
          //     onPressed: () async {
          //       final result = await Navigator.of(context).push(
          //         MaterialPageRoute(
          //           builder: (_) => const AddChildScreen(),
          //         ),
          //       );
          //       if (result == true) {
          //         _loadChildren();
          //       }
          //     },
          //     backgroundColor: AppColors.primary,
          //     elevation: 8,
          //     child: const Icon(Icons.add, color: Colors.white, size: 24),
          //   ),
          // ),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? [
                        AppColors.primary.withOpacity(0),
                        AppColors.primary.withOpacity(0),
                        AppColors.primary.withOpacity(0.3),
                        AppColors.getPureAppBarBackground(true),
                      ]
                    : [
                        AppColors.primary.withOpacity(0),
                        AppColors.primary.withOpacity(0),
                        AppColors.primary.withOpacity(0.3),
                        AppColors.getPureAppBarBackground(false),
                      ],
              ),
            ),
            child: SafeArea(
              bottom: false, // Supprime le padding du bas de la SafeArea
              child: Padding(
                padding: EdgeInsets.only(
                  left: AppDimensions.getHomePageResponsivePadding(context).left,
                  right: AppDimensions.getHomePageResponsivePadding(context).right,
                  top: AppDimensions.getHomePageResponsivePadding(context).top,
                  // bottom: 100, // Padding pour le dock flottant - supprimé ici
                ),
                child: Column(
                  children: [
                    SizedBox(height: AppDimensions.getAdaptiveSpacing(context) * 1.5),
                    // Header hero section
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Suivez le parcours scolaire\nde vos enfants',
                          style: TextStyle(
                            fontSize: _textSizeService.getScaledFontSize(
                                AppDimensions.getFormTitleFontSize(context) * 0.8),
                            fontWeight: FontWeight.w700,
                            color: AppColors.getTextColor(isDark),
                            height: 1.3,
                          ),
                        ),
                        SizedBox(height: AppDimensions.getAdaptiveSpacing(context)),
                        // Stats cards — grille 2x2
                        Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 16.0, //AppDimensions.getHomePageResponsivePadding(context).left),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildStatCard(
                                      icon: Icons.child_care,
                                      color: Colors.blue,
                                      value: '${_children.length}',
                                      label:
                                          'Enfant${_children.length > 1 ? 's' : ''} inscrit${_children.length > 1 ? 's' : ''}',
                                      isDark: isDark,
                                      isTablet: isTablet,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _buildStatCard(
                                      icon: Icons.grade,
                                      color: Colors.green,
                                      value: _getAverageGradeDisplay(),
                                      label: 'Niveau moyen',
                                      isDark: isDark,
                                      isTablet: isTablet,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildStatCard(
                                      icon: Icons.school,
                                      color: Colors.orange,
                                      value: '${_getUniqueSchoolsCount()}',
                                      label:
                                          'École${_getUniqueSchoolsCount() > 1 ? 's' : ''}',
                                      isDark: isDark,
                                      isTablet: isTablet,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _buildStatCard(
                                      icon: Icons.class_,
                                      color: Colors.purple,
                                      value: '${_getUniqueClassesCount()}',
                                      label:
                                          'Classe${_getUniqueClassesCount() > 1 ? 's' : ''}',
                                      isDark: isDark,
                                      isTablet: isTablet,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppDimensions.getAdaptiveSpacing(context)),
                    // Section enfants
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.getPureBackground(isDark),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(32),
                            topRight: Radius.circular(32),
                          ),
                        ),
                        child: Column(
                          children: [
                            const SizedBox(height: 28),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 22),
                              child: Row(
                                children: [
                                  Text(
                                    'Mes Enfants',
                                    style: TextStyle(
                                      fontSize: _textSizeService.getScaledFontSize(15),
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.getTextColor(isDark),
                                    ),
                                  ),
                                  const Spacer(),
                                  // Badge pour le nombre d'enfants
                                  // Container(
                                  //   padding: const EdgeInsets.symmetric(
                                  //       horizontal: 12, vertical: 6),
                                  //   decoration: BoxDecoration(
                                  //     color: AppColors.primary.toSurface(),
                                  //     borderRadius: BorderRadius.circular(20),
                                  //   ),
                                  //   child: Text(
                                  //     '${_children.length} enfant${_children.length > 1 ? 's' : ''}',
                                  //     style: TextStyle(
                                  //       fontSize: _textSizeService.getScaledFontSize(12),
                                  //       fontWeight: FontWeight.w600,
                                  //       color: AppColors.primary,
                                  //     ),
                                  //   ),
                                  // ),
                                  // const SizedBox(width: 8),
                                  // Bouton ajouter enfant
                                  Container(
                                    decoration: BoxDecoration(
                                      gradient: AppColors.primaryGradient,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: TextButton(
                                      onPressed: () async {
                                        final result = await Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => const AddChildScreen(),
                                          ),
                                        );
                                        if (result == true) {
                                          _loadChildren();
                                        }
                                      },
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.add, color: Colors.white, size: 16),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Ajouter un enfant',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: _textSizeService.getScaledFontSize(11),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 100), // Padding pour éviter que le contenu soit caché par la bottom nav
                                child: _isLoading
                                    ? const Center(child: CircularProgressIndicator())
                                    : _error != null
                                        ? Center(
                                            child: SingleChildScrollView(
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(Icons.error_outline,
                                                      size: 64, color: AppColors.error),
                                                  const SizedBox(height: 16),
                                                  Text(
                                                    'Une erreur est survenue',
                                                    style: TextStyle(
                                                      fontSize: _textSizeService
                                                          .getScaledFontSize(18),
                                                      fontWeight: FontWeight.w600,
                                                      color: AppColors.getTextColor(isDark),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    _error!,
                                                    style: TextStyle(
                                                      fontSize: _textSizeService
                                                          .getScaledFontSize(14),
                                                      color: AppColors.getTextColor(isDark,
                                                          type: TextType.secondary),
                                                    ),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                  const SizedBox(height: 24),
                                                  Container(
                                                    decoration: BoxDecoration(
                                                      gradient: AppColors.primaryGradient,
                                                      borderRadius:
                                                          BorderRadius.circular(12),
                                                    ),
                                                    child: ElevatedButton(
                                                      onPressed: _loadChildren,
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor: Colors.transparent,
                                                        shadowColor: Colors.transparent,
                                                        padding: const EdgeInsets.symmetric(
                                                            horizontal: 24, vertical: 12),
                                                      ),
                                                      child: Text(
                                                        'Réessayer',
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontWeight: FontWeight.w600,
                                                          fontSize: _textSizeService
                                                              .getScaledFontSize(14),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          )
                                        : _children.isEmpty
                                            ? Center(
                                                child: Padding(
                                                  padding: const EdgeInsets.symmetric(
                                                      horizontal: 16, vertical: 24),
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.center,
                                                    children: [
                                                      Container(
                                                        width: 60,
                                                        height: 60,
                                                        decoration: BoxDecoration(
                                                          gradient: LinearGradient(
                                                            colors: [
                                                              AppColors.primaryLight
                                                                  .withOpacity(0.15),
                                                              AppColors.primary
                                                                  .withOpacity(0.08),
                                                            ],
                                                          ),
                                                          borderRadius:
                                                              BorderRadius.circular(30),
                                                        ),
                                                        child: Icon(Icons.child_care,
                                                            size: 32,
                                                            color: AppColors.primary),
                                                      ),
                                                      const SizedBox(height: 24),
                                                      Text(
                                                        'Commencez votre parcours',
                                                        style: TextStyle(
                                                          fontSize: _textSizeService
                                                              .getScaledFontSize(18),
                                                          fontWeight: FontWeight.w700,
                                                          color: AppColors.getTextColor(
                                                              isDark),
                                                        ),
                                                      ),
                                                      const SizedBox(height: 12),
                                                      Text(
                                                        'Ajoutez votre premier enfant\npour suivre son évolution',
                                                        style: TextStyle(
                                                          fontSize: _textSizeService
                                                              .getScaledFontSize(13),
                                                          color: AppColors.getTextColor(
                                                              isDark,
                                                              type: TextType.secondary),
                                                          height: 1.3,
                                                        ),
                                                        textAlign: TextAlign.center,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              )
                                            : SingleChildScrollView(
                                                child: Column(
                                                  children: _children.map((child) {
                                                    return Container(
                                                      margin: const EdgeInsets.only(
                                                          bottom: 20,
                                                          left: 16,
                                                          right: 16),
                                                      decoration: BoxDecoration(
                                                        color: AppColors.getPureBackground(
                                                            isDark),
                                                        borderRadius:
                                                            BorderRadius.circular(16),
                                                        border: Border.all(
                                                          color: isDark
                                                              ? AppColors.grey700
                                                                  .withOpacity(0.3)
                                                              : AppColors.grey200
                                                                  .withOpacity(0.5),
                                                          width: 1,
                                                        ),
                                                      ),
                                                      child: ListTile(
                                                        contentPadding:
                                                            const EdgeInsets.symmetric(
                                                                horizontal: 8,
                                                                vertical: 5),
                                                        leading: Container(
                                                          width: 42,
                                                          height: 42,
                                                          decoration: BoxDecoration(
                                                            gradient:
                                                                AppColors.primaryGradient,
                                                            borderRadius:
                                                                BorderRadius.circular(10),
                                                          ),
                                                          child: child.photoUrl != null &&
                                                                  child.photoUrl!.isNotEmpty
                                                              ? ClipRRect(
                                                                  borderRadius:
                                                                      BorderRadius.circular(
                                                                          10),
                                                                  child: Image.network(
                                                                    child.photoUrl!,
                                                                    fit: BoxFit.cover,
                                                                    errorBuilder: (context,
                                                                        error, stackTrace) {
                                                                      return const Icon(
                                                                          Icons.person,
                                                                          color: Colors.white,
                                                                          size: 20);
                                                                    },
                                                                  ),
                                                                )
                                                              : const Icon(Icons.person,
                                                                  color: Colors.white,
                                                                  size: 20),
                                                        ),
                                                        title: Text(
                                                          child.fullName,
                                                          style: TextStyle(
                                                            fontSize: _textSizeService
                                                                .getScaledFontSize(14),
                                                            fontWeight: FontWeight.w700,
                                                            color: AppColors.getTextColor(
                                                                isDark),
                                                          ),
                                                        ),
                                                        subtitle: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment.start,
                                                          children: [
                                                            const SizedBox(height: 2),
                                                            Text(
                                                              child.establishment.isNotEmpty
                                                                  ? child.establishment
                                                                  : 'Établissement non renseigné',
                                                              style: TextStyle(
                                                                fontSize: _textSizeService
                                                                    .getScaledFontSize(11),
                                                                color: AppColors.getTextColor(
                                                                    isDark,
                                                                    type:
                                                                        TextType.secondary),
                                                                fontWeight: FontWeight.w500,
                                                              ),
                                                            ),
                                                            Text(
                                                              child.grade.isNotEmpty
                                                                  ? child.grade
                                                                  : 'Classe non renseignée',
                                                              style: TextStyle(
                                                                fontSize: _textSizeService
                                                                    .getScaledFontSize(10),
                                                                color: AppColors.getTextColor(
                                                                        isDark,
                                                                        type:
                                                                            TextType.secondary)
                                                                    .withOpacity(0.7),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        trailing: Container(
                                                          padding:
                                                              const EdgeInsets.all(4),
                                                          decoration: BoxDecoration(
                                                            color:
                                                                AppColors.primary.toSurface(),
                                                            borderRadius:
                                                                BorderRadius.circular(4),
                                                          ),
                                                          child: Icon(
                                                              Icons.arrow_forward_ios,
                                                              color: AppColors.primary,
                                                              size: 12),
                                                        ),
                                                        onTap: () {
                                                          MainScreenWrapper.of(context).navigateToChildDetail(child);
                                                        },
                                                      ),
                                                    );
                                                  }).toList(),
                                                ),
                                              ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  int _getUniqueClassesCount() {
    final uniqueClasses = _children.map((child) => child.grade).toSet();
    return uniqueClasses.length;
  }

  int _getUniqueSchoolsCount() {
    final uniqueSchools = _children.map((child) => child.establishment).toSet();
    return uniqueSchools.length;
  }

  String _getAverageGradeDisplay() {
    if (_children.isEmpty) return '-';

    final gradeLevels = _children.map((child) {
      final grade = child.grade.toLowerCase();
      if (grade.contains('cp') || grade.contains('1ère')) return 1;
      if (grade.contains('ce1') || grade.contains('2ème')) return 2;
      if (grade.contains('ce2') || grade.contains('3ème')) return 3;
      if (grade.contains('cm1') || grade.contains('4ème')) return 4;
      if (grade.contains('cm2') || grade.contains('5ème')) return 5;
      if (grade.contains('6ème')) return 6;
      if (grade.contains('5ème')) return 5;
      if (grade.contains('4ème')) return 4;
      if (grade.contains('3ème')) return 3;
      if (grade.contains('seconde')) return 10;
      if (grade.contains('première')) return 11;
      if (grade.contains('terminale')) return 12;
      return 3;
    }).toList();

    if (gradeLevels.isEmpty) return '-';

    final average = gradeLevels.reduce((a, b) => a + b) / gradeLevels.length;

    if (average <= 1) return 'CP';
    if (average <= 2) return 'CE1';
    if (average <= 3) return 'CE2';
    if (average <= 4) return 'CM1';
    if (average <= 5) return 'CM2';
    if (average <= 6) return '6ème';
    if (average <= 10) return 'Collège';
    if (average <= 11) return 'Première';
    return 'Lycée';
  }
}