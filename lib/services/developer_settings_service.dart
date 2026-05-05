import 'package:shared_preferences/shared_preferences.dart';

/// 開發者選項（目前僅「測試模式」開關）。
class DeveloperSettingsService {
  static const _keyTestMode = 'developer_test_mode';

  Future<bool> isTestModeEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyTestMode) ?? false;
  }

  Future<void> setTestModeEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyTestMode, value);
  }
}
