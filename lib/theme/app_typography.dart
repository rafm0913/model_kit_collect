import 'package:flutter/material.dart';

/// 應用程式字體大小與樣式定義
class AppTypography {
  AppTypography._();

  // === 字體大小 ===
  static const double sizeHeadline = 32;
  static const double sizeTitle = 24;
  static const double sizeSubtitle = 18;
  static const double sizeBody = 16;
  static const double sizeBodySmall = 14;
  static const double sizeLabel = 12;
  static const double sizeCaption = 10;

  // === 字重 ===
  static const FontWeight weightBold = FontWeight.w700;
  static const FontWeight weightMedium = FontWeight.w500;
  static const FontWeight weightRegular = FontWeight.w400;

  // === 預設文字樣式 ===
  static TextStyle get headline => const TextStyle(
        fontSize: sizeHeadline,
        fontWeight: weightBold,
        letterSpacing: 0,
      );

  static TextStyle get title => const TextStyle(
        fontSize: sizeTitle,
        fontWeight: weightBold,
      );

  static TextStyle get subtitle => const TextStyle(
        fontSize: sizeSubtitle,
        fontWeight: weightMedium,
      );

  static TextStyle get body => const TextStyle(
        fontSize: sizeBody,
        fontWeight: weightRegular,
      );

  static TextStyle get bodySmall => const TextStyle(
        fontSize: sizeBodySmall,
        fontWeight: weightRegular,
      );

  static TextStyle get label => const TextStyle(
        fontSize: sizeLabel,
        fontWeight: weightMedium,
        letterSpacing: 1.2,
      );

  static TextStyle get caption => const TextStyle(
        fontSize: sizeCaption,
        fontWeight: weightRegular,
        letterSpacing: 1.5,
      );
}
