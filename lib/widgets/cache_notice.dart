import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';
import 'coven_button.dart';

const _fg = Color(0xFFCDB8E6);
const _fgStrong = Color(0xFFE4D6F4);

const _months = ['янв.', 'февр.', 'марта', 'апр.', 'мая', 'июня', 'июля', 'авг.', 'сент.', 'окт.', 'нояб.', 'дек.'];

/// «24 сент., 21:19»
String formatSavedAt(DateTime t) {
  String two(int v) => v.toString().padLeft(2, '0');
  return '${t.day} ${_months[t.month - 1]}, ${two(t.hour)}:${two(t.minute)}';
}

/// Пометка, что сети нет и расклад идёт по сохранённому списку.
/// [inline] — компактная пилюля в шапке для горизонтальной ориентации,
/// иначе — плашка во всю ширину под шапкой.
class CacheNotice extends StatefulWidget {
  const CacheNotice({
    super.key,
    required this.savedAt,
    required this.checking,
    required this.onRefresh,
    this.inline = false,
  });

  final DateTime? savedAt;
  final bool checking;
  final VoidCallback onRefresh;
  final bool inline;

  @override
  State<CacheNotice> createState() => _CacheNoticeState();
}

class _CacheNoticeState extends State<CacheNotice> with TickerProviderStateMixin {
  // Появление: .5 s, сверху на 6 px.
  late final _appear = AnimationController(vsync: this, duration: const Duration(milliseconds: 500))..forward();
  late final _spin = AnimationController(vsync: this, duration: const Duration(seconds: 1));

  @override
  void initState() {
    super.initState();
    if (widget.checking) _spin.repeat();
  }

  @override
  void didUpdateWidget(CacheNotice old) {
    super.didUpdateWidget(old);
    if (widget.checking && !_spin.isAnimating) {
      _spin.repeat();
    } else if (!widget.checking) {
      _spin
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _appear.dispose();
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final date = widget.savedAt == null ? null : formatSavedAt(widget.savedAt!);
    final child = widget.inline ? _pill(date) : _banner(date);
    return Semantics(
      liveRegion: true,
      child: AnimatedBuilder(
        animation: _appear,
        builder: (context, child) {
          final t = Curves.ease.transform(_appear.value);
          return Opacity(opacity: t, child: Transform.translate(offset: Offset(0, -6 * (1 - t)), child: child));
        },
        child: child,
      ),
    );
  }

  BoxDecoration _decoration(double radius) => BoxDecoration(
        color: CovenColors.lavender.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: CovenColors.lavender.withValues(alpha: .35)),
      );

  Widget _pill(String? date) {
    return Container(
      height: 52,
      padding: const EdgeInsets.only(left: 14, right: 6),
      decoration: _decoration(999),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const WifiOffIcon(size: 18, color: _fg),
          const SizedBox(width: 10),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Офлайн · сохранённый список', style: CovenText.caption(color: _fgStrong).copyWith(fontSize: 13, fontWeight: FontWeight.w700, height: 1.2)),
              const SizedBox(height: 2),
              Text(date == null ? 'дата обновления неизвестна' : 'обновлён $date', style: CovenText.caption().copyWith(fontSize: 12, height: 1.2)),
            ],
          ),
          const SizedBox(width: 10),
          _RefreshButton(spin: _spin, checking: widget.checking, onPressed: widget.onRefresh),
        ],
      ),
    );
  }

  Widget _banner(String? date) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 8, 8, 8),
      decoration: _decoration(16),
      child: Row(
        children: [
          const WifiOffIcon(size: 20, color: _fg),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Нет интернета — показываем сохранённый список книг',
                  style: CovenText.body(color: _fgStrong).copyWith(fontWeight: FontWeight.w700, height: 1.3),
                ),
                const SizedBox(height: 2),
                Text(
                  date == null ? 'Расклад работает как обычно.' : 'Обновлён $date. Расклад работает как обычно.',
                  style: CovenText.caption().copyWith(fontSize: 13, height: 1.3),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          _RefreshButton(
            spin: _spin,
            checking: widget.checking,
            onPressed: widget.onRefresh,
            label: widget.checking ? 'Проверяем…' : 'Обновить',
          ),
        ],
      ),
    );
  }
}

/// Лавандовая контурная кнопка 44 px; во время проверки стрелка крутится.
class _RefreshButton extends StatelessWidget {
  const _RefreshButton({required this.spin, required this.checking, required this.onPressed, this.label});

  final Animation<double> spin;
  final bool checking;
  final VoidCallback onPressed;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final icon = AnimatedBuilder(
      animation: spin,
      builder: (context, child) => Transform.rotate(angle: spin.value * 2 * math.pi, child: child),
      child: const IconTheme(data: IconThemeData(color: _fgStrong, size: 18), child: RetryIcon()),
    );
    return Semantics(
      button: true,
      enabled: !checking,
      label: label == null ? 'Обновить список' : null,
      child: Opacity(
        opacity: checking ? .7 : 1,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: checking ? null : onPressed,
            customBorder: const StadiumBorder(),
            hoverColor: CovenColors.lavender.withValues(alpha: .14),
            child: Container(
              height: 44,
              constraints: const BoxConstraints(minWidth: 44),
              padding: EdgeInsets.symmetric(horizontal: label == null ? 0 : 16),
              decoration: ShapeDecoration(
                shape: StadiumBorder(side: BorderSide(color: CovenColors.lavender.withValues(alpha: .45))),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  icon,
                  if (label != null) ...[
                    const SizedBox(width: 8),
                    Text(label!, style: CovenText.button(color: _fgStrong).copyWith(fontSize: 14)),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
