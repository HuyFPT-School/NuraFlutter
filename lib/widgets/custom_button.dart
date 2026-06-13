import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final Color? color;
  final double? width;

  const CustomButton({
    super.key, required this.text, this.onPressed, this.isLoading = false,
    this.isOutlined = false, this.color, this.width,
  });

  @override
  Widget build(BuildContext context) {
    final btnColor = color ?? AppColors.primary;
    if (isOutlined) {
      return SizedBox(
        width: width ?? double.infinity,
        height: 52,
        child: OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: btnColor),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.borderRadius)),
          ),
          child: isLoading
            ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: btnColor))
            : Text(text, style: TextStyle(color: btnColor, fontSize: 16, fontWeight: FontWeight.w600)),
        ),
      );
    }
    return SizedBox(
      width: width ?? double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: btnColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.borderRadius)),
        ),
        child: isLoading
          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
