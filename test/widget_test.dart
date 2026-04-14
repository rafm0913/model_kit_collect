import 'package:flutter_test/flutter_test.dart';
import 'package:model_kit_collect/models/model_kit.dart';

void main() {
  test('ModelKit JSON can round-trip', () {
    final original = ModelKit(
      id: 'kit-001',
      category: '鋼彈',
      name: '我的第一盒',
      manufacturer: 'Bandai',
      grade: 'RG',
      mobileSuitName: 'RX-78-2 GUNDAM',
      scale: '1/144',
      status: '組裝中',
      statusOther: null,
      purchaseAmount: 1280,
      purchaseSource: '模型店',
      purchaseDate: DateTime(2026, 4, 10),
      notes: 'test note',
      statusLogs: [
        StatusLog(
          status: '全新',
          changedAt: DateTime.utc(2026, 4, 10, 8, 0, 0),
        ),
      ],
    );

    final json = original.toJson();
    final restored = ModelKit.fromJson(json);

    expect(restored.id, original.id);
    expect(restored.name, original.name);
    expect(restored.category, original.category);
    expect(restored.manufacturer, original.manufacturer);
    expect(restored.grade, original.grade);
    expect(restored.mobileSuitName, original.mobileSuitName);
    expect(restored.scale, original.scale);
    expect(restored.status, original.status);
    expect(restored.purchaseAmount, original.purchaseAmount);
    expect(restored.purchaseSource, original.purchaseSource);
    expect(restored.purchaseDate, original.purchaseDate);
    expect(restored.notes, original.notes);
    expect(restored.statusLogs.length, original.statusLogs.length);
    expect(restored.statusLogs.first.status, original.statusLogs.first.status);
  });
}
