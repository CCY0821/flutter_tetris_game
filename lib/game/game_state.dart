import 'dart:async';
import 'package:flutter/material.dart';
import '../models/tetromino.dart';
import '../services/audio_service.dart';

class GameState {
  static const int rowCount = 20;
  static const int colCount = 10;

  List<List<Color?>> board = [];
  Tetromino? currentTetromino;
  Tetromino? nextTetromino;
  Timer? gameTimer;
  final AudioService audioService = AudioService();

  int score = 0;
  bool isGameOver = false;
  bool isPaused = false;

  void initBoard() {
    board = List.generate(
      rowCount,
      (_) => List.generate(colCount, (_) => null),
    );
  }

  Future<void> initializeAudio() async {
    await audioService.initialize();
  }

  Future<void> startGame() async {
    initBoard();
    score = 0;
    isGameOver = false;
    isPaused = false;
    currentTetromino = Tetromino.random(colCount);
    nextTetromino = Tetromino.random(colCount);
    
    // 不自動播放背景音樂，等待用戶互動
    // await audioService.playBackgroundMusic();
  }

  Future<void> dispose() async {
    gameTimer?.cancel();
    await audioService.dispose();
  }
}
