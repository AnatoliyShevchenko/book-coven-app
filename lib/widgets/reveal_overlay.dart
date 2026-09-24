import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../data/book.dart';
import '../theme.dart';
import 'coven_button.dart';
import 'effects.dart';
import 'tarot_card.dart';

/// Звёздочки финала: доли экрана по x и y, размер, задержка.
const _sparks = <(double, double, double, double)>[
  (.108, .126, 18, 0), (.839, .101, 14, .6), (.180, .385, 12, 1.2), (.851, .352, 20, .3),
  (.072, .687, 16, 1.8), (.887, .637, 12, .9), (.300, .871, 14, 1.5), (.695, .888, 18, .2),
  (.504, .067, 10, 2.0), (.767, .787, 10, 1.1),
];

/// Финал расклада: карта-победитель вылетает, переворачивается,
/// за ней вращаются лучи и мерцают звёздочки.
class RevealOverlay extends StatelessWidget {
  const RevealOverlay({
    super.key,
    required this.book,
    required this.back,
    required this.onClose,
    required this.onReshuffle,
  });

  final Book book;
  final String back;
  final VoidCallback onClose;
  final VoidCallback onReshuffle;

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      label: 'Книга, которую читает ковен',
      child: ElapsedClock(builder: (context, seconds) {
        return ValueListenableBuilder<double>(
          valueListenable: seconds,
          builder: (context, s, _) => _build(context, reduce ? 10 : s, seconds),
        );
      }),
    );
  }

  Widget _build(BuildContext context, double s, ValueListenable<double> seconds) {
    double phase(double delay, double duration, [Curve curve = Curves.ease]) =>
        curve.transform(((s - delay) / duration).clamp(0, 1));

    final fade = phase(0, .6);
    final fly = phase(.2, .8, flipCurve);
    final flip = phase(1.2, 1.0, Curves.easeInOut);
    final rays = phase(1.3, 1.2);
    final title = phase(.3, .7);
    final actions = phase(2.3, .7);
    final showFront = s >= 1.7;

    final size = MediaQuery.sizeOf(context);
    final cardW = math.min(400.0, size.shortestSide * .48);
    final cardH = cardW * 477 / 400;
    final raysSize = cardW * 900 / 400;

    Widget rise(double t, Widget child) => Opacity(
          opacity: t,
          child: Transform.translate(offset: Offset(0, 14 * (1 - t)), child: child),
        );

    return Opacity(
      opacity: fade,
      child: ColoredBox(
        color: const Color(0xF00E0A12),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Лучи сдвинуты на 20 px вверх относительно центра, как в макете.
            Positioned.fill(
              child: Center(
                child: Transform.translate(
                  offset: const Offset(0, -20),
                  child: Opacity(
                    opacity: rays,
                    child: Transform.rotate(
                      angle: s > 1.3 ? (s - 1.3) / 60 * math.pi * 2 : 0,
                      child: CustomPaint(
                        size: Size.square(raysSize),
                        painter: RaysPainter(
                          inner: raysSize * (450 - 250) / 900,
                          outer: raysSize * (450 - 60) / 900,
                          rings: true,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            for (final (x, y, sz, d) in _sparks)
              Positioned(
                left: size.width * x,
                top: size.height * y,
                child: Sparkle(size: sz, delay: d + 1.6, seconds: seconds),
              ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                rise(
                  title,
                  Column(children: [
                    Text('СУДЬБА РЕШИЛА', style: CovenText.overline(size: 14, spacing: .28)),
                    const SizedBox(height: 6),
                    Text('Ковен читает', style: CovenText.titleL()),
                  ]),
                ),
                const SizedBox(height: 40),
                Opacity(
                  opacity: fly,
                  child: Transform.translate(
                    offset: Offset(0, 160 * (1 - fly)),
                    child: Transform.scale(
                      scale: .28 + .72 * fly,
                      child: Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 1 / 1600)
                          ..rotateY(flip * math.pi),
                        child: SizedBox(
                          width: cardW,
                          height: cardH,
                          child: showFront
                              ? Transform(
                                  alignment: Alignment.center,
                                  transform: Matrix4.rotationY(math.pi),
                                  child: _BigFront(book: book, width: cardW),
                                )
                              : _BigBack(image: back),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                IgnorePointer(
                  ignoring: actions < 1,
                  child: rise(
                    actions,
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CovenButton(label: 'К раскладу', onPressed: onClose),
                        const SizedBox(width: 14),
                        CovenButton.primary(label: 'Новый расклад', onPressed: onReshuffle),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BigBack extends StatelessWidget {
  const _BigBack({required this.image});

  final String image;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(CovenRadii.big),
        boxShadow: const [
          BoxShadow(color: CovenColors.accent, spreadRadius: 2),
          BoxShadow(color: Color(0x99000000), blurRadius: 80, offset: Offset(0, 30)),
        ],
      ),
      child: Image.asset(image, fit: BoxFit.cover),
    );
  }
}

class _BigFront extends StatelessWidget {
  const _BigFront({required this.book, required this.width});

  final Book book;
  final double width;

  @override
  Widget build(BuildContext context) {
    final k = width / 400;
    final ink = book.cover.ink;
    return Container(
      decoration: BoxDecoration(
        color: book.cover.bg,
        borderRadius: BorderRadius.circular(CovenRadii.big),
        boxShadow: [
          const BoxShadow(color: CovenColors.accent, spreadRadius: 2),
          BoxShadow(color: CovenColors.accent.withValues(alpha: .55), blurRadius: 90),
          const BoxShadow(color: Color(0x99000000), blurRadius: 80, offset: Offset(0, 30)),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          for (final (inset, alpha, radius) in [(16.0, .5, 14.0), (24.0, .25, 10.0)])
            Positioned.fill(
              left: inset * k,
              top: inset * k,
              right: inset * k,
              bottom: inset * k,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: ink.withValues(alpha: alpha)),
                  borderRadius: BorderRadius.circular(radius * k),
                ),
              ),
            ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 36 * k, vertical: 48 * k),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    book.title,
                    textAlign: TextAlign.center,
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis,
                    style: CovenText.cardTitle(44 * k, ink).copyWith(height: 1.02),
                  ),
                ),
                SizedBox(height: 26 * k),
                DividerOrnament(width: 90 * k, color: ink, stroke: 1.4),
                SizedBox(height: 26 * k),
                Text(
                  book.author.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: CovenText.cardAuthor(16 * k, ink).copyWith(letterSpacing: 1.6 * k, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
