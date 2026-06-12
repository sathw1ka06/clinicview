import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/colors.dart';
import '../../core/constants.dart';
import '../../core/responsive.dart';
import '../../providers/app_provider.dart';

class MainScreen extends StatelessWidget {
  final Widget child;

  const MainScreen({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final bool isMobile = Responsive.isMobile(context);
    final user = context.watch<AppProvider>().currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      // --- MOBILE APP BAR ---
      appBar: isMobile
          ? AppBar(
              backgroundColor: AppColors.surface,
              elevation: 0,
              title: Image.asset(AppConstants.logoPath, height: 24),
              actions: [
                Container(
                  constraints: const BoxConstraints(
                    maxWidth: 150,
                  ), // Prevents long emails from overflowing
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  alignment: Alignment.centerRight,
                  child: Text(
                    user?.email ?? '',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow
                        .ellipsis, // Adds '...' if the email is too long
                  ),
                ),
              ],
            )
          : null,
      body: Row(
        children: [
          // --- DESKTOP SIDEBAR ---
          if (!isMobile) ...[
            _buildSidebar(context),
            const VerticalDivider(
              thickness: 1,
              width: 1,
              color: AppColors.borderLight,
            ),
          ],
          Expanded(child: child),
        ],
      ),
      // --- MOBILE BOTTOM NAV ---
      bottomNavigationBar: isMobile ? _buildBottomNav(context) : null,
    );
  }

  Widget _buildSidebar(BuildContext context) {
    final int selectedIndex = _calculateSelectedIndex(context);
    final user = context.watch<AppProvider>().currentUser;

    return Container(
      width: 250,
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 8.0,
              vertical: 16.0,
            ),
            child: Image.asset(AppConstants.logoPath, height: 32),
          ),
          const SizedBox(height: 32),
          _SidebarItem(
            icon: Icons.home_filled,
            label: 'Home',
            isSelected: selectedIndex == 0,
            onTap: () => context.go('/home'),
          ),
          const SizedBox(height: 8),
          _SidebarItem(
            icon: Icons.upload_file,
            label: 'Workspace',
            isSelected: selectedIndex == 1,
            onTap: () {
              context.read<AppProvider>().clearWorkspace();
              context.go('/upload');
            },
          ),
          const SizedBox(height: 8),
          _SidebarItem(
            icon: Icons.person,
            label: 'Profile',
            isSelected: selectedIndex == 2,
            onTap: () => context.go('/profile'),
          ),
          const Spacer(),
          const Divider(color: AppColors.borderLight),
          const SizedBox(height: 16),
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primaryButton,
                child: Text(
                  user?.firstName.isNotEmpty == true
                      ? user!.firstName[0].toUpperCase()
                      : 'U',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${user?.firstName ?? ''} ${user?.lastName ?? ''}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      user?.email ?? '',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return NavigationBar(
      selectedIndex: _calculateSelectedIndex(context),
      onDestinationSelected: (int index) {
        if (index == 0) context.go('/home');
        if (index == 1) {
          context.read<AppProvider>().clearWorkspace();
          context.go('/upload');
        }
        if (index == 2) context.go('/profile');
      },
      backgroundColor: AppColors.surface,
      indicatorColor: AppColors.focusBorder.withValues(alpha: 0.3),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_filled),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.upload_file_outlined),
          selectedIcon: Icon(Icons.upload_file),
          label: 'Workspace',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }

  static int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/upload')) return 1;
    if (location.startsWith('/profile')) return 2;
    return 0;
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.background : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.focusBorder : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? AppColors.primaryButton
                  : AppColors.textSecondary,
              size: 20,
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? AppColors.primaryButton
                    : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
