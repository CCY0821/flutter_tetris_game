# 基础能量系统 v1 文档

## 概述

本文档介绍 Flutter Tetris 游戏中实现的基础符文能量系统，包括能量规则、HUD 位置集成、像素对齐原理和测试方法。

## 能量规则与API

### 基本规则

- **能量获取**: 自然消除 1 行 = +10 分，每 100 分 = 1 格能量
- **能量上限**: 最多 3 格能量
- **进度保留**: 可保留溢出进度（例：130 分 = 1 格 + 下一格 30%）
- **重要限制**: 法术造成的清除不可调用 `addScore` 方法

### 核心 API

#### RuneEnergyManager

```dart
final manager = RuneEnergyManager();

// 添加能量（仅限自然消除）
manager.addScore(linesCleared); // 每行+10分

// 查询状态
int bars = manager.currentBars;           // 当前完整格数 (0-3)
double ratio = manager.currentPartialRatio; // 下一格进度 (0.0-1.0)
bool isMax = manager.isMaxEnergy;         // 是否达到上限

// 消耗能量（供未来法术使用）
bool success = manager.consumeBars(2);    // 消耗2格能量

// 重置系统
manager.reset();

// 状态快照
RuneEnergyStatus status = manager.getStatus();
```

#### RuneEnergyStatus

```dart
class RuneEnergyStatus {
  final int currentBars;      // 当前格数
  final int maxBars;          // 最大格数 (3)
  final int currentScore;     // 当前总分数
  final double partialRatio;  // 部分格进度
  final bool isMaxEnergy;     // 是否满格
}
```

## HUD 擺位與整合

### 定位说明

能量 HUD 位于**右侧功能列的最下方**，且在**底部触控按钮区域上方**，两者间保留固定安全间距。

### 集成位置

**文件**: `lib/game/game_board.dart`

**具体位置**: 右侧 Column 中 `const Spacer()` 之前

```dart
Column(
  children: [
    // ... 现有内容 (NEXT面板、统计面板等)
    
    // 使用 Spacer 推到底部
    const Spacer(),
    
    // 符文能量 HUD (右侧栏最下方，触控区上方)
    RuneEnergyHUD(
      energyStatus: gameState.runeEnergyManager.getStatus(),
      gap: snap(4.0, MediaQuery.of(context).devicePixelRatio),
    ),
    
    // 保留与触控按钮区的安全间距
    SizedBox(
      height: snap(12.0, MediaQuery.of(context).devicePixelRatio),
    ),
  ]
)
```

### 布局参数

- **3格水平排列**: 格子间距 4px（经像素对齐）
- **单格尺寸**: 16×40（逻辑像素）
- **安全间距**: 与触控区间隔 12px

## 像素对齐原理

### snap/snapRect 函数

为确保在非整数 DPR（如 2.625）下的像素完美渲染：

```dart
// lib/core/pixel_snap.dart

/// 将逻辑像素对齐到物理像素边界
double snap(double logical, double dpr) => (logical * dpr).round() / dpr;

/// 将矩形所有边界对齐到物理像素
Rect snapRect(Rect r, double dpr) => Rect.fromLTRB(
  snap(r.left, dpr), snap(r.top, dpr), 
  snap(r.right, dpr), snap(r.bottom, dpr),
);
```

### 关键实现点

1. **边框处理**: 使用 `inside stroke` 避免踩外缘
2. **Canvas 绘制**: 所有坐标在 `canvas.draw*` 前先 `snap`
3. **Layout 备援**: 使用 `BorderSide.strokeAlignInside`
4. **禁止 Transform.scale**: 动画使用高度/数值补间

## 能量格子 UI 规格

### EnergyCell 单格规格

- **外框**: 16×40（逻辑 px）、外圆角 8
- **内容**: inset 上下左右 2、内容圆角 6
- **边框**: 1px inside（不踩外缘）
- **填充**: 自底向上依 ratio ∈ [0,1]
- **高光**: top=1px、height=2px、白 50%（在内容裁切内）

### 映射规则

- **已满格**: 显示 100%
- **下一格**: 显示 `currentPartialRatio`
- **其余格**: 显示 0%

### 实现方案

支持两种实现（可切换，默认 Canvas）:

```dart
enum EnergyCellImplementation { 
  canvas,  // CustomPaint 绘制（默认推荐）
  layout,  // 布局组件实现（备援）
}
```

## 测试方式

### 1. 逻辑测试

**文件**: `test/rune_energy_manager_test.dart`

测试覆盖：
- 单/多行消除
- 连续消行
- 3 格上限
- 溢出进度保留  
- `consumeBars` 成功/失败
- 重置功能
- 序列化/反序列化

### 2. Golden/UI 测试

**文件**: `test/rune_energy_hud_golden_test.dart`

**DPR 测试**: 1.0 / 2.0 / 2.625 / 3.0

**状态组合测试**:
- `bars=0, ratio=0.3` - 空格+30%进度
- `bars=1, ratio=0.0` - 1格满
- `bars=2, ratio=0.75` - 2格+75%进度  
- `bars=3, ratio=0.0` - 3格满

**验收要点**:
- 零像素溢出
- 边框锐利  
- 高光 top=1px & height=2px
- 填充贴齐 6px 内圆角

### 3. 父层缩放测试

```dart
Transform.scale(
  scale: 1.25, // 父层缩放
  child: RuneEnergyHUD(...),
)
```

验证：仍不外溢（靠裁切 + inside stroke + snap）

### 4. 测试运行

```bash
# 逻辑测试
flutter test test/rune_energy_manager_test.dart

# UI测试（生成Golden文件）
flutter test test/rune_energy_hud_golden_test.dart --update-goldens

# 全部能量相关测试
flutter test test/rune_energy*
```

## 常见坑位与注意事项

### 1. 像素溢出问题

❌ **错误做法**:
```dart
Container(
  width: 16.0,  // 未对齐
  border: Border.all(width: 1.0), // 踩外缘
)
```

✅ **正确做法**:
```dart
Container(
  width: snap(16.0, dpr),  // 像素对齐
  decoration: BoxDecoration(
    border: Border.all(
      width: snap(1.0, dpr),
      strokeAlign: BorderSide.strokeAlignInside, // inside stroke
    ),
  ),
)
```

### 2. 动画实现

❌ **禁止**:
```dart
Transform.scale(scale: animationValue) // 会改变外框几何
```

✅ **推荐**:
```dart
TweenAnimationBuilder<double>(
  tween: Tween(begin: oldRatio, end: newRatio),
  curve: Curves.easeOutCubic,
  duration: Duration(milliseconds: 220),
  builder: (context, ratio, child) => EnergyCell(ratio: ratio),
)
```

### 3. HUD 与触控区重叠

确保在 `Spacer()` 后、触控区前插入 HUD，并保留安全间距:

```dart
const Spacer(),           // 推到底部
RuneEnergyHUD(...),       // 能量HUD
SizedBox(height: 12),     // 安全间距
// 触控区在主Column外，不会重叠
```

### 4. 法术清除限制

⚠️ **重要**: 法术造成的清除不可调用 `addScore`
```dart
// ❌ 错误 - 法术清除调用
manager.addScore(magicClearedLines);

// ✅ 正确 - 仅自然消除调用  
if (isNaturalClear && !isMagicClear) {
  manager.addScore(clearedLines);
}
```

## 性能优化

### 1. 重绘隔离
每个 EnergyCell 用 `RepaintBoundary` 包装，避免不必要的重绘。

### 2. shouldRepaint 优化
```dart
@override
bool shouldRepaint(oldDelegate) {
  return ratio != oldDelegate.ratio ||
         borderColor != oldDelegate.borderColor ||
         // ... 仅在实际需要时重绘
}
```

### 3. 常量化
所有可能的值使用 `const` 或 `final` 声明。

## 文件结构

```
lib/
├── core/
│   └── pixel_snap.dart           # 像素对齐工具
├── game/
│   ├── rune_energy_manager.dart  # 能量管理器
│   ├── game_state.dart           # 游戏状态（已集成能量系统）
│   └── game_board.dart           # 游戏板（已集成HUD）
└── widgets/
    └── rune_energy_hud.dart      # 能量HUD组件

test/
├── rune_energy_manager_test.dart    # 逻辑测试
└── rune_energy_hud_golden_test.dart # UI/Golden测试
```

## 后续扩展

当前版本为基础能量系统，未来可扩展:

1. **法术系统**: 使用 `consumeBars()` 实现各种符文法术
2. **特效增强**: 满格发光、能量获取动画
3. **音效集成**: 能量获得、消耗音效
4. **视觉自定义**: 不同主题的能量条样式

---

*本文档对应基础能量系统 v1，确保零像素溢出、支持多DPR、位置准确集成的完整实现。*