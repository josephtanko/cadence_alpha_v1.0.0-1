import 'package:flutter/material.dart';

/// The Figma reference frame screens are designed against.
class DesignFrame {
  static const double width = 393;
  static const double height = 852;
}

/// main colors from the design spec.
class AppColors {
  static const background = Color(0xFFF5F5F5);
  static const textDark = Color(0xFF2A2A2A);
  static const black = Color(0xFF000000);
  static const white = Color(0xFFFFFFFF);
  static const searchFill = Color(0xFFF4F4F4);
  static const strokeGray = Color(0xFF7F7F7F);
}
/// Placeholder tempo 
class TempoDefaults {
  static const double bpm = 120;
  static const int beatsPerBar = 4;

  static double get secondsPerBar => (60 / bpm) * beatsPerBar;

  static List<double> get zoomSteps => [
        secondsPerBar * 4, // 4 bars per tick
        secondsPerBar * 2, // 2 bars per tick
        secondsPerBar, // 1 bar per tick (default)
        secondsPerBar / 2, // half bar (2 beats) per tick
        secondsPerBar / 4, // 1 beat per tick
        secondsPerBar / 8, // half beat per tick
      ];
}
class AppGradients {
  static const lyricSheetBackground = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFF5F5F5),
      Color(0xFFFFFFFF),
    ],
  );
}