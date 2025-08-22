import 'package:flutter/material.dart';
import '../core/constants.dart';

/// Cyberpunk 風格全畫面掃描線疊層
class ScanlineOverlay extends StatelessWidget {
  const ScanlineOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    if (!kShowScanline) {
      return const SizedBox.shrink();
    }

    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(
          painter: ScanlinePainter(),
        ),
      ),
    );
  }
}

/// 掃描線 CustomPainter 實現
class ScanlinePainter extends CustomPainter {
  static final Paint _scanlinePaint = Paint()
    ..color = Colors.white.withOpacity(kScanlineOpacity)
    ..strokeWidth = 1.0;

  @override
  void paint(Canvas canvas, Size size) {
    // 繪製水平掃描線
    for (double y = 0; y < size.height; y += kScanlineSpacing) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        _scanlinePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}