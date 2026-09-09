import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';

/// Paleta: mesa de fieltro azul-verdoso profundo, con el rojo y el azul de las
/// cartas como únicos colores saturados. El ámbar queda reservado al maná, así
/// que cuando ves ámbar en pantalla siempre significa "recurso".
class SS {
  static const table = Color(0xFF0F1A23);
  static const tableUp = Color(0xFF1A3040);
  static const surface = Color(0xFF1B2E3B);
  static const surfaceUp = Color(0xFF24404F);
  static const line = Color(0xFF31566A);

  static const rojo = Color(0xFFE2404C);
  static const rojoUp = Color(0xFFF06A73);
  static const azul = Color(0xFF3F82E6);
  static const azulUp = Color(0xFF6AA3F2);

  static const mana = Color(0xFFEDB63F);
  static const win = Color(0xFF4FD18B);
  static const react = Color(0xFF8B77E0);

  static const ink = Color(0xFFE8F0F5);
  static const mute = Color(0xFF8FA9B8);

  static Color of(bool red) => red ? rojo : azul;
  static Color upOf(bool red) => red ? rojoUp : azulUp;

  static const title = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w800,
    letterSpacing: 3.2,
    color: ink,
  );
  static const sub = TextStyle(fontSize: 11.5, color: mute, height: 1.4);
  static const body = TextStyle(fontSize: 12.5, color: ink, height: 1.45);
  static const numStyle = TextStyle(
    fontWeight: FontWeight.w800,
    color: Colors.white,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static ThemeData theme() => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: table,
        colorScheme: const ColorScheme.dark(
          primary: mana,
          secondary: azul,
          surface: surface,
        ),
        fontFamily: null,
      );

  /// Fondo de mesa: un halo cálido arriba que hace que las cartas resalten.
  static BoxDecoration tableBg() => const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -1.05),
          radius: 1.25,
          colors: [tableUp, table],
          stops: [0.0, 0.7],
        ),
      );
}
