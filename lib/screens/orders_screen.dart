import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/app_colors.dart';
import '../config/app_dimensions.dart';
import '../models/cart_item.dart';
import '../models/order.dart';
import '../services/order_service.dart';
import '../services/auth_service.dart';
import '../widgets/custom_loader.dart';
import '../widgets/custom_sliver_app_bar.dart';
import '../widgets/bottom_fade_gradient.dart';
import '../widgets/filter_row_widget.dart';
import '../widgets/bottom_sheets/reusable_bottom_sheet.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/main_screen_wrapper.dart';
import '../widgets/scroll_to_top_fab.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen>
    with SingleTickerProviderStateMixin {
  final OrderService _orderService = OrderService();
  final AuthService _authService = AuthService();
  List<Order> _orders = [];
  List<Order> _filteredOrders = [];
  bool _isLoading = true;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatusFilter = 'En attente';

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final ScrollController _mainScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _loadOrders();
  }

  @override
  void dispose() {
    _mainScrollController.dispose();
    _fadeController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  String? _getApiStatusParam(String filter) {
    switch (filter) {
      case 'En attente':
        return 'en_attente';
      case 'En cours':
        return 'en_cours';
      case 'Livrées':
        return 'livree';
      case 'Annulées':
        return 'annulee';
      default:
        return null;
    }
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    try {
      final currentUser = _authService.getCurrentUser();
      if (currentUser == null) {
        setState(() {
          _isLoading = false;
          _orders = [];
          _filteredOrders = [];
        });
        return;
      }
      
      final apiStatus = _getApiStatusParam(_selectedStatusFilter);
      final orders = await _orderService.getUserOrders(currentUser.phone, statut: apiStatus);
      
      setState(() {
        _orders = orders;
        _filteredOrders = orders;
        _isLoading = false;
      });
      _fadeController.forward(from: 0);
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Erreur lors du chargement des commandes: $e');
    }
  }

  // Méthode de filtrage des commandes
  void _filterOrders(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredOrders = _orders;
      } else {
        _filteredOrders = _orders.where((order) {
          final orderId = order.id.toLowerCase();
          final orderDate = _formatDate(order.createdAt).toLowerCase();
          final orderStatus = order.status.displayName.toLowerCase();
          final searchQuery = query.toLowerCase();
          
          return orderId.contains(searchQuery) ||
                 orderDate.contains(searchQuery) ||
                 orderStatus.contains(searchQuery);
        }).toList();
      }
    });
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        _filterOrders('');
      }
    });
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.red[400],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: isDark ? Colors.black : Colors.white,
        floatingActionButton: ScrollToTopFab(scrollController: _mainScrollController, bottomSpacerHeight: 70),
        body: _buildBody(),
      ),
    );
  }

  // ─── BODY ──────────────────────────────────────────────────────────────────
  Widget _buildBody() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDark ? Colors.black : Colors.white,
        body: SafeArea(
          child: CustomScrollView(
            controller: _mainScrollController,
            slivers: [
              _buildSliverAppBar(),
              SliverFillRemaining(
                hasScrollBody: false,
                child: const Center(
                  child: CustomLoader(
                    message: 'Chargement de vos commandes...',
                    loaderColor: AppColors.shopGreen,
                    showBackground: false,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Stack(
        children: [
          CustomScrollView(
            controller: _mainScrollController,
            slivers: [
              _buildSliverAppBar(),
              SliverToBoxAdapter(
                child: _buildSearchBar(),
              ),
              SliverFillRemaining(
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    _buildFilterButtons(),
                    _buildStatsHeader(),
                    Expanded(child: _buildOrdersList()),
                  ],
                ),
              ),
            ],
          ),
          const BottomFadeGradient(),
        ],
      ),
    );
  }

  // ─── SEARCH BAR ────────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return SearchBarWidget(
      isSearching: _isSearching,
      searchController: _searchController,
      onChanged: _filterOrders,
      onClear: () {
        _filterOrders('');
      },
      hintText: 'Rechercher une commande...',
    );
  }

  // ─── APP BAR ───────────────────────────────────────────────────────────────
  Widget _buildSliverAppBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return CustomSliverAppBar(
      title: 'Mes Commandes',
      isDark: isDark,
      automaticallyImplyLeading: true,
      actions: [
        // Bouton de recherche
        GestureDetector(
          onTap: _toggleSearch,
          child: Container(
            width: 40,
            height: 40,
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.screenCardThemed(context),
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppDimensions.getSettingsCardShadow(context),
            ),
            child: Icon(
              _isSearching ? Icons.close_rounded : Icons.search_rounded,
              size: 20,
              color: AppColors.shopBlue,
            ),
          ),
        ),
      ],
      onBackTap: () {
        final wrapper = MainScreenWrapper.maybeOf(context);
        if (wrapper != null) {
          wrapper.goBackToPreviousTab();
        } else {
          Navigator.pop(context);
        }
      },
    );
  }

  Widget _buildStatsHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Calculate stats
    final int totalCount = _orders.length;
    final double totalSum = _orders.fold<double>(
      0.0,
      (sum, order) => sum + order.totalAmount,
    );
    final int pendingCount = _orders.where((order) => order.status == OrderStatus.pending).length;
    final int validatedCount = _orders.where((order) => 
      order.status == OrderStatus.confirmed || 
      order.status == OrderStatus.processing || 
      order.status == OrderStatus.shipped || 
      order.status == OrderStatus.delivered
    ).length;

    // Format sum concisely: e.g., 11500 -> "11.5k" or 5000 -> "5k"
    String sumStr = "";
    if (totalSum >= 1000) {
      final double kValue = totalSum / 1000;
      sumStr = "${kValue.toStringAsFixed(kValue % 1 == 0 ? 0 : 1)}k";
    } else {
      sumStr = totalSum.toStringAsFixed(0);
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.screenCardThemed(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.screenDividerThemed(context).withOpacity(0.5), width: 1),
        boxShadow: AppDimensions.getSettingsCardShadow(context),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStatItem('Total', totalCount.toString(), isDark, Icons.shopping_bag_outlined, AppColors.shopBlue),
          _buildStatVerticalDivider(isDark),
          _buildStatItem('Somme', '$sumStr F', isDark, Icons.monetization_on_outlined, AppColors.shopGreen),
          _buildStatVerticalDivider(isDark),
          _buildStatItem('En attente', pendingCount.toString(), isDark, Icons.hourglass_empty_rounded, Colors.orange[700]!),
          _buildStatVerticalDivider(isDark),
          _buildStatItem('Validées', validatedCount.toString(), isDark, Icons.check_circle_outline_rounded, Colors.green[600]!),
        ],
      ),
    );
  }

  Widget _buildStatVerticalDivider(bool isDark) {
    return Container(
      width: 1,
      height: 36,
      color: AppColors.screenDividerThemed(context).withOpacity(0.5),
    );
  }

  Widget _buildStatItem(String title, String value, bool isDark, IconData icon, Color color) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.screenTextPrimaryThemed(context),
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.screenTextSecondaryThemed(context),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButtons() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: FilterRowWidget(
        filters: const ['En attente', 'En cours', 'Livrées', 'Annulées', 'Tous'],
        selectedFilter: _selectedStatusFilter,
        onFilterSelected: (String filter) {
          setState(() {
            _selectedStatusFilter = filter;
          });
          _loadOrders();
        },
      ),
    );
  }

  Widget _buildOrdersList() {
    final displayOrders = _isSearching ? _filteredOrders : _orders;
    
    return RefreshIndicator(
      color: AppColors.shopGreen,
      onRefresh: _loadOrders,
      child: Column(
        children: [
          // Indicateur de recherche active
          if (_isSearching)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                '${displayOrders.length} commande${displayOrders.length > 1 ? 's' : ''} trouvée${displayOrders.length > 1 ? 's' : ''}',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.screenTextSecondaryThemed(context),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          Expanded(
            child: displayOrders.isEmpty
                ? _buildEmptyStateArea()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                    itemCount: displayOrders.length,
                    itemBuilder: (context, index) => _buildOrderCard(
                      displayOrders[index],
                      index,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStateArea() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : AppColors.shopBlueSurface,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.receipt_long_outlined,
                  size: 38,
                  color: isDark ? AppColors.shopBlueLight : AppColors.shopBlue,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Aucune commande',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.screenTextPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _selectedStatusFilter == 'En attente'
                    ? 'Vous n\'avez aucune commande en attente.'
                    : 'Vous n\'avez aucune commande dans cette catégorie.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? const Color(0xFFAAAAAA) : AppColors.screenTextSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.shopBlueLight, AppColors.shopBlue],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shopBlue.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Text(
                    'Commencer vos achats',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // État vide pour la recherche

  // ─── SUMMARY BAR (miroir du checkout bar du CartScreen) ───────────────────

  // ─── EMPTY STATE ───────────────────────────────────────────────────────────

  // ─── ORDER CARD ────────────────────────────────────────────────────────────
  Widget _buildOrderCard(Order order, int index) {
    final statusInfo = _getStatusInfo(order.status);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 200 + index * 50),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 10 * (1 - value)),
          child: child,
        ),
      ),
      child: GestureDetector(
        onTap: () => _showOrderDetails(order),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: AppColors.screenCardThemed(context),
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppDimensions.getSettingsCardShadow(context),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                // Icône commande plus compacte
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark 
                        ? const Color(0xFF2C2C2E) 
                        : const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    statusInfo.icon,
                    color: AppColors.screenTextSecondaryThemed(context),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),

                // Info principale
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Ligne supérieure: ID + Statut
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'CMD #${order.id.substring(order.id.length - 6)}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.screenTextPrimaryThemed(context),
                                letterSpacing: -0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Status badge compact
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: statusInfo.color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              order.status.displayName,
                              style: TextStyle(
                                fontSize: 10,
                                color: statusInfo.color,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),

                      // Ligne du milieu: Date + Articles
                      Row(
                        children: [
                          Text(
                            _formatDate(order.createdAt),
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.screenTextSecondary,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Articles chip ultra compact
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.screenSurface,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.shopping_bag_outlined,
                                  size: 10,
                                  color: AppColors.screenTextSecondary,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  '${order.totalItems}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: AppColors.screenTextSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // Ligne inférieure: Prix + flèche
                      Row(
                        children: [
                          Text(
                            '${order.totalAmount.toStringAsFixed(0)} FCFA',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.shopGreen,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const Spacer(),
                          const Icon(
                            Icons.chevron_right,
                            size: 14,
                            color: AppColors.screenTextSecondary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showOrderDetails(Order order) {
    showModalBottomSheet(
      constraints: const BoxConstraints(maxWidth: double.infinity),
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: _OrderDetailsSheet(order: order),
      ),
    );
  }

  // ─── HELPERS ──────────────────────────────────────────────────────────────
  _StatusInfo _getStatusInfo(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return _StatusInfo(Colors.orange, Icons.schedule_rounded);
      case OrderStatus.confirmed:
        return _StatusInfo(Colors.blue, Icons.check_circle_outline_rounded);
      case OrderStatus.processing:
        return _StatusInfo(Colors.purple, Icons.autorenew_rounded);
      case OrderStatus.shipped:
        return _StatusInfo(Colors.indigo, Icons.local_shipping_outlined);
      case OrderStatus.delivered:
        return _StatusInfo(Colors.green, Icons.done_all_rounded);
      case OrderStatus.cancelled:
        return _StatusInfo(Colors.red, Icons.cancel_outlined);
      case OrderStatus.refunded:
        return _StatusInfo(Colors.grey, Icons.replay_rounded);
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) {
      return 'Aujourd\'hui, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Hier, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays < 7) {
      return 'Il y a ${diff.inDays} jours';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

// ─── STATUS INFO ──────────────────────────────────────────────────────────────
class _StatusInfo {
  final Color color;
  final IconData icon;
  const _StatusInfo(this.color, this.icon);
}

// ═══════════════════════════════════════════════════════════════════════════════
// ORDER DETAILS BOTTOM SHEET
// ═══════════════════════════════════════════════════════════════════════════════
// ═══════════════════════════════════════════════════════════════════════════════
// ORDER DETAILS BOTTOM SHEET — style aligné avec _buildOrderBottomSheet
// ═══════════════════════════════════════════════════════════════════════════════
class _OrderDetailsSheet extends StatefulWidget {
  final Order order;
  const _OrderDetailsSheet({required this.order});

  @override
  State<_OrderDetailsSheet> createState() => _OrderDetailsSheetState();
}

class _OrderDetailsSheetState extends State<_OrderDetailsSheet> {
  final DraggableScrollableController _draggableController = DraggableScrollableController();

  Order get order => widget.order;

  @override
  void dispose() {
    _draggableController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statusInfo = _getStatusInfo(order.status);

    return ReusableBottomSheet(
      title: 'Détails de la commande',
      subtitle: '#${order.id.substring(order.id.length - 8)}',
      icon: Icons.receipt_long_outlined,
      iconColor: AppColors.shopBlue,
      contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Statut + date + paiement
          _buildInfoCard(context, statusInfo),
          const SizedBox(height: 24),

          // Articles
          _sectionLabel(context, 'Articles (${order.totalItems})'),
          const SizedBox(height: 12),
          ...order.items.asMap().entries.map(
                (e) => _buildItemTile(context, e.value, e.key),
              ),

          const SizedBox(height: 24),

          // Récap total
          _sectionLabel(context, 'Récapitulatif'),
          const SizedBox(height: 12),
          _buildTotalCard(context),

          const SizedBox(height: 8),
        ],
      ),
      fixedBottomWidget: order.status == OrderStatus.pending
          ? Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              decoration: BoxDecoration(
                color: AppColors.screenCardThemed(context),
                border: Border(
                  top: BorderSide(color: AppColors.screenDividerThemed(context)),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          height: 52,
                          decoration: BoxDecoration(
                            color: AppColors.screenSurfaceThemed(context),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: AppColors.screenDividerThemed(context), width: 1.5),
                          ),
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.headset_mic_outlined,
                                    size: 18,
                                    color: AppColors.screenTextSecondaryThemed(context)),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    'Support',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.screenTextSecondaryThemed(context),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _CancelButton(order: order),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  // ─── Section label ─────────────────────────────────────────────────────────
  Widget _sectionLabel(BuildContext context, String text) => Text(
        text,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: AppColors.screenTextPrimaryThemed(context),
          letterSpacing: -0.3,
        ),
      );

  // ─── Info card (statut, date, paiement) ────────────────────────────────────
  Widget _buildInfoCard(BuildContext context, _StatusInfo statusInfo) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.screenSurfaceThemed(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.screenDividerThemed(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 5,
                child: _infoCell(
                  context,
                  label: 'Statut',
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusInfo.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusInfo.icon,
                            size: 13, color: statusInfo.color),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            order.status.displayName,
                            style: TextStyle(
                              fontSize: 11,
                              color: statusInfo.color,
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 4,
                child: _infoCell(
                  context,
                  label: 'Date',
                  child: Text(
                    _formatDate(order.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.screenTextPrimaryThemed(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 5,
                child: _infoCell(
                  context,
                  label: 'Paiement',
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.payment_outlined,
                          size: 14, color: AppColors.shopGreen),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          order.paymentMethod.displayName,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.screenTextPrimaryThemed(context),
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (order.paymentReference != null) ...[
            const SizedBox(height: 12),
            Divider(color: AppColors.screenDividerThemed(context), height: 1),
            const SizedBox(height: 12),
            _infoCell(
              context,
              label: 'Référence',
              child: Text(
                order.paymentReference!,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.screenTextPrimaryThemed(context),
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoCell(BuildContext context, {required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: AppColors.screenTextSecondaryThemed(context),
            fontWeight: FontWeight.w500,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 4),
        child,
      ],
    );
  }

  // ─── Item tile (même layout que CartScreen) ─────────────────────────────────
  Widget _buildItemTile(BuildContext context, CartItem item, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 200 + index * 60),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 12 * (1 - value)),
          child: child,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.screenCardThemed(context),
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppDimensions.getSettingsCardShadow(context),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image (même taille que CartScreen : 76×76)
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 76,
                  height: 76,
                  color: const Color(0xFFF5F5F5),
                  child: item.product.imageUrl != null
                      ? Image.network(
                          item.product.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.image_not_supported_outlined,
                            color: Color(0xFFCCCCCC),
                            size: 30,
                          ),
                        )
                      : const Icon(
                          Icons.shopping_bag_outlined,
                          color: Color(0xFFCCCCCC),
                          size: 30,
                        ),
                ),
              ),
              const SizedBox(width: 14),

              // Infos
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.product.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.screenTextPrimaryThemed(context),
                        letterSpacing: -0.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text(
                          '${item.product.price.toStringAsFixed(0)} FCFA',
                          style: const TextStyle(
                            fontSize: 15,
                            color: AppColors.shopGreen,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Spacer(),
                        // Quantité read-only (miroir du stepper, sans les boutons)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.screenSurfaceThemed(context),
                            borderRadius: BorderRadius.circular(8),
                            border:
                                Border.all(color: AppColors.screenDividerThemed(context)),
                          ),
                          child: Text(
                            'Qté : ${item.quantity}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.screenTextPrimaryThemed(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Total recap card (miroir du CartScreen) ───────────────────────────────
  Widget _buildTotalCard(BuildContext context) {
    final double subtotal = order.items.fold<double>(
      0.0,
      (sum, item) => sum + (item.product.price * item.quantity),
    );
    final double deliveryFee = order.totalAmount - subtotal;
    final bool isFree = deliveryFee <= 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.screenSurfaceThemed(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.screenDividerThemed(context)),
      ),
      child: Column(
        children: [
          _recapRow(
            context,
            'Sous-total',
            '${subtotal.toStringAsFixed(0)} FCFA',
            isSubtitle: true,
          ),
          const SizedBox(height: 8),
          _recapRow(
            context,
            'Frais de livraison',
            isFree ? 'Gratuite' : '${deliveryFee.toStringAsFixed(0)} FCFA',
            isSubtitle: true,
            valueColor: isFree ? Colors.green[600]! : AppColors.screenTextPrimaryThemed(context),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Divider(color: AppColors.screenDividerThemed(context), height: 1),
          ),
          _recapRow(
            context,
            'Total',
            '${order.totalAmount.toStringAsFixed(0)} FCFA',
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _recapRow(BuildContext context, String label, String value,
      {bool isSubtitle = false, bool isTotal = false, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 15 : 13,
            color: isTotal
                ? AppColors.screenTextPrimaryThemed(context)
                : AppColors.screenTextSecondaryThemed(context),
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 17 : 13,
            color: valueColor ??
                (isTotal
                    ? AppColors.shopGreen
                    : AppColors.screenTextPrimaryThemed(context)),
            fontWeight: isTotal ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────
  _StatusInfo _getStatusInfo(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return _StatusInfo(Colors.orange, Icons.schedule_rounded);
      case OrderStatus.confirmed:
        return _StatusInfo(Colors.blue, Icons.check_circle_outline_rounded);
      case OrderStatus.processing:
        return _StatusInfo(Colors.purple, Icons.autorenew_rounded);
      case OrderStatus.shipped:
        return _StatusInfo(Colors.indigo, Icons.local_shipping_outlined);
      case OrderStatus.delivered:
        return _StatusInfo(Colors.green, Icons.done_all_rounded);
      case OrderStatus.cancelled:
        return _StatusInfo(Colors.red, Icons.cancel_outlined);
      case OrderStatus.refunded:
        return _StatusInfo(Colors.grey, Icons.replay_rounded);
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) {
      return 'Aujourd\'hui, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Hier, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays < 7) {
      return 'Il y a ${diff.inDays} jours';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

// ─── CANCEL BUTTON ────────────────────────────────────────────────────────────
class _CancelButton extends StatefulWidget {
  final Order order;
  const _CancelButton({required this.order});

  @override
  State<_CancelButton> createState() => _CancelButtonState();
}

class _CancelButtonState extends State<_CancelButton> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _isLoading ? null : _cancel,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          color: const Color(0xFFFFF0F0),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.red.withOpacity(0.2), width: 1.5),
        ),
        child: Center(
          child: _isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.red[400]!),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cancel_outlined,
                        size: 18, color: Colors.red[400]),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Annuler',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.red[400],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Future<void> _cancel() async {
    final TextEditingController reasonController = TextEditingController();
    String selectedReason = "Changement d'avis";
    final List<String> commonReasons = [
      "Changement d'avis",
      "Erreur d'article / quantité",
      "Achat accidentel",
      "Délai de livraison trop long",
      "Autre raison (saisir ci-dessous)"
    ];

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  const Icon(Icons.cancel_outlined, color: Colors.red, size: 24),
                  const SizedBox(width: 8),
                  const Text(
                    'Annuler la commande',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Veuillez sélectionner le motif d\'annulation de votre commande :',
                      style: TextStyle(fontSize: 13, height: 1.4),
                    ),
                    const SizedBox(height: 14),
                    ...commonReasons.map((reason) {
                      final isSelected = selectedReason == reason;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? Colors.red[500]!.withOpacity(isDark ? 0.15 : 0.05)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected 
                                ? Colors.red[400]! 
                                : (isDark ? Colors.grey[800]! : Colors.grey[200]!),
                            width: 1.2,
                          ),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            setDialogState(() {
                              selectedReason = reason;
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            child: Row(
                              children: [
                                Icon(
                                  isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                                  color: isSelected ? Colors.red : Colors.grey,
                                  size: 18,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    reason,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      color: isSelected 
                                          ? (isDark ? Colors.red[300] : Colors.red[700])
                                          : (isDark ? Colors.grey[300] : Colors.grey[800]),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                    if (selectedReason == "Autre raison (saisir ci-dessous)") ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: reasonController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Saisissez votre motif ici...',
                          hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                          contentPadding: const EdgeInsets.all(12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: isDark ? Colors.grey[800]! : Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.red),
                          ),
                        ),
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Retour', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  child: const Text(
                    'Confirmer',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true) return;

    final String finalReason = selectedReason == "Autre raison (saisir ci-dessous)"
        ? (reasonController.text.trim().isNotEmpty ? reasonController.text.trim() : "Autre motif")
        : selectedReason;

    setState(() => _isLoading = true);
    try {
      final success = await OrderService().cancelOrder(widget.order.id, reason: finalReason);
      if (success && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Commande annulée avec succès',
                style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.green[500],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Échec de l\'annulation de la commande',
                  style: TextStyle(color: Colors.white)),
              backgroundColor: Colors.red[400],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e',
                style: const TextStyle(color: Colors.white)),
            backgroundColor: Colors.red[400],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}