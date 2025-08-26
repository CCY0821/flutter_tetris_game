import 'package:flutter/material.dart';
import '../game/marathon_system.dart';
import '../services/scoring_service.dart';
import '../theme/game_theme.dart';
import '../core/constants.dart';

/// 整合的統計面板：Marathon 模式資訊 + COMBO 統計
class IntegratedStatsPanel extends StatelessWidget {
  final MarathonSystem? marathonSystem;
  final ScoringService scoringService;

  const IntegratedStatsPanel({
    super.key,
    this.marathonSystem,
    required this.scoringService,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
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
            color: cyberpunkAccent.withOpacity(0.1),
            blurRadius: cyberpunkGlowSoft / 2,
            offset: const Offset(1, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 標題區域
          _buildHeader(),
          const SizedBox(height: 12),

          // Marathon 模式資訊
          if (marathonSystem != null) ...[
            _buildMarathonSection(),
            const SizedBox(height: 12),
            _buildDivider(),
            const SizedBox(height: 12),
          ],

          // COMBO 統計區域
          _buildComboSection(),
        ],
      ),
    );
  }

  /// 建立標題
  Widget _buildHeader() {
    return Row(
      children: [
        Icon(
          Icons.speed,
          color: cyberpunkPrimary,
          size: 16,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            'MARATHON',
            style: GameTheme.accentStyle.copyWith(
              fontSize: 11,
              letterSpacing: 1.5, // 標題字距
              color: cyberpunkPrimary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (marathonSystem != null) ...[
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: cyberpunkAccent.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: cyberpunkAccent.withOpacity(0.5),
                width: 1,
              ),
            ),
            child: Text(
              'Lv ${marathonSystem!.getLevelDisplayName()}',
              style: TextStyle(
                color: cyberpunkAccent,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0, // 數字字距
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// 建立分隔線
  Widget _buildDivider() {
    return Container(
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
    );
  }

  /// 建立 Marathon 區域
  Widget _buildMarathonSection() {
    if (marathonSystem == null) return const SizedBox.shrink();

    final stats = marathonSystem!.getStats();

    return Column(
      children: [
        // 關卡和進度
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'LINES',
                    style: GameTheme.accentStyle
                        .copyWith(fontSize: 9, color: Colors.white70),
                  ),
                  Text(
                    '${stats.totalLines}',
                    style: TextStyle(
                      color: Colors.cyan,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'SPEED',
                    style: GameTheme.accentStyle
                        .copyWith(fontSize: 9, color: Colors.white70),
                  ),
                  Text(
                    '${stats.gravity.toStringAsFixed(1)}G',
                    style: TextStyle(
                      color: _getSpeedColor(stats.gravity),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // 進度條
        Row(
          children: [
            Text(
              'Progress',
              style: GameTheme.accentStyle
                  .copyWith(fontSize: 10, color: Colors.white70),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(3),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: stats.progress,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.cyan,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${(stats.progress * 100).toInt()}%',
              style: GameTheme.accentStyle
                  .copyWith(fontSize: 10, color: Colors.cyan),
            ),
          ],
        ),
      ],
    );
  }

  /// 建立 COMBO 區域
  Widget _buildComboSection() {
    final stats = scoringService.getStatistics();
    final maxCombo = scoringService.maxCombo;
    final currentCombo = scoringService.currentCombo;

    return Column(
      children: [
        // 當前和最大連擊
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CURRENT',
                  style: GameTheme.accentStyle
                      .copyWith(fontSize: 10, color: Colors.white70),
                ),
                Row(
                  children: [
                    Text(
                      '$currentCombo',
                      style: TextStyle(
                        color: _getComboColor(currentCombo),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (currentCombo > 0) ...[
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          scoringService.comboRankDescription
                              .replaceAll('!', ''),
                          style: TextStyle(
                            color: _getComboColor(currentCombo),
                            fontSize: 7,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'MAX COMBO',
                  style: GameTheme.accentStyle
                      .copyWith(fontSize: 10, color: Colors.white70),
                ),
                Row(
                  children: [
                    if (maxCombo > 0)
                      Icon(
                        Icons.emoji_events,
                        color: GameTheme.highlight,
                        size: 10,
                      ),
                    if (maxCombo > 0) const SizedBox(width: 3),
                    Text(
                      '$maxCombo',
                      style: TextStyle(
                        color: _getComboColor(maxCombo),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),

        // 統計資訊
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
                child: _buildMiniStat(
                    'Total', '${stats['combos'] ?? 0}', GameTheme.accentBlue)),
            const SizedBox(width: 8),
            Expanded(
                child: _buildMiniStat('Points', '${stats['combo_count'] ?? 0}',
                    GameTheme.highlight)),
          ],
        ),
      ],
    );
  }

  /// 建立小型統計
  Widget _buildMiniStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: GameTheme.accentStyle
              .copyWith(fontSize: 9, color: Colors.white70),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// 根據連擊數獲取顏色
  Color _getComboColor(int combo) {
    if (combo >= 21) return const Color(0xFFFF1744); // 紅色 - LEGENDARY
    if (combo >= 16) return const Color(0xFFFF5722); // 橙紅色 - INCREDIBLE
    if (combo >= 11) return const Color(0xFFFF9800); // 橙色 - AMAZING
    if (combo >= 7) return const Color(0xFFFFC107); // 黃色 - EXCELLENT
    if (combo >= 4) return const Color(0xFF4CAF50); // 綠色 - GREAT
    if (combo >= 1) return const Color(0xFF2196F3); // 藍色 - NICE
    return GameTheme.accentBlue;
  }

  /// 根據速度獲取顏色
  Color _getSpeedColor(double gravity) {
    if (gravity < 1.0) {
      return Colors.green;
    } else if (gravity < 5.0) {
      return Colors.yellow;
    } else if (gravity < 15.0) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
}
