import 'package:flutter/material.dart';
import 'package:peladeiros_sa/core/constants/app_colors.dart';

class AppThemes {
  static WidgetStateProperty<T> widgetStatePropFrom<T>(
    T Function(Set<WidgetState> states) resolver,
  ) {
    return WidgetStateProperty.resolveWith(resolver);
  }

  static WidgetStatePropertyAll<T> widgetStatePropAll<T>(T value) {
    return WidgetStatePropertyAll<T>(value);
  }

  static ThemeData buildTheme({
    required Color primaryColor,
    required Brightness brightness,
  }) {
    final isDark = brightness == Brightness.dark;

    final scrim = isDark ? Colors.black54 : Colors.black12;
    final canvas = isDark ? AppColors.canvasDark : AppColors.canvasLight;
    final surface = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final onSurface = isDark ? AppColors.textDark : AppColors.textLight;
    final onSurfaceMuted = isDark
        ? AppColors.mutedTextDark
        : AppColors.mutedTextLight;
    final divider = isDark ? AppColors.outlineDark : AppColors.outlineLight;
    final card = surface;
    final onPrimary = primaryColor.computeLuminance() > 0.52
        ? AppColors.textLight
        : AppColors.white;
    final appBarFg = onPrimary;
    final hint = onSurfaceMuted;

    final secondary = AppColors.secondary;

    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: brightness,
      primary: primaryColor,
      onPrimary: onPrimary,
      secondary: secondary,
      onSecondary: AppColors.white,
      surface: surface,
      onSurface: onSurface,
      onSurfaceVariant: onSurfaceMuted,
      error: AppColors.danger,
      onError: AppColors.white,
    );

    final textTheme = Typography.englishLike2021
        .apply(bodyColor: onSurface, displayColor: onSurface)
        .copyWith(
          displayLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: onSurface,
          ),
          displayMedium: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: onSurface,
          ),
          headlineLarge: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: onSurface,
          ),
          headlineMedium: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: onSurface,
          ),
          titleLarge: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: onSurface,
          ),
          titleMedium: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: onSurface,
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: onSurface,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: onSurface,
          ),
          bodySmall: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: onSurfaceMuted,
          ),
          labelLarge: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: appBarFg,
          ),
        );

    return ThemeData(
      useMaterial3: true,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      colorScheme: colorScheme,
      brightness: brightness,
      scaffoldBackgroundColor: canvas,
      canvasColor: canvas,
      cardColor: card,
      dividerColor: divider,
      dividerTheme: DividerThemeData(color: divider, thickness: 1),
      hintColor: hint,
      iconTheme: IconThemeData(color: onSurfaceMuted),
      primaryColor: primaryColor,
      secondaryHeaderColor: primaryColor.withAlphaSafe(alpha: 0.08),
      disabledColor: AppColors.graphite4,
      splashColor: primaryColor.withAlphaSafe(alpha: 0.20),
      highlightColor: primaryColor.withAlphaSafe(alpha: 0.10),
      hoverColor: primaryColor.withAlphaSafe(alpha: 0.05),
      focusColor: primaryColor.withAlphaSafe(alpha: 0.12),

      textTheme: textTheme,
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: primaryColor,
        selectionColor: primaryColor.withAlphaSafe(alpha: 0.24),
        selectionHandleColor: primaryColor,
      ),
      primaryTextTheme: Typography.englishLike2021.apply(
        bodyColor: appBarFg,
        displayColor: appBarFg,
      ),

      appBarTheme: AppBarTheme(
        toolbarHeight: kToolbarHeight * 0.9,
        backgroundColor: primaryColor,
        foregroundColor: appBarFg,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: appBarFg,
        ),
        iconTheme: IconThemeData(color: appBarFg),
        actionsIconTheme: IconThemeData(color: appBarFg),
      ),

      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(44, 44),
          foregroundColor: onSurfaceMuted,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        ),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: primaryColor,
        selectedItemColor: onPrimary,
        unselectedItemColor: onPrimary.withAlphaSafe(alpha: 0.72),
        selectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        backgroundColor: primaryColor,
        indicatorColor: onPrimary.withAlphaSafe(alpha: isDark ? 0.24 : 0.16),
        elevation: 0,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? primaryColor : onSurfaceMuted,
          );
        }),
      ),

      drawerTheme: DrawerThemeData(
        backgroundColor: surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(right: Radius.circular(20)),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: onPrimary,
          disabledBackgroundColor: AppColors.graphite4,
          disabledForegroundColor: AppColors.graphite1,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          minimumSize: const Size(48, 48),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          elevation: 0,
          shadowColor: Colors.transparent,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: BorderSide(color: primaryColor, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          minimumSize: const Size(48, 48),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
          ),
        ),
      ),

      checkboxTheme: CheckboxThemeData(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.fieldDark : AppColors.fieldLight,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        hintStyle: TextStyle(color: hint),
        labelStyle: TextStyle(color: onSurfaceMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: divider, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: divider, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: primaryColor, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: const BorderSide(color: AppColors.danger, width: 2),
        ),
      ),

      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shadowColor: scrim,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: divider.withAlphaSafe(alpha: 0.8)),
        ),
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: isDark ? AppColors.graphite2 : AppColors.graphite7,
        selectedColor: primaryColor,
        disabledColor: AppColors.graphite4,
        labelStyle: TextStyle(
          color: isDark ? AppColors.graphite7 : AppColors.graphite1,
          fontWeight: FontWeight.w500,
        ),
        secondaryLabelStyle: TextStyle(
          color: AppColors.white,
          fontWeight: FontWeight.w600,
        ),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),

      listTileTheme: ListTileThemeData(
        tileColor: Colors.transparent,
        selectedTileColor: primaryColor.withAlphaSafe(alpha: 0.08),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        minLeadingWidth: 24,
        horizontalTitleGap: 12,
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: onPrimary,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      badgeTheme: BadgeThemeData(
        backgroundColor: secondary,
        textColor: AppColors.white,
        textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.graphite0,
        contentTextStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.white,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
        elevation: 4,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        elevation: 12,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: onSurface,
        ),
      ),

      popupMenuTheme: PopupMenuThemeData(
        color: surface,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: divider.withAlphaSafe(alpha: 0.8)),
        ),
        textStyle: TextStyle(color: onSurface, fontSize: 14),
      ),

      expansionTileTheme: ExpansionTileThemeData(
        backgroundColor: Colors.transparent,
        collapsedBackgroundColor: Colors.transparent,
        iconColor: primaryColor,
        collapsedIconColor: onSurfaceMuted,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide.none,
        ),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide.none,
        ),
      ),

      tabBarTheme: TabBarThemeData(
        labelColor: primaryColor,
        unselectedLabelColor: onSurfaceMuted,
        labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        indicatorSize: TabBarIndicatorSize.label,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(width: 2.5, color: primaryColor),
          borderRadius: BorderRadius.circular(2),
        ),
        dividerColor: Colors.transparent,
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primaryColor,
        linearTrackColor: divider,
        circularTrackColor: divider,
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.white;
          }
          return AppColors.graphite4;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor.withAlphaSafe(alpha: 0.75);
          }
          return divider;
        }),
        trackOutlineColor: WidgetStatePropertyAll(Colors.transparent),
      ),
    );
  }
}
