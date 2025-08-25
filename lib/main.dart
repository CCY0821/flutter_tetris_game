import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'game/game_board.dart';
import 'theme/game_theme.dart';
import 'core/constants.dart';
import 'widgets/scanline_overlay.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 設置系統UI樣式
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.resumed:
        // 應用從背景恢復時，確保遊戲狀態正確
        debugPrint('App resumed - ensuring game state consistency');
        break;
      case AppLifecycleState.paused:
        // 應用進入背景時，自動暫停遊戲
        debugPrint('App paused - game should auto-pause');
        break;
      case AppLifecycleState.detached:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Tetris Game',
      theme: ThemeData(
        // 🌃 Cyberpunk 全域主題設定
        scaffoldBackgroundColor: cyberpunkBgDeep,
        cardColor: cyberpunkPanel,
        // 設定 ElevatedButton 全域樣式
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: GameTheme.primaryButtonStyle,
        ),
        // 設定 OutlinedButton 全域樣式
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: cyberpunkPrimary,
            side: BorderSide(
              color: cyberpunkPrimary,
              width: cyberpunkBorderWidth,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(cyberpunkBorderRadius),
            ),
          ).copyWith(
            overlayColor: WidgetStateProperty.resolveWith<Color?>((states) {
              if (states.contains(WidgetState.hovered))
                return cyberpunkPrimary.withOpacity(0.1);
              if (states.contains(WidgetState.pressed))
                return cyberpunkPrimary.withOpacity(0.2);
              return null;
            }),
          ),
        ),
      ),
      home: Scaffold(
        backgroundColor: cyberpunkBgDeep, // Scaffold 背景設為深層背景
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
                              borderRadius: BorderRadius.circular(
                                  cyberpunkBorderRadiusLarge),
                              border: Border.all(
                                color: GameTheme.textAccent.withOpacity(0.3),
                                width: cyberpunkBorderWidthBold,
                              ),
                              boxShadow: cyberpunkPrimaryGlow,
                            ),
                            child: Text(
                              'TETRIS',
                              style: GameTheme.titleStyle.copyWith(
                                fontSize: 36,
                                letterSpacing: 4,
                                color: cyberpunkPrimary, // 霓虹青色標題
                                shadows: [
                                  Shadow(
                                    color: cyberpunkPrimary.withOpacity(0.5),
                                    blurRadius: cyberpunkGlowMed,
                                    offset: const Offset(2, 2),
                                  ),
                                  Shadow(
                                    color: cyberpunkSecondary.withOpacity(0.3),
                                    blurRadius: cyberpunkGlowStrong,
                                    offset: const Offset(0, 0),
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

              // 🖥️ 全畫面掃描線疊層 (最上層，不影響事件)
              const ScanlineOverlay(),
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
      ..color = cyberpunkGridLine.withOpacity(0.08) // 使用 Cyberpunk 網格線
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

    // 繪製裝飾性的霓虹點
    paint.color = cyberpunkPrimary.withOpacity(0.05);
    for (double x = spacing / 2; x < size.width; x += spacing * 2) {
      for (double y = spacing / 2; y < size.height; y += spacing * 2) {
        canvas.drawCircle(Offset(x, y), 2, paint);
      }
    }

    // 繪製一些隨機的霓虹洋紅點作為裝飾
    paint.color = cyberpunkSecondary.withOpacity(0.03);
    for (double x = spacing; x < size.width; x += spacing * 3) {
      for (double y = spacing; y < size.height; y += spacing * 3) {
        canvas.drawCircle(Offset(x, y), 1.5, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
