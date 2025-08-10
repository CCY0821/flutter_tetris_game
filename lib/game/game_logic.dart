import 'package:flutter/material.dart';
import '../models/tetromino.dart';
import 'game_state.dart';

class GameLogic {
  final GameState gameState;

  GameLogic(this.gameState);

  bool canMove(Tetromino tetro,
      {int dx = 0, int dy = 0, List<Offset>? overrideShape}) {
    for (final point in overrideShape ?? tetro.shape) {
      final x = tetro.x + point.dx.toInt() + dx;
      final y = tetro.y + point.dy.toInt() + dy;

      if (x < 0 || x >= GameState.colCount || y >= GameState.rowCount) {
        return false;
      }
      if (y >= 0 && gameState.board[y][x] != null) return false;
    }
    return true;
  }

  void lockTetromino() {
    for (final point in gameState.currentTetromino!.shape) {
      final x = gameState.currentTetromino!.x + point.dx.toInt();
      final y = gameState.currentTetromino!.y + point.dy.toInt();
      if (x >= 0 &&
          x < GameState.colCount &&
          y >= 0 &&
          y < GameState.rowCount) {
        gameState.board[y][x] = gameState.currentTetromino!.color;
      }
    }
    clearFullRows();
  }

  void clearFullRows() {
    List<List<Color?>> newBoard = [];
    int clearedRows = 0;

    for (int y = 0; y < gameState.board.length; y++) {
      if (gameState.board[y].every((cell) => cell != null)) {
        clearedRows++;
      } else {
        newBoard.add(gameState.board[y]);
      }
    }

    if (clearedRows > 0) {
      int base = 100;
      int bonus = (clearedRows - 1) * 50;
      gameState.score += clearedRows * base + bonus;
      
      // 播放消除音效
      gameState.audioService.playSoundEffect('line_clear');
    }

    for (int i = 0; i < clearedRows; i++) {
      newBoard.insert(0, List.generate(GameState.colCount, (_) => null));
    }

    gameState.board = newBoard;
  }

  void drop() {
    if (gameState.currentTetromino == null) return;

    if (canMove(gameState.currentTetromino!, dy: 1)) {
      gameState.currentTetromino!.y++;
    } else {
      // 播放方塊落地音效
      gameState.audioService.playSoundEffect('piece_drop');
      lockTetromino();
      spawnTetromino();
    }
  }

  void spawnTetromino() {
    final newTetro = gameState.nextTetromino!;
    newTetro.x = GameState.colCount ~/ 2;
    newTetro.y = 0;

    if (canMove(newTetro)) {
      gameState.currentTetromino = newTetro;
      gameState.nextTetromino = Tetromino.random(GameState.colCount);
    } else {
      gameState.isGameOver = true;
      // 播放遊戲結束音效
      gameState.audioService.playSoundEffect('game_over');
      // 停止背景音樂
      gameState.audioService.stopBackgroundMusic();
    }
  }

  void moveLeft() {
    if (canMove(gameState.currentTetromino!, dx: -1)) {
      gameState.currentTetromino!.x--;
    }
  }

  void moveRight() {
    if (canMove(gameState.currentTetromino!, dx: 1)) {
      gameState.currentTetromino!.x++;
    }
  }

  void moveDown() {
    if (canMove(gameState.currentTetromino!, dy: 1)) {
      gameState.currentTetromino!.y++;
    }
  }

  void rotate() {
    final rotated = gameState.currentTetromino!.shape
        .map((p) => Offset(-p.dy, p.dx))
        .toList();

    if (canMove(gameState.currentTetromino!, overrideShape: rotated)) {
      gameState.currentTetromino!.shape
        ..clear()
        ..addAll(rotated);
      // 播放旋轉音效
      gameState.audioService.playSoundEffect('piece_rotate');
    }
  }
}
