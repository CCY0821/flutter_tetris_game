import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tetris_game/game/demon_spawn_manager.dart';
import 'package:flutter_tetris_game/game/game_state.dart';

/// 階段 2 單元測試：惡魔方塊觸發系統
/// 測試 DemonSpawnManager 和分數加成系統
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DemonSpawnManager Tests', () {
    late DemonSpawnManager manager;

    setUp(() {
      manager = DemonSpawnManager();
    });

    test('Initial state should be zero spawns', () {
      expect(manager.spawnCount, 0);
      expect(manager.hasReachedMax, false);
    });

    test('First threshold should be 10,000 points', () {
      expect(manager.getNextThreshold(), 10000);
    });

    test('Should spawn at threshold and increment count', () {
      final shouldSpawn = manager.shouldSpawn(10000);
      expect(shouldSpawn, true);
      expect(manager.spawnCount, 1);
    });

    test('Should not spawn below threshold', () {
      final shouldSpawn = manager.shouldSpawn(9999);
      expect(shouldSpawn, false);
      expect(manager.spawnCount, 0);
    });

    test('Should not spawn twice at same score', () {
      manager.shouldSpawn(10000);
      expect(manager.spawnCount, 1);

      final shouldSpawnAgain = manager.shouldSpawn(10000);
      expect(shouldSpawnAgain, false);
      expect(manager.spawnCount, 1);
    });

    test('Threshold should increase exponentially', () {
      final threshold1 = manager.getNextThreshold(); // n=1
      manager.shouldSpawn(threshold1);

      final threshold2 = manager.getNextThreshold(); // n=2
      expect(threshold2, greaterThan(threshold1));
      expect(threshold2, closeTo(22974, 100)); // Actual formula: 10000 * (2^1.2)
    });

    test('Should spawn multiple times at different thresholds', () {
      final scores = [10000, 23100, 39200, 57500, 78000];

      for (int i = 0; i < scores.length; i++) {
        final shouldSpawn = manager.shouldSpawn(scores[i]);
        expect(shouldSpawn, true);
        expect(manager.spawnCount, i + 1);
      }
    });

    test('Should continue spawning beyond 15 times (no limit)', () {
      // Simulate 20 spawns to test unlimited spawning
      for (int i = 1; i <= 20; i++) {
        final threshold = manager.getNextThreshold();
        manager.shouldSpawn(threshold);
      }

      expect(manager.spawnCount, 20);
      expect(manager.hasReachedMax, false); // Always false now
      expect(manager.getNextThreshold(), greaterThan(0)); // Still returns valid threshold

      // Should continue spawning at higher scores
      final threshold21 = manager.getNextThreshold();
      final shouldSpawn = manager.shouldSpawn(threshold21);
      expect(shouldSpawn, true);
      expect(manager.spawnCount, 21);
    });

    test('Reset should clear all counters', () {
      manager.shouldSpawn(10000);
      manager.shouldSpawn(23100);
      expect(manager.spawnCount, 2);

      manager.reset();
      expect(manager.spawnCount, 0);
      expect(manager.getNextThreshold(), 10000);
    });

    test('State serialization should work correctly', () {
      manager.shouldSpawn(10000);
      manager.shouldSpawn(23100);

      final state = manager.getState();
      expect(state['spawnCount'], 2);
      expect(state['lastScore'], 23100);

      final newManager = DemonSpawnManager();
      newManager.restoreState(state);
      expect(newManager.spawnCount, 2);
    });

    test('Threshold table should have default 30 entries', () {
      final thresholds = DemonSpawnManager.getThresholdTable();
      expect(thresholds.length, 30); // Default size is now 30
      expect(thresholds[0], 10000);
      expect(thresholds[1], 22974); // n=2: 10000 * (2^1.2)
      expect(thresholds[14], greaterThan(200000)); // n=15 should be large
      expect(thresholds[29], greaterThan(500000)); // n=30: ~592,305
    });

    test('Force spawn should work and increment count', () {
      manager.forceSpawn();
      expect(manager.spawnCount, 1);

      manager.forceSpawn();
      expect(manager.spawnCount, 2);
    });

    test('Force spawn can exceed previous max (no limit)', () {
      for (int i = 0; i < 20; i++) {
        manager.forceSpawn();
      }
      expect(manager.spawnCount, 20); // No limit anymore
    });
  });

  group('GameState Score Multiplier Tests',
      skip: 'Requires audio plugins not available in test environment', () {
    late GameState gameState;

    setUp(() {
      gameState = GameState.instance;
      // Reset multiplier state before each test
      gameState.scoreMultiplier = 1.0;
      gameState.multiplierEndTime = null;
    });

    test('Reset multiplier should be 1.0', () {
      // After setUp reset
      expect(gameState.scoreMultiplier, 1.0);
      expect(gameState.multiplierEndTime, null);
    });

    test('startScoreMultiplier should set multiplier to 3.0', () {
      gameState.startScoreMultiplier();
      expect(gameState.scoreMultiplier, 3.0);
      expect(gameState.multiplierEndTime, isNotNull);
    });

    test('Multiplier should expire after duration', () async {
      gameState.startScoreMultiplier(duration: Duration(milliseconds: 100));
      expect(gameState.scoreMultiplier, 3.0);

      await Future.delayed(Duration(milliseconds: 150));
      gameState.checkMultiplierExpiry();

      expect(gameState.scoreMultiplier, 1.0);
      expect(gameState.multiplierEndTime, null);
    });

    test('Multiplier should not expire before duration', () async {
      gameState.startScoreMultiplier(duration: Duration(milliseconds: 200));
      expect(gameState.scoreMultiplier, 3.0);

      await Future.delayed(Duration(milliseconds: 50));
      gameState.checkMultiplierExpiry();

      expect(gameState.scoreMultiplier, 3.0);
      expect(gameState.multiplierEndTime, isNotNull);
    });

    test('Stacking multiplier should extend duration', () {
      final now = DateTime.now();
      gameState.startScoreMultiplier(duration: Duration(seconds: 5));
      final firstEndTime = gameState.multiplierEndTime;

      // Stack another multiplier
      gameState.startScoreMultiplier(duration: Duration(seconds: 5));
      final secondEndTime = gameState.multiplierEndTime;

      expect(secondEndTime, isNotNull);
      expect(
          secondEndTime!.isAfter(firstEndTime!), true); // Should be extended
      expect(gameState.scoreMultiplier, 3.0);
    });

    test('Multiplier expiry time should be in the future', () {
      gameState.startScoreMultiplier(duration: Duration(seconds: 10));
      final now = DateTime.now();
      expect(gameState.multiplierEndTime, isNotNull);
      expect(gameState.multiplierEndTime!.isAfter(now), true);
    });

    test('checkMultiplierExpiry should not reset unexpired multiplier', () {
      gameState.startScoreMultiplier(duration: Duration(seconds: 100));
      gameState.checkMultiplierExpiry();

      expect(gameState.scoreMultiplier, 3.0);
      expect(gameState.multiplierEndTime, isNotNull);
    });
  });

  group('Integration Tests',
      skip: 'Requires audio plugins not available in test environment', () {
    late GameState gameState;

    setUp(() {
      gameState = GameState.instance;
      // Reset demon spawn manager and multiplier without calling startGame
      gameState.demonSpawnManager.reset();
      gameState.scoreMultiplier = 1.0;
      gameState.multiplierEndTime = null;
    });

    test('Demon spawn manager should be initialized', () {
      expect(gameState.demonSpawnManager, isNotNull);
      expect(gameState.demonSpawnManager.spawnCount, 0);
    });

    test('Score multiplier should apply to points', () {
      final basePoints = 100;
      gameState.scoreMultiplier = 3.0;

      final multipliedPoints = (basePoints * gameState.scoreMultiplier).round();
      expect(multipliedPoints, 300);
    });

    test('Demon spawn should trigger at correct score', () {
      final shouldSpawn1 = gameState.demonSpawnManager.shouldSpawn(9999);
      expect(shouldSpawn1, false);

      final shouldSpawn2 = gameState.demonSpawnManager.shouldSpawn(10000);
      expect(shouldSpawn2, true);
    });

    test('Reset should clear demon spawn manager', () {
      gameState.demonSpawnManager.shouldSpawn(10000);
      gameState.demonSpawnManager.shouldSpawn(23100);
      expect(gameState.demonSpawnManager.spawnCount, 2);

      gameState.demonSpawnManager.reset();
      expect(gameState.demonSpawnManager.spawnCount, 0);
    });
  });

  group('Performance Tests', () {
    test('shouldSpawn should execute quickly', () {
      final manager = DemonSpawnManager();
      final stopwatch = Stopwatch()..start();

      for (int i = 0; i < 1000; i++) {
        manager.shouldSpawn(i * 100);
      }

      stopwatch.stop();
      expect(stopwatch.elapsedMilliseconds, lessThan(100));
    });

    test('getNextThreshold should execute quickly', () {
      final manager = DemonSpawnManager();
      final stopwatch = Stopwatch()..start();

      for (int i = 0; i < 10000; i++) {
        manager.getNextThreshold();
      }

      stopwatch.stop();
      expect(stopwatch.elapsedMilliseconds, lessThan(100));
    });

    test('checkMultiplierExpiry should execute quickly',
        skip: 'Requires audio plugins not available in test environment', () {
      final gameState = GameState.instance;
      gameState.startScoreMultiplier();

      final stopwatch = Stopwatch()..start();

      for (int i = 0; i < 10000; i++) {
        gameState.checkMultiplierExpiry();
      }

      stopwatch.stop();
      expect(stopwatch.elapsedMilliseconds, lessThan(100));
    });
  });

  group('Edge Cases', () {
    test('Negative score should not trigger spawn', () {
      final manager = DemonSpawnManager();
      final shouldSpawn = manager.shouldSpawn(-1000);
      expect(shouldSpawn, false);
    });

    test('Zero score should not trigger spawn', () {
      final manager = DemonSpawnManager();
      final shouldSpawn = manager.shouldSpawn(0);
      expect(shouldSpawn, false);
    });

    test('Very large score should trigger all spawns', () {
      final manager = DemonSpawnManager();
      final shouldSpawn = manager.shouldSpawn(999999999);
      expect(shouldSpawn, true);
      expect(manager.spawnCount, 1);
    });

    test('Multiplier with zero duration should expire immediately',
        skip: 'Requires audio plugins not available in test environment', () {
      final gameState = GameState.instance;
      // Reset multiplier state first
      gameState.scoreMultiplier = 1.0;
      gameState.multiplierEndTime = null;

      gameState.startScoreMultiplier(duration: Duration.zero);
      expect(gameState.scoreMultiplier, 3.0);

      gameState.checkMultiplierExpiry();
      expect(gameState.scoreMultiplier, 1.0);
    });

    test('State restore with invalid data should handle gracefully', () {
      final manager = DemonSpawnManager();
      manager.restoreState({'invalid': 'data'});
      expect(manager.spawnCount, 0);
    });
  });
}
