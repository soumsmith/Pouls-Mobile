import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/app_colors.dart';
import '../config/app_typography.dart';
import '../models/cart_item.dart';
import '../models/order.dart';
import '../services/order_service.dart';
import '../services/auth_service.dart';
import '../widgets/custom_loader.dart';
import '../widgets/custom_sliver_app_bar.dart';

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

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

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
    _fadeController.dispose();
    _searchController.dispose();
    super.dispose();
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
      final orders = await _orderService.getUserOrders(currentUser.phone);
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
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark
          .copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: AppColors.screenSurfaceThemed(context),
        body: _buildBody(),
      ),
    );
  }

  // ─── BODY ──────────────────────────────────────────────────────────────────
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CustomLoader(
          message: 'Chargement de vos commandes...',
          loaderColor: AppColors.shopGreen,
          showBackground: false,
        ),
      );
    }
    if (_orders.isEmpty) return _buildEmptyState();

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: CustomScrollView(
              slivers: [
                _buildSliverAppBar(),
                SliverFillRemaining(
                  child: Column(
                    children: [
                      Expanded(child: _buildOrdersList()),
                      _buildSummaryBar(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── SEARCH BAR ────────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      height: _isSearching ? 56 : 0,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      decoration: BoxDecoration(
        color: AppColors.screenCardThemed(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.screenShadowThemed(context),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: _isSearching
          ? Row(
              children: [
                const SizedBox(width: 12),
                Icon(
                  Icons.search_rounded,
                  color: AppColors.screenTextSecondaryThemed(context),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    style: TextStyle(
                      color: AppColors.screenTextPrimaryThemed(context),
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Rechercher une commande...',
                      hintStyle: TextStyle(
                        color: AppColors.screenTextSecondaryThemed(context),
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: _filterOrders,
                  ),
                ),
                if (_searchController.text.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      _filterOrders('');
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        Icons.close_rounded,
                        color: AppColors.screenTextSecondaryThemed(context),
                        size: 16,
                      ),
                    ),
                  ),
              ],
            )
          : null,
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
        // Bouton de recherche/rafraîchissement
        GestureDetector(
          onTap: _isSearching ? _toggleSearch : _loadOrders,
          child: Container(
            width: 40,
            height: 40,
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.screenCardThemed(context),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.screenShadowThemed(context),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              _isSearching ? Icons.close_rounded : Icons.search_rounded,
              size: 20,
              color: AppColors.shopBlue,
            ),
          ),
        ),
      ],
      onBackTap: () => Navigator.pop(context),
    );
  }

  // ─── ORDERS LIST ───────────────────────────────────────────────────────────
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
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.screenTextSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          Expanded(
            child: displayOrders.isEmpty
                ? _buildSearchEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
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

  // État vide pour la recherche
  Widget _buildSearchEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.screenSurface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.search_off_rounded,
              size: 40,
              color: AppColors.screenTextSecondary,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Aucune commande trouvée',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.screenTextPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Essayez avec d\'autres mots-clés',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.screenTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ─── SUMMARY BAR (miroir du checkout bar du CartScreen) ───────────────────
  Widget _buildSummaryBar() {
    final totalOrders = _orders.length;
    final pendingCount =
        _orders.where((o) => o.status == OrderStatus.pending).length;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.screenCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
              color: Color(0x14000000),
              blurRadius: 20,
              offset: Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.screenDivider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Résumé',
                        style: TextStyle(
                            fontSize: 13,
                            color: AppColors.screenTextSecondary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$totalOrders commande${totalOrders > 1 ? 's' : ''}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppColors.screenTextPrimary,
                          letterSpacing: -0.8,
                        ),
                      ),
                    ],
                  ),
                  if (pendingCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.schedule_rounded,
                              size: 13, color: Colors.orange),
                          const SizedBox(width: 5),
                          Text(
                            '$pendingCount en attente',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.orange,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── EMPTY STATE ───────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return SafeArea(
      child: Column(
        children: [
          _buildSliverAppBar(),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: const BoxDecoration(
                      color: AppColors.shopBlueSurface,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.receipt_long_outlined,
                        size: 48, color: AppColors.shopBlue),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Aucune commande',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.screenTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Vous n\'avez pas encore passé\nde commande',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.screenTextSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.shopBlueLight, AppColors.shopBlue],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.shopBlue.withOpacity(0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Text(
                        'Commencer vos achats',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
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
    );
  }

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
            color: AppColors.screenCard,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: AppColors.screenShadow,
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
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
                    color: statusInfo.color.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    statusInfo.icon,
                    color: statusInfo.color,
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
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.screenTextPrimary,
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
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _OrderDetailsSheet(order: order),
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
class _OrderDetailsSheet extends StatelessWidget {
  final Order order;
  const _OrderDetailsSheet({required this.order});

  @override
  Widget build(BuildContext context) {
    final statusInfo = _getStatusInfo(order.status);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.screenCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.92,
        maxChildSize: 0.96,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              // ── Header fixe (miroir du CartScreen bottom sheet) ──
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Column(
                  children: [
                    // Handle
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.screenDivider,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    // Header row
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.shopBlueSurface,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.receipt_long_outlined,
                              color: AppColors.shopBlue, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Détails de la commande',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.screenTextPrimary,
                                  letterSpacing: -0.4,
                                ),
                                overflow: TextOverflow.ellipsis,
                                softWrap: false,
                              ),
                              Text(
                                '#${order.id.substring(order.id.length - 8)}',
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.screenTextSecondary),
                                overflow: TextOverflow.ellipsis,
                                softWrap: false,
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: AppColors.screenSurface,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.close,
                                size: 16,
                                color: AppColors.screenTextSecondary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: AppColors.screenDivider, height: 1),
                  ],
                ),
              ),

              // ── Contenu scrollable ──
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Statut + date + paiement
                      _buildInfoCard(statusInfo),
                      const SizedBox(height: 24),

                      // Articles
                      _sectionLabel('Articles (${order.totalItems})'),
                      const SizedBox(height: 12),
                      ...order.items.asMap().entries.map(
                            (e) => _buildItemTile(e.value, e.key),
                          ),

                      const SizedBox(height: 24),

                      // Récap total
                      _sectionLabel('Récapitulatif'),
                      const SizedBox(height: 12),
                      _buildTotalCard(),

                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),

              // ── Boutons d'action fixés en bas (miroir du CartScreen) ──
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                decoration: const BoxDecoration(
                  color: AppColors.screenCard,
                  border:
                      Border(top: BorderSide(color: AppColors.screenDivider)),
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Bouton support (outline)
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: double.infinity,
                          height: 52,
                          decoration: BoxDecoration(
                            color: AppColors.screenSurface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: AppColors.screenDivider, width: 1.5),
                          ),
                          child: const Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.headset_mic_outlined,
                                    size: 18,
                                    color: AppColors.screenTextSecondary),
                                SizedBox(width: 8),
                                Text(
                                  'Contacter le support',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.screenTextSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Bouton annuler uniquement si pending
                      if (order.status == OrderStatus.pending) ...[
                        const SizedBox(height: 10),
                        _CancelButton(order: order),
                      ],

                      const SizedBox(height: 4),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ─── Section label ─────────────────────────────────────────────────────────
  Widget _sectionLabel(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: AppColors.screenTextPrimary,
          letterSpacing: -0.3,
        ),
      );

  // ─── Info card (statut, date, paiement) ────────────────────────────────────
  Widget _buildInfoCard(_StatusInfo statusInfo) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.screenSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.screenDivider),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _infoCell(
                  label: 'Statut',
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
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
                        Text(
                          order.status.displayName,
                          style: TextStyle(
                            fontSize: 12,
                            color: statusInfo.color,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: _infoCell(
                  label: 'Date',
                  child: Text(
                    _formatDate(order.createdAt),
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.screenTextPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: AppColors.screenDivider, height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _infoCell(
                  label: 'Paiement',
                  child: Row(
                    children: [
                      const Icon(Icons.payment_outlined,
                          size: 14, color: AppColors.shopGreen),
                      const SizedBox(width: 6),
                      Text(
                        order.paymentMethod.displayName,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.screenTextPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (order.paymentReference != null)
                Expanded(
                  child: _infoCell(
                    label: 'Référence',
                    child: Text(
                      order.paymentReference!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.screenTextPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoCell({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.screenTextSecondary,
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
  Widget _buildItemTile(CartItem item, int index) {
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
          color: AppColors.screenCard,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
                color: AppColors.screenShadow,
                blurRadius: 12,
                offset: Offset(0, 4)),
          ],
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
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.screenTextPrimary,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.product.subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.screenTextSecondary,
                        fontWeight: FontWeight.w400,
                      ),
                      maxLines: 1,
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
                            color: AppColors.screenSurface,
                            borderRadius: BorderRadius.circular(8),
                            border:
                                Border.all(color: AppColors.screenDivider),
                          ),
                          child: Text(
                            'Qté : ${item.quantity}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.screenTextPrimary,
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
  Widget _buildTotalCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.screenSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.screenDivider),
      ),
      child: Column(
        children: [
          _recapRow(
              'Sous-total', '${order.totalAmount.toStringAsFixed(0)} FCFA',
              isSubtitle: true),
          const SizedBox(height: 8),
          _recapRow('Frais de livraison', 'Gratuite',
              isSubtitle: true, valueColor: Colors.green[600]!),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(color: AppColors.screenDivider, height: 1),
          ),
          _recapRow(
            'Total',
            '${order.totalAmount.toStringAsFixed(0)} FCFA',
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _recapRow(String label, String value,
      {bool isSubtitle = false, bool isTotal = false, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 15 : 13,
            color: isTotal
                ? AppColors.screenTextPrimary
                : AppColors.screenTextSecondary,
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
                    : AppColors.screenTextPrimary),
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
              ? const CustomLoader(
                  message: '',
                  loaderColor: Colors.red,
                  size: 20,
                  showBackground: false,
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cancel_outlined,
                        size: 18, color: Colors.red[400]),
                    const SizedBox(width: 8),
                    Text(
                      'Annuler la commande',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.red[400],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Future<void> _cancel() async {
    setState(() => _isLoading = true);
    try {
      final success = await OrderService().cancelOrder(widget.order.id);
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