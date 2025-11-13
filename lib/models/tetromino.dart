import 'dart:math';
import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../game/demon_piece_generator.dart';
import '../theme/tetromino_colors.dart';

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
  /// 🔧 使用 TetrominoColors 常量確保序列化一致性
  static const Map<TetrominoType, Color> typeColors = {
    TetrominoType.I: TetrominoColors.I, // I: 霓虹青色 #00E5FF
    TetrominoType.J: TetrominoColors.J, // J: 純藍霓虹 (深邃電藍)
    TetrominoType.L: TetrominoColors.L, // L: 霓虹洋紅 #FF2ED1
    TetrominoType.O: TetrominoColors.O, // O: 賽博黃 #FCEE09
    TetrominoType.S: TetrominoColors.S, // S: 霓虹綠 (青綠電光)
    TetrominoType.T: TetrominoColors.T, // T: 電光紫 #8A2BE2
    TetrominoType.Z: TetrominoColors.Z, // Z: 霓虹紅 (洋紅偏紅)
    TetrominoType.D: TetrominoColors.D, // D: 霓虹橙 (熾熱橙光)
    TetrominoType.U: TetrominoColors.U, // U: 霓虹粉紅 (深粉紅電光)
    TetrominoType.H: TetrominoColors.H, // H: 霓虹青檸 (電光黃綠)
    TetrominoType.demon: TetrominoColors.demon, // DEMON: 金色
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
    // 惡魔方塊使用專用建構函式
    if (type == TetrominoType.demon) {
      return Tetromino.demon(boardWidth);
    }

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

  /// 創建惡魔方塊（10格隨機形狀，無法旋轉）
  factory Tetromino.demon(int boardWidth) {
    // 生成 5×5 布林矩陣
    final grid = DemonPieceGenerator.generateShape();

    // 轉換為 List<Offset> 格式
    final shape = <Offset>[];
    for (int y = 0; y < grid.length; y++) {
      for (int x = 0; x < grid[y].length; x++) {
        if (grid[y][x]) {
          // 以 (2, 2) 為中心點，轉換為相對偏移
          shape.add(Offset((x - 2).toDouble(), (y - 2).toDouble()));
        }
      }
    }

    return Tetromino(
      type: TetrominoType.demon,
      color: typeColors[TetrominoType.demon]!,
      shape: shape,
      x: boardWidth ~/ 2,
      y: 19, // 在緩衝區內生成
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

  /// 檢查是否為惡魔方塊（無法旋轉）
  bool get isDemon => type == TetrominoType.demon;

  @override
  String toString() {
    return 'Tetromino(type: $type, pos: ($x, $y), rotation: $rotation)';
  }
}
