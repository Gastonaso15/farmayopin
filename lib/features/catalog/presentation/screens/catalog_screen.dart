import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/widgets/brand_logo.dart';
import '../../../cart/data/models/cart_model.dart';
import '../../../cart/data/services/cart_service.dart';
import '../../../cart/presentation/screens/cart_screen.dart';
import '../../data/models/product_model.dart';
import '../../data/services/catalog_service.dart';
import '../widgets/category_chip.dart';
import '../widgets/product_card.dart';
import 'create_product_screen.dart';
import 'product_detail_screen.dart';

class CatalogScreen extends StatefulWidget {
  final CatalogService? catalogService;
  final String? token;

  const CatalogScreen({super.key, this.catalogService, this.token});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  late final CatalogService _catalogService;
  final CartService _cartService = CartService();
  final TextEditingController _searchController = TextEditingController();

  List<ProductModel> _allProducts = [];
  List<ProductModel> _filteredProducts = [];
  bool _isLoading = true;
  String _selectedCategory = 'Todos';
  int _cartItemCount = 0;
  int _selectedNavIndex = 1; // 1 = Catálogo

  final List<String> _categories = [
    'Todos',
    'Medicamentos',
    'Vitaminas',
    'Cuidado Personal',
  ];

  @override
  void initState() {
    super.initState();
    _catalogService = widget.catalogService ?? CatalogService();
    _loadProducts();
    _refreshCartCount();
    _searchController.addListener(_applyFilters);
  }

  Future<void> _refreshCartCount() async {
    try {
      final cart = await _cartService.getCarrito(token: widget.token);
      if (mounted) setState(() => _cartItemCount = cart.cantidadUnidades);
    } on CartException catch (_) {}
  }

  Future<void> _openCart() async {
    final cart = await Navigator.of(context).push<CartModel>(
      MaterialPageRoute(builder: (_) => CartScreen(token: widget.token)),
    );
    if (cart != null && mounted) {
      setState(() => _cartItemCount = cart.cantidadUnidades);
    } else {
      _refreshCartCount();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
    });

    final products = await _catalogService.getProductos(token: widget.token);

    if (mounted) {
      setState(() {
        _allProducts = products;
        _applyFilters();
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    final query = _searchController.text.toLowerCase().trim();

    setState(() {
      _filteredProducts = _allProducts.where((p) {
        final matchesCategory =
            _selectedCategory == 'Todos' ||
            p.categoria.toLowerCase() == _selectedCategory.toLowerCase();
        final matchesQuery =
            query.isEmpty ||
            p.nombre.toLowerCase().contains(query) ||
            p.detalle.toLowerCase().contains(query);
        return matchesCategory && matchesQuery;
      }).toList();
    });
  }

  void _onCategorySelected(String category) {
    setState(() {
      _selectedCategory = category;
      _applyFilters();
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header: Logo y Botón de Carrito con Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              color: Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const BrandLogo(iconSize: 32, fontSize: 22),
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'Crear Producto',
                        icon: const Icon(
                          Icons.add_circle_outline_rounded,
                          color: AppColors.primary,
                          size: 26,
                        ),
                        onPressed: () async {
                          final newProduct = await Navigator.of(context)
                              .push<ProductModel>(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      CreateProductScreen(token: widget.token),
                                ),
                              );
                          if (newProduct != null) {
                            _loadProducts();
                          }
                        },
                      ),
                      const SizedBox(width: 4),
                      _buildCartButton(),
                    ],
                  ),
                ],
              ),
            ),

            // Barra de búsqueda
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 14),
                    const Icon(
                      Icons.search_rounded,
                      size: 20,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(
                          color: AppColors.textDark,
                          fontSize: 15,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Buscar productos, medicamentos...',
                          hintStyle: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          isDense: true,
                        ),
                      ),
                    ),
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(
                          Icons.clear,
                          size: 18,
                          color: AppColors.textMuted,
                        ),
                        onPressed: () => _searchController.clear(),
                      ),
                  ],
                ),
              ),
            ),

            // Chips de Categorías (Scroll horizontal)
            SizedBox(
              height: 44,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  return CategoryChip(
                    label: cat,
                    isSelected: _selectedCategory == cat,
                    onTap: () => _onCategorySelected(cat),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),

            // Título de Sección
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Catálogo Completo',
                    style: TextStyle(
                      color: AppColors.textDark,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    '${_filteredProducts.length} productos',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Grilla de Productos
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    )
                  : _filteredProducts.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: _loadProducts,
                      child: GridView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 8,
                        ),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.65,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                        itemCount: _filteredProducts.length,
                        itemBuilder: (context, index) {
                          final product = _filteredProducts[index];
                          return ProductCard(
                            product: product,
                            onTap: () async {
                              final updated = await Navigator.of(context)
                                  .push<ProductModel>(
                                    MaterialPageRoute(
                                      builder: (_) => ProductDetailScreen(
                                        product: product,
                                        token: widget.token,
                                      ),
                                    ),
                                  );
                              if (updated != null) {
                                _loadProducts();
                              }
                            },
                            onAddToCart: () => _addToCart(product),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 56,
            color: AppColors.textSubtle.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 12),
          const Text(
            'No se encontraron productos',
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Prueba con otra búsqueda o categoría.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    final items = [
      {
        'icon': Icons.home_outlined,
        'activeIcon': Icons.home_rounded,
        'label': 'Inicio',
      },
      {
        'icon': Icons.grid_view_outlined,
        'activeIcon': Icons.grid_view_rounded,
        'label': 'Catálogo',
      },
      {
        'icon': Icons.shopping_cart_outlined,
        'activeIcon': Icons.shopping_cart_rounded,
        'label': 'Carrito',
      },
      {
        'icon': Icons.receipt_long_outlined,
        'activeIcon': Icons.receipt_long_rounded,
        'label': 'Historial',
      },
      {
        'icon': Icons.person_outline_rounded,
        'activeIcon': Icons.person_rounded,
        'label': 'Perfil',
      },
    ];

    return SafeArea(
      top: false,
      child: Container(
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.border, width: 1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(items.length, (index) {
            final isSelected = _selectedNavIndex == index;
            final isCart = index == 2;

            return InkWell(
              onTap: () {
                if (index == 2) {
                  _openCart();
                  return;
                }
                setState(() {
                  _selectedNavIndex = index;
                });
              },
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 56,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Icon(
                          isSelected
                              ? (items[index]['activeIcon'] as IconData)
                              : (items[index]['icon'] as IconData),
                          size: 22,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textMuted,
                        ),
                        if (isCart && _cartItemCount > 0)
                          Positioned(
                            right: -8,
                            top: -6,
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '$_cartItemCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      items[index]['label'] as String,
                      style: TextStyle(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textMuted,
                        fontSize: 10,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
