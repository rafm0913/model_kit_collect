import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// 統計頁面（待實作）
class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('統計', style: AppTypography.title.copyWith(color: AppColors.textPrimary)),
        backgroundColor: AppColors.cardBackground,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart, size: 80, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text(
              '統計功能開發中',
              style: AppTypography.subtitle.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
