import 'package:flutter/material.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/verify_otp_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/product/product_detail_screen.dart';
import '../screens/checkout/checkout_screen.dart';
import '../screens/checkout/payment_webview_screen.dart';
import '../screens/map/store_map_screen.dart';
import '../screens/splash_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String verifyOtp = '/verify-otp';
  static const String home = '/home';
  static const String productDetail = '/product-detail';
  static const String checkout = '/checkout';
  static const String paymentWebview = '/payment-webview';
  static const String storeMap = '/store-map';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case verifyOtp:
        final email = settings.arguments as String;
        return MaterialPageRoute(builder: (_) => VerifyOtpScreen(email: email));
      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case productDetail:
        final productId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => ProductDetailScreen(productId: productId),
        );
      case checkout:
        return MaterialPageRoute(builder: (_) => const CheckoutScreen());
      case paymentWebview:
        final url = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => PaymentWebviewScreen(url: url),
        );
      case storeMap:
        return MaterialPageRoute(builder: (_) => const StoreMapScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('Route not found: ${settings.name}')),
          ),
        );
    }
  }
}
