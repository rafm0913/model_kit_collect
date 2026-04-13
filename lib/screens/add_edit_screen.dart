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
  List<String> _selectedTags = [];
  List<String> _availableTags = [];
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
      _selectedTags = List.from(kit.tags);
    }
    _loadAvailableTags();
  }

  @override
  void dispose() {
    _modelNumberController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableTags() async {
    final existingTags = await _storage.loadAllTags();
    if (!mounted) return;

    final tags = <String>{..._selectedTags, ...existingTags};

    final sortedTags = tags.toList()..sort((a, b) => a.compareTo(b));
    setState(() => _availableTags = sortedTags);
  }

  void _toggleTagSelection(String tag, bool selected) {
    final normalized = ModelKit.normalizeTag(tag);
    setState(() {
      if (selected) {
        if (!_selectedTags.contains(normalized)) _selectedTags.add(normalized);
      } else {
        _selectedTags.remove(normalized);
      }
    });
  }

  Future<void> _openTagManager() async {
    FocusScope.of(context).unfocus();
    final result = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _TagManagerSheet(
        availableTags: _availableTags,
        selectedTags: _selectedTags,
      ),
    );
    if (result == null) return;

    final normalized = ModelKit.normalizeTags(result);
    final mergedPool = <String>{..._availableTags, ...normalized}.toList()
      ..sort((a, b) => a.compareTo(b));
    if (!mounted) return;
    setState(() {
      _selectedTags = normalized;
      _availableTags = mergedPool;
    });
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
        tags: ModelKit.normalizeTags(_selectedTags),
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

    return WillPopScope(
      onWillPop: () async {
        FocusScope.of(context).unfocus();
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => FocusScope.of(context).unfocus(),
            child: Text(
              _isEditing ? 'Edit Record' : 'Add Record',
              style: AppTypography.title.copyWith(color: AppColors.textPrimary),
            ),
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
        body: GestureDetector(
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: Form(
            key: _formKey,
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                16 + MediaQuery.of(context).viewInsets.bottom,
              ),
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
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
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
                ),
                if (_purchaseDate != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () {
                      FocusScope.of(context).unfocus();
                      setState(() => _purchaseDate = null);
                    },
                    tooltip: 'Clear date',
                    icon: const Icon(Icons.clear),
                  ),
                ],
              ],
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
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
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
                ),
                if (_assemblyStartDate != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () {
                      FocusScope.of(context).unfocus();
                      setState(() => _assemblyStartDate = null);
                    },
                    tooltip: 'Clear date',
                    icon: const Icon(Icons.clear),
                  ),
                ],
              ],
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
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
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
                ),
                if (_completionDate != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () {
                      FocusScope.of(context).unfocus();
                      setState(() => _completionDate = null);
                    },
                    tooltip: 'Clear date',
                    icon: const Icon(Icons.clear),
                  ),
                ],
              ],
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
            Text(
              'Tags',
              style: AppTypography.bodySmall.copyWith(
                fontWeight: AppTypography.weightMedium,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _openTagManager,
              icon: const Icon(Icons.sell_outlined),
              label: Text(_selectedTags.isEmpty ? '管理標籤' : '管理標籤（${_selectedTags.length}）'),
            ),
            if (_selectedTags.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _selectedTags
                    .map(
                      (tag) => InputChip(
                        label: Text(tag),
                        onDeleted: () => _toggleTagSelection(tag, false),
                      ),
                    )
                    .toList(),
              ),
            ],
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
        ),
      ),
    );
  }
}

class _TagManagerSheet extends StatefulWidget {
  final List<String> availableTags;
  final List<String> selectedTags;

  const _TagManagerSheet({
    required this.availableTags,
    required this.selectedTags,
  });

  @override
  State<_TagManagerSheet> createState() => _TagManagerSheetState();
}

class _TagManagerSheetState extends State<_TagManagerSheet> {
  final TextEditingController _inputController = TextEditingController();
  List<String> _selected = [];
  List<String> _pool = [];

  @override
  void initState() {
    super.initState();
    _selected = ModelKit.normalizeTags(widget.selectedTags);
    _pool = <String>{...widget.availableTags, ..._selected}.toList()
      ..sort((a, b) => a.compareTo(b));
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  String get _keyword => ModelKit.normalizeTag(_inputController.text);

  bool get _canCreate =>
      _keyword.isNotEmpty &&
      !_pool.any((tag) => ModelKit.normalizeTag(tag) == _keyword);

  List<String> get _suggestions {
    final source = _pool.where((tag) => !_selected.contains(tag));
    if (_keyword.isEmpty) return source.take(12).toList();
    return source.where((tag) => tag.contains(_keyword)).take(12).toList();
  }

  void _addTag(String rawTag) {
    final normalized = ModelKit.normalizeTag(rawTag);
    if (normalized.isEmpty) return;

    setState(() {
      if (!_selected.contains(normalized)) _selected.add(normalized);
      if (!_pool.contains(normalized)) {
        _pool = [..._pool, normalized]..sort((a, b) => a.compareTo(b));
      }
      _inputController.clear();
    });
  }

  void _removeTag(String tag) {
    setState(() => _selected.remove(ModelKit.normalizeTag(tag)));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          8,
          16,
          16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '管理這筆紀錄的標籤',
                  style: AppTypography.subtitle.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () =>
                      Navigator.pop(context, ModelKit.normalizeTags(_selected)),
                  child: const Text('完成'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _inputController,
              autofocus: true,
              textInputAction: TextInputAction.done,
              onChanged: (_) => setState(() {}),
              onSubmitted: _addTag,
              decoration: InputDecoration(
                hintText: '搜尋或建立標籤',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  onPressed: () => _addTag(_inputController.text),
                  icon: const Icon(Icons.add),
                  tooltip: '新增標籤',
                ),
              ),
            ),
            if (_selected.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _selected
                    .map(
                      (tag) => InputChip(
                        label: Text(tag),
                        onDeleted: () => _removeTag(tag),
                      ),
                    )
                    .toList(),
              ),
            ],
            const SizedBox(height: 10),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  if (_canCreate)
                    ListTile(
                      dense: true,
                      leading: const Icon(Icons.add_circle_outline, size: 18),
                      title: Text('建立新標籤 #$_keyword'),
                      onTap: () => _addTag(_keyword),
                    ),
                  ..._suggestions.map(
                    (tag) => ListTile(
                      dense: true,
                      leading: const Icon(Icons.tag, size: 18),
                      title: Text('#$tag'),
                      onTap: () => _addTag(tag),
                    ),
                  ),
                  if (_suggestions.isEmpty && !_canCreate)
                    Text(
                      _keyword.isEmpty ? '目前沒有可用標籤' : '找不到符合標籤',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
