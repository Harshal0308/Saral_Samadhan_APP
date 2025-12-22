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
  
  // New colorful palette for dashboard icons
  static const Color attendanceColor = Color(0xFF4CAF50); // Green
  static const Color attendanceBg = Color(0xFFE8F5E9);
  
  static const Color studentsColor = Color(0xFF2196F3); // Blue
  static const Color studentsBg = Color(0xFFE3F2FD);
  
  static const Color volunteersColor = Color(0xFF9C27B0); // Purple
  static const Color volunteersBg = Color(0xFFF3E5F5);
  
  static const Color analyticsColor = Color(0xFFFF9800); // Orange
  static const Color analyticsBg = Color(0xFFFFF3E0);
  
  // Quick action colors
  static const Color scheduleColor = Color(0xFF00BCD4); // Cyan
  static const Color scheduleBg = Color(0xFFE0F2F1);
  
  static const Color eventsColor = Color(0xFFE91E63); // Pink
  static const Color eventsBg = Color(0xFFFCE4EC);
  
  static const Color galleryColor = Color(0xFF795548); // Brown
  static const Color galleryBg = Color(0xFFEFEBE9);
  
  static const Color exportColor = Color(0xFF607D8B); // Blue Grey
  static const Color exportBg = Color(0xFFECEFF1);
  
  // Additional vibrant colors for variety
  static const Color successColor = Color(0xFF4CAF50);
  static const Color warningColor = Color(0xFFFF9800);
  static const Color errorColor = Color(0xFFF44336);
  static const Color infoColor = Color(0xFF2196F3);
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
