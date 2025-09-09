import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'game_logic.dart';
import 'game_state.dart';
import 'rune_system.dart';
import 'rune_definitions.dart';
import 'monotonic_timer.dart';
import '../theme/game_theme.dart';
import '../core/constants.dart';
import '../core/dual_logger.dart';

/// 關鍵事件同步日誌，避免被節流沖掉
void logCritical(String msg) {
  logCrit(msg);
}

class TouchControls extends StatefulWidget {
  final GameLogic gameLogic;
  final GameState gameState;
  final VoidCallback onStateChange;

  const TouchControls({
    super.key,
    required this.gameLogic,
    required this.gameState,
    required this.onStateChange,
  });

  @override
  State<TouchControls> createState() => _TouchControlsState();
}

class _TouchControlsState extends State<TouchControls> {
  Timer? _repeatTimer;
  Timer? _cooldownUpdateTimer;
  String? _activeButton;

  void _attach() {
    logCritical('TouchControls: Attaching listeners');
    // 設置UI更新回調，當能量變化時觸發rebuild
    widget.gameState.setUIUpdateCallback(() {
      logCritical('TouchControls: UI update callback triggered!');
      if (mounted) {
        setState(() {
          logCritical('TouchControls: setState called - rebuilding UI');
        });
      }
    });

    // 啟動冷卻倒數更新定時器 - 每秒更新一次
    _startCooldownUpdateTimer();
  }

  void _detach() {
    logCritical('TouchControls: Detaching listeners');
    _repeatTimer?.cancel();
    _cooldownUpdateTimer?.cancel();
  }

  @override
  void initState() {
    super.initState();
    _attach();
  }

  @override
  void reassemble() {
    super.reassemble();
    _detach();
    _attach();
    logCritical('TouchControls: reassemble - listeners reattached');
  }

  void _startCooldownUpdateTimer() {
    _cooldownUpdateTimer?.cancel();
    _cooldownUpdateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        // 檢查是否有任何符文槽在冷卻中
        bool hasAnyCooling = false;
        if (widget.gameState.hasRuneSystemInitialized) {
          for (final slot in widget.gameState.runeSystem.slots) {
            // 🔥 關鍵修復：每次檢查時都更新槽位狀態
            slot.update();
            if (slot.isCooling) {
              hasAnyCooling = true;
            }
          }
        }

        // 🔥 修復：無論是否有冷卻都要更新UI，確保狀態同步
        setState(() {
          // 冷卻倒數UI更新
        });
      }
    });
  }

  void _startRepeat(String action, VoidCallback callback) {
    if (widget.gameState.isPaused || widget.gameState.isGameOver) return;

    // 觸覺回饋 - 僅在開始時觸發一次
    HapticFeedback.lightImpact();

    setState(() {
      _activeButton = action;
    });
    callback(); // 立即執行一次
    widget.onStateChange();

    // 開始重複執行
    _repeatTimer?.cancel();
    _repeatTimer = Timer.periodic(const Duration(milliseconds: 150), (_) {
      if (_activeButton == action &&
          !widget.gameState.isPaused &&
          !widget.gameState.isGameOver) {
        callback();
        widget.onStateChange();
      }
    });
  }

  void _stopRepeat() {
    setState(() {
      _activeButton = null;
    });
    _repeatTimer?.cancel();
  }

  void _executeAction(String action, VoidCallback callback) {
    if (widget.gameState.isPaused || widget.gameState.isGameOver) return;

    callback();
    widget.onStateChange();
  }

  void _startSinglePress(String action, VoidCallback callback) {
    if (widget.gameState.isPaused || widget.gameState.isGameOver) return;

    // 觸覺回饋
    HapticFeedback.lightImpact();

    // 立即設置按下狀態
    setState(() {
      _activeButton = action;
    });

    callback();
    widget.onStateChange();
  }

  void _stopSinglePress() {
    setState(() {
      _activeButton = null;
    });
  }

  @override
  void dispose() {
    _detach();
    super.dispose();
  }

  Widget _buildRuneSlot(int index) {
    const slotSize = 48.0;

    // 確保符文系統已初始化
    if (!widget.gameState.hasRuneSystemInitialized) {
      return _buildEmptyRuneSlot(slotSize);
    }

    // 獲取符文槽配置和狀態
    final runeType = widget.gameState.runeLoadout.getSlot(index);
    final runeSlot = widget.gameState.runeSystem.slots[index];

    if (runeType == null) {
      // 空槽顯示
      return _buildEmptyRuneSlot(slotSize);
    }

    final definition = RuneConstants.getDefinition(runeType);
    final isDisabled = widget.gameState.isPaused || widget.gameState.isGameOver;
    final currentEnergyBars = widget.gameState.runeEnergyManager.currentBars;
    final hasEnoughEnergy =
        widget.gameState.runeEnergyManager.canConsume(definition.energyCost);
    final canCast = runeSlot.canCast && !isDisabled && hasEnoughEnergy;

    // 🔥 檢查能量檢測是否有問題
    debugPrint(
        'ENERGY DEBUG: currentBars=$currentEnergyBars, needCost=${definition.energyCost}, canConsume=$hasEnoughEnergy');

    // 檢查 UI 與核心狀態是否同步
    final coreEnergyBars = widget.gameState.runeEnergyManager.currentBars;
    final coreCooldown = runeSlot.cooldownRemaining;
    if (coreEnergyBars != widget.gameState.runeEnergyManager.currentBars) {
      logCritical(
          'Energy desync UI=$coreEnergyBars core=${widget.gameState.runeEnergyManager.currentBars}');
    }

    // 🔥 詳細除錯：追蹤所有影響 canCast 的因子
    debugPrint('RuneSlot $index (${definition.name}): '
        'runeSlot.canCast=${runeSlot.canCast}, runeSlot.state=${runeSlot.state}, '
        'disabled=$isDisabled, hasEnoughEnergy=$hasEnoughEnergy (need ${definition.energyCost}), '
        'final canCast=$canCast, cooldownRemaining=${runeSlot.cooldownRemaining}ms, '
        'cooldownEndTime=${runeSlot.cooldownEndTime}, now=${MonotonicTimer.now}');

    return GestureDetector(
      onTap: () {
        // 🔥 ChatGPT建議：強制重新計算最新狀態，確保UI狀態同步
        widget.gameState.runeSystem.slots[index].update(); // 強制更新狀態
        final clickTimeSlot = widget.gameState.runeSystem.slots[index];
        final clickTimeDefinition = RuneConstants.getDefinition(runeType);
        final clickTimeIsDisabled =
            widget.gameState.isPaused || widget.gameState.isGameOver;
        final clickTimeCurrentBars =
            widget.gameState.runeEnergyManager.currentBars;
        final clickTimeHasEnoughEnergy = widget.gameState.runeEnergyManager
            .canConsume(clickTimeDefinition.energyCost);
        final clickTimeCanCast = clickTimeSlot.canCast &&
            !clickTimeIsDisabled &&
            clickTimeHasEnoughEnergy;

        logCritical('=== CLICK DEBUG (ChatGPT修復) ===');
        logCritical('RuneSlot $index clicked!');
        logCritical(
            'UI build canCast=$canCast, currentBars=${currentEnergyBars}, hasEnoughEnergy=$hasEnoughEnergy');
        logCritical(
            'Click time (強制更新後) canCast=$clickTimeCanCast, currentBars=$clickTimeCurrentBars, hasEnoughEnergy=$clickTimeHasEnoughEnergy');
        logCritical(
            'Slot state: ${clickTimeSlot.state}, cooldownRemaining=${clickTimeSlot.cooldownRemaining}ms, needCost: ${clickTimeDefinition.energyCost}');
        logCritical('=============================');

        if (clickTimeCanCast) {
          _castRune(index);
        } else {
          _showRuneError(runeSlot, index);
        }
      },
      child: Container(
        width: slotSize,
        height: slotSize,
        margin: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              definition.themeColor.withOpacity(canCast ? 0.3 : 0.15),
              definition.themeColor.withOpacity(canCast ? 0.2 : 0.1),
            ],
          ),
          border: Border.all(
            color: definition.themeColor.withOpacity(canCast ? 0.8 : 0.4),
            width: canCast ? 2 : 1,
          ),
          boxShadow: canCast
              ? [
                  BoxShadow(
                    color: definition.themeColor.withOpacity(0.4),
                    offset: const Offset(0, 0),
                    blurRadius: 8,
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    offset: const Offset(2, 2),
                    blurRadius: 4,
                  ),
                ],
        ),
        child: Stack(
          children: [
            // 主圖標
            Center(
              child: Icon(
                definition.icon,
                color: definition.themeColor.withOpacity(canCast ? 1.0 : 0.5),
                size: 24,
              ),
            ),

            // 賽博龐克風格冷卻進度環 - 修復版本
            if (!canCast && runeSlot.cooldownRemaining > 0)
              Positioned.fill(
                child: CircularProgressIndicator(
                  value: runeSlot.cooldownProgress,
                  strokeWidth: 3,
                  backgroundColor: Colors.black.withOpacity(0.3),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    cyberpunkAccent.withOpacity(0.8),
                  ),
                ),
              ),

            // 賽博龐克風格冷卻倒數文字 - 修復版本
            if (!canCast && runeSlot.cooldownRemaining > 0)
              Positioned.fill(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Builder(
                      builder: (context) {
                        final cooldownSeconds =
                            (runeSlot.cooldownRemaining / 1000).ceil();

                        // 除錯：檢測修復後的狀態
                        if (cooldownSeconds <= 0) {
                          logCritical('COOLDOWN FIXED! Slot $index: '
                              'canCast=$canCast, cooldownRemaining=${runeSlot.cooldownRemaining}ms, '
                              'cooldownSeconds=$cooldownSeconds, state=${runeSlot.state}');
                        }

                        return Text(
                          '$cooldownSeconds',
                          style: TextStyle(
                            color: const Color(0xFF00FF88), // 賽博龐克綠色
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                color: Colors.white,
                                blurRadius: 2,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),

            // 效果激活時的倒數顯示（用於 Time Slow 等持續性符文）
            if (runeSlot.isActive)
              Positioned.fill(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: cyberpunkAccent.withOpacity(0.6),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      '${(runeSlot.effectRemaining / 1000).ceil()}',
                      style: TextStyle(
                        color: cyberpunkAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            color: cyberpunkAccent.withOpacity(0.7),
                            blurRadius: 6,
                          ),
                          Shadow(
                            color: Colors.black,
                            blurRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // 效果激活脈衝指示器（小圓點）
            if (runeSlot.isActive)
              Positioned(
                top: 2,
                right: 2,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: cyberpunkAccent,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: cyberpunkAccent.withOpacity(0.8),
                        blurRadius: 6,
                        spreadRadius: 1,
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

  Widget _buildEmptyRuneSlot(double slotSize) {
    return Container(
      width: slotSize,
      height: slotSize,
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cyberpunkPrimary.withOpacity(0.1),
            cyberpunkPrimary.withOpacity(0.05),
          ],
        ),
        border: Border.all(
          color: cyberpunkAccent.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            offset: const Offset(2, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.add_circle_outline,
          color: cyberpunkAccent.withOpacity(0.4),
          size: 20,
        ),
      ),
    );
  }

  void _castRune(int index) {
    logCritical('=== RUNE CAST DEBUG ===');

    try {
      // 調試信息：打印當前狀態
      final loadout = widget.gameState.runeLoadout;
      logCritical('Step 1: Got loadout');

      final energyManager = widget.gameState.runeEnergyManager;
      logCritical('Step 2: Got energy manager');

      final runeType = loadout.getSlot(index);
      logCritical('Step 3: Got runeType for slot $index');

      logCritical('Slot $index: ${runeType?.toString() ?? "EMPTY"}');
      logCritical('Energy Status: ${energyManager.toString()}');
      logCritical('Energy canConsume(1): ${energyManager.canConsume(1)}');
      logCritical('Energy canConsume(2): ${energyManager.canConsume(2)}');
      logCritical('Energy canConsume(3): ${energyManager.canConsume(3)}');

      logCritical('Step 4: About to call castRune');
      final result = widget.gameLogic.castRune(index);
      logCritical('Step 5: castRune returned');

      logCritical(
          'Cast Result: Success=${result.isSuccess}, Error=${result.error}, Message=${result.message}');
      logCritical('=======================');

      if (!result.isSuccess) {
        _showRuneErrorByResult(result, index);
      } else {
        // 成功施法，觸覺反饋
        HapticFeedback.mediumImpact();

        if (result.energyRefunded) {
          _showRuneMessage('Energy Refunded', Colors.yellow);
        }
      }
    } catch (e) {
      logCritical('ERROR in _castRune: $e');
    }
  }

  void _showRuneError(RuneSlot runeSlot, int index) {
    // 🔥 修復：使用統一的冷卻判斷邏輯，與UI顯示保持一致
    final runeType = runeSlot.runeType;
    if (runeType != null) {
      final definition = RuneConstants.getDefinition(runeType);
      final isDisabled =
          widget.gameState.isPaused || widget.gameState.isGameOver;
      final hasEnoughEnergy =
          widget.gameState.runeEnergyManager.canConsume(definition.energyCost);
      final finalCanCast = runeSlot.canCast && !isDisabled && hasEnoughEnergy;

      // 按優先級檢查錯誤原因
      if (!runeSlot.canCast && runeSlot.cooldownRemaining > 0) {
        _showRuneErrorFeedback(RuneCastError.cooldownActive, index);
      } else if (runeSlot.isDisabled) {
        _showRuneErrorFeedback(RuneCastError.temporalMutualExclusive, index);
      } else if (!hasEnoughEnergy) {
        _showRuneErrorFeedback(RuneCastError.energyInsufficient, index);
      }
    }
  }

  void _showRuneErrorByResult(RuneCastResult result, int index) {
    _showRuneErrorFeedback(result.error, index);
  }

  void _showRuneErrorFeedback(RuneCastError error, int index) {
    switch (error) {
      case RuneCastError.energyInsufficient:
        // 紅色短閃 + 輕震
        HapticFeedback.lightImpact();
        _flashRuneSlot(index, Colors.red, 200);
        _showRuneMessage('Energy Insufficient', Colors.red);
        break;

      case RuneCastError.cooldownActive:
        // 藍紫色節奏閃 + 無震
        _flashRuneSlot(index, cyberpunkAccent, 500);
        _showRuneMessage('Cooling Down', cyberpunkAccent);
        break;

      case RuneCastError.temporalMutualExclusive:
        // 琥珀色閃 + 輕震 + 固定提示
        HapticFeedback.lightImpact();
        _flashRuneSlot(index, Colors.amber, 300);
        _showRuneMessage('時間系效果互斥', Colors.amber);
        break;

      case RuneCastError.slotEmpty:
        _showRuneMessage('Empty Slot', Colors.grey);
        break;

      case RuneCastError.ghostInvalid:
        HapticFeedback.lightImpact();
        _flashRuneSlot(index, Colors.orange, 250);
        _showRuneMessage('Invalid Ghost Position', Colors.orange);
        break;

      default:
        _showRuneMessage('Cast Failed', Colors.red);
        break;
    }
  }

  void _flashRuneSlot(int index, Color color, int durationMs) {
    // 槽位閃爍效果的實現
    // 這裡可以通過setState觸發重繪，或使用Animation
    // 簡化版本：只觸發重繪
    setState(() {});

    Timer(Duration(milliseconds: durationMs), () {
      setState(() {});
    });
  }

  void _showRuneMessage(String message, Color color) {
    // 顯示符文操作消息
    // 可以用 SnackBar 或自定義浮動提示
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color.withOpacity(0.8),
        duration: const Duration(milliseconds: 1500),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 100, left: 20, right: 20),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String action,
    required VoidCallback onPressed,
    bool allowRepeat = false,
    double size = 72,
  }) {
    final bool isDisabled =
        widget.gameState.isPaused || widget.gameState.isGameOver;
    final bool isActive = _activeButton == action && !isDisabled;

    // 所有控制按鈕都使用增強效果
    final bool isDPadButton = [
      'left',
      'right',
      'down',
      'rotate',
      'rotate_ccw',
      'hard_drop'
    ].contains(action);

    // Cyberpunk 霓虹藍配色
    const neumorphBase = Color(0xFF00D9FF); // 主霓虹藍
    const neumorphLight = Color(0xFF33E2FF); // 亮霓虹藍
    const neumorphDark = Color(0xFF00A6CC); // 暗霓虹藍
    const cyberpunkAccent = Color(0xFF00FF88); // 霓虹綠
    const cyberpunkPink = Color(0xFFFF0080); // 電光粉

    // 鍵帽尺寸與位移計算
    final bezelSize = size;
    final keycapSize = size - 4; // 鍵帽略小於外框
    final pressOffset = isDPadButton ? 5.0 : 4.0; // 下壓距離

    return Container(
      width: bezelSize,
      height: bezelSize,
      margin: const EdgeInsets.all(3),
      child: Stack(
        children: [
          // 固定外框 (Bezel/Chassis)
          Container(
            width: bezelSize,
            height: bezelSize,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(isDPadButton ? 16 : 14),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1A1A1A), // 深灰框架
                  Color(0xFF0D0D0D), // 更深底色
                ],
              ),
              boxShadow: [
                // 外框深色陰影
                const BoxShadow(
                  color: Color(0x80000000),
                  offset: Offset(0, 2),
                  blurRadius: 4,
                ),
              ],
            ),
          ),

          // 可動鍵帽 (Keycap)
          AnimatedSlide(
            offset: isActive ? Offset(0, pressOffset / bezelSize) : Offset.zero,
            duration: Duration(milliseconds: isActive ? 100 : 5),
            curve: isActive ? Curves.easeOutCubic : Curves.linear,
            child: AnimatedScale(
              scale: isActive ? 0.985 : 1.0,
              duration: Duration(milliseconds: isActive ? 100 : 5),
              curve: isActive ? Curves.easeOutCubic : Curves.linear,
              child: Container(
                margin: const EdgeInsets.all(2), // 鍵帽與外框間隙
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(isDPadButton ? 14 : 12),
                  child: Container(
                    width: keycapSize,
                    height: keycapSize,
                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(isDPadButton ? 14 : 12),
                      // Neumorphism 鍵帽漸變
                      gradient: isDisabled
                          ? LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                neumorphBase.withOpacity(0.3),
                                neumorphDark.withOpacity(0.3),
                              ],
                            )
                          : LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: isActive
                                  ? [
                                      neumorphDark,
                                      neumorphBase.withOpacity(0.9),
                                    ]
                                  : [
                                      neumorphLight,
                                      neumorphBase,
                                    ],
                            ),
                      // 外陰影系統 (不使用內陰影)
                      boxShadow: isDisabled
                          ? [
                              const BoxShadow(
                                color: Color(0x1A000000),
                                offset: Offset(2, 2),
                                blurRadius: 4,
                              ),
                            ]
                          : isActive
                              ? [
                                  // Pressed 狀態：縮短陰影
                                  const BoxShadow(
                                    color: Color(0x0AFFFFFF), // 高光
                                    offset: Offset(-2, -2),
                                    blurRadius: 6,
                                  ),
                                  const BoxShadow(
                                    color: Color(0x4D000000), // 暗影
                                    offset: Offset(3, 3),
                                    blurRadius: 8,
                                  ),
                                  // 霓虹光環縮小
                                  BoxShadow(
                                    color: isDPadButton
                                        ? cyberpunkAccent.withOpacity(0.3)
                                        : neumorphBase.withOpacity(0.4),
                                    offset: const Offset(0, 0),
                                    blurRadius: isDPadButton ? 12 : 10,
                                  ),
                                ]
                              : [
                                  // Normal 狀態：完整外陰影
                                  const BoxShadow(
                                    color: Color(0x14FFFFFF), // 高光 (左上)
                                    offset: Offset(-4, -4),
                                    blurRadius: 10,
                                  ),
                                  const BoxShadow(
                                    color: Color(0x59000000), // 暗影 (右下)
                                    offset: Offset(6, 6),
                                    blurRadius: 16,
                                  ),
                                  // 霓虹外光環
                                  BoxShadow(
                                    color: isDPadButton
                                        ? cyberpunkAccent.withOpacity(0.35)
                                        : neumorphBase.withOpacity(0.55),
                                    offset: const Offset(0, 0),
                                    blurRadius: isDPadButton ? 20 : 16,
                                    spreadRadius: -2,
                                  ),
                                  // D-Pad 額外霓虹環
                                  if (isDPadButton)
                                    BoxShadow(
                                      color: cyberpunkPink.withOpacity(0.15),
                                      offset: const Offset(0, 0),
                                      blurRadius: 28,
                                      spreadRadius: -4,
                                    ),
                                ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius:
                          BorderRadius.circular(isDPadButton ? 14 : 12),
                      child: InkWell(
                        borderRadius:
                            BorderRadius.circular(isDPadButton ? 14 : 12),
                        hoverColor: neumorphBase.withOpacity(0.1),
                        splashColor: isDPadButton
                            ? cyberpunkAccent.withOpacity(0.3)
                            : neumorphBase.withOpacity(0.3),
                        onTapDown: !isDisabled
                            ? allowRepeat
                                ? (_) => _startRepeat(action, onPressed)
                                : (_) => _startSinglePress(action, onPressed)
                            : null,
                        onTapUp: !isDisabled
                            ? allowRepeat
                                ? (_) => _stopRepeat()
                                : (_) => _stopSinglePress()
                            : null,
                        onTapCancel: !isDisabled
                            ? allowRepeat
                                ? _stopRepeat
                                : _stopSinglePress
                            : null,
                        child: Center(
                          child: Icon(
                            icon,
                            color: isDisabled
                                ? neumorphBase.withOpacity(0.3)
                                : isActive
                                    ? (isDPadButton
                                        ? cyberpunkAccent // 按下時霓虹綠
                                        : Colors.white) // 按下時白色
                                    : Colors.black.withOpacity(0.8),
                            size: keycapSize * (isDPadButton ? 0.45 : 0.4),
                            shadows: isDisabled
                                ? null
                                : [
                                    // 主要圖示光效
                                    Shadow(
                                      color: isActive
                                          ? (isDPadButton
                                              ? cyberpunkAccent.withOpacity(0.9)
                                              : Colors.white.withOpacity(0.9))
                                          : Colors.black.withOpacity(0.6),
                                      blurRadius: isDPadButton ? 8 : 6,
                                      offset: const Offset(0, 0),
                                    ),
                                    // 圖示陰影層次
                                    const Shadow(
                                      color: Color(0x66000000),
                                      blurRadius: 2,
                                      offset: Offset(1, 1),
                                    ),
                                    // D-Pad 專用圖示內霓虹光
                                    if (isDPadButton)
                                      Shadow(
                                        color: isActive
                                            ? cyberpunkAccent.withOpacity(0.7)
                                            : cyberpunkPink.withOpacity(0.4),
                                        blurRadius: 10,
                                        offset: const Offset(0, 0),
                                      ),
                                  ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // 計算控制區域寬度，確保不為負數
    final controlWidth = (screenWidth - 32).clamp(200.0, double.infinity);

    return Container(
      width: controlWidth,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cyberpunkPanel,
            cyberpunkBgDeep,
            cyberpunkPanel.withOpacity(0.8),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(cyberpunkBorderRadiusLarge + 4),
        border: Border.all(
          color: cyberpunkPrimary.withOpacity(0.6),
          width: cyberpunkBorderWidth,
        ),
        boxShadow: [
          ...cyberpunkPanelShadow,
          BoxShadow(
            color: cyberpunkPrimary.withOpacity(0.15),
            blurRadius: cyberpunkGlowStrong,
            spreadRadius: -2,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 觸控按鈕區域 (置中)
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 旋轉按鈕和硬降按鈕
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildControlButton(
                    icon: Icons.rotate_left,
                    action: 'rotate_ccw',
                    onPressed: widget.gameLogic.rotateCounterClockwise,
                    allowRepeat: false,
                    size: 56,
                  ),
                  _buildControlButton(
                    icon: Icons.rotate_right,
                    action: 'rotate',
                    onPressed: widget.gameLogic.rotate,
                    allowRepeat: false,
                    size: 60,
                  ),
                  _buildControlButton(
                    icon: Icons.vertical_align_bottom,
                    action: 'hard_drop',
                    onPressed: widget.gameLogic.hardDrop,
                    allowRepeat: false,
                    size: 56,
                  ),
                ],
              ),

              const SizedBox(height: 6),

              // 方向按鈕
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 左移
                  _buildControlButton(
                    icon: Icons.keyboard_arrow_left,
                    action: 'left',
                    onPressed: widget.gameLogic.moveLeft,
                    allowRepeat: true,
                    size: 56,
                  ),

                  // 快速下降
                  _buildControlButton(
                    icon: Icons.keyboard_arrow_down,
                    action: 'down',
                    onPressed: widget.gameLogic.moveDown,
                    allowRepeat: true,
                    size: 56,
                  ),

                  // 右移
                  _buildControlButton(
                    icon: Icons.keyboard_arrow_right,
                    action: 'right',
                    onPressed: widget.gameLogic.moveRight,
                    allowRepeat: true,
                    size: 56,
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(width: 16),

          // 符文槽區域 (右側)
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildRuneSlot(0),
              _buildRuneSlot(1),
              _buildRuneSlot(2),
            ],
          ),
        ],
      ),
    );
  }
}
