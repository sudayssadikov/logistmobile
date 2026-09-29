import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../domain/models/chat_message_model.dart';

class VoiceNotePlayerWidget extends StatefulWidget {
  final VoiceNotePayload voicePayload;
  final bool isMine;

  const VoiceNotePlayerWidget({
    super.key,
    required this.voicePayload,
    required this.isMine,
  });

  @override
  State<VoiceNotePlayerWidget> createState() => _VoiceNotePlayerWidgetState();
}

class _VoiceNotePlayerWidgetState extends State<VoiceNotePlayerWidget> with SingleTickerProviderStateMixin {
  late final AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  double _progress = 0.0;
  double _playbackSpeed = 1.0;
  Timer? _fallbackTimer;

  @override
  void initState() {
    super.initState();
    _playbackSpeed = widget.voicePayload.playbackSpeed;
    _audioPlayer = AudioPlayer();

    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (!mounted) return;
      setState(() {
        _isPlaying = state == PlayerState.playing;
      });
    });

    _audioPlayer.onPositionChanged.listen((pos) {
      if (!mounted) return;
      final totalSec = widget.voicePayload.durationSeconds;
      if (totalSec > 0) {
        setState(() {
          _progress = (pos.inMilliseconds / (totalSec * 1000)).clamp(0.0, 1.0);
        });
      }
    });

    _audioPlayer.onPlayerComplete.listen((_) {
      if (!mounted) return;
      setState(() {
        _progress = 0.0;
        _isPlaying = false;
      });
    });
  }

  @override
  void dispose() {
    _fallbackTimer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _togglePlayPause() async {
    if (_isPlaying) {
      try {
        await _audioPlayer.pause();
      } catch (_) {
        _fallbackTimer?.cancel();
        setState(() => _isPlaying = false);
      }
    } else {
      final url = widget.voicePayload.audioUrl;
      if (url != null && url.isNotEmpty && (url.startsWith('http://') || url.startsWith('https://'))) {
        try {
          await _audioPlayer.setPlaybackRate(_playbackSpeed);
          await _audioPlayer.play(UrlSource(url));
        } catch (_) {
          _startFallbackAnimation();
        }
      } else {
        _startFallbackAnimation();
      }
    }
  }

  void _startFallbackAnimation() {
    _fallbackTimer?.cancel();
    setState(() => _isPlaying = true);
    final totalDurationMs = (widget.voicePayload.durationSeconds * 1000) / _playbackSpeed;
    const intervalMs = 50;
    final step = intervalMs / (totalDurationMs > 0 ? totalDurationMs : 3000);

    _fallbackTimer = Timer.periodic(const Duration(milliseconds: intervalMs), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _progress += step;
        if (_progress >= 1.0) {
          _progress = 0.0;
          _isPlaying = false;
          timer.cancel();
        }
      });
    });
  }

  Future<void> _toggleSpeed() async {
    double nextSpeed = 1.0;
    if (_playbackSpeed == 1.0) {
      nextSpeed = 1.5;
    } else if (_playbackSpeed == 1.5) {
      nextSpeed = 2.0;
    } else {
      nextSpeed = 1.0;
    }

    setState(() {
      _playbackSpeed = nextSpeed;
    });

    try {
      await _audioPlayer.setPlaybackRate(nextSpeed);
    } catch (_) {}
  }

  String _formatDuration(int totalSeconds, double progress) {
    final currentSeconds = (totalSeconds * (1.0 - progress)).clamp(0, totalSeconds).toInt();
    final m = currentSeconds ~/ 60;
    final s = currentSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final samples = widget.voicePayload.waveformSamples.isNotEmpty
        ? widget.voicePayload.waveformSamples
        : const [0.3, 0.6, 0.9, 0.4, 0.8, 0.5, 0.2, 0.7, 0.9, 0.6, 0.4, 0.8, 0.3, 0.5, 0.2];

    final primaryColor = widget.isMine ? Colors.white : AppColors.primary;
    final inactiveColor = widget.isMine ? Colors.white38 : (isDark ? AppColors.darkBorder : AppColors.lightBorder);

    return Container(
      constraints: const BoxConstraints(maxWidth: 260),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Play / Pause Circle
          GestureDetector(
            onTap: _togglePlayPause,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: widget.isMine ? Colors.white : AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: widget.isMine ? AppColors.primary : Colors.white,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Waveform and Duration Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Waveform Bars
                SizedBox(
                  height: 24,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      const barWidth = 3.0;
                      const barSpacing = 2.0;
                      final count = (constraints.maxWidth / (barWidth + barSpacing)).floor().clamp(10, 24);

                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: List.generate(count, (i) {
                          final sample = samples[i % samples.length];
                          final barHeight = (sample * 20).clamp(4.0, 22.0);
                          final isPassed = (i / count) <= _progress;

                          return Container(
                            width: barWidth,
                            height: barHeight,
                            decoration: BoxDecoration(
                              color: isPassed ? primaryColor : inactiveColor,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          );
                        }),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 4),

                // Duration & Speed Chip
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(widget.voicePayload.durationSeconds, _progress),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: widget.isMine ? Colors.white70 : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                      ),
                    ),
                    GestureDetector(
                      onTap: _toggleSpeed,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: widget.isMine ? Colors.white24 : AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${_playbackSpeed == 1.0 ? '1' : _playbackSpeed}x',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: widget.isMine ? Colors.white : AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
