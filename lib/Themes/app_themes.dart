import 'package:flutter/material.dart';

class AppThemes {
  AppThemes._();

  static const Color primary = Color.fromARGB(255, 0, 80, 217);
  static const Color secondary = Color.fromARGB(255, 245, 200, 0);

  static const Color accentPrimary = Color.fromARGB(255, 99, 152, 244);

  static const Color greyLight = Color(0xFFE0E0E0);
  static const Color greyDark = Color(0xFF4F4F4F);
  static const Color grey = Color(0xFF747474);
  static const Color blueGrey = Color(0xFFA0A5BD);

  /// Operator Theme
  static const Color bgDark = Color(0xFF17181A);
  static const Color cardBg = Color(0xFF23262B);
  static const Color inputBg = Color(0xFF191A1C);
  static const Color primaryCyan = Color(0xFF00E5C3);
  static const Color statusFinished = Color(0xFF4CAF50);
  static const Color statusPending = Color(0xFFFFB800);
  static const Color statusManual = Color(0xFF42A5F5);
  static const Color textGrey = Colors.grey;
  static const Color textWhite = Colors.white;

  static const List<Color> randomColor = [
    Color(0xFF00E0D1),
    Color(0xFF00EB9C),
    Color(0xFFFFDC6A),
    Color(0xFFFF88A2),
    Color(0xFFFB94FF),
  ];

  /// kartu produk pada halaman Data Management
  static const List<Color> productPalette = [
    Color(0xFF512DA8), 
    Color(0xFF00897B), 
    Color(0xFF1E88E5), 
    Color(0xFFFF7043), 
    Color(0xFF7B1FA2), 
    Color(0xFF43A047), 
    Color(0xFFD81B60), 
    Color(0xFF006064), 
  ];

  /// Gradient pairs untuk kartu produk 
  static const List<List<Color>> productGradients = [
    [Color(0xFF7C55FF), Color(0xFFE64980)],
    [Color(0xFF00B7FF), Color(0xFF0061FF)],
    [Color(0xFFFF8C42), Color(0xFFFC466B)],
    [Color(0xFF20C997), Color(0xFF0FB9B1)],
  ];

  // static String fontBaloo = "BalooBhai2";

  //************************* Light Theme ************************/

  static const Color lightBackground = Colors.white;
  static const Color lightTextDark = greyDark;
  static const Color lightTextGrey = grey;

  static final ThemeData lightTheme = ThemeData(
    splashFactory:
        InkRipple
            .splashFactory, // Dibuat agar splash pada material button tidak terlalu kencang
    brightness: Brightness.light,
    // fontFamily: fontBaloo,
    scaffoldBackgroundColor: lightBackground,
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primary,
      foregroundColor: Colors.white,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      elevation: 10.0,
      backgroundColor: lightBackground,
      unselectedItemColor: greyLight,
      selectedItemColor: primary,
      type: BottomNavigationBarType.fixed,
      unselectedLabelStyle: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w400,
      ),
      selectedLabelStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w400),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: lightBackground,
      elevation: 1,
      iconTheme: IconThemeData(color: lightTextDark),
      titleTextStyle: _lightTextTheme.displayMedium,
      toolbarTextStyle: _lightTextTheme.displayMedium,
      actionsIconTheme: IconThemeData(color: lightTextDark),
      centerTitle: true,
    ),
    colorScheme: const ColorScheme.light(primary: primary),
    textTheme: _lightTextTheme,
    textSelectionTheme: const TextSelectionThemeData(
      selectionColor: lightTextGrey,
      selectionHandleColor: lightTextGrey,
      cursorColor: lightTextGrey,
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(15)),
        ),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(style: ButtonStyle()),
    unselectedWidgetColor: AppThemes.secondary, // Colors.pink
  );

  static const TextTheme _lightTextTheme = TextTheme(
    displayLarge: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w800,
      letterSpacing: 1,
      color: lightTextDark,
    ),
    displayMedium: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w800,
      color: lightTextDark,
    ),
    displaySmall: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w800,
      color: lightTextDark,
    ),
    titleLarge: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: lightTextDark,
    ),
    titleMedium: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: lightTextDark,
    ),
    titleSmall: TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w500,
      color: lightTextDark,
    ),
    bodyLarge: TextStyle(
      fontSize: 12.5,
      fontWeight: FontWeight.w400,
      color: lightTextDark,
    ),
    bodyMedium: TextStyle(
      fontSize: 11.5,
      fontWeight: FontWeight.w400,
      color: lightTextDark,
    ),
    bodySmall: TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w300,
      color: lightTextDark,
    ),
    labelSmall: TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w500,
      color: lightTextGrey,
    ),
  );
}
