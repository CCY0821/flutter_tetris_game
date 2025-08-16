import 'package:flutter/material.dart';
import '../models/tetromino.dart';
import '../theme/game_theme.dart';
import '../services/scoring_service.dart';
import '../widgets/combo_stats_panel.dart';
import '../widgets/marathon_info_panel.dart';
import '../game/marathon_system.dart';
import '../services/audio_service.dart';

class GameUIComponents {
  static const double cellSize = 12;

  // 合併的 NEXT 和 SCORE 組件
  static Widget nextAndScorePanel(Tetromino? nextTetromino, int score) {
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
          // 分數區域
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'SCORE',
                style: GameTheme.accentStyle.copyWith(fontSize: 12),
              ),
              Text(
                '$score',
                style: GameTheme.titleStyle.copyWith(
                  fontSize: 16,
                  color: GameTheme.textAccent,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // 分隔線
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  GameTheme.gridLine.withOpacity(0.5),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // NEXT 方塊預覽
          Row(
            children: [
              Text(
                'NEXT',
                style: GameTheme.accentStyle.copyWith(fontSize: 12),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: GameTheme.gameBoardBg.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  children: preview
                      .map((row) => Row(
                            children: row
                                .map(
                                  (c) => Container(
                                    width: cellSize * 0.6,
                                    height: cellSize * 0.6,
                                    margin: const EdgeInsets.all(0.5),
                                    decoration: BoxDecoration(
                                      color: c ??
                                          GameTheme.gridLine.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(2),
                                      border: c != null
                                          ? null
                                          : Border.all(
                                              color: GameTheme.gridLine
                                                  .withOpacity(0.2),
                                              width: 0.5,
                                            ),
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
        ],
      ),
    );
  }

  // 保留原有的其他組件
  static Widget gameStatusIndicators({
    required int combo,
    required bool isBackToBackReady,
    required String comboRank,
  }) {
    if (combo == 0 && !isBackToBackReady) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getComboColor(combo).withOpacity(0.5),
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
              'COMBO $combo',
              style: GameTheme.accentStyle.copyWith(
                fontSize: 10,
                color: _getComboColor(combo),
                fontWeight: FontWeight.bold,
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
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }

  static Color _getComboColor(int combo) {
    if (combo >= 10) return const Color(0xFFFF6B6B);
    if (combo >= 7) return const Color(0xFFFFB347);
    if (combo >= 4) return const Color(0xFF4ECDC4);
    if (combo >= 2) return const Color(0xFF95E1D3);
    return GameTheme.textAccent;
  }

  static Widget comboEffectIndicator({
    required int combo,
    required String comboRank,
  }) {
    if (combo < 4) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getComboColor(combo).withOpacity(0.2),
            _getComboColor(combo).withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getComboColor(combo),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: _getComboColor(combo).withOpacity(0.3),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.whatshot,
                color: _getComboColor(combo),
                size: 20,
              ),
              const SizedBox(width: 4),
              Text(
                '$combo COMBO!',
                style: GameTheme.titleStyle.copyWith(
                  fontSize: 14,
                  color: _getComboColor(combo),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            comboRank,
            style: GameTheme.accentStyle.copyWith(
              fontSize: 10,
              color: _getComboColor(combo),
            ),
          ),
        ],
      ),
    );
  }

  static Widget infoBox(String value, {required String label}) {
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
            label,
            style: GameTheme.accentStyle.copyWith(fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GameTheme.titleStyle.copyWith(fontSize: 16),
          ),
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
                                  color: c ??
                                      GameTheme.gridLine.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(2),
                                  border: c != null
                                      ? null
                                      : Border.all(
                                          color: GameTheme.gridLine
                                              .withOpacity(0.2),
                                          width: 0.5,
                                        ),
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

  static Widget overlayText(String text, Color color) {
    return Container(
      color: Colors.black.withOpacity(0.8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color, width: 2),
          ),
          child: Text(
            text,
            style: GameTheme.titleStyle.copyWith(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  static Widget scoringInfoPanel(dynamic lastResult) {
    if (lastResult == null) {
      return const SizedBox.shrink();
    }

    // 處理 ScoringResult 類型
    final description = lastResult.description ?? '';
    final points = lastResult.points ?? 0;

    if (description.isEmpty || points == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: GameTheme.highlight.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'LAST SCORE',
            style: GameTheme.accentStyle.copyWith(fontSize: 10),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(
              color: Colors.yellow,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Points',
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
              Text(
                '+$points',
                style: TextStyle(
                  color: GameTheme.highlight,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Widget gameModeToggleButton(bool isMarathonMode, VoidCallback onToggle) {
    return ElevatedButton(
      onPressed: onToggle,
      style: ElevatedButton.styleFrom(
        backgroundColor: isMarathonMode 
            ? GameTheme.buttonSuccess 
            : GameTheme.buttonSecondary,
        foregroundColor: GameTheme.textPrimary,
        elevation: 4,
        shadowColor: (isMarathonMode 
            ? GameTheme.buttonSuccess 
            : GameTheme.buttonSecondary).withOpacity(0.4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isMarathonMode ? Icons.speed : Icons.videogame_asset,
            size: 18,
          ),
          const SizedBox(width: 6),
          Text(isMarathonMode ? 'Marathon' : 'Classic'),
        ],
      ),
    );
  }

  static Widget marathonInfoPanel(MarathonSystem marathonSystem) {
    return MarathonInfoPanel(marathonSystem: marathonSystem);
  }

  static Widget comboStatsPanel(ScoringService scoringService) {
    return ComboStatsPanel(scoringService: scoringService);
  }

  static Widget audioControlButton() {
    return Container(
      width: 20,
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: GameTheme.accentBlue.withOpacity(0.8),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              onPressed: () => AudioService().toggleMusic(),
              icon: Icon(
                AudioService().isMusicEnabled ? Icons.music_note : Icons.music_off,
                color: Colors.white,
                size: 20,
              ),
              tooltip: '切換背景音樂 (M)',
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'MUSIC',
            style: TextStyle(
              fontSize: 10,
              color: GameTheme.highlight,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: GameTheme.buttonSecondary.withOpacity(0.8),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              onPressed: () => AudioService().toggleSfx(),
              icon: Icon(
                AudioService().isSfxEnabled ? Icons.volume_up : Icons.volume_off,
                color: Colors.white,
                size: 20,
              ),
              tooltip: '切換音效 (S)',
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'SFX',
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

  static Widget ghostPieceControlButton(bool isEnabled, VoidCallback onToggle) {
    return Container(
      width: 20,
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: isEnabled 
                  ? GameTheme.buttonSuccess.withOpacity(0.8)
                  : GameTheme.primaryDark.withOpacity(0.8),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              onPressed: onToggle,
              icon: Icon(
                isEnabled ? Icons.visibility : Icons.visibility_off,
                color: Colors.white,
                size: 20,
              ),
              tooltip: isEnabled ? '關閉 Ghost Piece (G)' : '開啟 Ghost Piece (G)',
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'GHOST',
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

  static Widget controlHelpButton(BuildContext context) {
    return Container(
      width: 20,
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: GameTheme.accentBlue.withOpacity(0.8),
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
                      '↓  軟降落',
                      '↑  旋轉方塊',
                      'Space  快速降落',
                      'P  暫停/繼續遊戲',
                      'R  重新開始',
                      'H  顯示說明',
                      'M  切換背景音樂',
                      'S  切換音效',
                      'G  切換 Ghost Piece',
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildControlSection(
                    '🎮 WASD 控制',
                    [
                      'A D  移動方塊',
                      'S  軟降落',
                      'W  旋轉方塊',
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildControlSection(
                    '🎯 手把控制',
                    [
                      '十字鍵  移動和降落',
                      'A按鈕  旋轉方塊',
                      'Start  暫停/繼續',
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                '確定',
                style: GameTheme.accentStyle,
              ),
            ),
          ],
        );
      },
    );
  }

  static Widget _buildControlSection(String title, List<String> controls) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GameTheme.subtitleStyle.copyWith(
            fontWeight: FontWeight.bold,
            color: GameTheme.textAccent,
          ),
        ),
        const SizedBox(height: 8),
        ...controls.map((control) => Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 4),
              child: Text(
                control,
                style: GameTheme.bodyStyle,
              ),
            )),
      ],
    );
  }
}