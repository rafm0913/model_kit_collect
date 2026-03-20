import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../models/model_kit.dart';
import '../services/storage_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class AddEditScreen extends StatefulWidget {
  final ModelKit? modelKit;

  const AddEditScreen({super.key, this.modelKit});

  @override
  State<AddEditScreen> createState() => _AddEditScreenState();
}

class _AddEditScreenState extends State<AddEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _modelNumberController = TextEditingController();
  final _notesController = TextEditingController();
  final StorageService _storage = StorageService();

  DateTime? _purchaseDate;
  DateTime? _assemblyStartDate;
  DateTime? _completionDate;
  List<String> _photoPaths = [];
  bool _saving = false;

  bool get _isEditing => widget.modelKit != null;

  @override
  void initState() {
    super.initState();
    if (widget.modelKit != null) {
      final kit = widget.modelKit!;
      _modelNumberController.text = kit.modelNumber;
      _notesController.text = kit.notes ?? '';
      _purchaseDate = kit.purchaseDate;
      _assemblyStartDate = kit.assemblyStartDate;
      _completionDate = kit.completionDate;
      _photoPaths = List.from(kit.photoPaths);
    }
  }

  @override
  void dispose() {
    _modelNumberController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context, void Function(DateTime) setter) async {
    final initial = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => setter(picked));
  }

  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('拍照'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('從相簿選擇'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    final xFile = await picker.pickImage(source: source, imageQuality: 85);
    if (xFile == null) return;

    setState(() => _saving = true);
    try {
      final kitId = widget.modelKit?.id ?? DateTime.now().millisecondsSinceEpoch.toString();
      final path = await _storage.savePhoto(File(xFile.path), kitId);
      setState(() {
        _photoPaths.add(path);
        _saving = false;
      });
    } catch (_) {
      setState(() => _saving = false);
    }
  }

  Future<void> _removePhoto(int index) async {
    setState(() => _photoPaths.removeAt(index));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final id = widget.modelKit?.id ?? DateTime.now().millisecondsSinceEpoch.toString();
      final kit = ModelKit(
        id: id,
        modelNumber: _modelNumberController.text.trim(),
        purchaseDate: _purchaseDate,
        assemblyStartDate: _assemblyStartDate,
        completionDate: _completionDate,
        photoPaths: _photoPaths,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );

      List<ModelKit> kits = await _storage.loadModelKits();
      final idx = kits.indexWhere((k) => k.id == id);
      if (idx >= 0) {
        kits[idx] = kit;
      } else {
        kits.add(kit);
      }
      await _storage.saveModelKits(kits);

      if (mounted) Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy/MM/dd');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? '編輯記錄' : '新增記錄',
          style: AppTypography.title.copyWith(color: AppColors.textPrimary),
        ),
        backgroundColor: AppColors.cardBackground,
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saving ? null : _save,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _modelNumberController,
              decoration: const InputDecoration(
                labelText: '模型編號 *',
                hintText: '例如：RG 1/144 RX-78-2',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.tag),
              ),
              textCapitalization: TextCapitalization.characters,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return '請輸入模型編號';
                return null;
              },
            ),
            const SizedBox(height: 20),
            Text('購買日期', style: AppTypography.bodySmall.copyWith(fontWeight: AppTypography.weightMedium, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _pickDate(context, (d) => _purchaseDate = d),
              icon: const Icon(Icons.calendar_today),
              label: Text(_purchaseDate != null ? dateFormat.format(_purchaseDate!) : '選擇日期'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                alignment: Alignment.centerLeft,
              ),
            ),
            const SizedBox(height: 16),
            Text('組裝開始日期', style: AppTypography.bodySmall.copyWith(fontWeight: AppTypography.weightMedium, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _pickDate(context, (d) => _assemblyStartDate = d),
              icon: const Icon(Icons.build),
              label: Text(_assemblyStartDate != null ? dateFormat.format(_assemblyStartDate!) : '選擇日期'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                alignment: Alignment.centerLeft,
              ),
            ),
            const SizedBox(height: 16),
            Text('完成日期', style: AppTypography.bodySmall.copyWith(fontWeight: AppTypography.weightMedium, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _pickDate(context, (d) => _completionDate = d),
              icon: const Icon(Icons.check_circle_outline),
              label: Text(_completionDate != null ? dateFormat.format(_completionDate!) : '選擇日期'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                alignment: Alignment.centerLeft,
              ),
            ),
            const SizedBox(height: 24),
            Text('照片記錄', style: AppTypography.bodySmall.copyWith(fontWeight: AppTypography.weightMedium, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            SizedBox(
              height: 100,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  GestureDetector(
                    onTap: _saving ? null : _takePhoto,
                    child: Container(
                      width: 100,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: AppColors.buttonBackground,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: _saving
                          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                          : const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo, size: 36),
                                SizedBox(height: 4),
                                Text('新增照片'),
                              ],
                            ),
                    ),
                  ),
                  ...List.generate(_photoPaths.length, (i) {
                    return Stack(
                      children: [
                        Container(
                          width: 100,
                          margin: const EdgeInsets.only(right: 8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(_photoPaths[i]),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 12,
                          child: GestureDetector(
                            onTap: () => _removePhoto(i),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: AppColors.textLabel,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, color: AppColors.textPrimary, size: 18),
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: '備註',
                hintText: '可選填',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _saving
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textPrimary),
                    )
                  : Text(_isEditing ? '儲存' : '新增', style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary, fontWeight: AppTypography.weightBold)),
            ),
          ],
        ),
      ),
    );
  }
}
