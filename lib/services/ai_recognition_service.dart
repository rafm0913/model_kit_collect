import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';

class AIRecognitionConfidence {
  final double manufacturer;
  final double grade;
  final double mobileSuitName;
  final double scale;

  const AIRecognitionConfidence({
    required this.manufacturer,
    required this.grade,
    required this.mobileSuitName,
    required this.scale,
  });

  factory AIRecognitionConfidence.fromJson(Map<String, dynamic> json) {
    double normalize(dynamic raw) {
      if (raw is num) return raw.toDouble();
      if (raw is String) return double.tryParse(raw.trim()) ?? 0;
      return 0;
    }

    return AIRecognitionConfidence(
      manufacturer: normalize(json['manufacturer']),
      grade: normalize(json['grade']),
      mobileSuitName: normalize(json['mobileSuitName']),
      scale: normalize(json['scale']),
    );
  }
}

class AIRecognitionResult {
  final String? manufacturer;
  final String? grade;
  final String? mobileSuitName;
  final String? scale;
  final AIRecognitionConfidence? confidence;
  final List<String> rawText;

  const AIRecognitionResult({
    this.manufacturer,
    this.grade,
    this.mobileSuitName,
    this.scale,
    this.confidence,
    this.rawText = const [],
  });

  factory AIRecognitionResult.fromJson(Map<String, dynamic> json) {
    String? normalize(dynamic raw) {
      if (raw == null) return null;
      final v = raw.toString().trim();
      return v.isEmpty ? null : v;
    }

    AIRecognitionConfidence? parseConfidence(dynamic raw) {
      if (raw is Map<String, dynamic>)
        return AIRecognitionConfidence.fromJson(raw);
      return null;
    }

    List<String> parseRawText(dynamic raw) {
      if (raw is List) {
        return raw
            .map((e) => e?.toString().trim() ?? '')
            .where((e) => e.isNotEmpty)
            .toList();
      }
      return const [];
    }

    return AIRecognitionResult(
      manufacturer: normalize(json['manufacturer']),
      grade: normalize(json['grade']),
      mobileSuitName: normalize(json['mobileSuitName']),
      scale: normalize(json['scale']),
      confidence: parseConfidence(json['confidence']),
      rawText: parseRawText(json['rawText']),
    );
  }
}

class AIRecognitionService {
  final String endpoint;

  const AIRecognitionService({
    this.endpoint = 'https://api.dellspot.org/api/v1/ai/recognize-box',
  });

  Future<String> _getFirebaseBearerToken() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception('請先登入後再使用 AI 搜尋');
    }

    // 避免拿到過期 token（後端通常會以 Firebase Admin 驗證 JWT）
    final idToken = await currentUser.getIdToken(true);

    if (idToken == null || idToken.trim().isEmpty) {
      throw Exception('取得登入憑證失敗，請重新登入後再試一次');
    }
    return idToken;
  }

  Future<AIRecognitionResult> recognizeFromImagePath(String imagePath) async {
    final bearerToken = await _getFirebaseBearerToken();

    final header = decodeJwtHeader(bearerToken);
    print('jwt header: $header');
    print('alg: ${header['alg']}');

    final file = File(imagePath);
    final imageBytes = await file.readAsBytes();
    final imageB64 = base64Encode(imageBytes);

    final payload = jsonEncode({
      'imagesBase64': [imageB64],
    });

    final uri = Uri.parse(endpoint);
    final httpClient = HttpClient();
    try {
      final request = await httpClient.postUrl(uri);
      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      request.headers.set(
        HttpHeaders.authorizationHeader,
        'Bearer $bearerToken',
      );
      request.write(payload);
      final response = await request.close();
      final responseText = await response.transform(utf8.decoder).join();

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('辨識失敗（${response.statusCode}）：$responseText');
      }

      final decoded = jsonDecode(responseText);
      if (decoded is! Map<String, dynamic>) {
        throw Exception('辨識回應格式不正確：$responseText');
      }

      final payloadMap = (decoded['data'] is Map<String, dynamic>)
          ? (decoded['data'] as Map<String, dynamic>)
          : (decoded['result'] is Map<String, dynamic>)
          ? (decoded['result'] as Map<String, dynamic>)
          : decoded;

      return AIRecognitionResult.fromJson(payloadMap);
    } finally {
      httpClient.close();
    }
  }

  Map<String, dynamic> decodeJwtHeader(String jwt) {
    final parts = jwt.split('.');
    if (parts.length != 3) {
      throw FormatException('這不是 JWT（應該是 header.payload.signature 三段）');
    }
    final headerB64 = parts[0];
    final normalized = base64Url.normalize(headerB64);
    final headerJson = utf8.decode(base64Url.decode(normalized));
    final header = jsonDecode(headerJson);
    if (header is! Map<String, dynamic>) {
      throw FormatException('JWT header 不是 JSON object');
    }
    return header;
  }
}
