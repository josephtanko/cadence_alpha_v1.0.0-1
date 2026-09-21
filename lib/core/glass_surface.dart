// lib/core/glass_surface.dart
import 'dart:ui';
import 'package:flutter/material.dart';

class GlassSurface extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;
  final Widget child;

  const GlassSurface({
    super.key,
    required this.width,
    required this.height,
    required this.borderRadius,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            offset: Offset(0, 4),
            blurRadius: 10,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.35), // brighter frost, top-left
                  Colors.white.withValues(alpha: 0.10), // fades toward bottom-right
                ],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.4), // light-catching edge
                width: 1,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}