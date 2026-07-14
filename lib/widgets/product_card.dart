import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../config/app_theme.dart';
import '../models/product_model.dart';

class ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback? onTap;

  const ProductCard({super.key, required this.product, this.onTap});

  String _formatVND(double price) {
    final formatted = NumberFormat('#,###', 'vi_VN').format(price);
    return '${formatted.replaceAll(',', '.')}₫';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: cardDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                      child: Hero(
                        tag: 'product-${product.id}',
                        child: CachedNetworkImage(
                          imageUrl: product.firstImage,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            color: AppColors.surface,
                            child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: AppColors.surface,
                            child: const Icon(Icons.image_not_supported, color: AppColors.textSecondary),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (product.canPreOrder)
                    Positioned(
                      top: 8, left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.warning, borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('Pre-Order', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  if (product.isOutOfStock && !product.allowPreOrder)
                    Positioned(
                      top: 8, left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey, borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('Hết hàng', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name,
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(product.brandName,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  Text(_formatVND(product.price),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primary),
                  ),
                  if (product.comments != null && product.comments!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 14, color: AppColors.warning),
                        const SizedBox(width: 3),
                        Text(product.averageRating.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                        Text(' (${product.comments!.length})',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
