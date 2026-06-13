import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../config/routes.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscure1 = true, _obscure2 = true;

  @override
  void dispose() { _nameController.dispose(); _emailController.dispose(); _passwordController.dispose(); _confirmController.dispose(); super.dispose(); }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final success = await auth.register(_emailController.text.trim(), _passwordController.text, _nameController.text.trim());
    if (!mounted) return;
    if (success) {
      Navigator.pushNamed(context, AppRoutes.verifyOtp, arguments: _emailController.text.trim());
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error ?? 'Đăng ký thất bại'), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [AppColors.primaryLight, Colors.white]),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  const Text('NURA', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w700, color: AppColors.primary, letterSpacing: 4)),
                  const SizedBox(height: 4),
                  const Text('Tạo tài khoản mới', style: TextStyle(fontSize: 16, color: AppColors.textSecondary)),
                  const SizedBox(height: 36),
                  CustomTextField(
                    controller: _nameController, label: 'Họ và tên', hint: 'Nhập họ và tên',
                    prefixIcon: const Icon(Icons.person_outlined, color: AppColors.textSecondary),
                    validator: (v) => v == null || v.isEmpty ? 'Vui lòng nhập họ tên' : null,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _emailController, label: 'Email', hint: 'Nhập email',
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: const Icon(Icons.email_outlined, color: AppColors.textSecondary),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Vui lòng nhập email';
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v)) return 'Email không hợp lệ';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _passwordController, label: 'Mật khẩu', hint: 'Nhập mật khẩu',
                    obscureText: _obscure1,
                    prefixIcon: const Icon(Icons.lock_outlined, color: AppColors.textSecondary),
                    suffixIcon: IconButton(icon: Icon(_obscure1 ? Icons.visibility_off : Icons.visibility, color: AppColors.textSecondary), onPressed: () => setState(() => _obscure1 = !_obscure1)),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Vui lòng nhập mật khẩu';
                      if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{8,30}$').hasMatch(v)) return 'Mật khẩu phải có 8-30 ký tự, gồm chữ hoa, chữ thường và số';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _confirmController, label: 'Xác nhận mật khẩu', hint: 'Nhập lại mật khẩu',
                    obscureText: _obscure2,
                    prefixIcon: const Icon(Icons.lock_outlined, color: AppColors.textSecondary),
                    suffixIcon: IconButton(icon: Icon(_obscure2 ? Icons.visibility_off : Icons.visibility, color: AppColors.textSecondary), onPressed: () => setState(() => _obscure2 = !_obscure2)),
                    validator: (v) {
                      if (v != _passwordController.text) return 'Mật khẩu không khớp';
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  Consumer<AuthProvider>(
                    builder: (_, auth, __) => CustomButton(text: 'Đăng ký', isLoading: auth.isLoading, onPressed: _register),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Đã có tài khoản? ', style: TextStyle(color: AppColors.textSecondary)),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Text('Đăng nhập', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
