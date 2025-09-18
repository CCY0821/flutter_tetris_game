import 'dart:math' as math;
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import '../core/game_config.dart';

/// 符文目標選取系統 - 比例化和統計化
class RuneTargeting {
  /// 基於比例選取列數（用於 Thunder Strike 等）
  static List<int> selectColumnsByRatio(GameConfig config, double ratio) {
    final targetCount = (config.cols * ratio).ceil().clamp(1, config.cols);
    final startCol = config.cols - targetCount; // 從右側開始

    final columns = <int>[];
    for (int i = startCol; i < config.cols; i++) {
      columns.add(i);
    }

    developer.log(
        '[RuneTargeting] Selected $targetCount columns (ratio: $ratio): ${columns.join(",")}',
        name: 'rune_targeting');

    return columns;
  }

  /// 基於比例選取行數（用於 Dragon Roar 等）
  static List<int> selectRowsByRatio(
    List<List<Color?>> board,
    double ratio, {
    bool preferHighDensity = true,
  }) {
    final visibleStartRow = math.max(0, board.length - 20);
    final visibleRows = <int>[];

    // 收集可見區域的行
    for (int row = visibleStartRow; row < board.length; row++) {
      visibleRows.add(row);
    }

    final targetCount =
        (visibleRows.length * ratio).ceil().clamp(1, visibleRows.length);

    if (preferHighDensity) {
      // 按密度排序，選取密度最高的行
      visibleRows.sort((a, b) {
        final densityA = _calculateRowDensity(board, a);
        final densityB = _calculateRowDensity(board, b);
        return densityB.compareTo(densityA); // 降序
      });
    }

    final selectedRows = visibleRows.take(targetCount).toList();

    developer.log(
        '[RuneTargeting] Selected $targetCount rows (ratio: $ratio, preferHighDensity: $preferHighDensity): ${selectedRows.join(",")}',
        name: 'rune_targeting');

    return selectedRows;
  }

  /// 智能選取目標區域（用於複合法術）
  static Map<String, List<int>> selectSmartTargets(
    List<List<Color?>> board,
    GameConfig config, {
    double columnRatio = 0.15,
    double rowRatio = 0.15,
    bool preferHighDensity = true,
  }) {
    return {
      'columns': selectColumnsByRatio(config, columnRatio),
      'rows': selectRowsByRatio(board, rowRatio,
          preferHighDensity: preferHighDensity),
    };
  }

  /// 計算行密度（方塊數量 / 總格數）
  static double _calculateRowDensity(List<List<Color?>> board, int row) {
    if (row < 0 || row >= board.length) return 0.0;

    int blockCount = 0;
    for (int col = 0; col < board[row].length; col++) {
      if (board[row][col] != null) blockCount++;
    }

    return blockCount / board[row].length;
  }

  /// 計算列密度（方塊數量 / 可見行數）
  static double _calculateColumnDensity(List<List<Color?>> board, int col) {
    if (board.isEmpty || col < 0 || col >= board[0].length) return 0.0;

    final visibleStartRow = math.max(0, board.length - 20);
    int blockCount = 0;
    int totalRows = board.length - visibleStartRow;

    for (int row = visibleStartRow; row < board.length; row++) {
      if (board[row][col] != null) blockCount++;
    }

    return blockCount / totalRows;
  }

  /// 獲取高密度行（用於智能目標選取）
  static List<int> getHighDensityRows(List<List<Color?>> board, int count) {
    final visibleStartRow = math.max(0, board.length - 20);
    final rows = <int>[];

    for (int row = visibleStartRow; row < board.length; row++) {
      rows.add(row);
    }

    // 按密度排序
    rows.sort((a, b) {
      final densityA = _calculateRowDensity(board, a);
      final densityB = _calculateRowDensity(board, b);
      return densityB.compareTo(densityA);
    });

    return rows.take(count).toList();
  }
}
