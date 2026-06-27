/// The app's brand mark — a custom geometric glyph drawn on a solid ink
/// tile. Reads as a stylised "ticket / dispatch" symbol: a rounded
/// square with a notched corner and a cobalt accent bar.
///
/// Used on splash, login, and the app menu. Replaces the generic
/// `Icons.support_agent` so the brand has a unique, ownable mark rather
/// than a stock Material icon.
library;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    final Color tile = AppColors.inkButton(dark);
    final Color onTile = AppColors.onInkButton(dark);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: tile,
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: Center(
        child: SizedBox(
          width: size * 0.52,
          height: size * 0.52,
          child: CustomPaint(
            painter: _MarkPainter(
              stroke: onTile,
              accent: AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }
}

class _MarkPainter extends CustomPainter {
  const _MarkPainter({required this.stroke, required this.accent});

  final Color stroke;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double sw = (w * 0.13).clamp(1.6, 3.2);

    final Paint line = Paint()
      ..color = stroke
      ..strokeWidth = sw
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    // A ticket outline with a notched top-right corner.
    final double notch = w * 0.30;
    final Path ticket = Path()
      ..moveTo(0, h * 0.16)
      ..lineTo(0, h)
      ..lineTo(w, h)
      ..lineTo(w, notch)
      ..lineTo(w - notch, 0)
      ..lineTo(w * 0.16, 0)
      ..close();
    canvas.drawPath(ticket, line);

    // Cobalt accent bar — the "active line".
    final Paint bar = Paint()
      ..color = accent
      ..strokeWidth = sw
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(w * 0.28, h * 0.62),
      Offset(w * 0.72, h * 0.62),
      bar,
    );
    // A shorter line above it (muted) for the "row" feel.
    canvas.drawLine(
      Offset(w * 0.28, h * 0.40),
      Offset(w * 0.60, h * 0.40),
      line,
    );
  }

  @override
  bool shouldRepaint(_MarkPainter old) =>
      old.stroke != stroke || old.accent != accent;
}
