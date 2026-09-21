import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:just_audio/just_audio.dart';
import '../core/design_constants.dart';
import '../core/glass_surface.dart';
import '../core/controllers/toolbar_controller.dart';
import '../core/utils/format_duration.dart';
import 'tap_target.dart';

enum WorkspaceView { edit, cadence }

class CadenceToolbar extends StatefulWidget {
  final ToolbarController controller;
  final WorkspaceView currentView;
  final ValueChanged<WorkspaceView> onViewChanged;
  final VoidCallback? onImportTap;

  const CadenceToolbar({
    super.key,
    required this.controller,
    required this.currentView,
    required this.onViewChanged,
    this.onImportTap,
  });

  @override
  State<CadenceToolbar> createState() => _CadenceToolbarState();
}

class _CadenceToolbarState extends State<CadenceToolbar> {
  bool _placeholderPlaying = false;

  static const TextStyle _timeStyle = TextStyle(
    fontFamily: 'PerpetuaTitlingMT-Bold',
    fontSize: 10,
    color: AppColors.textDark,
  );

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        return SizedBox(
          width: 330,
          height: 130,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              _toolbarPill(),
              Positioned(
                left: 0,
                top: 72,
                child: widget.controller.isRecording ? _liveWaveform() : _trackScrubber(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _toolbarPill() {
    return GlassSurface(
      width: 330,
      height: 60,
      borderRadius: 20,
      child: Stack(
        children: [
          _viewIcon(
            view: WorkspaceView.edit,
            left: 21,
            top: 15,
            child: SvgPicture.asset('assets/icons/edit_mode_button.svg', width: 30, height: 30),
          ),
          _importIcon(),
          _playbackToggle(),
          _viewIcon(
            view: WorkspaceView.cadence,
            left: 221,
            top: 15,
            child: SvgPicture.asset('assets/icons/cadence_mode_button.svg', width: 30, height: 30),
          ),
          _recordToggle(),
          _activeToolIndicator(),
        ],
      ),
    );
  }

  Widget _viewIcon({
    required WorkspaceView view,
    required double left,
    required double top,
    required Widget child,
  }) {
    final pos = TapTarget.offset(left, top, 30);
    return Positioned(
      left: pos.dx,
      top: pos.dy,
      child: TapTarget(
        visualSize: 30,
        onTap: () => widget.onViewChanged(view),
        child: child,
      ),
    );
  }

  Widget _importIcon() {
    final pos = TapTarget.offset(81, 15, 30);
    return Positioned(
      left: pos.dx,
      top: pos.dy,
      child: TapTarget(
        visualSize: 30,
        onTap: () => widget.onImportTap?.call(),
        child: SvgPicture.asset('assets/icons/import_audio_button.svg', width: 30, height: 30),
      ),
    );
  }

  Widget _playbackToggle() {
    final pos = TapTarget.offset(161, 19, 20);

    if (widget.currentView == WorkspaceView.cadence) {
      return Positioned(
        left: pos.dx,
        top: pos.dy,
        child: TapTarget(
          visualSize: 20,
          onTap: () => setState(() => _placeholderPlaying = !_placeholderPlaying),
          child: _placeholderPlaying
              ? SvgPicture.asset('assets/icons/pause_playback_button.svg', width: 20, height: 22)
              : SvgPicture.asset('assets/icons/play_playback_button.svg', width: 20, height: 20),
        ),
      );
    }

    final player = widget.controller.audioPlayer;

    if (player == null) {
      return Positioned(
        left: pos.dx,
        top: pos.dy,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: Opacity(
              opacity: 0.3,
              child: SvgPicture.asset('assets/icons/play_playback_button.svg', width: 20, height: 20),
            ),
          ),
        ),
      );
    }

    if (widget.controller.isRecording) {
      final showPause = !widget.controller.isRecordingPaused;
      return Positioned(
        left: pos.dx,
        top: pos.dy,
        child: TapTarget(
          visualSize: 20,
          onTap: widget.controller.handlePlayPauseTap,
          child: showPause
              ? SvgPicture.asset('assets/icons/pause_playback_button.svg', width: 20, height: 22)
              : SvgPicture.asset('assets/icons/play_playback_button.svg', width: 20, height: 20),
        ),
      );
    }

    return Positioned(
      left: pos.dx,
      top: pos.dy,
      child: StreamBuilder<PlayerState>(
        stream: player.playerStateStream,
        builder: (context, snapshot) {
          final playing = snapshot.data?.playing ?? false;
          return TapTarget(
            visualSize: 20,
            onTap: widget.controller.handlePlayPauseTap,
            onDoubleTap: widget.controller.handlePlayDoubleTap,
            child: playing
                ? SvgPicture.asset('assets/icons/pause_playback_button.svg', width: 20, height: 22)
                : SvgPicture.asset('assets/icons/play_playback_button.svg', width: 20, height: 20),
          );
        },
      ),
    );
  }

  Widget _recordToggle() {
    final pos = TapTarget.offset(281, 15, 30);
    return Positioned(
      left: pos.dx,
      top: pos.dy,
      child: TapTarget(
        visualSize: 30,
        onTap: widget.controller.toggleRecordButton,
        child: widget.controller.isRecording
            ? Center(
                child: SvgPicture.asset('assets/icons/stop_record_button.svg', width: 14, height: 16),
              )
            : SvgPicture.asset('assets/icons/start_record_button.svg', width: 30, height: 30),
      ),
    );
  }

  Widget _activeToolIndicator() {
    final left = widget.currentView == WorkspaceView.cadence ? 221.0 : 21.0;
    return Positioned(
      left: left + 10,
      top: 50,
      child: Container(
        width: 10,
        height: 6,
        decoration: BoxDecoration(
          color: AppColors.textDark.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(5),
        ),
      ),
    );
  }

  Widget _trackScrubber() {
    final player = widget.controller.audioPlayer;
    if (player == null) return const SizedBox.shrink();

    const trackWidth = 330.0;
    const hitHeight = 28.0;

    return SizedBox(
      width: trackWidth,
      child: StreamBuilder<Duration>(
        stream: player.positionStream,
        builder: (context, snapshot) {
          final position = widget.controller.isSeeking
              ? widget.controller.seekPreviewPosition
              : (snapshot.data ?? Duration.zero);
          final total = widget.controller.totalDuration;
          final progress = total.inMilliseconds > 0
              ? (position.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0)
              : 0.0;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(formatDuration(position), style: _timeStyle),
                  Text(formatDuration(total), style: _timeStyle),
                ],
              ),
              const SizedBox(height: 4),
              SizedBox(
                height: hitHeight,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (details) =>
                      widget.controller.seekToLocalX(details.localPosition.dx, trackWidth),
                  onHorizontalDragStart: (_) => widget.controller.setSeeking(true),
                  onHorizontalDragUpdate: (details) =>
                      widget.controller.updateSeekPreview(details.localPosition.dx, trackWidth),
                  onHorizontalDragEnd: (_) => widget.controller.commitSeek(),
                  child: Center(
                    child: Container(
                      width: trackWidth,
                      height: 6,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        color: AppColors.strokeGray.withValues(alpha: 0.25),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: progress,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(3),
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _liveWaveform() {
    return SizedBox(
      width: 330,
      height: 34,
      child: CustomPaint(
        painter: _WaveformPainter(List.of(widget.controller.waveformLevels)),
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final List<double> levels;
  static const int maxBars = 55;

  _WaveformPainter(this.levels);

  @override
  void paint(Canvas canvas, Size size) {
    if (levels.isEmpty) return;
    final paint = Paint()
      ..color = AppColors.strokeGray.withValues(alpha: 0.25)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.square;

    final barSpacing = size.width / maxBars;
    for (var i = 0; i < levels.length; i++) {
      final x = i * barSpacing + barSpacing / 2;
      final barHeight = (levels[i] * size.height).clamp(2.0, size.height);
      final y1 = (size.height - barHeight) / 2;
      final y2 = y1 + barHeight;
      canvas.drawLine(Offset(x, y1), Offset(x, y2), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) => true;
}