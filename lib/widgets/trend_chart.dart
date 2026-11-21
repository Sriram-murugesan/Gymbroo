import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data.dart';
import '../theme.dart';

typedef ChartPoint = ({String date, double value});

class TrendChart extends StatelessWidget {
  final List<ChartPoint> points;
  const TrendChart({super.key, required this.points});

  @override
  Widget build(BuildContext context) => AspectRatio(
        aspectRatio: 2,
        child: CustomPaint(painter: _TrendPainter(points)),
      );
}

class _TrendPainter extends CustomPainter {
  final List<ChartPoint> pts;
  _TrendPainter(this.pts);

  @override
  void paint(Canvas canvas, Size size) {
    const px = 8.0, pt = 24.0, pb = 24.0;
    final vs = pts.map((p) => p.value);
    var lo = vs.reduce(math.min), hi = vs.reduce(math.max);
    if (lo == hi) {
      lo -= 1;
      hi += 1;
    }
    final n = pts.length - 1;
    double x(int i) => px + i * (size.width - 2 * px) / n;
    double y(double v) => pt + (1 - (v - lo) / (hi - lo)) * (size.height - pt - pb);
    final base = size.height - pb;

    canvas.drawLine(Offset(px, base), Offset(size.width - px, base), Paint()..color = C.line);

    final line = Path()..moveTo(x(0), y(pts[0].value));
    for (var i = 1; i <= n; i++) {
      line.lineTo(x(i), y(pts[i].value));
    }
    final fill = Path.from(line)
      ..lineTo(x(n), base)
      ..lineTo(x(0), base)
      ..close();
    canvas.drawPath(fill, Paint()..color = C.accent.withValues(alpha: .12));
    canvas.drawPath(
      line,
      Paint()
        ..color = C.accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
    for (var i = 0; i <= n; i++) {
      canvas.drawCircle(Offset(x(i), y(pts[i].value)), 3.5, Paint()..color = C.accent);
    }

    void label(String t, Offset at, {TextAlign align = TextAlign.left, Color color = C.muted, bool bold = false}) {
      final tp = TextPainter(
        text: TextSpan(text: t, style: TextStyle(color: color, fontSize: 11, fontWeight: bold ? FontWeight.w700 : FontWeight.w400)),
        textDirection: TextDirection.ltr,
      )..layout();
      final dx = align == TextAlign.right ? at.dx - tp.width : at.dx;
      tp.paint(canvas, Offset(dx, at.dy));
    }

    label(fmtNum(pts[0].value), Offset(x(0), y(pts[0].value) - 18));
    label(fmtNum(pts[n].value), Offset(x(n), y(pts[n].value) - 18), align: TextAlign.right, color: C.text, bold: true);
    label(shortDate(pts[0].date), Offset(px, size.height - 16));
    label(shortDate(pts[n].date), Offset(size.width - px, size.height - 16), align: TextAlign.right);
  }

  @override
  bool shouldRepaint(covariant _TrendPainter old) => old.pts != pts;
}
