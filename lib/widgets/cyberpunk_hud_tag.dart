import 'package:flutter/material.dart';
import '../core/constants.dart';

/// Cyberpunk 風格小型 HUD 標籤
class CyberpunkHudTag extends StatelessWidget {
  final String text;
  final String? highlightText; // 強調文字（如鍵位）
  final bool isCompact;

  const CyberpunkHudTag({
    super.key,
    required this.text,
    this.highlightText,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 6 : 8,
        vertical: isCompact ? 3 : 4,
      ),
      decoration: BoxDecoration(
        // 深底
        color: cyberpunkBgDeep,
        borderRadius: BorderRadius.circular(4),
        // 細描邊
        border: Border.all(
          color: cyberpunkPrimary.withOpacity(0.4),
          width: 1,
        ),
        // 上緣 10% 高光
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0.0, 0.1, 1.0],
          colors: [
            Colors.white.withOpacity(0.1), // 上緣高光
            cyberpunkBgDeep.withOpacity(0.9),
            cyberpunkBgDeep,
          ],
        ),
      ),
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (highlightText != null) {
      // 有強調文字時，分割顯示
      final parts = text.split(highlightText!);

      return RichText(
        text: TextSpan(
          style: TextStyle(
            fontSize: isCompact ? 10 : 11,
            color: cyberpunkPrimary, // 主體用 primary
            fontWeight: FontWeight.w500,
          ),
          children: [
            if (parts.isNotEmpty) TextSpan(text: parts[0]),
            TextSpan(
              text: highlightText,
              style: TextStyle(
                color: cyberpunkSecondary, // 強調鍵位用 secondary
                fontWeight: FontWeight.bold,
              ),
            ),
            if (parts.length > 1) TextSpan(text: parts[1]),
          ],
        ),
      );
    } else {
      // 純文字顯示
      return Text(
        text,
        style: TextStyle(
          fontSize: isCompact ? 10 : 11,
          color: cyberpunkPrimary,
          fontWeight: FontWeight.w500,
        ),
      );
    }
  }
}

/// Cyberpunk 控制提示群組
class CyberpunkControlHints extends StatelessWidget {
  final List<Map<String, String>> controls;
  final bool isCompact;

  const CyberpunkControlHints({
    super.key,
    required this.controls,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: controls.map((control) {
        return CyberpunkHudTag(
          text: control['text'] ?? '',
          highlightText: control['key'],
          isCompact: isCompact,
        );
      }).toList(),
    );
  }
}
