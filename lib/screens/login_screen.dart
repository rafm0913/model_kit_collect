import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'home_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Image.asset('assets/logo.png', height: 350, fit: BoxFit.contain),
              const SizedBox(height: 24),
              Text(
                '模型收藏記錄',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '使用 Google 帳號登入以同步你的收藏',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              _GoogleSignInButton(onPressed: () => _signInWithGoogle(context)),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _signInWithGoogle(BuildContext context) async {
    final auth = AuthService();
    try {
      final navigator = Navigator.of(context);
      final messenger = ScaffoldMessenger.of(context);

      // 顯示載入中
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(child: CircularProgressIndicator()),
      );

      final user = await auth.signInWithGoogle();

      if (!context.mounted) return;
      navigator.pop(); // 關閉載入對話框

      if (user != null) {
        navigator.pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else {
        messenger.showSnackBar(const SnackBar(content: Text('登入已取消')));
      }
    } catch (e, stack) {
      if (!context.mounted) return;
      Navigator.of(context).pop(); // 關閉載入對話框
      debugPrint('Google 登入錯誤: $e');
      debugPrint(stack.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('登入失敗：${e.toString().split('\n').first}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
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
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.g_mobiledata, size: 28),
        label: const Text('使用 Google 登入'),
        style: OutlinedButton.styleFrom(foregroundColor: Colors.black87),
      ),
    );
  }
}
