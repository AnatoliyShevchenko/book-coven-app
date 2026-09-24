import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/book.dart';
import '../data/book_repository.dart';
import '../theme.dart';
import '../widgets/coven_button.dart';
import '../widgets/effects.dart';
import '../widgets/reveal_overlay.dart';
import '../widgets/tarot_card.dart';

const _gap = 14.0;
const _dealStep = 30;
const _dealDuration = 600;
const _gatherDuration = Duration(milliseconds: 750);
const _winnerDelay = Duration(milliseconds: 1100);

/// Расклад: книги лежат рубашкой вверх, их открывают по одной.
/// Открытая карта выбывает, последняя оставшаяся — книга, которую читает ковен.
class SpreadScreen extends StatefulWidget {
  const SpreadScreen({super.key, required this.repository, required this.books, this.loadError});

  final BookRepository repository;
  final List<Book> books;
  final Object? loadError;

  @override
  State<SpreadScreen> createState() => _SpreadScreenState();
}

class _SpreadScreenState extends State<SpreadScreen> with TickerProviderStateMixin {
  final _random = math.Random();

  late List<Book> _books = widget.books;
  late Object? _error = widget.loadError;
  late List<int> _order = _shuffled();

  /// Позиции открытых карт в порядке открытия.
  final List<int> _out = [];
  int? _winner;
  bool _revealClosed = false;
  bool _loading = false;
  bool _fetching = false;
  int _round = 0;

  /// Свежий список из таблицы, пришедший во время перетасовки. Применяется при раздаче.
  List<Book>? _pending;

  late final _deal = AnimationController(vsync: this, duration: _dealTotal);
  late final _gather = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
  Timer? _winnerTimer;
  Timer? _dealTimer;

  Duration get _dealTotal => Duration(milliseconds: _dealDuration + _dealStep * math.max(0, _books.length - 1));

  int get _left => _books.length - _out.length;
  bool get _shuffling => _gather.isAnimating || _dealTimer != null;

  @override
  void initState() {
    super.initState();
    _deal.forward();
  }

  @override
  void dispose() {
    _winnerTimer?.cancel();
    _dealTimer?.cancel();
    _deal.dispose();
    _gather.dispose();
    super.dispose();
  }

  List<int> _shuffled() => List.generate(_books.length, (i) => i)..shuffle(_random);

  void _eliminate(int pos) {
    if (_shuffling || _winner != null || _out.contains(pos) || _left <= 1) return;
    setState(() => _out.add(pos));
    if (_left == 1) {
      final last = List.generate(_books.length, (i) => i).firstWhere((i) => !_out.contains(i));
      _winnerTimer = Timer(_winnerDelay, () {
        if (mounted) {
          setState(() {
            _winner = last;
            _revealClosed = false;
          });
        }
      });
    }
  }

  /// Собирает колоду, заодно подтягивает свежий список из таблицы и раздаёт заново.
  void _reshuffle() {
    _winnerTimer?.cancel();
    _dealTimer?.cancel();
    _pending = null;
    _fetching = true;
    widget.repository.load().then((books) {
      _fetching = false;
      _pending = books;
      // Пустой расклад ждал только загрузки: раздаём сразу, не дожидаясь следующей перетасовки.
      if (_books.isEmpty && _dealTimer == null && mounted) _dealNow();
    }, onError: (Object e) {
      _fetching = false;
      if (_books.isEmpty && mounted) {
        setState(() {
          _error = e;
          _loading = false;
        });
      }
    });

    setState(() {
      _winner = null;
      _revealClosed = false;
      _loading = _books.isEmpty;
      _gather.forward(from: 0);
      _dealTimer = Timer(_gatherDuration, _dealNow);
    });
  }

  void _dealNow() {
    _dealTimer?.cancel();
    _dealTimer = null;
    if (!mounted) return;
    if (_books.isEmpty && _pending == null && _fetching) return;
    setState(() {
      if (_pending != null) {
        _books = _pending!;
        _error = null;
        _pending = null;
      }
      _loading = false;
      _out.clear();
      _winner = null;
      _order = _shuffled();
      _round++;
      _gather.value = 0;
      _deal.duration = _dealTotal;
      _deal.forward(from: 0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    final compact = isCompact(context);
    final gap = compact ? 16.0 : 28.0;
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: IgnorePointer(child: AmbientBackground())),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.all(compact ? 24 : 40),
              child: Column(
                children: [
                  _Header(left: _left, total: _books.length, compact: compact),
                  SizedBox(height: gap),
                  Expanded(child: _books.isEmpty ? _emptyState() : _grid(reduce)),
                  SizedBox(height: gap),
                  _footer(compact),
                ],
              ),
            ),
          ),
          if (_winner != null && !_revealClosed)
            Positioned.fill(
              child: RevealOverlay(
                key: ValueKey(_round),
                book: _books[_order[_winner!]],
                back: _backFor(_winner!, _cols),
                onClose: () => setState(() => _revealClosed = true),
                onReshuffle: _reshuffle,
              ),
            ),
        ],
      ),
    );
  }

  int _cols = 6;

  /// Рубашки чередуются по диагонали при любом числе колонок.
  String _backFor(int pos, int cols) => cardBacks[(pos % cols + pos ~/ cols) % cardBacks.length];

  Widget _grid(bool reduce) {
    return LayoutBuilder(builder: (context, box) {
      final layout = _GridLayout.fit(_books.length, box.biggest);
      _cols = layout.cols;
      final lastStanding = _left == 1;
      final dealTilt = _round.isOdd ? 1.0 : -1.0;

      return Center(
        child: SizedBox(
          width: layout.width,
          height: layout.height,
          child: AnimatedBuilder(
            animation: Listenable.merge([_deal, _gather]),
            builder: (context, _) => Stack(
              children: [
                for (var pos = 0; pos < _order.length; pos++)
                  Positioned(
                    left: (pos % layout.cols) * (layout.cardW + layout.colGap),
                    top: (pos ~/ layout.cols) * (layout.cardH + _gap),
                    width: layout.cardW,
                    height: layout.cardH,
                    child: _animated(pos, dealTilt, reduce, _card(pos, layout.cols, lastStanding)),
                  ),
              ],
            ),
          ),
        ),
      );
    });
  }

  /// Раздача: карты по очереди падают сверху с поворотом. Сбор: колода сжимается и гаснет.
  Widget _animated(int pos, double tilt, bool reduce, Widget child) {
    if (reduce) return child;
    if (_gather.value > 0) {
      final g = Curves.easeInOut.transform(_gather.value);
      final scale = keyframes(g, [(0, 1), (.5, .8), (1, .8)], curve: Curves.linear);
      final opacity = keyframes(g, [(0, 1), (.5, .2), (1, 0)], curve: Curves.linear);
      final rot = keyframes(g, [(0, 0), (.5, 4), (1, 0)], curve: Curves.linear);
      return Opacity(
        opacity: opacity,
        child: Transform.rotate(angle: rot * math.pi / 180, child: Transform.scale(scale: scale, child: child)),
      );
    }
    final ms = _deal.value * _deal.duration!.inMilliseconds;
    final t = const Cubic(.2, .8, .2, 1).transform(((ms - pos * _dealStep) / _dealDuration).clamp(0, 1));
    if (t >= 1) return child;
    return Opacity(
      opacity: t,
      child: Transform.translate(
        offset: Offset(0, -40 * (1 - t)),
        child: Transform.rotate(
          angle: tilt * 6 * (1 - t) * math.pi / 180,
          child: Transform.scale(scale: .85 + .15 * t, child: child),
        ),
      ),
    );
  }

  Widget _card(int pos, int cols, bool lastStanding) {
    final book = _books[_order[pos]];
    final isOut = _out.contains(pos);
    final isWinner = _winner == pos;
    final state = isWinner
        ? CardState.winner
        : isOut
            ? CardState.out
            : lastStanding
                ? CardState.last
                : CardState.closed;
    final n = pos + 1;
    final label = isOut
        ? 'Карта $n: ${book.title} — не читаем'
        : isWinner
            ? 'Карта $n: ${book.title}, ${book.author} — читаем'
            : 'Карта $n, закрыта';
    final enabled = !isOut && !isWinner && !lastStanding && !_shuffling;

    return TarotCard(
      key: ValueKey('$_round-$pos'),
      book: book,
      back: _backFor(pos, cols),
      state: state,
      index: pos,
      semanticLabel: label,
      onTap: enabled ? () => _eliminate(pos) : null,
    );
  }

  Widget _emptyState() {
    final failed = _error != null;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _loading ? 'Тасуем колоду…' : (failed ? 'Не удалось загрузить книги' : 'В таблице нет непрочитанных книг'),
            textAlign: TextAlign.center,
            style: CovenText.title(),
          ),
          const SizedBox(height: 12),
          if (!_loading)
            Text(
              failed
                  ? 'Проверьте интернет и попробуйте ещё раз.'
                  : 'Добавьте книги в таблицу или очистите колонку Read.',
              textAlign: TextAlign.center,
              style: CovenText.body(),
            ),
          const SizedBox(height: 24),
          if (!_loading) CovenButton(label: 'Повторить', icon: const ShuffleIcon(), onPressed: _reshuffle),
        ],
      ),
    );
  }

  Widget _footer(bool compact) {
    final Widget content;
    if (_books.isEmpty) {
      content = Text('Книги берутся из общей таблицы ковена', style: CovenText.body());
    } else if (_winner != null) {
      final book = _books[_order[_winner!]];
      content = _FooterRow(
        body: Row(children: [
          Container(
            width: compact ? 40 : 52,
            height: compact ? 56 : 74,
            decoration: BoxDecoration(
              color: book.cover.bg,
              borderRadius: BorderRadius.circular(CovenRadii.thumb),
              boxShadow: [BoxShadow(color: CovenColors.accent.withValues(alpha: .7), spreadRadius: 1)],
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('КОВЕН ЧИТАЕТ', style: CovenText.overline()),
                const SizedBox(height: 3),
                Text(
                  book.title,
                  maxLines: compact ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: CovenText.title(size: compact ? 24 : 30).copyWith(height: 1.05),
                ),
                const SizedBox(height: 3),
                Text(book.author, style: CovenText.body()),
              ],
            ),
          ),
        ]),
        action: CovenButton(label: 'Новый расклад', onPressed: _reshuffle),
      );
    } else if (_out.isNotEmpty) {
      final book = _books[_order[_out.last]];
      content = _FooterRow(
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('ВЫБЫВАЕТ', style: CovenText.overline(color: CovenColors.lavender)),
            const SizedBox(height: 3),
            Text.rich(
              TextSpan(children: [
                TextSpan(text: book.title),
                TextSpan(
                  text: ' · ${book.author}',
                  style: CovenText.body().copyWith(fontWeight: FontWeight.w500),
                ),
              ]),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: CovenText.title(size: compact ? 22 : 26).copyWith(height: 1.05),
            ),
            const SizedBox(height: 10),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: _Progress(value: _out.length / math.max(1, _books.length - 1)),
            ),
          ],
        ),
        action: CovenButton(label: 'Начать заново', onPressed: _reshuffle),
      );
    } else {
      content = _FooterRow(
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Открывайте карты по очереди', style: CovenText.title(size: compact ? 24 : 28)),
            const SizedBox(height: 4),
            Text(
              compact
                  ? 'Открытая карта выбывает. Последняя оставшаяся — наша.'
                  : 'Каждая открытая карта — книга, которую мы не читаем.\nПоследняя оставшаяся — наша.',
              style: CovenText.body(),
            ),
          ],
        ),
        action: CovenButton(label: 'Перетасовать', icon: const ShuffleIcon(), onPressed: _shuffling ? null : _reshuffle),
      );
    }

    return Container(
      constraints: BoxConstraints(minHeight: compact ? 88 : 116),
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: compact ? 14 : 20),
      decoration: BoxDecoration(
        color: CovenColors.surface,
        borderRadius: BorderRadius.circular(CovenRadii.panel),
        border: Border.all(color: CovenColors.accent.withValues(alpha: .3)),
      ),
      alignment: Alignment.centerLeft,
      child: content,
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.left, required this.total, required this.compact});

  final int left;
  final int total;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final logo = compact ? 60.0 : 84.0;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          width: logo,
          height: logo,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: CovenColors.accent.withValues(alpha: .5), spreadRadius: 1),
              const BoxShadow(color: Color(0x80000000), blurRadius: 24, offset: Offset(0, 6)),
            ],
            image: const DecorationImage(image: AssetImage('assets/images/logo.jpg'), fit: BoxFit.cover),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Semantics(header: true, child: Text('Книжный ковен', style: CovenText.display().copyWith(fontSize: compact ? 34 : 44))),
              const SizedBox(height: 2),
              Text('Выбор следующей книги', style: CovenText.subtitle()),
            ],
          ),
        ),
        if (total > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Semantics(
              label: 'Осталось $left из $total',
              excludeSemantics: true,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text('Осталось', style: CovenText.caption()),
                  const SizedBox(width: 8),
                  Text('$left', style: CovenText.counter().copyWith(fontSize: compact ? 30 : 36)),
                  const SizedBox(width: 8),
                  Text('из $total', style: CovenText.caption()),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _FooterRow extends StatelessWidget {
  const _FooterRow({required this.body, required this.action});

  final Widget body;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(child: body),
      const SizedBox(width: 20),
      action,
    ]);
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: 6,
        color: CovenColors.track,
        alignment: Alignment.centerLeft,
        child: AnimatedFractionallySizedBox(
          duration: const Duration(milliseconds: 500),
          curve: Curves.ease,
          widthFactor: value.clamp(0, 1),
          heightFactor: 1,
          child: const DecoratedBox(
            decoration: BoxDecoration(
              color: CovenColors.accent,
              borderRadius: BorderRadius.all(Radius.circular(999)),
            ),
          ),
        ),
      ),
    );
  }
}

/// Сетка под любое число книг: подбираем число колонок, при котором карта крупнее всего.
class _GridLayout {
  const _GridLayout(this.cols, this.cardW, this.cardH, this.width, this.height, [this.colGap = _gap]);

  final int cols;
  final double colGap;
  final double cardW;
  final double cardH;
  final double width;
  final double height;

  /// Карты не шире 200: иначе при малом числе книг они становятся огромными.
  static const _maxCardW = 200.0;

  /// Ровная сетка без пустых мест в последнем ряду выигрывает,
  /// если её карты мельче самых крупных не больше чем на 20 %.
  static const _evenTolerance = .8;

  /// Предел, до которого расходятся колонки.
  static const _maxColGap = _gap * 3;

  factory _GridLayout.fit(int n, Size box) {
    final options = <_GridLayout>[];
    for (var cols = 1; cols <= n; cols++) {
      final rows = (n / cols).ceil();
      var w = (box.width - _gap * (cols - 1)) / cols;
      var h = w / cardAspect;
      final maxH = (box.height - _gap * (rows - 1)) / rows;
      if (h > maxH) {
        h = maxH;
        w = h * cardAspect;
      }
      if (w > _maxCardW) {
        w = _maxCardW;
        h = w / cardAspect;
      }
      options.add(_GridLayout(cols, w, h, cols * w + (cols - 1) * _gap, rows * h + (rows - 1) * _gap));
    }
    final largest = options.reduce((a, b) => b.cardW > a.cardW + .5 ? b : a);
    final even = options.where((o) => n % o.cols == 0 && o.cardW >= largest.cardW * _evenTolerance);
    final best = even.isEmpty ? largest : even.reduce((a, b) => b.cardW > a.cardW + .5 ? b : a);

    // Если сетку ограничила высота, по бокам остаётся место: немного разводим колонки.
    if (best.cols < 2) return best;
    final colGap = ((box.width - best.cols * best.cardW) / (best.cols - 1)).clamp(_gap, _maxColGap).toDouble();
    return _GridLayout(
      best.cols,
      best.cardW,
      best.cardH,
      best.cols * best.cardW + (best.cols - 1) * colGap,
      best.height,
      colGap,
    );
  }
}
