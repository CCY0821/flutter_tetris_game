import 'package:flutter/material.dart';

/// Tetromino 顏色定義和序列化映射
///
/// 此類統一管理方塊顏色的定義和序列化/反序列化映射
/// 避免在多個檔案中重複定義顏色值
class TetrominoColors {
  /// I 型方塊 - 霓虹青色 (Cyberpunk Primary)
  static const Color I = Color(0xFF00E5FF);

  /// J 型方塊 - 純藍霓虹 (深邃電藍)
  static const Color J = Color(0xFF0066FF);

  /// L 型方塊 - 霓虹洋紅 (Cyberpunk Secondary)
  static const Color L = Color(0xFFFF2ED1);

  /// O 型方塊 - 賽博黃 (Cyberpunk Caution)
  static const Color O = Color(0xFFFCEE09);

  /// S 型方塊 - 霓虹綠 (青綠電光)
  static const Color S = Color(0xFF00FF88);

  /// T 型方塊 - 電光紫 (Cyberpunk Accent)
  static const Color T = Color(0xFF8A2BE2);

  /// Z 型方塊 - 霓虹紅 (洋紅偏紅)
  static const Color Z = Color(0xFFFF0066);

  /// D 型方塊 - 霓虹橙 (熾熱橙光)
  static const Color D = Color(0xFFFF6600);

  /// U 型方塊 - 霓虹粉紅 (深粉紅電光)
  static const Color U = Color(0xFFFF1493);

  /// H 型方塊 - 霓虹青檸 (電光黃綠)
  static const Color H = Color(0xFFCCFF00);

  /// 惡魔方塊 - 金色
  static const Color demon = Color(0xFFFFD700);

  /// 顏色到整數的映射表 (用於序列化)
  static final Map<Color, int> colorToInt = {
    I: 1,
    J: 2,
    L: 3,
    O: 4,
    S: 5,
    T: 6,
    Z: 7,
    D: 8,
    U: 9,
    H: 10,
    demon: 11,
  };

  /// 整數到顏色的映射表 (用於反序列化)
  static const Map<int, Color> intToColor = {
    1: I,
    2: J,
    3: L,
    4: O,
    5: S,
    6: T,
    7: Z,
    8: D,
    9: U,
    10: H,
    11: demon,
  };
}
