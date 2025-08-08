import 'dart:math';
import 'package:flutter/material.dart';

class Tetromino {
  final List<Offset> shape;
  final Color color;
  int x; // 左上角在棋盤上的位置
  int y;

  Tetromino(this.shape, this.color, this.x, this.y);

  static final List<List<Offset>> shapes = [
    // I
    [Offset(0, 0), Offset(1, 0), Offset(2, 0), Offset(3, 0)],
    // O
    [Offset(0, 0), Offset(1, 0), Offset(0, 1), Offset(1, 1)],
    // T
    [Offset(0, 0), Offset(-1, 0), Offset(1, 0), Offset(0, 1)],
    // S
    [Offset(0, 0), Offset(1, 0), Offset(0, 1), Offset(-1, 1)],
    // Z
    [Offset(0, 0), Offset(-1, 0), Offset(0, 1), Offset(1, 1)],
    // L
    [Offset(0, 0), Offset(0, 1), Offset(0, 2), Offset(1, 2)],
    // J
    [Offset(0, 0), Offset(0, 1), Offset(0, 2), Offset(-1, 2)],
  ];

  static final List<Color> colors = [
    Colors.cyan,
    Colors.yellow,
    Colors.purple,
    Colors.green,
    Colors.red,
    Colors.orange,
    Colors.blue,
  ];

  factory Tetromino.random(int boardWidth) {
    final rand = Random();
    final index = rand.nextInt(shapes.length);
    final shape = shapes[index];
    final color = colors[index];
    final startX = boardWidth ~/ 2;
    return Tetromino(shape, color, startX, 0);
  }
}
