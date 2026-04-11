import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

/// 系統設定頁面
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('系統設定', style: AppTypography.title.copyWith(color: AppColors.textPrimary)),
        backgroundColor: AppColors.cardBackground,
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.primary),
            title: Text('登出', style: AppTypography.body.copyWith(color: AppColors.textPrimary)),
            onTap: () => _signOut(context),
          ),
        ],
      ),
    );
  }

  Future<void> _signOut(BuildContext context) async {
    await AuthService().signOut();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }
}
