class GameConfig {
  final int cols;
  final int rows;

  const GameConfig({
    required this.cols,
    required this.rows,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GameConfig && other.cols == cols && other.rows == rows;
  }

  @override
  int get hashCode => Object.hash(cols, rows);

  @override
  String toString() => 'GameConfig(cols: $cols, rows: $rows)';
}

const GameConfig defaultConfig = GameConfig(cols: 14, rows: 20);
