import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../utils/formatters.dart';

class TrendChart extends StatelessWidget {
  const TrendChart({
    super.key,
    required this.title,
    required this.values,
    required this.labels,
    this.height = 220,
  });

  final String title;
  final List<double> values;
  final List<String> labels;
  final double height;

  @override
  Widget build(BuildContext context) {
    final hasEnoughData = values.length >= 2;
    final minValue = values.isEmpty ? 0.0 : values.reduce(math.min);
    final maxValue = values.isEmpty ? 0.0 : values.reduce(math.max);
    final lastValue = values.isEmpty ? 0.0 : values.last;

    return Card(
      elevation: 1.0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _MetricChip(
                  label: '最低',
                  value: AppFormatters.score(minValue),
                ),
                _MetricChip(
                  label: '最高',
                  value: AppFormatters.score(maxValue),
                ),
                _MetricChip(
                  label: '当前',
                  value: AppFormatters.score(lastValue),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: height,
              child: hasEnoughData
                  ? CustomPaint(
                      painter: _TrendChartPainter(
                        values: values,
                        labels: labels,
                        lineColor: Theme.of(context).colorScheme.primary,
                        gridColor: Theme.of(context)
                            .colorScheme
                            .outlineVariant
                            .withOpacity(0.5),
                        textColor:
                            Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      child: Container(),
                    )
                  : Center(
                      child: Text(
                        '数据不足，至少需要 2 天快照',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$label：$value',
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _TrendChartPainter extends CustomPainter {
  _TrendChartPainter({
    required this.values,
    required this.labels,
    required this.lineColor,
    required this.gridColor,
    required this.textColor,
  });

  final List<double> values;
  final List<String> labels;
  final Color lineColor;
  final Color gridColor;
  final Color textColor;

  @override
  void paint(Canvas canvas, Size size) {
    const leftPad = 42.0;
    const rightPad = 12.0;
    const topPad = 12.0;
    const bottomPad = 30.0;

    final chartWidth = size.width - leftPad - rightPad;
    final chartHeight = size.height - topPad - bottomPad;

    if (chartWidth <= 0 || chartHeight <= 0 || values.length < 2) {
      return;
    }

    final minValue = values.reduce(math.min);
    final maxValue = values.reduce(math.max);
    final valueRange = (maxValue - minValue).abs() < 0.0001
        ? 1.0
        : (maxValue - minValue);

    final axisPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final pointPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;

    final dashedGridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;

    // axes
    canvas.drawLine(
      const Offset(leftPad, topPad),
      Offset(leftPad, topPad + chartHeight),
      axisPaint,
    );
    canvas.drawLine(
      Offset(leftPad, topPad + chartHeight),
      Offset(leftPad + chartWidth, topPad + chartHeight),
      axisPaint,
    );

    // horizontal grid
    const gridCount = 4;
    final textStyle = TextStyle(
      color: textColor,
      fontSize: 10,
    );

    for (int i = 0; i <= gridCount; i++) {
      final y = topPad + chartHeight - (chartHeight / gridCount) * i;
      _drawDashedLine(
        canvas,
        Offset(leftPad, y),
        Offset(leftPad + chartWidth, y),
        dashedGridPaint,
      );

      final v = minValue + (valueRange / gridCount) * i;
      _drawText(
        canvas,
        AppFormatters.score(v),
        Offset(2, y - 7),
        textStyle,
      );
    }

    final stepX = chartWidth / (values.length - 1);

    final points = <Offset>[];
    for (int i = 0; i < values.length; i++) {
      final normalized = (values[i] - minValue) / valueRange;
      final x = leftPad + stepX * i;
      final y = topPad + chartHeight - (normalized * chartHeight);
      points.add(Offset(x, y));
    }

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    canvas.drawPath(path, linePaint);

    for (final point in points) {
      canvas.drawCircle(point, 3.5, pointPaint);
    }

    // bottom labels: first / middle / last
    if (labels.isNotEmpty) {
      _drawText(
        canvas,
        labels.first,
        Offset(leftPad - 4, topPad + chartHeight + 8),
        textStyle,
        center: false,
      );

      if (labels.length > 2) {
        final midIndex = labels.length ~/ 2;
        _drawText(
          canvas,
          labels[midIndex],
          Offset(leftPad + chartWidth / 2 - 12, topPad + chartHeight + 8),
          textStyle,
          center: false,
        );
      }

      _drawText(
        canvas,
        labels.last,
        Offset(leftPad + chartWidth - 26, topPad + chartHeight + 8),
        textStyle,
        center: false,
      );
    }
  }

  void _drawDashedLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Paint paint,
  ) {
    const dashWidth = 5.0;
    const dashSpace = 4.0;
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final distance = math.sqrt(dx * dx + dy * dy);
    final dashCount = (distance / (dashWidth + dashSpace)).floor();

    for (int i = 0; i < dashCount; i++) {
      final startT = i * (dashWidth + dashSpace) / distance;
      final endT = (i * (dashWidth + dashSpace) + dashWidth) / distance;

      final x1 = start.dx + dx * startT;
      final y1 = start.dy + dy * startT;
      final x2 = start.dx + dx * endT;
      final y2 = start.dy + dy * endT;

      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);
    }
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset offset,
    TextStyle style, {
    bool center = false,
  }) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();

    final drawOffset = center
        ? Offset(offset.dx - textPainter.width / 2, offset.dy)
        : offset;

    textPainter.paint(canvas, drawOffset);
  }

  @override
  bool shouldRepaint(covariant _TrendChartPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.labels != labels ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.gridColor != gridColor ||
        oldDelegate.textColor != textColor;
  }
}