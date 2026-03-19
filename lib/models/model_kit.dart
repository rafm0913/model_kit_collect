/// 模型套件資料模型
class ModelKit {
  final String id;
  final String modelNumber; // 編號
  final DateTime? purchaseDate; // 購買日期
  final DateTime? assemblyStartDate; // 組裝開始日期
  final DateTime? completionDate; // 完成日期
  final List<String> photoPaths; // 照片路徑列表
  final String? notes; // 備註

  const ModelKit({
    required this.id,
    required this.modelNumber,
    this.purchaseDate,
    this.assemblyStartDate,
    this.completionDate,
    this.photoPaths = const [],
    this.notes,
  });

  ModelKit copyWith({
    String? id,
    String? modelNumber,
    DateTime? purchaseDate,
    DateTime? assemblyStartDate,
    DateTime? completionDate,
    List<String>? photoPaths,
    String? notes,
  }) {
    return ModelKit(
      id: id ?? this.id,
      modelNumber: modelNumber ?? this.modelNumber,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      assemblyStartDate: assemblyStartDate ?? this.assemblyStartDate,
      completionDate: completionDate ?? this.completionDate,
      photoPaths: photoPaths ?? this.photoPaths,
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
        notes: json['notes'] as String?,
      );
}
