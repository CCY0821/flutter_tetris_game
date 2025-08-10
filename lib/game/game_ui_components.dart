import 'package:flutter/material.dart';
import '../models/tetromino.dart';
import '../services/audio_service.dart';

class GameUIComponents {
  static const double cellSize = 20;

  static Widget nextBlockPreview(Tetromino? nextTetromino) {
    const previewSize = 8;
    const offsetX = 2;
    const offsetY = 2;

    final preview = List.generate(
      previewSize,
      (_) => List.generate(previewSize, (_) => null as Color?),
    );

    if (nextTetromino != null) {
      for (final p in nextTetromino.shape) {
        int px = p.dx.toInt() + offsetX;
        int py = p.dy.toInt() + offsetY;
        if (py >= 0 && py < previewSize && px >= 0 && px < previewSize) {
          preview[py][px] = nextTetromino.color;
        }
      }
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border.all(color: Colors.white),
      ),
      child: Column(
        children: preview
            .map((row) => Row(
                  children: row
                      .map(
                        (c) => Container(
                          width: cellSize,
                          height: cellSize,
                          margin: const EdgeInsets.all(1),
                          color: c ?? Colors.transparent,
                        ),
                      )
                      .toList(),
                ))
            .toList(),
      ),
    );
  }

  static Widget infoBox(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style:
            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }

  static Widget overlayText(String text, Color color) {
    return Positioned.fill(
      child: Container(
        color: Colors.black87,
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  static Widget audioControlButton() {
    final audioService = AudioService();
    return StatefulBuilder(
      builder: (context, setState) {
        return Column(
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () async {
                    await audioService.toggleMusic();
                    setState(() {});
                  },
                  icon: Icon(
                    audioService.isMusicEnabled ? Icons.music_note : Icons.music_off,
                    color: Colors.white,
                  ),
                  tooltip: audioService.isMusicEnabled ? '關閉音樂 (M)' : '開啟音樂 (M)',
                ),
                IconButton(
                  onPressed: () {
                    audioService.toggleSfx();
                    setState(() {});
                  },
                  icon: Icon(
                    audioService.isSfxEnabled ? Icons.volume_up : Icons.volume_off,
                    color: Colors.white,
                  ),
                  tooltip: audioService.isSfxEnabled ? '關閉音效 (S)' : '開啟音效 (S)',
                ),
              ],
            ),
            ElevatedButton(
              onPressed: () async {
                // 強制啟動音樂播放（用戶互動觸發）
                await audioService.playBackgroundMusic();
                setState(() {});
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('🎵 播放音樂'),
            ),
          ],
        );
      },
    );
  }
}
