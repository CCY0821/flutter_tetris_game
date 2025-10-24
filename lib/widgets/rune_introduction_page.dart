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
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              cyberpunkBgDeep,
              cyberpunkPanel,
              cyberpunkBgDeep,
            ],
            stops: [0.0, 0.5, 1.0],
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
                  const Icon(
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
                    icon: const Icon(
                      Icons.close,
                      color: cyberpunkPrimary,
                      size: 24,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: cyberpunkDanger.withOpacity(0.2),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(cyberpunkBorderRadius),
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
                        '1 能量符文', cyberpunkSuccess, _getOneEnergyRunes()),
                    const SizedBox(height: 20),
                    _buildRuneCategory(
                        '2 能量符文', cyberpunkWarning, _getTwoEnergyRunes()),
                    const SizedBox(height: 20),
                    _buildRuneCategory(
                        '3 能量符文', cyberpunkDanger, _getThreeEnergyRunes()),
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
        borderRadius: BorderRadius.circular(cyberpunkBorderRadius),
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
              borderRadius: BorderRadius.circular(cyberpunkBorderRadius),
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
                      const Icon(
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
                      const Icon(
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
        const Icon(
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
                borderRadius: BorderRadius.circular(cyberpunkBorderRadiusSmall),
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

  List<RuneData> _getOneEnergyRunes() {
    return [
      RuneData(
        name: '🔥 Flame Burst',
        icon: Icons.local_fire_department,
        cost: 1,
        cooldown: '6s',
        description: '精確選擇最有價值的目標清除，上方方塊結構整體下沉',
        categoryColor: cyberpunkSuccess,
      ),
      RuneData(
        name: '🔄 Element Morph',
        icon: Icons.transform,
        cost: 1,
        cooldown: '3s',
        description: '當前方塊隨機變形',
        categoryColor: cyberpunkSuccess,
      ),
    ];
  }

  List<RuneData> _getTwoEnergyRunes() {
    return [
      RuneData(
        name: '⚡ Thunder Strike Right',
        icon: Icons.flash_on,
        cost: 2,
        cooldown: '8s',
        description: '清理棋盤最右側行',
        categoryColor: cyberpunkWarning,
      ),
      RuneData(
        name: '⚡ Thunder Strike Left',
        icon: Icons.flash_off,
        cost: 2,
        cooldown: '8s',
        description: '清理棋盤最左側行',
        categoryColor: cyberpunkWarning,
      ),
      RuneData(
        name: '⏸ Time Change',
        icon: Icons.slow_motion_video,
        cost: 2,
        cooldown: '18s',
        duration: '10s',
        description: '下落速度 ×0.1，10秒後恢復原本速度',
        categoryColor: cyberpunkWarning,
      ),
      RuneData(
        name: '🏔️ Titan Gravity',
        icon: Icons.landscape,
        cost: 2,
        cooldown: '45s',
        description: '使用泰坦引力消除縱向空洞，分段壓實方塊',
        categoryColor: cyberpunkWarning,
      ),
      RuneData(
        name: '✨ Blessed Combo',
        icon: Icons.star,
        cost: 2,
        cooldown: '20s',
        duration: '10s',
        description: '10秒內自然消行分數 ×3',
        categoryColor: cyberpunkWarning,
      ),
    ];
  }

  List<RuneData> _getThreeEnergyRunes() {
    return [
      RuneData(
        name: '🐉 Dragon Roar',
        icon: Icons.whatshot,
        cost: 3,
        cooldown: '15s',
        description: '清除最下方三列，上方方塊結構整體下沉',
        categoryColor: cyberpunkDanger,
      ),
      RuneData(
        name: '😇 Angel\'s Grace',
        icon: Icons.flight,
        cost: 3,
        cooldown: '60s',
        description: '全部方塊清空',
        categoryColor: cyberpunkDanger,
      ),
      RuneData(
        name: '💫 Gravity Reset',
        icon: Icons.vertical_align_bottom,
        cost: 3,
        cooldown: '25s',
        description: '接下來五個方塊變成I',
        categoryColor: cyberpunkDanger,
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
