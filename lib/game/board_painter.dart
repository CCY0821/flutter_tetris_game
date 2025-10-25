import 'package:flutter/material.dart';
import '../models/tetromino.dart';
import '../theme/game_theme.dart';
import '../core/constants.dart';
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
  static final Paint _highlightPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;
  static final Paint _glowPaint = Paint(); // 單格外發光效果
  static final Paint _gradientPaint = Paint(); // 垂直漸層高光
  static final Paint _innerBorderPaint = Paint() // 內描邊效果
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;
  static final Paint _ghostPaint = Paint()..style = PaintingStyle.fill;
  static final Paint _ghostBorderPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;
  static final Paint _ghostDashPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;

  // 快取 Gradient 物件（參數化，避免每次重建）
  static const List<double> _gradientStops = [0.0, 1.0];

  BoardPainter(this.board, this.tetromino,
      {this.ghostPiece, this.cellSize = 20});

  void _drawBlock(Canvas canvas, double x, double y, Color blockColor,
      {bool isActive = false}) {
    final rect = Rect.fromLTWH(x * cellSize, y * cellSize, cellSize, cellSize);

    // 🌟 Step 1: 外發光效果 (依顏色調整強度) - 增強版
    final glowIntensity = isActive ? cyberpunkGlowMed : cyberpunkGlowSoft;
    _glowPaint.maskFilter = MaskFilter.blur(BlurStyle.outer, glowIntensity);
    _glowPaint.color = blockColor.withOpacity(
        isActive ? blockGlowOpacityActive : blockGlowOpacityNormal);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.inflate(1), const Radius.circular(3)),
      _glowPaint,
    );

    // 🎨 Step 2: 垂直漸層主體 (上淺下深) - 保持霓虹色彩
    // 優化：直接使用預先計算的顏色，避免每次 Color.lerp
    final topColor =
        Color.lerp(blockColor, Colors.white, blockGradientTopLighten)!;
    _gradientPaint.shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [topColor, blockColor],
      stops: _gradientStops,
    ).createShader(rect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(2)),
      _gradientPaint,
    );

    // ✨ Step 3: 頂部高光效果 - 增強版
    _highlightPaint.color = Colors.white.withOpacity(
        isActive ? blockHighlightOpacityActive : blockHighlightOpacityNormal);
    final highlightRect = Rect.fromLTWH(
        rect.left + 1, rect.top + 1, rect.width - 2, rect.height * 0.3);
    _highlightPaint.shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Colors.white.withOpacity(isActive
            ? blockTopHighlightStartActive
            : blockTopHighlightStartNormal),
        Colors.white.withOpacity(0.0),
      ],
    ).createShader(highlightRect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(highlightRect, const Radius.circular(1)),
      _highlightPaint,
    );

    // 🔲 Step 4: 1px 內描邊 (深色)
    _innerBorderPaint.color = Colors.black.withOpacity(blockInnerBorderOpacity);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(0.5), const Radius.circular(1.5)),
      _innerBorderPaint,
    );
  }

  void _drawGhostBlock(Canvas canvas, double x, double y, Color blockColor) {
    final rect = Rect.fromLTWH(x * cellSize, y * cellSize, cellSize, cellSize);

    // Ghost piece 使用半透明邊框樣式
    _ghostPaint.color = blockColor.withOpacity(ghostPieceFillOpacity);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(2)),
      _ghostPaint,
    );

    // 繪製邊框
    _ghostBorderPaint.color = blockColor.withOpacity(ghostPieceBorderOpacity);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(2)),
      _ghostBorderPaint,
    );

    // 添加虛線效果（可選）
    _ghostDashPaint.color = blockColor.withOpacity(ghostPieceDashOpacity);

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
    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height), _backgroundPaint);

    // 🌟 雙筆畫霓虹格線 - 模擬微光邊緣效果
    _gridPaint.shader = null;
    _gridGlowPaint.shader = null;

    // 第一次繪製：主格線
    _gridPaint.color = GameTheme.gridLine.withOpacity(gridLineOpacity);

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
    _gridGlowPaint.color = GameTheme.gridLine.withOpacity(gridGlowOpacity);

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
      // 添加邊界檢查防止越界
      if (y >= board.length) continue;

      for (int x = 0; x < GameState.colCount; x++) {
        // 添加邊界檢查防止越界
        if (x >= board[y].length) continue;

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

        // 檢查是否在有效範圍內且在可視區域
        if (GameState.isValidCoordinate(x, y) && GameState.isInVisibleArea(y)) {
          final visibleY = y - GameState.bufferRowCount;
          _drawGhostBlock(
              canvas, x.toDouble(), visibleY.toDouble(), ghostPiece!.color);
        }
      }
    }

    // 繪製當前下落的方塊（帶有特殊效果）
    if (tetromino != null) {
      for (final p in tetromino!.shape) {
        final x = tetromino!.x + p.dx.toInt();
        final y = tetromino!.y + p.dy.toInt();

        // 檢查是否在有效範圍內且在可視區域
        if (GameState.isValidCoordinate(x, y) && GameState.isInVisibleArea(y)) {
          final visibleY = y - GameState.bufferRowCount;
          _drawBlock(
              canvas, x.toDouble(), visibleY.toDouble(), tetromino!.color,
              isActive: true);
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
