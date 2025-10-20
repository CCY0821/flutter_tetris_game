import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/game_theme.dart';
import '../core/constants.dart';
import '../game/rune_definitions.dart';
import '../game/rune_loadout.dart';
import '../game/rune_events.dart';

/// 符文選擇頁面
/// 允許玩家配置3個符文槽，遵循3格符文限制規則
class RuneSelectionPage extends StatefulWidget {
  final RuneLoadout initialLoadout;
  final VoidCallback? onLoadoutChanged;

  const RuneSelectionPage({
    super.key,
    required this.initialLoadout,
    this.onLoadoutChanged,
  });

  @override
  State<RuneSelectionPage> createState() => _RuneSelectionPageState();
}

class _RuneSelectionPageState extends State<RuneSelectionPage> {
  late RuneLoadout _currentLoadout;
  int? _selectedSlot;

  @override
  void initState() {
    super.initState();
    _currentLoadout = widget.initialLoadout.copy();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.95,
        constraints: BoxConstraints(
          maxWidth: 600,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
          minHeight: 400,
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
          mainAxisSize: MainAxisSize.max,
          children: [
            // 標題欄
            _buildHeader(),

            // 符文槽配置區
            _buildLoadoutSection(),

            // 分隔線
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    cyberpunkPrimary.withOpacity(0.5),
                    Colors.transparent,
                  ],
                ),
              ),
            ),

            // 符文選擇區
            Expanded(
              child: _buildRuneGrid(),
            ),

            // 底部按鈕區
            _buildBottomActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
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
              'RUNE LOADOUT',
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
              backgroundColor: Colors.red.withOpacity(0.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadoutSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ACTIVE LOADOUT (3 SLOTS)',
            style: GameTheme.subtitleStyle.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: cyberpunkPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (int i = 0; i < RuneLoadout.maxSlots; i++)
                _buildLoadoutSlot(i),
            ],
          ),
          const SizedBox(height: 12),
          _buildLoadoutStatus(),
        ],
      ),
    );
  }

  Widget _buildLoadoutSlot(int index) {
    final runeType = _currentLoadout.getSlot(index);
    final isSelected = _selectedSlot == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedSlot = isSelected ? null : index;
        });
        HapticFeedback.lightImpact();
      },
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(cyberpunkBorderRadius),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: runeType != null
                ? [
                    RuneConstants.getDefinition(runeType)
                        .themeColor
                        .withOpacity(0.3),
                    RuneConstants.getDefinition(runeType)
                        .themeColor
                        .withOpacity(0.1),
                  ]
                : [
                    cyberpunkPanel.withOpacity(0.3),
                    cyberpunkBgDeep.withOpacity(0.5),
                  ],
          ),
          border: Border.all(
            color: isSelected
                ? cyberpunkPrimary
                : (runeType != null
                    ? RuneConstants.getDefinition(runeType)
                        .themeColor
                        .withOpacity(0.5)
                    : cyberpunkPrimary.withOpacity(0.3)),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: cyberpunkPrimary.withOpacity(0.5),
                    blurRadius: cyberpunkGlowMed,
                    offset: const Offset(0, 0),
                  ),
                ]
              : null,
        ),
        child: runeType != null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    RuneConstants.getDefinition(runeType).icon,
                    color: RuneConstants.getDefinition(runeType).themeColor,
                    size: 28,
                  ),
                  const SizedBox(height: 4),
                  _buildEnergyIndicator(
                      RuneConstants.getDefinition(runeType).energyCost),
                ],
              )
            : Icon(
                Icons.add,
                color: cyberpunkPrimary.withOpacity(0.5),
                size: 32,
              ),
      ),
    );
  }

  Widget _buildEnergyIndicator(int cost) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        3,
        (index) => Container(
          width: 6,
          height: 8,
          margin: const EdgeInsets.only(left: 1),
          decoration: BoxDecoration(
            color: index < cost
                ? cyberpunkAccent
                : cyberpunkAccent.withOpacity(0.2),
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadoutStatus() {
    final validation = _currentLoadout.validate();
    final usedSlots = _currentLoadout.usedSlots;
    final threeEnergyRune = _currentLoadout.threeEnergyRune;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              validation.isValid ? Icons.check_circle : Icons.error,
              color: validation.isValid ? cyberpunkAccent : Colors.red,
              size: 16,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                validation.isValid
                    ? 'Loadout Valid ($usedSlots/3 slots used)'
                    : validation.errorMessage!,
                style: GameTheme.bodyStyle.copyWith(
                  fontSize: 12,
                  color: validation.isValid ? cyberpunkAccent : Colors.red,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        if (threeEnergyRune != null) ...[
          const SizedBox(height: 4),
          Text(
            '3-Energy Rune: ${RuneConstants.getDefinition(threeEnergyRune).name}',
            style: GameTheme.bodyStyle.copyWith(
              fontSize: 11,
              color: Colors.orange,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRuneGrid() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SELECT RUNES',
            style: GameTheme.subtitleStyle.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: cyberpunkPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: RuneConstants.allTypes.length,
            itemBuilder: (context, index) {
              final runeType = RuneConstants.allTypes[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildRuneCard(runeType),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRuneCard(RuneType runeType) {
    final definition = RuneConstants.getDefinition(runeType);
    final isInLoadout = _currentLoadout.containsRune(runeType);
    final isDisabled = _shouldDisableRune(runeType);

    return GestureDetector(
      onTap: isDisabled ? null : () => _onRuneCardTap(runeType),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              definition.themeColor.withOpacity(isInLoadout ? 0.3 : 0.1),
              definition.themeColor.withOpacity(isInLoadout ? 0.2 : 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(cyberpunkBorderRadius),
          border: Border.all(
            color: isInLoadout
                ? definition.themeColor
                : definition.themeColor.withOpacity(0.3),
            width: isInLoadout ? 2 : 1,
          ),
          boxShadow: isInLoadout
              ? [
                  BoxShadow(
                    color: definition.themeColor.withOpacity(0.3),
                    blurRadius: cyberpunkGlowMed,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Opacity(
          opacity: isDisabled ? 0.5 : 1.0,
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: definition.themeColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  definition.icon,
                  color: definition.themeColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      definition.name,
                      style: GameTheme.subtitleStyle.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: definition.themeColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      definition.description,
                      style: GameTheme.bodyStyle.copyWith(
                        fontSize: 12,
                        color: Colors.grey[300],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _buildEnergyIndicator(definition.energyCost),
                        const SizedBox(width: 12),
                        Text(
                          '${definition.cooldownSeconds}s CD',
                          style: GameTheme.bodyStyle.copyWith(
                            fontSize: 11,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (definition.durationSeconds > 0) ...[
                          const SizedBox(width: 12),
                          Text(
                            '${definition.durationSeconds}s Duration',
                            style: GameTheme.bodyStyle.copyWith(
                              fontSize: 11,
                              color: Colors.amber[300],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (isInLoadout)
                Icon(
                  Icons.check_circle,
                  color: definition.themeColor,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }

  bool _shouldDisableRune(RuneType runeType) {
    final definition = RuneConstants.getDefinition(runeType);

    // 如果已經在配置中，不禁用
    if (_currentLoadout.containsRune(runeType)) {
      return false;
    }

    // 檢查3格符文限制
    if (definition.energyCost == 3) {
      final currentThreeEnergyRune = _currentLoadout.threeEnergyRune;
      return currentThreeEnergyRune != null;
    }

    return false;
  }

  void _onRuneCardTap(RuneType runeType) {
    HapticFeedback.lightImpact();

    setState(() {
      if (_currentLoadout.containsRune(runeType)) {
        // 移除符文
        final slotIndex = _currentLoadout.getSlotIndex(runeType);
        if (slotIndex >= 0) {
          _currentLoadout.removeSlot(slotIndex);
        }
      } else {
        // 添加符文
        if (_selectedSlot != null) {
          // 添加到選中的槽位
          _currentLoadout.setSlot(_selectedSlot!, runeType);
          _selectedSlot = null;
        } else {
          // 添加到第一個空槽位
          _currentLoadout.addRune(runeType);
        }
      }
    });
  }

  Widget _buildBottomActions() {
    final validation = _currentLoadout.validate();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            cyberpunkPanel.withOpacity(0.3),
            cyberpunkBgDeep.withOpacity(0.5),
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(18),
          bottomRight: Radius.circular(18),
        ),
      ),
      child: Row(
        children: [
          // 清空按鈕
          Expanded(
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.red.withOpacity(0.15),
                    Colors.red.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(cyberpunkBorderRadius),
                border: Border.all(
                  color: Colors.red.withOpacity(0.4),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _currentLoadout.clear();
                    _selectedSlot = null;
                  });
                  HapticFeedback.lightImpact();
                },
                icon: const Icon(Icons.clear_all, size: 20),
                label: Text(
                  'CLEAR',
                  style: GameTheme.subtitleStyle.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.red[300],
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(cyberpunkBorderRadius),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
          ),

          const SizedBox(width: 16),

          // 確認按鈕
          Expanded(
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: validation.isValid
                      ? [
                          cyberpunkPrimary.withOpacity(0.8),
                          cyberpunkPrimary.withOpacity(0.6),
                        ]
                      : [
                          Colors.grey.withOpacity(0.3),
                          Colors.grey.withOpacity(0.1),
                        ],
                ),
                borderRadius: BorderRadius.circular(cyberpunkBorderRadius),
                border: Border.all(
                  color: validation.isValid
                      ? cyberpunkPrimary.withOpacity(0.8)
                      : Colors.grey.withOpacity(0.5),
                  width: 1.5,
                ),
                boxShadow: validation.isValid
                    ? [
                        BoxShadow(
                          color: cyberpunkPrimary.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: ElevatedButton.icon(
                onPressed: validation.isValid ? _onConfirm : null,
                icon: Icon(
                  validation.isValid ? Icons.check_circle : Icons.error_outline,
                  size: 20,
                ),
                label: Text(
                  'CONFIRM',
                  style: GameTheme.subtitleStyle.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor:
                      validation.isValid ? Colors.white : Colors.grey[400],
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(cyberpunkBorderRadius),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onConfirm() {
    // 複製配置到原始loadout
    widget.initialLoadout.slots = List<RuneType?>.from(_currentLoadout.slots);

    // 通知變更
    widget.onLoadoutChanged?.call();

    // 觸覺反饋
    HapticFeedback.mediumImpact();

    // 關閉對話框
    Navigator.of(context).pop(true);

    debugPrint(
        'RuneSelectionPage: Loadout confirmed - ${widget.initialLoadout}');
  }
}
