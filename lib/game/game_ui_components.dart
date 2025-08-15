import 'package:flutter/material.dart';
import '../models/tetromino.dart';
import '../services/audio_service.dart';
import '../services/scoring_service.dart';
import '../theme/game_theme.dart';
import 'marathon_system.dart';
import '../widgets/marathon_info_panel.dart';

class GameUIComponents {
  static const double cellSize = 20;

  /// 顯示得分詳細資訊面板
  static Widget scoringInfoPanel(ScoringResult? scoringResult) {
    if (scoringResult == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: GameTheme.panelGradient,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: GameTheme.boardBorder,
          width: 1,
        ),
        boxShadow: GameTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'LAST SCORE',
                style: GameTheme.accentStyle.copyWith(fontSize: 10),
              ),
              Text(
                '+${scoringResult.points}',
                style: GameTheme.accentStyle.copyWith(
                  fontSize: 12,
                  color: GameTheme.highlight,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (scoringResult.achievements.isNotEmpty) ...[
            const SizedBox(height: 4),
            ...scoringResult.achievements.map((achievement) => Text(
                  achievement,
                  style: GameTheme.accentStyle.copyWith(fontSize: 9, color: Colors.white70),
                )),
          ],
          if (scoringResult.comboCount > 0) ...[
            const SizedBox(height: 2),
            Text(
              'Combo x${scoringResult.comboCount}',
              style: GameTheme.accentStyle.copyWith(
                fontSize: 9,
                color: GameTheme.accentBlue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 顯示連續消除（Combo）和 Back-to-Back 狀態
  static Widget gameStatusIndicators({
    required int combo,
    required bool isBackToBackReady,
  }) {
    if (combo == 0 && !isBackToBackReady) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: GameTheme.panelGradient,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: GameTheme.boardBorder,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (combo > 0) ...[
            Icon(
              Icons.flash_on,
              color: GameTheme.accentBlue,
              size: 16,
            ),
            const SizedBox(width: 2),
            Text(
              'COMBO ${combo}',
              style: GameTheme.accentStyle.copyWith(
                fontSize: 10,
                color: GameTheme.accentBlue,
              ),
            ),
          ],
          if (combo > 0 && isBackToBackReady) const SizedBox(width: 8),
          if (isBackToBackReady) ...[
            Icon(
              Icons.repeat,
              color: GameTheme.highlight,
              size: 16,
            ),
            const SizedBox(width: 2),
            Text(
              'B2B',
              style: GameTheme.accentStyle.copyWith(
                fontSize: 10,
                color: GameTheme.highlight,
              ),
            ),
          ],
        ],
      ),
    );
  }

  static Widget nextBlockPreview(Tetromino? nextTetromino) {
    const previewSize = 8;
    const offsetX = 2;
    const offsetY = 2;

    final preview = List.generate(
      previewSize,
      (_) => List.generate(previewSize, (_) => null as Color?),
    );

    if (nextTetromino != null) {
      for (final p in nextTetromino.shape) {
        int px = p.dx.toInt() + offsetX;
        int py = p.dy.toInt() + offsetY;
        if (py >= 0 && py < previewSize && px >= 0 && px < previewSize) {
          preview[py][px] = nextTetromino.color;
        }
      }
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: GameTheme.panelGradient,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: GameTheme.boardBorder,
          width: 2,
        ),
        boxShadow: GameTheme.cardShadow,
      ),
      child: Column(
        children: [
          Text(
            'NEXT',
            style: GameTheme.accentStyle.copyWith(fontSize: 12),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: GameTheme.gameBoardBg.withOpacity(0.7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: preview
                  .map((row) => Row(
                        children: row
                            .map(
                              (c) => Container(
                                width: cellSize * 0.8,
                                height: cellSize * 0.8,
                                margin: const EdgeInsets.all(0.5),
                                decoration: BoxDecoration(
                                  color: c ?? Colors.transparent,
                                  borderRadius: BorderRadius.circular(2),
                                  border: c != null
                                      ? Border.all(
                                          color: Colors.white.withOpacity(0.2),
                                          width: 0.5,
                                        )
                                      : null,
                                ),
                              ),
                            )
                            .toList(),
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  static Widget infoBox(String text, {String? label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: GameTheme.panelGradient,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: GameTheme.boardBorder,
          width: 1,
        ),
        boxShadow: GameTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null) ...[
            Text(
              label,
              style: GameTheme.subtitleStyle.copyWith(fontSize: 11),
            ),
            const SizedBox(height: 4),
          ],
          Text(
            text,
            style: GameTheme.accentStyle.copyWith(fontSize: 18),
          ),
        ],
      ),
    );
  }

  static Widget overlayText(String text, Color color) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.8),
              Colors.black.withOpacity(0.9),
              Colors.black.withOpacity(0.8),
            ],
          ),
        ),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withOpacity(0.1),
                  color.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: color.withOpacity(0.5),
                width: 2,
              ),
            ),
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 42,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.8),
                    blurRadius: 8,
                    offset: const Offset(2, 2),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Widget audioControlButton() {
    final audioService = AudioService();
    return StatefulBuilder(
      builder: (context, setState) {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: GameTheme.panelGradient,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: GameTheme.boardBorder,
              width: 1,
            ),
            boxShadow: GameTheme.cardShadow,
          ),
          child: Column(
            children: [
              Text(
                'AUDIO',
                style: GameTheme.accentStyle.copyWith(fontSize: 12),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: audioService.isMusicEnabled
                          ? GameTheme.buttonPrimary.withOpacity(0.8)
                          : GameTheme.gridLine,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      onPressed: () async {
                        await audioService.toggleMusic();
                        setState(() {});
                      },
                      icon: Icon(
                        audioService.isMusicEnabled
                            ? Icons.music_note
                            : Icons.music_off,
                        color: Colors.white,
                        size: 20,
                      ),
                      tooltip:
                          audioService.isMusicEnabled ? '關閉音樂 (M)' : '開啟音樂 (M)',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: audioService.isSfxEnabled
                          ? GameTheme.buttonPrimary.withOpacity(0.8)
                          : GameTheme.gridLine,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      onPressed: () {
                        audioService.toggleSfx();
                        setState(() {});
                      },
                      icon: Icon(
                        audioService.isSfxEnabled
                            ? Icons.volume_up
                            : Icons.volume_off,
                        color: Colors.white,
                        size: 20,
                      ),
                      tooltip:
                          audioService.isSfxEnabled ? '關閉音效 (S)' : '開啟音效 (S)',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () async {
                  await audioService.playBackgroundMusic();
                  setState(() {});
                },
                style: GameTheme.secondaryButtonStyle.copyWith(
                  minimumSize: MaterialStateProperty.all(const Size(120, 32)),
                  padding: MaterialStateProperty.all(
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.play_arrow, size: 16),
                    const SizedBox(width: 4),
                    Text('播放', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Ghost piece 控制按鈕
  static Widget ghostPieceControlButton(bool isEnabled, VoidCallback onToggle) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: GameTheme.panelGradient,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: GameTheme.boardBorder,
          width: 1,
        ),
        boxShadow: GameTheme.cardShadow,
      ),
      child: Column(
        children: [
          Text(
            'GHOST',
            style: GameTheme.accentStyle.copyWith(fontSize: 12),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: isEnabled
                  ? GameTheme.buttonPrimary.withOpacity(0.8)
                  : GameTheme.gridLine,
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              onPressed: onToggle,
              icon: Icon(
                isEnabled ? Icons.visibility : Icons.visibility_off,
                color: Colors.white,
                size: 20,
              ),
              tooltip: isEnabled ? '隱藏Ghost Piece (G)' : '顯示Ghost Piece (G)',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isEnabled ? 'ON' : 'OFF',
            style: TextStyle(
              fontSize: 10,
              color: isEnabled ? GameTheme.highlight : GameTheme.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// 控制說明資訊框
  static Widget controlHelpButton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: GameTheme.panelGradient,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: GameTheme.boardBorder,
          width: 1,
        ),
        boxShadow: GameTheme.cardShadow,
      ),
      child: Column(
        children: [
          Text(
            'CONTROLS',
            style: GameTheme.accentStyle.copyWith(fontSize: 12),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: GameTheme.buttonPrimary.withOpacity(0.8),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              onPressed: () => _showControlHelp(context),
              icon: const Icon(
                Icons.help_outline,
                color: Colors.white,
                size: 20,
              ),
              tooltip: '顯示控制說明 (H)',
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'HELP',
            style: TextStyle(
              fontSize: 10,
              color: GameTheme.highlight,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// 顯示控制說明對話框
  static void _showControlHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: GameTheme.gameBoardBg,
          title: Text(
            '🎮 遊戲控制說明',
            style: GameTheme.titleStyle.copyWith(fontSize: 20),
          ),
          content: Container(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildControlSection(
                    '⌨️ 鍵盤控制',
                    [
                      '← →  移動方塊',
                      '↑    順時針旋轉',
                      '↓    軟降（非鎖定）',
                      '空白   硬降（瞬間落地並鎖定）',
                      'Z    逆時針旋轉',
                      'X    順時針旋轉（備用）',
                      'P    暫停/恢復',
                      'R    重新開始',
                      'G    切換Ghost Piece',
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildControlSection(
                    '🎮 手把控制',
                    [
                      '搖桿左/右  移動方塊',
                      '搖桿上     硬降（瞬間落地）',
                      '搖桿下     軟降',
                      '左肩鍵     逆時針旋轉',
                      '右肩鍵     順時針旋轉',
                      'A鈕       順時針旋轉',
                      'B鈕       逆時針旋轉',
                      'X鈕       硬降',
                      'Y鈕       暫停',
                      'Start     暫停/恢復',
                      'Select    切換Ghost Piece',
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildControlSection(
                    '📱 觸控控制',
                    [
                      '點擊方向按鈕移動方塊',
                      '點擊旋轉按鈕改變方向',
                      '點擊硬降按鈕瞬間落地',
                      '長按移動按鈕連續移動',
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: GameTheme.primaryButtonStyle,
              child: const Text('確定'),
            ),
          ],
        );
      },
    );
  }

  /// 建立控制說明區塊
  static Widget _buildControlSection(String title, List<String> controls) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GameTheme.accentStyle.copyWith(fontSize: 16),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: GameTheme.gridLine.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: GameTheme.boardBorder.withOpacity(0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: controls
                .map((control) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        control,
                        style: GameTheme.bodyStyle.copyWith(fontSize: 13),
                      ),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }

  /// 遊戲模式切換按鈕
  static Widget gameModeToggleButton(
      bool isMarathonMode, VoidCallback onToggle) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: GameTheme.panelGradient,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: GameTheme.boardBorder,
          width: 1,
        ),
        boxShadow: GameTheme.cardShadow,
      ),
      child: Column(
        children: [
          Text(
            'MODE',
            style: GameTheme.accentStyle.copyWith(fontSize: 12),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: isMarathonMode
                  ? GameTheme.buttonPrimary.withOpacity(0.8)
                  : GameTheme.gridLine,
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              onPressed: onToggle,
              icon: Icon(
                isMarathonMode ? Icons.speed : Icons.score,
                color: Colors.white,
                size: 20,
              ),
              tooltip: isMarathonMode ? '切換至傳統模式' : '切換至Marathon模式',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isMarathonMode ? 'MARATHON' : 'CLASSIC',
            style: TextStyle(
              fontSize: 9,
              color: isMarathonMode
                  ? GameTheme.highlight
                  : GameTheme.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// Marathon 資訊面板
  static Widget marathonInfoPanel(MarathonSystem marathonSystem,
      {bool isVisible = true}) {
    return MarathonInfoPanel(
      marathonSystem: marathonSystem,
      isVisible: isVisible,
    );
  }

  /// Marathon 迷你資訊（用於主畫面）
  static Widget marathonMiniInfo(MarathonSystem marathonSystem) {
    return MarathonMiniInfo(marathonSystem: marathonSystem);
  }

  /// 速度顯示框（通用）
  static Widget speedInfoBox(String speedText, String modeText,
      {String? subtitle}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: GameTheme.panelGradient,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: GameTheme.boardBorder,
          width: 1,
        ),
        boxShadow: GameTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SPEED',
            style: GameTheme.subtitleStyle.copyWith(fontSize: 11),
          ),
          const SizedBox(height: 4),
          Text(
            speedText,
            style: GameTheme.accentStyle.copyWith(fontSize: 18),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: GameTheme.bodyStyle.copyWith(fontSize: 10),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            modeText,
            style: TextStyle(
              color: GameTheme.highlight,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
