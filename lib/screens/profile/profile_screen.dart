import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/colors.dart';
import '../../providers/app_provider.dart';
import '../../widgets/custom_button.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppProvider>().currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 50),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borderLight),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))
            ]
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 60,
                backgroundColor: AppColors.primaryButton,
                child: Text(
                  user?.firstName.isNotEmpty == true ? user!.firstName[0] : 'U',
                  style: const TextStyle(fontSize: 48, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                '${user?.firstName ?? 'Unknown'} ${user?.lastName ?? ''}'.trim(),
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.textPrimary, letterSpacing: 0.5),
              ),
              const SizedBox(height: 8),
              Text(
                user?.email ?? 'No email provided',
                style: const TextStyle(fontSize: 16, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 50),
              CustomButton(
                text: 'Logout',
                width: 200,
                isOutlined: true,
                onPressed: () {
                  context.read<AppProvider>().logout();
                  context.go('/login'); 
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}