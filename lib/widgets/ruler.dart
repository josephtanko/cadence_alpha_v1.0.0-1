import 'package:flutter/material.dart';
import '../core/controllers/ruler_zoom_controller.dart';
import '../core/design_constants.dart';

class Ruler extends StatelessWidget {
  final double barSpacing;
  final double secondsPerBar;
  final double totalDurationSeconds;

  const Ruler({
    super.key,
    this.barSpacing = 50,
    required this.secondsPerBar,
    required this.totalDurationSeconds,
  });

  static const double width = 80;
  static const double lineX = 17;
  static const double firstTickY = 24.5;
  static const double defaultBarSpacing = 50;

  static double heightFor(
    double secondsPerBar,
    double totalDurationSeconds, {
    double barSpacing = 50,
  }) {
    final barCount = (totalDurationSeconds / secondsPerBar).ceil() + 1;
    return firstTickY + ((barCount - 1) * barSpacing) + 40;
  }

  String _formatTime(double seconds) {
    final totalMs = (seconds * 1000).round();
    final minutes = totalMs ~/ 60000;
    final secs = (totalMs % 60000) ~/ 1000;
    final ms = (totalMs % 1000) ~/ 10; // 2-digit centiseconds/milliseconds (00-99)

    if (ms > 0) {
      return '$minutes:${secs.toString().padLeft(2, '0')}:${ms.toString().padLeft(2, '0')}s';
    }
    return '$minutes:${secs.toString().padLeft(2, '0')}s';
  }

  @override
  Widget build(BuildContext context) {
    final barCount = (totalDurationSeconds / secondsPerBar).ceil() + 1;
    final height = heightFor(
      secondsPerBar,
      totalDurationSeconds,
      barSpacing: barSpacing,
    );

    int subdivisionsPerBar = 1;
    if (barSpacing >= 140) {
      subdivisionsPerBar = 4; // Sub-seconds / quarter-bar ticks
    } else if (barSpacing >= 80) {
      subdivisionsPerBar = 2; // Half-bar ticks
    }

    final totalTicks = (barCount - 1) * subdivisionsPerBar + 1;
    final tickSpacing = barSpacing / subdivisionsPerBar;
    final secondsPerTick = secondsPerBar / subdivisionsPerBar;

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _RulerLinePainter(
                lineX: lineX,
                firstTickY: firstTickY,
                tickSpacing: tickSpacing,
                totalTicks: totalTicks,
                subdivisionsPerBar: subdivisionsPerBar,
              ),
            ),
          ),
          for (var i = 0; i < totalTicks; i++) ...[
            // Main Bar Numbers (Bar 0, 1, 2...)
            if (i % subdivisionsPerBar == 0)
              Positioned(
                left: -2,
                width: 15,
                top: firstTickY + (i * tickSpacing) - 6,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '${i ~/ subdivisionsPerBar}',
                      style: const TextStyle(
                        color: Color(0x7F2A2A2A),
                        fontSize: 10,
                        fontFamily: 'PerpetuaTitlingMT',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),

            // Dynamic Time Labels (Includes milliseconds on sub-ticks)
            Positioned(
              left: 32,
              top: firstTickY + (i * tickSpacing) - 5,
              child: Text(
                _formatTime(i * secondsPerTick),
                style: TextStyle(
                  color: i % subdivisionsPerBar == 0
                      ? const Color(0x7F2A2A2A)
                      : const Color(0x402A2A2A),
                  fontSize: i % subdivisionsPerBar == 0 ? 8 : 7,
                  fontFamily: 'PerpetuaTitlingMT',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RulerLinePainter extends CustomPainter {
  final double lineX;
  final double firstTickY;
  final double tickSpacing;
  final int totalTicks;
  final int subdivisionsPerBar;

  _RulerLinePainter({
    required this.lineX,
    required this.firstTickY,
    required this.tickSpacing,
    required this.totalTicks,
    required this.subdivisionsPerBar,
  });

  static const double _dashWidth = 6;
  static const double _dashHeight = 1.5;
  static const double _dashGap = 2.5;

  @override
  void paint(Canvas canvas, Size size) {
    final dashPaint = Paint()..color = const Color(0x402A2A2A);

    double y = 0;
    while (y < size.height) {
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(lineX, y),
          width: _dashWidth,
          height: _dashHeight,
        ),
        dashPaint,
      );
      y += _dashHeight + _dashGap;
    }

    final barTickPaint = Paint()
      ..color = const Color(0x402A2A2A)
      ..strokeWidth = 2;

    final subTickPaint = Paint()
      ..color = const Color(0x402A2A2A)
      ..strokeWidth = 1;

    for (var i = 0; i < totalTicks; i++) {
      final tickY = firstTickY + (i * tickSpacing);
      final isMainBar = i % subdivisionsPerBar == 0;

      canvas.drawLine(
        Offset(lineX, tickY),
        Offset(lineX + (isMainBar ? 10 : 5), tickY),
        isMainBar ? barTickPaint : subTickPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RulerLinePainter oldDelegate) =>
      oldDelegate.tickSpacing != tickSpacing ||
      oldDelegate.totalTicks != totalTicks ||
      oldDelegate.subdivisionsPerBar != subdivisionsPerBar;
}

class ZoomableRuler extends StatefulWidget {
  final double totalDurationSeconds;
  final double viewportWidth;
  final double viewportHeight;
  final RulerZoomController? controller;

  const ZoomableRuler({
    super.key,
    required this.totalDurationSeconds,
    required this.viewportWidth,
    required this.viewportHeight,
    this.controller,
  });

  @override
  State<ZoomableRuler> createState() => _ZoomableRulerState();
}

class _ZoomableRulerState extends State<ZoomableRuler> {
  late final RulerZoomController _controller;
  late final double _secondsPerBar;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? RulerZoomController();
    _secondsPerBar = TempoDefaults.secondsPerBar;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final isMultiTouch = _controller.activePointers >= 2;

        return ClipRect(
          child: SizedBox(
            width: widget.viewportWidth,
            height: widget.viewportHeight,
            child: Listener(
              onPointerDown: (_) => _controller.handlePointerDown(),
              onPointerUp: (_) => _controller.handlePointerUpOrCancel(),
              onPointerCancel: (_) => _controller.handlePointerUpOrCancel(),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onScaleStart: _controller.onScaleStart,
                onScaleUpdate: (details) =>
                    _controller.onScaleUpdate(details, _secondsPerBar),
                child: SingleChildScrollView(
                  controller: _controller.scrollController,
                  // Lock scroll physics instantly when 2+ fingers are on screen
                  physics: isMultiTouch
                      ? const NeverScrollableScrollPhysics()
                      : const BouncingScrollPhysics(),
                  child: Ruler(
                    barSpacing: _controller.barSpacing,
                    secondsPerBar: _secondsPerBar,
                    totalDurationSeconds: widget.totalDurationSeconds,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}