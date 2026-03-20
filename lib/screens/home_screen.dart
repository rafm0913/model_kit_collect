import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/model_kit.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import 'add_edit_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final StorageService _storage = StorageService();
  final AuthService _auth = AuthService();
  List<ModelKit> _kits = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadKits();
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

  Future<void> _navigateToAdd() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const AddEditScreen(),
      ),
    );
    if (result == true && mounted) _loadKits();
  }

  Future<void> _navigateToEdit(ModelKit kit) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditScreen(modelKit: kit),
      ),
    );
    if (result == true && mounted) _loadKits();
  }

  Future<void> _signOut() async {
    await _auth.signOut();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  Future<void> _deleteKit(ModelKit kit) async {
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
    await _storage.deleteModelPhotos(kit.id);
    _kits.removeWhere((k) => k.id == kit.id);
    await _storage.saveModelKits(_kits);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('模型收藏記錄', style: AppTypography.title.copyWith(color: AppColors.textPrimary)),
        backgroundColor: AppColors.cardBackground,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
            tooltip: '登出',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
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
                        style: AppTypography.subtitle.copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '點擊右下角 + 新增第一筆模型',
                        style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _kits.length,
                  itemBuilder: (context, index) {
                    final kit = _kits[index];
                    return _KitCard(
                      kit: kit,
                      onTap: () => _navigateToEdit(kit),
                      onDelete: () => _deleteKit(kit),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAdd,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add),
        label: Text('新增', style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary, fontWeight: AppTypography.weightBold)),
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

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy/MM/dd');
    final hasPhoto = kit.photoPaths.isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppColors.cardBackground,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: hasPhoto
                      ? Image.file(
                          File(kit.photoPaths.first),
                          fit: BoxFit.cover,
                        )
                      : Container(
                          color: AppColors.buttonBackground,
                          child: Icon(
                            Icons.image_not_supported_outlined,
                            size: 32,
                            color: AppColors.textMuted,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      kit.modelNumber,
                      style: AppTypography.subtitle.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: AppTypography.weightBold,
                      ),
                    ),
                    if (kit.purchaseDate != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '購買：${dateFormat.format(kit.purchaseDate!)}',
                        style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                    if (kit.assemblyStartDate != null)
                      Text(
                        '組裝：${dateFormat.format(kit.assemblyStartDate!)}',
                        style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                      ),
                    if (kit.completionDate != null)
                      Text(
                        '完成：${dateFormat.format(kit.completionDate!)}',
                        style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                      ),
                    if (kit.photoPaths.length > 1)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            Icon(Icons.photo_library, size: 14, color: AppColors.textMuted),
                            const SizedBox(width: 4),
                            Text(
                              '${kit.photoPaths.length} 張照片',
                              style: AppTypography.label.copyWith(color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
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
                        Text('刪除', style: TextStyle(color: AppColors.error)),
                      ],
                    ),
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
