import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../theme.dart';

/// Секунды с момента появления виджета. Питает бесконечные фоновые эффекты,
/// которым не нужен собственный [AnimationController].
class ElapsedClock extends StatefulWidget {
  const ElapsedClock({super.key, required this.builder});

  final Widget Function(BuildContext context, ValueListenable<double> seconds) builder;

  @override
  State<ElapsedClock> createState() => _ElapsedClockState();
}

class _ElapsedClockState extends State<ElapsedClock> with SingleTickerProviderStateMixin {
  final _seconds = ValueNotifier<double>(0);
  late final Ticker _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((d) => _seconds.value = d.inMicroseconds / 1e6)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _seconds.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _seconds);
}

/// Линейная интерполяция по ключевым кадрам `[(доля, значение), …]`,
/// как у CSS `@keyframes` с `ease-in-out` на каждом отрезке.
double keyframes(double t, List<(double, double)> frames, {Curve curve = Curves.easeInOut}) {
  if (t <= frames.first.$1) return frames.first.$2;
  for (var i = 1; i < frames.length; i++) {
    final (t1, v1) = frames[i];
    if (t <= t1) {
      final (t0, v0) = frames[i - 1];
      return v0 + (v1 - v0) * curve.transform((t - t0) / (t1 - t0));
    }
  }
  return frames.last.$2;
}

/// Фон расклада: мерцающее тёплое свечение и всплывающие пылинки.
class AmbientBackground extends StatelessWidget {
  const AmbientBackground({super.key, this.glowTop = 0.4, this.glowSize = 980, this.glowAlpha = 0.13});

  final double glowTop;
  final double glowSize;
  final double glowAlpha;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return CustomPaint(painter: _GlowPainter(1, 1, glowTop, glowSize, glowAlpha), size: Size.infinite);
    }
    return ElapsedClock(
      builder: (context, seconds) => CustomPaint(
        size: Size.infinite,
        painter: _AmbientPainter(seconds, glowTop, glowSize, glowAlpha),
      ),
    );
  }
}

class _GlowPainter extends CustomPainter {
  _GlowPainter(this.opacity, this.scale, this.top, this.diameter, this.alpha);

  final double opacity;
  final double scale;
  final double top;
  final double diameter;
  final double alpha;

  @override
  void paint(Canvas canvas, Size size) => paintGlow(canvas, size, opacity, scale, top, diameter, alpha);

  @override
  bool shouldRepaint(_GlowPainter old) => false;
}

void paintGlow(Canvas canvas, Size size, double opacity, double scale, double top, double diameter, double alpha) {
  final center = Offset(size.width / 2, size.height * top);
  final r = diameter / 2 * scale;
  const glow = Color(0xFFC98C46);
  final paint = Paint()
    ..shader = RadialGradient(colors: [
      glow.withValues(alpha: alpha * opacity),
      glow.withValues(alpha: 0),
    ]).createShader(Rect.fromCircle(center: center, radius: r));
  canvas.drawCircle(center, r, paint);
}

/// Пылинка: позиция по горизонтали в долях, размер, сдвиг старта и длительность цикла.
typedef _Mote = ({double x, double size, double delay, double period});

const _motes = <_Mote>[
  (x: .43, size: 2, delay: -6.3, period: 11.4), (x: .70, size: 2, delay: -5.9, period: 11.5),
  (x: .66, size: 2, delay: -0.6, period: 14.9), (x: .10, size: 2, delay: -1.5, period: 14.8),
  (x: .74, size: 2, delay: -15.2, period: 16.7), (x: .76, size: 2, delay: -9.2, period: 14.6),
  (x: .30, size: 2, delay: -8.9, period: 12.2), (x: .55, size: 2, delay: -8.7, period: 16.1),
  (x: .73, size: 2, delay: -1.6, period: 16.1), (x: .26, size: 3, delay: -1.6, period: 17.4),
  (x: .74, size: 2, delay: -9.9, period: 15.5), (x: .70, size: 3, delay: -12.4, period: 15.2),
  (x: .60, size: 3, delay: -4.8, period: 18.1), (x: .91, size: 2, delay: -1.3, period: 13.7),
  (x: .65, size: 3, delay: -11.7, period: 13.6), (x: .11, size: 2, delay: -8.2, period: 12.5),
  (x: .45, size: 2, delay: -14.9, period: 14.8), (x: .87, size: 2, delay: -12.2, period: 16.2),
  (x: .42, size: 3, delay: -11.1, period: 16.3), (x: .76, size: 3, delay: -1.1, period: 11.8),
  (x: .36, size: 3, delay: -11.2, period: 11.6), (x: .95, size: 3, delay: -10.4, period: 19.9),
];

class _AmbientPainter extends CustomPainter {
  _AmbientPainter(this.seconds, this.top, this.diameter, this.alpha) : super(repaint: seconds);

  final ValueListenable<double> seconds;
  final double top;
  final double diameter;
  final double alpha;

  @override
  void paint(Canvas canvas, Size size) {
    final s = seconds.value;

    // Свечение мерцает как свеча: цикл 5 s, яркость 70–100 %.
    final f = (s % 5) / 5;
    final opacity = keyframes(f, [(0, .75), (.2, 1), (.45, .7), (.6, .95), (.8, .8), (1, .75)]);
    final scale = keyframes(f, [(0, 1), (.45, 1.03), (1, 1)]);
    paintGlow(canvas, size, opacity, scale, top, diameter, alpha);

    // Пылинки всплывают снизу с лёгким дрейфом.
    for (final m in _motes) {
      final p = ((s - m.delay) % m.period) / m.period;
      final dy = keyframes(p, [(0, 0), (.5, -600), (1, -1240)], curve: Curves.linear);
      final dx = keyframes(p, [(0, 0), (.5, 18), (1, -12)], curve: Curves.linear);
      final a = keyframes(p, [(0, 0), (.1, .8), (.5, .55), (.9, .25), (1, 0)], curve: Curves.linear);
      final c = Offset(size.width * m.x + dx, size.height + 10 + dy);
      canvas.drawCircle(c, m.size * 2, Paint()
        ..color = CovenColors.spark.withValues(alpha: a * .35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
      canvas.drawCircle(c, m.size / 2, Paint()..color = CovenColors.spark.withValues(alpha: a));
    }
  }

  @override
  bool shouldRepaint(_AmbientPainter old) => false;
}

/// Лучи за логотипом и за картой-победителем: 24 штуки, чётные ярче.
class RaysPainter extends CustomPainter {
  RaysPainter({required this.inner, required this.outer, this.strong = .5, this.weak = .25, this.wide = 2, this.rings = false});

  final double inner;
  final double outer;
  final double strong;
  final double weak;
  final double wide;
  final bool rings;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    for (var i = 0; i < 24; i++) {
      final even = i.isEven;
      final paint = Paint()
        ..color = CovenColors.accent.withValues(alpha: even ? strong : weak)
        ..strokeWidth = even ? wide : 1
        ..strokeCap = StrokeCap.round;
      final a = i * math.pi / 12 - math.pi / 2;
      final dir = Offset(math.cos(a), math.sin(a));
      canvas.drawLine(c + dir * inner, c + dir * outer, paint);
    }
    if (rings) {
      final ring = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = CovenColors.accent.withValues(alpha: .25);
      canvas.drawCircle(c, size.width * 330 / 900, ring);
      _dashedCircle(canvas, c, size.width * 400 / 900, ring..color = CovenColors.accent.withValues(alpha: .12));
    }
  }

  void _dashedCircle(Canvas canvas, Offset c, double r, Paint paint) {
    final step = 12 / r;
    final dash = 2 / r;
    for (var a = 0.0; a < math.pi * 2; a += step) {
      canvas.drawArc(Rect.fromCircle(center: c, radius: r), a, dash, false, paint);
    }
  }

  @override
  bool shouldRepaint(RaysPainter old) => false;
}

/// Четырёхлучевая звёздочка из макета.
Path sparkPath(double s) {
  final k = s / 20;
  return Path()
    ..moveTo(10 * k, 0)
    ..cubicTo(10.8 * k, 6.5 * k, 13.5 * k, 9.2 * k, 20 * k, 10 * k)
    ..cubicTo(13.5 * k, 10.8 * k, 10.8 * k, 13.5 * k, 10 * k, 20 * k)
    ..cubicTo(9.2 * k, 13.5 * k, 6.5 * k, 10.8 * k, 0, 10 * k)
    ..cubicTo(6.5 * k, 9.2 * k, 9.2 * k, 6.5 * k, 10 * k, 0)
    ..close();
}

/// Мерцающая звёздочка: цикл 2.4 s, появляется и исчезает с масштабом .4 → 1.
class Sparkle extends StatelessWidget {
  const Sparkle({super.key, required this.size, required this.delay, required this.seconds});

  final double size;
  final double delay;
  final ValueListenable<double> seconds;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: seconds,
      builder: (context, s, _) {
        if (s < delay) return SizedBox.square(dimension: size);
        final p = ((s - delay) % 2.4) / 2.4;
        final v = keyframes(p, [(0, 0), (.5, 1), (1, 0)]);
        return Opacity(
          opacity: v,
          child: Transform.scale(
            scale: .4 + .6 * v,
            child: CustomPaint(size: Size.square(size), painter: _SparkPainter()),
          ),
        );
      },
    );
  }
}

class _SparkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) =>
      canvas.drawPath(sparkPath(size.width), Paint()..color = CovenColors.spark);

  @override
  bool shouldRepaint(_SparkPainter old) => false;
}
