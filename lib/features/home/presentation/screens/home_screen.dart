import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/brand_logo.dart';
import '../../../../core/widgets/client_bottom_nav.dart';
import '../../../../data/models/product_model.dart';
import '../../../../data/services/cart_service.dart';
import '../../../../data/services/catalog_service.dart';
import '../../../../routing/app_navigator.dart';
import '../../../catalog/presentation/widgets/product_card.dart';

/// Pantalla principal (Home / Inicio) para clientes de FarmaYopin.
///
/// Ofrece una experiencia acogedora con identidad visual de marca,
/// acceso rápido a categorías principales y vitrina de productos
/// destacados y ofertas.
class HomeScreen extends StatefulWidget {
  final String? token;
  final String nombre;
  final String email;
  final CatalogService? catalogService;
  final CartService? cartService;

  const HomeScreen({
    super.key,
    this.token,
    this.nombre = '',
    this.email = '',
    this.catalogService,
    this.cartService,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final CatalogService _catalogService;
  late final CartService _cartService;

  List<ProductModel> _featuredProducts = [];
  List<ProductModel> _vitaminsProducts = [];
  bool _isLoading = true;
  int _cartItemCount = 0;

  final List<Map<String, dynamic>> _quickCategories = [
    {
      'title': 'Medicamentos',
      'subtitle': 'Alivio y salud',
      'icon': Icons.medication_rounded,
      'color': Color(0xFF0D9488),
      'bg': Color(0xFFE6FFFA),
    },
    {
      'title': 'Vitaminas',
      'subtitle': 'Defensas y energía',
      'icon': Icons.wb_sunny_rounded,
      'color': Color(0xFFD97706),
      'bg': Color(0xFFFEF3C7),
    },
    {
      'title': 'Cuidado Personal',
      'subtitle': 'Higiene y bienestar',
      'icon': Icons.spa_rounded,
      'color': Color(0xFF7C3AED),
      'bg': Color(0xFFEDE9FE),
    },
    {
      'title': 'Todos',
      'displayName': 'Catálogo Completo',
      'subtitle': 'Todo en farmacia',
      'icon': Icons.grid_view_rounded,
      'color': Color(0xFF2563EB),
      'bg': Color(0xFFEFF6FF),
    },
  ];

  @override
  void initState() {
    super.initState();
    _catalogService = widget.catalogService ?? CatalogService();
    _cartService = widget.cartService ?? CartService();
    _loadData();
    _refreshCartCount();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final products = await _catalogService.getProductos(token: widget.token);
      if (mounted) {
        setState(() {
          // Seleccionamos destacados y vitaminas
          _featuredProducts = products.take(6).toList();
          _vitaminsProducts = products
              .where((p) => p.categoria.toLowerCase().contains('vitamina'))
              .take(4)
              .toList();
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _refreshCartCount() async {
    try {
      final cart = await _cartService.getCarrito(token: widget.token);
      if (mounted) setState(() => _cartItemCount = cart.cantidadUnidades);
    } on CartException catch (_) {}
  }

  Future<void> _openCart() async {
    final cart = await AppNavigator.toCart(context, token: widget.token);
    if (cart != null && mounted) {
      setState(() => _cartItemCount = cart.cantidadUnidades);
    } else {
      _refreshCartCount();
    }
  }

  Future<void> _openCatalog({String? category}) async {
    await AppNavigator.toCatalog(
      context,
      token: widget.token,
      nombre: widget.nombre,
      email: widget.email,
      initialCategory: category,
      catalogService: _catalogService,
    );
    _refreshCartCount();
  }

  Future<void> _addToCart(ProductModel product) async {
    try {
      final cart = await _cartService.agregarItem(
        productoId: product.id,
        cantidad: 1,
        token: widget.token,
      );
      if (!mounted) return;
      setState(() => _cartItemCount = cart.cantidadUnidades);

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${product.nombre} agregado al carrito.'),
          backgroundColor: AppColors.primary,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Ver carrito',
            textColor: Colors.white,
            onPressed: _openCart,
          ),
        ),
      );
    } on CartException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String get _primerNombre {
    final partes = widget.nombre.trim().split(RegExp(r'\s+'));
    if (partes.isNotEmpty && partes.first.isNotEmpty) {
      return partes.first;
    }
    return 'Hola';
  }

  String get _inicial {
    if (widget.nombre.trim().isNotEmpty) {
      return widget.nombre.trim().substring(0, 1).toUpperCase();
    }
    return 'F';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async {
                  await Future.wait([_loadData(), _refreshCartCount()]);
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      _buildGreetingAndSearchBar(),
                      const SizedBox(height: 24),
                      _buildCategoriesSection(),
                      const SizedBox(height: 24),
                      _buildFeaturedProductsSection(),
                      if (_vitaminsProducts.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        _buildVitaminsSection(),
                      ],
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: ClientBottomNav(
        currentIndex: 0, // 0 = Inicio
        cartCount: _cartItemCount,
        onTap: (index) => AppNavigator.goToClientTab(
          context,
          index,
          currentIndex: AppNavigator.tabInicio,
          token: widget.token,
          nombre: widget.nombre,
          email: widget.email,
          catalogService: _catalogService,
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const BrandLogo(iconSize: 32, fontSize: 22),
          Row(
            children: [
              IconButton(
                tooltip: 'Buscar en catálogo',
                icon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.textDark,
                  size: 24,
                ),
                onPressed: () => _openCatalog(),
              ),
              const SizedBox(width: 4),
              _buildCartButton(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCartButton() {
    return GestureDetector(
      onTap: _openCart,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            const Icon(
              Icons.shopping_bag_outlined,
              size: 20,
              color: AppColors.textDark,
            ),
            if (_cartItemCount > 0)
              Positioned(
                right: -4,
                top: -4,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: Center(
                    child: Text(
                      '$_cartItemCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGreetingAndSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => AppNavigator.goToClientTab(
                  context,
                  AppNavigator.tabPerfil,
                  token: widget.token,
                  nombre: widget.nombre,
                  email: widget.email,
                ),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6FFFA),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primaryLight.withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      _inicial,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.nombre.isNotEmpty
                          ? '¡Hola, $_primerNombre! 👋'
                          : '¡Bienvenido a FarmaYOpin! 👋',
                      style: const TextStyle(
                        color: AppColors.textDark,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      '¿Cómo podemos cuidar tu salud hoy?',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Buscador rápido interactivo que conduce al catálogo
          GestureDetector(
            onTap: () => _openCatalog(),
            child: Container(
              height: 46,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border, width: 1),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x06000000),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.search_rounded,
                    size: 20,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Buscar medicamentos, vitaminas, etc...',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Explorar',
                      style: TextStyle(
                        color: AppColors.textDark,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
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

  Widget _buildCategoriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Categorías Principales',
                style: TextStyle(
                  color: AppColors.textDark,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              TextButton(
                onPressed: () => _openCatalog(),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Ver catálogo',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.1,
            ),
            itemCount: _quickCategories.length,
            itemBuilder: (context, index) {
              final cat = _quickCategories[index];
              final categoryName = cat['title'] as String;
              final displayName =
                  (cat['displayName'] as String?) ?? categoryName;

              return InkWell(
                onTap: () {
                  _openCatalog(
                    category: categoryName == 'Todos' ? null : categoryName,
                  );
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border, width: 1),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x06000000),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: cat['bg'] as Color,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          cat['icon'] as IconData,
                          size: 20,
                          color: cat['color'] as Color,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textDark,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              cat['subtitle'] as String,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturedProductsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text(
                    'Productos Destacados',
                    style: TextStyle(
                      color: AppColors.textDark,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6FFFA),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Top',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () => _openCatalog(),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Ver todos',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (_isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          )
        else if (_featuredProducts.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: const Center(
                child: Text(
                  'No hay productos destacados disponibles.',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                ),
              ),
            ),
          )
        else
          SizedBox(
            height: 270,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: _featuredProducts.length,
              separatorBuilder: (context, index) => const SizedBox(width: 14),
              itemBuilder: (context, index) {
                final product = _featuredProducts[index];
                return SizedBox(
                  width: 175,
                  child: ProductCard(
                    product: product,
                    onTap: () async {
                      await AppNavigator.toProductDetailClient(
                        context,
                        product: product,
                        token: widget.token,
                      );
                      _refreshCartCount();
                    },
                    onAddToCart: () => _addToCart(product),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildVitaminsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Vitaminas y Suplementos',
                style: TextStyle(
                  color: AppColors.textDark,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              TextButton(
                onPressed: () => _openCatalog(category: 'Vitaminas'),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Explorar',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 270,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: _vitaminsProducts.length,
            separatorBuilder: (context, index) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final product = _vitaminsProducts[index];
              return SizedBox(
                width: 175,
                child: ProductCard(
                  product: product,
                  onTap: () async {
                    await AppNavigator.toProductDetailClient(
                      context,
                      product: product,
                      token: widget.token,
                    );
                    _refreshCartCount();
                  },
                  onAddToCart: () => _addToCart(product),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
