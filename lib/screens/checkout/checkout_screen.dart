import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import '../../config/app_theme.dart';
import '../../config/routes.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/checkout_service.dart';
import '../../services/api_client.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

/// Màn hình Checkout: nhập thông tin giao hàng, áp voucher,
/// chọn phương thức thanh toán và đặt hàng.
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});
  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>(); // Key để validate Form
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _noteController = TextEditingController();
  final _voucherController = TextEditingController();
  final _checkoutService = CheckoutService(); // Service gọi API checkout/voucher

  String _paymentMethod = 'cod'; // Mặc định: thanh toán khi nhận hàng (COD)
  bool _isLoading = false; // Trạng thái loading khi đặt hàng
  double _discount = 0; // Số tiền được giảm từ voucher
  String? _voucherError; // Thông báo lỗi khi áp voucher sai
  String? _appliedVoucher; // Mã voucher đã áp dụng thành công (null nếu chưa có)

  @override
  void initState() {
    super.initState();
    try {
      // Nếu user đã đăng nhập -> tự động điền sẵn SĐT/địa chỉ đã lưu trong hồ sơ
      final auth = context.read<AuthProvider>();
      if (auth.isAuthenticated && auth.user != null) {
        _phoneController.text = auth.user!.phone ?? '';
        _addressController.text = auth.user!.address ?? '';
      }
    } catch (e, s) {
      // Bọc try/catch để tránh crash toàn app nếu AuthProvider lỗi
      debugPrint('Error in CheckoutScreen initState: $e\n$s');
    }
  }

  @override
  void dispose() {
    // Dọn dẹp các controller khi widget bị huỷ, tránh memory leak
    _addressController.dispose();
    _phoneController.dispose();
    _noteController.dispose();
    _voucherController.dispose();
    super.dispose();
  }

  // Format số tiền theo kiểu Việt Nam: 1.000.000₫ (dùng dấu chấm phân cách)
  String _formatVND(double price) =>
      '${NumberFormat('#,###', 'vi_VN').format(price).replaceAll(',', '.')}₫';

  /// Gọi API kiểm tra & áp dụng mã voucher
  Future<void> _applyVoucher() async {
    final code = _voucherController.text.trim();
    if (code.isEmpty) return; // Không làm gì nếu ô nhập trống

    final cart = context.read<CartProvider>();
    try {
      // Gửi mã voucher + tổng tiền giỏ hàng lên backend để validate
      final data = await _checkoutService.validateVoucher(code, cart.totalPrice);
      setState(() {
        // Backend có thể trả về số tiền giảm cố định (discountAmount)
        // hoặc phần trăm giảm (discountPercentage) -> ưu tiên discountAmount trước
        _discount = (data['discountAmount'] as num?)?.toDouble() ??
            (data['discountPercentage'] as num?)?.toDouble() ??
            0;
        _appliedVoucher = code;
        _voucherError = null;
      });
    } on DioException catch (e) {
      // Lỗi từ API (network/response) -> lấy message thân thiện qua ApiClient
      setState(() {
        _voucherError = ApiClient.getErrorMessage(e);
        _discount = 0;
        _appliedVoucher = null;
      });
    } catch (_) {
      // Lỗi khác không xác định -> fallback thông báo chung
      setState(() {
        _voucherError = 'Voucher không hợp lệ';
        _discount = 0;
        _appliedVoucher = null;
      });
    }
  }

  /// Xử lý khi user bấm nút "Đặt hàng"
  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return; // Validate form trước
    final cart = context.read<CartProvider>();

    // Ràng buộc nghiệp vụ: đơn hàng phải >= 10.000đ
    if (cart.totalPrice < 10000) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Đơn hàng tối thiểu 10.000₫'), backgroundColor: AppColors.error));
      return;
    }
    // Ràng buộc nghiệp vụ: đơn hàng chỉ có sản phẩm đặt trước (pre-order)
    // thì không được thanh toán COD (bắt buộc phải thanh toán online)
    if (cart.hasOnlyPreOrder && _paymentMethod == 'cod') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Đơn hàng đặt trước không hỗ trợ COD'), backgroundColor: AppColors.error));
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Chuyển giỏ hàng thành danh sách {productId, quantity} để gửi lên API
      final cartItems = cart.cartItems
          .map((i) => {'productId': i.productId, 'quantity': i.quantity})
          .toList();

      final data = await _checkoutService.checkout(
        cartItems: cartItems,
        paymentMethod: _paymentMethod,
        voucherCode: _appliedVoucher,
        shippingAddress: _addressController.text.trim(),
        phone: _phoneController.text.trim(),
        note: _noteController.text.trim(),
      );

      if (!mounted) return; // Tránh gọi setState/context sau khi widget đã unmount
      cart.clearCart(); // Xoá giỏ hàng sau khi đặt hàng thành công

      // Backend có thể trả về "payUrl" hoặc "paymentUrl" tuỳ cổng thanh toán
      final payUrl = data['payUrl'] ?? data['paymentUrl'];
      if (payUrl != null && payUrl.toString().isNotEmpty) {
        // Nếu có URL thanh toán (MoMo/VNPay) -> điều hướng sang WebView thanh toán
        Navigator.pushReplacementNamed(context, AppRoutes.paymentWebview,
            arguments: payUrl.toString());
      } else {
        // Không có payUrl -> nghĩa là COD, đặt hàng xong luôn -> show dialog thành công
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            title: const Text('Đặt hàng thành công! 🎉'),
            content: const Text('Cảm ơn bạn đã đặt hàng. Đơn hàng sẽ được xử lý sớm nhất.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pushNamedAndRemoveUntil(
                    context, AppRoutes.home, (_) => false),
                child: const Text('OK'),
              )
            ],
          ),
        );
      }
    } on DioException catch (e) {
      // Lỗi gọi API checkout -> hiển thị message lỗi cụ thể
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(ApiClient.getErrorMessage(e)), backgroundColor: AppColors.error));
      }
    } catch (e) {
      // Lỗi không xác định khác -> thông báo chung
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã xảy ra lỗi'), backgroundColor: AppColors.error));
      }
    }
    if (mounted) setState(() => _isLoading = false); // Tắt loading dù thành công hay lỗi
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thanh toán')),
      // Lắng nghe CartProvider để hiển thị giỏ hàng realtime
      body: Consumer<CartProvider>(
        builder: (context, cart, _) {
          try {
            return Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ---------- PHẦN THÔNG TIN GIAO HÀNG ----------
                    const Text('Thông tin giao hàng',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    CustomTextField(
                        controller: _addressController,
                        label: 'Địa chỉ giao hàng',
                        hint: 'Nhập địa chỉ',
                        prefixIcon: const Icon(Icons.location_on_outlined, color: AppColors.textSecondary),
                        validator: (v) => v == null || v.isEmpty ? 'Vui lòng nhập địa chỉ' : null),
                    const SizedBox(height: 12),
                    CustomTextField(
                        controller: _phoneController,
                        label: 'Số điện thoại',
                        hint: 'Nhập số điện thoại',
                        keyboardType: TextInputType.phone,
                        prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.textSecondary),
                        validator: (v) => v == null || v.isEmpty ? 'Vui lòng nhập số điện thoại' : null),
                    const SizedBox(height: 12),
                    CustomTextField(
                        controller: _noteController,
                        label: 'Ghi chú',
                        hint: 'Ghi chú cho đơn hàng (tùy chọn)',
                        maxLines: 2,
                        prefixIcon: const Icon(Icons.note_outlined, color: AppColors.textSecondary)),

                    // ---------- PHẦN MÃ GIẢM GIÁ (VOUCHER) ----------
                    const SizedBox(height: 24),
                    const Text('Mã giảm giá',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(
                          child: CustomTextField(
                              controller: _voucherController,
                              hint: 'Nhập mã voucher',
                              // Khoá ô nhập lại khi đã áp dụng voucher thành công
                              enabled: _appliedVoucher == null)),
                      const SizedBox(width: 8),
                      // Nếu đã áp voucher -> hiện nút "x" để gỡ voucher
                      // Nếu chưa -> hiện nút "Áp dụng" để gọi _applyVoucher()
                      _appliedVoucher != null
                          ? IconButton(
                              icon: const Icon(Icons.close, color: AppColors.error),
                              onPressed: () => setState(() {
                                    _appliedVoucher = null;
                                    _discount = 0;
                                    _voucherController.clear();
                                  }))
                          : ElevatedButton(
                              onPressed: _applyVoucher,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                minimumSize: const Size(0, 52),
                              ),
                              child: const Text('Áp dụng', style: TextStyle(color: Colors.white))),
                    ]),
                    // Hiển thị lỗi voucher (nếu có)
                    if (_voucherError != null)
                      Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(_voucherError!,
                              style: const TextStyle(color: AppColors.error, fontSize: 12))),
                    // Hiển thị thông báo đã áp voucher thành công (nếu có)
                    if (_appliedVoucher != null)
                      Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text('Đã áp dụng mã: $_appliedVoucher ✓',
                              style: const TextStyle(color: AppColors.success, fontSize: 12))),

                    // ---------- PHẦN PHƯƠNG THỨC THANH TOÁN ----------
                    const SizedBox(height: 24),
                    const Text('Phương thức thanh toán',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    _buildPaymentOption('cod', 'Thanh toán khi nhận hàng', Icons.money),
                    _buildPaymentOption('momo', 'Ví MoMo', Icons.account_balance_wallet),
                    _buildPaymentOption('vnpay', 'VNPay', Icons.credit_card),
                    // Cảnh báo nếu đơn hàng toàn sản phẩm pre-order nhưng đang chọn COD
                    if (cart.hasOnlyPreOrder && _paymentMethod == 'cod')
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            color: AppColors.warning.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12)),
                        child: const Row(children: [
                          Icon(Icons.warning_amber, color: AppColors.warning, size: 20),
                          SizedBox(width: 8),
                          Expanded(
                              child: Text(
                                  'Đơn hàng chỉ có sản phẩm đặt trước, vui lòng chọn thanh toán online',
                                  style: TextStyle(fontSize: 12, color: AppColors.warning))),
                        ]),
                      ),

                    // ---------- PHẦN CHI TIẾT ĐƠN HÀNG / TỔNG TIỀN ----------
                    const SizedBox(height: 24),
                    const Text('Chi tiết đơn hàng',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    // Liệt kê từng sản phẩm trong giỏ: tên x số lượng - giá
                    ...cart.cartItems.map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            Expanded(
                                child: Text('${item.name} x${item.quantity}',
                                    style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis)),
                            Text(_formatVND(item.totalPrice), style: const TextStyle(fontSize: 13)),
                          ]),
                        )),
                    const Divider(),
                    _summaryRow('Tạm tính', _formatVND(cart.totalPrice)),
                    _summaryRow('Phí vận chuyển',
                        cart.shippingFee == 0 ? 'Miễn phí' : _formatVND(cart.shippingFee)),
                    // Chỉ hiện dòng giảm giá nếu có discount > 0
                    if (_discount > 0) _summaryRow('Giảm giá', '-${_formatVND(_discount)}', isDiscount: true),
                    const Divider(),
                    // Tổng cộng = grandTotal (tạm tính + phí ship) - discount
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      const Text('Tổng cộng', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                      Text(_formatVND(cart.grandTotal - _discount),
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.primary)),
                    ]),
                    const SizedBox(height: 24),
                    // Nút đặt hàng, disable/hiện loading khi đang gọi API
                    CustomButton(text: 'Đặt hàng', isLoading: _isLoading, onPressed: _placeOrder),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            );
          } catch (e, s) {
            // "Error boundary" thủ công: nếu build UI phía trên bị lỗi (crash)
            // thì hiển thị màn hình lỗi kèm stack trace thay vì crash cả app.
            // Hữu ích khi debug, nhưng nên cân nhắc ẩn stack trace ở bản production.
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  const Text('Lỗi giao diện thanh toán:',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(e.toString(), style: const TextStyle(color: Colors.red, fontFamily: 'monospace')),
                  const SizedBox(height: 16),
                  const Text('Chi tiết lỗi:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(s.toString(),
                      style: const TextStyle(fontSize: 11, color: Colors.grey, fontFamily: 'monospace')),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  /// Widget con: 1 dòng radio button chọn phương thức thanh toán
  Widget _buildPaymentOption(String value, String label, IconData icon) {
    return RadioListTile<String>(
      value: value,
      groupValue: _paymentMethod,
      onChanged: (v) => setState(() => _paymentMethod = v!),
      title: Row(children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Text(label)
      ]),
      activeColor: AppColors.primary,
      contentPadding: EdgeInsets.zero,
    );
  }

  /// Widget con: 1 dòng label - value trong phần tóm tắt đơn hàng
  /// (isDiscount = true -> tô màu xanh success cho dòng giảm giá)
  Widget _summaryRow(String label, String value, {bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.w500, color: isDiscount ? AppColors.success : null))
        ],
      ),
    );
  }
}