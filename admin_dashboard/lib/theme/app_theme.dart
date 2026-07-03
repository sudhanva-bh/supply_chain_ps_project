import 'package:flutter/material.dart';

class AppTheme {
  static const Color background = Color(0xFF121212);
  static const Color surface = Color(0xFF1E1E1E);
  static const Color surfaceVariant = Color(0xFF2A2A2A);
  static const Color primaryText = Color(0xFFE0E0E0);
  static const Color secondaryText = Color(0xFF9E9E9E);
  static const Color dividerColor = Color(0xFF333333);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: primaryText,
        onPrimary: background,
        secondary: secondaryText,
        onSecondary: background,
        surface: surface,
        onSurface: primaryText,
        error:
            primaryText, // Using primary text or light grey for errors to maintain monochromatic
        onError: background,
      ),
      dividerTheme: const DividerThemeData(
        color: dividerColor,
        thickness: 1,
        space: 1,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent, // Handled by GlassContainer
        elevation: 0,
        iconTheme: IconThemeData(color: primaryText),
        titleTextStyle: TextStyle(
          color: primaryText,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: Colors.transparent, // Handled by GlassContainer
        elevation: 0,
      ),
      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStateProperty.all(surfaceVariant),
        dataRowColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered)) {
            return surfaceVariant.withValues(alpha: 0.5);
          }
          return surface;
        }),
        dividerThickness: 1,
        decoration: BoxDecoration(
          border: Border.all(color: dividerColor),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: surfaceVariant,
        contentTextStyle: TextStyle(color: primaryText),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          side: BorderSide(color: dividerColor),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
