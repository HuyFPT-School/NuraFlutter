import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../config/app_theme.dart';
import '../../config/routes.dart';

/// Màn hình hiển thị WebView để người dùng thanh toán online
/// (VNPay, MoMo, ...) thông qua một URL do backend cung cấp.
class PaymentWebviewScreen extends StatefulWidget {
  final String url; // URL trang thanh toán (do backend trả về)
  const PaymentWebviewScreen({super.key, required this.url});

  @override
  State<PaymentWebviewScreen> createState() => _PaymentWebviewScreenState();
}

class _PaymentWebviewScreenState extends State<PaymentWebviewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true; // Cờ để show/hide loading spinner

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      // Cho phép JavaScript chạy không giới hạn trong WebView
      // (cần thiết vì các trang thanh toán VNPay/MoMo dùng JS)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)

      // Delegate để "nghe" các sự kiện điều hướng (navigation) của WebView
      ..setNavigationDelegate(NavigationDelegate(
        // Bắt đầu load 1 trang -> show loading
        onPageStarted: (_) => setState(() => _isLoading = true),
        // Load xong -> ẩn loading
        onPageFinished: (_) => setState(() => _isLoading = false),

        // Hàm này được gọi MỖI KHI WebView chuẩn bị điều hướng sang 1 URL mới.
        // Mình dùng nó để "chặn" và đọc URL redirect nhằm xác định
        // kết quả thanh toán thành công hay thất bại, thay vì để WebView
        // load thẳng trang kết quả.
        onNavigationRequest: (request) {
          final url = request.url.toLowerCase();

          // ------ TRƯỜNG HỢP 1: URL redirect có chứa "payment-result" ------
          // Đây là URL do BACKEND của mình tạo ra để redirect sau khi
          // cổng thanh toán xử lý xong (không phải URL gốc của VNPay/MoMo).
          if (url.contains('payment-result')) {

            // 1. Case VNPay: backend redirect kèm query param "status"
            if (url.contains('status=success')) {
              _showResult(true);
              return NavigationDecision.prevent; // Chặn không cho WebView load tiếp
            } else if (url.contains('status=error') || url.contains('status=failed')) {
              _showResult(false);
              return NavigationDecision.prevent;
            }

            // 2. Case MoMo: kiểm tra qua "resultCode"
            // Lưu ý: đoạn check "resultcode=0" nhưng loại trừ "00" và "000"
            // là để tránh nhầm "resultcode=0" (thành công) với các mã
            // resultcode khác bắt đầu bằng số 0 (ví dụ 00, 000 - đều là lỗi)
            if (url.contains('resultcode=0') && !url.contains('resultcode=00') && !url.contains('resultcode=000')) {
              _showResult(true);
              return NavigationDecision.prevent;
            } else if (url.contains('resultcode=')) {
              // Có resultcode nhưng không phải case thành công ở trên -> thất bại
              _showResult(false);
              return NavigationDecision.prevent;
            }

            // Fallback: nếu URL "payment-result" không khớp 2 case trên,
            // thì check chung chung theo từ khóa "success"
            if (url.contains('success')) {
              _showResult(true);
              return NavigationDecision.prevent;
            } else {
              // Không có "success" -> coi như thất bại
              _showResult(false);
              return NavigationDecision.prevent;
            }
          }

          // ------ TRƯỜNG HỢP 2: URL không chứa "payment-result" ------
          // Check thêm phòng khi cổng thanh toán redirect thẳng
          // (không qua backend) với từ khóa success/failed/cancel trong URL
          if (url.contains('success')) {
            _showResult(true);
            return NavigationDecision.prevent;
          }
          if (url.contains('failed') || url.contains('cancel')) {
            _showResult(false);
            return NavigationDecision.prevent;
          }

          // Không match trường hợp nào -> cho WebView load bình thường
          return NavigationDecision.navigate;
        },
      ))
      // Load URL thanh toán ban đầu (widget.url) vào WebView
      ..loadRequest(Uri.parse(widget.url));
  }

  /// Hiển thị dialog thông báo kết quả thanh toán (thành công/thất bại).
  /// barrierDismissible: false -> bắt buộc bấm nút OK, không tap ra ngoài để tắt.
  void _showResult(bool success) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text(success ? 'Thanh toán thành công! 🎉' : 'Thanh toán thất bại'),
        content: Text(success
            ? 'Đơn hàng của bạn đã được xác nhận.'
            : 'Vui lòng thử lại hoặc chọn phương thức khác.'),
        actions: [
          TextButton(
            // Bấm OK -> quay về màn hình Home, xóa hết stack điều hướng cũ
            onPressed: () => Navigator.pushNamedAndRemoveUntil(
                context, AppRoutes.home, (_) => false),
            child: const Text('OK'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thanh toán trực tuyến'),
        // Nút X để đóng màn hình thanh toán, quay lại màn trước đó
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // WebView chiếm toàn bộ màn hình
          Positioned.fill(
            child: WebViewWidget(controller: _controller),
          ),
          // Overlay loading spinner khi trang đang tải
          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        ],
      ),
    );
  }
}