import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../config/app_theme.dart';
import '../../providers/product_provider.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/loading_widget.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});
  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final _pageController = PageController();
  int _quantity = 1;
  bool _descExpanded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadProductDetail(widget.productId);
    });
  }

  @override
  void dispose() { _pageController.dispose(); super.dispose(); }

  String _formatVND(double price) {
    return '${NumberFormat('#,###', 'vi_VN').format(price).replaceAll(',', '.')}₫';
  }

  String _timeAgo(DateTime? date) {
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    if (diff.inDays < 30) return '${diff.inDays} ngày trước';
    return DateFormat('dd/MM/yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Consumer<ProductProvider>(
        builder: (_, provider, __) {
          final product = provider.selectedProduct;
          if (provider.isLoading || product == null) {
            return const LoadingWidget();
          }

          final maxQty = product.isOutOfStock ? product.maxPreOrderQuantity : product.quantity;

          return Stack(
            children: [
              CustomScrollView(
                slivers: [
                  SliverAppBar(
                    expandedHeight: 350,
                    pinned: true,
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.textPrimary,
                    flexibleSpace: FlexibleSpaceBar(
                      background: Stack(
                        children: [
                          PageView.builder(
                            controller: _pageController,
                            itemCount: product.imageUrl.length,
                            itemBuilder: (_, i) => Hero(
                              tag: i == 0 ? 'product-${product.id}' : 'product-img-$i',
                              child: CachedNetworkImage(
                                imageUrl: product.imageUrl[i],
                                fit: BoxFit.cover, width: double.infinity,
                                placeholder: (_, __) => Container(color: AppColors.surface),
                                errorWidget: (_, __, ___) => Container(
                                  color: AppColors.surface,
                                  child: const Icon(Icons.image_not_supported, size: 48, color: AppColors.textSecondary),
                                ),
                              ),
                            ),
                          ),
                          if (product.imageUrl.length > 1)
                            Positioned(
                              bottom: 16, left: 0, right: 0,
                              child: Center(
                                child: SmoothPageIndicator(
                                  controller: _pageController,
                                  count: product.imageUrl.length,
                                  effect: const WormEffect(
                                    dotHeight: 8, dotWidth: 8,
                                    activeDotColor: AppColors.primary,
                                    dotColor: Colors.white70,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(product.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 8),
                          Row(children: [
                            if (product.brandName.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(8)),
                                child: Text(product.brandName, style: const TextStyle(fontSize: 12, color: AppColors.primary)),
                              ),
                            const SizedBox(width: 8),
                            if (product.categoryName.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8)),
                                child: Text(product.categoryName, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                              ),
                          ]),
                          const SizedBox(height: 12),
                          Text(_formatVND(product.price), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.primary)),
                          const SizedBox(height: 8),
                          if (product.comments != null && product.comments!.isNotEmpty)
                            Row(children: [
                              ...List.generate(5, (i) => Icon(
                                i < product.averageRating.round() ? Icons.star : Icons.star_border,
                                size: 18, color: AppColors.warning,
                              )),
                              const SizedBox(width: 6),
                              Text('${product.averageRating.toStringAsFixed(1)} (${product.comments!.length} đánh giá)',
                                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                            ]),
                          if (product.canPreOrder) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: AppColors.warning.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                              child: Row(children: [
                                const Icon(Icons.schedule, color: AppColors.warning, size: 20),
                                const SizedBox(width: 8),
                                Expanded(child: Text(
                                  'Sản phẩm đặt trước${product.expectedRestockDate != null ? ' - Dự kiến: ${DateFormat('dd/MM/yyyy').format(product.expectedRestockDate!)}' : ''}',
                                  style: const TextStyle(fontSize: 13, color: AppColors.warning, fontWeight: FontWeight.w500),
                                )),
                              ]),
                            ),
                          ],
                          if (product.isOutOfStock && !product.allowPreOrder) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: Colors.grey.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                              child: const Row(children: [
                                Icon(Icons.remove_shopping_cart, color: Colors.grey, size: 20),
                                SizedBox(width: 8),
                                Text('Hết hàng', style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500)),
                              ]),
                            ),
                          ],

                          // Description
                          if (product.description != null && product.description!.isNotEmpty) ...[
                            const SizedBox(height: 20),
                            const Text('Mô tả sản phẩm', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            Text(product.description!,
                              maxLines: _descExpanded ? null : 3,
                              overflow: _descExpanded ? null : TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.6),
                            ),
                            GestureDetector(
                              onTap: () => setState(() => _descExpanded = !_descExpanded),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Text(_descExpanded ? 'Thu gọn' : 'Xem thêm',
                                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w500)),
                              ),
                            ),
                          ],

                          // Product Details Table
                          const SizedBox(height: 20),
                          const Text('Thông tin chi tiết', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          _buildDetailTable(product),

                          // Reviews
                          if (product.comments != null && product.comments!.isNotEmpty) ...[
                            const SizedBox(height: 20),
                            Text('Đánh giá (${product.comments!.length})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            ...product.comments!.map((c) => Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    CircleAvatar(radius: 16, backgroundColor: AppColors.primaryLight,
                                      child: Text(c.authorName[0].toUpperCase(), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600))),
                                    const SizedBox(width: 8),
                                    Expanded(child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(c.authorName, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                                        Row(children: List.generate(5, (i) => Icon(
                                          i < c.rating ? Icons.star : Icons.star_border, size: 14, color: AppColors.warning))),
                                      ],
                                    )),
                                    Text(_timeAgo(c.createdAt), style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                  ]),
                                  const SizedBox(height: 8),
                                  Text(c.content, style: const TextStyle(fontSize: 13, height: 1.5)),
                                ],
                              ),
                            )),
                          ],
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Sticky Bottom Bar
              if (!product.isOutOfStock || product.allowPreOrder)
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: Container(
                    padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))],
                    ),
                    child: Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(12)),
                          child: Row(children: [
                            IconButton(icon: const Icon(Icons.remove, size: 20),
                              onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null),
                            SizedBox(width: 32, child: Text('$_quantity', textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
                            IconButton(icon: const Icon(Icons.add, size: 20),
                              onPressed: _quantity < maxQty ? () => setState(() => _quantity++) : null),
                          ]),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              context.read<CartProvider>().addToCart(product, quantity: _quantity);
                              Fluttertoast.showToast(msg: 'Đã thêm vào giỏ hàng', backgroundColor: AppColors.success);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary, foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: const Text('Thêm vào giỏ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          ),
                        ),
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

  Widget _buildDetailTable(product) {
    final details = <MapEntry<String, String>>[
      if (product.manufacturer != null) MapEntry('Thương hiệu', product.manufacturer!),
      if (product.manufacture != null) MapEntry('Xuất xứ', product.manufacture!),
      if (product.weight != null) MapEntry('Trọng lượng', '${product.weight}g'),
      if (product.appropriateAge != null) MapEntry('Độ tuổi phù hợp', product.appropriateAge!),
      if (product.expiry != null) MapEntry('Hạn sử dụng', product.expiry!),
      if (product.storageInstructions != null) MapEntry('Bảo quản', product.storageInstructions!),
      if (product.instructionsForUse != null) MapEntry('Hướng dẫn sử dụng', product.instructionsForUse!),
      if (product.warning != null) MapEntry('Cảnh báo', product.warning!),
    ];
    if (details.isEmpty) return const Text('Chưa có thông tin', style: TextStyle(color: AppColors.textSecondary, fontSize: 13));
    return Table(
      columnWidths: const {0: FlexColumnWidth(2), 1: FlexColumnWidth(3)},
      border: TableBorder.all(color: AppColors.border, borderRadius: BorderRadius.circular(8)),
      children: details.map((e) => TableRow(children: [
        Padding(padding: const EdgeInsets.all(10), child: Text(e.key, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
        Padding(padding: const EdgeInsets.all(10), child: Text(e.value, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary))),
      ])).toList(),
    );
  }
}
