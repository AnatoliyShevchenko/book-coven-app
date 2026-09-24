import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/book.dart';
import '../theme.dart';
import 'coven_button.dart';
import 'effects.dart';

enum CardState { closed, out, last, winner }

const flipCurve = Cubic(.3, .8, .25, 1);
const flipDuration = Duration(milliseconds: 800);

/// Рубашки карт из макета.
const cardBacks = [
  'assets/images/back_moon.jpg',
  'assets/images/back_circle.jpg',
  'assets/images/back_herbs.jpg',
];

/// Карта расклада. Закрытая показывает рубашку. При выбывании переворачивается,
/// показывает обложку, сереет и получает плашку «Не читаем».
class TarotCard extends StatefulWidget {
  const TarotCard({
    super.key,
    required this.book,
    required this.back,
    required this.state,
    required this.index,
    required this.semanticLabel,
    this.onTap,
  });

  final Book book;
  final String back;
  final CardState state;

  /// Номер карты в раскладе: от него зависит задержка блика на рубашке.
  final int index;
  final String semanticLabel;
  final VoidCallback? onTap;

  @override
  State<TarotCard> createState() => _TarotCardState();
}

class _TarotCardState extends State<TarotCard> with TickerProviderStateMixin {
  late final _flip = AnimationController(vsync: this, duration: flipDuration);
  late final _winner = AnimationController(vsync: this, duration: flipDuration);
  // Серость и дымка после выбывания: 0.35–1.55 s от начала переворота.
  late final _afterOut = AnimationController(vsync: this, duration: const Duration(milliseconds: 1550));
  late final _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
  bool _pressed = false;

  bool get _faceUp => widget.state == CardState.out || widget.state == CardState.winner;

  @override
  void initState() {
    super.initState();
    _sync(null, animate: false);
  }

  @override
  void didUpdateWidget(TarotCard old) {
    super.didUpdateWidget(old);
    if (old.state != widget.state) _sync(old.state, animate: true);
  }

  void _sync(CardState? from, {required bool animate}) {
    final reduce = WidgetsBinding.instance.platformDispatcher.accessibilityFeatures.disableAnimations;
    final target = _faceUp ? 1.0 : 0.0;
    if (animate) {
      _flip.animateTo(target, curve: flipCurve);
    } else {
      _flip.value = target;
    }

    if (widget.state == CardState.out) {
      animate ? _afterOut.forward(from: 0) : _afterOut.value = 1;
    } else {
      _afterOut.value = 0;
    }

    final winner = widget.state == CardState.winner ? 1.0 : 0.0;
    animate ? _winner.animateTo(winner, curve: flipCurve) : _winner.value = winner;

    if (widget.state == CardState.last && !reduce) {
      _pulse.repeat();
    } else {
      _pulse
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _flip.dispose();
    _winner.dispose();
    _afterOut.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.semanticLabel,
      excludeSemantics: true,
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
        onTap: widget.onTap,
        child: LayoutBuilder(builder: (context, box) {
          return AnimatedBuilder(
            animation: Listenable.merge([_flip, _winner, _afterOut, _pulse]),
            builder: (context, _) => _buildCard(box.biggest),
          );
        }),
      ),
    );
  }

  Widget _buildCard(Size size) {
    final angle = _flip.value * math.pi;
    final showFront = angle > math.pi / 2;
    final pulse = keyframes(_pulse.value, [(0, 1), (.5, 1.06), (1, 1)]);
    final scale = (1 + .07 * _winner.value) * pulse * (_pressed ? .97 : 1);

    final transform = Matrix4.identity()
      ..setEntry(3, 2, .001)
      ..translateByDouble(0, _pressed ? -4 : 0, 0, 1)
      ..scaleByDouble(scale, scale, 1, 1)
      ..rotateY(angle);

    final face = showFront
        ? Transform(
            alignment: Alignment.center,
            transform: Matrix4.rotationY(math.pi),
            child: _Front(book: widget.book, size: size, out: widget.state == CardState.out, grey: _greyness),
          )
        : _Back(
            image: widget.back,
            index: widget.index,
            glow: widget.state == CardState.last,
          );

    final winnerGlow = widget.state == CardState.winner || _winner.value > 0;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: Transform(
            alignment: Alignment.center,
            transform: transform,
            child: DecoratedBox(
              position: DecorationPosition.foreground,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(CovenRadii.card),
                boxShadow: winnerGlow && showFront
                    ? [
                        BoxShadow(color: CovenColors.accent.withValues(alpha: _winner.value), spreadRadius: 2),
                      ]
                    : null,
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(CovenRadii.card),
                  boxShadow: [
                    if (winnerGlow && showFront)
                      BoxShadow(color: CovenColors.accent.withValues(alpha: .55 * _winner.value), blurRadius: 44)
                    else if (widget.state == CardState.last)
                      BoxShadow(color: CovenColors.accent.withValues(alpha: .4), blurRadius: 32)
                    else
                      const BoxShadow(color: Color(0x59000000), blurRadius: 18, offset: Offset(0, 6)),
                  ],
                ),
                child: face,
              ),
            ),
          ),
        ),
        if (widget.state == CardState.out) _puff(size),
      ],
    );
  }

  /// Серость лицевой стороны после выбывания: начинается через 0.5 s, длится 0.6 s.
  double get _greyness {
    final ms = _afterOut.value * 1550;
    return Curves.ease.transform(((ms - 500) / 600).clamp(0, 1));
  }

  /// Лавандовое облачко: стартует через 0.35 s, поднимается и тает за 1.2 s.
  Widget _puff(Size size) {
    final ms = _afterOut.value * 1550;
    final t = Curves.easeOut.transform(((ms - 350) / 1200).clamp(0, 1));
    if (t <= 0 || t >= 1) return const SizedBox.shrink();
    final opacity = keyframes(t, [(0, 0), (.3, 1), (1, 0)], curve: Curves.linear);
    final s = keyframes(t, [(0, .6), (.3, .6 + .8 * .3), (1, 1.4)], curve: Curves.linear);
    return Positioned(
      left: -size.width * .18,
      right: -size.width * .18,
      top: -size.height * .1,
      bottom: -size.height * .1,
      child: IgnorePointer(
        child: Transform.translate(
          offset: Offset(0, -30 * t),
          child: Transform.scale(
            scale: s,
            child: Opacity(
              opacity: opacity,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    CovenColors.lavender.withValues(alpha: .55),
                    CovenColors.lavender.withValues(alpha: 0),
                  ]),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Back extends StatelessWidget {
  const _Back({required this.image, required this.index, required this.glow});

  final String image;
  final int index;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: CovenColors.cardBack,
        borderRadius: BorderRadius.circular(CovenRadii.card),
        boxShadow: glow ? [const BoxShadow(color: CovenColors.accent, spreadRadius: 2)] : null,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(image, fit: BoxFit.cover, gaplessPlayback: true),
          if (!reduce) _Shimmer(delay: (index * 1.37) % 9),
        ],
      ),
    );
  }
}

/// Диагональный блик по рубашке: цикл 9 s, проходит в последние 18 % цикла.
class _Shimmer extends StatelessWidget {
  const _Shimmer({required this.delay});

  final double delay;

  @override
  Widget build(BuildContext context) {
    return ElapsedClock(builder: (context, seconds) {
      return ValueListenableBuilder<double>(
        valueListenable: seconds,
        builder: (context, s, _) {
          final p = ((s + 9 - delay) % 9) / 9;
          if (p < .82) return const SizedBox.shrink();
          final x = -1.2 + 2.4 * Curves.easeInOut.transform((p - .82) / .18);
          return FractionalTranslation(
            translation: Offset(x, 0),
            child: const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment(-.9, -.4),
                  end: Alignment(.9, .4),
                  colors: [Color(0x00FFECBE), Color(0x38FFECBE), Color(0x00FFECBE)],
                  stops: [.35, .5, .65],
                ),
              ),
            ),
          );
        },
      );
    });
  }
}

class _Front extends StatelessWidget {
  const _Front({required this.book, required this.size, required this.out, required this.grey});

  final Book book;
  final Size size;
  final bool out;

  /// 0 — цветная обложка, 1 — серость 85 %, яркость 78 %.
  final double grey;

  @override
  Widget build(BuildContext context) {
    final w = size.width;
    final ink = book.cover.ink;
    final titleSize = (w * .115).clamp(12.0, 20.0);
    final authorSize = (w * .085).clamp(9.0, 12.0);
    final inset = w * .06;

    Widget card = Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: book.cover.bg, borderRadius: BorderRadius.circular(CovenRadii.card)),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            left: inset,
            top: inset,
            right: inset,
            bottom: inset,
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: ink.withValues(alpha: .45)),
                borderRadius: BorderRadius.circular(7),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(w * .08, w * .09, w * .08, w * .22),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    book.title,
                    textAlign: TextAlign.center,
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis,
                    style: CovenText.cardTitle(titleSize, ink),
                  ),
                ),
                SizedBox(height: w * .05),
                DividerOrnament(width: w * .24, color: ink),
                SizedBox(height: w * .05),
                Text(
                  book.author.toUpperCase(),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: CovenText.cardAuthor(authorSize, ink),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (grey > 0) card = ColorFiltered(colorFilter: ColorFilter.matrix(_greyMatrix(grey)), child: card);
    if (!out) return card;

    return Stack(
      fit: StackFit.expand,
      children: [
        card,
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(CovenRadii.card)),
            child: Container(
              padding: const EdgeInsets.only(top: 5, bottom: 6),
              decoration: BoxDecoration(
                color: CovenColors.bg,
                border: Border(top: BorderSide(color: CovenColors.lavender.withValues(alpha: .6))),
              ),
              child: Text(
                'НЕ ЧИТАЕМ',
                textAlign: TextAlign.center,
                style: CovenText.overline(color: CovenColors.lavender, size: authorSize, spacing: .14),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// CSS `grayscale(.85 * t) brightness(1 - .22 * t)` одной матрицей.
List<double> _greyMatrix(double t) {
  final g = .85 * t;
  final b = 1 - .22 * t;
  // Матрица grayscale из спецификации Filter Effects.
  final m = [
    .2126 + .7874 * (1 - g), .7152 - .7152 * (1 - g), .0722 - .0722 * (1 - g),
    .2126 - .2126 * (1 - g), .7152 + .2848 * (1 - g), .0722 - .0722 * (1 - g),
    .2126 - .2126 * (1 - g), .7152 - .7152 * (1 - g), .0722 + .9278 * (1 - g),
  ];
  return [
    m[0] * b, m[1] * b, m[2] * b, 0, 0,
    m[3] * b, m[4] * b, m[5] * b, 0, 0,
    m[6] * b, m[7] * b, m[8] * b, 0, 0,
    0, 0, 0, 1, 0,
  ];
}
