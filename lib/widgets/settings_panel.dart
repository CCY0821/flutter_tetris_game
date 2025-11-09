import 'package:flutter/material.dart';
import '../theme/game_theme.dart';
import '../core/constants.dart';
import '../game/game_state.dart';
import '../game/game_ui_components.dart';
import 'rune_introduction_page.dart';
import 'rune_selection_page.dart';

class SettingsPanel extends StatefulWidget {
  final GameState gameState;
  final VoidCallback onGhostPieceToggle;
  final VoidCallback onStateChange;
  final BuildContext gameContext;

  const SettingsPanel({
    super.key,
    required this.gameState,
    required this.onGhostPieceToggle,
    required this.onStateChange,
    required this.gameContext,
  });

  @override
  State<SettingsPanel> createState() => _SettingsPanelState();
}

class _SettingsPanelState extends State<SettingsPanel> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
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
              GameTheme.primaryDark.withOpacity(0.95),
              GameTheme.secondaryDark.withOpacity(0.95),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: GameTheme.accentBlue.withOpacity(0.5),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: GameTheme.accentBlue.withOpacity(0.3),
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
                    GameTheme.accentBlue.withOpacity(0.2),
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
                    Icons.settings,
                    color: GameTheme.textPrimary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'GAME SETTINGS',
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
                      backgroundColor: GameTheme.buttonDanger.withOpacity(0.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 設置內容
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 音頻設置
                    _buildSettingSection(
                      'AUDIO',
                      Icons.volume_up,
                      child: GameUIComponents.audioControlButton(),
                    ),

                    const SizedBox(height: 20),

                    // 控制說明
                    _buildSettingSection(
                      'CONTROLS',
                      Icons.keyboard,
                      child: _buildControlsButton(),
                    ),

                    const SizedBox(height: 20),

                    // 符文配置
                    _buildSettingSection(
                      'RUNE LOADOUT',
                      Icons.auto_awesome,
                      child: _buildRuneLoadoutButton(),
                    ),

                    const SizedBox(height: 20),

                    // 符文介紹
                    _buildSettingSection(
                      'RUNE COMPENDIUM',
                      Icons.menu_book,
                      child: _buildRuneCompendiumButton(),
                    ),

                    const SizedBox(height: 20),

                    // 旋轉系統資訊
                    _buildSettingSection(
                      'ROTATION SYSTEM',
                      Icons.rotate_right,
                      child: GameUIComponents.infoBox(
                        'Super Rotation System (SRS)',
                        label: 'SYSTEM',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingSection(String title, IconData icon,
      {required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            GameTheme.secondaryDark.withOpacity(0.3),
            GameTheme.primaryDark.withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(cyberpunkBorderRadiusLarge),
        border: Border.all(
          color: GameTheme.gridLine.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 區域標題
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  GameTheme.accentBlue.withOpacity(0.1),
                  GameTheme.brightAccent.withOpacity(0.1),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(11),
                topRight: Radius.circular(11),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: GameTheme.textAccent,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: GameTheme.subtitleStyle.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // 設置內容
          Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildControlsButton() {
    return ElevatedButton(
      onPressed: () => _showControlHelp(widget.gameContext),
      style: GameTheme.primaryButtonStyle.copyWith(
        backgroundColor: WidgetStateProperty.all(
          GameTheme.accentBlue.withOpacity(0.8),
        ),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.help_outline, size: 18),
          SizedBox(width: 8),
          Text('View Controls'),
        ],
      ),
    );
  }

  Widget _buildRuneCompendiumButton() {
    return ElevatedButton(
      onPressed: () => _showRuneCompendium(context),
      style: GameTheme.primaryButtonStyle.copyWith(
        backgroundColor: WidgetStateProperty.all(
          cyberpunkPrimary.withOpacity(0.8),
        ),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.auto_awesome, size: 18, color: Colors.white),
          SizedBox(width: 8),
          Text('View Runes', style: TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildRuneLoadoutButton() {
    return ElevatedButton(
      onPressed: () => _showRuneLoadout(context),
      style: GameTheme.primaryButtonStyle.copyWith(
        backgroundColor: WidgetStateProperty.all(
          GameTheme.accentBlue.withOpacity(0.8),
        ),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.tune, size: 18),
          SizedBox(width: 8),
          Text('Configure Loadout'),
        ],
      ),
    );
  }

  void _showRuneLoadout(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return RuneSelectionPage(
          initialLoadout: widget.gameState.runeLoadout,
          onLoadoutChanged: () async {
            // 保存符文配置並重新載入符文系統
            await widget.gameState.saveRuneLoadout();
            // 觸發UI更新
            widget.onStateChange();
          },
        );
      },
    );
  }

  void _showRuneCompendium(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return const RuneIntroductionPage();
      },
    );
  }

  void _showControlHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: cyberpunkBgDeep,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(cyberpunkBorderRadius),
            side: BorderSide(
              color: cyberpunkPrimary.withOpacity(0.5),
              width: 1,
            ),
          ),
          title: Text(
            '📱 TOUCH CONTROLS',
            style: GameTheme.titleStyle.copyWith(
              fontSize: 18,
              letterSpacing: 2.0,
              color: cyberpunkPrimary,
            ),
          ),
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.85,
              maxHeight: MediaQuery.of(context).size.height * 0.6,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTouchControlRow(
                    Icons.settings,
                    '設定',
                    '開啟遊戲設定',
                  ),
                  _buildTouchControlRow(
                    Icons.pause,
                    '暫停/繼續',
                    '暫停或繼續遊戲',
                  ),
                  const Divider(color: cyberpunkAccent, height: 24),
                  _buildTouchControlRow(
                    Icons.keyboard_arrow_left,
                    '左移',
                    '方塊向左移動',
                  ),
                  _buildTouchControlRow(
                    Icons.keyboard_arrow_down,
                    '快降',
                    '方塊加速下降',
                  ),
                  _buildTouchControlRow(
                    Icons.keyboard_arrow_right,
                    '右移',
                    '方塊向右移動',
                  ),
                  const Divider(color: cyberpunkAccent, height: 24),
                  _buildTouchControlRow(
                    Icons.rotate_left,
                    '逆時針旋轉',
                    '方塊逆時針旋轉',
                  ),
                  _buildTouchControlRow(
                    Icons.rotate_right,
                    '順時針旋轉',
                    '方塊順時針旋轉',
                  ),
                  _buildTouchControlRow(
                    Icons.vertical_align_bottom,
                    '硬降',
                    '方塊瞬間落地',
                  ),
                  const Divider(color: cyberpunkAccent, height: 24),
                  _buildTouchControlRow(
                    Icons.auto_awesome,
                    '符文槽',
                    '點擊施放符文法術',
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                '確定',
                style: GameTheme.accentStyle,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTouchControlRow(IconData icon, String name, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          // 圖標
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  cyberpunkPrimary.withOpacity(0.3),
                  cyberpunkPrimary.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: cyberpunkAccent.withOpacity(0.5),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              color: cyberpunkAccent,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          // 功能名稱與說明
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GameTheme.subtitleStyle.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: GameTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: GameTheme.bodyStyle.copyWith(
                    fontSize: 12,
                    color: GameTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
