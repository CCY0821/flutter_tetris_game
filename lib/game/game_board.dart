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
  Timer? gameTimer;

  @override
  void initState() {
    super.initState();
    _initBoard();
    _spawnTetromino();

    RawKeyboard.instance.addListener(_handleKey);

    gameTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      setState(() {
        _drop();
      });
    });
  }

  @override
  void dispose() {
    RawKeyboard.instance.removeListener(_handleKey);
    gameTimer?.cancel();
    super.dispose();
  }

  void _handleKey(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      final key = event.logicalKey.keyLabel;
      setState(() {
        switch (key) {
          case 'Arrow Left':
            _moveLeft();
            break;
          case 'Arrow Right':
            _moveRight();
            break;
          case 'Arrow Down':
            _moveDown();
            break;
          case ' ':
            _rotate();
            break;
        }
      });
    }
  }

  void _initBoard() {
    board = List.generate(
      rowCount,
      (_) => List.generate(colCount, (_) => null),
    );
  }

  void _spawnTetromino() {
    currentTetromino = Tetromino.random(colCount);
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

  /// 清除所有填滿的行，並將上方下移
  void _clearFullRows() {
    setState(() {
      board.removeWhere((row) => row.every((cell) => cell != null));
      int removed = rowCount - board.length;
      for (int i = 0; i < removed; i++) {
        board.insert(0, List.generate(colCount, (_) => null));
      }
    });
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
    final rotatedShape =
        currentTetromino!.shape.map((p) => Offset(-p.dy, p.dx)).toList();

    if (_canMove(currentTetromino!, overrideShape: rotatedShape)) {
      currentTetromino!.shape
        ..clear()
        ..addAll(rotatedShape);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: colCount * cellSize,
      height: rowCount * cellSize,
      child: CustomPaint(
        painter: _BoardPainter(board, currentTetromino),
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

    // 畫格線
    paint.color = Colors.grey[800]!;
    for (int y = 0; y <= _GameBoardState.rowCount; y++) {
      canvas.drawLine(
          Offset(0, y * cellSize), Offset(size.width, y * cellSize), paint);
    }
    for (int x = 0; x <= _GameBoardState.colCount; x++) {
      canvas.drawLine(
          Offset(x * cellSize, 0), Offset(x * cellSize, size.height), paint);
    }

    // 畫鎖定的方塊
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

    // 畫目前方塊
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
