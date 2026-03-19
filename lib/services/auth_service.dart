import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';

import '../config/auth_config.dart';

/// Firebase 認證服務，負責 Google 登入
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late final GoogleSignIn _googleSignIn = GoogleSignIn(
    // 網頁版：必須設定 clientId
    // iOS/Android：必須設定 serverClientId（Web Client ID）才能取得 idToken 給 Firebase
    clientId: kIsWeb ? webGoogleClientId : null,
    serverClientId: kIsWeb ? null : webGoogleClientId,
  );

  /// 目前登入的使用者
  User? get currentUser => _auth.currentUser;

  /// 登入狀態變化串流
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// 使用 Google 帳號登入
  Future<User?> signInWithGoogle() async {
    try {
      // 觸發 Google 登入流程
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      // 取得 Google 的認證憑證
      final googleAuth = await googleUser.authentication;

      // 建立 Firebase 認證憑證
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 使用憑證登入 Firebase
      final userCredential = await _auth.signInWithCredential(credential);
      return userCredential.user;
    } catch (e) {
      rethrow;
    }
  }

  /// 登出
  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }
}
