import 'dart:math';
import 'package:flutter/material.dart';
import '../core/constants.dart';

enum TetrominoType { I, O }

class Tetromino {
  final TetrominoType type;
  List<Point<int>> position;
  final Color color;

  Tetromino._(this.type, this.position, this.color);

  factory Tetromino.random() {
    final type = TetrominoType.values[_random.nextInt(TetrominoType.values.length)];
    switch (type) {
      case TetrominoType.I:
        return Tetromino._(
          TetrominoType.I,
          [for (var i = 0; i < 4; i++) Point(i, 0)],
          Colors.cyan,
        );
      case TetrominoType.O:
        return Tetromino._(
          TetrominoType.O,
          [Point(0, 0), Point(1, 0), Point(0, 1), Point(1, 1)],
          Colors.yellow,
        );
    }
  }

  void moveDown() {
    position = position.map((p) => Point(p.x, p.y + 1)).toList();
  }
}

final _random = Random();
