import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../config/routes.dart';
import '../../providers/auth_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tài khoản'),
        elevation: 0,
      ),
      body: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          final user = auth.user;

          // Khi chưa đăng nhập, hiển thị lời mời đăng nhập/đăng ký thay cho thông tin tài khoản.
          if (user == null) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  CircleAvatar(
                    radius: 54,
                    backgroundColor: AppColors.surface,
                    child: const Icon(
                      Icons.person_outline,
                      size: 54,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Chào mừng bạn đến với NURA!',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Vui lòng đăng nhập hoặc đăng ký tài khoản để quản lý thông tin giao hàng, xem trạng thái đơn hàng và nhận các chương trình ưu đãi mới nhất từ NURA.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: () => Navigator.pushNamed(context, AppRoutes.login),
                    child: const Text('Đăng nhập'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => Navigator.pushNamed(context, AppRoutes.register),
                    child: const Text('Đăng ký tài khoản mới'),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          }

          // Tạo chữ cái viết tắt để làm avatar dự phòng khi người dùng chưa có ảnh đại diện.
          final initials = user.fullname.isNotEmpty
              ? user.fullname
                  .trim()
                  .split(' ')
                  .map((e) => e.isNotEmpty ? e[0].toUpperCase() : '')
                  .join()
              : 'U';
          final shortInitials = initials.length > 2 ? initials.substring(initials.length - 2) : initials;

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Khu vực đầu trang: avatar, trạng thái xác thực, tên, email và vai trò.
                const SizedBox(height: 10),
                Center(
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 54,
                        backgroundColor: AppColors.primaryLight,
                        backgroundImage: user.avatar != null && user.avatar!.isNotEmpty
                            ? NetworkImage(user.avatar!)
                            : null,
                        child: user.avatar == null || user.avatar!.isEmpty
                            ? Text(
                                shortInitials,
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              )
                            : null,
                      ),
                      if (user.isVerified)
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      user.fullname,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (user.role == 'Admin') ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'ADMIN',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 32),

                // Khối thông tin tài khoản lấy trực tiếp từ dữ liệu người dùng hiện tại.
                _buildSectionHeader('Thông tin tài khoản'),
                const SizedBox(height: 10),
                Container(
                  decoration: cardDecoration,
                  child: Column(
                    children: [
                      _buildInfoRow(
                        Icons.phone_android_outlined,
                        'Số điện thoại',
                        user.phone ?? 'Chưa cập nhật',
                      ),
                      const Divider(height: 1, indent: 56),
                      _buildInfoRow(
                        Icons.location_on_outlined,
                        'Địa chỉ nhận hàng',
                        user.address ?? 'Chưa cập nhật',
                      ),
                      const Divider(height: 1, indent: 56),
                      _buildInfoRow(
                        Icons.verified_user_outlined,
                        'Trạng thái tài khoản',
                        user.isVerified ? 'Đã xác thực' : 'Chưa xác thực',
                        trailingColor: user.isVerified ? AppColors.success : AppColors.warning,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Khối điều hướng nhanh đến các tiện ích liên quan đến tài khoản.
                _buildSectionHeader('Tiện ích & Ứng dụng'),
                const SizedBox(height: 10),
                Container(
                  decoration: cardDecoration,
                  child: Column(
                    children: [
                      _buildActionRow(
                        Icons.receipt_long_outlined,
                        'Đơn hàng của tôi',
                        () => Navigator.pushNamed(context, AppRoutes.myOrders),
                      ),
                      const Divider(height: 1, indent: 56),
                      _buildActionRow(
                        Icons.map_outlined,
                        'Bản đồ cửa hàng',
                        () => Navigator.pushNamed(context, AppRoutes.storeMap),
                      ),
                      const Divider(height: 1, indent: 56),
                      _buildActionRow(
                        Icons.info_outline,
                        'Về NURA',
                        () {
                          showAboutDialog(
                            context: context,
                            applicationName: 'NURA',
                            applicationVersion: '1.0.0',
                            applicationLegalese: '© 2026 NURA Baby & Mom Store',
                            applicationIcon: const Icon(
                              Icons.child_care,
                              color: AppColors.primary,
                              size: 40,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // Nút đăng xuất luôn yêu cầu xác nhận để tránh thao tác nhầm.
                OutlinedButton.icon(
                  onPressed: () => _confirmLogout(context, auth),
                  icon: const Icon(Icons.logout, color: AppColors.error),
                  label: const Text(
                    'Đăng xuất',
                    style: TextStyle(color: AppColors.error),
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                    side: const BorderSide(color: AppColors.error),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  // Tiêu đề nhỏ dùng để phân tách các nhóm nội dung trên trang profile.
  Widget _buildSectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  // Dòng hiển thị thông tin chỉ đọc như số điện thoại, địa chỉ hoặc trạng thái tài khoản.
  Widget _buildInfoRow(IconData icon, String label, String value, {Color? trailingColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: trailingColor ?? AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Dòng có thể bấm để điều hướng đến màn hình chức năng khác.
  Widget _buildActionRow(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // Hiển thị hộp thoại xác nhận trước khi gọi AuthProvider.logout và quay về màn đăng nhập.
  void _confirmLogout(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất khỏi tài khoản của mình?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              'Hủy',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await auth.logout();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.login,
                  (route) => false,
                );
              }
            },
            child: const Text(
              'Đăng xuất',
              style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
