import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/tetromino.dart';
import '../game/rune_loadout.dart';

/// 遊戲狀態持久化工具類
/// 負責將遊戲狀態序列化到本地存儲，並在需要時恢復
class GamePersistence {
  static const String _gameStateKey = 'tetris_game_state';
  static const String _runeLoadoutKey = 'tetris_rune_loadout';
  static const int _stateVersion = 1;
  static const int _runeLoadoutVersion = 1;

  /// 顏色到整數的映射表 (用於序列化)
  static final Map<Color, int> _colorToInt = {
    const Color(0xFF00E5FF): 1, // cyberpunkPrimary - I
    const Color(0xFF0066FF): 2, // J
    const Color(0xFFFF2ED1): 3, // cyberpunkSecondary - L
    const Color(0xFFFCEE09): 4, // cyberpunkCaution - O
    const Color(0xFF00FF88): 5, // S
    const Color(0xFF8A2BE2): 6, // cyberpunkAccent - T
    const Color(0xFFFF0066): 7, // Z
  };

  /// 整數到顏色的映射表 (用於反序列化)
  static const Map<int, Color> _intToColor = {
    1: Color(0xFF00E5FF), // I
    2: Color(0xFF0066FF), // J
    3: Color(0xFFFF2ED1), // L
    4: Color(0xFFFCEE09), // O
    5: Color(0xFF00FF88), // S
    6: Color(0xFF8A2BE2), // T
    7: Color(0xFFFF0066), // Z
  };

  /// 保存遊戲狀態
  static Future<bool> saveGameState(GameStateData gameData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stateMap = {
        'version': _stateVersion,
        'gameData': _gameDataToMap(gameData),
      };
      final jsonString = jsonEncode(stateMap);
      return await prefs.setString(_gameStateKey, jsonString);
    } catch (e) {
      debugPrint('Failed to save game state: $e');
      return false;
    }
  }

  /// 載入遊戲狀態
  static Future<GameStateData?> loadGameState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_gameStateKey);
      if (jsonString == null) return null;

      final stateMap = jsonDecode(jsonString) as Map<String, dynamic>;
      final version = stateMap['version'] as int?;

      // 版本檢查
      if (version != _stateVersion) {
        debugPrint(
            'Game state version mismatch. Expected: $_stateVersion, Got: $version');
        return null;
      }

      final gameDataMap = stateMap['gameData'] as Map<String, dynamic>;
      return _gameDataFromMap(gameDataMap);
    } catch (e) {
      debugPrint('Failed to load game state: $e');
      return null;
    }
  }

  /// 清除保存的遊戲狀態
  static Future<bool> clearGameState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_gameStateKey);
    } catch (e) {
      debugPrint('Failed to clear game state: $e');
      return false;
    }
  }

  /// 檢查是否有保存的遊戲狀態
  static Future<bool> hasSavedState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_gameStateKey);
    } catch (e) {
      debugPrint('Failed to check saved state: $e');
      return false;
    }
  }

  /// 將遊戲狀態轉換為 Map
  static Map<String, dynamic> _gameDataToMap(GameStateData gameData) {
    return {
      'board': _boardToIntList(gameData.board),
      'currentTetromino': gameData.currentTetromino != null
          ? _tetrominoToMap(gameData.currentTetromino!)
          : null,
      'nextTetromino': gameData.nextTetromino != null
          ? _tetrominoToMap(gameData.nextTetromino!)
          : null,
      'nextTetrominos':
          gameData.nextTetrominos.map((t) => _tetrominoToMap(t)).toList(),
      'score': gameData.score,
      'highScore': gameData.highScore,
      'isGameOver': gameData.isGameOver,
      'isPaused': gameData.isPaused,
      'isGhostPieceEnabled': gameData.isGhostPieceEnabled,
      'marathonSystem': {
        'currentLevel': gameData.marathonCurrentLevel,
        'totalLinesCleared': gameData.marathonTotalLinesCleared,
        'linesInCurrentLevel': gameData.marathonLinesInCurrentLevel,
      },
      'scoringService': {
        'comboCount': gameData.scoringComboCount,
        'lastWasDifficultClear': gameData.scoringLastWasDifficultClear,
        'totalLinesCleared': gameData.scoringTotalLinesCleared,
        'maxCombo': gameData.scoringMaxCombo,
        'statistics': gameData.scoringStatistics,
      },
    };
  }

  /// 從 Map 還原遊戲狀態
  static GameStateData _gameDataFromMap(Map<String, dynamic> map) {
    final boardData = map['board'] as List<dynamic>;
    final board = _intListToBoard(boardData);

    final currentTetrominoData =
        map['currentTetromino'] as Map<String, dynamic>?;
    final nextTetrominoData = map['nextTetromino'] as Map<String, dynamic>?;
    final nextTetrominosData = map['nextTetrominos'] as List<dynamic>;

    final marathonData = map['marathonSystem'] as Map<String, dynamic>;
    final scoringData = map['scoringService'] as Map<String, dynamic>;
    final scoringStats =
        Map<String, int>.from(scoringData['statistics'] as Map);

    return GameStateData(
      board: board,
      currentTetromino: currentTetrominoData != null
          ? _tetrominoFromMap(currentTetrominoData)
          : null,
      nextTetromino: nextTetrominoData != null
          ? _tetrominoFromMap(nextTetrominoData)
          : null,
      nextTetrominos: nextTetrominosData
          .cast<Map<String, dynamic>>()
          .map((data) => _tetrominoFromMap(data))
          .toList(),
      score: map['score'] as int,
      highScore: map['highScore'] as int,
      isGameOver: map['isGameOver'] as bool,
      isPaused: map['isPaused'] as bool,
      isGhostPieceEnabled: map['isGhostPieceEnabled'] as bool,
      marathonCurrentLevel: marathonData['currentLevel'] as int,
      marathonTotalLinesCleared: marathonData['totalLinesCleared'] as int,
      marathonLinesInCurrentLevel: marathonData['linesInCurrentLevel'] as int,
      scoringComboCount: scoringData['comboCount'] as int,
      scoringLastWasDifficultClear:
          scoringData['lastWasDifficultClear'] as bool,
      scoringTotalLinesCleared: scoringData['totalLinesCleared'] as int,
      scoringMaxCombo: scoringData['maxCombo'] as int,
      scoringStatistics: scoringStats,
    );
  }

  /// 將棋盤轉換為整數列表
  static List<List<int>> _boardToIntList(List<List<Color?>> board) {
    return board
        .map((row) => row
            .map((color) => color == null ? -1 : (_colorToInt[color] ?? 0))
            .toList())
        .toList();
  }

  /// 從整數列表還原棋盤
  static List<List<Color?>> _intListToBoard(List<dynamic> intList) {
    return intList
        .map((row) => (row as List<dynamic>)
            .map((colorInt) =>
                colorInt == -1 ? null : _intToColor[colorInt as int])
            .toList())
        .toList();
  }

  /// 將 Tetromino 轉換為 Map
  static Map<String, dynamic> _tetrominoToMap(Tetromino tetromino) {
    return {
      'type': tetromino.type.index,
      'x': tetromino.x,
      'y': tetromino.y,
      'rotation': tetromino.rotation,
    };
  }

  /// 從 Map 還原 Tetromino
  static Tetromino _tetrominoFromMap(Map<String, dynamic> map) {
    final type = TetrominoType.values[map['type'] as int];
    final tetromino = Tetromino.fromType(type, 10); // 假設寬度為10
    tetromino.x = map['x'] as int;
    tetromino.y = map['y'] as int;
    tetromino.rotation = map['rotation'] as int;

    // 需要根據旋轉狀態重新計算 shape
    // 這裡簡化處理，假設會在載入後重新計算正確的 shape
    return tetromino;
  }

  /// 保存符文配置
  static Future<bool> saveRuneLoadout(RuneLoadout loadout) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final loadoutMap = {
        'version': _runeLoadoutVersion,
        'loadout': loadout.toJson(),
      };
      final jsonString = jsonEncode(loadoutMap);
      final result = await prefs.setString(_runeLoadoutKey, jsonString);
      debugPrint('GamePersistence: Rune loadout saved - $loadout');
      return result;
    } catch (e) {
      debugPrint('Failed to save rune loadout: $e');
      return false;
    }
  }

  /// 載入符文配置
  static Future<RuneLoadout?> loadRuneLoadout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_runeLoadoutKey);
      if (jsonString == null) {
        debugPrint('GamePersistence: No saved rune loadout found');
        return null;
      }

      final loadoutMap = jsonDecode(jsonString) as Map<String, dynamic>;
      final version = loadoutMap['version'] as int?;

      // 版本檢查
      if (version != _runeLoadoutVersion) {
        debugPrint(
            'Rune loadout version mismatch. Expected: $_runeLoadoutVersion, Got: $version');
        return null;
      }

      final loadoutData = loadoutMap['loadout'] as Map<String, dynamic>;
      final loadout = RuneLoadout.fromJson(loadoutData);
      debugPrint('GamePersistence: Rune loadout loaded - $loadout');
      return loadout;
    } catch (e) {
      debugPrint('Failed to load rune loadout: $e');
      return null;
    }
  }

  /// 清除保存的符文配置
  static Future<bool> clearRuneLoadout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final result = await prefs.remove(_runeLoadoutKey);
      debugPrint('GamePersistence: Rune loadout cleared');
      return result;
    } catch (e) {
      debugPrint('Failed to clear rune loadout: $e');
      return false;
    }
  }

  /// 檢查是否有保存的符文配置
  static Future<bool> hasSavedRuneLoadout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_runeLoadoutKey);
    } catch (e) {
      debugPrint('Failed to check saved rune loadout: $e');
      return false;
    }
  }
}

/// 遊戲狀態資料結構
/// 用於序列化和反序列化的數據載體
class GameStateData {
  final List<List<Color?>> board;
  final Tetromino? currentTetromino;
  final Tetromino? nextTetromino;
  final List<Tetromino> nextTetrominos;
  final int score;
  final int highScore;
  final bool isGameOver;
  final bool isPaused;
  final bool isGhostPieceEnabled;

  // Marathon System 狀態
  final int marathonCurrentLevel;
  final int marathonTotalLinesCleared;
  final int marathonLinesInCurrentLevel;

  // Scoring Service 狀態
  final int scoringComboCount;
  final bool scoringLastWasDifficultClear;
  final int scoringTotalLinesCleared;
  final int scoringMaxCombo;
  final Map<String, int> scoringStatistics;

  const GameStateData({
    required this.board,
    required this.currentTetromino,
    required this.nextTetromino,
    required this.nextTetrominos,
    required this.score,
    required this.highScore,
    required this.isGameOver,
    required this.isPaused,
    required this.isGhostPieceEnabled,
    required this.marathonCurrentLevel,
    required this.marathonTotalLinesCleared,
    required this.marathonLinesInCurrentLevel,
    required this.scoringComboCount,
    required this.scoringLastWasDifficultClear,
    required this.scoringTotalLinesCleared,
    required this.scoringMaxCombo,
    required this.scoringStatistics,
  });

  /// 檢查遊戲狀態是否有效 (非新遊戲狀態)
  bool isValidGameInProgress() {
    // 嚴格檢查：必須同時滿足以下條件才認為是有效的進行中遊戲
    return !isGameOver &&
        currentTetromino != null &&
        nextTetromino != null &&
        (score > 0 || marathonTotalLinesCleared > 0 || !_isBoardEmpty());
  }

  /// 檢查棋盤是否為空
  bool _isBoardEmpty() {
    for (final row in board) {
      for (final cell in row) {
        if (cell != null) return false;
      }
    }
    return true;
  }

  @override
  String toString() {
    return 'GameStateData(score: $score, level: $marathonCurrentLevel, '
        'lines: $marathonTotalLinesCleared, gameOver: $isGameOver, '
        'paused: $isPaused, hasCurrentPiece: ${currentTetromino != null})';
  }
}
