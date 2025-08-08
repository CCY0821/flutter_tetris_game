import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/tetromino.dart';

class GameBoard extends StatefulWidget {
  const GameBoard({super.key});

  @override
  State<GameBoard> createState() => _GameBoardState();
}

class _GameBoardState extends State<GameBoard> {
  static const int rowCount = 20;
  static const int colCount = 10;
  static const double cellSize = 20;

  late List<List<Color?>> board;
  Tetromino? currentTetromino;
  Tetromino? nextTetromino;
  Timer? gameTimer;
  int score = 0;
  bool isGameOver = false;
  bool isPaused = false;

  @override
  void initState() {
    super.initState();
    _startGame();
    RawKeyboard.instance.addListener(_handleKey);
  }

  @override
  void dispose() {
    RawKeyboard.instance.removeListener(_handleKey);
    gameTimer?.cancel();
    super.dispose();
  }

  void _startGame() {
    _initBoard();
    score = 0;
    isGameOver = false;
    isPaused = false;
    currentTetromino = Tetromino.random(colCount);
    nextTetromino = Tetromino.random(colCount);
    gameTimer?.cancel();
    gameTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (!isPaused && !isGameOver) {
        setState(() {
          _drop();
        });
      }
    });
  }

  void _initBoard() {
    board = List.generate(
      rowCount,
      (_) => List.generate(colCount, (_) => null),
    );
  }

  void _handleKey(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      final key = event.logicalKey.keyLabel.toLowerCase();

      setState(() {
        if (key == 'p' && !isGameOver) {
          isPaused = !isPaused;
        } else if (key == 'r') {
          _startGame();
        } else if (!isPaused && !isGameOver) {
          switch (key) {
            case 'arrow left':
              _moveLeft();
              break;
            case 'arrow right':
              _moveRight();
              break;
            case 'arrow down':
              _moveDown();
              break;
            case ' ':
              _rotate();
              break;
          }
        }
      });
    }
  }

  void _spawnTetromino() {
    final newTetro = nextTetromino!;
    newTetro.x = colCount ~/ 2;
    newTetro.y = 0;

    if (_canMove(newTetro)) {
      currentTetromino = newTetro;
      nextTetromino = Tetromino.random(colCount);
    } else {
      setState(() {
        isGameOver = true;
        gameTimer?.cancel();
      });
    }
  }

  bool _canMove(Tetromino tetro,
      {int dx = 0, int dy = 0, List<Offset>? overrideShape}) {
    for (final point in overrideShape ?? tetro.shape) {
      final x = tetro.x + point.dx.toInt() + dx;
      final y = tetro.y + point.dy.toInt() + dy;

      if (x < 0 || x >= colCount || y >= rowCount) return false;
      if (y >= 0 && board[y][x] != null) return false;
    }
    return true;
  }

  void _lockTetromino() {
    for (final point in currentTetromino!.shape) {
      final x = currentTetromino!.x + point.dx.toInt();
      final y = currentTetromino!.y + point.dy.toInt();
      if (x >= 0 && x < colCount && y >= 0 && y < rowCount) {
        board[y][x] = currentTetromino!.color;
      }
    }
    _clearFullRows();
  }

  void _clearFullRows() {
    List<List<Color?>> newBoard = [];
    int clearedRows = 0;

    for (int y = 0; y < board.length; y++) {
      if (board[y].every((cell) => cell != null)) {
        clearedRows++;
      } else {
        newBoard.add(board[y]);
      }
    }

    if (clearedRows > 0) {
      int base = 100;
      int bonus = (clearedRows - 1) * 50;
      score += clearedRows * base + bonus;
    }

    for (int i = 0; i < clearedRows; i++) {
      newBoard.insert(0, List.generate(colCount, (_) => null));
    }

    board = newBoard;
  }

  void _drop() {
    if (currentTetromino == null) return;

    if (_canMove(currentTetromino!, dy: 1)) {
      currentTetromino!.y++;
    } else {
      _lockTetromino();
      _spawnTetromino();
    }
  }

  void _moveLeft() {
    if (_canMove(currentTetromino!, dx: -1)) {
      currentTetromino!.x--;
    }
  }

  void _moveRight() {
    if (_canMove(currentTetromino!, dx: 1)) {
      currentTetromino!.x++;
    }
  }

  void _moveDown() {
    if (_canMove(currentTetromino!, dy: 1)) {
      currentTetromino!.y++;
    }
  }

  void _rotate() {
    final rotated =
        currentTetromino!.shape.map((p) => Offset(-p.dy, p.dx)).toList();

    if (_canMove(currentTetromino!, overrideShape: rotated)) {
      currentTetromino!.shape
        ..clear()
        ..addAll(rotated);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // 左側主遊戲區
        Stack(
          children: [
            SizedBox(
              width: colCount * cellSize,
              height: rowCount * cellSize,
              child: CustomPaint(
                painter: _BoardPainter(board, currentTetromino),
              ),
            ),

            // 暫停或 Game Over 蓋板
            if (isPaused && !isGameOver)
              _overlayText('PAUSED', Colors.amber),
            if (isGameOver) _overlayText('GAME OVER', Colors.redAccent),
          ],
        ),

        const SizedBox(width: 16),

        // 右側控制區
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoBox('Score: $score'),
            const SizedBox(height: 16),
            _infoBox('Next'),
            const SizedBox(height: 8),
            _nextBlockPreview(),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => setState(() => isPaused = !isPaused),
              child: Text(isPaused ? 'Resume (P)' : 'Pause (P)'),
            ),
            ElevatedButton(
              onPressed: _startGame,
              child: const Text('Restart (R)'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _nextBlockPreview() {
  const previewSize = 8;
  const offsetX = 2; // 中央偏移
  const offsetY = 2;

  final preview = List.generate(
    previewSize,
    (_) => List.generate(previewSize, (_) => null as Color?),
  );

  if (nextTetromino != null) {
    for (final p in nextTetromino!.shape) {
      int px = p.dx.toInt() + offsetX;
      int py = p.dy.toInt() + offsetY;
      if (py >= 0 &&
          py < previewSize &&
          px >= 0 &&
          px < previewSize) {
        preview[py][px] = nextTetromino!.color;
      }
    }
  }

  return Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: Colors.black,
      border: Border.all(color: Colors.white),
    ),
    child: Column(
      children: preview
          .map((row) => Row(
                children: row
                    .map(
                      (c) => Container(
                        width: cellSize,
                        height: cellSize,
                        margin: const EdgeInsets.all(1),
                        color: c ?? Colors.transparent,
                      ),
                    )
                    .toList(),
              ))
          .toList(),
    ),
  );
}

  Widget _infoBox(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _overlayText(String text, Color color) {
    return Positioned.fill(
      child: Container(
        color: Colors.black87,
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

class _BoardPainter extends CustomPainter {
  final List<List<Color?>> board;
  final Tetromino? tetromino;

  _BoardPainter(this.board, this.tetromino);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    const cellSize = _GameBoardState.cellSize;

    paint.color = Colors.grey[800]!;
    for (int y = 0; y <= _GameBoardState.rowCount; y++) {
      canvas.drawLine(
        Offset(0, y * cellSize),
        Offset(size.width, y * cellSize),
        paint,
      );
    }
    for (int x = 0; x <= _GameBoardState.colCount; x++) {
      canvas.drawLine(
        Offset(x * cellSize, 0),
        Offset(x * cellSize, size.height),
        paint,
      );
    }

    for (int y = 0; y < board.length; y++) {
      for (int x = 0; x < board[y].length; x++) {
        if (board[y][x] != null) {
          paint.color = board[y][x]!;
          canvas.drawRect(
            Rect.fromLTWH(x * cellSize, y * cellSize, cellSize, cellSize),
            paint,
          );
        }
      }
    }

    if (tetromino != null) {
      paint.color = tetromino!.color;
      for (final p in tetromino!.shape) {
        final x = tetromino!.x + p.dx.toInt();
        final y = tetromino!.y + p.dy.toInt();
        if (y >= 0 &&
            y < board.length &&
            x >= 0 &&
            x < board[0].length) {
          canvas.drawRect(
            Rect.fromLTWH(x * cellSize, y * cellSize, cellSize, cellSize),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
// 測試 commit 是否成功
