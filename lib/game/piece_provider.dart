import '../models/tetromino.dart';
import 'dart:math';
import 'package:flutter/foundation.dart';

/// 方塊供應器接口
/// 提供可堆疊的裝飾器模式，支援多種方塊生成策略
abstract class IPieceProvider {
  /// 獲取下一個方塊類型
  TetrominoType getNext();

  /// 預覽接下來的 count 個方塊類型（不影響實際生成）
  List<TetrominoType> preview(int count);

  /// 檢查攔截器是否已用完（用於自動清理）
  bool get isExhausted;

  /// 攔截器優先級（數字越小優先級越高）
  int get priority;

  /// 攔截器類型描述（用於調試）
  String get description;
}

/// 基礎7-bag隨機方塊供應器
/// 實現標準俄羅斯方塊的7-bag算法
class BagProvider implements IPieceProvider {
  final Random _random;
  final Set<TetrominoType> _excludedTypes;
  List<TetrominoType> _bag = [];
  int _bagIndex = 0;

  BagProvider({Random? random, Set<TetrominoType>? excludedTypes})
      : _random = random ?? Random(),
        _excludedTypes = excludedTypes ?? {};

  @override
  TetrominoType getNext() {
    if (_bagIndex >= _bag.length) {
      _refillBag();
      _bagIndex = 0;
    }

    final piece = _bag[_bagIndex];
    _bagIndex++;
    return piece;
  }

  @override
  List<TetrominoType> preview(int count) {
    final result = <TetrominoType>[];

    // 創建當前狀態的副本來模擬預覽
    final tempBag = List<TetrominoType>.from(_bag);
    int tempIndex = _bagIndex;

    for (int i = 0; i < count; i++) {
      if (tempIndex >= tempBag.length) {
        // 需要重新填充bag
        tempBag.clear();
        tempBag.addAll(_generateNewBag());
        tempIndex = 0;
      }

      result.add(tempBag[tempIndex]);
      tempIndex++;
    }

    return result;
  }

  @override
  bool get isExhausted => false; // 基礎提供器永不耗盡

  @override
  int get priority => 1000; // 最低優先級

  @override
  String get description => 'BagProvider(7-bag RNG)';

  /// 重新填充方塊袋
  void _refillBag() {
    _bag = _generateNewBag();
  }

  /// 生成新的bag序列（排除指定類型）
  List<TetrominoType> _generateNewBag() {
    final newBag = TetrominoType.values
        .where((type) => !_excludedTypes.contains(type))
        .toList();
    newBag.shuffle(_random);
    return newBag;
  }

  /// 獲取當前bag狀態（用於調試和持久化）
  Map<String, dynamic> getState() {
    return {
      'bag': _bag.map((t) => t.name).toList(),
      'bagIndex': _bagIndex,
    };
  }

  /// 從狀態恢復（用於持久化）
  void restoreState(Map<String, dynamic> state) {
    _bag = (state['bag'] as List<dynamic>)
        .map((name) => TetrominoType.values.firstWhere((t) => t.name == name))
        .toList();
    _bagIndex = state['bagIndex'] as int;
  }
}

/// 強制序列攔截器
/// 強制接下來的 N 個方塊為指定類型
class ForcedSequenceProvider implements IPieceProvider {
  final TetrominoType forcedType;
  final IPieceProvider baseProvider;
  int remaining;

  ForcedSequenceProvider({
    required this.forcedType,
    required this.remaining,
    required this.baseProvider,
  });

  @override
  TetrominoType getNext() {
    if (remaining > 0) {
      remaining--;
      return forcedType;
    }

    // 已用完，委派給下層提供器
    return baseProvider.getNext();
  }

  @override
  List<TetrominoType> preview(int count) {
    final result = <TetrominoType>[];
    int tempRemaining = remaining;

    // 先填充強制類型
    for (int i = 0; i < count && tempRemaining > 0; i++) {
      result.add(forcedType);
      tempRemaining--;
    }

    // 如果還需要更多預覽，從基礎提供器獲取
    if (result.length < count) {
      final basePreview = baseProvider.preview(count - result.length);
      result.addAll(basePreview);
    }

    return result;
  }

  @override
  bool get isExhausted => remaining <= 0;

  @override
  int get priority => 100; // Hard-Force 高優先級

  @override
  String get description => 'ForcedSequence($forcedType × $remaining)';

  /// 獲取狀態（用於持久化）
  Map<String, dynamic> getState() {
    return {
      'forcedType': forcedType.name,
      'remaining': remaining,
      'baseState': baseProvider is BagProvider
          ? (baseProvider as BagProvider).getState()
          : null,
    };
  }

  /// 從狀態恢復
  static ForcedSequenceProvider fromState(
      Map<String, dynamic> state, IPieceProvider baseProvider) {
    final forcedType =
        TetrominoType.values.firstWhere((t) => t.name == state['forcedType']);
    final remaining = state['remaining'] as int;

    return ForcedSequenceProvider(
      forcedType: forcedType,
      remaining: remaining,
      baseProvider: baseProvider,
    );
  }
}

/// 方塊供應器堆疊管理器
/// 實現LIFO堆疊，管理多個攔截器的生命周期
class PieceProviderStack {
  final List<IPieceProvider> _stack = [];
  late IPieceProvider _baseProvider;

  PieceProviderStack({IPieceProvider? baseProvider}) {
    _baseProvider = baseProvider ?? BagProvider();
  }

  /// 添加新的攔截器到堆疊頂部（LIFO）
  void push(IPieceProvider provider) {
    _stack.add(provider);
    debugPrint('[PieceProviderStack] Pushed ${provider.description}');
  }

  /// 獲取下一個方塊類型
  TetrominoType getNext() {
    _cleanupExhausted();

    if (_stack.isNotEmpty) {
      return _stack.last.getNext();
    }

    return _baseProvider.getNext();
  }

  /// 預覽接下來的方塊類型
  List<TetrominoType> preview(int count) {
    _cleanupExhausted();

    if (_stack.isNotEmpty) {
      return _stack.last.preview(count);
    }

    return _baseProvider.preview(count);
  }

  /// 清理已用完的攔截器
  void _cleanupExhausted() {
    final initialCount = _stack.length;
    _stack.removeWhere((provider) {
      final exhausted = provider.isExhausted;
      if (exhausted) {
        debugPrint(
            'PieceProviderStack: Removed exhausted ${provider.description}');
      }
      return exhausted;
    });

    if (_stack.length != initialCount) {
      debugPrint(
          'PieceProviderStack: Cleaned ${initialCount - _stack.length} exhausted providers');
    }
  }

  /// 檢查當前頂層攔截器
  IPieceProvider? get topProvider => _stack.isNotEmpty ? _stack.last : null;

  /// 檢查堆疊深度
  int get stackDepth => _stack.length;

  /// 檢查堆疊是否為空
  bool get isEmpty => _stack.isEmpty;

  /// 獲取堆疊狀態描述（用於調試）
  String get stackDescription {
    if (_stack.isEmpty) {
      return 'Empty stack (using ${_baseProvider.description})';
    }

    final descriptions = _stack.map((p) => p.description).toList();
    return 'Stack: ${descriptions.join(' -> ')} -> ${_baseProvider.description}';
  }

  /// 清空所有攔截器（用於重置遊戲狀態）
  void clear() {
    debugPrint('[PieceProviderStack] Clearing ${_stack.length} providers');
    _stack.clear();
  }

  /// 獲取完整狀態（用於持久化）
  Map<String, dynamic> getState() {
    return {
      'baseProviderState': _baseProvider is BagProvider
          ? (_baseProvider as BagProvider).getState()
          : null,
      'stackStates': _stack.map((provider) {
        if (provider is ForcedSequenceProvider) {
          return {
            'type': 'ForcedSequence',
            'state': provider.getState(),
          };
        }
        return {
          'type': 'Unknown',
          'state': {},
        };
      }).toList(),
    };
  }

  /// 從狀態恢復
  void restoreState(Map<String, dynamic> state) {
    // 恢復基礎提供器
    if (state['baseProviderState'] != null && _baseProvider is BagProvider) {
      (_baseProvider as BagProvider).restoreState(state['baseProviderState']);
    }

    // 恢復堆疊
    _stack.clear();
    final stackStates = state['stackStates'] as List<dynamic>? ?? [];

    for (final stackState in stackStates) {
      final type = stackState['type'] as String;
      final providerState = stackState['state'] as Map<String, dynamic>;

      if (type == 'ForcedSequence') {
        final provider =
            ForcedSequenceProvider.fromState(providerState, _baseProvider);
        _stack.add(provider);
      }
    }

    debugPrint(
        'PieceProviderStack: Restored state with ${_stack.length} providers');
  }
}

/// 稀有方塊攔截器
/// 在指定週期內隨機插入稀有方塊（如H型）
/// 例如：每30個方塊隨機出現1次H型
class RareBlockInterceptor implements IPieceProvider {
  final IPieceProvider baseProvider;
  final TetrominoType rareType;
  final int cycleLength;
  final Random _random;

  int _currentCount = 0;
  int _rarePositionInCycle = -1;

  RareBlockInterceptor({
    required this.baseProvider,
    required this.rareType,
    required this.cycleLength,
    Random? random,
  }) : _random = random ?? Random() {
    _initNewCycle();
  }

  /// 初始化新週期，隨機決定稀有方塊的位置
  void _initNewCycle() {
    _rarePositionInCycle = _random.nextInt(cycleLength);
    debugPrint(
        '[RareBlockInterceptor] New cycle: $rareType will appear at position $_rarePositionInCycle/$cycleLength');
  }

  @override
  TetrominoType getNext() {
    // 檢查是否該出現稀有方塊
    if (_currentCount == _rarePositionInCycle) {
      _currentCount++;
      if (_currentCount >= cycleLength) {
        _currentCount = 0;
        _initNewCycle();
      }
      return rareType;
    }

    // 否則從基礎提供器獲取
    final next = baseProvider.getNext();

    _currentCount++;
    if (_currentCount >= cycleLength) {
      _currentCount = 0;
      _initNewCycle();
    }

    return next;
  }

  @override
  List<TetrominoType> preview(int count) {
    final result = <TetrominoType>[];
    int tempCount = _currentCount;
    int tempRarePos = _rarePositionInCycle;

    // 模擬預覽
    for (int i = 0; i < count; i++) {
      if (tempCount == tempRarePos) {
        result.add(rareType);
        tempCount++;
        if (tempCount >= cycleLength) {
          tempCount = 0;
          tempRarePos = _random.nextInt(cycleLength);
        }
      } else {
        // 這裡簡化處理，直接從基礎提供器預覽
        // 實際可能需要更複雜的邏輯來確保預覽準確
        final basePreview = baseProvider.preview(1);
        if (basePreview.isNotEmpty) {
          result.add(basePreview[0]);
        }
        tempCount++;
        if (tempCount >= cycleLength) {
          tempCount = 0;
          tempRarePos = _random.nextInt(cycleLength);
        }
      }
    }

    return result;
  }

  @override
  bool get isExhausted => false; // 永不耗盡

  @override
  int get priority => 50; // 中等優先級

  @override
  String get description =>
      'RareBlockInterceptor($rareType every $cycleLength blocks)';
}
