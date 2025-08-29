import 'dart:ui';

/// 像素对齐工具 - 确保非整数DPR下的像素完美渲染
/// 支持 DPR: 1.0, 2.0, 2.625, 3.0 等

/// 将逻辑像素坐标对齐到物理像素边界
/// 算法: (logical * dpr).round() / dpr
double snap(double logical, double dpr) => (logical * dpr).round() / dpr;

/// 将矩形的所有边界对齐到物理像素
Rect snapRect(Rect r, double dpr) => Rect.fromLTRB(
      snap(r.left, dpr),
      snap(r.top, dpr),
      snap(r.right, dpr),
      snap(r.bottom, dpr),
    );

/// 将尺寸对齐到物理像素
Size snapSize(Size size, double dpr) => Size(
      snap(size.width, dpr),
      snap(size.height, dpr),
    );

/// 将偏移对齐到物理像素
Offset snapOffset(Offset offset, double dpr) => Offset(
      snap(offset.dx, dpr),
      snap(offset.dy, dpr),
    );
