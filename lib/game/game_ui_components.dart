import 'package:flutter/material.dart';
import '../models/tetromino.dart';
import '../theme/game_theme.dart';
import '../core/constants.dart';
import '../services/scoring_service.dart';
import '../widgets/combo_stats_panel.dart';
import '../widgets/marathon_info_panel.dart';
import '../widgets/integrated_stats_panel.dart';
import '../game/marathon_system.dart';
import '../services/audio_service.dart';

class GameUIComponents {
  static const double cellSize = 6;

  // 合併的 NEXT 和 SCORE 組件
  static Widget nextAndScorePanel(Tetromino? nextTetromino, int score,
      List<Tetromino> nextTetrominos, int highScore) {
    const previewSize = 6;
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
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: cyberpunkPanel, // 面板底色
        borderRadius: BorderRadius.circular(cyberpunkBorderRadius),
        border: Border.all(
          color: cyberpunkPrimary, // 1px primary 外框
          width: 1,
        ),
        boxShadow: [
          // 輕微外光
          BoxShadow(
            color: cyberpunkPrimary.withOpacity(0.2),
            blurRadius: cyberpunkGlowSoft,
            offset: const Offset(0, 0),
          ),
          // 角落裝飾線效果
          BoxShadow(
            color: cyberpunkSecondary.withOpacity(0.1),
            blurRadius: cyberpunkGlowSoft / 2,
            offset: const Offset(1, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          // High Score 區域
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'HIGH SCORE',
                style: GameTheme.accentStyle.copyWith(
                  fontSize: 10,
                  letterSpacing: 1.2,
                  color: cyberpunkAccent, // 霓虹綠用於最高分
                ),
              ),
              Text(
                '$highScore',
                style: GameTheme.titleStyle.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                  color: cyberpunkAccent, // 霓虹綠數字
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // 分數區域
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'SCORE',
                style: GameTheme.accentStyle.copyWith(
                  fontSize: 12,
                  letterSpacing: 1.5, // 標題字距
                  color: cyberpunkPrimary,
                ),
              ),
              Text(
                '$score',
                style: GameTheme.titleStyle.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.bold, // 數字加粗
                  letterSpacing: 1.0, // 數字字距
                  color: cyberpunkCaution, // 賽博黃數字
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // 霓虹分隔線
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  cyberpunkPrimary.withOpacity(0.6),
                  cyberpunkSecondary.withOpacity(0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // NEXT 方塊預覽區域 - 水平並排設計
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // NEXT 標題和主要方塊
              Row(
                children: [
                  Text(
                    'NEXT',
                    style: GameTheme.accentStyle.copyWith(
                      fontSize: 11,
                      letterSpacing: 1.5, // 標題字距
                      color: cyberpunkPrimary,
                    ),
                  ),
                  const SizedBox(width: 6),

                  // 主要 NEXT 方塊（第一個）
                  Container(
                    padding: const EdgeInsets.all(4),
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
                                        width: cellSize * 0.8,
                                        height: cellSize * 0.8,
                                        margin: const EdgeInsets.all(0.4),
                                        decoration: BoxDecoration(
                                          color: c ??
                                              GameTheme.gridLine
                                                  .withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(2),
                                          border: c != null
                                              ? null
                                              : Border.all(
                                                  color: GameTheme.gridLine
                                                      .withOpacity(0.2),
                                                  width: 0.3,
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

              const SizedBox(height: 6),

              // 下三個方塊預覽（第二行）
              Row(
                children: [
                  const SizedBox(width: 40), // 對齊NEXT文字下方
                  ...nextTetrominos.take(3).map((tetromino) => Container(
                        margin: const EdgeInsets.only(right: 2),
                        child: _buildSmallPreview(tetromino),
                      )),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 建立小型方塊預覽
  static Widget _buildSmallPreview(Tetromino tetromino) {
    const smallPreviewSize = 4;
    const offsetX = 1;
    const offsetY = 1;

    final preview = List.generate(
      smallPreviewSize,
      (_) => List.generate(smallPreviewSize, (_) => null as Color?),
    );

    for (final p in tetromino.shape) {
      int px = p.dx.toInt() + offsetX;
      int py = p.dy.toInt() + offsetY;
      if (py >= 0 &&
          py < smallPreviewSize &&
          px >= 0 &&
          px < smallPreviewSize) {
        preview[py][px] = tetromino.color;
      }
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: GameTheme.gameBoardBg.withOpacity(0.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: preview
            .map((row) => Row(
                  children: row
                      .map(
                        (c) => Container(
                          width: cellSize * 0.6,
                          height: cellSize * 0.6,
                          margin: const EdgeInsets.all(0.25),
                          decoration: BoxDecoration(
                            color: c ?? Colors.transparent,
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      )
                      .toList(),
                ))
            .toList(),
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
            const Icon(
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
            const Icon(
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
                                  color:
                                      c ?? GameTheme.gridLine.withOpacity(0.1),
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
    return Positioned.fill(
      child: Container(
        // 背景：半透明深色遮罩
        color: const Color(0xAA0A0F1E),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
            decoration: BoxDecoration(
              // 面板：深層背景色
              color: cyberpunkPanel,
              borderRadius: BorderRadius.circular(cyberpunkBorderRadius),
              // 1px 霓虹描邊
              border: Border.all(
                color: cyberpunkPrimary,
                width: 1,
              ),
              // glowSoft 外光
              boxShadow: [
                BoxShadow(
                  color: cyberpunkPrimary.withOpacity(0.3),
                  blurRadius: cyberpunkGlowSoft,
                  offset: const Offset(0, 0),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 上方細裝飾線
                Container(
                  width: 120,
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        cyberpunkSecondary.withOpacity(0.8),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // 標題文字
                Text(
                  text,
                  style: GameTheme.titleStyle.copyWith(
                    color: cyberpunkPrimary,
                    fontSize: 20, // 縮小字體
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.0, // 調整字距
                  ),
                  textAlign: TextAlign.center, // 置中對齊
                ),
                const SizedBox(height: 8),
                // 下方細裝飾線
                Container(
                  width: 80,
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        cyberpunkAccent.withOpacity(0.6),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ],
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

  static Widget marathonInfoPanel(MarathonSystem marathonSystem) {
    return MarathonInfoPanel(marathonSystem: marathonSystem);
  }

  static Widget comboStatsPanel(ScoringService scoringService) {
    return ComboStatsPanel(scoringService: scoringService);
  }

  static Widget integratedStatsPanel(
      ScoringService scoringService, MarathonSystem? marathonSystem) {
    return IntegratedStatsPanel(
      scoringService: scoringService,
      marathonSystem: marathonSystem,
    );
  }

  static Widget audioControlButton() {
    return StatefulBuilder(
      builder: (context, setState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 音樂控制
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: AudioService().isMusicEnabled
                        ? GameTheme.buttonSuccess.withOpacity(0.8)
                        : GameTheme.primaryDark.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    onPressed: () {
                      AudioService().toggleMusic();
                      setState(() {});
                    },
                    icon: Icon(
                      AudioService().isMusicEnabled
                          ? Icons.music_note
                          : Icons.music_off,
                      color: Colors.white,
                      size: 20,
                    ),
                    tooltip: '切換背景音樂 (M)',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MUSIC ${(AudioService().musicVolume * 100).round()}%',
                        style: TextStyle(
                          fontSize: 12,
                          color: GameTheme.textAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: GameTheme.accentBlue,
                          inactiveTrackColor:
                              GameTheme.gridLine.withOpacity(0.3),
                          thumbColor: GameTheme.brightAccent,
                          overlayColor: GameTheme.accentBlue.withOpacity(0.2),
                          trackHeight: 4,
                          thumbShape:
                              RoundSliderThumbShape(enabledThumbRadius: 8),
                        ),
                        child: Slider(
                          value: AudioService().musicVolume,
                          onChanged: AudioService().isMusicEnabled
                              ? (value) {
                                  AudioService().setMusicVolume(value);
                                  setState(() {});
                                }
                              : null,
                          min: 0.0,
                          max: 1.0,
                          divisions: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 音效控制
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: AudioService().isSfxEnabled
                        ? GameTheme.buttonSuccess.withOpacity(0.8)
                        : GameTheme.primaryDark.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    onPressed: () {
                      AudioService().toggleSfx();
                      setState(() {});
                    },
                    icon: Icon(
                      AudioService().isSfxEnabled
                          ? Icons.volume_up
                          : Icons.volume_off,
                      color: Colors.white,
                      size: 20,
                    ),
                    tooltip: '切換音效 (S)',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SFX ${(AudioService().sfxVolume * 100).round()}%',
                        style: TextStyle(
                          fontSize: 12,
                          color: GameTheme.textAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: GameTheme.accentBlue,
                          inactiveTrackColor:
                              GameTheme.gridLine.withOpacity(0.3),
                          thumbColor: GameTheme.brightAccent,
                          overlayColor: GameTheme.accentBlue.withOpacity(0.2),
                          trackHeight: 4,
                          thumbShape:
                              RoundSliderThumbShape(enabledThumbRadius: 8),
                        ),
                        child: Slider(
                          value: AudioService().sfxVolume,
                          onChanged: AudioService().isSfxEnabled
                              ? (value) {
                                  AudioService().setSfxVolume(value);
                                  setState(() {});
                                }
                              : null,
                          min: 0.0,
                          max: 1.0,
                          divisions: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  static Widget ghostPieceControlButton(bool isEnabled, VoidCallback onToggle) {
    return SizedBox(
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
    return SizedBox(
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
