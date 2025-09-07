import 'package:flutter/material.dart';

/// 棋盤操作抽象類
/// 所有對棋盤的修改都通過此類進行批處理
abstract class BoardOperation {
  /// 是否為法術移除（不計分、不產生能量）
  bool get isSpellRemoval;

  /// 操作描述（用於調試）
  String get description;

  /// 執行操作
  void execute(List<List<Color?>> board);

  /// 檢查操作是否有效
  bool isValid(List<List<Color?>> board);
}

/// 清除單個格子操作
class ClearCellOperation extends BoardOperation {
  final int row;
  final int col;
  final bool isSpellRemoval;

  ClearCellOperation(this.row, this.col, {this.isSpellRemoval = false});

  @override
  String get description =>
      'Clear cell ($row, $col)${isSpellRemoval ? " [SPELL]" : ""}';

  @override
  bool isValid(List<List<Color?>> board) {
    return row >= 0 &&
        row < board.length &&
        col >= 0 &&
        col < board[row].length;
  }

  @override
  void execute(List<List<Color?>> board) {
    if (isValid(board)) {
      board[row][col] = null;
    }
  }
}

/// 清除整行操作
class ClearRowOperation extends BoardOperation {
  final int row;
  final bool isSpellRemoval;

  ClearRowOperation(this.row, {this.isSpellRemoval = false});

  @override
  String get description => 'Clear row $row${isSpellRemoval ? " [SPELL]" : ""}';

  @override
  bool isValid(List<List<Color?>> board) {
    return row >= 0 && row < board.length;
  }

  @override
  void execute(List<List<Color?>> board) {
    if (isValid(board)) {
      debugPrint('BatchProcessor: Executing ClearRowOperation for row $row');
      for (int col = 0; col < board[row].length; col++) {
        board[row][col] = null;
      }
      debugPrint('BatchProcessor: Row $row cleared successfully');
    } else {
      debugPrint('BatchProcessor: ClearRowOperation invalid for row $row');
    }
  }
}

/// 清除整列操作
class ClearColumnOperation extends BoardOperation {
  final int col;
  final bool isSpellRemoval;

  ClearColumnOperation(this.col, {this.isSpellRemoval = false});

  @override
  String get description =>
      'Clear column $col${isSpellRemoval ? " [SPELL]" : ""}';

  @override
  bool isValid(List<List<Color?>> board) {
    return board.isNotEmpty && col >= 0 && col < board[0].length;
  }

  @override
  void execute(List<List<Color?>> board) {
    if (isValid(board)) {
      for (int row = 0; row < board.length; row++) {
        if (col < board[row].length) {
          board[row][col] = null;
        }
      }
    }
  }
}

/// 下移盤面操作（Earthquake 用）
class ShiftBoardDownOperation extends BoardOperation {
  final bool isSpellRemoval;
  final int shiftRows;

  ShiftBoardDownOperation({this.isSpellRemoval = true, this.shiftRows = 1});

  @override
  String get description =>
      'Shift board down $shiftRows rows${isSpellRemoval ? " [SPELL]" : ""}';

  @override
  bool isValid(List<List<Color?>> board) {
    return board.isNotEmpty && shiftRows > 0 && shiftRows < board.length;
  }

  @override
  void execute(List<List<Color?>> board) {
    if (!isValid(board)) return;

    final rowCount = board.length;
    final colCount = board[0].length;

    // 從底部開始，將每行向下移動
    for (int row = rowCount - 1; row >= shiftRows; row--) {
      for (int col = 0; col < colCount; col++) {
        board[row][col] = board[row - shiftRows][col];
      }
    }

    // 清空頂部的行
    for (int row = 0; row < shiftRows; row++) {
      for (int col = 0; col < colCount; col++) {
        board[row][col] = null;
      }
    }
  }
}

/// 壓縮盤面操作（Gravity Reset 用）
class CompressBoardOperation extends BoardOperation {
  final bool isSpellRemoval;

  CompressBoardOperation({this.isSpellRemoval = true});

  @override
  String get description => 'Compress board${isSpellRemoval ? " [SPELL]" : ""}';

  @override
  bool isValid(List<List<Color?>> board) {
    return board.isNotEmpty;
  }

  @override
  void execute(List<List<Color?>> board) {
    if (!isValid(board)) return;

    final rowCount = board.length;
    final colCount = board[0].length;

    // 對每一列進行壓縮
    for (int col = 0; col < colCount; col++) {
      final columnBlocks = <Color?>[];

      // 收集該列中所有非空的方塊
      for (int row = rowCount - 1; row >= 0; row--) {
        if (board[row][col] != null) {
          columnBlocks.add(board[row][col]);
        }
      }

      // 清空該列
      for (int row = 0; row < rowCount; row++) {
        board[row][col] = null;
      }

      // 將方塊從底部開始填回
      for (int i = 0; i < columnBlocks.length; i++) {
        board[rowCount - 1 - i][col] = columnBlocks[i];
      }
    }
  }
}

/// 移除頂部行操作（Angel's Grace 用）
class RemoveTopRowsOperation extends BoardOperation {
  final int rowsToRemove;
  final bool isSpellRemoval;

  RemoveTopRowsOperation(this.rowsToRemove, {this.isSpellRemoval = true});

  @override
  String get description =>
      'Remove top $rowsToRemove rows${isSpellRemoval ? " [SPELL]" : ""}';

  @override
  bool isValid(List<List<Color?>> board) {
    return board.isNotEmpty && rowsToRemove > 0 && rowsToRemove <= board.length;
  }

  @override
  void execute(List<List<Color?>> board) {
    if (!isValid(board)) return;

    final rowCount = board.length;
    final colCount = board[0].length;

    // 向上移動剩餘的行
    for (int row = 0; row < rowCount - rowsToRemove; row++) {
      for (int col = 0; col < colCount; col++) {
        board[row][col] = board[row + rowsToRemove][col];
      }
    }

    // 清空頂部新增的空行
    for (int row = rowCount - rowsToRemove; row < rowCount; row++) {
      for (int col = 0; col < colCount; col++) {
        board[row][col] = null;
      }
    }
  }
}

/// 符文批處理系統
/// 核心職責：將同幀的多個棋盤操作合併，確保法術清行與自然清行分流
class RuneBatchProcessor {
  final List<BoardOperation> _operations = [];
  bool _isProcessing = false;
  VoidCallback? _onBoardChanged;

  /// 設置棋盤變化回調
  void setOnBoardChanged(VoidCallback callback) {
    _onBoardChanged = callback;
  }

  /// 手動觸發棋盤變化通知
  void notifyBoardChanged() {
    _onBoardChanged?.call();
    debugPrint('RuneBatchProcessor: Manual board change notification sent');
  }

  /// 添加操作到批處理隊列
  void addOperation(BoardOperation operation) {
    if (_isProcessing) {
      debugPrint(
          'RuneBatchProcessor: Warning - Cannot add operation during processing');
      return;
    }

    _operations.add(operation);
    debugPrint(
        'RuneBatchProcessor: Added operation - ${operation.description}');
  }

  /// 執行所有批處理操作
  /// 重要：確保法術清行與自然清行分流
  void execute(List<List<Color?>> board) {
    if (_operations.isEmpty || _isProcessing) {
      return;
    }

    _isProcessing = true;

    try {
      // 分離法術操作和自然操作
      final spellOperations =
          _operations.where((op) => op.isSpellRemoval).toList();
      final naturalOperations =
          _operations.where((op) => !op.isSpellRemoval).toList();

      debugPrint(
          'RuneBatchProcessor: Executing ${spellOperations.length} spell operations, '
          '${naturalOperations.length} natural operations');

      // 先執行法術操作（不計分不產能）
      for (final operation in spellOperations) {
        if (operation.isValid(board)) {
          operation.execute(board);
          debugPrint(
              'RuneBatchProcessor: Executed spell operation - ${operation.description}');
        } else {
          debugPrint(
              'RuneBatchProcessor: Skipped invalid spell operation - ${operation.description}');
        }
      }

      // 再執行自然操作（計分產能）
      for (final operation in naturalOperations) {
        if (operation.isValid(board)) {
          operation.execute(board);
          debugPrint(
              'RuneBatchProcessor: Executed natural operation - ${operation.description}');
        } else {
          debugPrint(
              'RuneBatchProcessor: Skipped invalid natural operation - ${operation.description}');
        }
      }

      // 單次重繪通知
      if (_operations.isNotEmpty) {
        _onBoardChanged?.call();
        debugPrint('RuneBatchProcessor: Board changed notification sent');
      }
    } catch (e) {
      debugPrint('RuneBatchProcessor: Error during execution - $e');
    } finally {
      // 清理操作隊列
      _operations.clear();
      _isProcessing = false;
    }
  }

  /// 檢查是否有待處理的操作
  bool get hasPendingOperations => _operations.isNotEmpty;

  /// 獲取待處理操作數量
  int get pendingOperationCount => _operations.length;

  /// 獲取待處理的法術操作數量
  int get pendingSpellOperationCount =>
      _operations.where((op) => op.isSpellRemoval).length;

  /// 獲取待處理的自然操作數量
  int get pendingNaturalOperationCount =>
      _operations.where((op) => !op.isSpellRemoval).length;

  /// 清空所有待處理操作（緊急情況用）
  void clear() {
    if (_isProcessing) {
      debugPrint(
          'RuneBatchProcessor: Warning - Cannot clear during processing');
      return;
    }

    final count = _operations.length;
    _operations.clear();
    debugPrint('RuneBatchProcessor: Cleared $count pending operations');
  }

  /// 檢查是否正在處理中
  bool get isProcessing => _isProcessing;

  @override
  String toString() {
    return 'RuneBatchProcessor(pending: ${_operations.length}, processing: $_isProcessing)';
  }
}
