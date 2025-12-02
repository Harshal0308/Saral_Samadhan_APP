import 'package:flutter/material.dart';

class SaralColors {
  // Extracted/approximated from Saral UI CSS variables
  static const Color background = Color(0xFFFFFFFF);
  static const Color card = Color(0xFFFFFFFF);
  // Purple-ish Saral primary to match provided UI
  static const Color primary = Color(0xFF6F46FF);
  static const Color foreground = Color(0xFF0B1220);
  static const Color secondary = Color(0xFF6B7280); // kept approximate
  static const Color muted = Color(0xFFF3F2FF);
  static const Color accent = Color(0xFFBFA8FF);
  static const Color destructive = Color(0xFFD4183D);
  static const Color border = Color(0x1A000000); // #0000001a
  static const Color inputBackground = Color(0xFFF3F3F5);
}

class SaralRadius {
  static const double radius = 10.0; // --radius: .625rem => ~10px
  static const double radius2xl = 16.0;
  static const double radius3xl = 24.0;
}

class SaralTextStyles {
  static const TextStyle h1 = TextStyle(
    fontSize: 48,
    fontWeight: FontWeight.w700,
    color: SaralColors.primary,
  );

  static const TextStyle title = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: SaralColors.foreground,
  );

  static const TextStyle body = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: SaralColors.foreground,
  );

  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Color(0xFFFFFFFF),
  );
}

class SaralTheme {
  static ThemeData light() {
    final base = ThemeData.light();
    return base.copyWith(
      scaffoldBackgroundColor: SaralColors.background,
      primaryColor: SaralColors.primary,
      colorScheme: base.colorScheme.copyWith(
        primary: SaralColors.primary,
        secondary: SaralColors.secondary,
        surface: SaralColors.background,
        onPrimary: Colors.white,
      ),
      cardColor: SaralColors.card,
      dividerColor: SaralColors.border,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: SaralColors.inputBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(SaralRadius.radius),
          borderSide: BorderSide(color: SaralColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(SaralRadius.radius),
          borderSide: BorderSide(color: SaralColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(SaralRadius.radius),
          borderSide: BorderSide(color: SaralColors.primary, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: SaralColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          textStyle: SaralTextStyles.button,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(SaralRadius.radius2xl),
          ),
        ),
      ),
      textTheme: base.textTheme.copyWith(
        displayLarge: SaralTextStyles.h1,
        titleLarge: SaralTextStyles.title,
        bodyLarge: SaralTextStyles.body,
        bodyMedium: SaralTextStyles.body,
      ),
    );
  }
}
