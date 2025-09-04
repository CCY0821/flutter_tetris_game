import 'package:flutter/material.dart';
import '../core/pixel_snap.dart';
import '../game/rune_energy_manager.dart';

/// 能量条实现方案
enum EnergyCellImplementation {
  /// Canvas 方案 - CustomPaint 绘制（默认推荐）
  canvas,

  /// Layout 方案 - 布局组件实现（备援）
  layout,
}

/// 符文能量HUD - 3格水平排列能量条
/// 定位: 右侧栏最下方，且在底部触控按钮区域上方
class RuneEnergyHUD extends StatelessWidget {
  final RuneEnergyStatus energyStatus;
  final double gap;
  final EnergyCellImplementation implementation;
  final bool debugOverlay;

  const RuneEnergyHUD({
    super.key,
    required this.energyStatus,
    this.gap = 4.0,
    this.implementation = EnergyCellImplementation.canvas,
    this.debugOverlay = false,
  });

  @override
  Widget build(BuildContext context) {
    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
    final snappedGap = snap(gap, devicePixelRatio);

    return RepaintBoundary(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (int i = 0; i < RuneEnergyManager.maxEnergy; i++) ...[
            EnergyCell(
              ratio: _getCellRatio(i),
              implementation: implementation,
              debugOverlay: debugOverlay,
            ),
            if (i < RuneEnergyManager.maxEnergy - 1)
              SizedBox(width: snappedGap),
          ],
        ],
      ),
    );
  }

  /// 获取指定索引格子的填充比例
  double _getCellRatio(int index) {
    if (index < energyStatus.currentBars) {
      return 1.0; // 已满格显示100%
    } else if (index == energyStatus.currentBars) {
      return energyStatus.partialRatio; // 下一格显示进度
    } else {
      return 0.0; // 其余为0%
    }
  }
}

/// 单个能量格子组件
class EnergyCell extends StatefulWidget {
  /// 填充比例 (0.0 ~ 1.0)
  final double ratio;

  /// 是否启用补间动画
  final bool animate;

  /// 动画持续时间
  final Duration duration;

  /// 动画曲线
  final Curve curve;

  /// 视觉尺寸 (逻辑像素)
  final Size size;

  /// 边框颜色
  final Color borderColor;

  /// 内容底色
  final Color fillBackground;

  /// 填充颜色
  final Color fillColor;

  /// 高光颜色
  final Color highlightColor;

  /// 实现方案
  final EnergyCellImplementation implementation;

  /// 调试覆盖层
  final bool debugOverlay;

  const EnergyCell({
    super.key,
    required this.ratio,
    this.animate = true,
    this.duration = const Duration(milliseconds: 220),
    this.curve = Curves.easeOutCubic,
    this.size = const Size(16, 40),
    this.borderColor = const Color(0xFFDBDBDB),
    this.fillBackground = const Color(0xFF101214),
    this.fillColor = const Color(0xFF44D17A),
    this.highlightColor = const Color(0x80FFFFFF), // 白色 50%
    this.implementation = EnergyCellImplementation.canvas,
    this.debugOverlay = false,
  }) : assert(
            ratio >= 0.0 && ratio <= 1.0, 'Ratio must be between 0.0 and 1.0');

  @override
  State<EnergyCell> createState() => _EnergyCellState();
}

class _EnergyCellState extends State<EnergyCell>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _currentRatio = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _updateAnimation();
    _currentRatio = widget.ratio.clamp(0.0, 1.0);

    if (widget.animate) {
      _controller.forward();
    }
  }

  void _updateAnimation() {
    _animation = Tween<double>(
      begin: _currentRatio.clamp(0.0, 1.0),
      end: widget.ratio.clamp(0.0, 1.0),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));
  }

  @override
  void didUpdateWidget(EnergyCell oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.ratio != widget.ratio) {
      if (widget.animate) {
        _updateAnimation();
        _controller.reset();
        _controller.forward();
      } else {
        _currentRatio = widget.ratio.clamp(0.0, 1.0);
      }
    }

    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;

    return RepaintBoundary(
      child: SizedBox(
        width: widget.size.width,
        height: widget.size.height,
        child: widget.animate
            ? AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  // 防止动画溢出：限制动画值在有效范围内
                  _currentRatio = _animation.value.clamp(0.0, 1.0);
                  return _buildImplementation(devicePixelRatio);
                },
              )
            : _buildImplementation(devicePixelRatio),
      ),
    );
  }

  Widget _buildImplementation(double devicePixelRatio) {
    switch (widget.implementation) {
      case EnergyCellImplementation.canvas:
        return _buildCanvasImplementation(devicePixelRatio);
      case EnergyCellImplementation.layout:
        return _buildLayoutImplementation(devicePixelRatio);
    }
  }

  /// Canvas 方案实现
  Widget _buildCanvasImplementation(double devicePixelRatio) {
    return CustomPaint(
      size: widget.size,
      painter: _EnergyCellCanvasPainter(
        ratio: _currentRatio,
        borderColor: widget.borderColor,
        fillBackground: widget.fillBackground,
        fillColor: widget.fillColor,
        highlightColor: widget.highlightColor,
        devicePixelRatio: devicePixelRatio,
        debugOverlay: widget.debugOverlay,
      ),
    );
  }

  /// Layout 方案实现 (备援)
  Widget _buildLayoutImplementation(double devicePixelRatio) {
    // 像素锁定：将尺寸对齐到实体像素
    final pixelAlignedWidth = snap(widget.size.width, devicePixelRatio);
    final pixelAlignedHeight = snap(widget.size.height, devicePixelRatio);

    return Container(
      width: pixelAlignedWidth,
      height: pixelAlignedHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: widget.borderColor,
          width: snap(1.0, devicePixelRatio),
          strokeAlign: BorderSide.strokeAlignInside,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(snap(2.0, devicePixelRatio)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(snap(6.0, devicePixelRatio)),
          clipBehavior: Clip.hardEdge,
          child: Stack(
            children: [
              // 背景
              Container(
                width: double.infinity,
                height: double.infinity,
                color: widget.fillBackground,
              ),

              // 填充
              if (_currentRatio > 0.0)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: FractionallySizedBox(
                    heightFactor: _currentRatio.clamp(0.0, 1.0),
                    widthFactor: 1.0,
                    child: Container(
                      color: widget.fillColor,
                    ),
                  ),
                ),

              // 高光（只在有填充时显示）
              if (_currentRatio > 0.0)
                Positioned(
                  top: snap(1.0, devicePixelRatio),
                  left: 0,
                  right: 0,
                  height: snap(2.0, devicePixelRatio),
                  child: Container(
                    color: widget.highlightColor,
                  ),
                ),

              // 调试覆盖层
              if (widget.debugOverlay)
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: Colors.red.withOpacity(0.5), width: 1),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Canvas 绘制器
class _EnergyCellCanvasPainter extends CustomPainter {
  final double ratio;
  final Color borderColor;
  final Color fillBackground;
  final Color fillColor;
  final Color highlightColor;
  final double devicePixelRatio;
  final bool debugOverlay;

  const _EnergyCellCanvasPainter({
    required this.ratio,
    required this.borderColor,
    required this.fillBackground,
    required this.fillColor,
    required this.highlightColor,
    required this.devicePixelRatio,
    required this.debugOverlay,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 防止溢出：确保比例值在有效范围内
    final clampedRatio = ratio.clamp(0.0, 1.0);
    
    // 1. 外框计算（像素对齐）
    final outerRect = snapRect(Offset.zero & size, devicePixelRatio);

    // 2. 边框处理（stroke inside 等效）
    final strokeWidth = snap(1.0, devicePixelRatio);
    final borderRect = snapRect(
      outerRect.deflate(strokeWidth * 0.5),
      devicePixelRatio,
    );
    final borderRadius = snap(8.0 - strokeWidth * 0.5, devicePixelRatio);

    // 3. 内容区域计算
    final contentInset = snap(2.0, devicePixelRatio) + strokeWidth * 0.5;
    final contentRect = snapRect(
      outerRect.deflate(contentInset),
      devicePixelRatio,
    );
    final contentRadius = snap(6.0, devicePixelRatio);

    // 4. 裁切路径
    final contentRRect = RRect.fromRectAndRadius(
      contentRect,
      Radius.circular(contentRadius),
    );

    // 5. 内容裁切
    canvas.save();
    canvas.clipRRect(contentRRect);

    // 6. 绘制背景
    final backgroundPaint = Paint()
      ..color = fillBackground
      ..isAntiAlias = true;
    canvas.drawRect(contentRect, backgroundPaint);

    // 7. 绘制填充
    if (clampedRatio > 0.0) {
      final fillHeight = snap(contentRect.height * clampedRatio, devicePixelRatio);
      // 额外边界检查：确保fillHeight不超过内容区域高度
      final safeFillHeight = fillHeight.clamp(0.0, contentRect.height);
      final fillRect = snapRect(
        Rect.fromLTWH(
          contentRect.left,
          contentRect.bottom - safeFillHeight,
          contentRect.width,
          safeFillHeight,
        ),
        devicePixelRatio,
      );

      final fillPaint = Paint()
        ..color = fillColor
        ..isAntiAlias = true;
      canvas.drawRect(fillRect, fillPaint);

      // 8. 绘制高光（距顶 1px，高 2px）
      final highlightTop = snap(contentRect.top + 1.0, devicePixelRatio);
      final highlightHeight = snap(2.0, devicePixelRatio);
      final highlightRect = snapRect(
        Rect.fromLTWH(
          contentRect.left,
          highlightTop,
          contentRect.width,
          highlightHeight,
        ),
        devicePixelRatio,
      );

      final highlightPaint = Paint()
        ..color = highlightColor
        ..isAntiAlias = true;
      canvas.drawRect(highlightRect, highlightPaint);
    }

    // 9. 恢复裁切
    canvas.restore();

    // 10. 绘制边框
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..isAntiAlias = true;

    final borderRRect = RRect.fromRectAndRadius(
      borderRect,
      Radius.circular(borderRadius),
    );
    canvas.drawRRect(borderRRect, borderPaint);

    // 11. 调试覆盖层
    if (debugOverlay) {
      final debugPaint = Paint()
        ..color = Colors.red.withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      canvas.drawRect(outerRect, debugPaint);
      canvas.drawRect(
          contentRect, debugPaint..color = Colors.green.withOpacity(0.5));
    }
  }

  @override
  bool shouldRepaint(_EnergyCellCanvasPainter oldDelegate) {
    return ratio != oldDelegate.ratio ||
        borderColor != oldDelegate.borderColor ||
        fillBackground != oldDelegate.fillBackground ||
        fillColor != oldDelegate.fillColor ||
        highlightColor != oldDelegate.highlightColor ||
        debugOverlay != oldDelegate.debugOverlay;
  }
}
