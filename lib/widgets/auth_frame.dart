import 'package:flutter/material.dart';
import '../core/colors.dart';
import '../core/constants.dart';

class AuthFrame extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? bottomText;

  const AuthFrame({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
    this.bottomText,
  });

  @override
  Widget build(BuildContext context) {
    // Check if the screen is narrow (mobile)
    final bool isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topLeft,
            radius: 1.5,
            colors: [Color(0xFFFFF9E6), Color(0xFFF7F5F0), Color(0xFFEBE8E0)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 16.0,
                horizontal: 16.0,
              ),
              child: Container(
                width: double.infinity, // Let it fill the screen on mobile
                constraints: const BoxConstraints(
                  maxWidth: 520,
                ), // But never wider than 520 on desktop!
                padding: EdgeInsets.all(
                  isMobile ? 24.0 : 32.0,
                ), // Dynamic padding
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Image.asset(
                        AppConstants.logoPath,
                        height: 24,
                        errorBuilder: (c, e, s) => const Text(
                          'datafoundry.ai',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    if (title == 'Welcome back') ...[
                      const Text(
                        'CLINICAL WORKSPACE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],

                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],

                    const SizedBox(height: 24),
                    child,

                    if (bottomText != null) ...[
                      const SizedBox(height: 20),
                      bottomText!,
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
