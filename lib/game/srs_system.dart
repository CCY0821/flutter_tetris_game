import 'package:flutter/material.dart';
import '../models/tetromino.dart';
import 'game_state.dart';

/// Super Rotation System (SRS) 實作
/// 提供智能旋轉與壁踢功能
class SRSSystem {
  /// SRS 旋轉狀態定義
  static const int rotationNorth = 0;
  static const int rotationEast = 1;
  static const int rotationSouth = 2;
  static const int rotationWest = 3;

  /// 壁踢偏移表 - I 型方塊專用
  static const Map<String, List<Offset>> _iKickTable = {
    '0->1': [
      Offset(0, 0),
      Offset(-2, 0),
      Offset(1, 0),
      Offset(-2, -1),
      Offset(1, 2)
    ],
    '1->0': [
      Offset(0, 0),
      Offset(2, 0),
      Offset(-1, 0),
      Offset(2, 1),
      Offset(-1, -2)
    ],
    '1->2': [
      Offset(0, 0),
      Offset(-1, 0),
      Offset(2, 0),
      Offset(-1, 2),
      Offset(2, -1)
    ],
    '2->1': [
      Offset(0, 0),
      Offset(1, 0),
      Offset(-2, 0),
      Offset(1, -2),
      Offset(-2, 1)
    ],
    '2->3': [
      Offset(0, 0),
      Offset(2, 0),
      Offset(-1, 0),
      Offset(2, 1),
      Offset(-1, -2)
    ],
    '3->2': [
      Offset(0, 0),
      Offset(-2, 0),
      Offset(1, 0),
      Offset(-2, -1),
      Offset(1, 2)
    ],
    '3->0': [
      Offset(0, 0),
      Offset(1, 0),
      Offset(-2, 0),
      Offset(1, -2),
      Offset(-2, 1)
    ],
    '0->3': [
      Offset(0, 0),
      Offset(-1, 0),
      Offset(2, 0),
      Offset(-1, 2),
      Offset(2, -1)
    ],
  };

  /// 壁踢偏移表 - JLSTZ 型方塊通用
  static const Map<String, List<Offset>> _jlstzKickTable = {
    '0->1': [
      Offset(0, 0),
      Offset(-1, 0),
      Offset(-1, 1),
      Offset(0, -2),
      Offset(-1, -2)
    ],
    '1->0': [
      Offset(0, 0),
      Offset(1, 0),
      Offset(1, -1),
      Offset(0, 2),
      Offset(1, 2)
    ],
    '1->2': [
      Offset(0, 0),
      Offset(1, 0),
      Offset(1, -1),
      Offset(0, 2),
      Offset(1, 2)
    ],
    '2->1': [
      Offset(0, 0),
      Offset(-1, 0),
      Offset(-1, 1),
      Offset(0, -2),
      Offset(-1, -2)
    ],
    '2->3': [
      Offset(0, 0),
      Offset(1, 0),
      Offset(1, 1),
      Offset(0, -2),
      Offset(1, -2)
    ],
    '3->2': [
      Offset(0, 0),
      Offset(-1, 0),
      Offset(-1, -1),
      Offset(0, 2),
      Offset(-1, 2)
    ],
    '3->0': [
      Offset(0, 0),
      Offset(-1, 0),
      Offset(-1, -1),
      Offset(0, 2),
      Offset(-1, 2)
    ],
    '0->3': [
      Offset(0, 0),
      Offset(1, 0),
      Offset(1, 1),
      Offset(0, -2),
      Offset(1, -2)
    ],
  };

  /// 方塊旋轉形狀定義 - I 型方塊
  static const Map<int, List<Offset>> _iShapes = {
    0: [Offset(-1, 0), Offset(0, 0), Offset(1, 0), Offset(2, 0)], // 水平
    1: [Offset(1, -1), Offset(1, 0), Offset(1, 1), Offset(1, 2)], // 垂直
    2: [Offset(-1, 1), Offset(0, 1), Offset(1, 1), Offset(2, 1)], // 水平（上移）
    3: [Offset(0, -1), Offset(0, 0), Offset(0, 1), Offset(0, 2)], // 垂直（左移）
  };

  /// 方塊旋轉形狀定義 - T 型方塊
  static const Map<int, List<Offset>> _tShapes = {
    0: [Offset(-1, 0), Offset(0, 0), Offset(1, 0), Offset(0, 1)], // ⊥
    1: [Offset(0, -1), Offset(0, 0), Offset(1, 0), Offset(0, 1)], // ⊢
    2: [Offset(0, -1), Offset(-1, 0), Offset(0, 0), Offset(1, 0)], // ⊤
    3: [Offset(0, -1), Offset(-1, 0), Offset(0, 0), Offset(0, 1)], // ⊣
  };

  /// 方塊旋轉形狀定義 - J 型方塊
  static const Map<int, List<Offset>> _jShapes = {
    0: [Offset(-1, 0), Offset(0, 0), Offset(1, 0), Offset(-1, 1)],
    1: [Offset(0, -1), Offset(0, 0), Offset(0, 1), Offset(1, -1)],
    2: [Offset(-1, 0), Offset(0, 0), Offset(1, 0), Offset(1, -1)],
    3: [Offset(-1, 1), Offset(0, -1), Offset(0, 0), Offset(0, 1)],
  };

  /// 方塊旋轉形狀定義 - L 型方塊
  static const Map<int, List<Offset>> _lShapes = {
    0: [Offset(-1, 0), Offset(0, 0), Offset(1, 0), Offset(1, 1)],
    1: [Offset(0, -1), Offset(0, 0), Offset(0, 1), Offset(1, 1)],
    2: [Offset(-1, -1), Offset(-1, 0), Offset(0, 0), Offset(1, 0)],
    3: [Offset(-1, -1), Offset(0, -1), Offset(0, 0), Offset(0, 1)],
  };

  /// 方塊旋轉形狀定義 - S 型方塊
  static const Map<int, List<Offset>> _sShapes = {
    0: [Offset(-1, 0), Offset(0, 0), Offset(0, 1), Offset(1, 1)],
    1: [Offset(0, 0), Offset(0, 1), Offset(1, -1), Offset(1, 0)],
    2: [Offset(-1, -1), Offset(0, -1), Offset(0, 0), Offset(1, 0)],
    3: [Offset(-1, 0), Offset(-1, 1), Offset(0, -1), Offset(0, 0)],
  };

  /// 方塊旋轉形狀定義 - Z 型方塊
  static const Map<int, List<Offset>> _zShapes = {
    0: [Offset(-1, 1), Offset(0, 1), Offset(0, 0), Offset(1, 0)],
    1: [Offset(0, -1), Offset(0, 0), Offset(1, 0), Offset(1, 1)],
    2: [Offset(-1, 0), Offset(0, 0), Offset(0, -1), Offset(1, -1)],
    3: [Offset(-1, -1), Offset(-1, 0), Offset(0, 0), Offset(0, 1)],
  };

  /// 方塊旋轉形狀定義 - O 型方塊（不旋轉）
  static const Map<int, List<Offset>> _oShapes = {
    0: [Offset(0, 0), Offset(1, 0), Offset(0, 1), Offset(1, 1)],
    1: [Offset(0, 0), Offset(1, 0), Offset(0, 1), Offset(1, 1)],
    2: [Offset(0, 0), Offset(1, 0), Offset(0, 1), Offset(1, 1)],
    3: [Offset(0, 0), Offset(1, 0), Offset(0, 1), Offset(1, 1)],
  };

  /// 方塊旋轉形狀定義 - D 型方塊（Domino 雙格）
  static const Map<int, List<Offset>> _dShapes = {
    0: [Offset(0, 0), Offset(0, 1)], // 垂直
    1: [Offset(0, 0), Offset(1, 0)], // 水平
    2: [Offset(0, 0), Offset(0, 1)], // 垂直
    3: [Offset(0, 0), Offset(1, 0)], // 水平
  };

  /// 方塊旋轉形狀定義 - U 型方塊（五格 U 型）
  static const Map<int, List<Offset>> _uShapes = {
    0: [
      Offset(-1, 0),
      Offset(1, 0),
      Offset(-1, 1),
      Offset(0, 1),
      Offset(1, 1)
    ], // 北：開口向上
    1: [
      Offset(0, -1),
      Offset(1, -1),
      Offset(0, 0),
      Offset(0, 1),
      Offset(1, 1)
    ], // 東：開口向右
    2: [
      Offset(-1, -1),
      Offset(0, -1),
      Offset(1, -1),
      Offset(-1, 0),
      Offset(1, 0)
    ], // 南：開口向下
    3: [
      Offset(-1, -1),
      Offset(0, -1),
      Offset(0, 0),
      Offset(-1, 1),
      Offset(0, 1)
    ], // 西：開口向左
  };

  /// 獲取方塊在指定旋轉狀態下的形狀
  static List<Offset> getShapeForRotation(TetrominoType type, int rotation) {
    switch (type) {
      case TetrominoType.I:
        return _iShapes[rotation] ?? _iShapes[0]!;
      case TetrominoType.T:
        return _tShapes[rotation] ?? _tShapes[0]!;
      case TetrominoType.J:
        return _jShapes[rotation] ?? _jShapes[0]!;
      case TetrominoType.L:
        return _lShapes[rotation] ?? _lShapes[0]!;
      case TetrominoType.S:
        return _sShapes[rotation] ?? _sShapes[0]!;
      case TetrominoType.Z:
        return _zShapes[rotation] ?? _zShapes[0]!;
      case TetrominoType.O:
        return _oShapes[rotation] ?? _oShapes[0]!;
      case TetrominoType.D:
        return _dShapes[rotation] ?? _dShapes[0]!;
      case TetrominoType.U:
        return _uShapes[rotation] ?? _uShapes[0]!;
    }
  }

  /// 獲取壁踢偏移表
  static List<Offset> getKickOffsets(
      TetrominoType type, int fromRotation, int toRotation) {
    final key = '$fromRotation->$toRotation';

    if (type == TetrominoType.I) {
      return _iKickTable[key] ?? [Offset.zero];
    } else if (type == TetrominoType.O) {
      // O 型方塊不需要壁踢
      return [Offset.zero];
    } else {
      // JLSTZ 型方塊使用通用表
      return _jlstzKickTable[key] ?? [Offset.zero];
    }
  }

  /// 檢查方塊在指定位置是否可以放置
  static bool canPlacePiece(
    List<List<Color?>> board,
    List<Offset> shape,
    int x,
    int y,
  ) {
    for (final offset in shape) {
      final newX = x + offset.dx.toInt();
      final newY = y + offset.dy.toInt();

      // 檢查邊界
      if (newX < 0 ||
          newX >= GameState.colCount ||
          newY >= GameState.totalRowCount) {
        return false;
      }

      // 檢查是否與已存在的方塊碰撞（允許在頂部邊界上方）
      if (newY >= 0 && board[newY][newX] != null) {
        return false;
      }
    }
    return true;
  }

  /// 嘗試SRS旋轉
  static SRSRotationResult attemptRotation(
    Tetromino currentPiece,
    List<List<Color?>> board,
    bool clockwise,
  ) {
    // O 型方塊不需要旋轉
    if (currentPiece.type == TetrominoType.O) {
      return SRSRotationResult(
        success: true,
        newX: currentPiece.x,
        newY: currentPiece.y,
        newRotation: currentPiece.rotation,
        newShape: currentPiece.shape,
        kickUsed: 0,
      );
    }

    final currentRotation = currentPiece.rotation;
    final targetRotation =
        clockwise ? (currentRotation + 1) % 4 : (currentRotation - 1 + 4) % 4;

    // 獲取目標旋轉狀態的形狀
    final targetShape = getShapeForRotation(currentPiece.type, targetRotation);

    // 獲取壁踢偏移表
    final kickOffsets =
        getKickOffsets(currentPiece.type, currentRotation, targetRotation);

    // 嘗試每個壁踢偏移
    for (int i = 0; i < kickOffsets.length; i++) {
      final offset = kickOffsets[i];
      final newX = currentPiece.x + offset.dx.toInt();
      final newY = currentPiece.y + offset.dy.toInt();

      if (canPlacePiece(board, targetShape, newX, newY)) {
        return SRSRotationResult(
          success: true,
          newX: newX,
          newY: newY,
          newRotation: targetRotation,
          newShape: targetShape,
          kickUsed: i,
        );
      }
    }

    // 所有壁踢嘗試都失敗
    return SRSRotationResult(
      success: false,
      newX: currentPiece.x,
      newY: currentPiece.y,
      newRotation: currentRotation,
      newShape: currentPiece.shape,
      kickUsed: -1,
    );
  }
}

/// SRS 旋轉結果
class SRSRotationResult {
  final bool success;
  final int newX;
  final int newY;
  final int newRotation;
  final List<Offset> newShape;
  final int kickUsed; // 使用的壁踢索引，-1表示失敗，0表示無需壁踢

  const SRSRotationResult({
    required this.success,
    required this.newX,
    required this.newY,
    required this.newRotation,
    required this.newShape,
    required this.kickUsed,
  });

  /// 是否使用了壁踢
  bool get usedWallKick => kickUsed > 0;

  /// 獲取壁踢類型描述
  String get kickDescription {
    if (kickUsed <= 0) return 'None';
    switch (kickUsed) {
      case 1:
        return 'Side Wall Kick';
      case 2:
        return 'Opposite Side Wall Kick';
      case 3:
        return 'Floor Kick';
      case 4:
        return 'Well Kick';
      default:
        return 'Wall Kick $kickUsed';
    }
  }
}
