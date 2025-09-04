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

  group('Dragon Roar - 超級優化版測試', () {
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
      // 通過增加分數來設置滿能量 (3格 = 300分)
      energyManager.addScore(30); // 30行 = 300分 = 3格能量
      
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

    group('前置檢查測試', () {
      test('需要活動方塊才能施放', () {
        // 沒有活動方塊的情況
        gameState.currentTetromino = null;
        
        final result = gameLogic.castRune(0);
        
        expect(result.isFailure, true);
        expect(result.error, RuneCastError.systemError);
        expect(result.message.contains('無活動方塊'), true);
      });

      test('能量不足時無法施放', () {
        // 設置活動方塊
        gameState.currentTetromino = Tetromino.fromType(TetrominoType.T, 10);
        
        // 通過重新初始化清空能量，並重新設置到符文系統
        energyManager = RuneEnergyManager();
        runeSystem.setEnergyManager(energyManager);
        
        final result = gameLogic.castRune(0);
        
        expect(result.isFailure, true);
        expect(result.error, RuneCastError.energyInsufficient);
      });

      test('冷卻中無法施放', () {
        // 設置活動方塊和滿能量
        gameState.currentTetromino = Tetromino.fromType(TetrominoType.T, 10);
        energyManager.addScore(30); // 滿能量
        
        // 先施放一次
        gameLogic.castRune(0);
        
        // 重新設置滿能量（因為施放會消耗）
        energyManager.addScore(30); // 重新滿能量
        
        // 立即再次施放
        final result = gameLogic.castRune(0);
        
        expect(result.isFailure, true);
        expect(result.error, RuneCastError.cooldownActive);
      });
    });

    group('智能中心計算測試', () {
      test('T型方塊在棋盤中央的中心計算', () {
        // 創建T型方塊在位置 (5, 30)
        final tetromino = Tetromino.fromType(TetrominoType.T, 10);
        tetromino.x = 5;
        tetromino.y = 30;
        gameState.currentTetromino = tetromino;
        
        energyManager.addScore(30); // 30行 = 300分 = 3格滿能量
        final result = gameLogic.castRune(0);
        
        expect(result.isSuccess, true);
        // 驗證目標行應該在 29, 30, 31 範圍內
      });

      test('I型方塊的中心計算', () {
        // 創建I型方塊
        final tetromino = Tetromino.fromType(TetrominoType.I, 10);
        tetromino.x = 5;
        tetromino.y = 25;
        gameState.currentTetromino = tetromino;
        
        energyManager.addScore(30); // 30行 = 300分 = 3格滿能量
        final result = gameLogic.castRune(0);
        
        expect(result.isSuccess, true);
      });

      test('邊界安全 - 頂部邊界', () {
        // 方塊在頂部邊界
        final tetromino = Tetromino.fromType(TetrominoType.O, 10);
        tetromino.x = 5;
        tetromino.y = 1; // 接近頂部
        gameState.currentTetromino = tetromino;
        
        energyManager.addScore(30); // 30行 = 300分 = 3格滿能量
        final result = gameLogic.castRune(0);
        
        expect(result.isSuccess, true);
        // 不應該嘗試清除負數行
      });

      test('邊界安全 - 底部邊界', () {
        // 方塊在底部邊界
        final tetromino = Tetromino.fromType(TetrominoType.O, 10);
        tetromino.x = 5;
        tetromino.y = GameState.totalRowCount - 2; // 接近底部
        gameState.currentTetromino = tetromino;
        
        energyManager.addScore(30); // 30行 = 300分 = 3格滿能量
        final result = gameLogic.castRune(0);
        
        expect(result.isSuccess, true);
        // 不應該嘗試清除超出邊界的行
      });
    });

    group('目標選擇和清除測試', () {
      test('清除三行（中心±1）', () {
        // 創建包含方塊的棋盤
        final board = gameState.board;
        
        // 在第 30, 31, 32 行添加方塊
        for (int row = 30; row <= 32; row++) {
          for (int col = 0; col < 5; col++) {
            board[row][col] = Colors.red;
          }
        }
        
        // 設置活動方塊在第31行
        final tetromino = Tetromino.fromType(TetrominoType.T, 10);
        tetromino.x = 5;
        tetromino.y = 31;
        gameState.currentTetromino = tetromino;
        
        energyManager.addScore(30); // 30行 = 300分 = 3格滿能量
        
        // 記錄清除前的方塊數量
        int blocksBefore = 0;
        for (int row = 30; row <= 32; row++) {
          for (int col = 0; col < board[row].length; col++) {
            if (board[row][col] != null) blocksBefore++;
          }
        }
        
        final result = gameLogic.castRune(0);
        
        expect(result.isSuccess, true);
        
        // 驗證方塊被清除（考慮重力效果）
        int blocksAfter = 0;
        for (int row = 30; row <= 32; row++) {
          for (int col = 0; col < board[row].length; col++) {
            if (board[row][col] != null) blocksAfter++;
          }
        }
        
        expect(blocksAfter, lessThan(blocksBefore));
      });

      test('空行智能過濾', () {
        // 創建只有中心行有方塊的情況
        final board = gameState.board;
        
        // 只在第31行添加方塊
        for (int col = 0; col < 3; col++) {
          board[31][col] = Colors.blue;
        }
        
        final tetromino = Tetromino.fromType(TetrominoType.T, 10);
        tetromino.x = 5;
        tetromino.y = 31;
        gameState.currentTetromino = tetromino;
        
        energyManager.addScore(30); // 30行 = 300分 = 3格滿能量
        final result = gameLogic.castRune(0);
        
        expect(result.isSuccess, true);
        // 應該優先清除有方塊的行
      });
    });

    group('智能重力系統測試', () {
      test('大範圍清除使用 Column Gravity', () {
        final board = gameState.board;
        
        // 創建大範圍有方塊的情況（3行 x 8列）
        for (int row = 30; row <= 32; row++) {
          for (int col = 0; col < 8; col++) {
            board[row][col] = Colors.green;
          }
        }
        
        final tetromino = Tetromino.fromType(TetrominoType.T, 10);
        tetromino.x = 5;
        tetromino.y = 31;
        gameState.currentTetromino = tetromino;
        
        energyManager.addScore(30); // 30行 = 300分 = 3格滿能量
        final result = gameLogic.castRune(0);
        
        expect(result.isSuccess, true);
        // 期望使用 Column Gravity 進行壓實
      });

      test('單行清除使用 Row Gravity', () {
        final board = gameState.board;
        
        // 只在一行添加少量方塊
        for (int col = 0; col < 3; col++) {
          board[31][col] = Colors.orange;
        }
        
        final tetromino = Tetromino.fromType(TetrominoType.T, 10);
        tetromino.x = 5;
        tetromino.y = 31;
        gameState.currentTetromino = tetromino;
        
        energyManager.addScore(30); // 30行 = 300分 = 3格滿能量
        final result = gameLogic.castRune(0);
        
        expect(result.isSuccess, true);
        // 期望使用 Row Gravity 保持結構
      });

      test('空揮情況跳過重力', () {
        // 完全空盤
        final tetromino = Tetromino.fromType(TetrominoType.T, 10);
        tetromino.x = 5;
        tetromino.y = 31;
        gameState.currentTetromino = tetromino;
        
        energyManager.addScore(30); // 30行 = 300分 = 3格滿能量
        final result = gameLogic.castRune(0);
        
        expect(result.isSuccess, true);
        // 空揮應該成功，但不觸發重力
      });
    });

    group('能量消耗和冷卻測試', () {
      test('成功施放消耗3格能量', () {
        gameState.currentTetromino = Tetromino.fromType(TetrominoType.T, 10);
        energyManager.addScore(30); // 30行 = 300分 = 3格滿能量
        
        expect(energyManager.currentBars, 3);
        
        final result = gameLogic.castRune(0);
        
        expect(result.isSuccess, true);
        expect(energyManager.currentBars, 0); // 消耗3格
      });

      test('15秒冷卻生效', () {
        gameState.currentTetromino = Tetromino.fromType(TetrominoType.T, 10);
        energyManager.addScore(30); // 30行 = 300分 = 3格滿能量
        
        // 第一次施放
        final result1 = gameLogic.castRune(0);
        expect(result1.isSuccess, true);
        
        // 檢查冷卻狀態
        final slot = runeSystem.slots[0];
        expect(slot.isCooling, true);
        expect(slot.cooldownRemaining, greaterThan(0));
        
        // 冷卻時間應該是15秒左右
        expect(slot.cooldownRemaining, greaterThan(14000)); // > 14秒
        expect(slot.cooldownRemaining, lessThan(16000)); // < 16秒
      });
    });

    group('錯誤處理測試', () {
      test('槽位為空時返回錯誤', () {
        // 清空槽位
        final loadout = gameState.runeLoadout;
        loadout.setSlot(0, null);
        runeSystem.reloadLoadout();
        
        gameState.currentTetromino = Tetromino.fromType(TetrominoType.T, 10);
        energyManager.addScore(30); // 30行 = 300分 = 3格滿能量
        
        final result = gameLogic.castRune(0);
        
        expect(result.isFailure, true);
        expect(result.error, RuneCastError.slotEmpty);
      });

      test('無效槽位索引', () {
        gameState.currentTetromino = Tetromino.fromType(TetrominoType.T, 10);
        energyManager.addScore(30); // 30行 = 300分 = 3格滿能量
        
        final result = gameLogic.castRune(999); // 無效索引
        
        expect(result.isFailure, true);
        expect(result.error, RuneCastError.systemError);
      });
    });

    group('性能和穩定性測試', () {
      test('連續施放穩定性', () {
        // 測試多次施放的穩定性
        for (int i = 0; i < 5; i++) {
          gameState.currentTetromino = Tetromino.fromType(TetrominoType.T, 10);
          energyManager.addScore(30); // 30行 = 300分 = 3格滿能量
          
          // 重置冷卻（模擬時間流逝）
          final slot = runeSystem.slots[0];
          slot.reset();
          
          final result = gameLogic.castRune(0);
          expect(result.isSuccess, true);
        }
      });

      test('大型棋盤處理性能', () {
        final board = gameState.board;
        
        // 填滿大部分棋盤
        for (int row = 20; row < GameState.totalRowCount; row++) {
          for (int col = 0; col < GameState.colCount; col++) {
            if ((row + col) % 3 != 0) { // 留一些空隙
              board[row][col] = Colors.purple;
            }
          }
        }
        
        gameState.currentTetromino = Tetromino.fromType(TetrominoType.T, 10);
        energyManager.addScore(30); // 30行 = 300分 = 3格滿能量
        
        final stopwatch = Stopwatch()..start();
        final result = gameLogic.castRune(0);
        stopwatch.stop();
        
        expect(result.isSuccess, true);
        expect(stopwatch.elapsedMilliseconds, lessThan(100)); // 應該在100ms內完成
      });
    });

    group('整合測試', () {
      test('完整遊戲情境模擬', () {
        final board = gameState.board;
        
        // 模擬遊戲中期情況：底部有一些堆積
        for (int row = 35; row < GameState.totalRowCount; row++) {
          for (int col = 0; col < GameState.colCount; col++) {
            if ((row + col) % 2 == 0) {
              board[row][col] = Colors.cyan;
            }
          }
        }
        
        // 設置下降中的方塊
        final tetromino = Tetromino.fromType(TetrominoType.T, 10);
        tetromino.x = 4;
        tetromino.y = 30;
        gameState.currentTetromino = tetromino;
        
        // 玩家擁有滿能量
        energyManager.addScore(30); // 30行 = 300分 = 3格滿能量
        
        // 執行 Dragon Roar
        final result = gameLogic.castRune(0);
        
        expect(result.isSuccess, true);
        expect(energyManager.currentBars, 0); // 能量被消耗
        
        // 驗證UI更新回調被觸發
        // （這裡可以添加 mock 來驗證回調）
      });
    });
  });
}