import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class BpmAnalyzer {
  static const MethodChannel _channel = MethodChannel('com.example.cadence/bpm');

  static Future<double?> analyzeBpm(String filePath) async {
    try {
      final double? result = await _channel.invokeMethod<double>('analyzeBpm', {
        'filePath': filePath,
      });
      return result;
    } on PlatformException catch (e) {
      debugPrint("Failed to analyze BPM (PlatformException): '${e.message}'.");
      return null;
    } catch (e) {
      debugPrint("Unexpected error analyzing BPM: $e");
      return null;
    }
  }
}