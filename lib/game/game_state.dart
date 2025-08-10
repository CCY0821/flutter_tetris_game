import 'dart:async';
import 'package:flutter/material.dart';
import '../models/tetromino.dart';

class GameState {
  static const int rowCount = 20;
  static const int colCount = 10;

  late List<List<Color?>> board;
  Tetromino? currentTetromino;
  Tetromino? nextTetromino;
  Timer? gameTimer;

  int score = 0;
  bool isGameOver = false;
  bool isPaused = false;

  void initBoard() {
    board = List.generate(
      rowCount,
      (_) => List.generate(colCount, (_) => null),
    );
  }

  void startGame() {
    initBoard();
    score = 0;
    isGameOver = false;
    isPaused = false;
    currentTetromino = Tetromino.random(colCount);
    nextTetromino = Tetromino.random(colCount);
  }

  void dispose() {
    gameTimer?.cancel();
  }
}
