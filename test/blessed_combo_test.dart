import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tetris_game/services/scoring_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Blessed Combo Tests', () {
    late ScoringService scoringService;

    setUp(() {
      scoringService = ScoringService();
    });

    test('ScoreOrigin enum should work correctly', () {
      expect(ScoreOrigin.natural, isNotNull);
      expect(ScoreOrigin.spell, isNotNull);
    });

    test('BlessedComboModifier should multiply natural scores by 3', () {
      // Create modifier with active state
      bool isActive = true;
      final modifier = BlessedComboModifier(() => isActive);

      // Test natural score multiplication
      double naturalScore = modifier.modifyScore(ScoreOrigin.natural, 100.0);
      expect(naturalScore, equals(300.0));

      // Test spell score remains unchanged
      double spellScore = modifier.modifyScore(ScoreOrigin.spell, 100.0);
      expect(spellScore, equals(100.0));

      // Test inactive state
      isActive = false;
      double inactiveScore = modifier.modifyScore(ScoreOrigin.natural, 100.0);
      expect(inactiveScore, equals(100.0));
    });

    test('ScoringService should apply modifiers correctly', () {
      // Add blessed combo modifier
      bool isActive = true;
      final modifier = BlessedComboModifier(() => isActive);
      scoringService.addModifier(modifier);

      // Test natural line clear with modifier
      final result = scoringService.calculateLineScore(
        linesCleared: 1,
        currentLevel: 1,
        origin: ScoreOrigin.natural,
      );

      expect(result.points, equals(300)); // 100 * 1 * 3 = 300

      // Test spell line clear (should not be affected by blessed combo modifier)
      final spellResult = scoringService.calculateLineScore(
        linesCleared: 1,
        currentLevel: 1,
        origin: ScoreOrigin.spell,
      );

      // Spell clears get combo bonus (50 * 1 * 1) but no blessed combo modifier
      expect(spellResult.points, equals(150)); // 100 + 50 = 150
    });

    test('Modifier system should handle multiple modifiers', () {
      bool modifier1Active = true;
      bool modifier2Active = true;

      final modifier1 = BlessedComboModifier(() => modifier1Active);
      // Create a second test modifier that doubles scores
      final modifier2 = TestScoreModifier(() => modifier2Active, 2.0);

      scoringService.addModifier(modifier1);
      scoringService.addModifier(modifier2);

      // Test combined effect: 100 * 3 * 2 = 600
      final result = scoringService.calculateLineScore(
        linesCleared: 1,
        currentLevel: 1,
        origin: ScoreOrigin.natural,
      );

      expect(result.points, equals(600));
    });
  });
}

/// Test score modifier for testing purposes
class TestScoreModifier extends ScoreModifier {
  final bool Function() _isActiveCallback;
  final double _multiplier;

  TestScoreModifier(this._isActiveCallback, this._multiplier);

  @override
  double modifyScore(ScoreOrigin origin, double baseScore) {
    if (origin == ScoreOrigin.natural && isActive) {
      return baseScore * _multiplier;
    }
    return baseScore;
  }

  @override
  bool get isActive => _isActiveCallback();

  @override
  String get description => 'Test Modifier (×$_multiplier)';
}
