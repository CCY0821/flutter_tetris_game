import 'package:shared_preferences/shared_preferences.dart';

class HighScoreService {
  static const String _highScoreKey = 'tetris_high_score';
  static HighScoreService? _instance;
  SharedPreferences? _prefs;
  int _cachedHighScore = 0;

  HighScoreService._internal();

  static HighScoreService get instance {
    _instance ??= HighScoreService._internal();
    return _instance!;
  }

  /// 初始化服務並載入高分
  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
    _cachedHighScore = _prefs!.getInt(_highScoreKey) ?? 0;
  }

  /// 獲取當前高分（同步方法，使用快取值）
  int get highScore => _cachedHighScore;

  /// 檢查並更新高分（如果新分數更高）
  Future<bool> updateHighScore(int newScore) async {
    if (newScore > _cachedHighScore) {
      _cachedHighScore = newScore;
      await _prefs?.setInt(_highScoreKey, newScore);
      return true; // 返回 true 表示創造了新紀錄
    }
    return false; // 返回 false 表示沒有破紀錄
  }

  /// 重置高分（用於測試或重置功能）
  Future<void> resetHighScore() async {
    _cachedHighScore = 0;
    await _prefs?.remove(_highScoreKey);
  }

  /// 直接設置高分（用於特殊情況）
  Future<void> setHighScore(int score) async {
    _cachedHighScore = score;
    await _prefs?.setInt(_highScoreKey, score);
  }
}