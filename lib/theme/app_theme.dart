import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  // -- Typography -------------------------
  // Display/Headings: Syne (premium geometric -- closest available
  //   substitute for PolySans on Google Fonts)
  // Body/UI: Plus Jakarta Sans

  static TextTheme get _textTheme => TextTheme(
    displayLarge: GoogleFonts.syne(
      fontSize: 36, fontWeight: FontWeight.w700,
      color: AppColors.textPrimary, letterSpacing: -1.0,
    ),
    displayMedium: GoogleFonts.syne(
      fontSize: 28, fontWeight: FontWeight.w700,
      color: AppColors.textPrimary, letterSpacing: -0.5,
    ),
    displaySmall: GoogleFonts.syne(
      fontSize: 22, fontWeight: FontWeight.w600,
      color: AppColors.textPrimary, letterSpacing: -0.3,
    ),
    headlineMedium: GoogleFonts.syne(
      fontSize: 20, fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    ),
    headlineSmall: GoogleFonts.syne(
      fontSize: 18, fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    ),
    titleLarge: GoogleFonts.plusJakartaSans(
      fontSize: 17, fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    ),
    titleMedium: GoogleFonts.plusJakartaSans(
      fontSize: 15, fontWeight: FontWeight.w600,
      color: AppColors.textPrimary, letterSpacing: 0.1,
    ),
    titleSmall: GoogleFonts.plusJakartaSans(
      fontSize: 13, fontWeight: FontWeight.w500,
      color: AppColors.textSecondary,
    ),
    bodyLarge: GoogleFonts.plusJakartaSans(
      fontSize: 16, fontWeight: FontWeight.w400,
      color: AppColors.textPrimary, height: 1.6,
    ),
    bodyMedium: GoogleFonts.plusJakartaSans(
      fontSize: 14, fontWeight: FontWeight.w400,
      color: AppColors.textSecondary, height: 1.5,
    ),
    bodySmall: GoogleFonts.plusJakartaSans(
      fontSize: 12, fontWeight: FontWeight.w400,
      color: AppColors.textMuted, height: 1.4,
    ),
    labelLarge: GoogleFonts.plusJakartaSans(
      fontSize: 15, fontWeight: FontWeight.w600,
      color: AppColors.textPrimary, letterSpacing: 0.2,
    ),
    labelMedium: GoogleFonts.plusJakartaSans(
      fontSize: 12, fontWeight: FontWeight.w500,
      color: AppColors.textSecondary, letterSpacing: 0.4,
    ),
    labelSmall: GoogleFonts.plusJakartaSans(
      fontSize: 11, fontWeight: FontWeight.w500,
      color: AppColors.textMuted, letterSpacing: 0.6,
    ),
  );

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.background,
    textTheme: _textTheme,

    colorScheme: const ColorScheme.dark(
      surface:      AppColors.surface,
      surfaceContainerHighest: AppColors.elevated,
      primary:      AppColors.accent,
      primaryContainer: AppColors.accentDim,
      onPrimary:    AppColors.textPrimary,
      onSurface:    AppColors.textPrimary,
      secondary:    AppColors.textSecondary,
      onSecondary:  AppColors.textPrimary,
      error:        AppColors.error,
      onError:      AppColors.textPrimary,
      outline:      AppColors.border,
    ),

    // -- AppBar -------------------------
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.syne(
        fontSize: 18, fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      iconTheme: const IconThemeData(
        color: AppColors.textPrimary, size: 24,
      ),
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: AppColors.background,
      ),
    ),

    // -- Cards (inspired by shadcn/ui dark card style) --
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border, width: 1),
      ),
    ),

    // -- Buttons ------------------------
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.textPrimary,
        disabledBackgroundColor: AppColors.elevated,
        disabledForegroundColor: AppColors.textMuted,
        elevation: 0,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: GoogleFonts.plusJakartaSans(
          fontSize: 15, fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        side: const BorderSide(color: AppColors.border, width: 1.5),
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: GoogleFonts.plusJakartaSans(
          fontSize: 15, fontWeight: FontWeight.w600,
        ),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.accent,
        textStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14, fontWeight: FontWeight.w600,
        ),
      ),
    ),

    // -- Inputs (shadcn/ui dark input style) --
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.elevated,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.border, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.border, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
      hintStyle: GoogleFonts.plusJakartaSans(
        color: AppColors.textMuted, fontSize: 14,
      ),
      labelStyle: GoogleFonts.plusJakartaSans(
        color: AppColors.textSecondary, fontSize: 14,
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 20, vertical: 16,
      ),
    ),

    // -- Checkbox -----------------------
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return AppColors.accent;
        return AppColors.elevated;
      }),
      checkColor: WidgetStateProperty.all(AppColors.textPrimary),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      side: const BorderSide(color: AppColors.border, width: 1.5),
    ),

    // -- Switch -------------------------
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return AppColors.accent;
        return AppColors.textMuted;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return AppColors.accentDim;
        return AppColors.elevated;
      }),
    ),

    // -- Bottom Navigation --------------
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.accent,
      unselectedItemColor: AppColors.textMuted,
      elevation: 0,
      type: BottomNavigationBarType.fixed,
      showSelectedLabels: true,
      showUnselectedLabels: true,
    ),

    // -- Navigation Bar (Material 3) ----
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.surface,
      indicatorColor: AppColors.accentDim,
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: AppColors.accent, size: 24);
        }
        return const IconThemeData(color: AppColors.textMuted, size: 24);
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return GoogleFonts.plusJakartaSans(
            fontSize: 11, fontWeight: FontWeight.w600,
            color: AppColors.accent,
          );
        }
        return GoogleFonts.plusJakartaSans(
          fontSize: 11, fontWeight: FontWeight.w500,
          color: AppColors.textMuted,
        );
      }),
    ),

    // -- Divider ------------------------
    dividerTheme: const DividerThemeData(
      color: AppColors.divider,
      thickness: 1,
      space: 1,
    ),

    // -- Snackbar -----------------------
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.elevated,
      contentTextStyle: GoogleFonts.plusJakartaSans(
        color: AppColors.textPrimary, fontSize: 14,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      behavior: SnackBarBehavior.floating,
    ),

    // -- Bottom Sheet -------------------
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.surface,
      modalBackgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      elevation: 0,
    ),

    // -- Dialog -------------------------
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.border, width: 1),
      ),
      titleTextStyle: GoogleFonts.syne(
        fontSize: 18, fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      contentTextStyle: GoogleFonts.plusJakartaSans(
        fontSize: 14, color: AppColors.textSecondary, height: 1.5,
      ),
    ),

    // -- Chip ---------------------------
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.elevated,
      selectedColor: AppColors.accentDim,
      labelStyle: GoogleFonts.plusJakartaSans(
        fontSize: 12, fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      ),
      side: const BorderSide(color: AppColors.border, width: 1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),

    // -- ListTile -----------------------
    listTileTheme: const ListTileThemeData(
      tileColor: Colors.transparent,
      selectedTileColor: AppColors.accentDim,
      iconColor: AppColors.textSecondary,
      textColor: AppColors.textPrimary,
      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    ),

    // -- Tab Bar ------------------------
    tabBarTheme: TabBarThemeData(
      labelColor: AppColors.textPrimary,
      unselectedLabelColor: AppColors.textMuted,
      indicatorColor: AppColors.accent,
      indicatorSize: TabBarIndicatorSize.label,
      labelStyle: GoogleFonts.plusJakartaSans(
        fontSize: 14, fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: GoogleFonts.plusJakartaSans(
        fontSize: 14, fontWeight: FontWeight.w400,
      ),
    ),

    // -- Icon ---------------------------
    iconTheme: const IconThemeData(
      color: AppColors.textPrimary, size: 24,
    ),

    // -- Page Transitions ---------------
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );
}
