import 'package:flutter/material.dart';
import '../models/tetromino.dart';
import '../services/audio_service.dart';
import '../theme/game_theme.dart';

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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: GameTheme.panelGradient,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: GameTheme.boardBorder,
          width: 2,
        ),
        boxShadow: GameTheme.cardShadow,
      ),
      child: Column(
        children: [
          Text(
            'NEXT',
            style: GameTheme.accentStyle.copyWith(fontSize: 12),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: GameTheme.gameBoardBg.withOpacity(0.7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: preview
                  .map((row) => Row(
                        children: row
                            .map(
                              (c) => Container(
                                width: cellSize * 0.8,
                                height: cellSize * 0.8,
                                margin: const EdgeInsets.all(0.5),
                                decoration: BoxDecoration(
                                  color: c ?? Colors.transparent,
                                  borderRadius: BorderRadius.circular(2),
                                  border: c != null
                                      ? Border.all(
                                          color: Colors.white.withOpacity(0.2),
                                          width: 0.5,
                                        )
                                      : null,
                                ),
                              ),
                            )
                            .toList(),
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  static Widget infoBox(String text, {String? label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: GameTheme.panelGradient,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: GameTheme.boardBorder,
          width: 1,
        ),
        boxShadow: GameTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null) ...[
            Text(
              label,
              style: GameTheme.subtitleStyle.copyWith(fontSize: 11),
            ),
            const SizedBox(height: 4),
          ],
          Text(
            text,
            style: GameTheme.accentStyle.copyWith(fontSize: 18),
          ),
        ],
      ),
    );
  }

  static Widget overlayText(String text, Color color) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.8),
              Colors.black.withOpacity(0.9),
              Colors.black.withOpacity(0.8),
            ],
          ),
        ),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withOpacity(0.1),
                  color.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: color.withOpacity(0.5),
                width: 2,
              ),
            ),
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 42,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.8),
                    blurRadius: 8,
                    offset: const Offset(2, 2),
                  ),
                ],
              ),
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
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: GameTheme.panelGradient,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: GameTheme.boardBorder,
              width: 1,
            ),
            boxShadow: GameTheme.cardShadow,
          ),
          child: Column(
            children: [
              Text(
                'AUDIO',
                style: GameTheme.accentStyle.copyWith(fontSize: 12),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: audioService.isMusicEnabled
                          ? GameTheme.buttonPrimary.withOpacity(0.8)
                          : GameTheme.gridLine,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      onPressed: () async {
                        await audioService.toggleMusic();
                        setState(() {});
                      },
                      icon: Icon(
                        audioService.isMusicEnabled
                            ? Icons.music_note
                            : Icons.music_off,
                        color: Colors.white,
                        size: 20,
                      ),
                      tooltip:
                          audioService.isMusicEnabled ? '關閉音樂 (M)' : '開啟音樂 (M)',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: audioService.isSfxEnabled
                          ? GameTheme.buttonPrimary.withOpacity(0.8)
                          : GameTheme.gridLine,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      onPressed: () {
                        audioService.toggleSfx();
                        setState(() {});
                      },
                      icon: Icon(
                        audioService.isSfxEnabled
                            ? Icons.volume_up
                            : Icons.volume_off,
                        color: Colors.white,
                        size: 20,
                      ),
                      tooltip:
                          audioService.isSfxEnabled ? '關閉音效 (S)' : '開啟音效 (S)',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () async {
                  await audioService.playBackgroundMusic();
                  setState(() {});
                },
                style: GameTheme.secondaryButtonStyle.copyWith(
                  minimumSize: MaterialStateProperty.all(const Size(120, 32)),
                  padding: MaterialStateProperty.all(
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.play_arrow, size: 16),
                    const SizedBox(width: 4),
                    Text('播放', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
