import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/model_kit.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../services/storage_service.dart';
import '../services/network_service.dart';
import 'add_edit_screen.dart';

class HomeScreen extends StatefulWidget {
  final ValueNotifier<int>? refreshTrigger;

  const HomeScreen({super.key, this.refreshTrigger});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final StorageService _storage = StorageService();
  final NetworkService _networkService = NetworkService();
  List<ModelKit> _kits = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadKits();
    widget.refreshTrigger?.addListener(_loadKits);
  }

  @override
  void dispose() {
    widget.refreshTrigger?.removeListener(_loadKits);
    super.dispose();
  }

  Future<void> _loadKits() async {
    if (!mounted) return;
    setState(() => _loading = true);
    final kits = await _storage.loadModelKits();
    if (!mounted) return;
    setState(() {
      _kits = kits;
      _loading = false;
    });
  }

  Future<void> _navigateToEdit(ModelKit kit) async {
    final hasInternet = await _networkService.hasInternetAccess();
    if (!mounted) return;
    if (!hasInternet) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('目前沒有網路，無法編輯記錄。')),
      );
      return;
    }

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => AddEditScreen(modelKit: kit)),
    );
    if (result == true && mounted) _loadKits();
  }

  Future<void> _deleteKit(ModelKit kit) async {
    final hasInternet = await _networkService.hasInternetAccess();
    if (!mounted) return;
    if (!hasInternet) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('目前沒有網路，無法刪除記錄。')),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('確認刪除'),
        content: Text('確定要刪除「${kit.modelNumber}」的記錄嗎？'),
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
    try {
      await _storage.deleteModelKit(kit.id);
      _kits.removeWhere((k) => k.id == kit.id);
      if (mounted) setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('刪除失敗：${e.toString().split('\n').first}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '庫存清單',
          style: AppTypography.title.copyWith(color: AppColors.textPrimary),
        ),
        backgroundColor: AppColors.cardBackground,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _kits.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 80,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '尚無記錄',
                    style: AppTypography.subtitle.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '點擊右下角 + 新增第一筆模型',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            )
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _VaultHeader(kits: _kits)),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final kit = _kits[index];
                      return _KitCard(
                        kit: kit,
                        onTap: () => _navigateToEdit(kit),
                        onDelete: () => _deleteKit(kit),
                      );
                    }, childCount: _kits.length),
                  ),
                ),
              ],
            ),
    );
  }
}

class _VaultHeader extends StatelessWidget {
  final List<ModelKit> kits;

  const _VaultHeader({required this.kits});

  @override
  Widget build(BuildContext context) {
    final activeCount = kits
        .where((k) => k.assemblyStartDate != null || k.completionDate != null)
        .length;
    final archivedCount = kits
        .where((k) => k.assemblyStartDate == null && k.completionDate == null)
        .length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'REGISTRY INDEX',
            style: AppTypography.caption.copyWith(
              color: AppColors.copper,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'VAULT COLLECTION',
            style: AppTypography.headline.copyWith(
              color: AppColors.textPrimary,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ACTIVE BUILDS',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                    Text(
                      activeCount.toString().padLeft(2, '0'),
                      style: AppTypography.title.copyWith(
                        color: AppColors.accentBlue,
                        fontSize: 28,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ARCHIVED',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                    Text(
                      archivedCount.toString().padLeft(2, '0'),
                      style: AppTypography.title.copyWith(
                        color: AppColors.textPrimary,
                        fontSize: 28,
                      ),
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
}

class _KitCard extends StatelessWidget {
  final ModelKit kit;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _KitCard({
    required this.kit,
    required this.onTap,
    required this.onDelete,
  });

  String _getBadge() {
    final parts = kit.modelNumber.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return 'KIT';
    final first = parts.first.toUpperCase();
    if (first.length <= 4 && RegExp(r'^[A-Z0-9]+$').hasMatch(first)) {
      return first;
    }
    return 'KIT';
  }

  ({int percent, String status, bool isCompleted}) _getProgress() {
    if (kit.completionDate != null) {
      return (percent: 100, status: 'COMPLETED', isCompleted: true);
    }
    if (kit.assemblyStartDate != null) {
      return (percent: 65, status: '65%', isCompleted: false);
    }
    return (percent: 0, status: 'QUEUE', isCompleted: false);
  }

  String _getSubtitle() {
    final parts = <String>[];
    if (kit.purchaseDate != null) {
      parts.add(
        'Bought on ${DateFormat('yyyy/MM/dd').format(kit.purchaseDate!)}',
      );
    }
    if (kit.tags.isNotEmpty) {
      parts.add(kit.tags.map((tag) => '#$tag').join(' '));
    }
    if (kit.notes != null && kit.notes!.isNotEmpty) {
      parts.add(kit.notes!);
    }
    return parts.join(' / ');
  }

  @override
  Widget build(BuildContext context) {
    final progress = _getProgress();
    final subtitle = _getSubtitle();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppColors.cardBackground,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(width: 4, color: AppColors.accentBlue),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  color: AppColors.copper.withValues(
                                    alpha: 0.3,
                                  ),
                                  child: Text(
                                    _getBadge(),
                                    style: AppTypography.label.copyWith(
                                      color: AppColors.copper,
                                      fontWeight: AppTypography.weightBold,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  kit.modelNumber.toUpperCase(),
                                  style: AppTypography.subtitle.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: AppTypography.weightBold,
                                  ),
                                ),
                                if (subtitle.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    subtitle,
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                progress.status,
                                style: AppTypography.label.copyWith(
                                  color: progress.isCompleted
                                      ? AppColors.accentBlue
                                      : AppColors.textMuted,
                                ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: 60,
                                child: LinearProgressIndicator(
                                  value: progress.percent / 100,
                                  backgroundColor: AppColors.buttonBackground,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    progress.isCompleted || progress.percent > 0
                                        ? AppColors.accentBlue
                                        : AppColors.textMuted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    onSelected: (value) {
                      if (value == 'delete') onDelete();
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, color: AppColors.error),
                            const SizedBox(width: 8),
                            Text(
                              '刪除',
                              style: TextStyle(color: AppColors.error),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
