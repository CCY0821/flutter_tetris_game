import 'package:flutter/material.dart';
import '../theme/game_theme.dart';
import '../core/constants.dart';

// 補充缺失的顏色常數
const Color cyberpunkDanger = Color(0xFFFF4444);
const Color cyberpunkWarning = Color(0xFFFF8800);
const Color cyberpunkSuccess = Color(0xFF00FF88);
const Color cyberpunkTextSecondary = Color(0xFF888888);

class RuneIntroductionPage extends StatelessWidget {
  const RuneIntroductionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.95,
        height: MediaQuery.of(context).size.height * 0.9,
        constraints: const BoxConstraints(
          maxWidth: 500,
          maxHeight: 800,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              cyberpunkBgDeep,
              cyberpunkPanel,
              cyberpunkBgDeep,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
          borderRadius: BorderRadius.circular(cyberpunkBorderRadiusLarge),
          border: Border.all(
            color: cyberpunkPrimary.withOpacity(0.6),
            width: cyberpunkBorderWidth,
          ),
          boxShadow: [
            ...cyberpunkPanelShadow,
            BoxShadow(
              color: cyberpunkPrimary.withOpacity(0.2),
              blurRadius: cyberpunkGlowStrong,
              spreadRadius: -2,
            ),
          ],
        ),
        child: Column(
          children: [
            // 標題欄
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    cyberpunkPrimary.withOpacity(0.2),
                    cyberpunkAccent.withOpacity(0.2),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.auto_awesome,
                    color: cyberpunkPrimary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'RUNE COMPENDIUM',
                      style: GameTheme.titleStyle.copyWith(
                        fontSize: 18,
                        letterSpacing: 2.0,
                        color: cyberpunkPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close,
                      color: cyberpunkPrimary,
                      size: 24,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: cyberpunkDanger.withOpacity(0.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 符文列表
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildRuneCategory(
                        'CLEANSE', cyberpunkDanger, _getClearRunes()),
                    const SizedBox(height: 20),
                    _buildRuneCategory(
                        'FIELD CONTROL', cyberpunkWarning, _getFieldRunes()),
                    const SizedBox(height: 20),
                    _buildRuneCategory(
                        'SURVIVAL', cyberpunkPrimary, _getSurvivalRunes()),
                    const SizedBox(height: 20),
                    _buildRuneCategory(
                        'TEMPORAL', cyberpunkAccent, _getTimeRunes()),
                    const SizedBox(height: 20),
                    _buildRuneCategory('ENHANCEMENT', cyberpunkSuccess,
                        _getEnhancementRunes()),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRuneCategory(
      String categoryName, Color categoryColor, List<RuneData> runes) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            categoryColor.withOpacity(0.1),
            categoryColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(cyberpunkBorderRadius),
        border: Border.all(
          color: categoryColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 類別標題
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  categoryColor.withOpacity(0.2),
                  categoryColor.withOpacity(0.1),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(11),
                topRight: Radius.circular(11),
              ),
            ),
            child: Text(
              categoryName,
              style: GameTheme.subtitleStyle.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                color: categoryColor,
              ),
            ),
          ),

          // 符文列表
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: runes.map((rune) => _buildRuneItem(rune)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRuneItem(RuneData rune) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            cyberpunkPanel.withOpacity(0.3),
            cyberpunkBgDeep.withOpacity(0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: rune.categoryColor.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: rune.categoryColor.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 符文圖示
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  rune.categoryColor.withOpacity(0.3),
                  rune.categoryColor.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: rune.categoryColor.withOpacity(0.5),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: rune.categoryColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              rune.icon,
              color: rune.categoryColor,
              size: 24,
            ),
          ),

          const SizedBox(width: 12),

          // 符文信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        rune.name,
                        style: GameTheme.subtitleStyle.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: rune.categoryColor,
                        ),
                      ),
                    ),
                    _buildEnergyBar(rune.cost),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  rune.description,
                  style: GameTheme.bodyStyle.copyWith(
                    fontSize: 12,
                    color: cyberpunkTextSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (rune.cooldown != null) ...[
                      Icon(
                        Icons.access_time,
                        size: 12,
                        color: cyberpunkTextSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'CD: ${rune.cooldown}',
                        style: GameTheme.bodyStyle.copyWith(
                          fontSize: 10,
                          color: cyberpunkTextSecondary,
                        ),
                      ),
                    ],
                    if (rune.duration != null) ...[
                      const SizedBox(width: 12),
                      Icon(
                        Icons.timer,
                        size: 12,
                        color: cyberpunkTextSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '持續: ${rune.duration}',
                        style: GameTheme.bodyStyle.copyWith(
                          fontSize: 10,
                          color: cyberpunkTextSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnergyBar(int cost) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.battery_charging_full,
          size: 14,
          color: cyberpunkAccent,
        ),
        const SizedBox(width: 4),
        Row(
          children: List.generate(
            3,
            (index) => Container(
              width: 8,
              height: 12,
              margin: const EdgeInsets.only(left: 1),
              decoration: BoxDecoration(
                color: index < cost
                    ? cyberpunkAccent
                    : cyberpunkAccent.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
                boxShadow: index < cost
                    ? [
                        BoxShadow(
                          color: cyberpunkAccent.withOpacity(0.5),
                          blurRadius: 2,
                        ),
                      ]
                    : null,
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<RuneData> _getClearRunes() {
    return [
      // 1 格能量符文
      RuneData(
        name: 'Flame Burst',
        icon: Icons.local_fire_department,
        cost: 1,
        cooldown: '6s',
        description: '立即清除當前方塊所在列',
        categoryColor: cyberpunkDanger,
      ),
      RuneData(
        name: 'Thunder Strike',
        icon: Icons.flash_on,
        cost: 1,
        cooldown: '8s',
        description: '隨機清除 1 列（偏向高堆積區）',
        categoryColor: cyberpunkDanger,
      ),
      // 3 格能量符文
      RuneData(
        name: 'Dragon Roar',
        icon: Icons.whatshot,
        cost: 3,
        cooldown: '15s',
        description: '清除當前列及上下各一行',
        categoryColor: cyberpunkDanger,
      ),
      RuneData(
        name: 'Column Breaker',
        icon: Icons.view_column,
        cost: 3,
        cooldown: '8s',
        description: '清除當前方塊影子所覆蓋的整條縱列',
        categoryColor: cyberpunkDanger,
      ),
    ];
  }

  List<RuneData> _getFieldRunes() {
    return [
      RuneData(
        name: 'Earthquake',
        icon: Icons.terrain,
        cost: 1,
        cooldown: '10s',
        description: '整個盤面下移 1 行，底行消失',
        categoryColor: cyberpunkWarning,
      ),
    ];
  }

  List<RuneData> _getSurvivalRunes() {
    return [
      RuneData(
        name: "Angel's Grace",
        icon: Icons.flight,
        cost: 2,
        cooldown: '18s',
        description: '刪除最頂端 2 行方塊',
        categoryColor: cyberpunkPrimary,
      ),
      RuneData(
        name: 'Gravity Reset',
        icon: Icons.vertical_align_bottom,
        cost: 3,
        cooldown: '25s',
        description: '整個棋盤壓縮到底部，消除所有空洞',
        categoryColor: cyberpunkPrimary,
      ),
    ];
  }

  List<RuneData> _getTimeRunes() {
    return [
      RuneData(
        name: 'Time Slow',
        icon: Icons.slow_motion_video,
        cost: 1,
        cooldown: '12s',
        duration: '5s',
        description: '5 秒內下落速度減半',
        categoryColor: cyberpunkAccent,
      ),
      RuneData(
        name: 'Time Stop',
        icon: Icons.pause_circle,
        cost: 2,
        cooldown: '18s',
        duration: '3s',
        description: '3 秒完全暫停，可移動旋轉',
        categoryColor: cyberpunkAccent,
      ),
    ];
  }

  List<RuneData> _getEnhancementRunes() {
    return [
      RuneData(
        name: 'Blessed Combo',
        icon: Icons.star,
        cost: 2,
        cooldown: '20s',
        duration: '10s',
        description: '10 秒內自然消除分數翻倍',
        categoryColor: cyberpunkSuccess,
      ),
    ];
  }
}

class RuneData {
  final String name;
  final IconData icon;
  final int cost;
  final String? cooldown;
  final String? duration;
  final String description;
  final Color categoryColor;

  RuneData({
    required this.name,
    required this.icon,
    required this.cost,
    this.cooldown,
    this.duration,
    required this.description,
    required this.categoryColor,
  });
}
