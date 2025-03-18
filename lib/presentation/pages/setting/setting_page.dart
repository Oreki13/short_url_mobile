import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:short_url_mobile/core/constant/route_constant.dart';
import 'package:short_url_mobile/core/theme/app_color.dart';
import 'package:short_url_mobile/core/theme/app_dimension.dart';
import 'package:short_url_mobile/core/theme/app_text.dart';
import 'package:short_url_mobile/domain/repositories/auth_repository.dart';
import 'package:short_url_mobile/dependency.dart' as di;

class SettingPage extends StatelessWidget {
  const SettingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), elevation: 0),
      body: Padding(
        padding: const EdgeInsets.all(AppDimensions.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Spacer(),
            // Logout Button
            ElevatedButton.icon(
              onPressed: () => _showLogoutConfirmationDialog(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(vertical: AppDimensions.md),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                ),
              ),
              icon: const Icon(Icons.logout_rounded),
              label: Text(
                'Logout',
                style: AppText.button.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            const Spacer(),
            // Version Info
            const Center(
              child: Text(
                'Version 1.0.0',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
            const SizedBox(height: AppDimensions.md),
          ],
        ),
      ),
    );
  }

  // Show logout confirmation dialog
  Future<void> _showLogoutConfirmationDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout Confirmation'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                'Logout',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ],
        );
      },
    );

    if (result == true) {
      _handleLogout(context);
    }
  }

  // Handle logout action
  Future<void> _handleLogout(BuildContext context) async {
    try {
      // Show loading dialog
      _showLoadingDialog(context);

      // Get auth repository from dependency injection
      final authRepository = di.sl<AuthRepository>();

      // Perform logout
      await authRepository.logout();

      // Close loading dialog
      context.pop();

      // Navigate to login screen
      if (context.mounted) {
        context.go(RouteConstants.login);
      }
    } catch (e) {
      // Close loading dialog
      context.pop();

      // Show error message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error during logout: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Show loading dialog
  void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('Logging out...'),
            ],
          ),
        );
      },
    );
  }
}
