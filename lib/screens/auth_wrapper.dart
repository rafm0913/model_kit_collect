import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../services/auth_service.dart';
import '../services/network_service.dart';
import 'login_screen.dart';
import 'main_shell.dart';

/// 根據登入狀態顯示登入頁或首頁
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final NetworkService _networkService = NetworkService();
  bool _checkingNetwork = true;
  bool _isStartupOffline = false;
  bool _offlineHintShown = false;

  @override
  void initState() {
    super.initState();
    _checkNetwork();
  }

  Future<void> _checkNetwork() async {
    setState(() => _checkingNetwork = true);
    final hasConnection = await _networkService.hasInternetAccess();
    if (!mounted) return;
    setState(() {
      _isStartupOffline = !hasConnection;
      _checkingNetwork = false;
    });
  }

  void _showStartupOfflineHint() {
    if (_offlineHintShown || !_isStartupOffline) return;
    _offlineHintShown = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '目前沒有網路，仍可瀏覽快取資料，但新增/修改/刪除等操作需要連線。',
          ),
          duration: Duration(seconds: 4),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingNetwork) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    _showStartupOfflineHint();

    return StreamBuilder<User?>(
      stream: AuthService().authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
          );
        }
        if (snapshot.hasData && snapshot.data != null) {
          return const MainShell();
        }
        return const LoginScreen();
      },
    );
  }
}
