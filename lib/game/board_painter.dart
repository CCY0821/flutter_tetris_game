import 'package:flutter/material.dart';
import '../models/tetromino.dart';
import '../theme/game_theme.dart';
import 'game_state.dart';

class BoardPainter extends CustomPainter {
  final List<List<Color?>> board;
  final Tetromino? tetromino;
  static const double cellSize = 20;

  BoardPainter(this.board, this.tetromino);

  void _drawBlock(Canvas canvas, double x, double y, Color blockColor,
      {bool isActive = false}) {
    final paint = Paint();
    final rect = Rect.fromLTWH(x * cellSize, y * cellSize, cellSize, cellSize);

    // 主要方塊顏色
    paint.color = blockColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(2)),
      paint,
    );

    // 添加高光效果
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(isActive ? 0.4 : 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        rect.deflate(0.5),
        const Radius.circular(2),
      ),
      highlightPaint,
    );

    // 添加內陰影效果
    final shadowPaint = Paint()..color = Colors.black.withOpacity(0.3);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
            x * cellSize + 1, y * cellSize + 1, cellSize - 2, cellSize - 2),
        const Radius.circular(1),
      ),
      shadowPaint,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    // 繪製背景
    paint.shader = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        GameTheme.gameBoardBg,
        Color(0xFF0F1419),
      ],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // 繪製細微的網格線
    paint.shader = null;
    paint.color = GameTheme.gridLine.withOpacity(0.3);
    paint.strokeWidth = 0.5;

    for (int y = 0; y <= GameState.rowCount; y++) {
      canvas.drawLine(
        Offset(0, y * cellSize),
        Offset(size.width, y * cellSize),
        paint,
      );
    }
    for (int x = 0; x <= GameState.colCount; x++) {
      canvas.drawLine(
        Offset(x * cellSize, 0),
        Offset(x * cellSize, size.height),
        paint,
      );
    }

    // 繪製已鎖定的方塊
    for (int y = 0; y < board.length; y++) {
      for (int x = 0; x < board[y].length; x++) {
        if (board[y][x] != null) {
          _drawBlock(canvas, x.toDouble(), y.toDouble(), board[y][x]!);
        }
      }
    }

    // 繪製當前下落的方塊（帶有特殊效果）
    if (tetromino != null) {
      for (final p in tetromino!.shape) {
        final x = tetromino!.x + p.dx.toInt();
        final y = tetromino!.y + p.dy.toInt();
        if (y >= 0 && y < board.length && x >= 0 && x < board[0].length) {
          _drawBlock(canvas, x.toDouble(), y.toDouble(), tetromino!.color,
              isActive: true);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
