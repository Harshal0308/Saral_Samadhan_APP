import 'package:flutter/material.dart';

class DailyAttendanceStat {
  final DateTime date;
  final int attended;
  final int total;

  const DailyAttendanceStat({
    required this.date,
    required this.attended,
    required this.total,
  });

  double get percentage {
    if (total == 0) return 0;
    return (attended * 100.0) / total;
  }
}

class AttendanceGraph extends StatelessWidget {
  final List<DailyAttendanceStat> data;

  const AttendanceGraph({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Container(
        height: 120,
        alignment: Alignment.center,
        child: const Text(
          'No attendance data yet.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return SizedBox(
      height: 160,
      child: CustomPaint(
        painter: _AttendanceGraphPainter(data: data, textStyle: Theme.of(context).textTheme.bodySmall),
      ),
    );
  }
}

class _AttendanceGraphPainter extends CustomPainter {
  final List<DailyAttendanceStat> data;
  final TextStyle? textStyle;

  _AttendanceGraphPainter({
    required this.data,
    this.textStyle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    const double leftMargin = 32;
    const double bottomMargin = 24;
    const double topMargin = 16;
    const double rightMargin = 8;

    final double chartWidth = size.width - leftMargin - rightMargin;
    final double chartHeight = size.height - topMargin - bottomMargin;

    final Paint axisPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 1;

    // Axes
    final double originX = leftMargin;
    final double originY = size.height - bottomMargin;

    // Y-axis
    canvas.drawLine(
      Offset(originX, topMargin),
      Offset(originX, originY),
      axisPaint,
    );

    // X-axis
    canvas.drawLine(
      Offset(originX, originY),
      Offset(size.width - rightMargin, originY),
      axisPaint,
    );

    // Y-axis ticks (0, 20, 40, 60, 80, 100)
    final List<int> yTicks = [0, 20, 40, 60, 80, 100];
    for (final tick in yTicks) {
      final double y = originY - (tick / 100.0) * chartHeight;

      // Tick line
      canvas.drawLine(
        Offset(originX - 4, y),
        Offset(originX, y),
        axisPaint,
      );

      // Tick label
      final tp = _buildTextPainter('$tick', textStyle);
      tp.layout();
      tp.paint(canvas, Offset(originX - tp.width - 6, y - tp.height / 2));
    }

    // Bars
    final int n = data.length;
    final double groupWidth = chartWidth / n;
    final double barWidth = groupWidth * 0.4;

    for (int i = 0; i < n; i++) {
      final stat = data[i];
      final double centerX = originX + groupWidth * (i + 0.5);

      final double percent = stat.percentage.clamp(0, 100);
      final double barHeight = (percent / 100.0) * chartHeight;

      final double barLeft = centerX - barWidth / 2;
      final double barTop = originY - barHeight;
      final double barRight = centerX + barWidth / 2;

      final Rect barRect = Rect.fromLTRB(barLeft, barTop, barRight, originY);

      final Paint barPaint = Paint()
        ..color = Colors.blueAccent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawRect(barRect, barPaint);

      // Label: "attended/total"
      final String ratioLabel = '${stat.attended}/${stat.total}';
      final TextPainter ratioTp = _buildTextPainter(ratioLabel, textStyle);
      ratioTp.layout();

      final double labelX = centerX - ratioTp.width / 2;
      double labelY = barTop - ratioTp.height - 2;
      if (labelY < topMargin) {
        labelY = topMargin;
      }
      ratioTp.paint(canvas, Offset(labelX, labelY));

      // X-axis label: day of month
      final String dayLabel = '${stat.date.day}';
      final TextPainter dayTp = _buildTextPainter(dayLabel, textStyle);
      dayTp.layout();
      dayTp.paint(
        canvas,
        Offset(centerX - dayTp.width / 2, originY + 4),
      );
    }
  }

  TextPainter _buildTextPainter(String text, TextStyle? baseStyle) {
    final TextSpan span = TextSpan(
      text: text,
      style: baseStyle ?? const TextStyle(fontSize: 10, color: Colors.black),
    );
    return TextPainter(
      text: span,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
  }

  @override
  bool shouldRepaint(covariant _AttendanceGraphPainter oldDelegate) {
    return oldDelegate.data != data || oldDelegate.textStyle != textStyle;
  }
}
