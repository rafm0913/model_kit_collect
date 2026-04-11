import 'package:flutter_test/flutter_test.dart';
import 'package:model_kit_collect/models/model_kit.dart';

void main() {
  test('ModelKit JSON can round-trip', () {
    final original = ModelKit(
      id: 'kit-001',
      modelNumber: 'RG 1/144 RX-78-2',
      purchaseDate: DateTime(2026, 4, 10),
      assemblyStartDate: DateTime(2026, 4, 11),
      completionDate: DateTime(2026, 4, 12),
      photoPaths: const ['https://example.com/photo.jpg'],
      notes: 'test note',
    );

    final json = original.toJson();
    final restored = ModelKit.fromJson(json);

    expect(restored.id, original.id);
    expect(restored.modelNumber, original.modelNumber);
    expect(restored.purchaseDate, original.purchaseDate);
    expect(restored.assemblyStartDate, original.assemblyStartDate);
    expect(restored.completionDate, original.completionDate);
    expect(restored.photoPaths, original.photoPaths);
    expect(restored.notes, original.notes);
  });
}
