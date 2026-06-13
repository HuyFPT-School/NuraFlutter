import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../config/app_theme.dart';
import '../../config/routes.dart';
import '../../providers/product_provider.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/product_card.dart';
import '../../widgets/empty_state_widget.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});
  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  bool _showSearch = false;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadProducts();
    });
  }

  @override
  void dispose() { _searchController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _showSearch
          ? TextField(
              controller: _searchController, autofocus: true,
              decoration: const InputDecoration(hintText: 'Tìm kiếm sản phẩm...', border: InputBorder.none, filled: false),
              onChanged: (q) => context.read<ProductProvider>().search(q),
            )
          : const Text('NURA', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 22, letterSpacing: 2)),
        actions: [
          IconButton(
            icon: Icon(_showSearch ? Icons.close : Icons.search),
            onPressed: () {
              setState(() { _showSearch = !_showSearch; if (!_showSearch) { _searchController.clear(); context.read<ProductProvider>().search(''); }});
            },
          ),
        ],
      ),
      body: Consumer<ProductProvider>(
        builder: (_, provider, __) {
          if (provider.isLoading && provider.products.isEmpty) return _buildShimmer();
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => provider.loadProducts(),
            child: Column(
              children: [
                SizedBox(
                  height: 50,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                        child: FilterChip(
                          label: const Text('Tất cả'),
                          selected: provider.selectedCategoryId == null,
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(color: provider.selectedCategoryId == null ? Colors.white : AppColors.textPrimary),
                          onSelected: (_) => provider.filterByCategory(null),
                        ),
                      ),
                      ...provider.categories.map((c) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                        child: FilterChip(
                          label: Text(c.name),
                          selected: provider.selectedCategoryId == c.id,
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(color: provider.selectedCategoryId == c.id ? Colors.white : AppColors.textPrimary),
                          onSelected: (_) => provider.filterByCategory(c.id),
                        ),
                      )),
                    ],
                  ),
                ),
                Expanded(
                  child: provider.products.isEmpty
                    ? const EmptyStateWidget(icon: Icons.inventory_2_outlined, title: 'Không tìm thấy sản phẩm')
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.62,
                        ),
                        itemCount: provider.products.length,
                        itemBuilder: (_, i) => ProductCard(
                          product: provider.products[i],
                          onTap: () => Navigator.pushNamed(context, AppRoutes.productDetail, arguments: provider.products[i].id),
                        ),
                      ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: Consumer<CartProvider>(
        builder: (_, cart, __) => cart.totalItems > 0
          ? FloatingActionButton(
              heroTag: null,
              onPressed: () {},
              child: badges.Badge(
                badgeContent: Text('${cart.totalItems}', style: const TextStyle(color: Colors.white, fontSize: 11)),
                child: const Icon(Icons.shopping_cart),
              ),
            )
          : const SizedBox(),
      ),
    );
  }

  Widget _buildShimmer() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.62),
      itemCount: 6,
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: Colors.grey[300]!, highlightColor: Colors.grey[100]!,
        child: Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14))),
      ),
    );
  }
}

class badges {
  static Widget Badge({required Widget badgeContent, required Widget child}) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(right: -6, top: -6, child: Container(
          padding: const EdgeInsets.all(4),
          decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
          child: badgeContent,
        )),
      ],
    );
  }
}
