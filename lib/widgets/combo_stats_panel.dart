import 'package:flutter/material.dart';
import '../services/scoring_service.dart';
import '../theme/game_theme.dart';
import '../utils/game_colors.dart';
import '../core/constants.dart';

/// 連擊統計資訊面板
class ComboStatsPanel extends StatelessWidget {
  final ScoringService scoringService;

  const ComboStatsPanel({
    super.key,
    required this.scoringService,
  });

  @override
  Widget build(BuildContext context) {
    final stats = scoringService.getStatistics();
    final maxCombo = scoringService.maxCombo;
    final currentCombo = scoringService.currentCombo;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: GameTheme.panelGradient,
        borderRadius: BorderRadius.circular(cyberpunkBorderRadiusLarge),
        border: Border.all(
          color: GameTheme.boardBorder,
          width: 2,
        ),
        boxShadow: GameTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 標題
          Row(
            children: [
              const Icon(
                Icons.flash_on,
                color: GameTheme.accentBlue,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                'COMBO STATS',
                style: GameTheme.accentStyle.copyWith(fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 當前連擊
          _buildStatRow(
            'Current',
            currentCombo.toString(),
            _getComboColor(currentCombo),
            showRank: true,
            rank: scoringService.comboRankDescription,
          ),
          const SizedBox(height: 8),

          // 最大連擊
          _buildStatRow(
            'Max Combo',
            maxCombo.toString(),
            _getComboColor(maxCombo),
            isRecord: true,
          ),
          const SizedBox(height: 8),

          // 總連擊次數
          _buildStatRow(
            'Total Combos',
            '${stats['combos'] ?? 0}',
            GameTheme.accentBlue,
          ),
          const SizedBox(height: 8),

          // 連擊積分
          _buildStatRow(
            'Combo Points',
            '${stats['combo_count'] ?? 0}',
            GameTheme.highlight,
          ),

          const SizedBox(height: 12),

          // 連擊等級條
          if (maxCombo > 0) _buildComboLevelBar(),
        ],
      ),
    );
  }

  /// 建立統計行
  Widget _buildStatRow(
    String label,
    String value,
    Color color, {
    bool isRecord = false,
    bool showRank = false,
    String rank = '',
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GameTheme.accentStyle
              .copyWith(fontSize: 10, color: Colors.white70),
        ),
        Row(
          children: [
            if (isRecord && int.parse(value) > 0)
              const Icon(
                Icons.emoji_events,
                color: GameTheme.highlight,
                size: 12,
              ),
            if (isRecord && int.parse(value) > 0) const SizedBox(width: 4),
            Text(
              value,
              style: GameTheme.accentStyle.copyWith(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (showRank && rank.isNotEmpty) ...[
              const SizedBox(width: 4),
              Text(
                rank.replaceAll('!', ''),
                style: GameTheme.accentStyle.copyWith(
                  fontSize: 8,
                  color: color,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  /// 建立連擊等級條
  Widget _buildComboLevelBar() {
    final levels = [
      ComboLevel('Nice', 1, 3),
      ComboLevel('Great', 4, 6),
      ComboLevel('Excellent', 7, 10),
      ComboLevel('Amazing', 11, 15),
      ComboLevel('Incredible', 16, 20),
      ComboLevel('LEGENDARY', 21, 999),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'COMBO LEVELS',
          style: GameTheme.accentStyle
              .copyWith(fontSize: 10, color: Colors.white70),
        ),
        const SizedBox(height: 6),
        ...levels.map((level) => _buildLevelIndicator(level)),
      ],
    );
  }

  /// 建立等級指示器
  Widget _buildLevelIndicator(ComboLevel level) {
    final isAchieved = scoringService.maxCombo >= level.minCombo;
    final color = isAchieved ? _getComboColor(level.minCombo) : Colors.grey;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isAchieved ? color : Colors.grey,
                width: 1,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '${level.name} (${level.minCombo}${level.maxCombo < 999 ? '-${level.maxCombo}' : '+'})',
            style: GameTheme.accentStyle.copyWith(
              fontSize: 9,
              color: isAchieved ? color : Colors.grey,
              fontWeight: isAchieved ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  /// 根據連擊數獲取顏色
  Color _getComboColor(int combo) {
    return GameColors.getComboColor(combo);
  }
}

/// 連擊等級類
class ComboLevel {
  final String name;
  final int minCombo;
  final int maxCombo;

  ComboLevel(this.name, this.minCombo, this.maxCombo);
}
