import 'package:flutter/material.dart';
import 'game_config.dart';
import '../models/tetromino.dart';

class PlacementSystem {
  static bool inBounds(int x, int y, GameConfig config) {
    final totalRows = config.rows + 20; // 20 buffer rows
    return x >= 0 && x < config.cols && y >= 0 && y < totalRows;
  }

  static bool canPlace(
      List<List<Color?>> board, Tetromino tetromino, GameConfig config,
      {int? atX, int? atY}) {
    final testX = atX ?? tetromino.x;
    final testY = atY ?? tetromino.y;

    for (final Offset offset in tetromino.shape) {
      final x = testX + offset.dx.round();
      final y = testY + offset.dy.round();

      if (!inBounds(x, y, config)) return false;
      if (board[y][x] != null) return false;
    }

    return true;
  }

  static int computeSpawnX(TetrominoType type, GameConfig config) {
    final shape = Tetromino.initialShapes[type]!;
    final minX = shape.map((p) => p.dx).reduce((a, b) => a < b ? a : b).round();
    final maxX = shape.map((p) => p.dx).reduce((a, b) => a > b ? a : b).round();
    final boundingWidth = maxX - minX + 1;

    return ((config.cols - boundingWidth) / 2).floor() - minX;
  }

  static int computeSpawnY(TetrominoType type) {
    switch (type) {
      case TetrominoType.I:
        return 18; // I型在緩衝區稍高
      default:
        return 19; // 標準緩衝區高度
    }
  }
}
