import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/app_colors.dart';
import '../models/cart_item.dart';
import '../models/lieu_livraison.dart';
import '../models/user.dart';
import '../services/order_service.dart';
import '../services/auth_service.dart';
import '../services/cart_service.dart';
import '../widgets/searchable_dropdown.dart';
import '../widgets/snackbar.dart';

class OrderWizardBottomSheet extends StatefulWidget {
  final Cart cart;
  final LieuLivraison? selectedLieu;
  final List<LieuLivraison> lieuxLivraison;
  final bool isLoadingLieux;
  final String? lieuxError;
  final OrderService orderService;
  final AuthService authService;
  final CartService cartService;
  final Function(String) onSuccess;
  final Function(String) onError;
  final VoidCallback onLoadLieux;

  const OrderWizardBottomSheet({
    super.key,
    required this.cart,
    this.selectedLieu,
    required this.lieuxLivraison,
    required this.isLoadingLieux,
    this.lieuxError,
    required this.orderService,
    required this.authService,
    required this.cartService,
    required this.onSuccess,
    required this.onError,
    required this.onLoadLieux,
  });

  @override
  State<OrderWizardBottomSheet> createState() => _OrderWizardBottomSheetState();
}

class _OrderWizardBottomSheetState extends State<OrderWizardBottomSheet>
    with TickerProviderStateMixin {
  int _currentStep = 0;
  late PageController _pageController;
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  // Controllers
  final _nomController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _adresseController = TextEditingController();
  final _emailController = TextEditingController();
  final _villeController = TextEditingController();
  final _paysController = TextEditingController();
  final _communeController = TextEditingController();
  final _ecoleController = TextEditingController();
  final _eleveIdController = TextEditingController();

  // State variables
  String _typeLivraison = 'domicile';
  double _prixLivraison = 2000;
  LieuLivraison? _selectedLieu;
  bool _isSubmitting = false;

  // Steps
  final List<String> _stepTitles = [
    'Livraison',
    'Coordonnées',
    'Infos scolaires',
    'Récapitulatif',
  ];

  final List<IconData> _stepIcons = [
    Icons.local_shipping_outlined,
    Icons.person_outline,
    Icons.school_outlined,
    Icons.receipt_long_outlined,
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 0.25,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    ));

    _initializeData();
  }

  void _initializeData() {
    final currentUser = widget.authService.getCurrentUser();
    _selectedLieu = widget.selectedLieu;

    if (currentUser != null) {
      _nomController.text = currentUser.fullName;
      _telephoneController.text = currentUser.phone;
      _emailController.text = currentUser.email ?? '';
      _adresseController.text = currentUser.adresse ?? '';
      _villeController.text = currentUser.ville ?? '';
      _paysController.text = 'Côte d\'Ivoire';
    }

    if (_selectedLieu != null) {
      _communeController.text = _selectedLieu!.nomcommune;
      _prixLivraison = _typeLivraison == 'domicile'
          ? _selectedLieu!.prixlivraison.toDouble()
          : 0;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _progressController.dispose();
    _nomController.dispose();
    _telephoneController.dispose();
    _adresseController.dispose();
    _emailController.dispose();
    _villeController.dispose();
    _paysController.dispose();
    _communeController.dispose();
    _ecoleController.dispose();
    _eleveIdController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 3) {
      setState(() {
        _currentStep++;
      });
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _updateProgress();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _updateProgress();
    }
  }

  void _updateProgress() {
    _progressController.animateTo((_currentStep + 1) / 4);
  }

  void _goToStep(int step) {
    if (step >= 0 && step <= 3 && step != _currentStep) {
      setState(() {
        _currentStep = step;
      });
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _updateProgress();
    }
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0: // Livraison
        // Permet de passer à l'étape suivante dès qu'au moins un champ obligatoire est rempli
        return _adresseController.text.trim().isNotEmpty ||
            _communeController.text.trim().isNotEmpty;
      case 1: // Coordonnées
        // Permet de passer à l'étape suivante dès qu'au moins un champ obligatoire est rempli
        return _nomController.text.trim().isNotEmpty ||
            _telephoneController.text.trim().isNotEmpty;
      case 2: // Infos scolaires (optionnel)
        return true;
      case 3: // Récapitulatif
        return true;
      default:
        return false;
    }
  }

  Future<void> _submitOrder() async {
    if (!_validateCurrentStep()) {
      _showErrorNotification('Veuillez remplir tous les champs obligatoires');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final result = await widget.orderService.createOrder(
        items: widget.cart.items,
        nom: _nomController.text.trim(),
        telephone: _telephoneController.text.trim(),
        adresse: _adresseController.text.trim(),
        email: _emailController.text.trim().isNotEmpty
            ? _emailController.text.trim()
            : null,
        ville: _villeController.text.trim().isNotEmpty
            ? _villeController.text.trim()
            : null,
        pays: _paysController.text.trim().isNotEmpty
            ? _paysController.text.trim()
            : null,
        commune: _communeController.text.trim(),
        typeLivraison: _typeLivraison,
        prixLivraison: _prixLivraison,
        ecole: _ecoleController.text.trim().isNotEmpty
            ? _ecoleController.text.trim()
            : null,
        eleveId: _eleveIdController.text.trim().isNotEmpty
            ? _eleveIdController.text.trim()
            : null,
      );

      // Vider le panier
      print('DEBUG: Vidage du panier...');
      await widget.cartService.clearCart();
      print('DEBUG: Panier vidé avec succès');
      
      // Afficher la notification de succès (fermera le bottom sheet automatiquement)
      _showSuccessNotification('Commande passée avec succès !');
      
      // Utiliser le callback onSuccess pour faire la redirection depuis le parent
      Future.delayed(const Duration(milliseconds: 500), () {
        print('DEBUG: Appel du callback onSuccess pour redirection');
        widget.onSuccess('Commande passée avec succès');
      });
    } catch (e) {
      _showErrorNotification('Erreur lors de la commande: $e');
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _showSuccessNotification(String message) {
    // Afficher le SnackBar de succès au-dessus du bottom sheet
    CartSnackBar.showOverlay(
      context,
      productName: 'Commande',
      message: ' passée avec succès !',
      backgroundColor: Colors.green,
      duration: const Duration(seconds: 3),
    );
    
    // Fermer le bottom sheet après un court délai
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        Navigator.pop(context);
      }
    });
  }

  void _showErrorNotification(String message) {
    // Afficher le SnackBar d'erreur au-dessus du bottom sheet
    CartSnackBar.showOverlay(
      context,
      productName: 'Erreur',
      message: message,
      backgroundColor: Colors.red,
      duration: const Duration(seconds: 4),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.70,
        ),
        decoration: const BoxDecoration(
          color: AppColors.screenCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with progress
            _buildHeader(),
            
            // Progress indicator
            _buildProgressIndicator(),
            
            // Content
            Flexible(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildLivraisonStep(),
                  _buildCoordonneesStep(),
                  _buildInfosScolairesStep(),
                  _buildRecapStep(),
                ],
              ),
            ),
            
            // Bottom navigation
            _buildBottomNavigation(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Column(
        children: [
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
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.shopBlueSurface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  _stepIcons[_currentStep],
                  color: AppColors.shopBlue,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Finaliser la commande - ${_stepTitles[_currentStep]}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.screenTextPrimary,
                        letterSpacing: -0.4,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Étape ${_currentStep + 1} sur 4',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.screenTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.screenSurface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.close,
                    size: 18,
                    color: AppColors.screenTextSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(4, (index) {
              final isActive = index == _currentStep;
              final isCompleted = index < _currentStep;
              
              return GestureDetector(
                onTap: () => _goToStep(index),
                child: Column(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? Colors.green
                            : isActive
                                ? AppColors.shopBlue
                                : AppColors.screenSurface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isActive
                              ? AppColors.shopBlue
                              : isCompleted
                                  ? Colors.green
                                  : AppColors.screenDivider,
                          width: 2,
                        ),
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: AppColors.shopBlue.withOpacity(0.25),
                                  blurRadius: 4,
                                  spreadRadius: 1,
                                ),
                              ]
                            : isCompleted
                                ? [
                                    BoxShadow(
                                      color: Colors.green.withOpacity(0.25),
                                      blurRadius: 4,
                                      spreadRadius: 1,
                                    ),
                                  ]
                                : null,
                      ),
                      child: isCompleted
                          ? const Icon(
                              Icons.check_rounded,
                              size: 16,
                              color: Colors.white,
                            )
                          : Icon(
                              _stepIcons[index],
                              size: 14,
                              color: isActive
                                  ? Colors.white
                                  : AppColors.screenTextSecondary,
                            ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _stepTitles[index],
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                        color: isActive
                            ? AppColors.shopBlue
                            : isCompleted
                                ? Colors.green
                                : AppColors.screenTextSecondary,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          Row(
            children: List.generate(4, (index) {
              final isCompleted = index < _currentStep;
              return Expanded(
                child: Container(
                  height: 3,
                  margin: EdgeInsets.only(
                    right: index < 3 ? 4 : 0,
                    left: index > 0 ? 4 : 0,
                  ),
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? Colors.green
                        : AppColors.screenDivider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: const BoxDecoration(
        color: AppColors.screenCard,
        border: Border(
          top: BorderSide(color: AppColors.screenDivider),
        ),
      ),
      child: SafeArea(
        top: false,
        child: _buildNavigationButtons(),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    final canNext = _validateCurrentStep();
    final isLast = _currentStep == 3;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: _currentStep > 0
            ? MainAxisAlignment.spaceBetween
            : MainAxisAlignment.end,
        children: [
          if (_currentStep > 0)
            GestureDetector(
              onTap: _previousStep,
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.screenSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.screenDivider),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.arrow_back_ios_new,
                      size: 14,
                      color: AppColors.screenTextSecondary,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Précédent',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.screenTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (!isLast)
            GestureDetector(
              onTap: canNext ? _nextStep : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  gradient: canNext
                      ? const LinearGradient(
                          colors: [
                            AppColors.shopBlueLight,
                            AppColors.shopBlue,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : LinearGradient(
                          colors: [
                            Colors.grey.shade300,
                            Colors.grey.shade300,
                          ],
                        ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: canNext
                      ? [
                          BoxShadow(
                            color: AppColors.shopBlue.withOpacity(0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Suivant',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: canNext ? Colors.white : Colors.grey.shade500,
                        letterSpacing: 0.1,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 14,
                      color: canNext ? Colors.white : Colors.grey.shade500,
                    ),
                  ],
                ),
              ),
            ),
          if (isLast)
            GestureDetector(
              onTap: canNext ? _submitOrder : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  gradient: canNext && !_isSubmitting
                      ? const LinearGradient(
                          colors: [AppColors.shopBlueLight, AppColors.shopBlue],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : LinearGradient(
                          colors: [
                            Colors.grey.shade300,
                            Colors.grey.shade300,
                          ],
                        ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: canNext && !_isSubmitting
                      ? [
                          BoxShadow(
                            color: AppColors.shopBlue.withOpacity(0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isSubmitting)
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.grey.shade500),
                        ),
                      )
                    else ...[
                      Text(
                        'Confirmer',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: canNext ? Colors.white : Colors.grey.shade500,
                          letterSpacing: 0.1,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.check_rounded,
                        size: 14,
                        color: canNext ? Colors.white : Colors.grey.shade500,
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  
  Widget _buildLivraisonStep() {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('Adresse de livraison'),
          const SizedBox(height: 12),
          _buildSheetTextField(
            controller: _adresseController,
            label: 'Adresse',
            hint: 'Quartier, rue...',
            icon: Icons.location_on_outlined,
            required: true,
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSheetTextField(
                  controller: _villeController,
                  label: 'Ville',
                  hint: 'Abidjan',
                  icon: Icons.location_city_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSheetTextField(
                  controller: _paysController,
                  label: 'Pays',
                  hint: 'Côte d\'Ivoire',
                  icon: Icons.flag_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildLieuLivraisonField(),
          const SizedBox(height: 12),
          _sectionSubLabel('Type de livraison'),
          const SizedBox(height: 8),
          Row(
            children: [
              _deliveryTypeChip(
                label: 'À domicile',
                icon: Icons.home_outlined,
                selected: _typeLivraison == 'domicile',
                onTap: () => setState(() {
                  _typeLivraison = 'domicile';
                  _prixLivraison = _selectedLieu?.prixlivraison.toDouble() ?? 2000;
                }),
              ),
              const SizedBox(width: 10),
              _deliveryTypeChip(
                label: 'Retrait sur place',
                icon: Icons.store_outlined,
                selected: _typeLivraison == 'retrait',
                onTap: () => setState(() {
                  _typeLivraison = 'retrait';
                  _prixLivraison = 0;
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCoordonneesStep() {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('Coordonnées'),
          const SizedBox(height: 12),
          _buildSheetTextField(
            controller: _nomController,
            label: 'Nom complet',
            hint: 'Jean Dupont',
            icon: Icons.person_outline,
            required: true,
          ),
          const SizedBox(height: 12),
          _buildSheetTextField(
            controller: _telephoneController,
            label: 'Téléphone',
            hint: '+225 07 00 00 00 00',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            required: true,
          ),
          const SizedBox(height: 12),
          _buildSheetTextField(
            controller: _emailController,
            label: 'Email',
            hint: 'jean@example.com',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
        ],
      ),
    );
  }

  Widget _buildInfosScolairesStep() {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('Informations scolaires (optionnel)'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.shopBlueSurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: AppColors.shopBlue,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Ces informations sont optionnelles mais peuvent aider à traiter votre commande plus rapidement.',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.shopBlue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildSheetTextField(
            controller: _ecoleController,
            label: 'École',
            hint: 'Nom de l\'établissement',
            icon: Icons.school_outlined,
          ),
          const SizedBox(height: 12),
          _buildSheetTextField(
            controller: _eleveIdController,
            label: 'ID Élève',
            hint: 'Identifiant de l\'élève',
            icon: Icons.badge_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildRecapStep() {
    final totalAmount = widget.cart.totalAmount + _prixLivraison;
    
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('Récapitulatif de la commande'),
          const SizedBox(height: 16),
          
          // Articles récap
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.screenSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.screenDivider),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Articles (${widget.cart.totalItems})',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.screenTextPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                ...widget.cart.items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${item.quantity}x ${item.product.title}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.screenTextSecondary,
                          ),
                        ),
                      ),
                      Text(
                        '${(item.product.price * item.quantity).toStringAsFixed(0)} FCFA',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.screenTextPrimary,
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Informations de livraison
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.screenSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.screenDivider),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Informations de livraison',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.screenTextPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                _recapInfoRow('Nom', _nomController.text),
                _recapInfoRow('Téléphone', _telephoneController.text),
                if (_emailController.text.isNotEmpty)
                  _recapInfoRow('Email', _emailController.text),
                _recapInfoRow('Adresse', _adresseController.text),
                _recapInfoRow('Commune', _communeController.text),
                if (_villeController.text.isNotEmpty)
                  _recapInfoRow('Ville', _villeController.text),
                _recapInfoRow('Type de livraison', _typeLivraison == 'domicile' ? 'À domicile' : 'Retrait sur place'),
                if (_ecoleController.text.isNotEmpty)
                  _recapInfoRow('École', _ecoleController.text),
                if (_eleveIdController.text.isNotEmpty)
                  _recapInfoRow('ID Élève', _eleveIdController.text),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Prix récap
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.shopBlueSurface.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.shopBlue.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                _recapRow(
                  'Sous-total',
                  '${widget.cart.totalAmount.toStringAsFixed(0)} FCFA',
                  isSubtitle: true,
                ),
                const SizedBox(height: 8),
                _recapRow(
                  'Frais de livraison',
                  '${_prixLivraison.toStringAsFixed(0)} FCFA',
                  isSubtitle: true,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Divider(
                    color: AppColors.screenDivider,
                    height: 1,
                  ),
                ),
                _recapRow(
                  'Total',
                  '${totalAmount.toStringAsFixed(0)} FCFA',
                  isTotal: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _recapInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label :',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.screenTextSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.screenTextPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w700,
      color: AppColors.screenTextPrimary,
      letterSpacing: -0.3,
    ),
  );

  Widget _sectionSubLabel(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: AppColors.screenTextSecondary,
    ),
  );

  Widget _deliveryTypeChip({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.shopBlueSurface
                : AppColors.screenSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? AppColors.shopBlue
                  : AppColors.screenDivider,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected
                    ? AppColors.shopBlue
                    : AppColors.screenTextSecondary,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: selected
                        ? AppColors.shopBlue
                        : AppColors.screenTextSecondary,
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

  Widget _recapRow(
    String label,
    String value, {
    bool isSubtitle = false,
    bool isTotal = false,
  }) {
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
            color: isTotal
                ? AppColors.shopBlue
                : AppColors.screenTextPrimary,
            fontWeight: isTotal ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildSheetTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool required = false,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.screenTextSecondary,
                letterSpacing: 0.2,
              ),
            ),
            if (required)
              const Text(
                ' *',
                style: TextStyle(
                  color: AppColors.shopBlue,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.screenTextPrimary,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFBBBBBB)),
            prefixIcon: Icon(icon, color: AppColors.shopBlue, size: 18),
            filled: true,
            fillColor: AppColors.screenSurface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.screenDivider),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.screenDivider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.shopBlue,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLieuLivraisonField() {
    if (widget.isLoadingLieux) {
      return _buildSheetLoadingField('Chargement des zones de livraison...');
    }

    if (widget.lieuxError != null) {
      return _buildSheetErrorField(widget.lieuxError!);
    }

    if (widget.lieuxLivraison.isEmpty) {
      return _buildSheetTextField(
        controller: TextEditingController(text: 'Aucune zone disponible'),
        label: 'Zone de livraison',
        hint: '',
        icon: Icons.location_on_outlined,
        required: true,
      );
    }

    final lieuNames = widget.lieuxLivraison
        .map((l) => '${l.nomcommune} — ${l.prixlivraison} FCFA')
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Text(
              'Zone de livraison',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.screenTextSecondary,
              ),
            ),
            Text(
              ' *',
              style: TextStyle(
                color: AppColors.shopBlue,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        SearchableDropdown(
          label: 'Zone de livraison',
          value: _selectedLieu != null
              ? '${_selectedLieu!.nomcommune} — ${_selectedLieu!.prixlivraison} FCFA'
              : 'Sélectionner une zone...',
          items: lieuNames,
          onChanged: (String selectedName) {
            final selectedLieu = widget.lieuxLivraison.firstWhere(
              (l) => '${l.nomcommune} — ${l.prixlivraison} FCFA' == selectedName,
            );
            setState(() {
              _selectedLieu = selectedLieu;
              _communeController.text = selectedLieu.nomcommune;
              _prixLivraison = _typeLivraison == 'domicile'
                  ? selectedLieu.prixlivraison.toDouble()
                  : 0;
            });
          },
          isDarkMode: false,
        ),
        if (_selectedLieu != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.shopBlueSurface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.local_shipping_outlined,
                  color: AppColors.shopBlue,
                  size: 15,
                ),
                const SizedBox(width: 8),
                Text(
                  'Frais de livraison : ${_selectedLieu!.prixlivraison} FCFA',
                  style: const TextStyle(
                    color: AppColors.shopBlue,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSheetLoadingField(String msg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.screenSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.screenDivider),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.shopBlue,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            msg,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.screenTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSheetErrorField(String error) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red[400], size: 16),
              const SizedBox(width: 8),
              Text(
                'Erreur de chargement',
                style: TextStyle(
                  color: Colors.red[400],
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: widget.onLoadLieux,
            child: Row(
              children: [
                Icon(Icons.refresh, color: Colors.red[400], size: 14),
                const SizedBox(width: 6),
                Text(
                  'Réessayer',
                  style: TextStyle(
                    color: Colors.red[400],
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
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

