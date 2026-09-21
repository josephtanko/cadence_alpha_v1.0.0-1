import 'package:flutter/material.dart';

/// Wraps a small visual icon in a larger invisible tap target, centered
/// around the icon's original visual position — meets standard ~44x44
/// accessibility tap-target guidance without changing how anything
/// looks on screen.
class TapTarget extends StatelessWidget {
  final double visualSize;
  final double hitSize;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;
  final Widget child;

  const TapTarget({
    super.key,
    required this.visualSize,
    required this.child,
    this.onTap,
    this.hitSize = 44,
    this.onDoubleTap,
  });

  /// Given an icon's original top-left Positioned coordinates and its
  /// visual size, returns the (left, top) to use for the TapTarget's
  /// own Positioned wrapper — keeps the visible icon exactly where it
  /// always was, just padded with extra invisible tappable space.
  static Offset offset(double originalLeft, double originalTop, double visualSize, [double hitSize = 44]) {
    final pad = (hitSize - visualSize) / 2;
    return Offset(originalLeft - pad, originalTop - pad);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: hitSize,
      height: hitSize,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        onDoubleTap: onDoubleTap,
        child: Center(
          child: SizedBox(width: visualSize, height: visualSize, child: child),
        ),
      ),
    );
  }
}