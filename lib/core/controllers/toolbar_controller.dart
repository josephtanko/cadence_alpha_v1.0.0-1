import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart'; // AppLifecycleState
import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import '../models/draft.dart';
import '../repositories/draft_repository.dart';

class ToolbarController extends ChangeNotifier {
  final Draft draft;

  ToolbarController(this.draft) {
    _setupAudioSession();
    if (draft.instrumentalPath != null) {
      loadInstrumental(draft.instrumentalPath!);
    }
  }

  AudioPlayer? audioPlayer;
  Duration totalDuration = Duration.zero;
  bool isSeeking = false;
  Duration seekPreviewPosition = Duration.zero;

  final AudioRecorder recorder = AudioRecorder();
  StreamSubscription<Amplitude>? _amplitudeSub;
  bool isRecording = false;
  bool isRecordingPaused = false;
  final List<double> waveformLevels = [];
  static const int _maxWaveformBars = 55;

  Future<void> _setupAudioSession() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
        avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.allowBluetooth |
            AVAudioSessionCategoryOptions.defaultToSpeaker,
        avAudioSessionMode: AVAudioSessionMode.defaultMode,
        avAudioSessionRouteSharingPolicy: AVAudioSessionRouteSharingPolicy.defaultPolicy,
        avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
        androidAudioAttributes: const AndroidAudioAttributes(
          contentType: AndroidAudioContentType.music,
          flags: AndroidAudioFlags.none,
          usage: AndroidAudioUsage.media,
        ),
        androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
        androidWillPauseWhenDucked: true,
      ));
      await session.setActive(true);
    } catch (_) {}
  }

  Future<void> loadInstrumental(String path) async {
    audioPlayer ??= AudioPlayer(handleAudioSessionActivation: false);
    try {
      final duration = await audioPlayer!.setFilePath(path, preload: true);
      totalDuration = duration ?? Duration.zero;
      await audioPlayer!.setLoopMode(LoopMode.one);
    } catch (_) {}
    notifyListeners();
  }

  Future<void> importInstrumental(String newFilePath) async {
    draft.instrumentalPath = newFilePath;
    await loadInstrumental(newFilePath);
    draft.updatedAt = DateTime.now().millisecondsSinceEpoch;
    await DraftRepository.upsert(draft);
  }

  Future<void> handleAppLifecycleChange(AppLifecycleState state) async {
    if ((state == AppLifecycleState.paused || state == AppLifecycleState.inactive) &&
        isRecording &&
        !isRecordingPaused) {
      await pauseRecordingAndPlayback();
    }
  }

  void _subscribeAmplitude() {
    _amplitudeSub?.cancel();
    _amplitudeSub = recorder.onAmplitudeChanged(const Duration(milliseconds: 100)).listen((amp) {
      final normalized = ((amp.current + 45) / 45).clamp(0.0, 1.0);
      waveformLevels.add(normalized);
      if (waveformLevels.length > _maxWaveformBars) {
        waveformLevels.removeAt(0);
      }
      notifyListeners();
    });
  }

  Future<void> toggleRecordButton() async {
    if (isRecording) {
      await stopRecordingAndCommit();
    } else {
      await startRecording();
    }
  }

  Future<void> startRecording() async {
    final hasPermission = await recorder.hasPermission();
    if (!hasPermission) return;

    final appDir = await getApplicationDocumentsDirectory();
    final recordingsDir = Directory('${appDir.path}/recordings');
    if (!await recordingsDir.exists()) {
      await recordingsDir.create(recursive: true);
    }
    final path = '${recordingsDir.path}/${draft.id}_${DateTime.now().millisecondsSinceEpoch}.m4a';

    const config = RecordConfig(
      encoder: AudioEncoder.aacLc,
      sampleRate: 44100,
      numChannels: 1,
      autoGain: true,
      echoCancel: true,
      noiseSuppress: true,
    );

    _subscribeAmplitude();
    await recorder.start(config, path: path);

    isRecording = true;
    isRecordingPaused = false;
    waveformLevels.clear();
    notifyListeners();

    if (audioPlayer != null) {
      await audioPlayer!.seek(audioPlayer!.position);
      await audioPlayer!.play();
    }
  }

  Future<void> pauseRecordingAndPlayback() async {
    await recorder.pause();
    await _amplitudeSub?.cancel();
    _amplitudeSub = null;
    await audioPlayer?.pause();
    isRecordingPaused = true;
    notifyListeners();
  }

  Future<void> resumeRecordingAndPlayback() async {
    if (audioPlayer != null) {
      audioPlayer!.play();
    }
    await recorder.resume();
    _subscribeAmplitude();
    isRecordingPaused = false;
    notifyListeners();
  }

  Future<void> stopRecordingAndCommit() async {
    await _amplitudeSub?.cancel();
    _amplitudeSub = null;

    final path = await recorder.stop();

    if (audioPlayer != null) {
      await audioPlayer!.pause();
      await audioPlayer!.seek(Duration.zero);
    }

    isRecording = false;
    isRecordingPaused = false;
    waveformLevels.clear();
    notifyListeners();

    if (path != null) {
      draft.cachedRecordings.add(
        CachedRecording(path: path, muted: true, createdAt: DateTime.now().millisecondsSinceEpoch),
      );
      draft.updatedAt = DateTime.now().millisecondsSinceEpoch;
      await DraftRepository.upsert(draft);
    }
  }

  Future<void> handlePlayPauseTap() async {
    if (isRecording) {
      if (isRecordingPaused) {
        await resumeRecordingAndPlayback();
      } else {
        await pauseRecordingAndPlayback();
      }
      return;
    }
    if (audioPlayer == null) return;
    if (audioPlayer!.playing) {
      audioPlayer!.pause();
    } else {
      audioPlayer!.play();
    }
  }

  Future<void> handlePlayDoubleTap() async {
    if (isRecording || audioPlayer == null) return;
    await audioPlayer!.seek(Duration.zero);
    await audioPlayer!.pause();
  }

  void updateSeekPreview(double dx, double width) {
    if (totalDuration.inMilliseconds == 0) return;
    final fraction = (dx / width).clamp(0.0, 1.0);
    seekPreviewPosition = Duration(milliseconds: (fraction * totalDuration.inMilliseconds).round());
    notifyListeners();
  }

  void seekToLocalX(double dx, double width) {
    if (audioPlayer == null || totalDuration.inMilliseconds == 0) return;
    final fraction = (dx / width).clamp(0.0, 1.0);
    audioPlayer!.seek(Duration(milliseconds: (fraction * totalDuration.inMilliseconds).round()));
  }

  void commitSeek() {
    audioPlayer?.seek(seekPreviewPosition);
    isSeeking = false;
    notifyListeners();
  }

  void setSeeking(bool value) {
    isSeeking = value;
    notifyListeners();
  }

  Future<void> disposeController() async {
    await audioPlayer?.dispose();
    await _amplitudeSub?.cancel();
    if (isRecording) {
      await recorder.stop();
    }
    await recorder.dispose();
  }
}