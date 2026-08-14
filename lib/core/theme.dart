import 'package:flutter/material.dart';

import 'material_theme.dart';

/// EventEase theme — red brand color matching the SRS artwork.
class AppTheme {
  static const brand = Color(0xFFD32F2F);

  static ThemeData get light => _theme(EventEaseColorSchemes.light);

  static ThemeData get dark => _theme(EventEaseColorSchemes.dark);

  static ThemeData _theme(ColorScheme colorScheme) => ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        appBarTheme: AppBarTheme(centerTitle: true, backgroundColor: colorScheme.surface),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: const OutlineInputBorder(),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: colorScheme.outline),
          ),
          filled: true,
          fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: .35),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            shape: const StadiumBorder(),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            shape: const StadiumBorder(),
          ),
        ),
        chipTheme: ChipThemeData(
          shape: const StadiumBorder(),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
        dialogTheme: DialogThemeData(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
}
