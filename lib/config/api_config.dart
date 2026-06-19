class ApiConfig {
  static const String baseUrl = 'https://mom-baby-milk-server.vercel.app';

  // Auth
  static const String login = '/api/auth/login';
  static const String register = '/api/auth/register';
  static const String logout = '/api/auth/logout';
  static const String refreshToken = '/api/auth/token';
  static const String verifyEmail = '/api/auth/verify-email';
  static const String forgetPassword = '/api/auth/forget-password';
  static const String resetPassword = '/api/auth/reset-password';
  static const String changePassword = '/api/auth/change-password';
  static const String sendResetOtp = '/api/auth/send-reset-otp';

  // Products
  static const String products = '/api/product';
  static String productById(String id) => '/api/product/$id';
  static String productsByCategory(String id) => '/api/product/category/$id';
  static String productsByBrand(String id) => '/api/product/brand/$id';
  static String addComment(String id) => '/api/product/$id/comments';

  // Categories & Brands
  static const String categories = '/api/category';
  static const String brands = '/api/brand';

  // Checkout & Orders
  static const String checkout = '/api/checkout';
  static const String myOrders = '/api/orders/my-orders';
  static String orderById(String id) => '/api/orders/$id';
  static String cancelOrder(String id) => '/api/orders/$id/cancel';
  static String confirmDelivery(String id) => '/api/orders/$id/confirm-delivery';
  static String retryPayment(String id) => '/api/orders/$id/retry-payment';

  // Notifications
  static const String notifications = '/api/notifications';
  static const String unreadCount = '/api/notifications/unread-count';
  static String markRead(String id) => '/api/notifications/$id/read';
  static const String markAllRead = '/api/notifications/read-all';
  static String deleteNotification(String id) => '/api/notifications/$id';

  // Support/Chat
  static const String conversations = '/api/support/conversations';
  static String conversationById(String id) => '/api/support/conversations/$id';
  static String conversationMessages(String id) => '/api/support/conversations/$id/messages';

  // Vouchers
  static const String vouchers = '/api/voucher';
  static const String validateVoucher = '/api/voucher/validate';

  // Users
  static const String users = '/api/users';
  static const String myVouchers = '/api/users/my-vouchers';
  static String userById(String id) => '/api/users/$id';

  // Wishlist
  static const String wishlist = '/api/wishlist';

  // Staff endpoints
  static const String dashboardStats = '/api/orders/dashboard-stats';
  static String lowStockProducts(int threshold) => '/api/product?lowStock=true&threshold=$threshold';
  static const String allOrders = '/api/orders';
  static String updateOrderStatus(String id) => '/api/orders/$id/status';
  static String updatePaymentStatus(String id) => '/api/orders/$id/payment-status';

  // Admin endpoints
  static const String revenueSummary = '/api/analytics/revenue-summary';
  static const String ordersStats = '/api/analytics/orders-stats';
  static const String topProducts = '/api/analytics/top-products';
  static const String allUsers = '/api/users';
  static String createUserEndpoint = '/api/users';
  static String updateUserEndpoint(String id) => '/api/users/$id';
  static String deleteUserEndpoint(String id) => '/api/users/$id';
}
