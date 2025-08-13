import 'package:flutter/material.dart';
import 'game/game_board.dart';
import 'theme/game_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Tetris Game',
      home: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: GameTheme.backgroundGradient,
          ),
          child: Stack(
            children: [
              // 背景裝飾
              Positioned.fill(
                child: CustomPaint(
                  painter: BackgroundPatternPainter(),
                ),
              ),

              // 主遊戲內容
              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // 遊戲標題
                          Container(
                            margin: const EdgeInsets.only(bottom: 24),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  GameTheme.highlight.withOpacity(0.1),
                                  GameTheme.brightAccent.withOpacity(0.1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: GameTheme.textAccent.withOpacity(0.3),
                                width: 2,
                              ),
                            ),
                            child: Text(
                              'TETRIS',
                              style: GameTheme.titleStyle.copyWith(
                                fontSize: 36,
                                letterSpacing: 4,
                                shadows: [
                                  Shadow(
                                    color: GameTheme.highlight.withOpacity(0.5),
                                    blurRadius: 8,
                                    offset: const Offset(2, 2),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // 遊戲板
                          const GameBoard(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BackgroundPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = GameTheme.gridLine.withOpacity(0.05)
      ..strokeWidth = 1;

    // 繪製網格背景圖案
    const spacing = 40.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }

    // 繪製裝飾性的點
    paint.color = GameTheme.textAccent.withOpacity(0.03);
    for (double x = spacing / 2; x < size.width; x += spacing * 2) {
      for (double y = spacing / 2; y < size.height; y += spacing * 2) {
        canvas.drawCircle(Offset(x, y), 2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
