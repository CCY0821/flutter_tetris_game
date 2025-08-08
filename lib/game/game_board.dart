import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../models/tetromino.dart';

class GameBoard extends StatefulWidget {
  const GameBoard({super.key});

  @override
  State<GameBoard> createState() => _GameBoardState();
}

class _GameBoardState extends State<GameBoard> {
  Tetromino? currentBlock;
  Timer? gameTimer;

  @override
  void initState() {
    super.initState();
    spawnNewBlock();
    startGameLoop();
  }

  void spawnNewBlock() {
    setState(() {
      currentBlock = Tetromino.random();
    });
  }

  void startGameLoop() {
    gameTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (currentBlock == null) return;
      setState(() {
        currentBlock!.moveDown();
      });
    });
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: boardWidth * blockSize,
        height: boardHeight * blockSize,
        color: Colors.blueGrey[900],
        child: CustomPaint(
          painter: _BoardPainter(currentBlock),
        ),
      ),
    );
  }
}

class _BoardPainter extends CustomPainter {
  final Tetromino? block;

  _BoardPainter(this.block);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[700]!
      ..style = PaintingStyle.stroke;

    // 畫格線
    for (int y = 0; y < boardHeight; y++) {
      for (int x = 0; x < boardWidth; x++) {
        final rect = Rect.fromLTWH(
          x * blockSize,
          y * blockSize,
          blockSize,
          blockSize,
        );
        canvas.drawRect(rect, paint);
      }
    }

    // 畫方塊
    if (block != null) {
      final blockPaint = Paint()
        ..color = block!.color
        ..style = PaintingStyle.fill;

      for (var p in block!.position) {
        canvas.drawRect(
          Rect.fromLTWH(p.x * blockSize, p.y * blockSize, blockSize, blockSize),
          blockPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BoardPainter oldDelegate) => true;
}
