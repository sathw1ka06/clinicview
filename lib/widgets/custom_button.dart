import 'package:flutter/material.dart';
import '../core/colors.dart';
import '../core/constants.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool isOutlined;
  final double? width; // Now allows null (flexible width)
  final IconData? icon; 

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.width = double.infinity, // Still defaults to full width unless specified
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 48,
      child: isOutlined
          ? OutlinedButton(
              onPressed: isLoading ? null : onPressed,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.borderLight),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.buttonRadius),
                ),
              ),
              child: _buildChild(context, Colors.black87),
            )
          : ElevatedButton(
              onPressed: isLoading ? null : onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryButton,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.buttonRadius),
                ),
              ),
              child: _buildChild(context, Colors.white),
            ),
    );
  }

  Widget _buildChild(BuildContext context, Color textColor) {
    if (isLoading) {
      return SizedBox(
          height: 20, width: 20, 
          child: CircularProgressIndicator(color: textColor, strokeWidth: 2));
    }
    
    if (icon != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min, // Ensures it doesn't force expansion
        children: [
          Icon(icon, color: textColor, size: 20),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: textColor)),
        ],
      );
    }

    return Text(text, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: textColor));
  }
}