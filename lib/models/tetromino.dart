import 'dart:math';
import 'package:flutter/material.dart';
import '../core/constants.dart';

/// 俄羅斯方塊類型枚舉
enum TetrominoType { I, O, T, S, Z, L, J, D, U, H, demon }

/// 俄羅斯方塊類別，支援SRS旋轉系統
class Tetromino {
  final TetrominoType type;
  final Color color;
  List<Offset> shape;
  int x; // 中心點在棋盤上的位置
  int y;
  int rotation; // 旋轉狀態 (0-3)

  Tetromino({
    required this.type,
    required this.color,
    required this.shape,
    required this.x,
    required this.y,
    this.rotation = 0,
  });

  /// 方塊類型與霓虹顏色對應表 - Cyberpunk 2077 風格
  static const Map<TetrominoType, Color> typeColors = {
    TetrominoType.I: cyberpunkPrimary, // I: 霓虹青色 #00E5FF (primary)
    TetrominoType.J: Color(0xFF0066FF), // J: 純藍霓虹 (深邃電藍)
    TetrominoType.L: cyberpunkSecondary, // L: 霓虹洋紅 #FF2ED1 (secondary)
    TetrominoType.O: cyberpunkCaution, // O: 賽博黃 #FCEE09 (警示霓虹)
    TetrominoType.S: Color(0xFF00FF88), // S: 霓虹綠 (青綠電光)
    TetrominoType.T: cyberpunkAccent, // T: 電光紫 #8A2BE2 (accent)
    TetrominoType.Z: Color(0xFFFF0066), // Z: 霓虹紅 (洋紅偏紅)
    TetrominoType.D: Color(0xFFFF6600), // D: 霓虹橙 (熾熱橙光)
    TetrominoType.U: Color(0xFFFF1493), // U: 霓虹粉紅 (深粉紅電光)
    TetrominoType.H: Color(0xFFCCFF00), // H: 霓虹青檸 (電光黃綠)
    TetrominoType.demon: Color(0xFFFFD700), // DEMON: 金色 (實際渲染使用徑向漸層)
  };

  /// 初始形狀定義（北向，旋轉狀態0）
  static const Map<TetrominoType, List<Offset>> initialShapes = {
    TetrominoType.I: [Offset(-1, 0), Offset(0, 0), Offset(1, 0), Offset(2, 0)],
    TetrominoType.O: [Offset(0, 0), Offset(1, 0), Offset(0, 1), Offset(1, 1)],
    TetrominoType.T: [Offset(-1, 0), Offset(0, 0), Offset(1, 0), Offset(0, 1)],
    TetrominoType.S: [Offset(-1, 0), Offset(0, 0), Offset(0, 1), Offset(1, 1)],
    TetrominoType.Z: [Offset(-1, 1), Offset(0, 1), Offset(0, 0), Offset(1, 0)],
    TetrominoType.L: [Offset(-1, 0), Offset(0, 0), Offset(1, 0), Offset(1, 1)],
    TetrominoType.J: [Offset(-1, 0), Offset(0, 0), Offset(1, 0), Offset(-1, 1)],
    TetrominoType.D: [Offset(0, 0), Offset(0, 1)],
    TetrominoType.U: [
      Offset(-1, 0),
      Offset(1, 0),
      Offset(-1, 1),
      Offset(0, 1),
      Offset(1, 1)
    ],
    TetrominoType.H: [
      Offset(-1, -1),
      Offset(1, -1),
      Offset(-1, 0),
      Offset(0, 0),
      Offset(1, 0),
      Offset(-1, 1),
      Offset(1, 1)
    ],
  };

  /// 生成隨機方塊
  factory Tetromino.random(int boardWidth) {
    final rand = Random();
    const types = TetrominoType.values;
    final type = types[rand.nextInt(types.length)];

    return Tetromino.fromType(type, boardWidth);
  }

  /// 根據類型創建方塊
  factory Tetromino.fromType(TetrominoType type, int boardWidth) {
    final color = typeColors[type]!;
    final shape = List<Offset>.from(initialShapes[type]!);

    // 計算起始位置
    int startX;
    int startY;

    switch (type) {
      case TetrominoType.I:
        startX = boardWidth ~/ 2;
        startY = 18; // I型在緩衝區內生成，稍微高一點
        break;
      case TetrominoType.O:
        startX = boardWidth ~/ 2;
        startY = 19; // 在緩衝區內生成
        break;
      default:
        startX = boardWidth ~/ 2;
        startY = 19; // 在緩衝區內生成
        break;
    }

    return Tetromino(
      type: type,
      color: color,
      shape: shape,
      x: startX,
      y: startY,
      rotation: 0,
    );
  }

  /// 創建副本
  Tetromino copy() {
    return Tetromino(
      type: type,
      color: color,
      shape: List<Offset>.from(shape),
      x: x,
      y: y,
      rotation: rotation,
    );
  }

  /// 更新方塊狀態
  void updateState({
    int? newX,
    int? newY,
    int? newRotation,
    List<Offset>? newShape,
  }) {
    if (newX != null) x = newX;
    if (newY != null) y = newY;
    if (newRotation != null) rotation = newRotation;
    if (newShape != null) shape = List<Offset>.from(newShape);
  }

  /// 獲取方塊在棋盤上的絕對位置
  List<Offset> getAbsolutePositions() {
    return shape
        .map((offset) => Offset(
              x + offset.dx,
              y + offset.dy,
            ))
        .toList();
  }

  /// 檢查是否為T型方塊（用於T-Spin檢測）
  bool get isT => type == TetrominoType.T;

  /// 檢查是否為I型方塊（用於特殊處理）
  bool get isI => type == TetrominoType.I;

  /// 檢查是否為O型方塊（不需旋轉）
  bool get isO => type == TetrominoType.O;

  @override
  String toString() {
    return 'Tetromino(type: $type, pos: ($x, $y), rotation: $rotation)';
  }
}
