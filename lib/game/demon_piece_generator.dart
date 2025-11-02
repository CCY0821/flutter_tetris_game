import 'dart:math';
import 'package:flutter/foundation.dart';

/// 惡魔方塊生成器
/// 使用洪水填充（Flood Fill）演算法生成 10 格隨機連續方塊
/// 限制在 5×5 範圍內，確保方塊寬度不超過棋盤寬度（10格）
class DemonPieceGenerator {
  static const int defaultMaxWidth = 5;
  static const int defaultMaxHeight = 5;
  static const int defaultTargetCells = 10;
  static const int defaultMaxRetries = 10;
  static const int boardWidth = 10;

  /// 使用洪水填充生成 10 格隨機方塊
  ///
  /// 參數:
  /// - [maxWidth]: 最大寬度限制（預設 5）
  /// - [maxHeight]: 最大高度限制（預設 5）
  /// - [targetCells]: 目標格子數量（預設 10）
  /// - [maxRetries]: 最大重試次數（預設 10）
  ///
  /// 返回: 5×5 布林矩陣，true 表示有方塊，false 表示空格
  static List<List<bool>> generateShape({
    int maxWidth = defaultMaxWidth,
    int maxHeight = defaultMaxHeight,
    int targetCells = defaultTargetCells,
    int maxRetries = defaultMaxRetries,
  }) {
    for (int retry = 0; retry < maxRetries; retry++) {
      final shape = _floodFillGenerate(maxWidth, maxHeight, targetCells);

      // 驗證生成的方塊
      if (_isConnected(shape) && _canBePlacedOnEmptyBoard(shape)) {
        debugPrint(
            '[DemonPieceGenerator] Generated valid shape (attempt ${retry + 1})');
        return shape;
      }

      debugPrint(
          '[DemonPieceGenerator] Invalid shape (attempt ${retry + 1}), retrying...');
    }

    // 所有重試都失敗，返回降級方案
    debugPrint(
        '[DemonPieceGenerator] All retries failed, using fallback shape (2×5 rectangle)');
    return _generateFallbackShape();
  }

  /// 洪水填充核心演算法
  /// 從中心點 (2, 2) 開始，隨機向四周擴展
  static List<List<bool>> _floodFillGenerate(
    int maxWidth,
    int maxHeight,
    int targetCells,
  ) {
    final Random random = Random();

    // 初始化空白網格
    final grid = List.generate(
      maxHeight,
      (_) => List.generate(maxWidth, (_) => false),
    );

    // 設置起點 (2, 2) 為第一格
    grid[2][2] = true;
    final existingCells = [(2, 2)];

    // 生成剩餘 9 格（共 10 格）
    for (int i = 1; i < targetCells; i++) {
      final neighbors = _getAvailableNeighbors(grid, existingCells);

      if (neighbors.isEmpty) {
        // 無法繼續擴展，返回當前形狀（會在外層驗證失敗）
        debugPrint('[DemonPieceGenerator] Cannot expand further at cell $i');
        break;
      }

      // 隨機選擇一個可用的相鄰格子
      final newCell = neighbors[random.nextInt(neighbors.length)];
      grid[newCell.$1][newCell.$2] = true;
      existingCells.add(newCell);
    }

    return grid;
  }

  /// 獲取所有可用的相鄰格子（上下左右）
  /// 確保不超出邊界且尚未被佔用
  static List<(int, int)> _getAvailableNeighbors(
    List<List<bool>> grid,
    List<(int, int)> existingCells,
  ) {
    final neighbors = <(int, int)>[];
    final maxHeight = grid.length;
    final maxWidth = grid[0].length;

    // 四個方向：上、下、左、右
    const directions = [
      (-1, 0), // 上
      (1, 0), // 下
      (0, -1), // 左
      (0, 1), // 右
    ];

    // 遍歷現有格子，找出所有可用的相鄰格子
    for (final cell in existingCells) {
      final (y, x) = cell;

      for (final direction in directions) {
        final newY = y + direction.$1;
        final newX = x + direction.$2;

        // 檢查邊界
        if (newY < 0 || newY >= maxHeight || newX < 0 || newX >= maxWidth) {
          continue;
        }

        // 檢查是否已被佔用
        if (grid[newY][newX]) {
          continue;
        }

        // 避免重複添加
        if (!neighbors.contains((newY, newX))) {
          neighbors.add((newY, newX));
        }
      }
    }

    return neighbors;
  }

  /// 驗證方塊連通性（所有格子必須互相連接）
  /// 使用深度優先搜索（DFS）檢查連通性
  static bool _isConnected(List<List<bool>> grid) {
    final maxHeight = grid.length;
    final maxWidth = grid[0].length;

    // 找到第一個填充的格子作為起點
    int? startY;
    int? startX;
    int totalCells = 0;

    for (int y = 0; y < maxHeight; y++) {
      for (int x = 0; x < maxWidth; x++) {
        if (grid[y][x]) {
          totalCells++;
          if (startY == null) {
            startY = y;
            startX = x;
          }
        }
      }
    }

    // 沒有填充格子，返回 false
    if (startY == null || totalCells == 0) {
      return false;
    }

    // 使用 DFS 檢查連通性
    final visited = List.generate(
      maxHeight,
      (_) => List.generate(maxWidth, (_) => false),
    );

    int connectedCount = 0;

    void dfs(int y, int x) {
      if (y < 0 || y >= maxHeight || x < 0 || x >= maxWidth) return;
      if (visited[y][x] || !grid[y][x]) return;

      visited[y][x] = true;
      connectedCount++;

      // 遞迴檢查四個方向
      dfs(y - 1, x); // 上
      dfs(y + 1, x); // 下
      dfs(y, x - 1); // 左
      dfs(y, x + 1); // 右
    }

    dfs(startY, startX!);

    // 檢查所有填充格子都被訪問到
    return connectedCount == totalCells;
  }

  /// 驗證方塊可在空棋盤上放置
  /// 檢查方塊寬度是否超過棋盤寬度（10格）
  static bool _canBePlacedOnEmptyBoard(List<List<bool>> grid) {
    final maxWidth = grid[0].length;

    // 計算實際寬度（有填充格子的列數）
    int minX = maxWidth;
    int maxX = 0;

    for (int y = 0; y < grid.length; y++) {
      for (int x = 0; x < maxWidth; x++) {
        if (grid[y][x]) {
          minX = min(minX, x);
          maxX = max(maxX, x);
        }
      }
    }

    final actualWidth = maxX - minX + 1;

    // 檢查寬度是否超過棋盤寬度
    if (actualWidth > boardWidth) {
      debugPrint(
          '[DemonPieceGenerator] Shape width ($actualWidth) exceeds board width ($boardWidth)');
      return false;
    }

    return true;
  }

  /// 降級方案：返回固定的 2×5 矩形方塊
  /// 確保遊戲不會因生成失敗而卡住
  static List<List<bool>> _generateFallbackShape() {
    return [
      [true, true, true, true, true],
      [true, true, true, true, true],
      [false, false, false, false, false],
      [false, false, false, false, false],
      [false, false, false, false, false],
    ];
  }

  /// 獲取方塊的邊界框（用於調試和優化）
  /// 返回 (minX, minY, maxX, maxY)
  static (int, int, int, int) getBoundingBox(List<List<bool>> grid) {
    final maxHeight = grid.length;
    final maxWidth = grid[0].length;

    int minX = maxWidth;
    int minY = maxHeight;
    int maxX = 0;
    int maxY = 0;

    for (int y = 0; y < maxHeight; y++) {
      for (int x = 0; x < maxWidth; x++) {
        if (grid[y][x]) {
          minX = min(minX, x);
          minY = min(minY, y);
          maxX = max(maxX, x);
          maxY = max(maxY, y);
        }
      }
    }

    return (minX, minY, maxX, maxY);
  }

  /// 計算方塊中填充格子的數量
  static int countCells(List<List<bool>> grid) {
    int count = 0;
    for (final row in grid) {
      for (final cell in row) {
        if (cell) count++;
      }
    }
    return count;
  }
}
