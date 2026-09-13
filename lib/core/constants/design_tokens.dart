import 'package:flutter/material.dart';

abstract final class AppColors {
  // A crisp glacial blue palette keeps the product technical, calm, and premium.
  static const accent = Color(0xFF50C7FF);
  static const accentDeep = Color(0xFF1479ED);
  static const cyan = Color(0xFF68E0F0);
  static const navy = Color(0xFF0B3263);
  static const navyDeep = Color(0xFF06182F);
  static const brass = Color(0xFFA47B3C);
  static const brassMist = Color(0xFFF5EFE5);
  static const ink = Color(0xFF132238);
  static const mist = Color(0xFFEAF5FF);
  static const success = Color(0xFF42C996);
  static const warning = Color(0xFFFFB85C);
  static const danger = Color(0xFFFF6B75);
  static const lightBackground = Color(0xFFF5F8FC);
  static const lightSurface = Color(0xFFFFFFFF);
  static const darkBackground = Color(0xFF0B0F14);
  static const darkSurface = Color(0xFF141A22);
}

abstract final class AppSpacing {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
}

abstract final class AppRadius {
  static const small = 12.0;
  static const medium = 18.0;
  static const large = 24.0;
  static const extraLarge = 32.0;
  static const pill = 999.0;
}

abstract final class AppDuration {
  static const fast = Duration(milliseconds: 160);
  static const normal = Duration(milliseconds: 260);
  static const slow = Duration(milliseconds: 420);
}

abstract final class AppIconSize {
  static const small = 18.0;
  static const medium = 22.0;
  static const large = 28.0;
}
