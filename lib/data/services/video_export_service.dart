import 'dart:typed_data';

import 'package:flutter/services.dart';

/// Method-channel wrapper for the native H.264 video encoder.
/// Sequence: startEncoder → addFrame (×N) → finalize.
class VideoExportService {
  static const _ch = MethodChannel('film_maker/video_export');

  Future<void> startEncoder({
    required int width,
    required int height,
    required int fps,
    required int bitrateBps,
  }) =>
      _ch.invokeMethod<void>('startEncoder', {
        'width': width,
        'height': height,
        'fps': fps,
        'bitrate': bitrateBps,
      });

  /// [rgbaBytes] must be width × height × 4 raw RGBA pixels.
  Future<void> addFrame(Uint8List rgbaBytes) =>
      _ch.invokeMethod<void>('addFrame', rgbaBytes);

  /// Finalizes encoding, optionally muxes [musicPath], saves to gallery.
  /// Returns the gallery URI / file path of the saved MP4.
  Future<String> finalize({
    String? musicPath,
    required String outputName,
  }) async {
    final result = await _ch.invokeMethod<String>('finalize', {
      'musicPath': musicPath,
      'outputName': outputName,
    });
    return result!;
  }

  Future<void> cancelExport() => _ch.invokeMethod<void>('cancelExport');
}
