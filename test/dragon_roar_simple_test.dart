import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tetris_game/models/tetromino.dart';
import 'package:flutter_tetris_game/game/game_state.dart';
import 'package:flutter_tetris_game/game/game_logic.dart';
import 'package:flutter_tetris_game/game/rune_system.dart';
import 'package:flutter_tetris_game/game/rune_events.dart';
import 'package:flutter_tetris_game/game/rune_energy_manager.dart';

void main() {
  // 初始化 Flutter 綁定
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Dragon Roar - 簡化驗證測試', () {
    late GameState gameState;
    late GameLogic gameLogic;
    late RuneSystem runeSystem;
    late RuneEnergyManager energyManager;

    setUp(() {
      // 初始化遊戲狀態
      gameState = GameState();
      gameState.initBoard();

      // 初始化能量管理器
      energyManager = gameState.runeEnergyManager;
      energyManager.addScore(30); // 30行 = 300分 = 3格滿能量

      // 設置 Dragon Roar 到槽位 0
      final loadout = gameState.runeLoadout;
      loadout.setSlot(0, RuneType.dragonRoar);

      // 初始化符文系統
      runeSystem = RuneSystem(loadout);
      runeSystem.setEnergyManager(energyManager);
      gameState.runeSystem = runeSystem;

      // 初始化遊戲邏輯
      gameLogic = GameLogic(gameState);
    });

    test('基本施法成功測試', () async {
      // 設置活動方塊
      gameState.currentTetromino = Tetromino.fromType(TetrominoType.T, 10);
      gameState.currentTetromino!.x = 5;
      gameState.currentTetromino!.y = 30;

      // 確認初始條件
      expect(energyManager.currentBars, 3); // 滿能量
      expect(gameState.currentTetromino, isNotNull); // 有活動方塊

      // 等待避免節流
      await Future.delayed(const Duration(milliseconds: 300));

      // 執行施法
      final result = gameLogic.castRune(0);

      print(
          '✅ Cast result: ${result.isSuccess} - ${result.error} - ${result.message}');

      // 驗證結果
      expect(result.isSuccess, true,
          reason: 'Dragon Roar 應該施法成功 - ${result.error} - ${result.message}');
      expect(energyManager.currentBars, 0, reason: '應該消耗3格能量');

      // 驗證冷卻開始
      final slot = runeSystem.slots[0];
      expect(slot.isCooling, true, reason: '施法後應該進入冷卻');
      expect(slot.cooldownRemaining, greaterThan(0), reason: '冷卻時間應該大於0');

      print('✅ Dragon Roar 基本施法測試通過');
    });

    test('無活動方塊時施法失敗', () async {
      // 移除活動方塊
      gameState.currentTetromino = null;

      // 等待避免節流
      await Future.delayed(const Duration(milliseconds: 300));

      final result = gameLogic.castRune(0);

      expect(result.isFailure, true);
      expect(result.error, RuneCastError.systemError);
      expect(result.message.contains('無活動方塊'), true);

      print('✅ 無活動方塊防護測試通過');
    });

    test('能量不足時施法失敗', () async {
      // 設置活動方塊
      gameState.currentTetromino = Tetromino.fromType(TetrominoType.T, 10);

      // 清空能量
      energyManager = RuneEnergyManager();
      runeSystem.setEnergyManager(energyManager);

      // 等待避免節流
      await Future.delayed(const Duration(milliseconds: 300));

      final result = gameLogic.castRune(0);

      expect(result.isFailure, true);
      expect(result.error, RuneCastError.energyInsufficient);

      print('✅ 能量不足防護測試通過');
    });

    test('實際清除效果驗證', () async {
      final board = gameState.board;

      // 在第30-32行添加一些方塊
      for (int row = 30; row <= 32; row++) {
        for (int col = 0; col < 3; col++) {
          board[row][col] = Colors.red;
        }
      }

      // 設置活動方塊在第31行
      gameState.currentTetromino = Tetromino.fromType(TetrominoType.T, 10);
      gameState.currentTetromino!.x = 5;
      gameState.currentTetromino!.y = 31;

      // 計算清除前的方塊數量
      int blocksBefore = 0;
      for (int row = 30; row <= 32; row++) {
        for (int col = 0; col < board[row].length; col++) {
          if (board[row][col] != null) blocksBefore++;
        }
      }

      expect(blocksBefore, 9, reason: '應該有9個方塊（3行x3列）');

      // 等待避免節流
      await Future.delayed(const Duration(milliseconds: 300));

      // 執行施法
      final result = gameLogic.castRune(0);
      expect(result.isSuccess, true);

      // 計算清除後的方塊數量（考慮重力效果）
      int blocksAfter = 0;
      for (int row = 30; row <= 32; row++) {
        for (int col = 0; col < board[row].length; col++) {
          if (board[row][col] != null) blocksAfter++;
        }
      }

      expect(blocksAfter, lessThan(blocksBefore),
          reason: '清除後方塊數量應該減少（原有 $blocksBefore，現有 $blocksAfter）');

      print('✅ 實際清除效果驗證通過：清除了 ${blocksBefore - blocksAfter} 個方塊');
    });

    test('冷卻機制驗證', () async {
      gameState.currentTetromino = Tetromino.fromType(TetrominoType.T, 10);

      // 等待避免節流
      await Future.delayed(const Duration(milliseconds: 300));

      // 第一次施法
      final result1 = gameLogic.castRune(0);
      expect(result1.isSuccess, true);

      // 重新設置能量（模擬有充足能量）
      energyManager.addScore(30);

      // 等待避免節流
      await Future.delayed(const Duration(milliseconds: 300));

      // 立即第二次施法應該失敗（冷卻中）
      final result2 = gameLogic.castRune(0);
      expect(result2.isFailure, true);
      expect(result2.error, RuneCastError.cooldownActive);

      print('✅ 冷卻機制驗證通過');
    });
  });
}
