import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Copies the picked instrumental file into the app's own persistent
/// storage folder, so playback/waveform logic never breaks if the user
/// later moves, renames, or deletes the original file they picked it
/// from 
Future<String> copyInstrumentalToAppStorage(String sourcePath, String draftId) async {
  final appDir = await getApplicationDocumentsDirectory();
  final instrumentalsDir = Directory('${appDir.path}/instrumentals');
  if (!await instrumentalsDir.exists()) {
    await instrumentalsDir.create(recursive: true);
  }

  final extension = sourcePath.split('.').last;
  final destPath = '${instrumentalsDir.path}/$draftId.$extension';
  final copiedFile = await File(sourcePath).copy(destPath);
  return copiedFile.path;
}