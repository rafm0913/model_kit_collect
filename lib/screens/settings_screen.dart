import 'package:flutter/material.dart';

import '../models/model_kit.dart';
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
        title: Text(
          '系統設定',
          style: AppTypography.title.copyWith(color: AppColors.textPrimary),
        ),
        backgroundColor: AppColors.cardBackground,
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.sell_outlined, color: AppColors.primary),
            title: Text(
              '標籤管理',
              style: AppTypography.body.copyWith(color: AppColors.textPrimary),
            ),
            subtitle: Text(
              '管理標籤、查看使用次數（不分大小寫）',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textMuted,
              ),
            ),
            trailing: const Icon(
              Icons.chevron_right,
              color: AppColors.textMuted,
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TagManagementScreen(),
                ),
              );
            },
          ),
          const Divider(height: 24),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.primary),
            title: Text(
              '登出',
              style: AppTypography.body.copyWith(color: AppColors.textPrimary),
            ),
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

enum TagManagementMode { manage, select }

class TagManagementScreen extends StatefulWidget {
  final TagManagementMode mode;
  final List<String> initialSelectedTags;

  const TagManagementScreen({
    super.key,
    this.mode = TagManagementMode.manage,
    this.initialSelectedTags = const [],
  });

  bool get isSelectionMode => mode == TagManagementMode.select;

  @override
  State<TagManagementScreen> createState() => _TagManagementScreenState();
}

class _TagManagementScreenState extends State<TagManagementScreen> {
  final StorageService _storage = StorageService();
  final NetworkService _networkService = NetworkService();
  final TextEditingController _newTagController = TextEditingController();
  bool _loadingTags = true;
  bool _updatingTags = false;
  List<_TagUsage> _tags = [];
  Set<String> _selectedTags = {};

  @override
  void initState() {
    super.initState();
    _selectedTags = ModelKit.normalizeTags(widget.initialSelectedTags).toSet();
    _loadTags();
  }

  @override
  void dispose() {
    _newTagController.dispose();
    super.dispose();
  }

  Future<void> _loadTags() async {
    setState(() => _loadingTags = true);
    final usageCounts = await _storage.loadTagUsageCounts();
    var tags = usageCounts.entries
        .map((entry) => _TagUsage(tag: entry.key, count: entry.value))
        .toList();
    if (widget.isSelectionMode) {
      final existingTags = tags.map((item) => item.tag).toSet();
      for (final selectedTag in _selectedTags) {
        if (!existingTags.contains(selectedTag)) {
          tags.add(_TagUsage(tag: selectedTag, count: 0));
        }
      }
    }
    tags = _sortedTags(tags);
    if (!mounted) return;
    setState(() {
      _tags = tags;
      _loadingTags = false;
    });
  }

  List<_TagUsage> _sortedTags(List<_TagUsage> tags) {
    final copied = List<_TagUsage>.from(tags);
    copied.sort((a, b) {
      if (widget.isSelectionMode) {
        final aSelected = _selectedTags.contains(a.tag);
        final bSelected = _selectedTags.contains(b.tag);
        if (aSelected != bSelected) return aSelected ? -1 : 1;
      }
      final byCount = b.count.compareTo(a.count);
      if (byCount != 0) return byCount;
      return a.tag.compareTo(b.tag);
    });
    return copied;
  }

  void _toggleTag(String tag) {
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else {
        _selectedTags.add(tag);
      }
      _tags = _sortedTags(_tags);
    });
  }

  void _addTagToSelection() {
    final normalized = ModelKit.normalizeTag(_newTagController.text);
    if (normalized.isEmpty) return;
    setState(() {
      _selectedTags.add(normalized);
      if (!_tags.any((item) => item.tag == normalized)) {
        _tags = [..._tags, _TagUsage(tag: normalized, count: 0)];
      }
      _tags = _sortedTags(_tags);
      _newTagController.clear();
    });
  }

  void _submitSelection() {
    Navigator.pop(context, _selectedTags.toList()..sort());
  }

  Future<bool> _ensureOnlineForAction(String actionName) async {
    final hasInternet = await _networkService.hasInternetAccess();
    if (hasInternet) return true;
    if (!mounted) return false;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('目前沒有網路，無法$actionName。')));
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('已更新 $changed 筆收藏的標籤')));
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
        content: Text('確定要刪除標籤「#$tag」嗎？\n此操作會套用到所有收藏。'),
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('已從 $changed 筆收藏移除標籤')));
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
          widget.isSelectionMode ? '選擇標籤' : '標籤管理',
          style: AppTypography.title.copyWith(color: AppColors.textPrimary),
        ),
        backgroundColor: AppColors.cardBackground,
        actions: [
          if (widget.isSelectionMode)
            TextButton.icon(
              onPressed: _loadingTags ? null : _submitSelection,
              icon: const Icon(Icons.check),
              label: const Text('完成'),
            ),
        ],
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              widget.isSelectionMode ? '可勾選既有標籤，也可直接新增標籤' : '不分大小寫，同一標籤會自動合併',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ),
          if (widget.isSelectionMode)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _newTagController,
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        labelText: '新增標籤',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _addTagToSelection(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _addTagToSelection,
                    child: const Text('加入'),
                  ),
                ],
              ),
            ),
          if (_loadingTags)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            )
          else if (_tags.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                textAlign: TextAlign.center,
                'No tags found',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            )
          else if (widget.isSelectionMode)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _tags
                    .map(
                      (item) => FilterChip(
                        selected: _selectedTags.contains(item.tag),
                        selectedColor: AppColors.copper,
                        label: Text('#${item.tag}'),
                        avatar: _selectedTags.contains(item.tag)
                            ? const Icon(Icons.check, size: 16)
                            : const Icon(Icons.sell_outlined, size: 16),
                        onSelected: (_) => _toggleTag(item.tag),
                      ),
                    )
                    .toList(),
              ),
            )
          else
            ..._tags.map(
              (item) => ListTile(
                leading: const Icon(
                  Icons.sell_outlined,
                  color: AppColors.primary,
                ),
                title: Text(
                  '#${item.tag}',
                  style: AppTypography.body.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                subtitle: Text(
                  item.count > 0 ? '使用於 ${item.count} 筆收藏' : '尚未使用',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: _updatingTags
                          ? null
                          : () => _renameTag(item.tag),
                      tooltip: '重新命名',
                      icon: const Icon(Icons.edit_outlined),
                    ),
                    IconButton(
                      onPressed: _updatingTags
                          ? null
                          : () => _deleteTag(item.tag),
                      tooltip: '刪除',
                      icon: const Icon(
                        Icons.delete_outline,
                        color: AppColors.error,
                      ),
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
