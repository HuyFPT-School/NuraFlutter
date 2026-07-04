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
import '../screens/staff/staff_home_screen.dart';
import '../screens/staff/staff_order_detail_screen.dart';
import '../screens/admin/admin_home_screen.dart';
import '../screens/order/my_orders_screen.dart';
import '../screens/order/order_detail_screen.dart';
import '../screens/staff/staff_create_product_screen.dart';

class AppRoutes {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String verifyOtp = '/verify-otp';
  static const String home = '/home';
  static const String staffHome = '/staff-home';
  static const String staffOrderDetail = '/staff-order-detail';
  static const String adminHome = '/admin-home';
  static const String productDetail = '/product-detail';
  static const String checkout = '/checkout';
  static const String paymentWebview = '/payment-webview';
  static const String storeMap = '/store-map';
  static const String myOrders = '/my-orders';
  static const String orderDetail = '/order-detail';
  static const String staffCreateProduct = '/staff-create-product';

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
      case staffHome:
        return MaterialPageRoute(builder: (_) => const StaffHomeScreen());
      case staffOrderDetail:
        final order = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => StaffOrderDetailScreen(order: order),
        );
      case adminHome:
        return MaterialPageRoute(builder: (_) => const AdminHomeScreen());
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
      case myOrders:
        return MaterialPageRoute(builder: (_) => const MyOrdersScreen());
      case orderDetail:
        final orderId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => OrderDetailScreen(orderId: orderId),
        );
      case staffCreateProduct:
        return MaterialPageRoute(
          builder: (_) => const StaffCreateProductScreen(),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('Route not found: ${settings.name}')),
          ),
        );
    }
  }
}
