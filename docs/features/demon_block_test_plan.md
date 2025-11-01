# 惡魔方塊系統 - 詳細測試方案

**版本**: 1.0
**日期**: 2025-11-01
**目的**: 為每個子任務提供具體、可執行的測試方案

---

## 📋 測試方案總覽

| 測試類型 | 數量 | 工具 |
|---------|------|------|
| 單元測試 | 15 個 | `flutter test` |
| 整合測試 | 8 個 | `flutter test integration_test/` |
| 手動測試 | 12 個 | 視覺確認 + 性能監控 |
| 性能測試 | 5 個 | Flutter DevTools |

---

## 🚀 階段 1：核心數據結構測試方案

### 1.1 新增 DEMON 枚舉與顏色定義

#### 測試方案
```dart
// test/tetromino_definitions_test.dart

test('DEMON 枚舉值存在', () {
  expect(TetrominoType.values.contains(TetrominoType.DEMON), true);
});

test('DEMON 顏色定義存在且為金色', () {
  final color = TetrominoColors.getColor(TetrominoType.DEMON);
  expect(color, isNotNull);
  expect(color.value, 0xFFFFD700); // 金色
});

test('DEMON 在所有方塊類型 Map 中註冊', () {
  final allTypes = TetrominoType.values;
  for (var type in allTypes) {
    expect(TetrominoColors.getColor(type), isNotNull);
  }
});
```

#### 驗收標準
- ✅ 枚舉值 `TetrominoType.DEMON` 存在
- ✅ `TetrominoColors.getColor(TetrominoType.DEMON)` 返回 `Color(0xFFFFD700)`
- ✅ 編譯無錯誤，無 lint 警告

#### 執行方式
```bash
flutter test test/tetromino_definitions_test.dart
```

---

### 1.2 建立 DemonPieceGenerator 基礎架構

#### 測試方案
```dart
// test/demon_piece_generator_test.dart

test('generateShape 返回非空 List<List<bool>>', () {
  final shape = DemonPieceGenerator.generateShape();
  expect(shape, isNotNull);
  expect(shape.length, greaterThan(0));
  expect(shape[0].length, greaterThan(0));
});

test('生成的方塊格數接近 10（±2）', () {
  final shape = DemonPieceGenerator.generateShape();
  int count = 0;
  for (var row in shape) {
    for (var cell in row) {
      if (cell) count++;
    }
  }
  expect(count, inInclusiveRange(8, 12)); // 允許些許誤差
});

test('生成的方塊在 5×5 範圍內', () {
  final shape = DemonPieceGenerator.generateShape();
  expect(shape.length, lessThanOrEqualTo(5));
  expect(shape[0].length, lessThanOrEqualTo(5));
});

test('連續生成 10 次無拋出異常', () {
  for (int i = 0; i < 10; i++) {
    expect(() => DemonPieceGenerator.generateShape(), returnsNormally);
  }
});
```

#### 驗收標準
- ✅ 生成的方塊非空
- ✅ 格數在 8-12 範圍內
- ✅ 尺寸不超過 5×5
- ✅ 連續生成 10 次無異常

#### 執行方式
```bash
flutter test test/demon_piece_generator_test.dart
```

---

### 1.3 實現驗證機制

#### 測試方案
```dart
// test/demon_piece_generator_validation_test.dart

test('_isConnected 正確驗證連通方塊', () {
  final connectedShape = [
    [true, true, false],
    [false, true, true],
  ];
  expect(DemonPieceGenerator.testIsConnected(connectedShape), true);
});

test('_isConnected 正確拒絕分離方塊', () {
  final disconnectedShape = [
    [true, false, true],
    [false, false, false],
  ];
  expect(DemonPieceGenerator.testIsConnected(disconnectedShape), false);
});

test('_canBePlacedOnEmptyBoard 拒絕超寬方塊', () {
  final tooWideShape = List.generate(2, (_) => List.filled(11, true));
  expect(DemonPieceGenerator.testCanBePlaced(tooWideShape), false);
});

test('_canBePlacedOnEmptyBoard 接受正常寬度', () {
  final normalShape = List.generate(3, (_) => List.filled(5, true));
  expect(DemonPieceGenerator.testCanBePlaced(normalShape), true);
});

test('生成 100 次方塊，全部通過連通性驗證', () {
  for (int i = 0; i < 100; i++) {
    final shape = DemonPieceGenerator.generateShape();
    expect(DemonPieceGenerator.testIsConnected(shape), true,
        reason: '第 $i 次生成的方塊不連通');
  }
});

test('生成 100 次方塊，全部通過寬度驗證', () {
  for (int i = 0; i < 100; i++) {
    final shape = DemonPieceGenerator.generateShape();
    expect(shape[0].length, lessThanOrEqualTo(10),
        reason: '第 $i 次生成的方塊寬度超過 10');
  }
});

test('降級方案返回 2×5 矩形', () {
  final fallback = DemonPieceGenerator.testGetFallbackShape();
  expect(fallback.length, 2);
  expect(fallback[0].length, 5);

  int count = 0;
  for (var row in fallback) {
    for (var cell in row) {
      if (cell) count++;
    }
  }
  expect(count, 10);
});
```

#### 驗收標準
- ✅ 連通性驗證正確（DFS/BFS 算法）
- ✅ 寬度驗證正確（拒絕 > 10 格寬）
- ✅ 100 次生成全部通過驗證
- ✅ 降級方案返回 2×5 矩形

#### 執行方式
```bash
flutter test test/demon_piece_generator_validation_test.dart
```

#### 性能要求
- 單次生成時間 < 50ms
- 100 次生成總時間 < 5 秒

---

### 1.4 擴展 Tetromino 支援動態矩陣

#### 測試方案
```dart
// test/tetromino_demon_test.dart

test('Tetromino.demon() 能成功創建', () {
  final demon = Tetromino.demon();
  expect(demon, isNotNull);
  expect(demon.type, TetrominoType.DEMON);
});

test('DEMON 方塊 shape 為 10 格', () {
  final demon = Tetromino.demon();
  int count = 0;
  for (var row in demon.shape) {
    for (var cell in row) {
      if (cell) count++;
    }
  }
  expect(count, 10);
});

test('DEMON 方塊旋轉返回自身（不旋轉）', () {
  final demon = Tetromino.demon();
  final rotatedCW = demon.rotate(true);
  final rotatedCCW = demon.rotate(false);

  expect(identical(demon, rotatedCW), true);
  expect(identical(demon, rotatedCCW), true);
});

test('DEMON 方塊 getBoundingBox 返回正確尺寸', () {
  final demon = Tetromino.demon();
  final bbox = demon.getBoundingBox();

  expect(bbox.width, greaterThan(0));
  expect(bbox.height, greaterThan(0));
  expect(bbox.width, lessThanOrEqualTo(5));
  expect(bbox.height, lessThanOrEqualTo(5));
});

test('正常方塊仍可旋轉', () {
  final tPiece = Tetromino.fromType(TetrominoType.T);
  final rotated = tPiece.rotate(true);

  expect(identical(tPiece, rotated), false);
  expect(rotated.type, TetrominoType.T);
});
```

#### 驗收標準
- ✅ `Tetromino.demon()` 成功創建
- ✅ 惡魔方塊格數為 10
- ✅ 旋轉返回自身（`identical` 檢查）
- ✅ `getBoundingBox` 正確計算 5×5 範圍
- ✅ 不影響其他方塊的旋轉功能

#### 執行方式
```bash
flutter test test/tetromino_demon_test.dart
```

---

### 1.5 單元測試與驗證

#### 測試方案
```dart
// test/demon_block_phase1_integration_test.dart

test('階段 1 整合測試：生成 100 次惡魔方塊', () {
  for (int i = 0; i < 100; i++) {
    final demon = Tetromino.demon();

    // 驗證 1：類型正確
    expect(demon.type, TetrominoType.DEMON);

    // 驗證 2：格數為 10
    int count = 0;
    for (var row in demon.shape) {
      for (var cell in row) {
        if (cell) count++;
      }
    }
    expect(count, 10, reason: '第 $i 次生成的方塊格數不是 10');

    // 驗證 3：寬度不超過 10
    expect(demon.shape[0].length, lessThanOrEqualTo(10));

    // 驗證 4：無法旋轉
    expect(identical(demon, demon.rotate(true)), true);
  }
});

test('性能測試：100 次生成時間 < 5 秒', () {
  final stopwatch = Stopwatch()..start();

  for (int i = 0; i < 100; i++) {
    Tetromino.demon();
  }

  stopwatch.stop();
  expect(stopwatch.elapsedMilliseconds, lessThan(5000));

  print('100 次生成平均時間: ${stopwatch.elapsedMilliseconds / 100} ms');
});
```

#### 驗收標準
- ✅ 100 次生成全部正確
- ✅ 每次生成時間 < 50ms
- ✅ 所有單元測試通過（覆蓋率 > 90%）

#### 執行方式
```bash
flutter test test/demon_block_phase1_integration_test.dart --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html  # 查看覆蓋率報告
```

---

## ⚡ 階段 2：觸發系統測試方案

### 2.1 實現 DemonSpawnManager 核心邏輯

#### 測試方案
```dart
// test/demon_spawn_manager_test.dart

test('初始門檻值為 10,000', () {
  final manager = DemonSpawnManager();
  expect(manager.getNextThreshold(), 10000);
});

test('前 15 個門檻值計算正確', () {
  final expected = [
    10000, 23097, 39189, 58032, 79432,
    103246, 129358, 157678, 188132, 220659,
    255103, 291413, 329543, 369451, 411101,
  ];

  final manager = DemonSpawnManager();
  for (int i = 0; i < 15; i++) {
    final threshold = manager.getNextThreshold();
    expect(threshold, closeTo(expected[i], 10),
        reason: '第 ${i + 1} 個門檻值不正確');
    manager.shouldSpawn(threshold); // 觸發
  }
});

test('達到 15 次上限後返回 -1', () {
  final manager = DemonSpawnManager();

  for (int i = 0; i < 15; i++) {
    final threshold = manager.getNextThreshold();
    manager.shouldSpawn(threshold);
  }

  expect(manager.getNextThreshold(), -1);
  expect(manager.shouldSpawn(999999), false);
});

test('reset() 後門檻值歸零', () {
  final manager = DemonSpawnManager();

  manager.shouldSpawn(10000);
  expect(manager.spawnCount, 1);

  manager.reset();
  expect(manager.spawnCount, 0);
  expect(manager.getNextThreshold(), 10000);
});

test('shouldSpawn 只在達到門檻時觸發一次', () {
  final manager = DemonSpawnManager();

  expect(manager.shouldSpawn(9999), false);
  expect(manager.shouldSpawn(10000), true);
  expect(manager.shouldSpawn(10001), false); // 分數增加但不重複觸發
  expect(manager.shouldSpawn(10002), false);
});
```

#### 驗收標準
- ✅ 初始門檻為 10,000
- ✅ 前 15 個門檻值與設計表一致（誤差 ±10）
- ✅ 第 16 次返回 -1
- ✅ `reset()` 正確歸零
- ✅ 不重複觸發

#### 執行方式
```bash
flutter test test/demon_spawn_manager_test.dart
```

---

### 2.2 擴展 GameState 狀態管理

#### 測試方案
```dart
// test/game_state_demon_test.dart

test('GameState 初始化惡魔相關欄位', () {
  final state = GameState();
  expect(state.demonSpawnCount, 0);
  expect(state.scoreMultiplier, 1.0);
  expect(state.multiplierEndTime, isNull);
});

test('startScoreMultiplier 設置 3.0 倍率', () {
  final state = GameState();
  state.startScoreMultiplier();

  expect(state.scoreMultiplier, 3.0);
  expect(state.multiplierEndTime, isNotNull);

  final remaining = state.multiplierEndTime!.difference(DateTime.now());
  expect(remaining.inSeconds, closeTo(10, 1));
});

test('疊加邏輯：連續兩次啟動加成', () async {
  final state = GameState();

  // 第一次啟動
  state.startScoreMultiplier();
  await Future.delayed(Duration(seconds: 5));

  // 5 秒後第二次啟動
  state.startScoreMultiplier();

  final remaining = state.multiplierEndTime!.difference(DateTime.now());
  expect(remaining.inSeconds, closeTo(15, 1)); // 5 + 10 = 15
});

test('checkMultiplierExpiry 到期後恢復 1.0', () async {
  final state = GameState();

  state.startScoreMultiplier(duration: Duration(milliseconds: 100));
  expect(state.scoreMultiplier, 3.0);

  await Future.delayed(Duration(milliseconds: 150));
  state.checkMultiplierExpiry();

  expect(state.scoreMultiplier, 1.0);
  expect(state.multiplierEndTime, isNull);
});

test('暫停/恢復邏輯保留剩餘時間', () async {
  final state = GameState();

  state.startScoreMultiplier();
  await Future.delayed(Duration(seconds: 3));

  // 暫停
  state.pauseGame();
  final pausedTime = DateTime.now();

  await Future.delayed(Duration(seconds: 2)); // 暫停 2 秒

  // 恢復
  state.resumeGame();

  final remaining = state.multiplierEndTime!.difference(DateTime.now());
  expect(remaining.inSeconds, closeTo(7, 1)); // 10 - 3 = 7
});

test('resetGame 清空所有惡魔狀態', () {
  final state = GameState();

  state.demonSpawnCount = 5;
  state.startScoreMultiplier();

  state.resetGame();

  expect(state.demonSpawnCount, 0);
  expect(state.scoreMultiplier, 1.0);
  expect(state.multiplierEndTime, isNull);
});
```

#### 驗收標準
- ✅ 初始化欄位正確
- ✅ `startScoreMultiplier()` 設置 3.0 倍率和 10 秒計時
- ✅ 疊加邏輯正確（剩餘時間 + 10 秒）
- ✅ `checkMultiplierExpiry()` 到期後恢復 1.0
- ✅ 暫停/恢復保留剩餘時間
- ✅ `resetGame()` 清空所有狀態

#### 執行方式
```bash
flutter test test/game_state_demon_test.dart
```

---

### 2.3 整合 DemonSpawnManager 到 GameState

#### 測試方案
```dart
// test/game_state_spawn_integration_test.dart

test('GameState 整合 DemonSpawnManager', () {
  final state = GameState();

  expect(state.demonSpawnCount, 0);

  // 模擬分數增長
  state.updateScore(10000);

  // 驗證觸發通知
  // (需要監聽 notifyListeners 或使用 ChangeNotifier 測試工具)
});

test('分數更新時檢查觸發條件', () {
  final state = GameState();

  state.updateScore(9999);
  expect(state.demonSpawnCount, 0);

  state.updateScore(10000);
  // 預期觸發惡魔方塊生成
  // 驗證 PieceProvider 接收到通知
});

test('resetGame 時重置 DemonSpawnManager', () {
  final state = GameState();

  state.updateScore(10000); // 觸發第 1 次
  state.updateScore(23097); // 觸發第 2 次

  state.resetGame();

  // 下一個門檻應該回到 10,000
  expect(state.getNextDemonThreshold(), 10000);
});
```

#### 驗收標準
- ✅ GameState 包含 `_demonSpawnManager` 實例
- ✅ 分數更新時自動檢查觸發條件
- ✅ 達到門檻時發送通知
- ✅ `resetGame()` 調用 `manager.reset()`

#### 執行方式
```bash
flutter test test/game_state_spawn_integration_test.dart
```

---

### 2.4 修改 PieceProvider 插入惡魔方塊

#### 測試方案
```dart
// test/piece_provider_demon_test.dart

test('insertDemonPiece 插入到佇列頂部', () {
  final provider = PieceProviderStack();

  final normalNext = provider.getNextPiece();
  expect(normalNext.type, isNot(TetrominoType.DEMON));

  provider.insertDemonPiece();

  final demonNext = provider.getNextPiece();
  expect(demonNext.type, TetrominoType.DEMON);
});

test('insertDemonPiece 後的下一個方塊恢復正常', () {
  final provider = PieceProviderStack();

  provider.insertDemonPiece();

  final first = provider.getNextPiece();
  expect(first.type, TetrominoType.DEMON);

  final second = provider.getNextPiece();
  expect(second.type, isNot(TetrominoType.DEMON));
});

test('連續插入 2 個惡魔方塊', () {
  final provider = PieceProviderStack();

  provider.insertDemonPiece();
  provider.insertDemonPiece();

  final first = provider.getNextPiece();
  final second = provider.getNextPiece();

  expect(first.type, TetrominoType.DEMON);
  expect(second.type, TetrominoType.DEMON);
});
```

#### 驗收標準
- ✅ `insertDemonPiece()` 方法存在
- ✅ 插入後下一個方塊為 DEMON
- ✅ 只影響下一個方塊，不影響後續佇列
- ✅ 支援連續插入

#### 執行方式
```bash
flutter test test/piece_provider_demon_test.dart
```

---

### 2.5 實現計時器與單元測試

#### 測試方案
```dart
// test/game_logic_demon_timer_test.dart

test('放置 DEMON 方塊後啟動計時器', () {
  final logic = GameLogic();
  final state = logic.gameState;

  // 模擬放置惡魔方塊
  logic.lockPiece(Tetromino.demon());

  expect(state.scoreMultiplier, 3.0);
  expect(state.multiplierEndTime, isNotNull);
});

test('放置正常方塊不啟動計時器', () {
  final logic = GameLogic();
  final state = logic.gameState;

  logic.lockPiece(Tetromino.fromType(TetrominoType.I));

  expect(state.scoreMultiplier, 1.0);
  expect(state.multiplierEndTime, isNull);
});

test('遊戲循環中自動檢查計時器到期', () async {
  final logic = GameLogic();
  final state = logic.gameState;

  state.startScoreMultiplier(duration: Duration(milliseconds: 100));

  // 運行遊戲循環
  logic.startGameLoop();

  await Future.delayed(Duration(milliseconds: 150));

  expect(state.scoreMultiplier, 1.0);

  logic.stopGameLoop();
});

test('階段 2 整合測試：完整觸發流程', () async {
  final logic = GameLogic();
  final state = logic.gameState;

  // 1. 分數達到 10,000
  state.updateScore(10000);

  // 2. 驗證下一個方塊為 DEMON
  final nextPiece = logic.pieceProvider.getNextPiece();
  expect(nextPiece.type, TetrominoType.DEMON);

  // 3. 放置惡魔方塊
  logic.lockPiece(nextPiece);

  // 4. 驗證計時器啟動
  expect(state.scoreMultiplier, 3.0);

  // 5. 等待計時器到期
  await Future.delayed(Duration(seconds: 11));
  state.checkMultiplierExpiry();

  // 6. 驗證恢復正常
  expect(state.scoreMultiplier, 1.0);
});
```

#### 驗收標準
- ✅ 放置 DEMON 啟動計時器
- ✅ 放置正常方塊不影響
- ✅ 遊戲循環自動檢查到期
- ✅ 完整流程測試通過

#### 執行方式
```bash
flutter test test/game_logic_demon_timer_test.dart
```

---

## 🎨 階段 3：視覺效果測試方案

### 3.1 實現惡魔方塊徑向漸層渲染

#### 測試方案（手動 + 視覺確認）
```dart
// test/tetromino_painter_demon_test.dart

test('_paintDemonCell 方法存在', () {
  final painter = TetromininoPainter(/* ... */);
  expect(painter, isNotNull);
  // 反射檢查 _paintDemonCell 方法存在（或公開測試版本）
});

// 視覺測試（需要在模擬器中運行）
testWidgets('惡魔方塊顯示金紅漸層', (tester) async {
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: CustomPaint(
        painter: TetromininoPainter(
          piece: Tetromino.demon(),
          // ...
        ),
      ),
    ),
  ));

  await tester.pumpAndSettle();

  // 截圖比對（需要 golden test）
  await expectLater(
    find.byType(CustomPaint),
    matchesGoldenFile('golden/demon_piece_gradient.png'),
  );
});
```

#### 手動測試步驟
1. 啟動模擬器
2. 運行 app，手動生成惡魔方塊
3. **視覺確認**：
   - [ ] 方塊中心為金色 (#FFD700)
   - [ ] 方塊邊緣為紅色 (#DC143C)
   - [ ] 漸層平滑過渡
   - [ ] 邊框為深紅色 (#8B0000)，寬度 2px
4. 截圖保存到 `test_screenshots/demon_gradient.png`

#### 驗收標準
- ✅ `_paintDemonCell()` 方法存在
- ✅ 使用 `RadialGradient`
- ✅ 視覺確認漸層正確
- ✅ Golden test 通過（如有）

---

### 3.2 實現幽靈方塊預覽系統

#### 測試方案
```dart
// test/ghost_piece_test.dart

test('_calculateGhostPiece 返回正確落點', () {
  final logic = GameLogic();

  // 設置當前方塊在頂部中央
  logic.currentPiece = Tetromino.fromType(TetrominoType.I);
  logic.currentX = 3;
  logic.currentY = 0;

  final ghost = logic.calculateGhostPiece();

  expect(ghost, isNotNull);
  expect(ghost!.x, 3); // X 位置不變
  expect(ghost.y, greaterThan(logic.currentY)); // Y 位置更低
});

test('幽靈方塊與硬降位置一致', () {
  final logic = GameLogic();

  logic.currentPiece = Tetromino.fromType(TetrominoType.T);
  logic.currentX = 5;
  logic.currentY = 3;

  final ghost = logic.calculateGhostPiece();

  // 執行硬降
  final hardDropY = logic.hardDrop();

  expect(ghost!.y, hardDropY);
});

test('惡魔方塊幽靈預覽（無旋轉）', () {
  final logic = GameLogic();

  logic.currentPiece = Tetromino.demon();
  logic.currentX = 2;
  logic.currentY = 0;

  final ghost = logic.calculateGhostPiece();

  expect(ghost, isNotNull);
  expect(identical(ghost!.piece.shape, logic.currentPiece!.shape), true);
});
```

#### 手動測試步驟
1. 運行遊戲
2. **視覺確認**（測試每種方塊類型）：
   - [ ] I 方塊幽靈正確
   - [ ] T 方塊幽靈正確
   - [ ] DEMON 方塊幽靈正確
   - [ ] 幽靈方塊半透明（opacity 0.3-0.4）
   - [ ] 幽靈方塊位於硬降落點
3. 左右移動方塊，確認幽靈同步移動

#### 驗收標準
- ✅ `_calculateGhostPiece()` 正確計算落點
- ✅ 幽靈位置與硬降一致
- ✅ 惡魔方塊幽靈不考慮旋轉
- ✅ 視覺確認所有方塊類型

---

### 3.3 實現 Next Piece 預警動畫

#### 測試方案
```dart
// test/next_piece_warning_test.dart

testWidgets('Next Piece 為 DEMON 時顯示預警', (tester) async {
  final logic = GameLogic();
  logic.pieceProvider.insertDemonPiece();

  await tester.pumpWidget(MaterialApp(
    home: GameScreen(logic: logic),
  ));

  // 查找警告文字
  expect(find.text('⚠️ 惡魔方塊'), findsOneWidget);

  // 查找動畫效果
  expect(find.byType(AnimatedOpacity), findsWidgets);
});

test('AnimationController 週期為 1.0 秒', () {
  final controller = AnimationController(
    duration: Duration(seconds: 1),
    vsync: TestVSync(),
  );

  expect(controller.duration!.inSeconds, 1);
  controller.dispose();
});
```

#### 手動測試步驟
1. 手動觸發惡魔方塊（分數達到 10,000）
2. **視覺確認**：
   - [ ] Next Piece 區域顯示紅色脈動光環
   - [ ] 光環 Opacity 在 0.5 ↔ 1.0 之間變化
   - [ ] 脈動週期約 1.0 秒
   - [ ] 顯示警告文字「⚠️ 惡魔方塊」
   - [ ] 文字為紅色粗體
3. 放置惡魔方塊後，確認預警消失

#### 驗收標準
- ✅ AnimationController 創建成功
- ✅ 檢測到 DEMON 時啟動動畫
- ✅ 視覺確認脈動效果
- ✅ 放置後動畫停止

---

### 3.4 創建分數加成計時器 UI

#### 測試方案
```dart
// test/multiplier_timer_widget_test.dart

testWidgets('計時器 UI 顯示剩餘時間', (tester) async {
  final state = GameState();
  state.startScoreMultiplier();

  await tester.pumpWidget(MaterialApp(
    home: MultiplierTimerWidget(gameState: state),
  ));

  // 查找倒數計時文字
  expect(find.textContaining('s'), findsOneWidget);

  // 查找進度條
  expect(find.byType(LinearProgressIndicator), findsOneWidget);
});

testWidgets('最後 3 秒閃爍效果', (tester) async {
  final state = GameState();
  state.startScoreMultiplier(duration: Duration(seconds: 3));

  await tester.pumpWidget(MaterialApp(
    home: MultiplierTimerWidget(gameState: state),
  ));

  // 初始狀態
  await tester.pump(Duration(milliseconds: 500));

  // 檢查閃爍動畫
  await tester.pump(Duration(milliseconds: 500));

  // 驗證 AnimatedOpacity 存在
  expect(find.byType(AnimatedOpacity), findsWidgets);
});

test('進度條值隨時間遞減', () async {
  final state = GameState();
  state.startScoreMultiplier(duration: Duration(seconds: 10));

  await Future.delayed(Duration(seconds: 5));

  final remaining = state.multiplierEndTime!.difference(DateTime.now());
  final progress = remaining.inMilliseconds / 10000;

  expect(progress, closeTo(0.5, 0.1));
});
```

#### 手動測試步驟
1. 觸發惡魔方塊並放置
2. **視覺確認**（計時器 UI）：
   - [ ] 顯示火焰 emoji 🔥
   - [ ] 顯示「三倍加成」文字
   - [ ] 倒數計時正確（例如 "9.5s"）
   - [ ] 進度條從 100% 遞減到 0%
   - [ ] 進度條顏色為紅到黃漸層
   - [ ] 最後 3 秒文字閃爍
   - [ ] 計時結束淡出動畫
3. 測試疊加：放置第二個惡魔方塊
   - [ ] 時間累加顯示（例如 "18.2s"）

#### 驗收標準
- ✅ Widget 正確顯示剩餘時間
- ✅ 進度條動畫平滑
- ✅ 最後 3 秒閃爍效果
- ✅ 疊加時顯示累計時間
- ✅ 視覺確認通過

---

### 3.5 旋轉按鈕禁用與整合測試

#### 測試方案
```dart
// test/rotation_button_disabled_test.dart

testWidgets('DEMON 方塊時旋轉按鈕禁用', (tester) async {
  final logic = GameLogic();
  logic.currentPiece = Tetromino.demon();

  await tester.pumpWidget(MaterialApp(
    home: TouchControls(logic: logic),
  ));

  final rotateButton = find.byKey(Key('rotate_button'));

  // 檢查按鈕禁用狀態
  final widget = tester.widget<GestureDetector>(rotateButton);
  expect(widget.onTap, isNull); // 或檢查 ignorePointer
});

testWidgets('正常方塊時旋轉按鈕啟用', (tester) async {
  final logic = GameLogic();
  logic.currentPiece = Tetromino.fromType(TetrominoType.T);

  await tester.pumpWidget(MaterialApp(
    home: TouchControls(logic: logic),
  ));

  final rotateButton = find.byKey(Key('rotate_button'));

  final widget = tester.widget<GestureDetector>(rotateButton);
  expect(widget.onTap, isNotNull);
});
```

#### 手動測試步驟
1. 運行遊戲
2. **視覺確認**（正常方塊）：
   - [ ] 旋轉按鈕正常顏色
   - [ ] 點擊旋轉按鈕有效
3. 觸發惡魔方塊
4. **視覺確認**（惡魔方塊）：
   - [ ] 旋轉按鈕變灰色（opacity: 0.5）
   - [ ] 點擊旋轉按鈕無效
   - [ ] 方塊確實無法旋轉

#### 性能測試
```bash
# 運行 Flutter DevTools
flutter run --profile
# 在 DevTools 中監控：
- FPS：應維持 60 FPS
- 幀渲染時間：應 < 16.67ms
- UI 線程：應 < 50% 使用率
```

#### 驗收標準
- ✅ DEMON 方塊時按鈕禁用
- ✅ 正常方塊時按鈕啟用
- ✅ 視覺確認通過
- ✅ FPS 維持 60

---

## 🔍 階段 4：遊戲邏輯整合測試方案

### 4.1 整合分數乘數系統

#### 測試方案
```dart
// test/scoring_multiplier_test.dart

test('加成期間單行消除分數 ×3', () {
  final state = GameState();
  state.startScoreMultiplier();

  final score = calculateLineScore(1, state);
  expect(score, 300); // 100 × 3
});

test('加成期間四行消除分數 ×3', () {
  final state = GameState();
  state.startScoreMultiplier();

  final score = calculateLineScore(4, state);
  expect(score, 2400); // 800 × 3
});

test('加成期間連擊分數 ×3', () {
  final state = GameState();
  state.startScoreMultiplier();
  state.comboCount = 5;

  final comboBonus = calculateComboBonus(state);
  expect(comboBonus, greaterThan(0));
  // 驗證乘數應用
});

test('非加成期間分數正常', () {
  final state = GameState();

  final score = calculateLineScore(1, state);
  expect(score, 100);
});

test('加成到期後分數恢復正常', () async {
  final state = GameState();
  state.startScoreMultiplier(duration: Duration(milliseconds: 100));

  await Future.delayed(Duration(milliseconds: 150));
  state.checkMultiplierExpiry();

  final score = calculateLineScore(1, state);
  expect(score, 100);
});
```

#### 手動測試步驟
1. 觸發惡魔方塊並放置
2. **測試分數計算**：
   - [ ] 消除 1 行：100 → 300
   - [ ] 消除 2 行：300 → 900
   - [ ] 消除 3 行：500 → 1500
   - [ ] 消除 4 行：800 → 2400
   - [ ] 連擊加成也 ×3
3. 等待計時器到期
4. **驗證恢復**：
   - [ ] 消除 1 行：恢復 100

#### 驗收標準
- ✅ 所有分數計算正確 ×3
- ✅ 連擊加成正確
- ✅ 到期後恢復正常
- ✅ 手動測試通過

---

### 4.2 整合計時器到遊戲循環

#### 測試方案
```dart
// test/game_loop_timer_test.dart

test('遊戲循環每幀檢查計時器', () async {
  final logic = GameLogic();
  final state = logic.gameState;

  state.startScoreMultiplier(duration: Duration(milliseconds: 100));

  logic.startGameLoop();

  await Future.delayed(Duration(milliseconds: 150));

  // 驗證計時器已到期
  expect(state.scoreMultiplier, 1.0);

  logic.stopGameLoop();
});

test('計時器精準度 < 100ms', () async {
  final logic = GameLogic();
  final state = logic.gameState;

  state.startScoreMultiplier(duration: Duration(seconds: 1));

  final stopwatch = Stopwatch()..start();

  logic.startGameLoop();

  while (state.scoreMultiplier == 3.0) {
    await Future.delayed(Duration(milliseconds: 10));
  }

  stopwatch.stop();

  logic.stopGameLoop();

  expect(stopwatch.elapsedMilliseconds, inInclusiveRange(900, 1100));
});
```

#### 驗收標準
- ✅ 每幀調用 `checkMultiplierExpiry()`
- ✅ 精準度誤差 < 100ms
- ✅ 不影響遊戲性能

---

### 4.3 處理暫停與恢復邏輯

#### 測試方案
```dart
// test/pause_resume_timer_test.dart

test('暫停時計時器停止倒數', () async {
  final state = GameState();

  state.startScoreMultiplier();
  await Future.delayed(Duration(seconds: 3));

  state.pauseGame();
  final pauseTime = state.multiplierEndTime!.difference(DateTime.now());

  await Future.delayed(Duration(seconds: 2));

  // 暫停期間時間不變
  final stillPausedTime = state.multiplierEndTime!.difference(DateTime.now());
  expect(pauseTime.inSeconds, closeTo(stillPausedTime.inSeconds, 1));
});

test('恢復後計時器繼續倒數', () async {
  final state = GameState();

  state.startScoreMultiplier();
  await Future.delayed(Duration(seconds: 3));

  state.pauseGame();
  await Future.delayed(Duration(seconds: 2));

  state.resumeGame();

  final remaining = state.multiplierEndTime!.difference(DateTime.now());
  expect(remaining.inSeconds, closeTo(7, 1)); // 10 - 3 = 7
});

test('多次暫停/恢復穩定性', () async {
  final state = GameState();

  state.startScoreMultiplier();

  for (int i = 0; i < 3; i++) {
    await Future.delayed(Duration(milliseconds: 500));
    state.pauseGame();
    await Future.delayed(Duration(milliseconds: 300));
    state.resumeGame();
  }

  expect(state.scoreMultiplier, 3.0);
  expect(state.multiplierEndTime, isNotNull);
});
```

#### 驗收標準
- ✅ 暫停時計時器停止
- ✅ 恢復後繼續倒數
- ✅ 多次暫停/恢復穩定
- ✅ UI 正確更新

---

### 4.4 處理 Game Over 與重啟邏輯

#### 測試方案
```dart
// test/game_over_reset_test.dart

test('Game Over 時重置所有惡魔狀態', () {
  final logic = GameLogic();
  final state = logic.gameState;

  // 模擬遊戲進行
  state.updateScore(10000); // 觸發第 1 次
  state.startScoreMultiplier();
  state.demonSpawnCount = 3;

  // Game Over
  logic.gameOver();

  expect(state.demonSpawnCount, 0);
  expect(state.scoreMultiplier, 1.0);
  expect(state.multiplierEndTime, isNull);
});

test('重啟後第一個惡魔方塊在 10,000 分', () {
  final logic = GameLogic();
  final state = logic.gameState;

  // 第一局
  state.updateScore(10000);
  state.updateScore(23097);

  // 重啟
  logic.resetGame();

  // 驗證門檻歸零
  expect(state.getNextDemonThreshold(), 10000);
});

test('重啟不影響正常遊戲功能', () {
  final logic = GameLogic();

  // 第一局
  logic.startGame();
  logic.gameOver();

  // 重啟
  logic.resetGame();
  logic.startGame();

  // 驗證正常功能
  expect(logic.currentPiece, isNotNull);
  expect(logic.gameState.score, 0);
});
```

#### 驗收標準
- ✅ Game Over 調用 `resetGame()`
- ✅ 所有惡魔狀態歸零
- ✅ 門檻回到 10,000
- ✅ 不影響正常功能

---

### 4.5 邊界情況測試與修復

#### 測試方案
```dart
// test/edge_cases_test.dart

test('連續放置 3 個惡魔方塊疊加', () async {
  final state = GameState();

  state.startScoreMultiplier(); // 第 1 個
  await Future.delayed(Duration(seconds: 3));

  state.startScoreMultiplier(); // 第 2 個
  await Future.delayed(Duration(seconds: 3));

  state.startScoreMultiplier(); // 第 3 個

  final remaining = state.multiplierEndTime!.difference(DateTime.now());
  expect(remaining.inSeconds, closeTo(24, 2)); // (10-3) + (10-3) + 10
});

test('加成期間 Game Over 不崩潰', () {
  final logic = GameLogic();
  final state = logic.gameState;

  state.startScoreMultiplier();

  expect(() => logic.gameOver(), returnsNormally);
  expect(state.scoreMultiplier, 1.0);
});

test('達到 15 次上限後不再觸發', () {
  final logic = GameLogic();
  final state = logic.gameState;

  // 觸發 15 次
  final thresholds = [
    10000, 23097, 39189, 58032, 79432,
    103246, 129358, 157678, 188132, 220659,
    255103, 291413, 329543, 369451, 411101,
  ];

  for (var threshold in thresholds) {
    state.updateScore(threshold);
  }

  expect(state.demonSpawnCount, 15);

  // 第 16 次不觸發
  state.updateScore(500000);
  expect(state.demonSpawnCount, 15);
});

test('Timer 正確釋放（記憶體洩漏測試）', () async {
  final logic = GameLogic();

  // 重複啟動/停止計時器 100 次
  for (int i = 0; i < 100; i++) {
    logic.gameState.startScoreMultiplier(duration: Duration(milliseconds: 10));
    await Future.delayed(Duration(milliseconds: 20));
    logic.gameState.checkMultiplierExpiry();
  }

  // 驗證無記憶體洩漏（需要 DevTools Memory Profiler）
  // 手動驗證：記憶體使用應該穩定
});
```

#### 手動記憶體測試
```bash
# 1. 啟動 profile 模式
flutter run --profile

# 2. 打開 DevTools
flutter pub global activate devtools
flutter pub global run devtools

# 3. 執行記憶體測試
- 觸發惡魔方塊 10 次
- 每次等待計時器到期
- 觀察 Memory 圖表
- 驗證無持續增長
```

#### 驗收標準
- ✅ 連續疊加 3 個方塊正確
- ✅ 加成期間 Game Over 穩定
- ✅ 15 次上限生效
- ✅ 無記憶體洩漏
- ✅ 所有邊界測試通過

---

## 🧪 階段 5：測試與平衡方案

### 5.1 完整功能測試

#### 測試方案（手動測試）
```markdown
# 功能測試檢查表

## 測試目標：從 0 分玩到第一個惡魔方塊

### 前置條件
- [ ] 模擬器已啟動
- [ ] App 已編譯無錯誤
- [ ] 螢幕錄製工具準備好

### 測試步驟
1. [ ] 啟動遊戲，確認初始狀態正確
   - 分數：0
   - 等級：1
   - 無惡魔方塊

2. [ ] 遊玩至 10,000 分
   - 記錄開始時間：_____
   - 記錄達到時間：_____
   - 遊玩時長：_____ 分鐘（目標：5-8 分鐘）

3. [ ] 觸發第一個惡魔方塊
   - [ ] Next Piece 顯示紅色預警
   - [ ] 警告文字「⚠️ 惡魔方塊」顯示
   - [ ] 脈動光環正常

4. [ ] 惡魔方塊進入遊戲
   - [ ] 方塊顯示金紅漸層
   - [ ] 旋轉按鈕禁用
   - [ ] 幽靈方塊顯示落點

5. [ ] 放置惡魔方塊
   - [ ] 計時器 UI 出現
   - [ ] 顯示「🔥 三倍加成」
   - [ ] 倒數計時開始（10.0s）
   - [ ] 進度條遞減

6. [ ] 加成期間消除測試
   - 消除 1 行：100 → 300 ✓/✗
   - 消除 2 行：300 → 900 ✓/✗
   - 消除 4 行：800 → 2400 ✓/✗

7. [ ] 計時器到期
   - [ ] 倒數到 0.0s
   - [ ] UI 淡出動畫
   - [ ] 分數恢復正常

### 截圖/錄影
- [ ] 惡魔方塊漸層效果
- [ ] Next Piece 預警動畫
- [ ] 計時器 UI
- [ ] 完整遊玩流程錄影

### 發現的問題
(記錄任何 bug 或異常)
```

#### 形狀多樣性測試
```dart
// test/shape_diversity_test.dart

test('生成 20 次惡魔方塊，驗證形狀多樣性', () {
  final shapes = <String>{};

  for (int i = 0; i < 20; i++) {
    final demon = Tetromino.demon();
    final shapeHash = _hashShape(demon.shape);
    shapes.add(shapeHash);
  }

  // 至少應該有 10 種不同形狀
  expect(shapes.length, greaterThan(10));
});

String _hashShape(List<List<bool>> shape) {
  return shape.map((row) =>
    row.map((cell) => cell ? '1' : '0').join()
  ).join('|');
}
```

#### 驗收標準
- ✅ 0 分到 10,000 分遊玩流程順暢
- ✅ 所有視覺效果正確顯示
- ✅ 分數計算準確
- ✅ 形狀多樣性足夠（> 10 種）
- ✅ 截圖/錄影完成

---

### 5.2 性能基準測試

#### 測試方案
```dart
// test/performance_benchmark_test.dart

test('惡魔方塊生成時間 < 50ms', () {
  final times = <int>[];

  for (int i = 0; i < 100; i++) {
    final stopwatch = Stopwatch()..start();
    Tetromino.demon();
    stopwatch.stop();
    times.add(stopwatch.elapsedMicroseconds);
  }

  final avgTime = times.reduce((a, b) => a + b) / times.length;
  final avgMs = avgTime / 1000;

  print('平均生成時間: $avgMs ms');
  expect(avgMs, lessThan(50));
});

test('100 次生成總時間 < 5 秒', () {
  final stopwatch = Stopwatch()..start();

  for (int i = 0; i < 100; i++) {
    Tetromino.demon();
  }

  stopwatch.stop();

  print('100 次生成總時間: ${stopwatch.elapsedMilliseconds} ms');
  expect(stopwatch.elapsedMilliseconds, lessThan(5000));
});
```

#### FPS 測試（手動）
```markdown
# FPS 測試步驟

## 工具
- Flutter DevTools Performance 頁面

## 測試場景
1. [ ] 正常遊玩（無惡魔方塊）
   - FPS：_____ (目標：60)
   - 幀渲染時間：_____ ms (目標：< 16.67ms)

2. [ ] 惡魔方塊在場（金紅漸層）
   - FPS：_____ (目標：60)
   - 幀渲染時間：_____ ms

3. [ ] 幽靈方塊 + 惡魔方塊
   - FPS：_____ (目標：60)
   - 幀渲染時間：_____ ms

4. [ ] 計時器 UI + 預警動畫
   - FPS：_____ (目標：60)
   - 幀渲染時間：_____ ms

5. [ ] 所有效果同時存在
   - FPS：_____ (目標：≥ 55)
   - 幀渲染時間：_____ ms

## 結論
- 是否維持 60 FPS：是/否
- 需要優化的場景：_____
```

#### 記憶體測試
```markdown
# 記憶體測試步驟

## 工具
- Flutter DevTools Memory 頁面

## 測試流程
1. [ ] 啟動遊戲，記錄初始記憶體：_____ MB
2. [ ] 遊玩 10 分鐘，記錄記憶體：_____ MB
3. [ ] 觸發惡魔方塊 5 次，記錄記憶體：_____ MB
4. [ ] 等待計時器到期 5 次，記錄記憶體：_____ MB
5. [ ] Game Over 重啟 3 次，記錄記憶體：_____ MB

## 分析
- 記憶體增長：_____ MB
- 是否有持續增長：是/否
- 是否有記憶體洩漏：是/否

## 垃圾回收
- [ ] 手動觸發 GC（DevTools）
- [ ] 記憶體回收到：_____ MB
- [ ] 與初始值差異：_____ MB (目標：< 20 MB)
```

#### 驗收標準
- ✅ 生成時間 < 50ms
- ✅ FPS 維持 60
- ✅ 記憶體增長 < 20 MB
- ✅ 無記憶體洩漏

---

### 5.3 難度曲線平衡

#### 測試方案（手動）
```markdown
# 難度曲線測試

## 測試目標
驗證惡魔方塊觸發時機是否合理

## 測試流程
1. [ ] 第 1 次觸發（10,000 分）
   - 預估關卡：Level _____
   - 實際關卡：Level _____
   - 遊玩時長：_____ 分鐘（目標：5-8 分鐘）
   - 難度感受：容易/適中/困難

2. [ ] 第 2 次觸發（23,097 分）
   - 預估關卡：Level 18
   - 實際關卡：Level _____
   - 間隔時長：_____ 分鐘
   - 難度感受：容易/適中/困難

3. [ ] 第 3 次觸發（39,189 分）
   - 預估關卡：Level 28
   - 實際關卡：Level _____
   - 間隔時長：_____ 分鐘
   - 難度感受：容易/適中/困難

## 曲線調整
- 當前公式：n^1.2
- 第一次觸發時間是否合適：是/否
- 建議調整：
  - [ ] 保持 n^1.2
  - [ ] 改為 n^1.15（更頻繁）
  - [ ] 改為 n^1.25（更稀疏）
  - [ ] 改為 n^1.3（更稀疏）

## 15 次上限測試
- [ ] 是否有玩家能達到 15 次：是/否
- [ ] 第 15 次分數：411,101
- [ ] 達到時關卡：Level _____
- [ ] 建議上限：_____ 次
```

#### 數學驗證
```dart
// test/difficulty_curve_test.dart

test('驗證觸發曲線公式', () {
  final expected = [
    10000, 23097, 39189, 58032, 79432,
    103246, 129358, 157678, 188132, 220659,
    255103, 291413, 329543, 369451, 411101,
  ];

  for (int n = 1; n <= 15; n++) {
    final threshold = (10000 * pow(n, 1.2)).round();
    expect(threshold, closeTo(expected[n - 1], 10));
  }
});

test('測試替代公式 n^1.15', () {
  for (int n = 1; n <= 5; n++) {
    final current = (10000 * pow(n, 1.2)).round();
    final alternative = (10000 * pow(n, 1.15)).round();

    print('n=$n: 當前=$current, 替代=$alternative, 差異=${current - alternative}');
  }
});
```

#### 驗收標準
- ✅ 第一次觸發在 5-8 分鐘
- ✅ 間隔時間合理
- ✅ 15 次上限適當
- ✅ 記錄最終參數

---

### 5.4 邊界情況壓力測試

#### 測試方案
```dart
// test/stress_test.dart

test('降級方案觸發頻率統計', () {
  int fallbackCount = 0;
  int totalGenerated = 0;

  // 生成 1000 次
  for (int i = 0; i < 1000; i++) {
    final shape = DemonPieceGenerator.generateShape();
    totalGenerated++;

    // 檢查是否為降級方案（2×5 矩形）
    if (_isFallbackShape(shape)) {
      fallbackCount++;
    }
  }

  final fallbackRate = fallbackCount / totalGenerated;
  print('降級方案觸發率: ${(fallbackRate * 100).toStringAsFixed(2)}%');

  // 降級方案應該非常罕見（< 1%）
  expect(fallbackRate, lessThan(0.01));
});

bool _isFallbackShape(List<List<bool>> shape) {
  return shape.length == 2 &&
         shape[0].length == 5 &&
         shape[0].every((cell) => cell) &&
         shape[1].every((cell) => cell);
}

test('快速重啟遊戲 10 次', () {
  final logic = GameLogic();

  for (int i = 0; i < 10; i++) {
    logic.startGame();
    logic.updateScore(10000);
    logic.gameOver();
    logic.resetGame();
  }

  // 驗證狀態清空
  expect(logic.gameState.demonSpawnCount, 0);
  expect(logic.gameState.scoreMultiplier, 1.0);
});
```

#### 手動壓力測試
```markdown
# 壓力測試檢查表

## 測試 1：連續 3 個惡魔方塊
1. [ ] 修改代碼強制連續生成 3 個惡魔方塊
2. [ ] 全部放置後驗證計時器
3. [ ] 預期時間：約 30 秒
4. [ ] 實際時間：_____ 秒
5. [ ] 結果：通過/失敗

## 測試 2：加成期間暫停/恢復 10 次
1. [ ] 觸發惡魔方塊並放置
2. [ ] 連續暫停/恢復 10 次
3. [ ] 驗證計時器仍正確倒數
4. [ ] 結果：通過/失敗

## 測試 3：達到 15 次上限
1. [ ] 修改代碼模擬快速達到 15 次
2. [ ] 驗證第 16 次不觸發
3. [ ] 分數繼續增長時無異常
4. [ ] 結果：通過/失敗

## 測試 4：極端形狀放置
1. [ ] 生成 100 個惡魔方塊
2. [ ] 嘗試放置所有形狀
3. [ ] 成功放置率：_____ %
4. [ ] 無法放置的形狀數：_____
5. [ ] 結果：通過/失敗
```

#### 驗收標準
- ✅ 降級方案觸發率 < 1%
- ✅ 連續 3 個疊加穩定
- ✅ 多次暫停/恢復穩定
- ✅ 15 次上限生效
- ✅ 快速重啟穩定
- ✅ 所有形狀可放置

---

### 5.5 最終驗收與文檔

#### 完整流程測試
```markdown
# 最終驗收檢查表

## 完整遊戲流程（0 → Game Over）

### 階段 1：遊戲開始
- [ ] 啟動遊戲無錯誤
- [ ] 初始狀態正確
- [ ] 所有 UI 元素顯示

### 階段 2：正常遊玩
- [ ] 方塊移動/旋轉正常
- [ ] 消除行正常
- [ ] 分數累積正確
- [ ] 等級提升正常

### 階段 3：第一個惡魔方塊
- [ ] 達到 10,000 分觸發
- [ ] 預警動畫正確
- [ ] 方塊顯示正確
- [ ] 無法旋轉
- [ ] 放置後計時器啟動

### 階段 4：分數加成
- [ ] 計時器 UI 顯示
- [ ] 分數 ×3 正確
- [ ] 倒數計時精準
- [ ] 到期後恢復

### 階段 5：後續觸發
- [ ] 第 2 次在 23,097 分
- [ ] 第 3 次在 39,189 分
- [ ] 疊加邏輯正確

### 階段 6：暫停/恢復
- [ ] 暫停功能正常
- [ ] 計時器暫停
- [ ] 恢復後繼續

### 階段 7：Game Over
- [ ] 遊戲結束正確
- [ ] 狀態重置
- [ ] 可正常重啟

### 性能指標
- [ ] 全程 FPS ≥ 55
- [ ] 無記憶體洩漏
- [ ] 無崩潰
- [ ] 無卡頓

### 發現的 Bug
(記錄所有 bug)
1. _____
2. _____
3. _____
```

#### 測試報告模板
```markdown
# 惡魔方塊系統測試報告

**測試日期**: 2025-11-01
**測試者**: _____
**測試環境**: Android/iOS, 模擬器/真機

## 測試總結
- 總測試項目：125 個
- 通過項目：_____ 個
- 失敗項目：_____ 個
- 通過率：_____ %

## 性能數據
| 指標 | 目標 | 實際 | 達標 |
|------|------|------|------|
| 生成時間 | < 50ms | _____ ms | ✓/✗ |
| FPS | 60 | _____ | ✓/✗ |
| 記憶體增長 | < 20 MB | _____ MB | ✓/✗ |
| 計時器精度 | < 100ms | _____ ms | ✓/✗ |

## 平衡參數
| 參數 | 最終值 | 備註 |
|------|--------|------|
| 觸發公式 | n^_____ | 保持/調整 |
| 最大次數 | _____ 次 | |
| 降級觸發率 | _____ % | |

## 發現的問題
1. [P1] _____
2. [P2] _____

## 建議
1. _____
2. _____

## 結論
系統是否可發布：是/否
```

#### 驗收標準
- ✅ 完整流程測試通過
- ✅ 所有 bug 記錄完整
- ✅ 測試報告完成
- ✅ 設計文檔更新
- ✅ 程式碼提交

---

## 📊 測試工具總覽

### 自動化測試工具
```bash
# 單元測試
flutter test

# 覆蓋率報告
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html

# 整合測試
flutter test integration_test/

# 性能測試
flutter run --profile
flutter drive --target=test_driver/perf_test.dart
```

### 手動測試工具
```bash
# DevTools
flutter pub global activate devtools
flutter pub global run devtools

# 性能監控
flutter run --profile
# 打開 DevTools Performance 頁面

# 記憶體分析
flutter run --profile
# 打開 DevTools Memory 頁面
```

### 測試數據收集
- 截圖工具：系統內建
- 錄影工具：OBS Studio / QuickTime
- FPS 監控：Flutter DevTools
- 記憶體監控：Flutter DevTools
- 日誌收集：`flutter logs`

---

## 🎯 測試優先級

| 優先級 | 測試類型 | 數量 | 必須通過 |
|--------|----------|------|----------|
| P0 | 單元測試 | 50+ | 100% |
| P0 | 核心功能測試 | 15 | 100% |
| P1 | 整合測試 | 8 | 100% |
| P1 | 性能測試 | 5 | 80% |
| P2 | 手動測試 | 12 | 90% |
| P3 | 壓力測試 | 5 | 80% |

---

## 📝 測試執行建議

1. **開發階段**：每完成一個子任務立即執行對應的單元測試
2. **階段結束**：執行該階段的整合測試
3. **全部完成**：執行完整的手動測試和性能測試
4. **發布前**：執行所有測試並生成報告

**預估總測試時間**: 3-4 小時
