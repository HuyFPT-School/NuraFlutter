import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../providers/notification_provider.dart';
import '../../providers/cart_provider.dart';
import '../product/product_list_screen.dart';
import '../cart/cart_screen.dart';
import '../notification/notification_screen.dart';
import '../chat/ai_chat_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    ProductListScreen(),
    CartScreen(),
    AiChatScreen(),
    NotificationScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().loadUnreadCount();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Consumer2<CartProvider, NotificationProvider>(
        builder: (_, cart, notif, __) => BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          items: [
            const BottomNavigationBarItem(icon: Icon(Icons.storefront), label: 'Sản phẩm'),
            BottomNavigationBarItem(
              icon: _badgeIcon(Icons.shopping_cart_outlined, cart.totalItems),
              activeIcon: _badgeIcon(Icons.shopping_cart, cart.totalItems),
              label: 'Giỏ hàng',
            ),
            const BottomNavigationBarItem(icon: Icon(Icons.auto_awesome_outlined), activeIcon: Icon(Icons.auto_awesome), label: 'Tư vấn AI'),
            BottomNavigationBarItem(
              icon: _badgeIcon(Icons.notifications_outlined, notif.unreadCount),
              activeIcon: _badgeIcon(Icons.notifications, notif.unreadCount),
              label: 'Thông báo',
            ),
            const BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Cá nhân'),
          ],
        ),
      ),
    );
  }

  Widget _badgeIcon(IconData icon, int count) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon),
        if (count > 0) Positioned(
          right: -6, top: -4,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
            child: Text('$count', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
          ),
        ),
      ],
    );
  }
}
