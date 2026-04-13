import 'package:flutter/material.dart';

import '../services/network_service.dart';
import '../services/storage_service.dart';
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
            leading: const Icon(Icons.sell_outlined, color: AppColors.primary),
            title: Text('標籤管理', style: AppTypography.body.copyWith(color: AppColors.textPrimary)),
            subtitle: Text(
              '管理標籤、查看使用次數（不分大小寫）',
              style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
            ),
            trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TagManagementScreen()),
              );
            },
          ),
          const Divider(height: 24),
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

class TagManagementScreen extends StatefulWidget {
  const TagManagementScreen({super.key});

  @override
  State<TagManagementScreen> createState() => _TagManagementScreenState();
}

class _TagManagementScreenState extends State<TagManagementScreen> {
  final StorageService _storage = StorageService();
  final NetworkService _networkService = NetworkService();
  bool _loadingTags = true;
  bool _updatingTags = false;
  List<_TagUsage> _tags = [];

  @override
  void initState() {
    super.initState();
    _loadTags();
  }

  Future<void> _loadTags() async {
    setState(() => _loadingTags = true);
    final usageCounts = await _storage.loadTagUsageCounts();
    final tags = usageCounts.entries
        .map((entry) => _TagUsage(tag: entry.key, count: entry.value))
        .toList()
      ..sort((a, b) {
        final byCount = b.count.compareTo(a.count);
        if (byCount != 0) return byCount;
        return a.tag.compareTo(b.tag);
      });
    if (!mounted) return;
    setState(() {
      _tags = tags;
      _loadingTags = false;
    });
  }

  Future<bool> _ensureOnlineForAction(String actionName) async {
    final hasInternet = await _networkService.hasInternetAccess();
    if (hasInternet) return true;
    if (!mounted) return false;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('目前沒有網路，無法$actionName。')),
    );
    return false;
  }

  Future<void> _renameTag(String oldTag) async {
    final controller = TextEditingController(text: oldTag);
    final newTag = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('重新命名標籤'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: '新標籤名稱',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('儲存'),
          ),
        ],
      ),
    );

    if (newTag == null) return;
    final normalizedOld = oldTag.trim().toLowerCase();
    final normalizedNew = newTag.trim().toLowerCase();
    if (normalizedNew.isEmpty || normalizedNew == normalizedOld) return;
    if (!await _ensureOnlineForAction('更新標籤')) return;

    setState(() => _updatingTags = true);
    try {
      final changed = await _storage.replaceTagInAllKits(
        fromTag: normalizedOld,
        toTag: normalizedNew,
      );
      await _loadTags();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已更新 $changed 筆記錄的標籤')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('更新失敗：${e.toString().split('\n').first}')),
      );
    } finally {
      if (mounted) setState(() => _updatingTags = false);
    }
  }

  Future<void> _deleteTag(String tag) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('刪除標籤'),
        content: Text('確定要刪除標籤「#$tag」嗎？\n此操作會套用到所有紀錄。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('刪除'),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    if (!await _ensureOnlineForAction('刪除標籤')) return;

    setState(() => _updatingTags = true);
    try {
      final changed = await _storage.replaceTagInAllKits(fromTag: tag);
      await _loadTags();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已從 $changed 筆記錄移除標籤')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('刪除失敗：${e.toString().split('\n').first}')),
      );
    } finally {
      if (mounted) setState(() => _updatingTags = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '標籤管理',
          style: AppTypography.title.copyWith(color: AppColors.textPrimary),
        ),
        backgroundColor: AppColors.cardBackground,
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              '不分大小寫，同一標籤會自動合併',
              style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
            ),
          ),
          if (_loadingTags)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
            )
          else if (_tags.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                '目前沒有可管理的標籤',
                style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
              ),
            )
          else
            ..._tags.map(
              (item) => ListTile(
                leading: const Icon(Icons.sell_outlined, color: AppColors.primary),
                title: Text(
                  '#${item.tag}',
                  style: AppTypography.body.copyWith(color: AppColors.textPrimary),
                ),
                subtitle: Text(
                  '使用於 ${item.count} 筆紀錄',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: _updatingTags ? null : () => _renameTag(item.tag),
                      tooltip: '重新命名',
                      icon: const Icon(Icons.edit_outlined),
                    ),
                    IconButton(
                      onPressed: _updatingTags ? null : () => _deleteTag(item.tag),
                      tooltip: '刪除',
                      icon: const Icon(Icons.delete_outline, color: AppColors.error),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TagUsage {
  final String tag;
  final int count;

  const _TagUsage({required this.tag, required this.count});
}
