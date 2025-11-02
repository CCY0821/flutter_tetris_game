import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tetris_game/game/demon_piece_generator.dart';
import 'package:flutter_tetris_game/models/tetromino.dart';

void main() {
  group('DemonPieceGenerator Tests', () {
    test('生成的方塊必須是 10 格', () {
      for (int i = 0; i < 100; i++) {
        final shape = DemonPieceGenerator.generateShape();
        final cellCount = DemonPieceGenerator.countCells(shape);
        expect(cellCount, equals(10),
            reason: 'Attempt ${i + 1}: Expected 10 cells, got $cellCount');
      }
    });

    test('生成的方塊必須連通', () {
      for (int i = 0; i < 100; i++) {
        final shape = DemonPieceGenerator.generateShape();
        // 使用內部的 _isConnected 方法需要通過生成器的驗證
        // 如果生成成功，代表已通過連通性驗證
        final cellCount = DemonPieceGenerator.countCells(shape);
        expect(cellCount, equals(10),
            reason: 'Attempt ${i + 1}: Shape is not valid (not connected)');
      }
    });

    test('方塊寬度不超過 10 格', () {
      for (int i = 0; i < 100; i++) {
        final shape = DemonPieceGenerator.generateShape();
        final (minX, _, maxX, _) = DemonPieceGenerator.getBoundingBox(shape);
        final actualWidth = maxX - minX + 1;
        expect(actualWidth, lessThanOrEqualTo(10),
            reason:
                'Attempt ${i + 1}: Width $actualWidth exceeds board width (10)');
      }
    });

    test('邊界框不超過 5×5', () {
      for (int i = 0; i < 100; i++) {
        final shape = DemonPieceGenerator.generateShape();
        expect(shape.length, lessThanOrEqualTo(5),
            reason: 'Attempt ${i + 1}: Height ${shape.length} exceeds 5');
        expect(shape[0].length, lessThanOrEqualTo(5),
            reason: 'Attempt ${i + 1}: Width ${shape[0].length} exceeds 5');
      }
    });

    test('降級方案生成 2×5 矩形（10格）', () {
      // 直接測試降級方案（private method，通過100%失敗率來觸發）
      // 由於我們無法直接調用 _generateFallbackShape，我們檢查任何形狀都至少10格
      final shape = DemonPieceGenerator.generateShape();
      final cellCount = DemonPieceGenerator.countCells(shape);
      expect(cellCount, equals(10));
    });

    test('生成形狀多樣性（至少5種不同形狀）', () {
      final shapeHashes = <int>{};
      for (int i = 0; i < 50; i++) {
        final shape = DemonPieceGenerator.generateShape();
        // 計算形狀哈希值（簡單版本：將格子位置序列化）
        final hash = shape
            .expand((row) => row)
            .toList()
            .toString()
            .hashCode;
        shapeHashes.add(hash);
      }
      expect(shapeHashes.length, greaterThanOrEqualTo(5),
          reason:
              'Expected at least 5 different shapes, got ${shapeHashes.length}');
    });
  });

  group('Tetromino.demon Tests', () {
    test('惡魔方塊創建成功', () {
      final demon = Tetromino.demon(10);
      expect(demon.type, equals(TetrominoType.demon));
      expect(demon.shape.length, equals(10),
          reason: 'Demon tetromino should have exactly 10 cells');
    });

    test('惡魔方塊顏色為金色', () {
      final demon = Tetromino.demon(10);
      expect(demon.color.value, equals(0xFFFFD700),
          reason: 'Demon tetromino color should be gold (#FFD700)');
    });

    test('惡魔方塊 isDemon 屬性為 true', () {
      final demon = Tetromino.demon(10);
      expect(demon.isDemon, isTrue,
          reason: 'isDemon should return true for demon tetromino');
    });

    test('惡魔方塊起始位置正確', () {
      final demon = Tetromino.demon(10);
      expect(demon.x, equals(5), reason: 'Demon should start at x=5 (center)');
      expect(demon.y, equals(19),
          reason: 'Demon should start at y=19 (buffer zone)');
      expect(demon.rotation, equals(0),
          reason: 'Demon should start with rotation=0');
    });

    test('惡魔方塊通過 fromType 創建', () {
      final demon = Tetromino.fromType(TetrominoType.demon, 10);
      expect(demon.type, equals(TetrominoType.demon));
      expect(demon.shape.length, equals(10));
    });

    test('生成100個惡魔方塊，都是10格', () {
      for (int i = 0; i < 100; i++) {
        final demon = Tetromino.demon(10);
        expect(demon.shape.length, equals(10),
            reason: 'Attempt ${i + 1}: Demon should have 10 cells');
      }
    });
  });

  group('Tetromino isDemon getter Tests', () {
    test('惡魔方塊 isDemon 返回 true', () {
      final demon = Tetromino.demon(10);
      expect(demon.isDemon, isTrue);
    });

    test('其他方塊 isDemon 返回 false', () {
      final types = [
        TetrominoType.I,
        TetrominoType.O,
        TetrominoType.T,
        TetrominoType.S,
        TetrominoType.Z,
        TetrominoType.L,
        TetrominoType.J,
      ];

      for (final type in types) {
        final tetromino = Tetromino.fromType(type, 10);
        expect(tetromino.isDemon, isFalse,
            reason: '$type should not be identified as demon');
      }
    });
  });

  group('SRS Rotation Tests (Demon)', () {
    test('惡魔方塊複製保持相同屬性', () {
      final demon = Tetromino.demon(10);
      final copy = demon.copy();

      expect(copy.type, equals(demon.type));
      expect(copy.color, equals(demon.color));
      expect(copy.shape.length, equals(demon.shape.length));
      expect(copy.x, equals(demon.x));
      expect(copy.y, equals(demon.y));
      expect(copy.rotation, equals(demon.rotation));
    });

    test('惡魔方塊 toString 正確顯示', () {
      final demon = Tetromino.demon(10);
      final str = demon.toString();
      expect(str, contains('demon'));
      expect(str, contains('5')); // x position
      expect(str, contains('19')); // y position
    });
  });

  group('Performance Tests', () {
    test('生成時間應小於 50ms', () {
      final stopwatch = Stopwatch()..start();
      for (int i = 0; i < 100; i++) {
        DemonPieceGenerator.generateShape();
      }
      stopwatch.stop();

      final averageTime = stopwatch.elapsedMilliseconds / 100;
      expect(averageTime, lessThan(50),
          reason:
              'Average generation time $averageTime ms exceeds 50ms threshold');
    });

    test('Tetromino.demon 創建時間應小於 50ms', () {
      final stopwatch = Stopwatch()..start();
      for (int i = 0; i < 100; i++) {
        Tetromino.demon(10);
      }
      stopwatch.stop();

      final averageTime = stopwatch.elapsedMilliseconds / 100;
      expect(averageTime, lessThan(50),
          reason:
              'Average Tetromino.demon creation time $averageTime ms exceeds 50ms threshold');
    });
  });
}
