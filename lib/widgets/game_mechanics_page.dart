import 'package:flutter/material.dart';
import '../theme/game_theme.dart';
import '../core/constants.dart';

/// 遊戲機制介紹頁面
/// 使用標籤頁切換顯示符文系統和惡魔方塊系統
class GameMechanicsPage extends StatelessWidget {
  const GameMechanicsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
            maxWidth: 400,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                cyberpunkBgDeep.withOpacity(0.95),
                GameTheme.secondaryDark.withOpacity(0.95),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: cyberpunkPrimary.withOpacity(0.5),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: cyberpunkPrimary.withOpacity(0.3),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 標題欄
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      cyberpunkPrimary.withOpacity(0.2),
                      GameTheme.brightAccent.withOpacity(0.2),
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
                      Icons.info_outline,
                      color: GameTheme.textPrimary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'GAME MECHANICS',
                        style: GameTheme.titleStyle.copyWith(
                          fontSize: 16,
                          letterSpacing: 1.2,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.close,
                        color: GameTheme.textPrimary,
                        size: 20,
                      ),
                      style: IconButton.styleFrom(
                        minimumSize: const Size(36, 36),
                        padding: EdgeInsets.zero,
                        backgroundColor:
                            GameTheme.buttonDanger.withOpacity(0.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 標籤頁選擇器
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: cyberpunkAccent.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                ),
                child: TabBar(
                  indicatorColor: cyberpunkAccent,
                  indicatorWeight: 3,
                  labelColor: cyberpunkAccent,
                  unselectedLabelColor: GameTheme.textSecondary,
                  labelStyle: GameTheme.subtitleStyle.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  tabs: const [
                    Tab(
                      icon: Icon(Icons.auto_awesome, size: 20),
                      text: '符文系統',
                    ),
                    Tab(
                      icon: Icon(Icons.diamond, size: 20),
                      text: '惡魔方塊',
                    ),
                  ],
                ),
              ),

              // 標籤頁內容
              Flexible(
                child: TabBarView(
                  children: [
                    _buildRuneSystemTab(),
                    _buildDemonBlockTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 符文系統標籤頁
  Widget _buildRuneSystemTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 標題
          _buildSectionTitle('⚡ 能量系統', Icons.battery_charging_full),
          const SizedBox(height: 12),
          _buildInfoCard([
            '• 消除 1 行 = +50 分',
            '• 100 分 = 1 格能量',
            '• 最多儲存 3 格能量',
            '• 可保留溢出進度',
          ]),
          const SizedBox(height: 20),

          // 符文使用
          _buildSectionTitle('🎯 符文使用', Icons.touch_app),
          const SizedBox(height: 12),
          _buildInfoCard([
            '• 3 個符文槽位（可配置）',
            '• 10 種符文可選',
            '• 需消耗能量施放',
            '• 每種符文有獨立冷卻時間',
          ]),
          const SizedBox(height: 20),

          // 符文分類
          _buildSectionTitle('📚 符文分類', Icons.category),
          const SizedBox(height: 12),
          _buildInfoCard([
            '瞬發類：立即生效',
            '  例：Flame Burst, Thunder Strike',
            '',
            '時間系：持續一段時間',
            '  例：Gravity Reset, Titan Gravity',
            '  ⚠️ 同時只能有 1 個時間系符文',
          ]),
          const SizedBox(height: 16),

          // 提示
          _buildHintBox(
            '💡 提示：在設定中查看「RUNE COMPENDIUM」了解所有符文詳情',
          ),
        ],
      ),
    );
  }

  /// 惡魔方塊標籤頁
  Widget _buildDemonBlockTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 觸發條件
          _buildSectionTitle('🎯 觸發條件', Icons.flag),
          const SizedBox(height: 12),
          _buildInfoCard([
            '• 達到特定分數門檻時觸發',
            '• 分數越高，觸發越頻繁',
            '• 無次數上限',
          ]),
          const SizedBox(height: 20),

          // 方塊特徵
          _buildSectionTitle('💎 方塊特徵', Icons.diamond),
          const SizedBox(height: 12),
          _buildInfoCard([
            '• 超大尺寸：10 格方塊',
            '• 金色外觀（GOLD 顏色）',
            '• 形狀隨機生成',
          ]),
          const SizedBox(height: 20),

          // 分數加成
          _buildSectionTitle('🔥 分數加成', Icons.trending_up),
          const SizedBox(height: 12),
          _buildInfoCard([
            '放置惡魔方塊後觸發：',
            '',
            '✨ 所有得分 × 3 倍',
            '⏱️ 持續 10 秒',
            '🔄 可疊加時間',
            '',
            '範例：',
            '  剩餘 5 秒時再次觸發',
            '  → 總時間變為 15 秒',
          ]),
          const SizedBox(height: 16),

          // 提示
          _buildHintBox(
            '💡 提示：惡魔方塊雖然難以放置，但能帶來巨大的分數優勢！',
          ),
        ],
      ),
    );
  }

  /// 建立區段標題
  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          color: cyberpunkAccent,
          size: 18,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: GameTheme.subtitleStyle.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: cyberpunkAccent,
          ),
        ),
      ],
    );
  }

  /// 建立資訊卡片
  Widget _buildInfoCard(List<String> items) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            GameTheme.secondaryDark.withOpacity(0.5),
            GameTheme.primaryDark.withOpacity(0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(cyberpunkBorderRadius),
        border: Border.all(
          color: cyberpunkAccent.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items.map((item) {
          // 空行
          if (item.isEmpty) {
            return const SizedBox(height: 8);
          }
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              item,
              style: GameTheme.bodyStyle.copyWith(
                fontSize: 13,
                height: 1.4,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// 建立提示框
  Widget _buildHintBox(String hint) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cyberpunkPrimary.withOpacity(0.15),
        borderRadius: BorderRadius.circular(cyberpunkBorderRadius),
        border: Border.all(
          color: cyberpunkPrimary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.lightbulb_outline,
            color: GameTheme.brightAccent,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              hint,
              style: GameTheme.bodyStyle.copyWith(
                fontSize: 12,
                color: GameTheme.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
