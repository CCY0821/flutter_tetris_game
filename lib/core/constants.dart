import 'package:flutter/material.dart';

// 遊戲板基礎常數
const int boardWidth = 10;
const int boardHeight = 20;
const double blockSize = 20.0;

// =============================================================================
// 🌃 CYBERPUNK 2077 霓虹調色盤與強度常數 🌃
// =============================================================================
// 基於賽博龐克美學的霓虹色彩系統，專為未來感 Tetris 體驗設計

/// Cyberpunk 主色調 - 霓虹青色（科技感核心色）
/// 用途：主要 UI 元素、邊框、強調色
const Color cyberpunkPrimary = Color(0xFF00E5FF); // Neon Cyan

/// Cyberpunk 次色調 - 霓虹洋紅（能量脈衝色）
/// 用途：次要按鈕、特效、動態元素
const Color cyberpunkSecondary = Color(0xFFFF2ED1); // Neon Magenta

/// Cyberpunk 強調色 - 電光紫（神秘科技色）
/// 用途：特殊狀態、高級功能、重要提示
const Color cyberpunkAccent = Color(0xFF8A2BE2); // Electric Purple

/// Cyberpunk 警告色 - 賽博黃（危險警示色）
/// 用途：少量強調、警告狀態、關鍵資訊
const Color cyberpunkCaution = Color(0xFFFCEE09); // Cyberpunk Yellow

/// Cyberpunk 深層背景 - 深空藍（沉浸感基調）
/// 用途：主背景、深層容器
const Color cyberpunkBgDeep = Color(0xFF0A0F1E);

/// Cyberpunk 面板背景 - 暗夜藍（中層容器）
/// 用途：面板背景、卡片容器、功能區域
const Color cyberpunkPanel = Color(0xFF101826);

/// Cyberpunk 網格線 - 主色 60% 透明度
/// 用途：網格、分隔線、輔助線條
final Color cyberpunkGridLine = cyberpunkPrimary.withOpacity(0.6);

// =============================================================================
// 🌟 CYBERPUNK 光暈強度常數 🌟
// =============================================================================
// 三級光暈系統，用於 BoxShadow blurRadius 參數

/// 軟光暈 - 細膩環境光
/// 用途：按鈕默認狀態、文字陰影
const double cyberpunkGlowSoft = 4.0;

/// 中等光暈 - 標準霓虹效果
/// 用途：交互元素、重要面板
const double cyberpunkGlowMed = 8.0;

/// 強烈光暈 - 高能量特效
/// 用途：激活狀態、特殊效果、焦點元素
const double cyberpunkGlowStrong = 16.0;

// =============================================================================
// 🎨 CYBERPUNK 預設組合效果 🎨
// =============================================================================

/// Cyberpunk 主要按鈕光暈效果
List<BoxShadow> get cyberpunkPrimaryGlow => [
      BoxShadow(
        color: cyberpunkPrimary.withOpacity(0.3),
        blurRadius: cyberpunkGlowMed,
        spreadRadius: 1,
      ),
    ];

/// Cyberpunk 次要按鈕光暈效果
List<BoxShadow> get cyberpunkSecondaryGlow => [
      BoxShadow(
        color: cyberpunkSecondary.withOpacity(0.3),
        blurRadius: cyberpunkGlowMed,
        spreadRadius: 1,
      ),
    ];

/// Cyberpunk 強調元素光暈效果
List<BoxShadow> get cyberpunkAccentGlow => [
      BoxShadow(
        color: cyberpunkAccent.withOpacity(0.4),
        blurRadius: cyberpunkGlowStrong,
        spreadRadius: 2,
      ),
    ];

/// Cyberpunk 警告光暈效果
List<BoxShadow> get cyberpunkCautionGlow => [
      BoxShadow(
        color: cyberpunkCaution.withOpacity(0.5),
        blurRadius: cyberpunkGlowStrong,
        spreadRadius: 1,
      ),
    ];

/// Cyberpunk 面板內陰影
List<BoxShadow> get cyberpunkPanelShadow => [
      BoxShadow(
        color: cyberpunkBgDeep.withOpacity(0.8),
        blurRadius: cyberpunkGlowSoft,
        offset: const Offset(0, 2),
      ),
    ];

// =============================================================================
// 📐 CYBERPUNK 邊框與圓角常數 📐
// =============================================================================

/// Cyberpunk 標準邊框寬度
const double cyberpunkBorderWidth = 1.5;

/// Cyberpunk 強調邊框寬度
const double cyberpunkBorderWidthBold = 2.5;

/// Cyberpunk 標準圓角
const double cyberpunkBorderRadius = 8.0;

/// Cyberpunk 大型圓角
const double cyberpunkBorderRadiusLarge = 12.0;

// =============================================================================
// 📺 CYBERPUNK SCANLINE 掃描線系統 📺
// =============================================================================

/// 是否顯示全畫面掃描線效果
const bool kShowScanline = true;

/// 掃描線透明度
const double kScanlineOpacity = 0.08; // 提高透明度讓掃描線更明顯

/// 掃描線間距 (像素)
const double kScanlineSpacing = 3.0; // 增加間距讓效果更清楚
