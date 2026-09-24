import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/effects.dart';

/// Размеры планшетного сплэша из макета. Логотип того же размера стоит
/// на нативном сплэше, поэтому переход с него незаметен.
const splashLogoSize = 260.0;
const _ringSize = 330.0;
const _gap = 56.0;

/// Когда появление завершено и можно уходить на расклад.
const splashMinDuration = Duration(milliseconds: 2800);

/// Анимированный сплэш: дорисовывается кольцо, проявляются свечение и лучи,
/// затем название, подзаголовок и фазы луны как индикатор загрузки.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    return Scaffold(
      body: ElapsedClock(builder: (context, seconds) {
        return ValueListenableBuilder<double>(
          valueListenable: seconds,
          builder: (context, s, _) => _build(context, reduce ? 10 : s, seconds, reduce),
        );
      }),
    );
  }

  Widget _build(BuildContext context, double s, ValueListenable<double> seconds, bool reduce) {
    double phase(double delay, double duration, [Curve curve = Curves.ease]) =>
        curve.transform(((s - delay) / duration).clamp(0, 1));

    final ring = phase(.25, 1.3, const Cubic(.4, 0, .2, 1));
    final dots = phase(1.3, .8);
    final rays = phase(1.1, 1.4) * .9;
    final glowIn = phase(.1, 1.2);
    final title = phase(1.4, .8);
    final tag = phase(1.75, .8);
    final phases = phase(2.2, .6);

    // Свечение мерцает с 1.3 s, ореол логотипа пульсирует с 1.2 s.
    final flicker = s < 1.3 ? 1.0 : keyframes(((s - 1.3) % 5) / 5, [(0, .8), (.25, 1), (.5, .72), (.75, .95), (1, .8)]);
    final halo = s < 1.2 ? 0.0 : keyframes(((s - 1.2) % 2.4) / 2.4, [(0, 0), (.5, 1), (1, 0)]);

    Widget rise(double t, Widget child) => Opacity(
          opacity: t,
          child: Transform.translate(offset: Offset(0, 12 * (1 - t)), child: child),
        );

    return Stack(
      fit: StackFit.expand,
      children: [
        CustomPaint(painter: _SplashGlowPainter(glowIn * flicker)),
        if (!reduce) const IgnorePointer(child: AmbientBackground(glowAlpha: 0)),
        Center(
          child: Opacity(
            opacity: rays,
            child: Transform.rotate(
              angle: s > 1.1 ? (s - 1.1) / 60 * math.pi * 2 : 0,
              child: CustomPaint(
                size: const Size.square(760),
                painter: RaysPainter(inner: 180, outer: 340, strong: .38, weak: .18, wide: 1.6),
              ),
            ),
          ),
        ),
        // Логотип ровно по центру экрана, как на нативном сплэше, текст под ним.
        Center(
          child: SizedBox.square(
            dimension: _ringSize,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(size: const Size.square(_ringSize), painter: _RingPainter(ring, dots)),
                Container(
                  width: splashLogoSize,
                  height: splashLogoSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: const DecorationImage(image: AssetImage('assets/images/logo.jpg'), fit: BoxFit.cover),
                    boxShadow: [
                      BoxShadow(color: CovenColors.accent.withValues(alpha: .4 + .2 * halo), spreadRadius: 1),
                      BoxShadow(color: CovenColors.accent.withValues(alpha: .35 * halo), blurRadius: 48),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        LayoutBuilder(builder: (context, box) {
          // Под логотипом на низком экране мало места: зазор уменьшается,
          // а текст с фазами луны пропорционально сжимается.
          final below = box.maxHeight / 2 - splashLogoSize / 2;
          final gap = (below * .2).clamp(20.0, _gap);
          return Padding(
            padding: EdgeInsets.only(top: box.maxHeight - below + gap, bottom: 16),
            child: Align(
              alignment: Alignment.topCenter,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.topCenter,
                child: Column(
                  children: [
                    rise(
                      title,
                      Text('Книжный ковен', style: CovenText.display().copyWith(fontSize: 60, letterSpacing: 0)),
                    ),
                    const SizedBox(height: 12),
                    rise(
                      tag,
                      Text(
                        'ЧИТАТЬ · МЕЧТАТЬ · КОЛДОВАТЬ',
                        style: CovenText.overline(size: 16, spacing: .22).copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                    SizedBox(height: gap),
                    Opacity(
                      opacity: phases,
                      child: Semantics(label: 'Загрузка', liveRegion: true, child: _MoonPhases(seconds: s)),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _SplashGlowPainter extends CustomPainter {
  _SplashGlowPainter(this.opacity);

  final double opacity;

  @override
  void paint(Canvas canvas, Size size) => paintGlow(canvas, size, opacity, 1, .44, 900, .18);

  @override
  bool shouldRepaint(_SplashGlowPainter old) => old.opacity != opacity;
}

/// Кольцо вокруг логотипа рисуется от верхней точки по часовой стрелке,
/// потом проявляется внутреннее пунктирное кольцо.
class _RingPainter extends CustomPainter {
  _RingPainter(this.progress, this.dots);

  final double progress;
  final double dots;

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 216;
    final c = size.center(Offset.zero);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..color = CovenColors.accent
      ..strokeWidth = 1.5 * k;
    canvas.drawArc(Rect.fromCircle(center: c, radius: 102 * k), -math.pi / 2, progress * math.pi * 2, false, paint);

    if (dots > 0) {
      final r = 96 * k;
      final dot = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1 * k
        ..color = CovenColors.accent.withValues(alpha: .5 * dots);
      final step = 11 * k / r;
      for (var a = 0.0; a < math.pi * 2; a += step) {
        canvas.drawArc(Rect.fromCircle(center: c, radius: r), a, 2 * k / r, false, dot);
      }
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress || old.dots != dots;
}

/// Пять фаз луны, пульсирующие волной как индикатор загрузки.
class _MoonPhases extends StatelessWidget {
  const _MoonPhases({required this.seconds});

  final double seconds;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 5; i++) ...[
          if (i > 0) const SizedBox(width: 14),
          Builder(builder: (context) {
            final p = ((seconds - i * .2) % 1.6) / 1.6;
            final v = keyframes(p, [(0, 0), (.5, 1), (1, 0)]);
            return Opacity(
              opacity: .35 + .65 * v,
              child: Transform.scale(
                scale: .9 + .1 * v,
                child: CustomPaint(size: const Size.square(14), painter: _MoonPainter(i)),
              ),
            );
          }),
        ],
      ],
    );
  }
}

class _MoonPainter extends CustomPainter {
  _MoonPainter(this.phase);

  /// 0 — новолуние, 1 — растущая, 2 — полнолуние, 3 — убывающая, 4 — новолуние.
  final int phase;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final fill = Paint()..color = CovenColors.accent;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = CovenColors.accent;
    final rect = Rect.fromCircle(center: c, radius: 6);
    switch (phase) {
      case 2:
        canvas.drawCircle(c, 6.6, fill);
      case 1:
        canvas.drawArc(rect, math.pi / 2, math.pi, true, fill);
        canvas.drawCircle(c, 6, stroke);
      case 3:
        canvas.drawArc(rect, -math.pi / 2, math.pi, true, fill);
        canvas.drawCircle(c, 6, stroke);
      default:
        canvas.drawCircle(c, 6, stroke);
    }
  }

  @override
  bool shouldRepaint(_MoonPainter old) => old.phase != phase;
}
