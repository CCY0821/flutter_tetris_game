import 'package:flutter/material.dart';
import 'game/shaders/chroma_key_image.dart';

/// Test page to verify chroma key (green screen) removal on angels_grace.png
class TestChromaKeyPage extends StatefulWidget {
  const TestChromaKeyPage({Key? key}) : super(key: key);

  @override
  State<TestChromaKeyPage> createState() => _TestChromaKeyPageState();
}

class _TestChromaKeyPageState extends State<TestChromaKeyPage> {
  double _tolerance = 0.15;
  double _feather = 0.3;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Chroma Key Test - Angel\'s Grace'),
        backgroundColor: Colors.grey[900],
      ),
      body: Column(
        children: [
          // Control Panel
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[900],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tolerance: ${_tolerance.toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.white),
                ),
                Slider(
                  value: _tolerance,
                  min: 0.0,
                  max: 0.5,
                  divisions: 50,
                  onChanged: (value) => setState(() => _tolerance = value),
                ),
                const SizedBox(height: 8),
                Text(
                  'Feather: ${_feather.toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.white),
                ),
                Slider(
                  value: _feather,
                  min: 0.0,
                  max: 1.0,
                  divisions: 20,
                  onChanged: (value) => setState(() => _feather = value),
                ),
              ],
            ),
          ),

          // Image Display Area
          Expanded(
            child: Stack(
              children: [
                // Checkerboard background
                const CustomPaint(
                  painter: _CheckerboardPainter(),
                  size: Size.infinite,
                ),
                // Content
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Original Image
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Original (with green background)',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            Image.asset(
                              'assets/animations/angels_grace.png',
                              width: 300,
                              height: 300,
                              fit: BoxFit.contain,
                            ),
                          ],
                        ),
                      ),

                      const Divider(color: Colors.white),

                      // Chroma Keyed Image
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Chroma Keyed (green removed)',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            ChromaKeyImage(
                              assetPath: 'assets/animations/angels_grace.png',
                              width: 300,
                              height: 300,
                              tolerance: _tolerance,
                              feather: _feather,
                              fit: BoxFit.contain,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Info Panel
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[900],
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Instructions:',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '• Tolerance: How closely colors must match #00FF00 to be removed',
                  style: TextStyle(color: Colors.white70),
                ),
                Text(
                  '• Feather: Smoothness of edges (0=hard cut, 1=very soft)',
                  style: TextStyle(color: Colors.white70),
                ),
                Text(
                  '• Background checkerboard shows transparency',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for checkerboard background
class _CheckerboardPainter extends CustomPainter {
  const _CheckerboardPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const squareSize = 20.0;
    final paint1 = Paint()..color = Colors.grey[800]!;
    final paint2 = Paint()..color = Colors.grey[700]!;

    for (double y = 0; y < size.height; y += squareSize) {
      for (double x = 0; x < size.width; x += squareSize) {
        final isEven = ((x ~/ squareSize) + (y ~/ squareSize)) % 2 == 0;
        canvas.drawRect(
          Rect.fromLTWH(x, y, squareSize, squareSize),
          isEven ? paint1 : paint2,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_CheckerboardPainter oldDelegate) => false;
}
