import 'package:flutter/material.dart';
import '../game/marathon_system.dart';
import '../utils/game_colors.dart';
import '../core/constants.dart';

/// Marathon 模式資訊面板
class MarathonInfoPanel extends StatelessWidget {
  final MarathonSystem marathonSystem;
  final bool isVisible;

  const MarathonInfoPanel({
    super.key,
    required this.marathonSystem,
    this.isVisible = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();

    final stats = marathonSystem.getStats();

    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(cyberpunkBorderRadius),
        border: Border.all(color: Colors.cyan, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 標題
          const Text(
            'MARATHON MODE',
            style: TextStyle(
              color: Colors.cyan,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),

          // 關卡資訊
          _buildLevelSection(stats),
          const SizedBox(height: 12),

          // 進度條
          _buildProgressSection(stats),
          const SizedBox(height: 12),

          // 速度資訊
          _buildSpeedSection(stats),
        ],
      ),
    );
  }

  Widget _buildLevelSection(MarathonStats stats) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'LEVEL',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              marathonSystem.getLevelDisplayName(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text(
              'LINES',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${stats.totalLines}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProgressSection(MarathonStats stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'PROGRESS',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${stats.linesInLevel}/${MarathonSystem.linesPerLevel}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),

        // 進度條
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(cyberpunkBorderRadiusMedium),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: stats.progress,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.cyan, Colors.blue],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius:
                    BorderRadius.circular(cyberpunkBorderRadiusMedium),
              ),
            ),
          ),
        ),
        const SizedBox(height: 2),

        // 到下一關的行數
        if (!marathonSystem.isMaxLevel)
          Text(
            'Next: ${marathonSystem.linesToNextLevel} lines',
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 10,
            ),
          )
        else
          const Text(
            'MAX LEVEL',
            style: TextStyle(
              color: Colors.red,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
      ],
    );
  }

  Widget _buildSpeedSection(MarathonStats stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'SPEED',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${stats.gravity.toStringAsFixed(2)}G',
                  style: TextStyle(
                    color: _getSpeedColor(stats.gravity),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  marathonSystem.getSpeedDescription(),
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${stats.dropInterval}ms',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'interval',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Color _getSpeedColor(double gravity) {
    return GameColors.getSpeedColor(gravity);
  }
}

/// 簡化版的 Marathon 資訊顯示（用於主遊戲畫面）
class MarathonMiniInfo extends StatelessWidget {
  final MarathonSystem marathonSystem;

  const MarathonMiniInfo({
    super.key,
    required this.marathonSystem,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(cyberpunkBorderRadiusMedium),
        border: Border.all(color: Colors.cyan.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Lv ${marathonSystem.getLevelDisplayName()}',
            style: const TextStyle(
              color: Colors.cyan,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${marathonSystem.linesInCurrentLevel}/${MarathonSystem.linesPerLevel}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
            ),
          ),
          const SizedBox(width: 4),

          // 迷你進度條
          Container(
            width: 20,
            height: 3,
            decoration: BoxDecoration(
              color: Colors.grey[700],
              borderRadius: BorderRadius.circular(cyberpunkBorderRadiusTiny),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: marathonSystem.levelProgress,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.cyan,
                  borderRadius:
                      BorderRadius.circular(cyberpunkBorderRadiusTiny),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
