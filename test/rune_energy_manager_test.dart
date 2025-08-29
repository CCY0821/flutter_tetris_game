import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tetris_game/game/rune_energy_manager.dart';

void main() {
  group('RuneEnergyManager Tests', () {
    late RuneEnergyManager manager;

    setUp(() {
      manager = RuneEnergyManager();
    });

    group('Basic Functionality', () {
      test('初始状态应为空', () {
        expect(manager.currentBars, equals(0));
        expect(manager.currentScore, equals(0));
        expect(manager.currentPartialRatio, equals(0.0));
        expect(manager.isMaxEnergy, isFalse);
      });

      test('单行消除应产生10分能量', () {
        manager.addScore(1);
        expect(manager.currentScore, equals(10));
        expect(manager.currentBars, equals(0));
        expect(manager.currentPartialRatio, closeTo(0.1, 0.01)); // 10/100 = 10%
      });

      test('100分应产生1格能量', () {
        manager.addScore(10); // 10行 = 100分
        expect(manager.currentScore, equals(100));
        expect(manager.currentBars, equals(1));
        expect(manager.currentPartialRatio, equals(0.0));
      });

      test('130分应为1格+30%进度', () {
        manager.addScore(13); // 13行 = 130分
        expect(manager.currentScore, equals(130));
        expect(manager.currentBars, equals(1));
        expect(manager.currentPartialRatio, closeTo(0.3, 0.01)); // 30/100 = 30%
      });
    });

    group('Multiple Lines Clearing', () {
      test('多行消除应正确累积', () {
        manager.addScore(2); // 20分
        manager.addScore(3); // 30分
        manager.addScore(5); // 50分

        expect(manager.currentScore, equals(100)); // 总计100分
        expect(manager.currentBars, equals(1));
        expect(manager.currentPartialRatio, equals(0.0));
      });

      test('连续消除应保留溢出进度', () {
        manager.addScore(8); // 80分
        expect(manager.currentPartialRatio, closeTo(0.8, 0.01));

        manager.addScore(3); // +30分 = 110分总计
        expect(manager.currentBars, equals(1));
        expect(manager.currentPartialRatio, closeTo(0.1, 0.01)); // 10分剩余
      });
    });

    group('Energy Limits', () {
      test('3格为上限', () {
        manager.addScore(50); // 500分，远超3格上限

        expect(manager.currentBars, equals(3)); // 最多3格
        expect(manager.currentScore, equals(500)); // 分数正常累积
        expect(manager.isMaxEnergy, isTrue);
        expect(manager.currentPartialRatio, equals(0.0)); // 满格时不显示进度
      });

      test('超出上限时进度为0', () {
        manager.addScore(32); // 320分 = 3格满+20分剩余

        expect(manager.currentBars, equals(3));
        expect(manager.currentPartialRatio, equals(0.0)); // 满格不显示进度
      });
    });

    group('Energy Consumption', () {
      test('消耗前检查是否有足够能量', () {
        manager.addScore(15); // 150分 = 1格

        expect(manager.canConsume(1), isTrue);
        expect(manager.canConsume(2), isFalse);
        expect(manager.canConsume(0), isFalse); // 无效输入
        expect(manager.canConsume(-1), isFalse); // 无效输入
      });

      test('成功消耗能量应减少分数和格数', () {
        manager.addScore(25); // 250分 = 2格

        bool consumed = manager.consumeBars(1);
        expect(consumed, isTrue);
        expect(manager.currentScore, equals(150)); // 250 - 100
        expect(manager.currentBars, equals(1));
      });

      test('消耗失败时状态不变', () {
        manager.addScore(5); // 50分 = 0格

        bool consumed = manager.consumeBars(1);
        expect(consumed, isFalse);
        expect(manager.currentScore, equals(50)); // 未改变
        expect(manager.currentBars, equals(0)); // 未改变
      });

      test('消耗多格能量', () {
        manager.addScore(35); // 350分 = 3格

        bool consumed = manager.consumeBars(2);
        expect(consumed, isTrue);
        expect(manager.currentScore, equals(150)); // 350 - 200
        expect(manager.currentBars, equals(1));
      });
    });

    group('Reset Functionality', () {
      test('重置应清空所有状态', () {
        manager.addScore(20); // 设置一些初始状态

        manager.reset();

        expect(manager.currentBars, equals(0));
        expect(manager.currentScore, equals(0));
        expect(manager.currentPartialRatio, equals(0.0));
        expect(manager.isMaxEnergy, isFalse);
      });
    });

    group('Status and Serialization', () {
      test('getStatus应返回正确快照', () {
        manager.addScore(17); // 170分 = 1格 + 70%

        final status = manager.getStatus();
        expect(status.currentBars, equals(1));
        expect(status.maxBars, equals(3));
        expect(status.currentScore, equals(170));
        expect(status.partialRatio, closeTo(0.7, 0.01));
        expect(status.isMaxEnergy, isFalse);
      });

      test('序列化和反序列化应保持状态', () {
        manager.addScore(23); // 230分 = 2格 + 30%

        final json = manager.toJson();
        final newManager = RuneEnergyManager();
        newManager.fromJson(json);

        expect(newManager.currentBars, equals(manager.currentBars));
        expect(newManager.currentScore, equals(manager.currentScore));
        expect(newManager.currentPartialRatio,
            closeTo(manager.currentPartialRatio, 0.01));
      });

      test('反序列化应验证数据有效性', () {
        final invalidData = {
          'currentScore': -50, // 无效负分数
          'currentBars': 5, // 超出上限
        };

        manager.fromJson(invalidData);

        expect(manager.currentScore, equals(0)); // 修正为0
        expect(manager.currentBars, equals(3)); // 限制为最大值
      });
    });

    group('Event Callbacks', () {
      test('能量变化时应触发回调', () {
        bool callbackTriggered = false;
        manager.setOnEnergyChanged(() {
          callbackTriggered = true;
        });

        manager.addScore(10); // 产生1格能量
        expect(callbackTriggered, isTrue);
      });

      test('满格时应触发特殊回调', () {
        bool fullCallbackTriggered = false;
        manager.setOnEnergyFull(() {
          fullCallbackTriggered = true;
        });

        manager.addScore(30); // 达到3格
        expect(fullCallbackTriggered, isTrue);
      });

      test('已经满格时不应重复触发满格回调', () {
        int fullCallbackCount = 0;
        manager.setOnEnergyFull(() {
          fullCallbackCount++;
        });

        manager.addScore(30); // 第一次达到满格
        manager.addScore(5); // 继续添加但已经满格

        expect(fullCallbackCount, equals(1)); // 只触发一次
      });
    });

    group('Edge Cases', () {
      test('添加0行或负数行不应改变状态', () {
        manager.addScore(0);
        expect(manager.currentScore, equals(0));

        manager.addScore(-5);
        expect(manager.currentScore, equals(0));
      });

      test('toString应返回有用信息', () {
        manager.addScore(15); // 150分 = 1格 + 50%

        final str = manager.toString();
        expect(str, contains('1/3')); // 格数信息
        expect(str, contains('150')); // 分数信息
        expect(str, contains('50.0')); // 进度信息
      });
    });
  });
}
