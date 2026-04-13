import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/model_kit.dart';

/// 負責模型資料的雲端儲存與讀取
class StorageService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String get _userId {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('使用者尚未登入');
    }
    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> get _kitsCollection => _firestore
      .collection('users')
      .doc(_userId)
      .collection('model_kits');

  Future<List<ModelKit>> loadModelKits() async {
    try {
      final snapshot = await _kitsCollection
          .orderBy('updatedAt', descending: true)
          .get()
          .timeout(const Duration(seconds: 12));
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return ModelKit.fromJson(data);
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> upsertModelKit(ModelKit kit) async {
    await _kitsCollection.doc(kit.id).set({
      ...kit.toJson(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true)).timeout(const Duration(seconds: 12));
  }

  Future<void> deleteModelKit(String modelKitId) async {
    await _kitsCollection
        .doc(modelKitId)
        .delete()
        .timeout(const Duration(seconds: 12));
  }

  Future<List<String>> loadAllTags() async {
    final kits = await loadModelKits();
    final tags = <String>{};
    for (final kit in kits) {
      tags.addAll(ModelKit.normalizeTags(kit.tags));
    }
    final sorted = tags.toList()..sort((a, b) => a.compareTo(b));
    return sorted;
  }

  Future<Map<String, int>> loadTagUsageCounts() async {
    final kits = await loadModelKits();
    final counts = <String, int>{};
    for (final kit in kits) {
      final tags = ModelKit.normalizeTags(kit.tags);
      for (final tag in tags) {
        counts[tag] = (counts[tag] ?? 0) + 1;
      }
    }
    return counts;
  }

  /// 批次替換所有紀錄中的標籤（toTag 為 null 時等同刪除）
  Future<int> replaceTagInAllKits({
    required String fromTag,
    String? toTag,
  }) async {
    final normalizedFrom = ModelKit.normalizeTag(fromTag);
    final normalizedTo = toTag == null ? null : ModelKit.normalizeTag(toTag);
    if (normalizedFrom.isEmpty) return 0;
    if (normalizedTo != null && normalizedTo == normalizedFrom) return 0;

    final kits = await loadModelKits();
    final batch = _firestore.batch();
    var changedCount = 0;

    for (final kit in kits) {
      final tags = ModelKit.normalizeTags(kit.tags);
      if (!tags.contains(normalizedFrom)) continue;

      final updated = tags.where((tag) => tag != normalizedFrom).toList();
      if (normalizedTo != null &&
          normalizedTo.isNotEmpty &&
          !updated.contains(normalizedTo)) {
        updated.add(normalizedTo);
      }

      batch.set(_kitsCollection.doc(kit.id), {
        'tags': updated,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      changedCount++;
    }

    if (changedCount > 0) {
      await batch.commit().timeout(const Duration(seconds: 12));
    }
    return changedCount;
  }
}
