/// 棋盤相關常數和工具方法
///
/// 此檔案包含 Tetris 棋盤的標準尺寸常數和座標計算方法
/// 用於避免循環依賴問題，讓所有需要棋盤常數的模組都能安全引用
class BoardConstants {
  /// Tetris 標準可視區域高度（GUIDELINE 規範）
  /// 玩家可見的遊戲區域為 20 行
  static const int visibleRowCount = 20;

  /// Tetris 標準寬度（GUIDELINE 規範）
  /// 遊戲區域寬度固定為 10 列
  static const int colCount = 10;

  /// SRS 系統所需的緩衝區高度
  /// 用於方塊生成、旋轉檢測和 T-Spin 判定
  /// 緩衝區位於可視區域上方，不顯示給玩家
  static const int bufferRowCount = 20;

  /// 總矩陣大小（包含緩衝區和可視區域）
  /// 40 行 = 20 行緩衝區 + 20 行可視區域
  /// 10 列（無水平緩衝區）
  static const int totalRowCount = bufferRowCount + visibleRowCount;

  /// 計算可視區域的起始行索引
  /// 用於符文系統等需要操作可視區域的場景
  /// [boardHeight] 棋盤的總高度（通常為 40）
  /// 返回值：可視區域起始行（從緩衝區底部開始，通常為 20）
  static int getVisibleAreaStartRow(int boardHeight) {
    return boardHeight > visibleRowCount ? boardHeight - visibleRowCount : 0;
  }
}
