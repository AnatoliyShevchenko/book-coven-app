import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/coven_button.dart';
import '../widgets/effects.dart';

/// Нет ни сети, ни сохранённого списка: показывать нечего.
/// Свеча погасла, над ней вьётся дымок; кнопка пробует загрузить книги снова.
class OfflineScreen extends StatelessWidget {
  const OfflineScreen({super.key, required this.checking, required this.onRetry});

  /// Идёт повторная попытка: кнопка неактивна и показывает «Ищем сеть…».
  final bool checking;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final landscape = size.width > size.height;
    final compact = isCompact(context);

    final art = SizedBox(
      width: landscape ? (compact ? 220 : 300) : 260,
      height: landscape ? (compact ? 264 : 360) : 312,
      child: const _CandleArt(),
    );

    final text = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: landscape ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          const _OfflinePill(),
          SizedBox(height: compact ? 24 : 32),
          Semantics(
            header: true,
            child: Text(
              'Связь с ковеном прервалась',
              textAlign: landscape ? TextAlign.start : TextAlign.center,
              style: CovenText.title(size: compact ? 40 : 48).copyWith(height: 1.05),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Похоже, пропал интернет. Проверьте Wi-Fi или мобильные данные — '
            'карты вернутся, как только появится сеть.',
            textAlign: landscape ? TextAlign.start : TextAlign.center,
            style: CovenText.body().copyWith(fontSize: 18, height: 1.5),
          ),
          SizedBox(height: compact ? 24 : 32),
          CovenButton.primary(
            label: checking ? 'Ищем сеть…' : 'Попробовать снова',
            icon: checking ? const _PhasesSpinner() : const RetryIcon(),
            onPressed: checking ? null : onRetry,
          ),
        ],
      ),
    );

    return Stack(
      children: [
        // Холодное лавандовое свечение вместо тёплого: свеча не горит.
        Positioned.fill(
          child: CustomPaint(painter: _ColdGlowPainter()),
        ),
        SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(compact ? 40 : 80),
              child: landscape
                  ? Row(mainAxisSize: MainAxisSize.min, children: [art, const SizedBox(width: 72), Flexible(child: text)])
                  : Column(mainAxisSize: MainAxisSize.min, children: [art, const SizedBox(height: 32), text]),
            ),
          ),
        ),
      ],
    );
  }
}

class _ColdGlowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height * .4);
    const r = 380.0;
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(colors: [
          CovenColors.lavenderDeep.withValues(alpha: .12),
          CovenColors.lavenderDeep.withValues(alpha: 0),
        ]).createShader(Rect.fromCircle(center: c, radius: r)),
    );
  }

  @override
  bool shouldRepaint(_ColdGlowPainter old) => false;
}

/// Лавандовая плашка «Нет интернета» с перечёркнутым значком Wi-Fi.
class _OfflinePill extends StatelessWidget {
  const _OfflinePill();

  @override
  Widget build(BuildContext context) {
    const fg = Color(0xFFCDB8E6);
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: CovenColors.lavender.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: CovenColors.lavender.withValues(alpha: .35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const WifiOffIcon(size: 16, color: fg),
          const SizedBox(width: 8),
          Text('НЕТ ИНТЕРНЕТА', style: CovenText.overline(color: fg, size: 13, spacing: .08)),
        ],
      ),
    );
  }
}

/// Три фазы луны, мигающие по очереди, — индикатор на неактивной кнопке.
class _PhasesSpinner extends StatelessWidget {
  const _PhasesSpinner();

  @override
  Widget build(BuildContext context) {
    final color = IconTheme.of(context).color ?? CovenColors.onAccent;
    return ElapsedClock(builder: (context, seconds) {
      return ValueListenableBuilder<double>(
        valueListenable: seconds,
        builder: (context, s, _) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 3; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              Opacity(
                opacity: .35 + .65 * keyframes(((s - i * .15) % 1.2) / 1.2, [(0, 0), (.5, 1), (1, 0)]),
                child: CustomPaint(size: const Size.square(12), painter: _PhasePainter(i, color)),
              ),
            ],
          ],
        ),
      );
    });
  }
}

class _PhasePainter extends CustomPainter {
  _PhasePainter(this.phase, this.color);

  /// 0 — растущая, 1 — полнолуние, 2 — убывающая.
  final int phase;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 14;
    final c = size.center(Offset.zero);
    final fill = Paint()..color = color;
    if (phase == 1) {
      canvas.drawCircle(c, 6.6 * k, fill);
      return;
    }
    final rect = Rect.fromCircle(center: c, radius: 6 * k);
    canvas.drawArc(rect, phase == 0 ? math.pi / 2 : -math.pi / 2, math.pi, true, fill);
    canvas.drawCircle(
      c,
      6 * k,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4 * k
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_PhasePainter old) => old.color != color;
}

/// Погасшая свеча в подсвечнике: дымок вьётся и чуть покачивается,
/// уголёк на фитиле тлеет, звёздочки мерцают, над всем — месяц.
class _CandleArt extends StatelessWidget {
  const _CandleArt();

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return CustomPaint(painter: _CandlePainter(null));
    }
    return ElapsedClock(builder: (context, seconds) => CustomPaint(painter: _CandlePainter(seconds)));
  }
}

class _CandlePainter extends CustomPainter {
  _CandlePainter(this.seconds) : super(repaint: seconds);

  final ValueListenable<double>? seconds;

  @override
  void paint(Canvas canvas, Size size) {
    final s = seconds?.value ?? 0;
    final still = seconds == null;
    canvas.scale(size.width / 200, size.height / 240);

    Paint stroke(Color c, double w) => Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    Paint fill(Color c) => Paint()..color = c;

    // Месяц: круг, из которого вырезан смещённый вправо-вверх круг.
    // В макете он задан двумя дугами, которые при этих размерах вырождаются в ноль.
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addOval(Rect.fromCircle(center: const Offset(158, 36), radius: 14)),
        Path()..addOval(Rect.fromCircle(center: const Offset(165, 31), radius: 11)),
      ),
      fill(CovenColors.accent),
    );

    // Звёздочки-крестики мерцают со сдвигом в секунду.
    for (final (x, y, r, w, d) in [(40.0, 39.0, 3.0, 1.4, 0.0), (24.0, 94.0, 2.0, 1.2, 1.0), (174.0, 98.5, 2.5, 1.2, 2.0)]) {
      final a = still ? .6 : keyframes(((s - d) % 3) / 3, [(0, .25), (.5, .9), (1, .25)]);
      final p = stroke(CovenColors.accent.withValues(alpha: a), w);
      canvas.drawLine(Offset(x, y - r), Offset(x, y + r), p);
      canvas.drawLine(Offset(x - r, y), Offset(x + r, y), p);
    }

    // Дымок: пунктир бежит вверх, вся струйка покачивается на 4 px.
    final sway = still ? 0.0 : 4 * keyframes((s % 6) / 6, [(0, 0), (.5, 1), (1, 0)]);
    canvas.save();
    canvas.translate(sway, 0);
    _dashed(
      canvas,
      Path()
        ..moveTo(100, 92)
        ..cubicTo(92, 82, 110, 74, 101, 62)
        ..cubicTo(92, 50, 110, 42, 100, 30)
        ..cubicTo(94, 22, 100, 14, 98, 8),
      stroke(CovenColors.lavender, 2.2),
      offset: (s % 3.2) / 3.2 * 44,
    );
    _dashed(
      canvas,
      Path()
        ..moveTo(102, 90)
        ..cubicTo(112, 80, 94, 70, 104, 58)
        ..cubicTo(112, 48, 98, 40, 106, 28),
      stroke(CovenColors.lavenderDeep.withValues(alpha: .55), 1.6),
      offset: ((s + 1.2) % 4.4) / 4.4 * 44,
    );
    canvas.restore();

    // Фитиль и тлеющий уголёк.
    canvas.drawPath(Path()..moveTo(100, 111)..cubicTo(100, 104, 97, 101, 99, 95), stroke(const Color(0xFF2A2230), 2.4));
    final ember = still ? .5 : keyframes((s % 2.6) / 2.6, [(0, .15), (.5, .9), (1, .15)]);
    canvas.drawCircle(const Offset(99, 95), 2, fill(CovenColors.candle.withValues(alpha: ember)));

    // Свеча с потёками воска.
    canvas.drawPath(
      Path()
        ..moveTo(76, 116)
        ..cubicTo(76, 111, 124, 111, 124, 116)
        ..lineTo(124, 202)
        ..lineTo(76, 202)
        ..close(),
      fill(const Color(0xFFE9DCC2)),
    );
    canvas.drawOval(Rect.fromCenter(center: const Offset(100, 116), width: 48, height: 10), fill(const Color(0xFFF4EAD5)));
    canvas.drawPath(
      Path()
        ..moveTo(82, 118)
        ..cubicTo(82, 128, 86, 130, 86, 138)
        ..cubicTo(86, 142, 90, 142, 90, 138)
        ..lineTo(90, 120)
        ..close(),
      fill(const Color(0xFFF4EAD5)),
    );
    canvas.drawPath(
      Path()
        ..moveTo(112, 118)
        ..cubicTo(112, 124, 115, 126, 115, 132)
        ..cubicTo(115, 135, 118, 135, 118, 132)
        ..lineTo(118, 119)
        ..close(),
      fill(const Color(0xFFF4EAD5)),
    );
    canvas.drawRect(const Rect.fromLTRB(76, 150, 86, 202), fill(const Color(0xFFD6C7AA).withValues(alpha: .6)));

    // Подсвечник с ручкой.
    final dish = Path()
      ..moveTo(50, 206)
      ..cubicTo(50, 200, 150, 200, 150, 206)
      ..cubicTo(150, 214, 128, 220, 100, 220)
      ..cubicTo(72, 220, 50, 214, 50, 206)
      ..close();
    canvas.drawPath(dish, fill(const Color(0xFF241C2C)));
    canvas.drawPath(dish, stroke(CovenColors.accent, 1.5));
    final rim = Rect.fromCenter(center: const Offset(100, 205), width: 68, height: 10);
    canvas.drawOval(rim, fill(CovenColors.surface));
    canvas.drawOval(rim, stroke(CovenColors.accent.withValues(alpha: .8), 1));
    canvas.drawPath(
      Path()
        ..moveTo(150, 208)
        ..cubicTo(162, 208, 166, 214, 160, 219)
        ..cubicTo(156, 222, 150, 220, 148, 216),
      stroke(CovenColors.accent, 1.5),
    );
  }

  /// Пунктир 10/12 со сдвигом, как `stroke-dasharray` с бегущим `stroke-dashoffset`.
  void _dashed(Canvas canvas, Path path, Paint paint, {required double offset}) {
    const dash = 10.0;
    const period = 22.0;
    for (final metric in path.computeMetrics()) {
      for (var d = -period + offset % period; d < metric.length; d += period) {
        final start = math.max(0.0, d);
        final end = math.min(metric.length, d + dash);
        if (end > start) canvas.drawPath(metric.extractPath(start, end), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_CandlePainter old) => false;
}
