// lib/game/shaders/chroma_key.dart
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Chroma Key (綠幕去除) Shader 管理器
///
/// 單例模式，負責載入、快取與降級處理
class ChromaKey {
  ChromaKey._();
  static final ChromaKey I = ChromaKey._();

  ui.FragmentProgram? _prog;
  bool _initTried = false;
  bool get isReady => _prog != null;

  /// 確保 shader 已載入（只載入一次）
  Future<void> ensureLoaded() async {
    if (_initTried) return;
    _initTried = true;
    try {
      _prog =
          await ui.FragmentProgram.fromAsset('assets/shaders/chroma_key.frag');
      debugPrint('[ChromaKey] ✅ Shader loaded successfully');
    } catch (e) {
      debugPrint('[ChromaKey] ❌ Load failed, fallback to non-shader. $e');
      _prog = null; // 降級：之後直接走非 shader 路徑
    }
  }

  /// 建立 shader 實例並設定 uniforms
  ///
  /// 參數：
  /// - [image]: 來源圖片（sprite sheet）
  /// - [srcRect]: 來源矩形（sprite sheet 的裁切區域）
  /// - [dstRect]: 目標矩形（繪製在畫布上的區域）
  /// - [key]: 色鍵顏色（預設 #00FF00 綠幕）
  /// - [tolerance]: 色差容差（0.10-0.14，預設 0.12）
  /// - [softness]: 邊緣柔化範圍（0.05-0.10，預設 0.05）
  ui.FragmentShader? createShader({
    required ui.Image image,
    required Rect srcRect,
    required Rect dstRect,
    Color key = const Color(0xFF00FF00),
    double tolerance = 0.12,
    double softness = 0.05,
  }) {
    final prog = _prog;
    if (prog == null) return null;

    final shader = prog.fragmentShader();
    int i = 0;

    // 0) sampler2D uImage
    shader.setImageSampler(0, image);

    // 1) vec2 uImageSize
    shader.setFloat(i++, image.width.toDouble());
    shader.setFloat(i++, image.height.toDouble());

    // 2) vec2 uSrcLT (來源矩形左上角)
    shader.setFloat(i++, srcRect.left);
    shader.setFloat(i++, srcRect.top);

    // 3) vec2 uSrcSize (來源矩形尺寸)
    shader.setFloat(i++, srcRect.width);
    shader.setFloat(i++, srcRect.height);

    // 4) vec2 uDstLT (目標矩形左上角)
    shader.setFloat(i++, dstRect.left);
    shader.setFloat(i++, dstRect.top);

    // 5) vec2 uDstSize (目標矩形尺寸)
    shader.setFloat(i++, dstRect.width);
    shader.setFloat(i++, dstRect.height);

    // 6) vec3 uKey (色鍵顏色 0-1)
    shader.setFloat(i++, key.red / 255.0);
    shader.setFloat(i++, key.green / 255.0);
    shader.setFloat(i++, key.blue / 255.0);

    // 7) float uTolerance
    shader.setFloat(i++, tolerance);

    // 8) float uSoftness
    shader.setFloat(i++, softness);

    return shader;
  }
}
