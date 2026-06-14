import 'package:flutter/material.dart';

abstract final class Mg {
  static const paper      = Color(0xFFF5EFE3);
  static const surface    = Color(0xFFFFFDF8);
  static const ink        = Color(0xFF2B2722);
  static const muted1     = Color(0xFF8A8174);
  static const muted2     = Color(0xFFA89E8C);
  static const muted3     = Color(0xFFB3A892);
  static const border     = Color(0xFFECE2CF);
  static const border2    = Color(0xFFE8DEC9);
  static const divider    = Color(0xFFEFE6D4);
  static const tray       = Color(0xFFECE3D2);
  static const trayBorder = Color(0xFFE2D8C2);
  static const blue       = Color(0xFF3B6FD4);
  static const blueTint   = Color(0xFFEAF0FB);
  static const blueHi     = Color(0xFFD8E3F8);
  static const amber      = Color(0xFFB6852A);
  static const amberTint  = Color(0xFFF6EFDD);
  static const amberHi    = Color(0xFFECDFBF);
  static const green      = Color(0xFF3B9E63);
  static const red        = Color(0xFFC0563F);
  static const tagBg      = Color(0xFFF1E9DA);
  static const tagBorder  = Color(0xFFE8DEC9);

  static ThemeData theme() => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: paper,
    colorScheme: const ColorScheme.light(
      primary: blue,
      surface: surface,
      onPrimary: Color(0xFFFFFDF8),
      onSurface: ink,
      outline: Color(0xFFECE2CF),
    ),
    dividerColor: divider,
    cardColor: surface,
    dialogTheme: const DialogThemeData(backgroundColor: surface),
    textSelectionTheme: const TextSelectionThemeData(
      selectionColor: Color(0xFFD9E3F7),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: ink,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}
