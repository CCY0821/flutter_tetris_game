import 'rune_events.dart';
import 'rune_definitions.dart';

/// 符文配置類
/// 管理玩家攜帶的3個符文槽位
class RuneLoadout {
  /// 3個符文槽位（可以為空）
  List<RuneType?> slots = [null, null, null];

  /// 最大槽位數量
  static const int maxSlots = 3;

  RuneLoadout({List<RuneType?>? initialSlots}) {
    if (initialSlots != null) {
      slots = List<RuneType?>.from(initialSlots);
      // 確保槽位數量正確
      while (slots.length < maxSlots) {
        slots.add(null);
      }
      if (slots.length > maxSlots) {
        slots = slots.take(maxSlots).toList();
      }
    }
  }

  /// 檢查配置是否合法
  /// 規則：3格能量符文只能選擇其中一個
  bool isValidLoadout() {
    final threeEnergyRunes = slots
        .where((rune) => rune != null)
        .where((rune) => RuneConstants.getDefinition(rune!).energyCost == 3)
        .toList();

    return threeEnergyRunes.length <= 1;
  }

  /// 設置指定槽位的符文
  /// 返回是否設置成功（會檢查3格符文限制）
  bool setSlot(int index, RuneType? rune) {
    if (index < 0 || index >= maxSlots) {
      return false;
    }

    // 創建測試配置
    final testSlots = List<RuneType?>.from(slots);
    testSlots[index] = rune;

    // 檢查3格符文限制
    final testLoadout = RuneLoadout(initialSlots: testSlots);
    if (!testLoadout.isValidLoadout()) {
      return false;
    }

    // 設置成功
    slots[index] = rune;
    return true;
  }

  /// 移除指定槽位的符文
  void removeSlot(int index) {
    if (index >= 0 && index < maxSlots) {
      slots[index] = null;
    }
  }

  /// 清空所有槽位
  void clear() {
    for (int i = 0; i < maxSlots; i++) {
      slots[i] = null;
    }
  }

  /// 獲取指定槽位的符文
  RuneType? getSlot(int index) {
    if (index >= 0 && index < maxSlots) {
      return slots[index];
    }
    return null;
  }

  /// 檢查是否包含指定符文
  bool containsRune(RuneType rune) {
    return slots.contains(rune);
  }

  /// 獲取符文所在的槽位索引（-1表示未找到）
  int getSlotIndex(RuneType rune) {
    return slots.indexOf(rune);
  }

  /// 獲取已使用的槽位數量
  int get usedSlots => slots.where((rune) => rune != null).length;

  /// 獲取空槽位數量
  int get emptySlots => maxSlots - usedSlots;

  /// 檢查是否有空槽位
  bool get hasEmptySlot => emptySlots > 0;

  /// 檢查是否已滿
  bool get isFull => emptySlots == 0;

  /// 檢查是否為空
  bool get isEmpty => usedSlots == 0;

  /// 獲取已配置的符文列表（不包含null）
  List<RuneType> get configuredRunes {
    return slots.where((rune) => rune != null).cast<RuneType>().toList();
  }

  /// 獲取當前的3格符文（如果有的話）
  RuneType? get threeEnergyRune {
    return slots.where((rune) => rune != null).firstWhere(
          (rune) => RuneConstants.getDefinition(rune!).energyCost == 3,
          orElse: () => null,
        );
  }

  /// 檢查是否可以添加指定符文
  /// 考慮3格符文限制和槽位限制
  bool canAddRune(RuneType rune) {
    // 如果已經包含這個符文，不能重複添加
    if (containsRune(rune)) {
      return false;
    }

    // 如果沒有空槽位，不能添加
    if (!hasEmptySlot) {
      return false;
    }

    // 檢查3格符文限制
    final runeDefinition = RuneConstants.getDefinition(rune);
    if (runeDefinition.energyCost == 3) {
      // 如果要添加的是3格符文，檢查是否已經有其他3格符文
      return threeEnergyRune == null;
    }

    return true;
  }

  /// 添加符文到第一個空槽位
  /// 返回添加的槽位索引，失敗返回-1
  int addRune(RuneType rune) {
    if (!canAddRune(rune)) {
      return -1;
    }

    // 找到第一個空槽位
    for (int i = 0; i < maxSlots; i++) {
      if (slots[i] == null) {
        slots[i] = rune;
        return i;
      }
    }

    return -1;
  }

  /// 交換兩個槽位的符文
  void swapSlots(int index1, int index2) {
    if (index1 >= 0 &&
        index1 < maxSlots &&
        index2 >= 0 &&
        index2 < maxSlots &&
        index1 != index2) {
      final temp = slots[index1];
      slots[index1] = slots[index2];
      slots[index2] = temp;
    }
  }

  /// 複製配置
  RuneLoadout copy() {
    return RuneLoadout(initialSlots: List<RuneType?>.from(slots));
  }

  /// 從JSON恢復配置
  static RuneLoadout fromJson(Map<String, dynamic> json) {
    final List<dynamic> slotsData = json['slots'] as List<dynamic>? ?? [];
    final List<RuneType?> slots = [];

    for (int i = 0; i < maxSlots; i++) {
      if (i < slotsData.length && slotsData[i] != null) {
        final runeTypeName = slotsData[i] as String;
        try {
          final runeType = RuneType.values.firstWhere(
            (type) => type.name == runeTypeName,
          );
          slots.add(runeType);
        } catch (e) {
          slots.add(null); // 無效的符文類型，設為空
        }
      } else {
        slots.add(null);
      }
    }

    return RuneLoadout(initialSlots: slots);
  }

  /// 轉換為JSON格式（用於持久化）
  Map<String, dynamic> toJson() {
    return {
      'slots': slots.map((rune) => rune?.name).toList(),
      'version': 1, // 版本號，用於未來兼容性
    };
  }

  /// 驗證配置完整性
  ValidationResult validate() {
    // 檢查槽位數量
    if (slots.length != maxSlots) {
      return ValidationResult.error('槽位數量不正確');
    }

    // 檢查3格符文限制
    if (!isValidLoadout()) {
      return ValidationResult.error('3格能量符文只能選擇其中一個');
    }

    // 檢查重複符文
    final nonNullRunes = slots.where((rune) => rune != null).toList();
    final uniqueRunes = nonNullRunes.toSet();
    if (nonNullRunes.length != uniqueRunes.length) {
      return ValidationResult.error('不能配置重複的符文');
    }

    return ValidationResult.success();
  }

  @override
  String toString() {
    final runeNames = slots
        .map((rune) =>
            rune != null ? RuneConstants.getDefinition(rune).name : 'Empty')
        .join(', ');
    return 'RuneLoadout([$runeNames])';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! RuneLoadout) return false;

    if (slots.length != other.slots.length) return false;
    for (int i = 0; i < slots.length; i++) {
      if (slots[i] != other.slots[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode {
    return Object.hashAll(slots);
  }
}

/// 配置驗證結果
class ValidationResult {
  final bool isValid;
  final String? errorMessage;

  const ValidationResult._(this.isValid, this.errorMessage);

  static ValidationResult success() => const ValidationResult._(true, null);
  static ValidationResult error(String message) =>
      ValidationResult._(false, message);

  @override
  String toString() {
    return isValid ? 'Valid' : 'Invalid: $errorMessage';
  }
}
