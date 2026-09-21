import 'package:flutter/widgets.dart';

class RulerZoomController extends ChangeNotifier {
  final ScrollController scrollController = ScrollController();

  double _barSpacing = RulerDefaults.defaultBarSpacing;
  double get barSpacing => _barSpacing;

  int _activePointers = 0;
  int get activePointers => _activePointers;

  double _gestureStartBarSpacing = RulerDefaults.defaultBarSpacing;
  double _gestureStartScrollOffset = 0;
  double _gestureStartFocalLocalY = 0;

  static const double minBarSpacing = 30.0;
  static const double maxBarSpacing = 300.0;

  void handlePointerDown() {
    _activePointers++;
    notifyListeners();
  }

  void handlePointerUpOrCancel() {
    _activePointers = (_activePointers - 1).clamp(0, 10);
    notifyListeners();
  }

  void onScaleStart(ScaleStartDetails details) {
    _gestureStartBarSpacing = _barSpacing;
    _gestureStartScrollOffset = scrollController.hasClients ? scrollController.offset : 0;
    _gestureStartFocalLocalY = details.localFocalPoint.dy;
  }

  void onScaleUpdate(ScaleUpdateDetails details, double secondsPerBar) {
    if (details.pointerCount < 2) return;

    final newBarSpacing = (_gestureStartBarSpacing * details.scale)
        .clamp(minBarSpacing, maxBarSpacing);

    final anchorContentY = _gestureStartScrollOffset + _gestureStartFocalLocalY;
    final barFractionAtAnchor = (anchorContentY - RulerDefaults.firstTickY) / _gestureStartBarSpacing;
    final newAnchorContentY = RulerDefaults.firstTickY + (barFractionAtAnchor * newBarSpacing);

    final currentFocalLocalY = details.localFocalPoint.dy;
    final targetOffset = newAnchorContentY - currentFocalLocalY;

    _barSpacing = newBarSpacing;
    notifyListeners();

    if (scrollController.hasClients) {
      final maxScroll = scrollController.position.maxScrollExtent;
      scrollController.jumpTo(targetOffset.clamp(0.0, maxScroll));
    }
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }
}

class RulerDefaults {
  static const double defaultBarSpacing = 50.0;
  static const double firstTickY = 24.5;
}