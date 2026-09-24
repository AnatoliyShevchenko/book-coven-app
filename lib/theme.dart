import 'package:flutter/material.dart';

/// Цветовые токены из UI Kit.
abstract final class CovenColors {
  static const bg = Color(0xFF0F0D12);
  static const surface = Color(0xFF1A1620);
  static const surface2 = Color(0xFF221B2A);
  static const accent = Color(0xFFC9A45C);
  static const accentHover = Color(0xFFD9B775);
  static const text = Color(0xFFF1E8D6);
  static const textMuted = Color(0xFFB3A8BF);
  static const lavender = Color(0xFFB79AD6);
  static const lavenderDeep = Color(0xFF9C7FC0);
  static const candle = Color(0xFFE3A94B);
  static const track = Color(0xFF3A2F44);
  static const onAccent = Color(0xFF1B1622);
  static const spark = Color(0xFFE2C487);
  static const cardBack = Color(0xFF1A2033);
}

/// Скругления из UI Kit.
abstract final class CovenRadii {
  static const thumb = 6.0;
  static const card = 12.0;
  static const panel = 20.0;
  static const big = 22.0;
}

/// Низкий экран, например планшет 960×600 dp в горизонтальной ориентации:
/// шапка, панель и отступы становятся компактнее, чтобы картам осталось место.
bool isCompact(BuildContext context) => MediaQuery.sizeOf(context).height < 720;

/// Пропорция карты: ширина к высоте.
const cardAspect = 0.838;

const _serif = 'Cormorant Garamond';
const _sans = 'Manrope';

/// Шрифты переменные, поэтому вес задаём и через [FontWeight], и через ось `wght`.
TextStyle _style(
  String family,
  double size,
  FontWeight weight, {
  double? height,
  double? letterSpacing,
  Color color = CovenColors.text,
}) {
  return TextStyle(
    fontFamily: family,
    fontSize: size,
    fontWeight: weight,
    fontVariations: [FontVariation('wght', weight.value.toDouble())],
    height: height,
    letterSpacing: letterSpacing,
    color: color,
  );
}

/// Типографика из UI Kit. Имена совпадают с подписями в макете.
abstract final class CovenText {
  static TextStyle display({Color color = CovenColors.text}) =>
      _style(_serif, 44, FontWeight.w600, height: 1, letterSpacing: 0.44, color: color);
  static TextStyle titleL({Color color = CovenColors.text}) =>
      _style(_serif, 40, FontWeight.w600, height: 1, color: color);
  static TextStyle title({double size = 28, Color color = CovenColors.text}) =>
      _style(_serif, size, FontWeight.w600, height: 1.1, color: color);
  static TextStyle cardTitle(double size, Color color) =>
      _style(_serif, size, FontWeight.w700, height: 1.05, color: color);
  static TextStyle counter({Color color = CovenColors.accent}) =>
      _style(_serif, 36, FontWeight.w700, height: 1, color: color);

  static TextStyle button({Color color = CovenColors.text}) =>
      _style(_sans, 16, FontWeight.w600, height: 1, color: color);
  static TextStyle subtitle({Color color = CovenColors.textMuted}) =>
      _style(_sans, 16, FontWeight.w400, height: 1.375, color: color);
  static TextStyle body({Color color = CovenColors.textMuted}) =>
      _style(_sans, 15, FontWeight.w400, height: 1.4, color: color);
  static TextStyle caption({Color color = CovenColors.textMuted}) =>
      _style(_sans, 14, FontWeight.w400, height: 1.43, color: color);
  static TextStyle overline({Color color = CovenColors.accent, double size = 12, double spacing = 0.12}) =>
      _style(_sans, size, FontWeight.w700, letterSpacing: size * spacing, color: color);
  static TextStyle cardAuthor(double size, Color color) =>
      _style(_sans, size, FontWeight.w600, height: 1.2, letterSpacing: size * 0.04, color: color);
}

ThemeData buildCovenTheme() {
  return ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: CovenColors.bg,
    fontFamily: _sans,
    colorScheme: const ColorScheme.dark(
      surface: CovenColors.bg,
      primary: CovenColors.accent,
      onPrimary: CovenColors.onAccent,
      secondary: CovenColors.lavender,
      onSurface: CovenColors.text,
    ),
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
  );
}
