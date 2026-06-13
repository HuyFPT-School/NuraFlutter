import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../config/app_theme.dart';
import '../../config/routes.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/empty_state_widget.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  String _formatVND(double price) {
    return '${NumberFormat('#,###', 'vi_VN').format(price).replaceAll(',', '.')}₫';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Giỏ hàng'),
        actions: [
          Consumer<CartProvider>(
            builder: (_, cart, __) => cart.cartItems.isNotEmpty
              ? IconButton(icon: const Icon(Icons.delete_outline, color: AppColors.error),
                  onPressed: () => showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Xóa giỏ hàng'),
                      content: const Text('Bạn có chắc muốn xóa tất cả sản phẩm?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
                        TextButton(onPressed: () { cart.clearCart(); Navigator.pop(context); },
                          child: const Text('Xóa', style: TextStyle(color: AppColors.error))),
                      ],
                    ),
                  ))
              : const SizedBox(),
          ),
        ],
      ),
      body: Consumer<CartProvider>(
        builder: (_, cart, __) {
          if (cart.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.shopping_cart_outlined,
              title: 'Giỏ hàng trống',
              subtitle: 'Hãy thêm sản phẩm vào giỏ hàng',
            );
          }
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: cart.cartItems.length,
                  itemBuilder: (_, i) {
                    final item = cart.cartItems[i];
                    return Dismissible(
                      key: Key(item.productId),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(color: AppColors.error.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
                        child: const Icon(Icons.delete, color: AppColors.error),
                      ),
                      onDismissed: (_) => cart.removeFromCart(item.productId),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: cardDecoration,
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: CachedNetworkImage(
                                imageUrl: item.imageUrl ?? '',
                                width: 80, height: 80, fit: BoxFit.cover,
                                errorWidget: (_, __, ___) => Container(width: 80, height: 80, color: AppColors.surface,
                                  child: const Icon(Icons.image, color: AppColors.textSecondary)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.name, maxLines: 2, overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                                  const SizedBox(height: 4),
                                  Text(_formatVND(item.effectivePrice),
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.primary)),
                                  if (item.isPreOrder)
                                    Container(
                                      margin: const EdgeInsets.only(top: 4),
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(color: AppColors.warning.withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
                                      child: const Text('Đặt trước', style: TextStyle(fontSize: 10, color: AppColors.warning, fontWeight: FontWeight.w600)),
                                    ),
                                ],
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(10)),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  InkWell(
                                    onTap: item.quantity > 1 ? () => cart.updateQuantity(item.productId, item.quantity - 1) : null,
                                    child: Padding(padding: const EdgeInsets.all(6), child: Icon(Icons.remove, size: 16,
                                      color: item.quantity > 1 ? AppColors.textPrimary : AppColors.border)),
                                  ),
                                  Padding(padding: const EdgeInsets.symmetric(horizontal: 8),
                                    child: Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.w600))),
                                  InkWell(
                                    onTap: item.quantity < item.availableStock ? () => cart.updateQuantity(item.productId, item.quantity + 1) : null,
                                    child: Padding(padding: const EdgeInsets.all(6), child: Icon(Icons.add, size: 16,
                                      color: item.quantity < item.availableStock ? AppColors.textPrimary : AppColors.border)),
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
              Container(
                padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).padding.bottom + 16),
                decoration: const BoxDecoration(color: Colors.white,
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))]),
                child: Column(
                  children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      const Text('Tạm tính:', style: TextStyle(color: AppColors.textSecondary)),
                      Text(_formatVND(cart.totalPrice), style: const TextStyle(fontWeight: FontWeight.w500)),
                    ]),
                    const SizedBox(height: 6),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      const Text('Phí vận chuyển:', style: TextStyle(color: AppColors.textSecondary)),
                      Text(cart.shippingFee == 0 ? 'Miễn phí' : _formatVND(cart.shippingFee),
                        style: TextStyle(fontWeight: FontWeight.w500, color: cart.shippingFee == 0 ? AppColors.success : null)),
                    ]),
                    const Divider(height: 20),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      const Text('Tổng cộng:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      Text(_formatVND(cart.grandTotal), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.primary)),
                    ]),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity, height: 52,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pushNamed(context, AppRoutes.checkout),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                        child: Text('Thanh toán (${cart.totalItems})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
