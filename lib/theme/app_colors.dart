import 'package:flutter/material.dart';

/// 應用程式顏色定義
/// 參考 Assembly Pro 設計系統 + Access Terminal 風格
class AppColors {
  AppColors._();

  // === 主色調 ===
  static const Color primary = Color(0xFFFF6B00); // 主色（橘色）
  static const Color secondary = Color(0xFF007AFF); // 次要色（藍色）
  static const Color tertiary = Color(0xFFE5A102); // 第三色（金黃）

  // === 背景色 ===
  static const Color background = Color(0xFF121417); // 主背景
  static const Color backgroundDark = Color(0xFF0A0A0A); // 深色背景（登入頁）
  static const Color cardBackground = Color(0xFF121212); // 卡片背景
  static const Color buttonBackground = Color(0xFF1A1A1A); // 按鈕背景（深色）
  static const Color whiteBackground = Color(0xFFFFFFFF); // 背景圖背景（白色）

  // === 文字色 ===
  static const Color textPrimary = Color(0xFFFFFFFF); // 主要文字（白）
  static const Color textSecondary = Color(0xFFCCCCCC); // 次要文字（淺灰）
  static const Color textMuted = Color(0xFF888888); // 弱化文字
  static const Color textLabel = Color(0xFF444444); // 標籤文字（深灰）

  // === 邊框與分隔 ===
  static const Color border = Color(0xFF333333);
  static const Color borderLight = Color(0xFF444444);

  // === 狀態色 ===
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFE53935);
  static const Color warning = Color(0xFFE5A102);
}
