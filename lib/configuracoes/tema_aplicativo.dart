import 'package:flutter/material.dart';

abstract final class CoresGaleria {
  static const vinho = Color(0xFF6D1B2A);
  static const vinhoEscuro = Color(0xFF3F0F18);
  static const dourado = Color(0xFFC29A4A);
  static const creme = Color(0xFFF8F2E8);
  static const cremeEscuro = Color(0xFFE9DDCB);
  static const tinta = Color(0xFF2C2522);
}

abstract final class TemaAplicativo {
  static ThemeData get claro {
    final esquema = ColorScheme.fromSeed(
      seedColor: CoresGaleria.vinho,
      brightness: Brightness.light,
      primary: CoresGaleria.vinho,
      secondary: CoresGaleria.dourado,
      surface: CoresGaleria.creme,
    );

    return ThemeData(
      useMaterial3: true,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
      ),
      colorScheme: esquema,
      scaffoldBackgroundColor: CoresGaleria.creme,
      appBarTheme: const AppBarTheme(
        backgroundColor: CoresGaleria.vinho,
        foregroundColor: Colors.white,
        centerTitle: false,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shadowColor: CoresGaleria.vinho.withValues(alpha: 0.12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        errorMaxLines: 4,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: CoresGaleria.cremeEscuro),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: CoresGaleria.vinho, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(48, 48),
          backgroundColor: CoresGaleria.vinho,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: CoresGaleria.cremeEscuro,
        labelTextStyle: WidgetStateProperty.resolveWith((estados) {
          final selecionado = estados.contains(WidgetState.selected);
          return TextStyle(
            color: selecionado ? CoresGaleria.vinho : CoresGaleria.tinta,
            fontWeight: selecionado ? FontWeight.w700 : FontWeight.w500,
          );
        }),
      ),
      textTheme: const TextTheme(
        headlineSmall: TextStyle(
          color: CoresGaleria.vinhoEscuro,
          fontWeight: FontWeight.w700,
        ),
        titleLarge: TextStyle(
          color: CoresGaleria.vinhoEscuro,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: TextStyle(
          color: CoresGaleria.tinta,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(color: CoresGaleria.tinta, height: 1.45),
        bodyMedium: TextStyle(color: CoresGaleria.tinta, height: 1.4),
      ),
    );
  }
}
