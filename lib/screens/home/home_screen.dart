import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/design_constants.dart';
import '../../core/glass_surface.dart';
import '../../core/models/draft.dart';
import '../../core/repositories/draft_repository.dart';
import '../../core/utils/file_storage.dart';
import '../../core/utils/bpm_analyzer.dart';
import '../../widgets/new_draft_modal.dart';
import '../draft_workspace/draft_workspace_screen.dart';
import 'package:just_audio/just_audio.dart';
import '../../widgets/draft_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _showNewDraftModal = false;
  List<Draft> _drafts = [];
  bool _loadingDrafts = true;

  @override
  void initState() {
    super.initState();
    _loadDrafts();
  }

  Future<void> _loadDrafts() async {
    final drafts = await DraftRepository.loadAll();
    if (!mounted) return;
    setState(() {
      _drafts = drafts;
      _loadingDrafts = false;
    });
  }

  void _openNewDraftModal() {
    setState(() => _showNewDraftModal = true);
  }

  void _closeNewDraftModal() {
    setState(() => _showNewDraftModal = false);
  }

  Future<void> _handleSaveDraft(String name, String? instrumentalPath) async {
    setState(() => _showNewDraftModal = false);

    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final now = DateTime.now().millisecondsSinceEpoch;

    String? storedInstrumentalPath;
    int? durationMs;
    double? analyzedBpm;

    if (instrumentalPath != null) {
      storedInstrumentalPath = await copyInstrumentalToAppStorage(instrumentalPath, id);

      final tempPlayer = AudioPlayer();
      try {
        final duration = await tempPlayer.setFilePath(storedInstrumentalPath);
        durationMs = duration?.inMilliseconds;
      } catch (_) {
        durationMs = null;
      } finally {
        await tempPlayer.dispose();
      }

      analyzedBpm = await BpmAnalyzer.analyzeBpm(storedInstrumentalPath);
    }

    final draft = Draft(
      id: id,
      name: name,
      instrumentalPath: storedInstrumentalPath,
      instrumentalDurationMs: durationMs,
      bpm: analyzedBpm,
      lyricText: '',
      createdAt: now,
      updatedAt: now,
    );

    await DraftRepository.upsert(draft);

    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => DraftWorkspaceScreen(draft: draft)),
    );

    _loadDrafts();
  }

  Future<void> _openExistingDraft(Draft draft) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => DraftWorkspaceScreen(draft: draft)),
    );
    _loadDrafts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      body: SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.fitWidth,
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: DesignFrame.width,
            height: DesignFrame.height,
            child: Stack(
              children: [
                if (!_showNewDraftModal && !_loadingDrafts && _drafts.isEmpty)
                  _emptyStateIcon(),

                if (!_showNewDraftModal && !_loadingDrafts && _drafts.isNotEmpty)
                  _draftsList(),

                _getProButton(),
                _settingsButton(),
                _searchBar(),
                _filterBox(),
                _createTagButton(),
                _allTagsButton(),

                if (!_showNewDraftModal) _pageTitle(),
                if (!_showNewDraftModal) _newDraftButton(context),

                if (_showNewDraftModal) ...[
                  _bgBlur(),
                  _pageTitle(),
                  NewDraftModal(
                    onCancel: _closeNewDraftModal,
                    onSave: _handleSaveDraft,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _draftsList() {
    return Positioned(
      left: 30,
      top: 260,
      child: ClipRect(
        child: SizedBox(
          width: 330,
          height: 590,
          child: Stack(
            children: [
              Transform.translate(
                offset: const Offset(0, -25),
                child: ListView.separated(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  itemCount: _drafts.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final draft = _drafts[index];
                    return DraftCard(
                      draft: draft,
                      completion: 0.0,
                      onTap: () => _openExistingDraft(draft),
                      onMenuTap: () {},
                    );
                  },
                ),
              ),
              Positioned(
                left: -1.5,
                top: -15,
                child: IgnorePointer(
                  child: SizedBox(
                    width: 332,
                    height: 590,
                    child: SvgPicture.asset(
                      'assets/icons/draftlist_faders.svg',
                      width: 332,
                      height: 590,
                      fit: BoxFit.fill,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bgBlur() {
    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _closeNewDraftModal,
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              color: AppColors.background.withValues(alpha: 0.10),
            ),
          ),
        ),
      ),
    );
  }

  Widget _pageTitle() {
    return Positioned(
      left: 30,
      top: 120,
      child: SizedBox(
        width: 123,
        height: 38,
        child: Text(
          _showNewDraftModal ? 'NEW' : 'DRAFTS',
          style: const TextStyle(
            fontFamily: 'PerpetuaTitlingMT',
            fontSize: 32,
            fontWeight: FontWeight.w300,
            color: AppColors.textDark,
          ),
        ),
      ),
    );
  }

  Widget _getProButton() {
    return Positioned(
      left: 230,
      top: 66,
      child: GestureDetector(
        onTap: () {},
        child: Container(
          width: 85,
          height: 30,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: AppColors.textDark,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset('assets/icons/crown_icon.svg', width: 16, height: 16),
              const SizedBox(width: 4),
              const Flexible(
                child: Text(
                  'Get Pro',
                  style: TextStyle(fontFamily: 'Arial', fontSize: 12, color: AppColors.white),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
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
        child: SvgPicture.asset(
          'assets/icons/settings_icon.svg',
          width: 32,
          height: 32,
        ),
      ),
    );
  }

  Widget _searchBar() {
    return Positioned(
      left: 30,
      top: 170,
      child: Container(
        width: 270,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.searchFill,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.strokeGray.withValues(alpha: 0.15),
            width: 2,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              left: 9,
              top: 6,
              child: SvgPicture.asset(
                'assets/icons/magnifier_icon.svg',
                width: 24,
                height: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterBox() {
    return Positioned(
      left: 320,
      top: 170,
      child: GestureDetector(
        onTap: () {},
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.searchFill,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.strokeGray.withValues(alpha: 0.15),
              width: 2,
            ),
          ),
          child: Center(
            child: SvgPicture.asset(
              'assets/icons/sort_icon.svg',
              width: 24,
              height: 24,
            ),
          ),
        ),
      ),
    );
  }

  Widget _createTagButton() {
    return Positioned(
      left: 30,
      top: 225,
      child: GestureDetector(
        onTap: () {},
        child: GlassSurface(
          width: 100,
          height: 30,
          borderRadius: 20,
          child: const Center(
            child: Text(
              '+ Create tag',
              style: TextStyle(
                fontFamily: 'Arial',
                fontSize: 12,
                color: AppColors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _allTagsButton() {
    return Positioned(
      left: 145,
      top: 225,
      child: GestureDetector(
        onTap: () {},
        child: Container(
          width: 65,
          height: 30,
          decoration: BoxDecoration(
            color: AppColors.textDark,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Center(
            child: Text(
              'All tags',
              style: TextStyle(
                fontFamily: 'Arial',
                fontSize: 12,
                color: AppColors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _emptyStateIcon() {
    return Positioned(
      left: 103,
      top: 405,
      child: SizedBox(
        width: 189,
        height: 103,
        child: SvgPicture.asset('assets/icons/empty_state_image.svg'),
      ),
    );
  }

  Widget _newDraftButton(BuildContext context) {
    return Positioned(
      left: 280,
      top: 710,
      child: GestureDetector(
        onTap: _openNewDraftModal,
        child: GlassSurface(
          width: 80,
          height: 80,
          borderRadius: 20,
          child: const Center(
            child: Text(
              '+',
              style: TextStyle(
                fontFamily: 'Arial',
                fontSize: 32,
                color: AppColors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }
}