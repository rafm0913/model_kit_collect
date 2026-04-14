import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../services/network_service.dart';
import 'add_edit_screen.dart';
import 'home_screen.dart';
import 'statistics_screen.dart';
import 'settings_screen.dart';

/// 主畫面殼層，含底部導覽列
/// 左至右：收藏清單、統計、系統設定
/// 新增按鈕在右下角（僅收藏清單頁顯示）
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final NetworkService _networkService = NetworkService();
  int _selectedIndex = 0;
  final ValueNotifier<int> _refreshInventory = ValueNotifier(0);
  bool _hasInternet = true;
  Timer? _networkTimer;

  @override
  void initState() {
    super.initState();
    _refreshNetworkStatus();
    _networkTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _refreshNetworkStatus();
    });
  }

  void _onAddTap() async {
    final hasInternet = await _networkService.hasInternetAccess();
    if (!mounted) return;
    if (!hasInternet) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('目前沒有網路，無法新增收藏。')),
      );
      return;
    }

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const AddEditScreen()),
    );
    if (result == true && mounted) {
      _refreshInventory.value++;
    }
  }

  @override
  void dispose() {
    _networkTimer?.cancel();
    _refreshInventory.dispose();
    super.dispose();
  }

  Future<void> _refreshNetworkStatus() async {
    final hasInternet = await _networkService.hasInternetAccess();
    if (!mounted || _hasInternet == hasInternet) return;
    setState(() => _hasInternet = hasInternet);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          HomeScreen(refreshTrigger: _refreshInventory),
          const StatisticsScreen(),
          const SettingsScreen(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton.extended(
              onPressed: _hasInternet ? _onAddTap : null,
              backgroundColor: _hasInternet
                  ? AppColors.primary
                  : AppColors.buttonBackground,
              icon: Icon(
                _hasInternet ? Icons.add : Icons.wifi_off_rounded,
                color: _hasInternet
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
              ),
              label: Text(
                _hasInternet ? 'Add' : 'Offline',
                style: AppTypography.bodySmall.copyWith(
                  color: _hasInternet
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                  fontWeight: AppTypography.weightBold,
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildBottomNav() {
    return Container(
      height: 80,
      color: AppColors.backgroundDark,
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(
              icon: Icons.inventory_2_outlined,
              activeIcon: Icons.inventory_2,
              isSelected: _selectedIndex == 0,
              onTap: () => setState(() => _selectedIndex = 0),
            ),
            _NavItem(
              icon: Icons.bar_chart_outlined,
              activeIcon: Icons.bar_chart,

              isSelected: _selectedIndex == 1,
              onTap: () => setState(() => _selectedIndex = 1),
            ),
            _NavItem(
              icon: Icons.settings_outlined,
              activeIcon: Icons.settings,

              isSelected: _selectedIndex == 2,
              onTap: () => setState(() => _selectedIndex = 2),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? AppColors.primary : AppColors.textMuted;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isSelected ? activeIcon : icon, size: 24, color: color),
          ],
        ),
      ),
    );
  }
}
