import 'package:flutter/material.dart';

import '../theme.dart';

enum CovenButtonKind { primary, ghost }

/// Кнопка из UI Kit: высота 52, скругление 999, бока 26, иконка 20 с зазором 10.
/// На экране одна основная кнопка, остальные контурные.
class CovenButton extends StatefulWidget {
  const CovenButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.kind = CovenButtonKind.ghost,
    this.icon,
  });

  const CovenButton.primary({super.key, required this.label, required this.onPressed, this.icon})
      : kind = CovenButtonKind.primary;

  final String label;
  final VoidCallback? onPressed;
  final CovenButtonKind kind;
  final Widget? icon;

  @override
  State<CovenButton> createState() => _CovenButtonState();
}

class _CovenButtonState extends State<CovenButton> {
  bool _pressed = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final primary = widget.kind == CovenButtonKind.primary;

    final Color bg;
    final Color fg;
    final Color? border;
    if (primary) {
      bg = !enabled ? const Color(0xFF4A3F33) : (_pressed ? CovenColors.accentHover : CovenColors.accent);
      fg = enabled ? CovenColors.onAccent : const Color(0xFF8C8170);
      border = null;
    } else {
      bg = _pressed ? CovenColors.accent.withValues(alpha: .18) : Colors.transparent;
      fg = enabled ? CovenColors.text : const Color(0xFF6E6478);
      border = CovenColors.accent.withValues(alpha: enabled ? .55 : .2);
    }

    return Semantics(
      button: true,
      enabled: enabled,
      child: FocusableActionDetector(
        enabled: enabled,
        onShowFocusHighlight: (v) => setState(() => _focused = v),
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) => widget.onPressed?.call()),
        },
        child: GestureDetector(
          onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
          onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
          onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
          onTap: widget.onPressed,
          child: AnimatedScale(
            scale: _pressed ? .97 : 1,
            duration: const Duration(milliseconds: 120),
            child: Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 26),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(999),
                border: border == null ? null : Border.all(color: border),
              ),
              foregroundDecoration: _focused
                  ? BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: CovenColors.text, width: 2, strokeAlign: 3),
                    )
                  : null,
              child: IconTheme(
                data: IconThemeData(color: fg, size: 20),
                child: DefaultTextStyle(
                  style: CovenText.button(color: fg),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.icon != null) ...[widget.icon!, const SizedBox(width: 10)],
                      Text(widget.label, maxLines: 1),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Линейная иконка «перетасовать» 24×24, линия 1.8.
class ShuffleIcon extends StatelessWidget {
  const ShuffleIcon({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = IconTheme.of(context);
    return CustomPaint(
      size: Size.square(theme.size ?? 20),
      painter: _ShufflePainter(theme.color ?? CovenColors.text),
    );
  }
}

class _ShufflePainter extends CustomPainter {
  _ShufflePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 24;
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8 * k
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    Offset o(double x, double y) => Offset(x * k, y * k);
    canvas.drawPath(Path()..moveTo(16 * k, 3 * k)..lineTo(21 * k, 3 * k)..lineTo(21 * k, 8 * k), p);
    canvas.drawLine(o(4, 20), o(21, 3), p);
    canvas.drawPath(Path()..moveTo(21 * k, 16 * k)..lineTo(21 * k, 21 * k)..lineTo(16 * k, 21 * k), p);
    canvas.drawLine(o(15, 15), o(21, 21), p);
    canvas.drawLine(o(4, 4), o(9, 9), p);
  }

  @override
  bool shouldRepaint(_ShufflePainter old) => old.color != color;
}

/// Орнамент-разделитель: две линии и ромб посередине.
class DividerOrnament extends StatelessWidget {
  const DividerOrnament({super.key, required this.width, required this.color, this.stroke = 1.2});

  final double width;
  final Color color;
  final double stroke;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size(width, width * 8 / 34), painter: _DividerPainter(color, stroke));
  }
}

class _DividerPainter extends CustomPainter {
  _DividerPainter(this.color, this.stroke);

  final Color color;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 34;
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    final cy = size.height / 2;
    canvas.drawLine(Offset(0, cy), Offset(12 * k, cy), p);
    canvas.drawLine(Offset(22 * k, cy), Offset(34 * k, cy), p);
    final d = size.height * .4;
    canvas.drawPath(
      Path()
        ..moveTo(17 * k, cy - d)
        ..lineTo(17 * k + d, cy)
        ..lineTo(17 * k, cy + d)
        ..lineTo(17 * k - d, cy)
        ..close(),
      p,
    );
  }

  @override
  bool shouldRepaint(_DividerPainter old) => old.color != color;
}
