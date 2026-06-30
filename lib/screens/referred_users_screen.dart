import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/app_colors.dart';
import '../config/app_dimensions.dart';
import '../models/referred_user.dart';
import '../services/referral_service.dart';
import '../services/auth_service.dart';
import '../widgets/custom_sliver_app_bar.dart';
import '../widgets/components/bottom_spacer.dart';
import '../widgets/components/custom_error_state.dart';

class ReferredUsersScreen extends StatefulWidget {
  const ReferredUsersScreen({super.key});

  @override
  State<ReferredUsersScreen> createState() => _ReferredUsersScreenState();
}

class _ReferredUsersScreenState extends State<ReferredUsersScreen> {
  bool _isLoading = true;
  List<ReferredUser> _referredUsers = [];
  String? _referralCode;

  @override
  void initState() {
    super.initState();
    _loadReferredUsers();
  }

  Future<void> _loadReferredUsers() async {
    setState(() => _isLoading = true);
    
    final currentUser = AuthService.instance.getCurrentUser();
    if (currentUser != null && currentUser.phone.isNotEmpty) {
      final users = await ReferralService.getReferredUsers(currentUser.phone);
      // Extraire le code de parrainage du parent (ici on prend le referred_by du premier enfant s'il y en a)
      if (users.isNotEmpty && users.first.referredBy != null) {
         _referralCode = users.first.referredBy;
      }
      if (mounted) {
        setState(() {
          _referredUsers = users;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDarkMode(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: (isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark).copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: AppColors.screenBg(context),
        body: CustomScrollView(
          slivers: [
            CustomSliverAppBar(
              title: 'Utilisateurs parrainés',
              isDark: isDark,
              automaticallyImplyLeading: true,
            ),
            SliverToBoxAdapter(
              child: _isLoading
                  ? const Padding(
                      padding: EdgeInsets.only(top: 100),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.screenOrange,
                        ),
                      ),
                    )
                  : _referredUsers.isEmpty
                      ? _buildEmptyState()
                      : _buildUsersList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
      child: CustomErrorState(
        title: 'Aucun utilisateur parrainé',
        message: 'Vous n\'avez pas encore parrainé d\'utilisateurs. Partagez votre code pour commencer à gagner des points !',
        icon: Icons.group_add_rounded,
        iconColor: AppColors.screenOrange,
      ),
    );
  }

  Widget _buildUsersList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_referralCode != null)
             Container(
               width: double.infinity,
               margin: const EdgeInsets.only(bottom: 24),
               padding: const EdgeInsets.all(16),
               decoration: BoxDecoration(
                 gradient: const LinearGradient(
                   colors: [Color(0xFFFF7A3C), Color(0xFFFF6B2C)],
                   begin: Alignment.topLeft,
                   end: Alignment.bottomRight,
                 ),
                 borderRadius: BorderRadius.circular(16),
                 boxShadow: AppDimensions.getSettingsCardShadow(context),
               ),
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   const Text(
                     'Votre code de parrainage',
                     style: TextStyle(
                       color: Colors.white70,
                       fontSize: 13,
                       fontWeight: FontWeight.w600,
                     ),
                   ),
                   const SizedBox(height: 8),
                   Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: [
                       Text(
                         _referralCode!,
                         style: const TextStyle(
                           color: Colors.white,
                           fontSize: 24,
                           fontWeight: FontWeight.w800,
                           letterSpacing: 2,
                         ),
                       ),
                       IconButton(
                         icon: const Icon(Icons.copy_rounded, color: Colors.white),
                         onPressed: () {
                           Clipboard.setData(ClipboardData(text: _referralCode!));
                           ScaffoldMessenger.of(context).showSnackBar(
                             const SnackBar(content: Text('Code copié !')),
                           );
                         },
                       ),
                     ],
                   ),
                 ],
               ),
             ),
          Text(
            '${_referredUsers.length} utilisateur${_referredUsers.length > 1 ? 's' : ''} parrainé${_referredUsers.length > 1 ? 's' : ''}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.screenTextPrimaryThemed(context),
            ),
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _referredUsers.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final user = _referredUsers[index];
              return _buildUserCard(user);
            },
          ),
          const BottomSpacer(height: 125),
        ],
      ),
    );
  }

  Widget _buildUserCard(ReferredUser user) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.screenCardThemed(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppDimensions.getSettingsCardShadow(context),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF2196F3).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                (user.prenoms?.isNotEmpty == true ? user.prenoms![0].toUpperCase() : '') +
                (user.nom?.isNotEmpty == true ? user.nom![0].toUpperCase() : ''),
                style: const TextStyle(
                  color: Color(0xFF2196F3),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${user.prenoms ?? ''} ${user.nom ?? ''}'.trim(),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.screenTextPrimaryThemed(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.phone ?? 'Numéro masqué',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.screenTextSecondaryThemed(context),
                  ),
                ),
              ],
            ),
          ),
          if (user.points != null && user.points! > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.stars_rounded,
                    size: 14,
                    color: Color(0xFF10B981),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${user.points}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF10B981),
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
