import 'package:flutter/material.dart';
import 'package:short_url_mobile/core/theme/app_color.dart';
import 'package:short_url_mobile/core/theme/app_dimension.dart';
import 'package:short_url_mobile/core/theme/app_text.dart';

class AppTheme {
  // Light Theme
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: AppColors.primaryBlue,
      primaryContainer: AppColors.primaryDarkBlue,
      secondary: AppColors.secondary,
      onPrimary: AppColors.white,
      error: AppColors.error,
      surface: AppColors.lightBackground,
    ),
    scaffoldBackgroundColor: AppColors.lightBackground,

    // Text Theme
    textTheme: TextTheme(
      displayLarge: AppText.h1.copyWith(color: AppColors.black),
      displayMedium: AppText.h2.copyWith(color: AppColors.black),
      displaySmall: AppText.h3.copyWith(color: AppColors.black),
      bodyLarge: AppText.bodyLarge.copyWith(color: AppColors.black),
      bodyMedium: AppText.bodyMedium.copyWith(color: AppColors.black),
      bodySmall: AppText.bodySmall.copyWith(color: Colors.black87),
      labelLarge: AppText.button.copyWith(color: AppColors.white),
      titleMedium: AppText.bodyLarge.copyWith(
        color: AppColors.black,
        fontWeight: FontWeight.w500,
      ),
      titleSmall: AppText.bodyMedium.copyWith(
        color: AppColors.black,
        fontWeight: FontWeight.w500,
      ),
      labelSmall: AppText.caption.copyWith(color: Colors.black54),
    ),

    // Button Theme
    buttonTheme: ButtonThemeData(
      buttonColor: AppColors.primaryBlue,
      textTheme: ButtonTextTheme.primary,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.md,
        vertical: AppDimensions.sm,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      ),
      height: AppDimensions.buttonHeight,
    ),

    // AppBar Theme
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.primaryBlue,
      foregroundColor: AppColors.white,
      elevation: AppDimensions.elevationMd,
      centerTitle: false,
      titleTextStyle: AppText.h3,
    ),

    // Card Theme
    cardTheme: CardTheme(
      elevation: AppDimensions.elevationMd,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      ),
      color: AppColors.white,
      margin: const EdgeInsets.all(AppDimensions.sm),
    ),

    // Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.md,
        vertical: AppDimensions.md,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        borderSide: const BorderSide(color: AppColors.grey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      floatingLabelStyle: AppText.bodySmall.copyWith(
        color: AppColors.primaryBlue,
      ),
    ),

    // Elevated Button Theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all(AppColors.primaryBlue),
        foregroundColor: WidgetStateProperty.all(AppColors.white),
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(
            horizontal: AppDimensions.md,
            vertical: AppDimensions.sm,
          ),
        ),
        minimumSize: WidgetStateProperty.all(
          const Size.fromHeight(AppDimensions.buttonHeight),
        ),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
        ),
        textStyle: WidgetStateProperty.all(AppText.button),
      ),
    ),

    // Outlined Button Theme
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.all(AppColors.primaryBlue),
        side: WidgetStateProperty.all(
          const BorderSide(color: AppColors.primaryBlue),
        ),
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(
            horizontal: AppDimensions.md,
            vertical: AppDimensions.sm,
          ),
        ),
        minimumSize: WidgetStateProperty.all(
          const Size.fromHeight(AppDimensions.buttonHeight),
        ),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
        ),
        textStyle: WidgetStateProperty.all(AppText.button),
      ),
    ),

    // Text Button Theme
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.all(AppColors.primaryBlue),
        textStyle: WidgetStateProperty.all(AppText.button),
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(
            horizontal: AppDimensions.sm,
            vertical: AppDimensions.xs,
          ),
        ),
      ),
    ),

    // Divider
    dividerTheme: const DividerThemeData(
      color: AppColors.lightGrey,
      thickness: 1,
      space: AppDimensions.md,
    ),

    // Dialog
    dialogTheme: DialogTheme(
      backgroundColor: AppColors.white,
      elevation: AppDimensions.elevationLg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      ),
    ),

    // Checkbox
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.primaryBlue;
        }
        return AppColors.lightGrey;
      }),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusXs),
      ),
    ),

    // Snackbar
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.black,
      contentTextStyle: AppText.bodyMedium.copyWith(color: AppColors.white),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      ),
    ),
  );

  // Dark Theme
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primaryDarkBlue,
      primaryContainer: AppColors.primaryBlue,
      secondary: AppColors.secondary,
      onPrimary: AppColors.white,
      error: AppColors.error,
      surface: AppColors.darkBackground,
    ),
    scaffoldBackgroundColor: AppColors.darkBackground,

    // Text Theme
    textTheme: TextTheme(
      displayLarge: AppText.h1.copyWith(color: AppColors.white),
      displayMedium: AppText.h2.copyWith(color: AppColors.white),
      displaySmall: AppText.h3.copyWith(color: AppColors.white),
      bodyLarge: AppText.bodyLarge.copyWith(color: AppColors.white),
      bodyMedium: AppText.bodyMedium.copyWith(color: AppColors.white),
      bodySmall: AppText.bodySmall.copyWith(color: Colors.white70),
      labelLarge: AppText.button.copyWith(color: AppColors.white),
      titleMedium: AppText.bodyLarge.copyWith(
        color: AppColors.white,
        fontWeight: FontWeight.w500,
      ),
      titleSmall: AppText.bodyMedium.copyWith(
        color: AppColors.white,
        fontWeight: FontWeight.w500,
      ),
      labelSmall: AppText.caption.copyWith(color: Colors.white54),
    ),

    // Button Theme
    buttonTheme: ButtonThemeData(
      buttonColor: AppColors.primaryDarkBlue,
      textTheme: ButtonTextTheme.primary,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.md,
        vertical: AppDimensions.sm,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      ),
      height: AppDimensions.buttonHeight,
    ),

    // AppBar Theme
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1E1E1E),
      foregroundColor: AppColors.white,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: AppText.h3,
    ),

    // Card Theme
    cardTheme: CardTheme(
      elevation: AppDimensions.elevationMd,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      ),
      color: const Color(0xFF2C2C2C),
      margin: const EdgeInsets.all(AppDimensions.sm),
    ),

    // Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.md,
        vertical: AppDimensions.md,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        borderSide: const BorderSide(color: AppColors.grey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        borderSide: const BorderSide(
          color: AppColors.primaryDarkBlue,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      floatingLabelStyle: AppText.bodySmall.copyWith(
        color: AppColors.primaryDarkBlue,
      ),
      filled: true,
      fillColor: const Color(0xFF1E1E1E),
    ),

    // Elevated Button Theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all(AppColors.primaryDarkBlue),
        foregroundColor: WidgetStateProperty.all(AppColors.white),
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(
            horizontal: AppDimensions.md,
            vertical: AppDimensions.sm,
          ),
        ),
        minimumSize: WidgetStateProperty.all(
          const Size.fromHeight(AppDimensions.buttonHeight),
        ),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
        ),
        textStyle: WidgetStateProperty.all(AppText.button),
      ),
    ),

    // Outlined Button Theme
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.all(AppColors.primaryDarkBlue),
        side: WidgetStateProperty.all(
          const BorderSide(color: AppColors.primaryDarkBlue),
        ),
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(
            horizontal: AppDimensions.md,
            vertical: AppDimensions.sm,
          ),
        ),
        minimumSize: WidgetStateProperty.all(
          const Size.fromHeight(AppDimensions.buttonHeight),
        ),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
        ),
        textStyle: WidgetStateProperty.all(AppText.button),
      ),
    ),

    // Text Button Theme
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.all(AppColors.primaryDarkBlue),
        textStyle: WidgetStateProperty.all(AppText.button),
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(
            horizontal: AppDimensions.sm,
            vertical: AppDimensions.xs,
          ),
        ),
      ),
    ),

    // Divider
    dividerTheme: const DividerThemeData(
      color: Color(0xFF3E3E3E),
      thickness: 1,
      space: AppDimensions.md,
    ),

    // Dialog
    dialogTheme: DialogTheme(
      backgroundColor: const Color(0xFF2C2C2C),
      elevation: AppDimensions.elevationLg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      ),
    ),

    // Checkbox
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.primaryDarkBlue;
        }
        return AppColors.grey;
      }),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusXs),
      ),
    ),

    // Snackbar
    snackBarTheme: SnackBarThemeData(
      backgroundColor: Colors.grey[800],
      contentTextStyle: AppText.bodyMedium.copyWith(color: AppColors.white),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      ),
    ),
  );
}
