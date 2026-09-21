import 'package:cadence/core/glass_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum HighlightClipboardAction { none, copy, cut }
/// Custom text-selection popup to replace the native copy/paste menu.
///
/// [initialAction] seeds this instance's state from whatever was last
/// performed on a PREVIOUS selection (so state 2 — greyed source
/// button + paste slot — can appear the moment a new selection opens
/// the menu, per spec). [onActionChanged] reports any change back up
/// so the next menu instance is seeded correctly too.
class HighlightMenu extends StatefulWidget {
  final HighlightClipboardAction initialAction;
  final ValueChanged<HighlightClipboardAction> onActionChanged;
  final VoidCallback onPunchIn;
  final VoidCallback onPlaySelection;
  final VoidCallback onCopy;
  final VoidCallback onCut;
  final VoidCallback onPaste;

  const HighlightMenu({
    super.key,
    required this.initialAction,
    required this.onActionChanged,
    required this.onPunchIn,
    required this.onPlaySelection,
    required this.onCopy,
    required this.onCut,
    required this.onPaste,
  });

  @override
  State<HighlightMenu> createState() => _HighlightMenuState();
}

class _HighlightMenuState extends State<HighlightMenu> {
  late HighlightClipboardAction _lastAction = widget.initialAction;

  static const double _buttonSize = 48;
  static const double _spacing = 50;

  void _handleCopyTap() {
    widget.onCopy();
    setState(() => _lastAction = HighlightClipboardAction.copy);
    widget.onActionChanged(HighlightClipboardAction.copy);
  }

  void _handleCutTap() {
    widget.onCut();
    setState(() => _lastAction = HighlightClipboardAction.cut);
    widget.onActionChanged(HighlightClipboardAction.cut);
  }

  void _handlePasteTap() {
    widget.onPaste();
    setState(() => _lastAction = HighlightClipboardAction.none);
    widget.onActionChanged(HighlightClipboardAction.none); // reverts menu to state 1
  }

  @override
  Widget build(BuildContext context) {
    final showPaste = _lastAction != HighlightClipboardAction.none;
    final copyDisabled = _lastAction == HighlightClipboardAction.copy;
    final cutDisabled = _lastAction == HighlightClipboardAction.cut;

    final specs = <_IconSpec>[
      _IconSpec('assets/icons/punch_in_icon.svg', 12, 17, widget.onPunchIn),
      _IconSpec('assets/icons/play_selection_icon.svg', 13, 15, widget.onPlaySelection),
      _IconSpec('assets/icons/copy_icon.svg', 15, 15, _handleCopyTap, enabled: !copyDisabled),
      _IconSpec('assets/icons/cut_icon.svg', 15, 16, _handleCutTap, enabled: !cutDisabled),
      if (showPaste) _IconSpec('assets/icons/paste_icon.svg', 15, 15, _handlePasteTap),
    ];

    final width = (_spacing * (specs.length - 1)) + _buttonSize;

    return Material(
      color: Colors.transparent,
      child: Container(
        width: width,
        height: _buttonSize,
        decoration: const BoxDecoration(
          boxShadow: [
            BoxShadow(color: Color(0x0C000000), blurRadius: 10, offset: Offset(0, 2)),
          ],
        ),
        child: Stack(
          children: [
            for (var i = 0; i < specs.length; i++)
              Positioned(left: i * _spacing, top: 0, child: _ActionButton(spec: specs[i])),
          ],
        ),
      ),
    );
  }
}

class _IconSpec {
  final String assetPath;
  final double width;
  final double height;
  final VoidCallback onTap;
  final bool enabled;
  const _IconSpec(this.assetPath, this.width, this.height, this.onTap, {this.enabled = true});
}

class _ActionButton extends StatelessWidget {
  final _IconSpec spec;
  const _ActionButton({required this.spec});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: spec.enabled ? spec.onTap : null,
      child: GlassSurface(
        width: 48,
        height: 48,
        borderRadius: 20,
        child: Center(
          child: Opacity(
            opacity: spec.enabled ? 1.0 : 0.1,
            child: SvgPicture.asset(
              spec.assetPath,
              width: spec.width,
              height: spec.height,
              colorFilter: const ColorFilter.mode(Color(0xFF2A2A2A), BlendMode.srcIn),
            ),
          ),
        ),
      ),
    );
  }
}