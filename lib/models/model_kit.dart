/// 模型收藏資料模型
class ModelKit {
  static const String otherOption = 'Other';

  static const List<String> categoryOptions = ['鋼彈', '其它'];
  static const List<String> manufacturerOptions = [
    'Bandai',
    'Kotobukiya',
    'Tamiya',
    'Hasegawa',
    'Aoshima',
    'Good Smile Company',
    'Max Factory',
    'Academy',
    'Fujimi',
    'Revell',
    'Trumpeter',
    otherOption,
  ];
  static const List<String> gradeOptions = [
    'EG',
    'HG',
    'RG',
    'MG',
    'MGEX',
    'Re100',
    'FM',
    'PG',
    'PGU',
    'MEGA SIZE MODEL',
    otherOption,
  ];
  static const List<String> statusOptions = [
    '已預購',
    '全新',
    '組裝中',
    '上色中',
    '已組裝',
    '已上色',
    '完成',
    '其他',
  ];

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

  final String id;
  final String category;
  final String? categoryOther;
  final String name;
  final int? quantity;
  final String manufacturer;
  final String? manufacturerOther;
  final String grade;
  final String? gradeOther;
  final String mobileSuitName;
  final String scale;
  final String status;
  final String? statusOther;
  final double? purchaseAmount;
  final String purchaseSource;
  final DateTime? purchaseDate;
  final String? notes;
  final List<String> tags;
  final List<StatusLog> statusLogs;

  const ModelKit({
    required this.id,
    required this.category,
    this.categoryOther,
    required this.name,
    this.quantity,
    required this.manufacturer,
    this.manufacturerOther,
    required this.grade,
    this.gradeOther,
    required this.mobileSuitName,
    required this.scale,
    required this.status,
    this.statusOther,
    this.purchaseAmount,
    this.purchaseSource = '',
    this.purchaseDate,
    this.notes,
    this.tags = const [],
    this.statusLogs = const [],
  });

  String get displayCategory {
    if (category == '其它' &&
        categoryOther != null &&
        categoryOther!.isNotEmpty) {
      return categoryOther!;
    }
    return category;
  }

  String get displayManufacturer {
    if (manufacturer == otherOption &&
        manufacturerOther != null &&
        manufacturerOther!.isNotEmpty) {
      return manufacturerOther!;
    }
    return manufacturer;
  }

  String get displayGrade {
    if (grade == otherOption && gradeOther != null && gradeOther!.isNotEmpty) {
      return gradeOther!;
    }
    return grade;
  }

  String get displayStatus {
    if (status == '其他' && statusOther != null && statusOther!.isNotEmpty) {
      return statusOther!;
    }
    return status;
  }

  ModelKit copyWith({
    String? id,
    String? category,
    String? categoryOther,
    String? name,
    int? quantity,
    String? manufacturer,
    String? manufacturerOther,
    String? grade,
    String? gradeOther,
    String? mobileSuitName,
    String? scale,
    String? status,
    String? statusOther,
    double? purchaseAmount,
    String? purchaseSource,
    DateTime? purchaseDate,
    String? notes,
    List<String>? tags,
    List<StatusLog>? statusLogs,
  }) {
    return ModelKit(
      id: id ?? this.id,
      category: category ?? this.category,
      categoryOther: categoryOther ?? this.categoryOther,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      manufacturer: manufacturer ?? this.manufacturer,
      manufacturerOther: manufacturerOther ?? this.manufacturerOther,
      grade: grade ?? this.grade,
      gradeOther: gradeOther ?? this.gradeOther,
      mobileSuitName: mobileSuitName ?? this.mobileSuitName,
      scale: scale ?? this.scale,
      status: status ?? this.status,
      statusOther: statusOther ?? this.statusOther,
      purchaseAmount: purchaseAmount ?? this.purchaseAmount,
      purchaseSource: purchaseSource ?? this.purchaseSource,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      notes: notes ?? this.notes,
      tags: tags ?? this.tags,
      statusLogs: statusLogs ?? this.statusLogs,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'category': category,
    'categoryOther': categoryOther,
    'name': name,
    'quantity': quantity,
    'manufacturer': manufacturer,
    'manufacturerOther': manufacturerOther,
    'grade': grade,
    'gradeOther': gradeOther,
    'mobileSuitName': mobileSuitName,
    'scale': scale,
    'status': status,
    'statusOther': statusOther,
    'purchaseAmount': purchaseAmount,
    'purchaseSource': purchaseSource,
    'purchaseDate': purchaseDate?.toIso8601String(),
    'notes': notes,
    'tags': normalizeTags(tags),
    'statusLogs': statusLogs.map((log) => log.toJson()).toList(),
  };

  factory ModelKit.fromJson(Map<String, dynamic> json) {
    final legacyModelNumber = (json['modelNumber'] as String?) ?? '';
    final legacyTags =
        (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
        const <String>[];
    final statusLogsRaw = (json['statusLogs'] as List<dynamic>?) ?? const [];

    return ModelKit(
      id: json['id'] as String,
      category:
          (json['category'] as String?) ??
          (legacyTags.isNotEmpty ? legacyTags.first : categoryOptions.first),
      categoryOther: json['categoryOther'] as String?,
      name:
          (json['name'] as String?) ??
          ((legacyModelNumber.isNotEmpty) ? legacyModelNumber : '未命名收藏'),
      quantity: _parseQuantity(json['quantity']),
      manufacturer: (json['manufacturer'] as String?) ?? otherOption,
      manufacturerOther: json['manufacturerOther'] as String?,
      grade: (json['grade'] as String?) ?? otherOption,
      gradeOther: json['gradeOther'] as String?,
      mobileSuitName: (json['mobileSuitName'] as String?) ?? '',
      scale: (json['scale'] as String?) ?? '',
      status:
          (json['status'] as String?) ??
          (json['completionDate'] != null
              ? '完成'
              : (json['assemblyStartDate'] != null ? '組裝中' : '全新')),
      statusOther: json['statusOther'] as String?,
      purchaseAmount: _parsePurchaseAmount(json['purchaseAmount']),
      purchaseSource: (json['purchaseSource'] as String?) ?? '',
      purchaseDate: json['purchaseDate'] != null
          ? DateTime.parse(json['purchaseDate'] as String)
          : null,
      notes: json['notes'] as String?,
      tags: normalizeTags(legacyTags),
      statusLogs: statusLogsRaw
          .whereType<Map<String, dynamic>>()
          .map(StatusLog.fromJson)
          .toList(),
    );
  }

  static double? _parsePurchaseAmount(dynamic raw) {
    if (raw == null) return null;
    if (raw is num) return raw.toDouble();
    return double.tryParse(raw.toString());
  }

  static int? _parseQuantity(dynamic raw) {
    if (raw == null) return null;
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return int.tryParse(raw.toString());
  }
}

class StatusLog {
  final String status;
  final String? statusOther;
  final DateTime changedAt;

  const StatusLog({
    required this.status,
    this.statusOther,
    required this.changedAt,
  });

  String get displayStatus {
    if (status == '其他' && statusOther != null && statusOther!.isNotEmpty) {
      return statusOther!;
    }
    return status;
  }

  Map<String, dynamic> toJson() => {
    'status': status,
    'statusOther': statusOther,
    'changedAt': changedAt.toIso8601String(),
  };

  factory StatusLog.fromJson(Map<String, dynamic> json) => StatusLog(
    status: (json['status'] as String?) ?? '其他',
    statusOther: json['statusOther'] as String?,
    changedAt: json['changedAt'] != null
        ? DateTime.parse(json['changedAt'] as String)
        : DateTime.now(),
  );
}
