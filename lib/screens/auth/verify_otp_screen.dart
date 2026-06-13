import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../config/routes.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';

class VerifyOtpScreen extends StatefulWidget {
  final String email;
  const VerifyOtpScreen({super.key, required this.email});
  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  int _countdown = 60;
  Timer? _timer;

  @override
  void initState() { super.initState(); _startTimer(); }

  void _startTimer() {
    _countdown = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_countdown > 0) { setState(() => _countdown--); } else { t.cancel(); }
    });
  }

  @override
  void dispose() { _timer?.cancel(); for (var c in _controllers) c.dispose(); for (var f in _focusNodes) f.dispose(); super.dispose(); }

  String get _otp => _controllers.map((c) => c.text).join();

  Future<void> _verify() async {
    if (_otp.length != 6) return;
    final auth = context.read<AuthProvider>();
    final success = await auth.verifyOtp(widget.email, _otp);
    if (!mounted) return;
    if (success) {
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (_) => false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error ?? 'Xác thực thất bại'), backgroundColor: AppColors.error),
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
            child: Column(
              children: [
                const SizedBox(height: 60),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
                  child: const Icon(Icons.mark_email_read_outlined, size: 48, color: AppColors.primary),
                ),
                const SizedBox(height: 24),
                const Text('Xác thực email', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                Text('Nhập mã OTP đã gửi đến\n${widget.email}',
                  textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                const SizedBox(height: 36),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(6, (i) => SizedBox(
                    width: 48, height: 56,
                    child: TextFormField(
                      controller: _controllers[i],
                      focusNode: _focusNodes[i],
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      inputFormatters: [LengthLimitingTextInputFormatter(1), FilteringTextInputFormatter.digitsOnly],
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                      decoration: InputDecoration(
                        filled: true, fillColor: AppColors.surface, counterText: '',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
                      ),
                      onChanged: (v) {
                        if (v.isNotEmpty && i < 5) _focusNodes[i + 1].requestFocus();
                        if (v.isEmpty && i > 0) _focusNodes[i - 1].requestFocus();
                        if (_otp.length == 6) _verify();
                      },
                    ),
                  )),
                ),
                const SizedBox(height: 32),
                Consumer<AuthProvider>(
                  builder: (_, auth, __) => CustomButton(text: 'Xác nhận', isLoading: auth.isLoading, onPressed: _verify),
                ),
                const SizedBox(height: 16),
                _countdown > 0
                  ? Text('Gửi lại mã sau $_countdown giây', style: const TextStyle(color: AppColors.textSecondary))
                  : TextButton(onPressed: _startTimer, child: const Text('Gửi lại mã', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
