import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/model_kit.dart';

/// 負責模型資料與照片的儲存與讀取
class StorageService {
  static const String _dataFileName = 'model_kits.json';

  Future<Directory> get _appDir async {
    final dir = await getApplicationDocumentsDirectory();
    final modelKitDir = Directory('${dir.path}/model_kit_collect');
    if (!await modelKitDir.exists()) {
      await modelKitDir.create(recursive: true);
    }
    return modelKitDir;
  }

  Future<File> get _dataFile async {
    final dir = await _appDir;
    return File('${dir.path}/$_dataFileName');
  }

  Future<List<ModelKit>> loadModelKits() async {
    try {
      final file = await _dataFile;
      if (!await file.exists()) return [];
      final content = await file.readAsString();
      final list = jsonDecode(content) as List<dynamic>;
      return list
          .map((e) => ModelKit.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveModelKits(List<ModelKit> kits) async {
    final file = await _dataFile;
    final json = jsonEncode(kits.map((e) => e.toJson()).toList());
    await file.writeAsString(json);
  }

  /// 儲存照片到 app 目錄，回傳相對路徑
  Future<String> savePhoto(File sourceFile, String modelKitId) async {
    final dir = await _appDir;
    final photosDir = Directory('${dir.path}/photos/$modelKitId');
    if (!await photosDir.exists()) {
      await photosDir.create(recursive: true);
    }
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final ext = sourceFile.path.split('.').last;
    final destPath = '${photosDir.path}/$timestamp.$ext';
    await sourceFile.copy(destPath);
    return destPath;
  }

  /// 刪除照片檔案
  Future<void> deletePhoto(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }

  /// 刪除模型的所有照片
  Future<void> deleteModelPhotos(String modelKitId) async {
    try {
      final dir = await _appDir;
      final photosDir = Directory('${dir.path}/photos/$modelKitId');
      if (await photosDir.exists()) {
        await photosDir.delete(recursive: true);
      }
    } catch (_) {}
  }
}
