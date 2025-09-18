import 'dart:developer' as developer;
import 'package:flutter/material.dart';

/// 清行來源枚舉
enum LineClearSource {
  natural, // 自然清行（方塊放置後形成的完整行）
  spell, // 法術清行（符文効果造成的清行）
}

/// 清行結果
class LineClearResult {
  final List<int> clearedRows;
  final LineClearSource source;
  final int blocksRemoved;

  LineClearResult({
    required this.clearedRows,
    required this.source,
    required this.blocksRemoved,
  });

  bool get hasClears => clearedRows.isNotEmpty;
  int get lineCount => clearedRows.length;
}

/// 清行系統 - 統一處理自然和法術清行
class LineClearSystem {
  /// 檢查並清除完整行
  static LineClearResult clearCompletedLines(
    List<List<Color?>> board, {
    required LineClearSource source,
  }) {
    final completedRows = <int>[];
    int blocksRemoved = 0;

    // 檢查完整行（從下往上）
    for (int row = board.length - 1; row >= 0; row--) {
      bool isComplete = true;
      for (int col = 0; col < board[row].length; col++) {
        if (board[row][col] == null) {
          isComplete = false;
          break;
        }
      }

      if (isComplete) {
        completedRows.add(row);
        blocksRemoved += board[row].length;

        // 記錄清行日誌
        developer.log(
            '[LineClearSystem] Cleared row $row, source: $source, blocks: ${board[row].length}',
            name: 'line_clear');
      }
    }

    if (completedRows.isNotEmpty) {
      _performLineClear(board, completedRows);
    }

    return LineClearResult(
      clearedRows: completedRows,
      source: source,
      blocksRemoved: blocksRemoved,
    );
  }

  /// 執行實際的清行操作
  static void _performLineClear(
      List<List<Color?>> board, List<int> rowsToRemove) {
    // 從上到下排序（確保正確的清行順序）
    final sortedRows = List<int>.from(rowsToRemove)..sort();

    // 從下往上移除行
    for (int i = sortedRows.length - 1; i >= 0; i--) {
      final rowIndex = sortedRows[i] - i; // 調整索引（考慮已移除的行）

      // 移除完整行
      board.removeAt(rowIndex);

      // 在頂部添加空行
      board.insert(0, List.generate(board.first.length, (_) => null));
    }
  }

  /// 計算指定行中的方塊數量
  static int countBlocksInRow(List<List<Color?>> board, int row) {
    if (row < 0 || row >= board.length) return 0;

    int count = 0;
    for (int col = 0; col < board[row].length; col++) {
      if (board[row][col] != null) count++;
    }
    return count;
  }
}
