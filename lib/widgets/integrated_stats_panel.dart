import 'package:flutter/material.dart';
import '../game/marathon_system.dart';
import '../services/scoring_service.dart';
import '../theme/game_theme.dart';

/// 整合的統計面板：Marathon 模式資訊 + COMBO 統計
class IntegratedStatsPanel extends StatelessWidget {
  final MarathonSystem? marathonSystem;
  final ScoringService scoringService;
  final bool isMarathonMode;

  const IntegratedStatsPanel({
    super.key,
    this.marathonSystem,
    required this.scoringService,
    this.isMarathonMode = false,
  });

  @override
  Widget build(BuildContext context) {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 標題區域
          _buildHeader(),
          const SizedBox(height: 12),

          // Marathon 模式資訊（如果啟用）
          if (isMarathonMode && marathonSystem != null) ...[
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
          isMarathonMode ? Icons.speed : Icons.flash_on,
          color: isMarathonMode ? Colors.cyan : GameTheme.accentBlue,
          size: 18,
        ),
        const SizedBox(width: 6),
        Text(
          isMarathonMode ? 'MARATHON STATS' : 'COMBO STATS',
          style: GameTheme.accentStyle.copyWith(fontSize: 12),
        ),
        if (isMarathonMode && marathonSystem != null) ...[
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.cyan.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'Lv ${marathonSystem!.getLevelDisplayName()}',
              style: TextStyle(
                color: Colors.cyan,
                fontSize: 10,
                fontWeight: FontWeight.bold,
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LINES',
                  style: GameTheme.accentStyle.copyWith(fontSize: 10, color: Colors.white70),
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'SPEED',
                  style: GameTheme.accentStyle.copyWith(fontSize: 10, color: Colors.white70),
                ),
                Text(
                  '${stats.gravity.toStringAsFixed(1)}G',
                  style: TextStyle(
                    color: _getSpeedColor(stats.gravity),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        // 進度條
        Row(
          children: [
            Text(
              'Progress',
              style: GameTheme.accentStyle.copyWith(fontSize: 10, color: Colors.white70),
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
              style: GameTheme.accentStyle.copyWith(fontSize: 10, color: Colors.cyan),
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
                  style: GameTheme.accentStyle.copyWith(fontSize: 10, color: Colors.white70),
                ),
                Row(
                  children: [
                    Text(
                      '$currentCombo',
                      style: TextStyle(
                        color: _getComboColor(currentCombo),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (currentCombo > 0) ...[
                      const SizedBox(width: 4),
                      Text(
                        scoringService.comboRankDescription.replaceAll('!', ''),
                        style: TextStyle(
                          color: _getComboColor(currentCombo),
                          fontSize: 8,
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
                  style: GameTheme.accentStyle.copyWith(fontSize: 10, color: Colors.white70),
                ),
                Row(
                  children: [
                    if (maxCombo > 0)
                      Icon(
                        Icons.emoji_events,
                        color: GameTheme.highlight,
                        size: 12,
                      ),
                    if (maxCombo > 0) const SizedBox(width: 4),
                    Text(
                      '$maxCombo',
                      style: TextStyle(
                        color: _getComboColor(maxCombo),
                        fontSize: 16,
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
            _buildMiniStat('Total', '${stats['combos'] ?? 0}', GameTheme.accentBlue),
            _buildMiniStat('Points', '${stats['combo_count'] ?? 0}', GameTheme.highlight),
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
          style: GameTheme.accentStyle.copyWith(fontSize: 9, color: Colors.white70),
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