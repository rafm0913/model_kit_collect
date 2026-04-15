import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/model_kit.dart';
import '../services/network_service.dart';
import '../services/storage_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'settings_screen.dart';

class AddEditScreen extends StatefulWidget {
  final ModelKit? modelKit;

  const AddEditScreen({super.key, this.modelKit});

  @override
  State<AddEditScreen> createState() => _AddEditScreenState();
}

class _AddEditScreenState extends State<AddEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _mobileSuitNameController = TextEditingController();
  final _scaleController = TextEditingController();
  final _purchaseAmountController = TextEditingController();
  final _purchaseSourceController = TextEditingController();
  final _notesController = TextEditingController();
  final _manufacturerOtherController = TextEditingController();
  final _gradeOtherController = TextEditingController();
  final _statusOtherController = TextEditingController();

  final StorageService _storage = StorageService();
  final NetworkService _networkService = NetworkService();

  late String _manufacturer;
  late String _grade;
  late String _status;
  late List<StatusLog> _statusLogs;
  late List<String> _tags;
  late bool _isEditMode;
  bool _isScaleApplicable = true;
  DateTime? _purchaseDate;
  bool _saving = false;

  bool get _hasExistingKit => widget.modelKit != null;
  bool get _isManufacturerOther => _manufacturer == ModelKit.otherOption;
  bool get _isGradeOther => _grade == ModelKit.otherOption;
  bool get _isStatusOther => _status == '其他';

  String _safeDropdownValue({
    required String current,
    required List<String> options,
    required String fallback,
  }) {
    if (options.contains(current)) return current;
    if (options.contains(fallback)) return fallback;
    return options.first;
  }

  String _extractScaleNumber(String scale) {
    final value = scale.trim();
    if (value.isEmpty) return '';
    if (value.startsWith('1:')) return value.substring(2).trim();
    if (value.startsWith('1/')) return value.substring(2).trim();
    final matched = RegExp(r'^\d+$').firstMatch(value);
    if (matched != null) return matched.group(0) ?? '';
    return '';
  }

  ({String selected, String? otherText}) _resolveDropdownValue({
    required String? rawValue,
    required List<String> options,
    required String fallbackOption,
    String? existingOther,
  }) {
    final raw = (rawValue ?? '').trim();
    final other = (existingOther ?? '').trim();
    if (raw.isEmpty) {
      return (
        selected: fallbackOption,
        otherText: other.isEmpty ? null : other,
      );
    }
    if (options.contains(raw)) {
      return (selected: raw, otherText: other.isEmpty ? null : other);
    }
    // 若舊資料已存在非選項值，避免 Dropdown assertion，改掛到「其他」補充欄。
    return (selected: fallbackOption, otherText: raw);
  }

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.modelKit == null;

    if (widget.modelKit != null) {
      _applyKitToForm(widget.modelKit!);
      return;
    }

    _manufacturer = ModelKit.manufacturerOptions.first;
    _grade = ModelKit.gradeOptions.first;
    _status = ModelKit.statusOptions.first;
    _statusLogs = [];
    _tags = [];
    _isScaleApplicable = true;
  }

  void _applyKitToForm(ModelKit kit) {
    final manufacturerResolved = _resolveDropdownValue(
      rawValue: kit.manufacturer,
      options: ModelKit.manufacturerOptions,
      fallbackOption: ModelKit.otherOption,
      existingOther: kit.manufacturerOther,
    );
    final gradeResolved = _resolveDropdownValue(
      rawValue: kit.grade,
      options: ModelKit.gradeOptions,
      fallbackOption: ModelKit.otherOption,
      existingOther: kit.gradeOther,
    );
    final statusResolved = _resolveDropdownValue(
      rawValue: kit.status,
      options: ModelKit.statusOptions,
      fallbackOption: '其他',
      existingOther: kit.statusOther,
    );

    _manufacturer = manufacturerResolved.selected;
    _grade = gradeResolved.selected;
    _status = statusResolved.selected;
    _statusLogs = List<StatusLog>.from(kit.statusLogs);
    _tags = ModelKit.normalizeTags(kit.tags);

    _nameController.text = kit.name;
    _quantityController.text = kit.quantity?.toString() ?? '';
    _mobileSuitNameController.text = kit.mobileSuitName;
    final scaleNumber = _extractScaleNumber(kit.scale);
    _isScaleApplicable = scaleNumber.isNotEmpty;
    _scaleController.text = scaleNumber;
    _purchaseAmountController.text = kit.purchaseAmount != null
        ? kit.purchaseAmount!.toStringAsFixed(0)
        : '';
    _purchaseSourceController.text = kit.purchaseSource;
    _notesController.text = kit.notes ?? '';
    _manufacturerOtherController.text = manufacturerResolved.otherText ?? '';
    _gradeOtherController.text = gradeResolved.otherText ?? '';
    _statusOtherController.text = statusResolved.otherText ?? '';
    _purchaseDate = kit.purchaseDate;
  }

  String _currentScaleText() {
    if (!_isScaleApplicable) return '不適用比例';
    final scaleNumber = _scaleController.text.trim();
    if (scaleNumber.isEmpty) return '1/';
    return '1/$scaleNumber';
  }

  String _currentStatusText() {
    if (_status == '其他' && _statusOtherController.text.trim().isNotEmpty) {
      return _statusOtherController.text.trim();
    }
    return _status;
  }

  Future<void> _enterEditMode() async {
    final hasInternet = await _networkService.hasInternetAccess();
    if (!mounted) return;
    if (!hasInternet) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('目前沒有網路，無法進入編輯模式。')));
      return;
    }
    setState(() => _isEditMode = true);
  }

  void _cancelEditMode() {
    final kit = widget.modelKit;
    if (kit == null) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _applyKitToForm(kit);
      _isEditMode = false;
    });
  }

  Widget _buildViewField({
    required String label,
    required String value,
    int maxLines = 3,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.caption.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 4),
          Text(
            value.isEmpty ? '未填寫' : value,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.body.copyWith(color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildViewTagField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '標籤',
            style: AppTypography.caption.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 6),
          if (_tags.isEmpty)
            Text(
              '未填寫',
              style: AppTypography.body.copyWith(color: AppColors.textPrimary),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _tags
                  .map(
                    (tag) => Chip(
                      visualDensity: VisualDensity.compact,
                      label: Text('#$tag'),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildViewModeBody() {
    final dateFormat = DateFormat('yyyy/MM/dd');
    final logs = List<StatusLog>.from(_statusLogs)
      ..sort((a, b) => b.changedAt.compareTo(a.changedAt));

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildViewField(
                label: '名稱',
                value: _nameController.text.trim(),
                maxLines: 2,
              ),
              _buildViewField(
                label: '數量',
                value: _quantityController.text.trim(),
              ),
              _buildViewField(
                label: '製造商',
                value:
                    _isManufacturerOther &&
                        _manufacturerOtherController.text.trim().isNotEmpty
                    ? _manufacturerOtherController.text.trim()
                    : _manufacturer,
              ),
              _buildViewField(
                label: '模型等級',
                value:
                    _isGradeOther &&
                        _gradeOtherController.text.trim().isNotEmpty
                    ? _gradeOtherController.text.trim()
                    : _grade,
              ),
              _buildViewField(
                label: '機體名稱',
                value: _mobileSuitNameController.text.trim(),
              ),
              _buildViewField(label: '比例', value: _currentScaleText()),
              _buildViewField(label: '狀態', value: _currentStatusText()),
              _buildViewField(
                label: '購買金額',
                value: _purchaseAmountController.text.trim(),
              ),
              _buildViewField(
                label: '購買來源',
                value: _purchaseSourceController.text.trim(),
              ),
              _buildViewField(
                label: '購買日期',
                value: _purchaseDate == null
                    ? ''
                    : dateFormat.format(_purchaseDate!),
              ),
              _buildViewTagField(),
              _buildViewField(
                label: '備註',
                value: _notesController.text.trim(),
                maxLines: 6,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '狀態歷程',
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: AppTypography.weightBold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              if (logs.isEmpty)
                Text(
                  '目前尚無狀態紀錄',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textMuted,
                  ),
                )
              else
                ...logs.map(
                  (log) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      '${DateFormat('yyyy/MM/dd HH:mm').format(log.changedAt)}  ${log.displayStatus}',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _mobileSuitNameController.dispose();
    _scaleController.dispose();
    _purchaseAmountController.dispose();
    _purchaseSourceController.dispose();
    _notesController.dispose();
    _manufacturerOtherController.dispose();
    _gradeOtherController.dispose();
    _statusOtherController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(
    BuildContext context,
    void Function(DateTime) setter,
  ) async {
    FocusScope.of(context).unfocus();
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
    FocusScope.of(context).unfocus();
    if (!await _ensureOnlineForAction(_hasExistingKit ? '儲存修改' : '新增收藏')) {
      return;
    }
    if (!mounted) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final id =
          widget.modelKit?.id ??
          DateTime.now().millisecondsSinceEpoch.toString();
      final purchaseAmount = _purchaseAmountController.text.trim().isEmpty
          ? null
          : double.tryParse(_purchaseAmountController.text.trim());
      final quantity = _quantityController.text.trim().isEmpty
          ? null
          : int.tryParse(_quantityController.text.trim());
      final scale = _isScaleApplicable
          ? '1/${_scaleController.text.trim()}'
          : '';

      final existingLogs = List<StatusLog>.from(_statusLogs);
      final isStatusChanged =
          widget.modelKit == null ||
          widget.modelKit!.status != _status ||
          (widget.modelKit!.statusOther ?? '') !=
              _statusOtherController.text.trim();
      final incomingStatusOther = _statusOtherController.text.trim().isEmpty
          ? null
          : _statusOtherController.text.trim();
      final shouldAppendStatusLog =
          isStatusChanged &&
          (existingLogs.isEmpty ||
              existingLogs.last.status != _status ||
              (existingLogs.last.statusOther ?? '') !=
                  (incomingStatusOther ?? ''));
      final updatedLogs = shouldAppendStatusLog
          ? [
              ...existingLogs,
              StatusLog(
                status: _status,
                statusOther: incomingStatusOther,
                changedAt: DateTime.now(),
              ),
            ]
          : existingLogs;

      final kit = ModelKit(
        id: id,
        category: '鋼彈',
        categoryOther: null,
        name: _nameController.text.trim(),
        quantity: quantity,
        manufacturer: _manufacturer,
        manufacturerOther: _manufacturerOtherController.text.trim().isEmpty
            ? null
            : _manufacturerOtherController.text.trim(),
        grade: _grade,
        gradeOther: _gradeOtherController.text.trim().isEmpty
            ? null
            : _gradeOtherController.text.trim(),
        mobileSuitName: _mobileSuitNameController.text.trim(),
        scale: scale,
        status: _status,
        statusOther: incomingStatusOther,
        purchaseAmount: purchaseAmount,
        purchaseSource: _purchaseSourceController.text.trim(),
        purchaseDate: _purchaseDate,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        tags: _tags,
        statusLogs: updatedLogs,
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

  Widget _buildOtherField({
    required bool isVisible,
    required TextEditingController controller,
    required String label,
    required String hint,
  }) {
    if (!isVisible) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildScaleInput() {
    if (!_isScaleApplicable) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.buttonBackground,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '不適用比例',
                style: AppTypography.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: () {
                setState(() => _isScaleApplicable = true);
              },
              icon: const Icon(Icons.add, size: 16),
              label: const Text('增加比例'),
            ),
          ],
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 56,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.buttonBackground,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '1/',
            style: AppTypography.body.copyWith(color: AppColors.textPrimary),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextFormField(
            controller: _scaleController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: '比例數字',
              hintText: '例如：144',
              border: OutlineInputBorder(),
            ),
            validator: (v) {
              if (!_isScaleApplicable) return null;
              if (v == null || v.trim().isEmpty) return '請輸入比例數字';
              if (!RegExp(r'^\d+$').hasMatch(v.trim())) {
                return '只能輸入純數字';
              }
              return null;
            },
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          tooltip: '移除比例',
          onPressed: () {
            FocusScope.of(context).unfocus();
            setState(() {
              _isScaleApplicable = false;
              _scaleController.clear();
            });
          },
          icon: const Icon(Icons.remove_circle_outline),
        ),
      ],
    );
  }

  Widget _buildDatePicker({
    required String title,
    required DateTime? value,
    required VoidCallback onClear,
    required VoidCallback onPick,
  }) {
    final dateFormat = DateFormat('yyyy/MM/dd');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.bodySmall.copyWith(
            fontWeight: AppTypography.weightMedium,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onPick,
                icon: const Icon(Icons.calendar_today),
                label: Text(value != null ? dateFormat.format(value) : '選擇日期'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  alignment: Alignment.centerLeft,
                ),
              ),
            ),
            if (value != null) ...[
              const SizedBox(width: 8),
              IconButton(
                onPressed: onClear,
                tooltip: '清除日期',
                icon: const Icon(Icons.clear),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildStatusLogSection() {
    final logs = List<StatusLog>.from(_statusLogs)
      ..sort((a, b) => b.changedAt.compareTo(a.changedAt));
    final isPendingNewLog =
        !_saving &&
        (_status != (widget.modelKit?.status ?? '') ||
            _statusOtherController.text.trim() !=
                (widget.modelKit?.statusOther ?? ''));
    final dateTimeFormat = DateFormat('yyyy/MM/dd HH:mm');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '狀態歷程',
            style: AppTypography.bodySmall.copyWith(
              fontWeight: AppTypography.weightBold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () => _openStatusLogEditor(),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('新增'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _statusLogs.isEmpty ? null : _clearStatusLogs,
                icon: const Icon(Icons.delete_sweep_outlined, size: 16),
                label: const Text('清空'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (logs.isEmpty)
            Text(
              '目前尚無狀態紀錄',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textMuted,
              ),
            )
          else
            ...logs
                .take(8)
                .map(
                  (log) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${dateTimeFormat.format(log.changedAt)}  ${log.displayStatus}',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        IconButton(
                          iconSize: 18,
                          visualDensity: VisualDensity.compact,
                          tooltip: '編輯',
                          onPressed: () =>
                              _openStatusLogEditor(existingLog: log),
                          icon: const Icon(Icons.edit_outlined),
                        ),
                        IconButton(
                          iconSize: 18,
                          visualDensity: VisualDensity.compact,
                          tooltip: '刪除',
                          onPressed: () => _removeStatusLog(log),
                          icon: const Icon(
                            Icons.delete_outline,
                            color: AppColors.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          if (logs.length > 8)
            Text(
              '... 尚有 ${logs.length - 8} 筆較早紀錄',
              style: AppTypography.caption.copyWith(color: AppColors.textMuted),
            ),
          if (isPendingNewLog) ...[
            const SizedBox(height: 8),
            Text(
              '儲存後將新增狀態：${_isStatusOther && _statusOtherController.text.trim().isNotEmpty ? _statusOtherController.text.trim() : _status}',
              style: AppTypography.caption.copyWith(
                color: AppColors.accentBlue,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _removeTag(String tag) {
    setState(() {
      _tags = _tags.where((t) => t != tag).toList();
    });
  }

  Future<void> _openTagSelector() async {
    final selectedTags = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(
        builder: (_) => TagManagementScreen(
          mode: TagManagementMode.select,
          initialSelectedTags: _tags,
        ),
      ),
    );
    if (!mounted || selectedTags == null) return;
    setState(() {
      _tags = ModelKit.normalizeTags(selectedTags);
    });
  }

  Widget _buildTagSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '標籤',
              style: AppTypography.bodySmall.copyWith(
                fontWeight: AppTypography.weightMedium,
                color: AppColors.textSecondary,
              ),
            ),
            const Spacer(),
            OutlinedButton.icon(
              onPressed: _openTagSelector,
              icon: const Icon(Icons.settings_outlined, size: 16),
              label: const Text('管理標籤'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_tags.isEmpty)
          Text(
            '目前沒有標籤，可點「管理標籤」來選擇或新增',
            style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _tags
                .map(
                  (tag) => InputChip(
                    label: Text('#$tag'),
                    onDeleted: () => _removeTag(tag),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }

  Future<void> _clearStatusLogs() async {
    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('清空狀態歷程'),
        content: const Text('確定要清空所有狀態歷程嗎？此操作可重新新增。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('清空'),
          ),
        ],
      ),
    );
    if (shouldClear != true) return;
    setState(() => _statusLogs = []);
  }

  void _removeStatusLog(StatusLog target) {
    setState(() {
      _statusLogs = _statusLogs
          .where((log) => !identical(log, target))
          .toList();
    });
  }

  Future<void> _openStatusLogEditor({StatusLog? existingLog}) async {
    final editing = existingLog != null;
    var tempStatus = existingLog?.status ?? _status;
    var tempStatusOther = existingLog?.statusOther ?? '';
    var tempChangedAt = existingLog?.changedAt ?? DateTime.now();

    final result = await showDialog<StatusLog>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          Future<void> pickDateTime() async {
            final pickedDate = await showDatePicker(
              context: ctx,
              initialDate: tempChangedAt,
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (pickedDate == null) return;
            if (!ctx.mounted) return;
            final pickedTime = await showTimePicker(
              context: ctx,
              initialTime: TimeOfDay.fromDateTime(tempChangedAt),
            );
            if (pickedTime == null) return;
            if (!ctx.mounted) return;
            setDialogState(() {
              tempChangedAt = DateTime(
                pickedDate.year,
                pickedDate.month,
                pickedDate.day,
                pickedTime.hour,
                pickedTime.minute,
              );
            });
          }

          return AlertDialog(
            title: Text(editing ? '編輯狀態紀錄' : '新增狀態紀錄'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _safeDropdownValue(
                      current: tempStatus,
                      options: ModelKit.statusOptions,
                      fallback: '其他',
                    ),
                    decoration: const InputDecoration(
                      labelText: '狀態',
                      border: OutlineInputBorder(),
                    ),
                    items: ModelKit.statusOptions
                        .map(
                          (item) =>
                              DropdownMenuItem(value: item, child: Text(item)),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setDialogState(() => tempStatus = value);
                    },
                  ),
                  if (tempStatus == '其他') ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      initialValue: tempStatusOther,
                      decoration: const InputDecoration(
                        labelText: '狀態補充（可選）',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) => tempStatusOther = value,
                    ),
                  ],
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: pickDateTime,
                    icon: const Icon(Icons.event_outlined),
                    label: Text(
                      DateFormat('yyyy/MM/dd HH:mm').format(tempChangedAt),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(
                    ctx,
                    StatusLog(
                      status: tempStatus,
                      statusOther: tempStatusOther.trim().isEmpty
                          ? null
                          : tempStatusOther.trim(),
                      changedAt: tempChangedAt,
                    ),
                  );
                },
                child: const Text('儲存'),
              ),
            ],
          );
        },
      ),
    );

    if (result == null) return;
    setState(() {
      if (existingLog == null) {
        _statusLogs = [..._statusLogs, result];
      } else {
        final index = _statusLogs.indexOf(existingLog);
        if (index >= 0) {
          final copied = List<StatusLog>.from(_statusLogs);
          copied[index] = result;
          _statusLogs = copied;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (_, _) => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => FocusScope.of(context).unfocus(),
            child: Text(
              _hasExistingKit ? (_isEditMode ? '編輯收藏' : '收藏詳情') : '新增收藏',
              style: AppTypography.title.copyWith(color: AppColors.textPrimary),
            ),
          ),
          backgroundColor: AppColors.cardBackground,
          actions: [
            if (_hasExistingKit && !_isEditMode)
              TextButton.icon(
                onPressed: _enterEditMode,
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('開始編輯'),
              ),
            if (_hasExistingKit && _isEditMode)
              IconButton(
                tooltip: '取消編輯',
                icon: const Icon(Icons.close),
                onPressed: _cancelEditMode,
              ),
            if (_hasExistingKit && _isEditMode)
              IconButton(
                icon: const Icon(Icons.save),
                onPressed: _saving ? null : _save,
              ),
          ],
        ),
        body: !_isEditMode && _hasExistingKit
            ? _buildViewModeBody()
            : GestureDetector(
                onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.fromLTRB(
                      16,
                      16,
                      16,
                      16 + MediaQuery.of(context).viewInsets.bottom,
                    ),
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: '名稱 *',
                          hintText: '給自己辨認用，例如：生日禮物那盒',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.bookmark_outline),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return '請輸入名稱';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _quantityController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: '數量',
                          hintText: '只能輸入數字',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.format_list_numbered),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return null;
                          if (!RegExp(r'^\d+$').hasMatch(v.trim())) {
                            return '數量只能輸入數字';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      DropdownButtonFormField<String>(
                        initialValue: _safeDropdownValue(
                          current: _manufacturer,
                          options: ModelKit.manufacturerOptions,
                          fallback: ModelKit.otherOption,
                        ),
                        decoration: const InputDecoration(
                          labelText: '製造商',
                          border: OutlineInputBorder(),
                        ),
                        items: ModelKit.manufacturerOptions
                            .map(
                              (item) => DropdownMenuItem(
                                value: item,
                                child: Text(item),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _manufacturer = value);
                        },
                      ),
                      _buildOtherField(
                        isVisible: _isManufacturerOther,
                        controller: _manufacturerOtherController,
                        label: '製造商補充（可選）',
                        hint: '可留空',
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: _safeDropdownValue(
                          current: _grade,
                          options: ModelKit.gradeOptions,
                          fallback: ModelKit.otherOption,
                        ),
                        decoration: const InputDecoration(
                          labelText: '模型等級',
                          border: OutlineInputBorder(),
                        ),
                        items: ModelKit.gradeOptions
                            .map(
                              (item) => DropdownMenuItem(
                                value: item,
                                child: Text(item),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _grade = value);
                        },
                      ),
                      _buildOtherField(
                        isVisible: _isGradeOther,
                        controller: _gradeOtherController,
                        label: '模型等級補充（可選）',
                        hint: '可留空',
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _mobileSuitNameController,
                        decoration: const InputDecoration(
                          labelText: '機體名稱',
                          hintText: '例如：RX-78-2 GUNDAM',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '比例',
                        style: AppTypography.bodySmall.copyWith(
                          fontWeight: AppTypography.weightMedium,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildScaleInput(),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: _safeDropdownValue(
                          current: _status,
                          options: ModelKit.statusOptions,
                          fallback: '其他',
                        ),
                        decoration: const InputDecoration(
                          labelText: '狀態',
                          border: OutlineInputBorder(),
                        ),
                        items: ModelKit.statusOptions
                            .map(
                              (item) => DropdownMenuItem(
                                value: item,
                                child: Text(item),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _status = value);
                        },
                      ),
                      _buildOtherField(
                        isVisible: _isStatusOther,
                        controller: _statusOtherController,
                        label: '狀態補充（可選）',
                        hint: '可留空',
                      ),
                      const SizedBox(height: 12),
                      _buildStatusLogSection(),
                      const SizedBox(height: 16),
                      _buildTagSection(),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _purchaseAmountController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: '購買金額',
                          hintText: '例如：1200',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.attach_money),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return null;
                          if (double.tryParse(v.trim()) == null) {
                            return '請輸入數字';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _purchaseSourceController,
                        decoration: const InputDecoration(
                          labelText: '購買來源',
                          hintText: '例如：網購、實體店',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildDatePicker(
                        title: '購買日期',
                        value: _purchaseDate,
                        onPick: () =>
                            _pickDate(context, (d) => _purchaseDate = d),
                        onClear: () {
                          FocusScope.of(context).unfocus();
                          setState(() => _purchaseDate = null);
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: '備註',
                          hintText: '可留空',
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
                                _hasExistingKit ? '儲存收藏' : '新增收藏',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: AppTypography.weightBold,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
