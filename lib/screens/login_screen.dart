import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            top: 150,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final w = constraints.maxWidth * 1.5;
                final h = constraints.maxHeight * 1.5;
                return Center(
                  child: Transform.rotate(
                    angle: -0.7,
                    alignment: Alignment.center,
                    child: SizedBox(
                      width: w,
                      height: h,
                      child: Image.asset('assets/login_background.png'),
                    ),
                  ),
                );
              },
            ),
          ),
          // 深色遮罩
          Container(color: AppColors.backgroundDark.withValues(alpha: 0.85)),
          // 主內容
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const Spacer(),
                  // 登入卡片（置中）
                  _LoginCard(onSignIn: () => _signInWithGoogle(context)),
                  const Spacer(),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _signInWithGoogle(BuildContext context) async {
    final auth = AuthService();
    try {
      final navigator = Navigator.of(context);
      final messenger = ScaffoldMessenger.of(context);

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );

      final user = await auth.signInWithGoogle();

      if (!context.mounted) return;
      navigator.pop();

      if (user != null) {
        navigator.pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: const Text('登入已取消'),
            backgroundColor: AppColors.textMuted,
          ),
        );
      }
    } catch (e, stack) {
      if (!context.mounted) return;
      Navigator.of(context).pop();
      debugPrint('Google 登入錯誤: $e');
      debugPrint(stack.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('登入失敗：${e.toString().split('\n').first}'),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }
}

class _LoginCard extends StatelessWidget {
  final VoidCallback onSignIn;

  const _LoginCard({required this.onSignIn});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topLeft,
      children: [
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(color: AppColors.cardBackground),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Logo 框
              Stack(
                alignment: Alignment.topLeft,
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        margin: const EdgeInsets.all(4),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.border, width: 1),
                          color: Colors.transparent,
                        ),
                        child: Image.asset(
                          'assets/logo.png',
                          height: 80,
                          fit: BoxFit.contain,
                          color: AppColors.whiteBackground,
                        ),
                      ),
                      Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(color: AppColors.primary),
                      ),
                    ],
                  ),
                  Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(color: AppColors.primary),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // SECURE ACCESS MODULE 標籤
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(width: 6, height: 6, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'SECURE ACCESS MODULE',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.primary,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(width: 6, height: 6, color: AppColors.primary),
                ],
              ),
              const SizedBox(height: 24),
              // 主標題
              Text(
                'Access Terminal',
                style: AppTypography.headline.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              // 副標題
              Text(
                'Authorize connection to synchronize with your master workbench.',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              // Google 登入按鈕
              _GoogleSignInButton(onPressed: onSignIn),
              const SizedBox(height: 24),
              // 分隔線
              Container(height: 1, color: AppColors.border),
              const SizedBox(height: 16),
              // 狀態文字
              Text(
                'SECURE SSO TUNNEL ACTIVE',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textLabel,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.transparent,
            border: Border(
              left: const BorderSide(color: AppColors.primary, width: 2),
              top: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

class _GoogleSignInButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _GoogleSignInButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: Material(
        color: AppColors.buttonBackground,
        child: InkWell(
          onTap: onPressed,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.g_mobiledata,
                  size: 28,
                  color: AppColors.textPrimary,
                ),
                const SizedBox(width: 12),
                Text(
                  'SIGN IN WITH GOOGLE',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: AppTypography.weightBold,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(width: 12),
                Icon(Icons.login, size: 20, color: AppColors.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
