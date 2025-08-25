import 'package:flutter/material.dart';
import '../theme/game_theme.dart';
import '../core/constants.dart';
import '../game/game_state.dart';
import '../game/game_ui_components.dart';
import 'cyberpunk_hud_tag.dart';

class SettingsPanel extends StatelessWidget {
  final GameState gameState;
  final VoidCallback onGameModeToggle;
  final VoidCallback onGhostPieceToggle;
  final VoidCallback onStateChange;
  final BuildContext gameContext;

  const SettingsPanel({
    super.key,
    required this.gameState,
    required this.onGameModeToggle,
    required this.onGhostPieceToggle,
    required this.onStateChange,
    required this.gameContext,
  });

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
                  Icon(
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
                    icon: Icon(
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
                    // 遊戲模式設置
                    _buildSettingSection(
                      'GAME MODE',
                      Icons.gamepad,
                      child: GameUIComponents.gameModeToggleButton(
                        gameState.isMarathonMode,
                        onGameModeToggle,
                      ),
                    ),

                    const SizedBox(height: 20),

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
        borderRadius: BorderRadius.circular(12),
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
      onPressed: () => _showControlHelp(gameContext),
      style: GameTheme.primaryButtonStyle.copyWith(
        backgroundColor: WidgetStateProperty.all(
          GameTheme.accentBlue.withOpacity(0.8),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.help_outline, size: 18),
          const SizedBox(width: 8),
          Text('View Controls'),
        ],
      ),
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
            '🎮 CONTROL INTERFACE',
            style: GameTheme.titleStyle.copyWith(
              fontSize: 18,
              letterSpacing: 2.0,
              color: cyberpunkPrimary,
            ),
          ),
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.8,
              maxHeight: MediaQuery.of(context).size.height * 0.6,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildCyberpunkControlSection(
                    '⌨️ KEYBOARD',
                    [
                      {'key': '← →', 'text': '← → 移動方塊'},
                      {'key': '↓', 'text': '↓ 軟降落'},
                      {'key': '↑', 'text': '↑ 旋轉方塊'},
                      {'key': 'SPACE', 'text': 'SPACE 快速降落'},
                      {'key': 'P', 'text': 'P 暫停/繼續'},
                      {'key': 'R', 'text': 'R 重新開始'},
                      {'key': 'H', 'text': 'H 顯示說明'},
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildCyberpunkControlSection(
                    '🎮 WASD',
                    [
                      {'key': 'A D', 'text': 'A D 移動方塊'},
                      {'key': 'S', 'text': 'S 軟降落'},
                      {'key': 'W', 'text': 'W 旋轉方塊'},
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

  Widget _buildControlSection(String title, List<String> controls) {
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

  /// 建立 Cyberpunk 風格控制區段
  Widget _buildCyberpunkControlSection(
      String title, List<Map<String, String>> controls) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            color: cyberpunkAccent,
          ),
        ),
        const SizedBox(height: 12),
        CyberpunkControlHints(
          controls: controls,
          isCompact: false,
        ),
      ],
    );
  }
}
