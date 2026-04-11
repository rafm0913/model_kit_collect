import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/model_kit.dart';
import '../services/network_service.dart';
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
  final NetworkService _networkService = NetworkService();

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

  Future<void> _pickDate(
    BuildContext context,
    void Function(DateTime) setter,
  ) async {
    final initial = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => setter(picked));
  }

  Future<void> _save() async {
    if (!await _ensureOnlineForAction(_isEditing ? '儲存修改' : '新增記錄')) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final id =
          widget.modelKit?.id ??
          DateTime.now().millisecondsSinceEpoch.toString();
      final kit = ModelKit(
        id: id,
        modelNumber: _modelNumberController.text.trim(),
        purchaseDate: _purchaseDate,
        assemblyStartDate: _assemblyStartDate,
        completionDate: _completionDate,
        photoPaths: _photoPaths,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      await _storage.upsertModelKit(kit);

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('儲存失敗：${e.toString().split('\n').first}')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
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

  Widget _buildPhoto(String path) {
    return Image.network(
      path,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        color: AppColors.buttonBackground,
        alignment: Alignment.center,
        child: const Icon(Icons.broken_image, color: AppColors.textMuted),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy/MM/dd');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit Record' : 'Add Record',
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
                labelText: 'Model Number *',
                hintText: 'e.g. RG 1/144 RX-78-2',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.tag),
              ),
              textCapitalization: TextCapitalization.characters,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Please enter model number';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            Text(
              'Purchase Date',
              style: AppTypography.bodySmall.copyWith(
                fontWeight: AppTypography.weightMedium,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _pickDate(context, (d) => _purchaseDate = d),
              icon: const Icon(Icons.calendar_today),
              label: Text(
                _purchaseDate != null
                    ? dateFormat.format(_purchaseDate!)
                    : 'Select Date',
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                alignment: Alignment.centerLeft,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Assembly Start Date',
              style: AppTypography.bodySmall.copyWith(
                fontWeight: AppTypography.weightMedium,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () =>
                  _pickDate(context, (d) => _assemblyStartDate = d),
              icon: const Icon(Icons.build),
              label: Text(
                _assemblyStartDate != null
                    ? dateFormat.format(_assemblyStartDate!)
                    : 'Select Date',
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                alignment: Alignment.centerLeft,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Completion Date',
              style: AppTypography.bodySmall.copyWith(
                fontWeight: AppTypography.weightMedium,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _pickDate(context, (d) => _completionDate = d),
              icon: const Icon(Icons.check_circle_outline),
              label: Text(
                _completionDate != null
                    ? dateFormat.format(_completionDate!)
                    : 'Select Date',
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                alignment: Alignment.centerLeft,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Photo',
              style: AppTypography.bodySmall.copyWith(
                fontWeight: AppTypography.weightMedium,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 100,
              child: _photoPaths.isEmpty
                  ? Container(
                      decoration: BoxDecoration(
                        color: AppColors.buttonBackground,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '圖片將由系統後續補齊',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    )
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _photoPaths.length,
                      itemBuilder: (context, i) {
                        return Container(
                          width: 100,
                          margin: const EdgeInsets.only(right: 8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: _buildPhoto(_photoPaths[i]),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                hintText: 'Optional',
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
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.textPrimary,
                      ),
                    )
                  : Text(
                      _isEditing ? 'Save' : 'Add',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: AppTypography.weightBold,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
