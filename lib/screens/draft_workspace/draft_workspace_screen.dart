import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/design_constants.dart';
import '../../core/glass_surface.dart';
import '../../core/models/draft.dart';
import '../../core/repositories/draft_repository.dart';
import '../../core/controllers/toolbar_controller.dart';
import '../../core/utils/bpm_analyzer.dart';
import '../../widgets/highlight_menu.dart';
import '../../widgets/cadence_toolbar.dart';
import '../../widgets/ruler.dart';

class DraftWorkspaceScreen extends StatefulWidget {
  final Draft draft;

  const DraftWorkspaceScreen({super.key, required this.draft});

  @override
  State<DraftWorkspaceScreen> createState() => _DraftWorkspaceScreenState();
}

class _DraftWorkspaceScreenState extends State<DraftWorkspaceScreen> with WidgetsBindingObserver {
  static const double _textBoxAbsoluteTop = 209;
  static const double _textBoxFullHeight = 620;
  static const double _bufferAboveKeyboard = 8;
  static const double _shieldStartY = 541;

  late final ToolbarController _controller;
  late final TextEditingController _lyricController;
  final ScrollController _lyricsScrollController = ScrollController();
  Timer? _saveDebounce;
  HighlightClipboardAction _lastClipboardAction = HighlightClipboardAction.none;

  WorkspaceView _view = WorkspaceView.edit;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _controller = ToolbarController(widget.draft);
    _lyricController = TextEditingController(text: widget.draft.lyricText);
    _lyricController.addListener(_onLyricChanged);

    _checkAndAnalyzeBpm();
  }

  Future<void> _checkAndAnalyzeBpm() async {
    final path = widget.draft.instrumentalPath;
    if (path != null && path.isNotEmpty && (widget.draft.bpm == null || widget.draft.bpm == 0)) {
      final detectedBpm = await BpmAnalyzer.analyzeBpm(path);
      if (detectedBpm != null && mounted) {
        setState(() {
          widget.draft.bpm = detectedBpm;
        });
        await _persist();
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _controller.handleAppLifecycleChange(state);
  }

  void _onLyricChanged() {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 600), _persist);
  }

  Future<void> _persist() async {
    widget.draft.lyricText = _lyricController.text;
    widget.draft.updatedAt = DateTime.now().millisecondsSinceEpoch;
    await DraftRepository.upsert(widget.draft);
  }

  Future<void> _handleBack() async {
    _saveDebounce?.cancel();
    if (_controller.isRecording) {
      await _controller.stopRecordingAndCommit();
    }
    await _persist();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _saveDebounce?.cancel();
    _lyricController.removeListener(_onLyricChanged);
    _lyricController.dispose();
    _lyricsScrollController.dispose();
    _controller.disposeController();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.sizeOf(context).width / DesignFrame.width;
    final keyboardInsetReal = MediaQuery.of(context).viewInsets.bottom;
    final keyboardInsetDesign = keyboardInsetReal / scale;

    double textBoxHeight = _textBoxFullHeight;
    if (keyboardInsetDesign > 0) {
      final keyboardTopY = DesignFrame.height - keyboardInsetDesign;
      final available = keyboardTopY - _textBoxAbsoluteTop - _bufferAboveKeyboard;
      textBoxHeight = available.clamp(80.0, _textBoxFullHeight);
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _handleBack();
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        resizeToAvoidBottomInset: false,
        body: Container(
          decoration: const BoxDecoration(
            gradient: AppGradients.lyricSheetBackground,
          ),
          child: SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.fitWidth,
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: DesignFrame.width,
                height: DesignFrame.height,
                child: Stack(
                  children: [
                    IndexedStack(
                      index: _view.index,
                      children: [
                        _lyricContent(textBoxHeight),
                        _cadenceContent(),
                      ],
                    ),
                    _pageTitle(),
                    _getProButtonSmall(),
                    _settingsButton(),
                    _backButton(),
                    Positioned(
                      left: 31,
                      top: 710,
                      child: CadenceToolbar(
                        controller: _controller,
                        currentView: _view,
                        onViewChanged: (v) => setState(() => _view = v),
                        onImportTap: () {},
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _lyricContent(double textBoxHeight) {
    return SizedBox(
      width: DesignFrame.width,
      height: DesignFrame.height,
      child: Stack(
        children: [_pagesBackground(textBoxHeight)],
      ),
    );
  }

  Widget _pagesBackground(double textBoxHeight) {
    return Positioned(
      left: 0,
      top: 169,
      child: SizedBox(
        width: 393,
        height: 690,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 3,
              top: 4,
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                child: SvgPicture.asset(
                  'assets/icons/Lyric_sheet_1.svg',
                  width: 393,
                  height: 690,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withValues(alpha: 0.25),
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: SvgPicture.asset('assets/icons/Lyric_sheet_2.svg', width: 393, height: 690),
            ),
            Positioned.fill(
              child: SvgPicture.asset('assets/icons/Lyric_sheet_1.svg', width: 393, height: 690),
            ),
            Positioned(
              left: 233,
              top: 10,
              child: GestureDetector(
                onTap: () {},
                child: SvgPicture.asset('assets/icons/add_sheet_3_button.svg', width: 76.5, height: 19.5),
              ),
            ),
            Positioned(
              left: 14,
              top: 40,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOut,
                width: 366,
                height: textBoxHeight,
                clipBehavior: Clip.hardEdge,
                decoration: const BoxDecoration(),
                child: ShaderMask(
                  shaderCallback: (bounds) {
                    final fadeStart = ((_shieldStartY - 40 - 60) / bounds.height).clamp(0.0, 1.0);
                    return LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: const [Colors.black, Colors.transparent],
                      stops: [fadeStart, 1.0],
                    ).createShader(bounds);
                  },
                  blendMode: BlendMode.dstIn,
                  child: Stack(
                    children: [
                      TextSelectionTheme(
                        data: TextSelectionThemeData(
                          cursorColor: const Color(0xFFFFD52E),
                          selectionColor: const Color(0xFFFFD52E).withValues(alpha: 0.4),
                          selectionHandleColor: const Color(0xFFFFD52E),
                        ),
                        child: TextField(
                          controller: _lyricController,
                          scrollController: _lyricsScrollController,
                          scrollPhysics: const BouncingScrollPhysics(),
                          maxLines: null,
                          minLines: null,
                          expands: true,
                          keyboardType: TextInputType.multiline,
                          textInputAction: TextInputAction.newline,
                          textAlignVertical: TextAlignVertical.top,
                          cursorColor: const Color(0xFFFFD52E),
                          cursorWidth: 1.5,
                          strutStyle: const StrutStyle(
                            fontFamily: 'MontserratBlack',
                            fontSize: 20,
                            height: 1.5,
                            forceStrutHeight: true,
                          ),
                          style: const TextStyle(
                            fontFamily: 'MontserratBlack',
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
                            height: 1.5,
                            color: Color(0xFF000000),
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isCollapsed: true,
                            contentPadding: EdgeInsets.fromLTRB(18, 18, 18, 0),
                          ),
                          contextMenuBuilder: (context, editableTextState) {
                            final anchors = editableTextState.contextMenuAnchors;
                            final anchor = anchors.secondaryAnchor ?? anchors.primaryAnchor;

                            return CustomSingleChildLayout(
                              delegate: _HighlightMenuLayoutDelegate(anchor),
                              child: HighlightMenu(
                                initialAction: _lastClipboardAction,
                                onActionChanged: (action) =>
                                    setState(() => _lastClipboardAction = action),
                                onPunchIn: () => editableTextState.hideToolbar(),
                                onPlaySelection: () => editableTextState.hideToolbar(),
                                onCopy: () =>
                                    editableTextState.copySelection(SelectionChangedCause.toolbar),
                                onCut: () =>
                                    editableTextState.cutSelection(SelectionChangedCause.toolbar),
                                onPaste: () =>
                                    editableTextState.pasteText(SelectionChangedCause.toolbar),
                              ),
                            );
                          },
                        ),
                      ),
                      Positioned(
                        left: 0,
                        top: 8,
                        child: IgnorePointer(
                          child: SizedBox(
                            width: 343,
                            height: 655,
                            child: SvgPicture.asset(
                              'assets/icons/textfield_faders.svg',
                              width: 343,
                              height: 655,
                              fit: BoxFit.fill,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              top: _shieldStartY,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {},
                onHorizontalDragStart: (_) {},
                onHorizontalDragUpdate: (_) {},
                child: SizedBox(width: 393, height: 690 - _shieldStartY),
              ),
            ),
            Positioned(
              right: 16,
              top: 42,
              child: GestureDetector(
                onTap: () {},
                child: SvgPicture.asset('assets/icons/fullscreen_button.svg', width: 16, height: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cadenceContent() {
    return SizedBox(
      width: DesignFrame.width,
      height: DesignFrame.height,
      child: Stack(
        children: [
          _rulerArea(),
          _cadenceFaders(),
        ],
      ),
    );
  }

  Widget _rulerArea() {
    final totalSeconds = widget.draft.instrumentalDurationMs != null
        ? widget.draft.instrumentalDurationMs! / 1000
        : 180.0;

    const viewportWidth = DesignFrame.width - 30;
    const viewportHeight = 655.0;

    return Positioned(
      left: 30,
      top: 196,
      child: ZoomableRuler(
        totalDurationSeconds: totalSeconds,
        viewportWidth: viewportWidth,
        viewportHeight: viewportHeight,
      ),
    );
  }

  Widget _cadenceFaders() {
    return Positioned(
      left: 30,
      top: 196,
      child: IgnorePointer(
        child: SizedBox(
          width: 329,
          height: 655,
          child: SvgPicture.asset(
            'assets/icons/cadence_mode_faders.svg',
            width: 329,
            height: 655,
            fit: BoxFit.fill,
          ),
        ),
      ),
    );
  }

  Widget _pageTitle() {
    final title = widget.draft.name.trim().isEmpty ? 'untitled' : widget.draft.name.trim();
    return Positioned(
      left: 30,
      top: 120,
      width: DesignFrame.width - 60,
      child: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontFamily: 'Times New Roman',
          fontSize: 32,
          fontWeight: FontWeight.w400,
          color: AppColors.textDark,
        ),
      ),
    );
  }

  Widget _getProButtonSmall() {
    return Positioned(
      left: 283,
      top: 66,
      child: GestureDetector(
        onTap: () {},
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(color: AppColors.textDark, borderRadius: BorderRadius.circular(20)),
          child: Center(
            child: SvgPicture.asset('assets/icons/crown_icon.svg', width: 20, height: 20),
          ),
        ),
      ),
    );
  }

  Widget _settingsButton() {
    return Positioned(
      left: 324,
      top: 65,
      child: GestureDetector(
        onTap: () {},
        child: SvgPicture.asset('assets/icons/settings_icon.svg', width: 32, height: 32),
      ),
    );
  }

  Widget _backButton() {
    return Positioned(
      left: 30,
      top: 65,
      child: GestureDetector(
        onTap: _handleBack,
        child: GlassSurface(
          width: 32,
          height: 32,
          borderRadius: 16,
          child: Center(
            child: SvgPicture.asset('assets/icons/back_chevron.svg', width: 16, height: 16),
          ),
        ),
      ),
    );
  }
}

class _HighlightMenuLayoutDelegate extends SingleChildLayoutDelegate {
  final Offset anchor;
  const _HighlightMenuLayoutDelegate(this.anchor);

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) => constraints.loosen();

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    double x = anchor.dx - (childSize.width / 2);
    x = x.clamp(8.0, size.width - childSize.width - 8.0);
    double y = anchor.dy - childSize.height - 12;
    if (y < 8) y = anchor.dy + 12;
    return Offset(x, y);
  }

  @override
  bool shouldRelayout(covariant _HighlightMenuLayoutDelegate oldDelegate) =>
      oldDelegate.anchor != anchor;
}