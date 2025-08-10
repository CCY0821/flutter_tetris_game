import 'package:flutter/material.dart';
import '../models/tetromino.dart';
import 'game_state.dart';

class BoardPainter extends CustomPainter {
  final List<List<Color?>> board;
  final Tetromino? tetromino;
  static const double cellSize = 20;

  BoardPainter(this.board, this.tetromino);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    // 繪製網格線
    paint.color = Colors.grey[800]!;
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
          paint.color = board[y][x]!;
          canvas.drawRect(
            Rect.fromLTWH(x * cellSize, y * cellSize, cellSize, cellSize),
            paint,
          );
        }
      }
    }

    // 繪製當前下落的方塊
    if (tetromino != null) {
      paint.color = tetromino!.color;
      for (final p in tetromino!.shape) {
        final x = tetromino!.x + p.dx.toInt();
        final y = tetromino!.y + p.dy.toInt();
        if (y >= 0 && y < board.length && x >= 0 && x < board[0].length) {
          canvas.drawRect(
            Rect.fromLTWH(x * cellSize, y * cellSize, cellSize, cellSize),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
