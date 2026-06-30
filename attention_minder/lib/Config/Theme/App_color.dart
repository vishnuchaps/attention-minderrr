import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color primary = Color(0xFF000000); // Add your primary color here
  static const Color secondary = Color(0xFF757575); // Add more colors as needed
  static const Color background = Color(0xFFFFFFFF);
  static const Color opacityLayer = Color(0x00000000); // Use for opacity: 0px
}

class AppTextStyles {
  static final TextStyle bodyNormalRegular = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5, // Line height = fontSize * lineHeight (16 * 1.5 = 24)
  );

  static final TextStyle nunitoCenter = GoogleFonts.nunitoSans(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: Colors.black
  );

  static final TextStyle poppinsSmall = GoogleFonts.poppins(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );

  static final TextStyle poppinsExtraSmall = GoogleFonts.poppins(
    fontSize: 8,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      scaffoldBackgroundColor: AppColors.background,
      textTheme: TextTheme(
        bodyLarge: AppTextStyles.bodyNormalRegular,
        bodyMedium: AppTextStyles.nunitoCenter,
        titleMedium: AppTextStyles.poppinsSmall,
        titleSmall: AppTextStyles.poppinsExtraSmall,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          textStyle: AppTextStyles.bodyNormalRegular,
        ),
      ),
      // Add more theming options as needed
    );
  }
}
