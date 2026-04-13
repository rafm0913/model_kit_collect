/// 模型套件資料模型
class ModelKit {
  final String id;
  final String modelNumber; // 編號
  final DateTime? purchaseDate; // 購買日期
  final DateTime? assemblyStartDate; // 組裝開始日期
  final DateTime? completionDate; // 完成日期
  final List<String> photoPaths; // 照片路徑列表
  final List<String> tags; // 標籤
  final String? notes; // 備註

  const ModelKit({
    required this.id,
    required this.modelNumber,
    this.purchaseDate,
    this.assemblyStartDate,
    this.completionDate,
    this.photoPaths = const [],
    this.tags = const [],
    this.notes,
  });

  static String normalizeTag(String tag) => tag.trim().toLowerCase();

  static List<String> normalizeTags(List<String> tags) {
    final normalized = <String>[];
    for (final raw in tags) {
      final tag = normalizeTag(raw);
      if (tag.isEmpty || normalized.contains(tag)) continue;
      normalized.add(tag);
    }
    return normalized;
  }

  ModelKit copyWith({
    String? id,
    String? modelNumber,
    DateTime? purchaseDate,
    DateTime? assemblyStartDate,
    DateTime? completionDate,
    List<String>? photoPaths,
    List<String>? tags,
    String? notes,
  }) {
    return ModelKit(
      id: id ?? this.id,
      modelNumber: modelNumber ?? this.modelNumber,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      assemblyStartDate: assemblyStartDate ?? this.assemblyStartDate,
      completionDate: completionDate ?? this.completionDate,
      photoPaths: photoPaths ?? this.photoPaths,
      tags: tags != null ? normalizeTags(tags) : this.tags,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'modelNumber': modelNumber,
        'purchaseDate': purchaseDate?.toIso8601String(),
        'assemblyStartDate': assemblyStartDate?.toIso8601String(),
        'completionDate': completionDate?.toIso8601String(),
        'photoPaths': photoPaths,
        'tags': normalizeTags(tags),
        'notes': notes,
      };

  factory ModelKit.fromJson(Map<String, dynamic> json) => ModelKit(
        id: json['id'] as String,
        modelNumber: json['modelNumber'] as String,
        purchaseDate: json['purchaseDate'] != null
            ? DateTime.parse(json['purchaseDate'] as String)
            : null,
        assemblyStartDate: json['assemblyStartDate'] != null
            ? DateTime.parse(json['assemblyStartDate'] as String)
            : null,
        completionDate: json['completionDate'] != null
            ? DateTime.parse(json['completionDate'] as String)
            : null,
        photoPaths: (json['photoPaths'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        tags: normalizeTags(
          (json['tags'] as List<dynamic>?)
                  ?.map((e) => e.toString())
                  .toList() ??
              [],
        ),
        notes: json['notes'] as String?,
      );
}
