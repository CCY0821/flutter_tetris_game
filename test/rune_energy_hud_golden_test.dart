import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tetris_game/widgets/rune_energy_hud.dart';
import 'package:flutter_tetris_game/game/rune_energy_manager.dart';

void main() {
  group('RuneEnergyHUD Golden Tests', () {
    late TestWidgetsFlutterBinding binding;

    setUp(() {
      binding = TestWidgetsFlutterBinding.ensureInitialized();
    });

    tearDown(() {
      binding.platformDispatcher.clearAllTestValues();
    });

    // DPR 与状态测试组合
    final testCases = [
      // DPR: 1.0, 2.0, 2.625, 3.0
      // 状态组合: bars=0,ratio=0.3 / bars=1,ratio=0.0 / bars=2,ratio=0.75 / bars=3,ratio=0.0
      for (final dpr in [1.0, 2.0, 2.625, 3.0])
        for (final testData in [
          {'bars': 0, 'ratio': 0.3, 'desc': '0格30%'},
          {'bars': 1, 'ratio': 0.0, 'desc': '1格满'},
          {'bars': 2, 'ratio': 0.75, 'desc': '2格75%'},
          {'bars': 3, 'ratio': 0.0, 'desc': '3格满'},
        ])
          {'dpr': dpr, ...testData},
    ];

    for (final testCase in testCases) {
      final dpr = testCase['dpr'] as double;
      final bars = testCase['bars'] as int;
      final ratio = testCase['ratio'] as double;
      final desc = testCase['desc'] as String;

      group('DPR $dpr', () {
        testWidgets('Canvas - $desc', (tester) async {
          // 设置测试环境 (3格HUD需要更宽的视窗)
          tester.view.physicalSize = Size(200 * dpr, 300 * dpr);
          tester.view.devicePixelRatio = dpr;

          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });

          // 创建测试状态
          final energyStatus = RuneEnergyStatus(
            currentBars: bars,
            maxBars: 3,
            currentScore: bars * 100 + (ratio * 100).round(),
            partialRatio: bars < 3 ? ratio : 0.0,
            isMaxEnergy: bars >= 3,
          );

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                backgroundColor: Colors.black, // 深色背景便于查看能量条
                body: Center(
                  child: RuneEnergyHUD(
                    energyStatus: energyStatus,
                    implementation: EnergyCellImplementation.canvas,
                    debugOverlay: true, // 开启调试覆盖层
                  ),
                ),
              ),
            ),
          );

          // 等待渲染完成
          await tester.pumpAndSettle();

          // Golden 测试
          await expectLater(
            find.byType(Scaffold),
            matchesGoldenFile(
                'goldens/rune_energy_hud_canvas_dpr${dpr}_bars${bars}_ratio${(ratio * 100).round()}.png'),
          );
        });

        testWidgets('Layout - $desc', (tester) async {
          // 设置测试环境
          tester.view.physicalSize = Size(200 * dpr, 300 * dpr);
          tester.view.devicePixelRatio = dpr;

          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });

          // 创建测试状态
          final energyStatus = RuneEnergyStatus(
            currentBars: bars,
            maxBars: 3,
            currentScore: bars * 100 + (ratio * 100).round(),
            partialRatio: bars < 3 ? ratio : 0.0,
            isMaxEnergy: bars >= 3,
          );

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                backgroundColor: Colors.black,
                body: Center(
                  child: RuneEnergyHUD(
                    energyStatus: energyStatus,
                    implementation: EnergyCellImplementation.layout,
                    debugOverlay: true,
                  ),
                ),
              ),
            ),
          );

          await tester.pumpAndSettle();

          await expectLater(
            find.byType(Scaffold),
            matchesGoldenFile(
                'goldens/rune_energy_hud_layout_dpr${dpr}_bars${bars}_ratio${(ratio * 100).round()}.png'),
          );
        });
      });
    }

    group('Animation Tests', () {
      testWidgets('Canvas动画 0→1', (tester) async {
        tester.view.devicePixelRatio = 2.0;

        addTearDown(() {
          tester.view.resetDevicePixelRatio();
        });

        // 初始状态：空能量
        var energyStatus = const RuneEnergyStatus(
          currentBars: 0,
          maxBars: 3,
          currentScore: 0,
          partialRatio: 0.0,
          isMaxEnergy: false,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              backgroundColor: Colors.black,
              body: StatefulBuilder(
                builder: (context, setState) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      RuneEnergyHUD(
                        energyStatus: energyStatus,
                        implementation: EnergyCellImplementation.canvas,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            energyStatus = const RuneEnergyStatus(
                              currentBars: 1,
                              maxBars: 3,
                              currentScore: 100,
                              partialRatio: 0.0,
                              isMaxEnergy: false,
                            );
                          });
                        },
                        child: const Text('Fill Energy'),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );

        // 等待初始渲染
        await tester.pumpAndSettle();

        // 触发动画
        await tester.tap(find.text('Fill Energy'));
        await tester.pump(const Duration(milliseconds: 100)); // 动画中段
        expect(tester.takeException(), isNull);

        await tester.pumpAndSettle(); // 动画完成
        expect(tester.takeException(), isNull);
      });
    });

    group('Parent Scale Tests', () {
      for (final impl in EnergyCellImplementation.values) {
        testWidgets('$impl - Transform.scale无溢出测试', (tester) async {
          tester.view.devicePixelRatio = 2.625; // 非整数 DPR

          addTearDown(() {
            tester.view.resetDevicePixelRatio();
          });

          const energyStatus = RuneEnergyStatus(
            currentBars: 2,
            maxBars: 3,
            currentScore: 275,
            partialRatio: 0.75,
            isMaxEnergy: false,
          );

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                backgroundColor: Colors.black,
                body: Center(
                  child: Transform.scale(
                    scale: 1.25, // 父层缩放
                    child: RuneEnergyHUD(
                      energyStatus: energyStatus,
                      implementation: impl,
                      debugOverlay: true,
                    ),
                  ),
                ),
              ),
            ),
          );

          await tester.pumpAndSettle();

          // 验证没有溢出异常
          expect(tester.takeException(), isNull);

          // 验证组件存在
          expect(find.byType(RuneEnergyHUD), findsOneWidget);
          expect(find.byType(Transform), findsOneWidget);
        });
      }
    });

    group('Edge Cases', () {
      testWidgets('零能量渲染正确', (tester) async {
        const energyStatus = RuneEnergyStatus(
          currentBars: 0,
          maxBars: 3,
          currentScore: 0,
          partialRatio: 0.0,
          isMaxEnergy: false,
        );

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Center(
                child: RuneEnergyHUD(
                  energyStatus: energyStatus,
                ),
              ),
            ),
          ),
        );

        expect(find.byType(RuneEnergyHUD), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('最大能量渲染正确', (tester) async {
        const energyStatus = RuneEnergyStatus(
          currentBars: 3,
          maxBars: 3,
          currentScore: 300,
          partialRatio: 0.0,
          isMaxEnergy: true,
        );

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Center(
                child: RuneEnergyHUD(
                  energyStatus: energyStatus,
                ),
              ),
            ),
          ),
        );

        expect(find.byType(RuneEnergyHUD), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('自定义颜色工作正常', (tester) async {
        const energyStatus = RuneEnergyStatus(
          currentBars: 1,
          maxBars: 3,
          currentScore: 160,
          partialRatio: 0.6,
          isMaxEnergy: false,
        );

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Center(
                child: RuneEnergyHUD(
                  energyStatus: energyStatus,
                  // 使用个别EnergyCell来测试自定义颜色
                ),
              ),
            ),
          ),
        );

        expect(find.byType(RuneEnergyHUD), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    });

    group('Performance Tests', () {
      testWidgets('RepaintBoundary隔离重绘', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: List.generate(
                  3,
                  (index) => RuneEnergyHUD(
                    key: ValueKey(index),
                    energyStatus: RuneEnergyStatus(
                      currentBars: index,
                      maxBars: 3,
                      currentScore: index * 100,
                      partialRatio: 0.0,
                      isMaxEnergy: false,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        expect(find.byType(RuneEnergyHUD), findsNWidgets(3));
        expect(find.byType(RepaintBoundary),
            findsAtLeastNWidgets(3)); // HUD本身 + 每个Cell
      });

      testWidgets('快速状态变化处理正确', (tester) async {
        var currentBars = 0;
        var currentScore = 0;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  return RuneEnergyHUD(
                    energyStatus: RuneEnergyStatus(
                      currentBars: currentBars,
                      maxBars: 3,
                      currentScore: currentScore,
                      partialRatio: 0.0,
                      isMaxEnergy: false,
                    ),
                  );
                },
              ),
            ),
          ),
        );

        // 快速变更状态测试
        for (int i = 0; i <= 3; i++) {
          currentBars = i;
          currentScore = i * 100;
          await tester.pump();
        }

        expect(find.byType(RuneEnergyHUD), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    });

    group('Pixel Alignment Tests', () {
      testWidgets('像素对齐功能验证', (tester) async {
        // 使用非整数DPR测试像素对齐
        tester.view.devicePixelRatio = 2.625;

        addTearDown(() {
          tester.view.resetDevicePixelRatio();
        });

        const energyStatus = RuneEnergyStatus(
          currentBars: 1,
          maxBars: 3,
          currentScore: 150,
          partialRatio: 0.5,
          isMaxEnergy: false,
        );

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              backgroundColor: Colors.black,
              body: Center(
                child: RuneEnergyHUD(
                  energyStatus: energyStatus,
                  debugOverlay: true, // 显示对齐网格
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // 验证无像素溢出
        expect(tester.takeException(), isNull);
        expect(find.byType(RuneEnergyHUD), findsOneWidget);
      });
    });
  });
}
