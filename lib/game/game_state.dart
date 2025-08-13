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

  // 速度系統相關
  static const int baseSpeed = 500; // 起始速度 (毫秒)
  static const int maxSpeed = 300; // 最高速度 (毫秒)
  static const int speedIncrease = 20; // 每階段加速 (毫秒)
  static const int scorePerLevel = 1000; // 每級所需分數

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

  // 獲取當前遊戲速度 (毫秒)
  int get dropSpeed {
    int level = score ~/ scorePerLevel;
    int currentSpeed = baseSpeed - (level * speedIncrease);
    return currentSpeed < maxSpeed ? maxSpeed : currentSpeed;
  }

  // 獲取當前速度等級
  int get speedLevel {
    return (score ~/ scorePerLevel) + 1;
  }

  // 獲取下一個速度等級所需分數
  int get nextLevelScore {
    int currentLevel = score ~/ scorePerLevel;
    return (currentLevel + 1) * scorePerLevel;
  }

  // 獲取到下一個等級還需要的分數
  int get scoreToNextLevel {
    return nextLevelScore - score;
  }

  Future<void> dispose() async {
    gameTimer?.cancel();
    await audioService.dispose();
  }
}
