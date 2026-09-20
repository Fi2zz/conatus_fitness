import 'package:flutter/cupertino.dart';

/// BPM 曲线画笔：四阶段均值点连成折线（架构 6.1 曲线可视化）。
class BpmCurvePainter extends CustomPainter {
  BpmCurvePainter(this.bpms);

  static const _minBpm = 60;
  static const _maxBpm = 180;
  static const _topPad = 12.0;
  static const _bottomPad = 12.0;

  final List<int> bpms;

  @override
  void paint(Canvas canvas, Size size) {
    if (bpms.length < 2) return;
    final points = <Offset>[
      for (var i = 0; i < bpms.length; i++)
        Offset(
          size.width * i / (bpms.length - 1),
          size.height -
              _bottomPad -
              (size.height - _topPad - _bottomPad) *
                  (bpms[i] - _minBpm) /
                  (_maxBpm - _minBpm),
        ),
    ];
    final line = Paint()
      ..color = CupertinoColors.systemBlue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < points.length - 1; i++) {
      canvas.drawLine(points[i], points[i + 1], line);
    }
    final dot = Paint()..color = CupertinoColors.systemBlue;
    for (final point in points) {
      canvas.drawCircle(point, 4, dot);
    }
  }

  @override
  bool shouldRepaint(BpmCurvePainter oldDelegate) => oldDelegate.bpms != bpms;
}
