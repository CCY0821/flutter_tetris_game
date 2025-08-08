import 'package:flutter/material.dart';
import '../core/constants.dart';

class GameBoard extends StatelessWidget {
  const GameBoard({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: boardWidth * blockSize,
        height: boardHeight * blockSize,
        color: Colors.black, // 背景顏色方便看到
        child: CustomPaint(
          painter: _BoardPainter(),
        ),
      ),
    );
  }
}

class _BoardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey
      ..style = PaintingStyle.stroke;

    for (int y = 0; y < boardHeight; y++) {
      for (int x = 0; x < boardWidth; x++) {
        final rect = Rect.fromLTWH(
          x * blockSize,
          y * blockSize,
          blockSize,
          blockSize,
        );
        canvas.drawRect(rect, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
