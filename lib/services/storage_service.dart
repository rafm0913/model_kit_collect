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
}
