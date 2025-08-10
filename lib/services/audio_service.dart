import 'package:audioplayers/audioplayers.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioPlayer _backgroundMusicPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer();
  
  bool _isMusicEnabled = true;
  bool _isSfxEnabled = true;
  double _musicVolume = 0.5;
  double _sfxVolume = 0.7;

  // Getters
  bool get isMusicEnabled => _isMusicEnabled;
  bool get isSfxEnabled => _isSfxEnabled;
  double get musicVolume => _musicVolume;
  double get sfxVolume => _sfxVolume;

  // 初始化音頻服務
  Future<void> initialize() async {
    await _backgroundMusicPlayer.setVolume(_musicVolume);
    await _sfxPlayer.setVolume(_sfxVolume);
  }

  // 播放背景音樂
  Future<void> playBackgroundMusic() async {
    if (!_isMusicEnabled) return;
    
    try {
      print('Attempting to play background music...');
      print('Music enabled: $_isMusicEnabled');
      // 先設定循環模式，再播放
      await _backgroundMusicPlayer.setReleaseMode(ReleaseMode.loop);
      await _backgroundMusicPlayer.play(
        AssetSource('audio/background_music.mp3'),
      );
      print('Background music started successfully!');
    } catch (e) {
      print('Error playing background music: $e'); // 暫時開啟除錯
      print('Audio file path: assets/audio/background_music.mp3');
      print('Music enabled: $_isMusicEnabled');
      // 如果音樂檔案不存在，使用預設的靜音處理
    }
  }

  // 停止背景音樂
  Future<void> stopBackgroundMusic() async {
    await _backgroundMusicPlayer.stop();
  }

  // 暫停背景音樂
  Future<void> pauseBackgroundMusic() async {
    await _backgroundMusicPlayer.pause();
  }

  // 恢復背景音樂
  Future<void> resumeBackgroundMusic() async {
    if (!_isMusicEnabled) return;
    await _backgroundMusicPlayer.resume();
  }

  // 播放音效
  Future<void> playSoundEffect(String soundName) async {
    if (!_isSfxEnabled) return;
    
    try {
      await _sfxPlayer.play(AssetSource('audio/$soundName.mp3'));
    } catch (e) {
      // print('Error playing sound effect $soundName: $e'); // 生產環境中移除
    }
  }

  // 音樂開關
  Future<void> toggleMusic() async {
    _isMusicEnabled = !_isMusicEnabled;
    if (_isMusicEnabled) {
      await playBackgroundMusic();
    } else {
      await pauseBackgroundMusic();
    }
  }

  // 音效開關
  void toggleSfx() {
    _isSfxEnabled = !_isSfxEnabled;
  }

  // 設定音樂音量
  Future<void> setMusicVolume(double volume) async {
    _musicVolume = volume.clamp(0.0, 1.0);
    await _backgroundMusicPlayer.setVolume(_musicVolume);
  }

  // 設定音效音量
  Future<void> setSfxVolume(double volume) async {
    _sfxVolume = volume.clamp(0.0, 1.0);
    await _sfxPlayer.setVolume(_sfxVolume);
  }

  // 清理資源
  Future<void> dispose() async {
    await _backgroundMusicPlayer.dispose();
    await _sfxPlayer.dispose();
  }
}