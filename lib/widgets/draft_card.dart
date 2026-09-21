import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../core/design_constants.dart';
import '../core/glass_surface.dart';
import '../core/models/draft.dart';
import '../core/utils/format_duration.dart';
import 'tap_target.dart';

/// [completion] is 0.0–1.0 for the progress ring, currently passed as
/// 0.0 for now. Swap caller's value once completion tracking is built.
class DraftCard extends StatelessWidget {
  final Draft draft;
  final double completion;
  final VoidCallback onTap;
  final VoidCallback onMenuTap;

  const DraftCard({
    super.key,
    required this.draft,
    required this.onTap,
    required this.onMenuTap,
    this.completion = 0.0,
  });

  static const List<String> _monthAbbrev = [
    'jan', 'feb', 'mar', 'apr', 'may', 'jun',
    'jul', 'aug', 'sep', 'oct', 'nov', 'dec',
  ];

  String _formatDate(int millis) {
    final date = DateTime.fromMillisecondsSinceEpoch(millis);
    return '${date.day} ${_monthAbbrev[date.month - 1]}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final dateText = _formatDate(draft.updatedAt);
    final subtitle = draft.instrumentalDurationMs != null
        ? '$dateText • ${formatDuration(Duration(milliseconds: draft.instrumentalDurationMs!))}'
        : dateText;

    return GestureDetector(
      onTap: onTap,
      child: GlassSurface(
        width: 330,
        height: 80,
        borderRadius: 20,
        child: Stack(
          children: [
            // Completion ring
            Positioned(
              left: 11,
              top: 18,
              child: SizedBox(
                width: 42,
                height: 42,
                child: CustomPaint(
                  painter: _CompletionRingPainter(completion),
                ),
              ),
            ),

            // Title
            Positioned(
              left: 67,
              top: 16,
              child: SizedBox(
                width: 200,
                child: Text(
                  draft.name.trim().isEmpty ? 'untitled' : draft.name.trim(),
                  style: const TextStyle(
                    fontFamily: 'Arial',
                    fontSize: 18,
                    color: AppColors.textDark,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ),

            // Date + duration
            Positioned(
              left: 67,
              top: 39,
              child: Text(
                subtitle,
                style: TextStyle(
                  fontFamily: 'Arial',
                  fontSize: 16,
                  color: AppColors.textDark.withValues(alpha: 0.50),
                ),
              ),
            ),

            // Dot menu
            Positioned(
              left: 297 - 10, // TapTarget.offset(297, 28, 24, 44) = (287, 18)
              top: 28 - 10,
              child: TapTarget(
                visualSize: 24,
                onTap: onMenuTap,
                child: SvgPicture.asset(
                  'assets/icons/dot_menu_icon.svg',
                  width: 24,
                  height: 24,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Draws the circular completion indicator. Spec: starts at -90° (top),
/// and sweeps counter-clockwise proportional to [progress] (0.0–1.0).
class _CompletionRingPainter extends CustomPainter {
  final double progress;

  _CompletionRingPainter(this.progress);

  static const double _strokeWidth = 5;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = (size.width - _strokeWidth) / 2;
    final center = Offset(size.width / 2, size.height / 2);

    final backgroundPaint = Paint()
      ..color = const Color(0x407E7E7E) // #7E7E7E @ 25%
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth;
    canvas.drawCircle(center, radius, backgroundPaint);

    if (progress <= 0) return; // nothing to draw for an empty ring

    final foregroundPaint = Paint()
      ..color = const Color(0xFF171717)
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.round;

    const startAngle = -1.5707963267948966; // -90° in radians (-pi/2)
    final sweepAngle = -6.283185307179586 * progress.clamp(0.0, 1.0); // -2*pi * progress

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      foregroundPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CompletionRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}