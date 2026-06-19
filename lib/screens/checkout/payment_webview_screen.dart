import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../config/app_theme.dart';
import '../../config/routes.dart';

class PaymentWebviewScreen extends StatefulWidget {
  final String url;
  const PaymentWebviewScreen({super.key, required this.url});
  @override
  State<PaymentWebviewScreen> createState() => _PaymentWebviewScreenState();
}

class _PaymentWebviewScreenState extends State<PaymentWebviewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) => setState(() => _isLoading = true),
        onPageFinished: (_) => setState(() => _isLoading = false),
        onNavigationRequest: (request) {
          final url = request.url.toLowerCase();
          
          if (url.contains('payment-result')) {
            // 1. For VNPay (redirected by our backend): check status parameter
            if (url.contains('status=success')) {
              _showResult(true);
              return NavigationDecision.prevent;
            } else if (url.contains('status=error') || url.contains('status=failed')) {
              _showResult(false);
              return NavigationDecision.prevent;
            }
            
            // 2. For MoMo: check resultCode parameter
            if (url.contains('resultcode=0') && !url.contains('resultcode=00') && !url.contains('resultcode=000')) {
              _showResult(true);
              return NavigationDecision.prevent;
            } else if (url.contains('resultcode=')) {
              _showResult(false);
              return NavigationDecision.prevent;
            }
            
            // Fallback for general payment result url
            if (url.contains('success')) {
              _showResult(true);
              return NavigationDecision.prevent;
            } else {
              _showResult(false);
              return NavigationDecision.prevent;
            }
          }
          
          if (url.contains('success')) {
            _showResult(true);
            return NavigationDecision.prevent;
          }
          if (url.contains('failed') || url.contains('cancel')) {
            _showResult(false);
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
      ))
      ..loadRequest(Uri.parse(widget.url));
  }

  void _showResult(bool success) {
    showDialog(
      context: context, barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text(success ? 'Thanh toán thành công! 🎉' : 'Thanh toán thất bại'),
        content: Text(success ? 'Đơn hàng của bạn đã được xác nhận.' : 'Vui lòng thử lại hoặc chọn phương thức khác.'),
        actions: [TextButton(
          onPressed: () => Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (_) => false),
          child: const Text('OK'),
        )],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thanh toán trực tuyến'),
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: WebViewWidget(controller: _controller),
          ),
          if (_isLoading) const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        ],
      ),
    );
  }
}
