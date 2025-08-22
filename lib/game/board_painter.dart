import 'package:flutter/material.dart';
import '../models/tetromino.dart';
import '../theme/game_theme.dart';
import 'game_state.dart';

class BoardPainter extends CustomPainter {
  final List<List<Color?>> board;
  final Tetromino? tetromino;
  final Tetromino? ghostPiece;
  final double cellSize;
  
  // 快取Paint物件避免重複建立
  static final Paint _backgroundPaint = Paint();
  static final Paint _gridPaint = Paint()..strokeWidth = 0.5;
  static final Paint _gridGlowPaint = Paint()..strokeWidth = 0.3; // 微光邊緣用更細線寬
  static final Paint _blockPaint = Paint();
  static final Paint _highlightPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;
  static final Paint _shadowPaint = Paint();
  static final Paint _ghostPaint = Paint()..style = PaintingStyle.fill;
  static final Paint _ghostBorderPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;
  static final Paint _ghostDashPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;

  BoardPainter(this.board, this.tetromino, {this.ghostPiece, this.cellSize = 20});

  void _drawBlock(Canvas canvas, double x, double y, Color blockColor,
      {bool isActive = false}) {
    final rect = Rect.fromLTWH(x * cellSize, y * cellSize, cellSize, cellSize);
    
    // 使用快取的Paint並設定顏色
    _blockPaint.color = blockColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(2)),
      _blockPaint,
    );

    // 添加高光效果
    _highlightPaint.color = Colors.white.withOpacity(isActive ? 0.4 : 0.2);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        rect.deflate(0.5),
        const Radius.circular(2),
      ),
      _highlightPaint,
    );

    // 添加內陰影效果
    _shadowPaint.color = Colors.black.withOpacity(0.3);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
            x * cellSize + 1, y * cellSize + 1, cellSize - 2, cellSize - 2),
        const Radius.circular(1),
      ),
      _shadowPaint,
    );
  }

  void _drawGhostBlock(Canvas canvas, double x, double y, Color blockColor) {
    final rect = Rect.fromLTWH(x * cellSize, y * cellSize, cellSize, cellSize);

    // Ghost piece 使用半透明邊框樣式
    _ghostPaint.color = blockColor.withOpacity(0.3);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(2)),
      _ghostPaint,
    );

    // 繪製邊框
    _ghostBorderPaint.color = blockColor.withOpacity(0.6);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(2)),
      _ghostBorderPaint,
    );

    // 添加虛線效果（可選）
    _ghostDashPaint.color = blockColor.withOpacity(0.8);

    // 繪製內部虛線
    final innerRect = rect.deflate(3);
    canvas.drawRRect(
      RRect.fromRectAndRadius(innerRect, const Radius.circular(1)),
      _ghostDashPaint,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    // 繪製背景
    _backgroundPaint.shader = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        GameTheme.gameBoardBg,
        Color(0xFF0F1419),
      ],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), _backgroundPaint);

    // 🌟 雙筆畫霓虹格線 - 模擬微光邊緣效果
    _gridPaint.shader = null;
    _gridGlowPaint.shader = null;
    
    // 第一次繪製：主格線 (60% 透明度)
    _gridPaint.color = GameTheme.gridLine.withOpacity(0.6);
    
    for (int y = 0; y <= GameState.rowCount; y++) {
      canvas.drawLine(
        Offset(0, y * cellSize),
        Offset(size.width, y * cellSize),
        _gridPaint,
      );
    }
    for (int x = 0; x <= GameState.colCount; x++) {
      canvas.drawLine(
        Offset(x * cellSize, 0),
        Offset(x * cellSize, size.height),
        _gridPaint,
      );
    }
    
    // 第二次繪製：微光邊緣 (更低透明度 + 微偏移)
    _gridGlowPaint.color = GameTheme.gridLine.withOpacity(0.2);
    
    for (int y = 0; y <= GameState.rowCount; y++) {
      // 微偏移製造光暈效果
      canvas.drawLine(
        Offset(0.5, y * cellSize + 0.5),
        Offset(size.width + 0.5, y * cellSize + 0.5),
        _gridGlowPaint,
      );
    }
    for (int x = 0; x <= GameState.colCount; x++) {
      // 微偏移製造光暈效果
      canvas.drawLine(
        Offset(x * cellSize + 0.5, 0.5),
        Offset(x * cellSize + 0.5, size.height + 0.5),
        _gridGlowPaint,
      );
    }

    // 繪製已鎖定的方塊（只繪製可見區域）
    for (int y = GameState.bufferRowCount; y < GameState.totalRowCount; y++) {
      for (int x = 0; x < GameState.colCount; x++) {
        if (board[y][x] != null) {
          // 將緩衝區座標轉換為可見區域座標
          final visibleY = y - GameState.bufferRowCount;
          _drawBlock(canvas, x.toDouble(), visibleY.toDouble(), board[y][x]!);
        }
      }
    }

    // 先繪製Ghost piece（在當前方塊之下）
    if (ghostPiece != null) {
      for (final p in ghostPiece!.shape) {
        final x = ghostPiece!.x + p.dx.toInt();
        final y = ghostPiece!.y + p.dy.toInt();

        // 檢查是否在有效範圍內
        if (x >= 0 &&
            x < GameState.colCount &&
            y >= 0 &&
            y < GameState.totalRowCount) {
          // 只繪製在可見區域內的部分
          if (y >= GameState.bufferRowCount) {
            final visibleY = y - GameState.bufferRowCount;
            _drawGhostBlock(
                canvas, x.toDouble(), visibleY.toDouble(), ghostPiece!.color);
          }
        }
      }
    }

    // 繪製當前下落的方塊（帶有特殊效果）
    if (tetromino != null) {
      for (final p in tetromino!.shape) {
        final x = tetromino!.x + p.dx.toInt();
        final y = tetromino!.y + p.dy.toInt();

        // 檢查是否在有效範圍內
        if (x >= 0 &&
            x < GameState.colCount &&
            y >= 0 &&
            y < GameState.totalRowCount) {
          // 只繪製在可見區域內的部分
          if (y >= GameState.bufferRowCount) {
            final visibleY = y - GameState.bufferRowCount;
            _drawBlock(
                canvas, x.toDouble(), visibleY.toDouble(), tetromino!.color,
                isActive: true);
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant BoardPainter oldDelegate) {
    return board != oldDelegate.board ||
           tetromino != oldDelegate.tetromino ||
           ghostPiece != oldDelegate.ghostPiece ||
           cellSize != oldDelegate.cellSize;
  }
}
