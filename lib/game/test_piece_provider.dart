import 'dart:math';
import '../models/tetromino.dart';
import 'piece_provider.dart';

/// 測試 PieceProvider 系統
/// 這是一個臨時測試文件，確保系統運作正常
void testPieceProviderSystem() {
  print('=== Testing PieceProvider System ===');
  
  // 測試 1: 基礎 BagProvider
  print('\n1. Testing BagProvider:');
  final bagProvider = BagProvider(random: Random(42)); // 固定種子用於可重現測試
  
  // 生成14個方塊（兩個完整的bag）
  final pieces = <TetrominoType>[];
  for (int i = 0; i < 14; i++) {
    pieces.add(bagProvider.getNext());
  }
  print('Generated pieces: ${pieces.map((p) => p.name).join(', ')}');
  
  // 測試預覽功能
  final preview = bagProvider.preview(5);
  print('Preview next 5: ${preview.map((p) => p.name).join(', ')}');
  
  // 測試 2: ForcedSequenceProvider
  print('\n2. Testing ForcedSequenceProvider:');
  final baseBag = BagProvider(random: Random(42));
  final forcedProvider = ForcedSequenceProvider(
    forcedType: TetrominoType.I,
    remaining: 3,
    baseProvider: baseBag,
  );
  
  print('Forced provider description: ${forcedProvider.description}');
  
  // 應該產生 3 個 I，然後回到正常
  final forcedPieces = <TetrominoType>[];
  for (int i = 0; i < 8; i++) {
    forcedPieces.add(forcedProvider.getNext());
    print('Piece ${i + 1}: ${forcedPieces.last.name} (remaining: ${forcedProvider.remaining})');
  }
  
  // 測試預覽
  final forcedPreview = ForcedSequenceProvider(
    forcedType: TetrominoType.I,
    remaining: 2,
    baseProvider: BagProvider(random: Random(42)),
  ).preview(8);
  print('Forced preview: ${forcedPreview.map((p) => p.name).join(', ')}');
  
  // 測試 3: PieceProviderStack
  print('\n3. Testing PieceProviderStack:');
  final stack = PieceProviderStack(baseProvider: BagProvider(random: Random(42)));
  
  print('Initial stack: ${stack.stackDescription}');
  
  // 添加第一個攔截器：3個I
  final baseBagForStack = BagProvider(random: Random(42));
  stack.push(ForcedSequenceProvider(
    forcedType: TetrominoType.I,
    remaining: 3,
    baseProvider: baseBagForStack,
  ));
  print('After adding I×3: ${stack.stackDescription}');
  
  // 添加第二個攔截器：2個O（應該優先執行）
  stack.push(ForcedSequenceProvider(
    forcedType: TetrominoType.O,
    remaining: 2,
    baseProvider: baseBagForStack,
  ));
  print('After adding O×2: ${stack.stackDescription}');
  
  // 測試LIFO行為：應該先出2個O，然後3個I，然後正常
  print('\nTesting LIFO behavior:');
  final stackPieces = <TetrominoType>[];
  for (int i = 0; i < 10; i++) {
    stackPieces.add(stack.getNext());
    print('Stack piece ${i + 1}: ${stackPieces.last.name} (depth: ${stack.stackDepth})');
    print('  Current stack: ${stack.stackDescription}');
  }
  
  // 測試預覽
  final stackPreview = stack.preview(8);
  print('Stack preview: ${stackPreview.map((p) => p.name).join(', ')}');
  
  // 測試 4: 持久化
  print('\n4. Testing Persistence:');
  final baseBagForPersist = BagProvider(random: Random(42));
  final persistStack = PieceProviderStack(baseProvider: baseBagForPersist);
  persistStack.push(ForcedSequenceProvider(
    forcedType: TetrominoType.I,
    remaining: 5,
    baseProvider: baseBagForPersist,
  ));
  
  // 使用一些方塊
  persistStack.getNext(); // 用掉一個I
  persistStack.getNext(); // 用掉第二個I
  
  // 保存狀態
  final state = persistStack.getState();
  print('Saved state: $state');
  
  // 創建新的stack並恢復狀態
  final restoredStack = PieceProviderStack(baseProvider: BagProvider(random: Random(42)));
  restoredStack.restoreState(state);
  
  print('Restored stack: ${restoredStack.stackDescription}');
  
  // 應該還有3個I
  final restoredPieces = <TetrominoType>[];
  for (int i = 0; i < 5; i++) {
    restoredPieces.add(restoredStack.getNext());
  }
  print('Restored pieces: ${restoredPieces.map((p) => p.name).join(', ')}');
  
  print('\n=== All tests completed ===');
}

